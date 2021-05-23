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
% StitchLoadTrajInfo
%==================================================================   
        function StitchLoadTrajInfo(obj,StitchMetaData,log)
            obj.StitchMetaData = StitchMetaData;
            
            %------------------------------------------------------
            % Get ReconInfo (if don't already have)
            %------------------------------------------------------
            if obj.StitchMetaData.PullReconLocal
                obj.PullReconInfoLocal(log);
            end
           
            %------------------------------------------------------
            % Load Trajectory 
            %------------------------------------------------------
            if obj.StitchMetaData.LoadTrajLocal == 1
                obj.LoadTrajectoryLocal(log);        
            end
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
            % Load Trajectory 
            %------------------------------------------------------
            if obj.StitchMetaData.LoadTrajLocal == 1
                ReconInfoMat = obj.LoadTrajectoryLocal(log);        
            end

            %------------------------------------------------------
            % Update ReconInfo
            %------------------------------------------------------            
            obj.UpdateReconInfo(log);
            
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
            % Initialize ReconFunction
            %------------------------------------------------------
            if not(isobject(obj.Recon))
                func = str2func(obj.StitchMetaData.ReconFunction);
                obj.Recon = func();
            end
            ReconName = class(obj.Recon);
            if ~strcmp(ReconName,obj.StitchMetaData.ReconFunction)
                %Data = obj.Recon.Data;         % if field
                %SetData = 1;
                delete(obj.Recon);
                func = str2func(obj.StitchMetaData.ReconFunction);
                obj.Recon = func();
            end
            obj.Recon.StitchInit(obj.StitchMetaData,ReconInfoMat,log);
%             if SetData == 1
%                 obj.Recon.SetData(Data);
%             end
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
            if isempty(ReconMetaData)
                error('Reload Data');
            end
            fields = fieldnames(ReconMetaData);
            for n = 1:length(fields)
                obj.StitchMetaData.(fields{n}) = ReconMetaData.(fields{n});
            end
            obj.StitchMetaData.GpuTot = gpuDeviceCount;
            if obj.StitchMetaData.GpuTot > obj.StitchMetaData.RxChannels
                obj.StitchMetaData.GpuTot = obj.StitchMetaData.RxChannels;
            end
            obj.StitchMetaData.ChanPerGpu = ceil(obj.StitchMetaData.RxChannels/obj.StitchMetaData.GpuTot);
            if isobject(obj.Recon)
                obj.Recon.UpdateStitchMetaData(obj.StitchMetaData);
            end
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
            if not(exist(obj.StitchMetaData.ReconProtocol,'file'))
                error(['ReconProtocol ''',obj.StitchMetaData.ReconProtocol,''' does not exist']);
            end
            func = str2func(obj.StitchMetaData.ReconProtocol);            
            obj.StitchMetaData = func(obj.StitchMetaData,log);
            if not(isfield(obj.StitchMetaData,'TrajFile'))
                obj.StitchMetaData.TrajFile = [obj.StitchMetaData.StitchRelatedPath,'Trajectories\',obj.StitchMetaData.TrajName,'_X'];
            end
            if not(isfield(obj.StitchMetaData,'ResetGpus'))
                obj.StitchMetaData.ResetGpus = 0;
            end
            if not(isfield(obj.StitchMetaData,'LoadTrajLocal'))
                obj.StitchMetaData.LoadTrajLocal = 1;
            end
        end  
        
%==================================================================
% UpdateReconInfo
%==================================================================   
        function UpdateReconInfo(obj,log)
            if not(isfield(obj.StitchMetaData,'Kernel'))
                obj.StitchMetaData.Kernel = 'KBCw2b5p5ss1p6';
            end
            obj.StitchMetaData.KernelFile = [obj.StitchMetaData.StitchRelatedPath,'Kernels\Kern_',obj.StitchMetaData.Kernel,'.mat'];
            load(obj.StitchMetaData.KernelFile);
            SubSamp = saveData.KRNprms.DesforSS;
            PossibleZeroFill = saveData.KRNprms.PossibleZeroFill;
            obj.StitchMetaData.Matrix = obj.StitchMetaData.Fov/obj.StitchMetaData.Vox;
            obj.StitchMetaData.SubSampMatrix = obj.StitchMetaData.Matrix * SubSamp;
            if not(isfield(obj.StitchMetaData,'ZeroFill'))
                ind = find(PossibleZeroFill > obj.StitchMetaData.SubSampMatrix,1,'first');
                obj.StitchMetaData.ZeroFill = PossibleZeroFill(ind);
            end
            if obj.StitchMetaData.ZeroFill < obj.StitchMetaData.SubSampMatrix
                error('Specified ZeroFill is too small');
            end
            obj.StitchMetaData.InvFiltFile = [obj.StitchMetaData.StitchRelatedPath,'InverseFilters\IF_',obj.StitchMetaData.Kernel,'zf',num2str(obj.StitchMetaData.ZeroFill),'S.mat'];   
            if not(isfield(obj.StitchMetaData,'ReturnFov'))
                obj.StitchMetaData.ReturnFov = 'Design';
            end
            if not(isfield(obj.StitchMetaData,'Super'))
                obj.StitchMetaData.Super.ProfRes = 10;
                obj.StitchMetaData.Super.ProfFilt = 12;
            end
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
% StitchFinishAcqProcess
%==================================================================   
        function StitchFinishAcqProcess(obj,DataObj,log)
            obj.Recon.StitchFinishAcqProcess(DataObj,log);
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
        
%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            delete(obj.Recon);
        end   
        
    end
end