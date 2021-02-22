%================================================================
%  
%================================================================

classdef StitchRecon < handle

    properties (SetAccess = private)                    
        StitchMetaData;
        Recon;
    end
    methods 

        
%==================================================================
% Constructor
%==================================================================   
        function obj = StitchRecon()
        end   

%==================================================================
% StitchInit
%==================================================================   
        function StitchInit(obj,StitchMetaData,log)
            obj.StitchMetaData = StitchMetaData;
            
            %------------------------------------------------------
            % Get ReconInfo (if don't already have)
            %------------------------------------------------------
            if obj.StitchMetaData.PullReconLocal
                obj.PullReconInfoLocal(log);
            end

            %------------------------------------------------------
            % Reset GPUs (if requested)
            %------------------------------------------------------
            if obj.StitchMetaData.ResetGpus
                log.info('Reset GPUs');
                GpuTot = gpuDeviceCount;
                for n = 1:GpuTot
                    gpuDevice(n);               
                end
            end
            
            %------------------------------------------------------
            % Load Trajectory 
            %------------------------------------------------------
            if obj.StitchMetaData.LoadTrajLocal == 1
                ReconInfoMat = obj.LoadTrajectoryLocal(log);        
            end
            
            %------------------------------------------------------
            % Initialize ReconFunction
            %------------------------------------------------------
            func = str2func(obj.StitchMetaData.ReconFunction);
            obj.Recon = func();
            obj.Recon.StitchInit(obj.StitchMetaData,ReconInfoMat,log);
        end           

%==================================================================
% UpdateTestStitchMetaData
%==================================================================          
        function UpdateTestStitchMetaData(obj,ReconMetaData,log)
%             if ReconMetaData.Fov ~= obj.StitchMetaData.Fov || ...
%                ReconMetaData.Vox ~= obj.StitchMetaData.Vox || ...
%                ReconMetaData.Elip ~= obj.StitchMetaData.Elip || ...
%                ReconMetaData.Tro ~= obj.StitchMetaData.Tro || ...
%                ReconMetaData.Nproj ~= obj.StitchMetaData.Nproj || ...
%                ReconMetaData.p ~= obj.StitchMetaData.p
%                 log.ERROR('Recon incompatable with data'); 
%             end                    
            fields = fieldnames(ReconMetaData);
            for n = 1:length(fields)
                obj.StitchMetaData.(fields{n}) = ReconMetaData.(fields{n});
            end
            obj.StitchMetaData.GpuTot = gpuDeviceCount;
            if obj.StitchMetaData.GpuTot > obj.StitchMetaData.RxChannels
                obj.StitchMetaData.GpuTot = obj.StitchMetaData.RxChannels;
            end
            obj.StitchMetaData.ChanPerGpu = ceil(obj.StitchMetaData.RxChannels/obj.StitchMetaData.GpuTot);
            obj.Recon.UpdateStitchMetaData(obj.StitchMetaData);
        end        
        
%==================================================================
% StitchDataProcessInit
%==================================================================           
        function StitchDataProcessInit(obj,DataObj,log) 
            obj.Recon.StitchReconDataProcessInit(DataObj,log);
        end
            
%==================================================================
% PullReconInfoLocal
%==================================================================   
        function PullReconInfoLocal(obj,log)
            ReconPath = 'D:\StitchRelated\DefaultReconstructions\';
            addpath(ReconPath);
            if not(exist(obj.StitchMetaData.ReconProtocol,'file'))
                log.error(['ReconProtocol ''',obj.StitchMetaData.ReconProtocol,''' does not exist']);
            end
            func = str2func(obj.StitchMetaData.ReconProtocol);            
            obj.StitchMetaData = func(obj.StitchMetaData,log);
        end  

%==================================================================
% StitchIntraAcqProcess
%================================================================== 
        function StitchIntraAcqProcess(obj,DataObj,log)
            obj.Recon.StitchIntraAcqProcess(DataObj,log);
        end 
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)
            obj.Recon.StitchPostAcqProcess(DataObj,log);
        end 
        
%==================================================================
% StitchReturnImage
%================================================================== 
        function Image = StitchReturnImage(obj,log)
            Image = obj.Recon.StitchReturnImage(log);
        end        
        
%==================================================================
% LoadTrajectoryLocal 
%==================================================================   
        function ReconInfoMat = LoadTrajectoryLocal(obj,log)
            log.info('Retreive Trajectory Info From HardDrive');
            warning 'off';                          % because tries to find functions not on path
            load(obj.StitchMetaData.TrajFile);
            warning 'on';
            IMP = saveData.IMP;
            
            %------------------------------------------------------
            % Check File type
            %------------------------------------------------------ 
            if isfield(IMP,'Kmat')
%                 log.info('Arrange Trajectory Info Into Proper Format');                                   
%                 KspaceMat0 = permute(IMP.Kmat,[2 1 3]);
%                 KspaceMat = KspaceMat0;
%                 KspaceMat(:,:,1) = KspaceMat0(:,:,2);
%                 KspaceMat(:,:,2) = KspaceMat0(:,:,1);
%                 KspaceMat(:,:,3) = KspaceMat0(:,:,3);
%                 SampDensComp = permute(IMP.SDC,[2 1]);
%                 ReconInfoMat = cat(3,KspaceMat,SampDensComp);
%                 kRad = sqrt(KspaceMat(:,:,1).^2 + KspaceMat(:,:,2).^2 + KspaceMat(:,:,3).^2);
%                 obj.StitchMetaData.kMaxRad = max(kRad(:));
%                 obj.StitchMetaData.kStep = IMP.PROJdgn.kstep;               
%                 obj.StitchMetaData.npro = IMP.PROJimp.npro;
%                 obj.StitchMetaData.Dummies = IMP.dummies;
%                 obj.StitchMetaData.NumTraj = IMP.PROJimp.nproj;
%                 obj.StitchMetaData.NumCol = IMP.KSMP.nproRecon;
%                 obj.StitchMetaData.SampStart = IMP.KSMP.DiscardStart+1;
%                 obj.StitchMetaData.SampEnd = obj.StitchMetaData.SampStart+obj.StitchMetaData.NumCol-1;
                error('redo recon file');
            else
                ReconInfoMat = IMP.ReconInfoMat;
                obj.StitchMetaData.kMaxRad = IMP.kMaxRad;
                obj.StitchMetaData.kStep = IMP.kStep;               
                obj.StitchMetaData.npro = IMP.npro;
                obj.StitchMetaData.Dummies = IMP.Dummies;
                obj.StitchMetaData.NumTraj = IMP.NumTraj;
                obj.StitchMetaData.NumCol = IMP.NumCol;
                obj.StitchMetaData.SampStart = IMP.SampStart;
                obj.StitchMetaData.SampEnd = IMP.SampEnd;
                obj.StitchMetaData.Fov = IMP.Fov;
                obj.StitchMetaData.Vox = IMP.Vox;
            end
        end             
    end
end