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
% StitchGridInit
%==================================================================           
        function StitchGridInit(obj,log) 

            %---------------------------------------------
            % Allocate Image Space on CPU
            %---------------------------------------------
            NumExp = 1;
            log.info('Allocate CPU Memory');
            obj.Image = complex(zeros([obj.ImageMatrixMemDims,NumExp,obj.StitchMetaData.RxChannels],'single'),zeros([obj.ImageMatrixMemDims,NumExp,obj.StitchMetaData.RxChannels],'single'));            
            obj.GridInitialize(log);  
        end        
        
%==================================================================
% StitchIntraAcqProcess
%================================================================== 
        function StitchIntraAcqProcess(obj,DataObj,log)           
            if obj.StitchMetaData.LoadTrajLocal == 1
                Start = DataObj.DataBlockAcqStartNumber;
                Stop = DataObj.DataBlockAcqStopNumber;
                if Stop-Start+1 == DataObj.DataBlockLength
                    obj.GpuGrid(obj.ReconInfoMat(:,Start:Stop,:),DataObj.Data,log);
                elseif Stop-Start+1 < DataObj.DataBlockLength
                    TempReconInfoMat = zeros(DataObj.NumCol,DataObj.DataBlockLength,4,'single');
                    TempReconInfoMat(:,1:Stop-Start+1,:) = obj.ReconInfoMat(:,Start:Stop,:);
                    obj.GpuGrid(TempReconInfoMat,DataObj.Data,log);
                end
            else
                obj.GpuGrid(DataObj.ReconInfoMat,DataObj.Data,log);
            end
        end
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,log)
            obj.GridFinish(log);
            log.info('Fourier Transform');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.KspaceScaleCorrect(GpuNum,GpuChan); 
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);                 
                    obj.InverseFourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);          
                    obj.MultInvFilt(GpuNum,GpuChan); 
                end
            end
            log.info('Return Images from GPU');
            Scale = 1e10;  % for Siemens (should come from above...)
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    obj.ScaleImage(GpuNum,GpuChan,Scale); 
                    obj.Image(:,:,:,:,ChanNum) = obj.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
                end
            end
            obj.FreeKspaceImageMatricesGpuMem;
            
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
            else
                error('unrecognized ''Return Fov''');
            end
        end        
     
%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 
            Image = obj.Image;
            %--
            Image = permute(Image,[2 1 3 4 5 6 7]);             % this has gotta go...  (handle in k-space array...)
            Image = flip(Image,2);
            %--
        end         
        
    end
end