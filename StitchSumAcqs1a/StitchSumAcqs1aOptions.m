%==================================================================
% 
%==================================================================

classdef StitchSumAcqs1aOptions < handle

properties (SetAccess = private)                   
    StitchSupportingPath
    AcqInfoFile                     % Specify as file
    KernelFile = 'KBCw2b5p5ss1p6'
    Kernel
    InvFiltFile
    InvFilt
    ZeroFill
    Fov2Return = 'Design'          % {'All','Design',Values}
    CoilCombine = 'Super';          % {'Super','ReturnAll','Single};
    SuperProfRes = 10
    SuperProfFilt = 12
    Gpus2Use
    ImageType = 'complex'
    ImagePrecision = 'single'
    ReconTrajBlockSpecify = 'All'       % {'All',Values}
    ReconTrajBlockLength
    ReconTrajBlocksPerImage
    Matrix
    SubSampMatrix
    Fov
    SubSampFov
    IntensityScale = 'Default'      
end

methods 
   
%==================================================================
% Constructor
%==================================================================  
function obj = StitchSumAcqs1aOptions             
end

%==================================================================
% SetStitchSupportingPath
%==================================================================         
        function SetStitchSupportingPath(obj,val)
            obj.StitchSupportingPath = val;
        end  

%==================================================================
% SetAcqInfoFile
%==================================================================         
        function SetAcqInfoFile(obj,val)
            obj.AcqInfoFile = val;
        end  

%==================================================================
% SetCoilCombine
%==================================================================         
        function SetCoilCombine(obj,val)
            obj.CoilCombine = val;
        end         
        
%==================================================================
% SetFov2Return
%==================================================================         
        function SetFov2Return(obj,val)
            obj.Fov2Return = val;
        end        

%==================================================================
% SetGpus2Use
%==================================================================         
        function SetGpus2Use(obj,val)
            obj.Gpus2Use = val;
        end         
        
%==================================================================
% SetKernelFile
%==================================================================   
        function SetKernelFile(obj,val)
            obj.KernelFile = val;
        end          
        
%==================================================================
% SetZeroFill
%==================================================================   
        function SetZeroFill(obj,val)
            obj.ZeroFill = val;
        end           

%==================================================================
% SetSuperProf
%==================================================================   
        function SetSuperProf(obj,Res,Filt)
            obj.SuperProfRes = Res;
            obj.SuperProfFilt = Filt;
        end         

%==================================================================
% SetImageType
%==================================================================   
        function SetImageType(obj,val)
            obj.ImageType = val;
        end         

%==================================================================
% SetImagePrecision
%==================================================================   
        function SetImagePrecision(obj,val)
            obj.ImagePrecision = val;
        end        

%==================================================================
% SetReconTrajBlockLength
%==================================================================   
        function SetReconTrajBlockLength(obj,val)
            obj.ReconTrajBlockSpecify = val;
        end     

%==================================================================
% SetIntensityScale
%==================================================================   
        function SetIntensityScale(obj,val)
            obj.IntensityScale = val;
        end         
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,AcqInfo)   
            
            %------------------------------------------------------
            % Load Kernel
            %------------------------------------------------------
            if isempty(obj.StitchSupportingPath)
                loc = mfilename('fullpath');
                ind = strfind(loc,'Base');
                obj.StitchSupportingPath = [loc(1:ind+4),'Supporting',filesep]; 
            end
            load([obj.StitchSupportingPath,'Kernels',filesep,'Kern_',obj.KernelFile,'.mat']);
            obj.Kernel = saveData.KRNprms;

            %------------------------------------------------------
            % Test/Load InvFilt
            %------------------------------------------------------            
            obj.Matrix = AcqInfo.Fov/AcqInfo.Vox;
            SubSamp = obj.Kernel.DesforSS;
            obj.SubSampMatrix = SubSamp * obj.Matrix;
            obj.Fov = AcqInfo.Fov;
            obj.SubSampFov = AcqInfo.Fov * SubSamp;
            PossibleZeroFill = obj.Kernel.PossibleZeroFill;
            if isempty(obj.ZeroFill)
                ind = find(PossibleZeroFill > obj.SubSampMatrix,1,'first');
                obj.ZeroFill = PossibleZeroFill(ind);
            end
            if obj.ZeroFill < obj.SubSampMatrix
                error('Specified ZeroFill is too small');
            end
            obj.InvFiltFile = [obj.KernelFile,'zf',num2str(obj.ZeroFill),'S'];   
            load([obj.StitchSupportingPath,'InverseFilters',filesep,'IF_',obj.InvFiltFile,'.mat']);              
            obj.InvFilt = saveData.IFprms;
            
            %------------------------------------------------------
            % Test Gpus
            %------------------------------------------------------  
            GpuTot = gpuDeviceCount;
            if isempty(obj.Gpus2Use)
                obj.Gpus2Use = GpuTot;
            end
            if obj.Gpus2Use > GpuTot
                error('More Gpus than available have been specified');
            end

            %------------------------------------------------------
            % ReconTrajBlock
            %------------------------------------------------------  
            if strcmp(obj.ReconTrajBlockSpecify,'All')
                obj.ReconTrajBlockLength = AcqInfo.NumTraj;
            else
                obj.ReconTrajBlockLength = obj.ReconTrajBlockSpecify;
            end
            obj.ReconTrajBlocksPerImage = ceil(AcqInfo.NumTraj/obj.ReconTrajBlockLength); 
        end            
    end
end