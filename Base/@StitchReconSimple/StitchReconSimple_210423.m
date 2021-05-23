%================================================================
%  
%================================================================

classdef StitchReconSimple < Grid

    properties (SetAccess = private)                    
        StitchMetaData;
        ReconInfoMat;
        Image;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconSimple()
            obj@Grid;   
        end
        
%==================================================================
% StitchBasicInit
%==================================================================   
        function StitchBasicInit(obj,StitchMetaData,ReconInfoMat,log)
            obj.StitchMetaData = StitchMetaData;
            obj.ReconInfoMat = ReconInfoMat;
            
            %------------------------------------------------------
            % GridSupportFileLoad
            %------------------------------------------------------
            obj.GridKernelInvFiltLoad(log);
            
            %---------------------------------------------
            % Setup FFT
            %---------------------------------------------
            log.info('Setup Fourier Transform');
            ZeroFillArray = [obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill];          % isotropic for now
            obj.SetupFourierTransform(ZeroFillArray);
        end   
        
%==================================================================
% UpdateStitchMetaData
%==================================================================          
        function UpdateStitchMetaData(obj,StitchMetaData)
            obj.StitchMetaData = StitchMetaData;
        end

%==================================================================
% AddToStitchMetaData
%==================================================================          
        function AddToStitchMetaData(obj,Field,Val)
            for n = 1:length(Field)
                obj.StitchMetaData.(Field{n}) = Val{n};
            end
        end         
        
%==================================================================
% StitchGridInit
%==================================================================           
        function StitchGridInit(obj,log) 
            NumExp = 1;
            log.info('Allocate CPU Memory');
            obj.Image = complex(zeros([obj.ImageMatrixMemDims,NumExp,obj.StitchMetaData.RxChannels],'single'),0);               
            obj.GridInitialize(log);  
        end        
        
%==================================================================
% StitchGridDataBlock
%================================================================== 
        function StitchGridDataBlock(obj,DataObj,Info,log)           
            if obj.StitchMetaData.LoadTrajLocal == 1
                Start = Info.TrajAcqStart;
                Stop = Info.TrajAcqStop;
                if Stop-Start+1 == DataObj.DataBlockLength
                    obj.GpuGrid(obj.ReconInfoMat(:,Start:Stop,:),DataObj.DataBlock,log);
                elseif Stop-Start+1 < DataObj.DataBlockLength
                    TempReconInfoMat = zeros(DataObj.NumCol,DataObj.DataBlockLength,4,'single');
                    TempReconInfoMat(:,1:Stop-Start+1,:) = obj.ReconInfoMat(:,Start:Stop,:);
                    obj.GpuGrid(TempReconInfoMat,DataObj.DataBlock,log);
                end
            else
                obj.GpuGrid(DataObj.ReconInfoMat,DataObj.DataBlock,log);
            end
        end
        
%==================================================================
% StitchFft
%================================================================== 
        function StitchFft(obj,log)

            %---------------------------------------------
            % Fourier Transform
            %---------------------------------------------      
            log.info('Fourier Transform');
            Scale = 1e10;  % for Siemens (should come from above...)
            Scale = Scale/(obj.SubSamp^3);
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                    obj.InverseFourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                    obj.MultInvFilt(GpuNum,GpuChan); 
                    obj.ScaleImage(GpuNum,GpuChan,Scale); 
                end
            end
            
            %----------------------------------------------
            % Return Images
            %----------------------------------------------            
            log.info('Return Images from GPU');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    obj.Image(:,:,:,:,ChanNum) = obj.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
                end
            end
            
            %----------------------------------------------
            % Return FoV
            %----------------------------------------------
            if strcmp(obj.StitchMetaData.ReturnFov,'All')
                obj.Image = obj.Image;
            elseif strcmp(obj.StitchMetaData.ReturnFov,'Design')
                log.info('Return FoV');
                start = obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2+1;
                stop = obj.ImageMatrixMemDims - obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2;
                obj.Image = obj.Image(start(1):stop(1),start(2):stop(2),start(3):stop(3),:,:,:);
            elseif strcmp(obj.StitchMetaData.ReturnFov,'HeadBig')
                log.info('Return FoV');
                FovWanted(1) = 260;
                FovWanted(2) = 220;                 
                FovWanted(3)= 220;
                ImSize = size(obj.Image);
                NewImSize = 2*round((FovWanted/(obj.StitchMetaData.Fov*obj.SubSamp)).*ImSize/2);
                start = ImSize/2 - NewImSize/2 + 1;
                stop = ImSize/2 + NewImSize/2;                
                obj.Image = obj.Image(start(2):stop(2),start(1):stop(1),start(3):stop(3),:,:,:);
            else
                error('unrecognized ''Return Fov''');
            end
        end        

%==================================================================
% StitchFreeGpuMemory
%==================================================================           
        function StitchFreeGpuMemory(obj,log) 
            obj.ReleaseGriddingGpuMem;
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperMatricesGpuMem;
            end
        end          
        
%==================================================================
% StitchReturnIndividualImages
%==================================================================           
        function Image = StitchReturnIndividualImages(obj,log) 
            Image = obj.Image;
            %--
            Image = permute(Image,[2 1 3 4 5 6 7]);             % this has gotta go...  (handle in k-space array...)
            Image = flip(Image,2);
            %--
        end         
        
    end
end