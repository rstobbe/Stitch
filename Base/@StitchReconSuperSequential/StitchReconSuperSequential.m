%================================================================
%  
%================================================================

classdef StitchReconSuperSequential < Grid

    properties (SetAccess = private)                    
        StitchMetaData;
        ReconInfoMat;
        Image;
        ImageHighSoS; ImageHighSoSArr;
        ImageLowSoS; ImageLowSoSArr;
        SuperFilt;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconSuperSequential()
            obj@Grid;   
        end
        
%==================================================================
% StitchBasicInitSeq
%==================================================================   
        function StitchBasicInitSeq(obj,StitchMetaData,ReconInfoMat,log)
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
            
            %---------------------------------------------
            % Allocate Image Space on CPU
            %---------------------------------------------
            log.info('Allocate CPU Memory');
            obj.Image = complex(zeros([obj.ImageMatrixMemDims],'single'),0);
            obj.ImageHighSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);
            obj.ImageLowSoSArr = complex(zeros([obj.ImageMatrixMemDims,obj.NumGpuUsed],'single'),0);
            
            %---------------------------------------------
            % Initialize Super
            %---------------------------------------------            
            log.info('Create/Load Super Filter');
            obj.CreateLoadSuperFilter(obj.StitchMetaData,log);
            obj.LoadSuperFiltGpuMem(obj.SuperFilt);
        end   

%==================================================================
% UpdateStitchMetaData
%==================================================================          
% - in StitchReconSuper 

%==================================================================
% AddToStitchMetaData
%==================================================================          
% - in StitchReconSuper 

%==================================================================
% StitchGridInit
%==================================================================           
        function StitchGridInit(obj,log) 
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
% StitchFftCombine
%================================================================== 
        function StitchFftCombine(obj,log)

            %---------------------------------------------
            % Initialize Summation Matrices
            %---------------------------------------------                 
            log.info('Initialize Super');
            obj.ImageHighSoS = complex(zeros([obj.ImageMatrixMemDims],'single'),0);
            obj.ImageLowSoS = zeros([obj.ImageMatrixMemDims],'single');            
            obj.AllocateSuperMatricesGpuMem;
            
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
            % Super
            %----------------------------------------------
            log.info('Super Combine');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);
                    obj.FourierTransform(GpuNum,GpuChan);
                    obj.ImageFourierTransformShift(GpuNum,GpuChan);       % return to normal
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan); 
                    obj.SuperKspaceFilter(GpuNum,GpuChan);
                    obj.KspaceFourierTransformShift(GpuNum,GpuChan);         
                    obj.InverseFourierTransformSpecify(GpuNum,obj.HSuperLow,obj.HKspaceMatrix(GpuChan,:));    
                    obj.ImageFourierTransformShiftSpecify(GpuNum,obj.HSuperLow);          
                    obj.CreateLowImageConjugate(GpuNum);
                    obj.BuildLowSosImage(GpuNum);   
                    obj.BuildHighSosImage(GpuNum,GpuChan);           
                end
            end

            %----------------------------------------------
            % Return Data / Finish Super
            %----------------------------------------------
            log.info('Finish Super (Return HighSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(obj.ImageHighSoSArr(:,:,:,m),GpuNum,obj.HSuperHighSoS);
            end
            log.info('Finish Super (Return LowSoS)');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(obj.ImageLowSoSArr(:,:,:,m),GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            log.info('Finish Super (Combine Gpus)');
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,m));
            end
            log.info('Finish Super (Create Image)');
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            
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
% StitchFreeGpuMemory
%==================================================================           
        function StitchFreeGpuMemory(obj,log) 
            obj.ReleaseGriddingGpuMem;
            if not(isempty(obj.HSuperFilt))
                obj.FreeSuperMatricesGpuMem;
            end
        end   

%==================================================================
% StitchReturnSuperImage
%==================================================================           
        function Image = StitchReturnSuperImage(obj,log) 
            Image = obj.Image;
            %--
            Image = permute(Image,[2 1 3 4 5 6 7]);
            Image = flip(Image,2);
            %--
        end            
        
%==================================================================
% CreateLoadSuperFilter
%==================================================================         
        function CreateLoadSuperFilter(obj,StitchMetaData,log)

            fwidx = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            fwidy = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            fwidz = 2*round((StitchMetaData.Fov/StitchMetaData.Super.ProfRes)/2);
            F0 = Kaiser_v1b(fwidx,fwidy,fwidz,StitchMetaData.Super.ProfFilt,'unsym');
            x = obj.ImageMatrixMemDims(1);
            y = obj.ImageMatrixMemDims(2);
            z = obj.ImageMatrixMemDims(3);
            obj.SuperFilt = zeros(obj.ImageMatrixMemDims,'single');
            obj.SuperFilt(x/2-fwidx/2+1:x/2+fwidx/2,y/2-fwidy/2+1:y/2+fwidy/2,z/2-fwidz/2+1:z/2+fwidz/2) = F0;
        end
    end
end