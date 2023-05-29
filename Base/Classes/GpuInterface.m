classdef GpuInterface < handle

    properties (SetAccess = private)                    
        GpuParams; CompCap; NumGpuUsed; ChanPerGpu;       
        HSampDat; SampDatMemDims;
        HReconInfo; ReconInfoMemDims;
        HKernel; iKern; KernHw; KernelMemDims; ConvScaleVal;
        HPhaseImage;
        HKspaceMatrix;
        HImageMatrix; ImageMatrixMemDims;
        HImageRetFovMatrix; ImageRetFovMatrixMemDims; 
        HTempMatrix;
        HFourierTransformPlan;
        HInvFilt;
        HSuperFilt; HSuperLow; HSuperLowConj; HSuperLowSoS; HSuperHighSoS;        
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function obj = GpuInterface()           
        end        
        
%==================================================================
% GpuInit
%==================================================================   
        function GpuInit(obj,Gpus2Use)
            obj.GpuParams = gpuDevice; 
            obj.NumGpuUsed = uint64(Gpus2Use);
            obj.CompCap = num2str(round(str2double(obj.GpuParams.ComputeCapability)*10));
        end

%==================================================================
% SetChanPerGpu
%==================================================================           
        function SetChanPerGpu(obj,ChanPerGpu)
            obj.ChanPerGpu = ChanPerGpu;
        end

%==================================================================
% SetupFourierTransform
%   - All GPUs
%==================================================================         
        function SetupFourierTransform(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            func = str2func(['CreateFourierTransformPlanAllGpu',obj.CompCap]);
            [obj.HFourierTransformPlan,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end
        
%==================================================================
% ReleaseFourierTransform
%   - All GPUs
%==================================================================         
        function ReleaseFourierTransform(obj)
            func = str2func(['TeardownFourierTransformPlanAllGpu',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HFourierTransformPlan);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HFourierTransformPlan = [];
        end        
      
%==================================================================
% LoadKernelGpuMem
%   - All GPUs
%================================================================== 
        function LoadKernelGpuMem(obj,Kernel,iKern,KernHw,ConvScaleVal)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end
            if ~isreal(Kernel)
                error('Kernel must be real');
            end  
            obj.ConvScaleVal = ConvScaleVal;
            obj.iKern = uint64(iKern);
            obj.KernHw = uint64(KernHw);
            sz = size(Kernel);
            obj.KernelMemDims = uint64(sz);
            func = str2func(['AllocateLoadRealMatrixAllGpuMem',obj.CompCap]);
            [obj.HKernel,Error] = func(obj.NumGpuUsed,Kernel);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% LoadComplexKernelGpuMem
%   - All GPUs
%================================================================== 
        function LoadComplexKernelGpuMem(obj,Kernel,iKern,KernHw,ConvScaleVal)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end
            if isreal(Kernel)
                error('Kernel must be complex');
            end            
            obj.ConvScaleVal = ConvScaleVal;
            obj.iKern = uint64(iKern);
            obj.KernHw = uint64(KernHw);
            sz = size(Kernel);
            obj.KernelMemDims = uint64(sz);
            func = str2func(['AllocateLoadComplexMatrixAllGpuMem',obj.CompCap]);
            [obj.HKernel,Error] = func(obj.NumGpuUsed,Kernel);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% LoadCorniceKernelGpuMem
%   - All GPUs
%================================================================== 
        function LoadCorniceKernelGpuMem(obj,Kernel,iKern,KernHw,ConvScaleVal)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end
            if isreal(Kernel)
                error('Kernel must be complex');
            end            
            obj.ConvScaleVal = ConvScaleVal;
            obj.iKern = uint64(iKern);
            obj.KernHw = uint64(KernHw);
            sz = size(Kernel);
            obj.KernelMemDims = uint64(sz(1:3));
            func = str2func(['AllocateLoadComplexMatrixSingleGpuMem',obj.CompCap]);
            obj.HKernel = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = uint64(m-1);
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    if ChanNum > sz(4)
                        error;
                    end
                    [obj.HKernel(p,m),Error] = func(GpuNum,complex(Kernel(:,:,:,ChanNum)));    
                    %[obj.HKernel(p,m),Error] = func(GpuNum,Kernel(:,:,:,ChanNum));                   
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
            end
        end          

%==================================================================
% AllocateLoadComplexImages
%================================================================== 
        function AllocateLoadComplexImages(obj,Image)
            if ~isa(Image,'single')
                error('Image must be in single format');
            end
            if isreal(Image)
                error('Image must be complex');
            end            
            sz = size(Image);
            obj.ImageMatrixMemDims = uint64(sz(1:3));
            func = str2func(['AllocateLoadComplexMatrixSingleGpuMem',obj.CompCap]);
            obj.HImageMatrix = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = uint64(m-1);
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    if ChanNum > sz(4)
                        error('Image array greater than number of channels specified');
                    end
                    [obj.HImageMatrix(p,m),Error] = func(GpuNum,Image(:,:,:,ChanNum));                  
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
            end
        end          

%==================================================================
% AllocateInitializeRetFovImages
%   - input = array of 3 dimension sizes
%==================================================================                      
        function AllocateInitializeRetFovImages(obj,ImageRetFovMatrixMemDims)
            obj.ImageRetFovMatrixMemDims = uint64(ImageRetFovMatrixMemDims);
            obj.HImageRetFovMatrix = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            func = str2func(['AllocateInitializeComplexMatrixAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [obj.HImageRetFovMatrix(n,:),Error] = func(obj.NumGpuUsed,obj.ImageRetFovMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    MaxChanPerGpu = n
                    error(Error);
                end
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% AllocateStaticPhaseImageGpuMem
%   - Diffusion context
%   - Only need one per GPU 
%   - rewritten for each trajectory 
%================================================================== 
        function AllocateStaticPhaseImageGpuMem(obj)    
            obj.HPhaseImage = zeros(obj.NumGpuUsed,'uint64');
            func = str2func(['AllocateComplexMatrixAllGpuMem',obj.CompCap]);
            [obj.HPhaseImage,Error] = func(obj.NumGpuUsed,obj.KernelMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% LoadStaticPhaseImageGpuMem
%   - Diffusion context
%   - Load a StatcPhaseImage for each trajectory
%================================================================== 
        function LoadComplexPhaseImageGpuMem(obj,PhaseImage)
%             sz = size(PhaseImage);
%             if sz(1) ~= obj.KernelMemDims
%                 error('Phase image must be same dimensions as Kernel');
%             end
%             func = str2func(['LoadComplexMatrixAllGpuMem',obj.CompCap]);
%             [Error] = func(...stuff... PhaseImage);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
        end         
        
%==================================================================
% FreeKernelGpuMem
%================================================================== 
        function FreeKernelGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HKernel);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HKernel = [];
        end          
        
%==================================================================
% LoadInvFiltGpuMem
%   - All GPUs
%================================================================== 
        function LoadInvFiltGpuMem(obj,InvFilt)
            if ~isa(InvFilt,'single')
                error('InvFilt must be in single format');
            end 
            sz = size(InvFilt);
            obj.ImageMatrixMemDims = uint64(sz);
            func = str2func(['AllocateLoadRealMatrixAllGpuMem',obj.CompCap]);
            [obj.HInvFilt,Error] = func(obj.NumGpuUsed,InvFilt);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% FreeInvFiltGpuMem
%================================================================== 
        function FreeInvFiltGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HInvFilt);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HInvFilt = [];
        end          
        
%==================================================================
% LoadSuperFiltGpuMem
%   - All GPUs
%================================================================== 
        function LoadSuperFiltGpuMem(obj,SuperFilt)
            if ~isa(SuperFilt,'single')
                error('SuperFilt must be in single format');
            end 
            sz = size(SuperFilt);
            obj.ImageMatrixMemDims = uint64(sz);
            func = str2func(['AllocateLoadRealMatrixAllGpuMem',obj.CompCap]);
            [obj.HSuperFilt,Error] = func(obj.NumGpuUsed,SuperFilt);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% FreeSuperFiltGpuMem
%================================================================== 
        function FreeSuperFiltGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HSuperFilt);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HSuperFilt = [];
        end        
        
%==================================================================
% AllocateReconInfoGpuMem
%   - ReconInfoMemDims: array of 3 (read x proj x 4 [x,y,z,sdc])
%   - function allocates ReconInfo space on all GPUs
%================================================================== 
        function AllocateReconInfoGpuMem(obj,ReconInfoMemDims)    
            if ReconInfoMemDims(3) ~= 4
                error('ReconInfo dimensionality problem');  
            end
            obj.ReconInfoMemDims = uint64(ReconInfoMemDims);
            func = str2func(['AllocateReconInfoGpuMem',obj.CompCap]);
            [obj.HReconInfo,Error] = func(obj.NumGpuUsed,obj.ReconInfoMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% FreeReconInfoGpuMem
%================================================================== 
        function FreeReconInfoGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HReconInfo);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HReconInfo = [];
        end          
              
%==================================================================
% LoadReconInfoGpuMem
%   - kMat -> already normalized
%   - ReconInfo: read x proj x 4 [x,y,z,sdc]
%   - function loads ReconInfo on all GPUs
%================================================================== 
        function LoadReconInfoGpuMem(obj,ReconInfo)
            if ~isa(ReconInfo,'single')
                error('ReconInfo must be in single format');
            end       
            sz = size(ReconInfo);
            for n = 1:length(sz)
                if sz(n) ~= obj.ReconInfoMemDims(n)
                    error('ReconInfo dimensionality problem');  
                end
            end
            func = str2func(['LoadReconInfoGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end   

%==================================================================
% LoadReconInfoGpuMemAsync
%   - kMat -> already normalized
%   - ReconInfo: read x proj x 4 [x,y,z,sdc]
%   - function loads ReconInfo on all GPUs
%================================================================== 
        function LoadReconInfoGpuMemAsync(obj,ReconInfo)
            if ~isa(ReconInfo,'single')
                error('ReconInfo must be in single format');
            end       
            sz = size(ReconInfo);
            for n = 1:length(sz)
                if sz(n) ~= obj.ReconInfoMemDims(n)
                    error('ReconInfo dimensionality problem');  
                end
            end
            func = str2func(['LoadReconInfoGpuMemAsync',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% AllocateSampDatGpuMem
%   - SampDatMemDims: array of 2 (read x proj)
%   - function allocates SampDat space on all GPUs
%================================================================== 
        function AllocateSampDatGpuMem(obj,SampDatMemDims)    
            for n = 1:length(SampDatMemDims)
                if isempty(obj.ReconInfoMemDims)
                    error('AllocateReconInfoGpuMem first');
                end
                if SampDatMemDims(n) ~= obj.ReconInfoMemDims(n)
                    error('SampDat dimensionality problem');  
                end
            end
            obj.SampDatMemDims = uint64(SampDatMemDims);
            obj.HSampDat = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            func = str2func(['AllocateSampDatGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [obj.HSampDat(n,:),Error] = func(obj.NumGpuUsed,obj.SampDatMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end  

%==================================================================
% FreeSampDatGpuMem
%================================================================== 
        function FreeSampDatGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [Error] = func(obj.NumGpuUsed,obj.HSampDat(n,:));
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            obj.HSampDat = [];
        end       
        
%==================================================================
% LoadSampDatGpuMemAsync
%   - SampDat: read x proj
%   - function loads SampDat on one GPU asynchronously
%================================================================== 
        function LoadSampDatGpuMemAsync(obj,LoadGpuNum,GpuChanNum,SampDat)
            if LoadGpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            LoadGpuNum = uint64(LoadGpuNum);
            if ~isa(SampDat,'single')
                error('SampDat must be in single format');
            end
            func = str2func(['LoadSampDatGpuMemAsyncRI',obj.CompCap]);
            [Error] = func(LoadGpuNum,obj.HSampDat(GpuChanNum,:),SampDat);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end       
        
%==================================================================
% AllocateKspaceImageMatricesGpuMem
%   - input = array of 3 dimension sizes
%==================================================================                      
        function AllocateKspaceImageMatricesGpuMem(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            obj.HKspaceMatrix = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            obj.HImageMatrix = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            func = str2func(['AllocateInitializeComplexMatrixAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [obj.HImageMatrix(n,:),Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    MaxChanPerGpu = n
                    error(Error);
                end
                [obj.HKspaceMatrix(n,:),Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    MaxChanPerGpu = n
                    error(Error);
                end
            end
            [obj.HTempMatrix,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% AllocateKspaceMatricesGpuMem
%   - input = array of 3 dimension sizes
%==================================================================                      
        function AllocateKspaceMatricesGpuMem(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            obj.HKspaceMatrix = zeros([obj.ChanPerGpu,obj.NumGpuUsed],'uint64');
            func = str2func(['AllocateInitializeComplexMatrixAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [obj.HKspaceMatrix(n,:),Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    MaxChanPerGpu = n
                    error(Error);
                end
            end
        end          
        
%==================================================================
% AllocateKspaceImageMatricesCorniceGpuMem
%   - input = array of 3 dimension sizes
%==================================================================                      
        function AllocateKspaceImageMatricesCorniceGpuMem(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            func = str2func(['AllocateInitializeComplexMatrixAllGpuMem',obj.CompCap]);
            [obj.HImageMatrix,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [obj.HKspaceMatrix,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [obj.HTempMatrix,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end             
        
%==================================================================
% InitializeKspaceMatricesGpuMem
%==================================================================                      
        function InitializeKspaceMatricesGpuMem(obj)
            obj.HKspaceMatrix = zeros([obj.NumGpuUsed,obj.NumGpuUsed],'uint64');
            func = str2func(['InitializeComplexMatrixAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [Error] = func(obj.NumGpuUsed,obj.HKspaceMatrix(n,:),obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end    

%==================================================================
% FreeKspaceImageMatricesGpuMem
%==================================================================                      
        function FreeKspaceImageMatricesGpuMem(obj)
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [Error] = func(obj.NumGpuUsed,obj.HImageMatrix(n,:));
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [Error] = func(obj.NumGpuUsed,obj.HKspaceMatrix(n,:));
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            [Error] = func(obj.NumGpuUsed,obj.HTempMatrix);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HImageMatrix = [];
            obj.HKspaceMatrix = [];
            obj.HTempMatrix = [];
        end    
        
%==================================================================
% FreeKspaceImageMatricesCorniceGpuMem
%==================================================================                      
        function FreeKspaceImageMatricesCorniceGpuMem(obj)
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HImageMatrix);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func(obj.NumGpuUsed,obj.HKspaceMatrix);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func(obj.NumGpuUsed,obj.HTempMatrix);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HImageMatrix = [];
            obj.HKspaceMatrix = [];
            obj.HTempMatrix = [];
        end           

%==================================================================
% FreeImageMatricesGpuMem
%==================================================================                      
        function FreeImageMatricesGpuMem(obj)
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            for n = 1:obj.ChanPerGpu
                [Error] = func(obj.NumGpuUsed,obj.HImageMatrix(n,:));
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HImageMatrix = [];
        end          
        
%==================================================================
% AllocateSuperMatricesGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateSuperMatricesGpuMem(obj)
            func = str2func(['AllocateInitializeComplexMatrixAllGpuMem',obj.CompCap]);
            [obj.HSuperLow,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [obj.HSuperLowConj,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [obj.HSuperLowSoS,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [obj.HSuperHighSoS,Error] = func(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% FreeSuperMatricesGpuMem
%================================================================== 
        function FreeSuperMatricesGpuMem(obj)    
            func = str2func(['FreeAllGpuMem',obj.CompCap]);
            [Error] = func(obj.NumGpuUsed,obj.HSuperLow);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func(obj.NumGpuUsed,obj.HSuperLowConj);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func(obj.NumGpuUsed,obj.HSuperLowSoS);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func(obj.NumGpuUsed,obj.HSuperHighSoS);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            obj.HSuperLow = [];
            obj.HSuperLowConj = [];
            obj.HSuperLowSoS = [];
            obj.HSuperHighSoS = [];
        end        
        
%==================================================================
% GridSampDat
%==================================================================                      
        function GridSampDat(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['GridSampDat',obj.CompCap]);
            [Error] = func(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel,obj.HKspaceMatrix(GpuChanNum,:),...
                                    obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end            

%==================================================================
% GridSampDatFullKern
%==================================================================                      
        function GridSampDatFullKern(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['GridSampDatFullKern',obj.CompCap]);
            [Error] = func(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel,obj.HKspaceMatrix(GpuChanNum,:),...
                                    obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% GridSampDatComplexKern
%==================================================================                      
        function GridSampDatComplexKern(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['GridSampDatComplexKern',obj.CompCap]);
            [Error] = func(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel,obj.HKspaceMatrix(GpuChanNum,:),...
                                    obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% GridSampDatCornice
%==================================================================                      
        function GridSampDatCornice(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['GridSampDatComplexKern',obj.CompCap]);
%------------------------  Separate Images ---------         
%             [Error] = func(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),...
%                                     obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
%---------------------------------------------------   
            [Error] = func(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel(GpuChanNum,:),obj.HKspaceMatrix(1,:),...
                                    obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% ReturnOneKspaceMatrixGpuMem
%================================================================== 
        function KspaceMatrix = ReturnOneKspaceMatrixGpuMem(obj,TestGpuNum,GpuChanNum)
            if TestGpuNum > obj.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            func = str2func(['ReturnComplexMatrixSingleGpu',obj.CompCap]);
            [KspaceMatrix,Error] = func(TestGpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 
        
%==================================================================
% ReturnOneImageMatrixGpuMem
%================================================================== 
        function ImageMatrix = ReturnOneImageMatrixGpuMem(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ReturnComplexMatrixSingleGpu',obj.CompCap]);
            [ImageMatrix,Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 

%==================================================================
% ReturnOneImageRetFovMatrixGpuMem
%================================================================== 
        function ImageRetFovMatrix = ReturnOneImageRetFovMatrixGpuMem(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ReturnComplexMatrixSingleGpu',obj.CompCap]);
            [ImageRetFovMatrix,Error] = func(GpuNum,obj.HImageRetFovMatrix(GpuChanNum,:),obj.ImageRetFovMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% ReturnOneRealMatrixGpuMemSpecify
%================================================================== 
        function ImageMatrix = ReturnOneRealMatrixGpuMemSpecify(obj,ImageMatrix,GpuNum,Image)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ReturnRealMatrixSingleGpu',obj.CompCap]);
            [ImageMatrix,Error] = func(GpuNum,Image,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% ReturnOneImageMatrixGpuMemSpecify
%================================================================== 
        function ImageMatrix = ReturnOneImageMatrixGpuMemSpecify(obj,GpuNum,Image)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ReturnComplexMatrixSingleGpu',obj.CompCap]);
            [ImageMatrix,Error] = func(GpuNum,Image,obj.ImageMatrixMemDims);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% KspaceFourierTransformShift
%==================================================================         
        function KspaceFourierTransformShift(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['FourierTransformShiftSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end     

%==================================================================
% ImageFourierTransformShift
%==================================================================         
        function ImageFourierTransformShift(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['FourierTransformShiftSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
 
%==================================================================
% ImageFourierTransformShiftSpecify
%==================================================================         
        function ImageFourierTransformShiftSpecify(obj,GpuNum,Image)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['FourierTransformShiftSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,Image,obj.HTempMatrix,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% InverseFourierTransform
%==================================================================         
        function InverseFourierTransform(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ExecuteInverseFourierTransformSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 
        
%==================================================================
% InverseFourierTransformSpecify
%==================================================================         
        function InverseFourierTransformSpecify(obj,GpuNum,Image,Kspace)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ExecuteInverseFourierTransformSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,Image,Kspace,obj.HFourierTransformPlan,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% FourierTransform
%==================================================================         
        function FourierTransform(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ExecuteFourierTransformSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% FourierTransformSpecify
%==================================================================         
        function FourierTransformSpecify(obj,GpuNum,Image,Kspace)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['ExecuteFourierTransformSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,Image,Kspace,obj.HFourierTransformPlan);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% MultInvFilt
%==================================================================         
        function MultInvFilt(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['DivideComplexMatrixRealMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HInvFilt,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% SuperKspaceFilter
%==================================================================         
        function SuperKspaceFilter(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['MultiplyComplexMatrixRealMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HSuperFilt,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% KspaceScaleCorrect
%==================================================================         
        function KspaceScaleCorrect(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(1/obj.ConvScaleVal);
            func = str2func(['ScaleComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% ScaleImage
%==================================================================         
        function ScaleImage(obj,GpuNum,GpuChanNum,Scale)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(Scale);
            func = str2func(['ScaleComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% ScaleImageSpecify
%==================================================================         
        function ScaleImageSpecify(obj,GpuNum,Image,Scale)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(Scale);
            func = str2func(['ScaleComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,Image,Scale,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% CreateLowImageConjugate
%==================================================================         
        function CreateLowImageConjugate(obj,GpuNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func1 = str2func(['CopyComplexMatrixSingleGpuMemAsync',obj.CompCap]);
            func2 = str2func(['ConjugateComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func1(GpuNum,obj.HSuperLowConj,obj.HSuperLow,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
            [Error] = func2(GpuNum,obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end           
 
%==================================================================
% BuildLowSosImage
%==================================================================         
        function BuildLowSosImage(obj,GpuNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['MultiplyAccumComplexMatrixComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HSuperLowSoS,obj.HSuperLow,obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% BuildHighSosImage
%==================================================================         
        function BuildHighSosImage(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['MultiplyAccumComplexMatrixComplexMatrixSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HSuperHighSoS,obj.HImageMatrix(GpuChanNum,:),obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% ReturnFov
%==================================================================         
        function ReturnFov(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            Inset = uint64((obj.ImageMatrixMemDims(1) - obj.ImageRetFovMatrixMemDims(1))/2);
            GpuNum = uint64(GpuNum);
            func = str2func(['ReturnFovSingleGpu',obj.CompCap]);
            [Error] = func(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HImageRetFovMatrix(GpuChanNum,:),obj.ImageMatrixMemDims,obj.ImageRetFovMatrixMemDims,Inset);  
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% CudaDeviceWait
%================================================================== 
        function CudaDeviceWait(obj,GpuNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            func = str2func(['CudaDeviceWait',obj.CompCap]);
            [Error] = func(GpuNum);
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end
                
    end
end

        