%================================================================
%  
%================================================================

classdef StitchReconSuper < Grid

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
        function [obj,StitchMetaDataReturn] = StitchReconSuper(StitchMetaData,log)
            obj@Grid;   
            obj.StitchMetaData = StitchMetaData;
            
            %------------------------------------------------------
            % If traj not part of data stream
            %   -> pull locally 
            %------------------------------------------------------
            if obj.StitchMetaData.LoadLocal == 1
                obj.LoadTrajectoryLocal(log);        
            end

            %------------------------------------------------------
            % Initialize 
            %------------------------------------------------------
            obj.GridInitialize(obj.StitchMetaData,log);  
            
            %---------------------------------------------
            % Setup FFT
            %---------------------------------------------
            log.info('Setup Fourier Transform');
            ZeroFillArray = [StitchMetaData.ZeroFill StitchMetaData.ZeroFill StitchMetaData.ZeroFill];          % isotropic for now
            obj.SetupFourierTransform(ZeroFillArray);
            
            %---------------------------------------------
            % Allocate Image Space on CPU
            %---------------------------------------------
            NumExp = 1;
            log.info('Allocate CPU Memory');
            obj.Image = complex(zeros([obj.ImageMatrixMemDims,NumExp],'single'),zeros([obj.ImageMatrixMemDims,NumExp],'single'));
            obj.ImageHighSoS = complex(zeros([obj.ImageMatrixMemDims,NumExp],'single'),zeros([obj.ImageMatrixMemDims,NumExp],'single'));
            obj.ImageLowSoS = zeros([obj.ImageMatrixMemDims,NumExp],'single');
            obj.ImageHighSoSArr = complex(zeros([obj.ImageMatrixMemDims,NumExp,obj.NumGpuUsed],'single'),zeros([obj.ImageMatrixMemDims,NumExp,obj.NumGpuUsed],'single'));
            obj.ImageLowSoSArr = complex(zeros([obj.ImageMatrixMemDims,NumExp,obj.NumGpuUsed],'single'),zeros([obj.ImageMatrixMemDims,NumExp,obj.NumGpuUsed],'single'));
            
            %---------------------------------------------
            % Initialize Super
            %---------------------------------------------            
            log.info('Initialize Super');
            obj.CreateLoadSuperFilter(StitchMetaData,log);
            obj.LoadSuperFiltGpuMem(obj.SuperFilt);
            obj.AllocateSuperMatricesGpuMem;

            %---------------------------------------------
            % Finish
            %---------------------------------------------  
            StitchMetaDataReturn = obj.StitchMetaData;
        end   
        
%==================================================================
% StitchProcessData
%================================================================== 
        function StitchProcessData(obj,log)           
            if obj.StitchMetaData.LoadLocal == 1
                Start = obj.TrajCounter - obj.BlockLength + 1;
                Stop = Start +  obj.BlockLength - 1;
                obj.WriteReconInfoBlock(obj.ReconInfoMat(:,Start:Stop,:));        
            end
            obj.GridRealTime(log);           
        end
        
%==================================================================
% StitchFinish
%================================================================== 
        function StitchFinish(obj,log)
            obj.GridFinish(log);

            %---------------------------------------------
            % Fourier Transform
            %---------------------------------------------              
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
            log.info('Combine GPUs / Finish Super');
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageHighSoSArr(:,:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(obj.ImageHighSoSArr(:,:,:,:,m),GpuNum,obj.HSuperHighSoS);
            end
            for m = 1:obj.NumGpuUsed
                GpuNum = m-1;
                obj.ImageLowSoSArr(:,:,:,:,m) = obj.ReturnOneImageMatrixGpuMemSpecify(obj.ImageLowSoSArr(:,:,:,:,m),GpuNum,obj.HSuperLowSoS);
            end
            obj.CudaDeviceWait(obj.NumGpuUsed-1);
            for m = 1:obj.NumGpuUsed
                obj.ImageHighSoS = obj.ImageHighSoS + obj.ImageHighSoSArr(:,:,:,:,m);
                obj.ImageLowSoS = obj.ImageLowSoS + real(obj.ImageLowSoSArr(:,:,:,:,m));
            end
            obj.Image = obj.ImageHighSoS./(sqrt(obj.ImageLowSoS));
            obj.FreeKspaceImageMatricesGpuMem;
            
            %----------------------------------------------
            % Return FoV
            %----------------------------------------------
            log.info('Return FoV');
            start = obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2+1;
            stop = obj.ImageMatrixMemDims - obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2;
            obj.Image = obj.Image(start(1):stop(1),start(2):stop(2),start(3):stop(3),:,:,:);   
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
        
%==================================================================
% LoadTrajectoryLocal 
%==================================================================   
        function LoadTrajectoryLocal(obj,log)
            log.info('Retreive Trajectory Info From HardDrive');
            warning 'off';                          % because tries to find functions not on path
            load(obj.StitchMetaData.TrajFile);
            warning 'on';
            IMP = saveData.IMP;
            
            %------------------------------------------------------
            % Check File type
            %------------------------------------------------------ 
            if isfield(IMP,'Kmat')
                log.info('Arrange Trajectory Info Into Proper Format');                                   
                KspaceMat0 = permute(IMP.Kmat,[2 1 3]);
                KspaceMat = KspaceMat0;
                KspaceMat(:,:,1) = KspaceMat0(:,:,2);
                KspaceMat(:,:,2) = KspaceMat0(:,:,1);
                KspaceMat(:,:,3) = KspaceMat0(:,:,3);
                SampDensComp = permute(IMP.SDC,[2 1]);
                obj.ReconInfoMat = cat(3,KspaceMat,SampDensComp);
                kRad = sqrt(KspaceMat(:,:,1).^2 + KspaceMat(:,:,2).^2 + KspaceMat(:,:,3).^2);
                obj.StitchMetaData.kMaxRad = max(kRad(:));
                obj.StitchMetaData.kStep = IMP.PROJdgn.kstep;               
                obj.StitchMetaData.npro = IMP.PROJimp.npro;
                obj.StitchMetaData.Dummies = IMP.dummies;
                obj.StitchMetaData.NumTraj = IMP.PROJimp.nproj;
                obj.StitchMetaData.NumCol = IMP.KSMP.nproRecon;
                obj.StitchMetaData.SampStart = IMP.KSMP.DiscardStart+1;
                obj.StitchMetaData.SampEnd = obj.StitchMetaData.SampStart+obj.StitchMetaData.NumCol-1;           
            else
                obj.ReconInfoMat = IMP.ReconInfoMat;
                obj.StitchMetaData.kMaxRad = IMP.kMaxRad;
                obj.StitchMetaData.kStep = IMP.kStep;               
                obj.StitchMetaData.npro = IMP.npro;
                obj.StitchMetaData.Dummies = IMP.Dummies;
                obj.StitchMetaData.NumTraj = IMP.NumTraj;
                obj.StitchMetaData.NumCol = IMP.NumCol;
                obj.StitchMetaData.SampStart = IMP.SampStart;
                obj.StitchMetaData.SampEnd = IMP.SampEnd;
            end
        end          

    end
end