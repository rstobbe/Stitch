%================================================================
%  
%================================================================

classdef StitchRecon < StitchFunctions

    properties (SetAccess = private)                    
        StitchMetaData;
        ReconInfoMat;
        Recon;
        ReconName;
    end
    methods 

        
%==================================================================
% Constructor
%==================================================================   
        function obj = StitchRecon()
            obj@StitchFunctions;
        end   

%==================================================================
% SetStitchMetaData
%==================================================================   
        function SetStitchMetaData(obj,Field,Value)
            obj.StitchMetaData.(Field) = Value;
        end        
 
%==================================================================
% SetStitchMetaDataStruct
%==================================================================          
        function SetStitchMetaDataStruct(obj,NewMetaData)
            fields = fieldnames(NewMetaData);
            for n = 1:length(fields)
                obj.StitchMetaData.(fields{n}) = NewMetaData.(fields{n});
            end
        end         
                
%==================================================================
% StitchFullInit
%==================================================================   
        function StitchFullInit(obj,log)   
            obj.UpdateReconInfo(log);
            if isobject(obj.Recon)
                delete(obj.Recon);
            end
            func = str2func(obj.StitchMetaData.ReconFunction);
            obj.Recon = func();
            obj.ReconName = obj.StitchMetaData.ReconFunction;
            if strcmp(obj.StitchMetaData.ReconBlockLength,'All') || strcmp(obj.StitchMetaData.ReconBlockLength,'all')
                sz = size(obj.ReconInfoMat);
                obj.StitchMetaData.ReconBlockLength = sz(2);
            end
            obj.StitchInit(log);
        end           
     
%==================================================================
% UpdateReconInfo
%==================================================================   
        function UpdateReconInfo(obj,log)
            if not(isfield(obj.StitchMetaData,'CoilCombine'))
                obj.StitchMetaData.CoilCombine = 'Super';
            end
            if not(isfield(obj.StitchMetaData,'StitchRelatedPath'))
                loc = mfilename('fullpath');
                ind = strfind(loc,'Base');
                obj.StitchMetaData.StitchRelatedPath = [loc(1:ind+4),'Supporting\']; 
            end
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
            GpuTot = gpuDeviceCount;
            if not(isfield(obj.StitchMetaData,'Gpus2Use'))
                obj.StitchMetaData.Gpus2Use = GpuTot;
            end
            if obj.StitchMetaData.Gpus2Use > GpuTot
                error('More Gpus than available have been specified');
            end
            obj.StitchMetaData.GpuTot = obj.StitchMetaData.Gpus2Use;
            if obj.StitchMetaData.GpuTot > obj.StitchMetaData.RxChannels
                obj.StitchMetaData.GpuTot = obj.StitchMetaData.RxChannels;
            end
            if not(isfield(obj.StitchMetaData,'ImageType'))
                obj.StitchMetaData.ImageType = 'complex';
            end
            if not(isfield(obj.StitchMetaData,'ImagePrecision'))
                obj.StitchMetaData.ImagePrecision = 'single';
            end
            if strcmp(obj.StitchMetaData.ImageType,'complex')
                if not(strcmp(obj.StitchMetaData.ImagePrecision,'single'))
                    error('Image must be single to be complex');
                end
            end
            if not(isfield(obj.StitchMetaData,'ReconBlockLength'))
                obj.StitchMetaData.ReconBlockLength = 'All';
            end
        end               
 
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)
            obj.Recon.StitchPostAcqProcess(obj,DataObj,log);
        end        
        
%==================================================================
% StitchIntraAcqProcess
%================================================================== 
        function StitchIntraAcqProcess(obj,DataObj,log)
            obj.Recon.StitchIntraAcqProcess(DataObj,log);
        end 

%==================================================================
% StitchFinishAcqProcess
%==================================================================   
        function StitchFinishAcqProcess(obj,DataObj,log)
            obj.Recon.StitchFinishAcqProcess(DataObj,log);
        end          
                
%==================================================================
% LoadTrajectoryLocal 
%==================================================================   
        function LoadTrajectoryLocal(obj,log)
            %log.info('Retreive Trajectory Info From HardDrive');
            warning 'off';                                  % because tries to find functions not on path
            load(obj.StitchMetaData.TrajFile);
            warning 'on';
            IMP = saveData.IMP;
            %-------------------------------
            % compatability check here
            %-------------------------------
            obj.ReconInfoMat = IMP.ReconInfoMat;            % in future not from here
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
        
%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            obj.StitchFreeGpuMemory;
        end   
        
    end
end