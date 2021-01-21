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
        function [obj,StitchMetaDataReturn] = ReconSimple(StitchMetaData,log)
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
            obj.Image = complex(zeros([obj.ImageMatrixMemDims,NumExp],'single'),zeros([obj.ImageMatrixMemDims,NumExp],'single'));
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
            log.info('Return FoV');
            start = obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2+1;
            stop = obj.ImageMatrixMemDims - obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2;
            obj.Image = obj.Image(start(1):stop(1),start(2):stop(2),start(3):stop(3),:,:,:);
        end        
        
%==================================================================
% LoadTrajectoryLocal (turn own object - to use for other recons)
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