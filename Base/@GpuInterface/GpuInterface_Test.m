classdef GpuInterface < handle

    properties (SetAccess = private)                    
        GpuParams; NumGpuUsed; ChanPerGpu;       
        HSampDat; SampDatMemDims;
        HReconInfo; ReconInfoMemDims;
        HKernel; iKern; KernHw; KernelMemDims; ConvScaleVal;
        HKspaceMatrix;
        HImageMatrix; ImageMatrixMemDims;
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
% Init
%==================================================================   
        function InitGpuInterface(obj,NumGpuUsed,GpuParams,ChanPerGpu)
            obj.NumGpuUsed = uint64(NumGpuUsed);
            obj.GpuParams = GpuParams;
            obj.ChanPerGpu = ChanPerGpu;
        end

%==================================================================
% SetupFourierTransform
%   - All GPUs
%==================================================================         
        function SetupFourierTransform(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HFourierTransformPlan,Error] = CreateFourierTransformPlanAllGpu75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [obj.HFourierTransformPlan,Error] = CreateFourierTransformPlanAllGpu61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end
      
%==================================================================
% LoadKernelGpuMem
%   - All GPUs
%================================================================== 
        function LoadKernelGpuMem(obj,Kernel,iKern,KernHw,ConvScaleVal)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end
            obj.ConvScaleVal = ConvScaleVal;
            obj.iKern = uint64(iKern);
            obj.KernHw = uint64(KernHw);
            sz = size(Kernel);
            obj.KernelMemDims = uint64(sz);
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HKernel,Error] = AllocateLoadRealMatrixAllGpuMem75(obj.NumGpuUsed,Kernel);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1 
                [obj.HKernel,Error] = AllocateLoadRealMatrixAllGpuMem61(obj.NumGpuUsed,Kernel);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HInvFilt,Error] = AllocateLoadRealMatrixAllGpuMem75(obj.NumGpuUsed,InvFilt);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1 
                [obj.HInvFilt,Error] = AllocateLoadRealMatrixAllGpuMem61(obj.NumGpuUsed,InvFilt);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HSuperFilt,Error] = AllocateLoadRealMatrixAllGpuMem75(obj.NumGpuUsed,SuperFilt);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1 
                [obj.HSuperFilt,Error] = AllocateLoadRealMatrixAllGpuMem61(obj.NumGpuUsed,SuperFilt);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HReconInfo,Error] = AllocateReconInfoGpuMem75(obj.NumGpuUsed,obj.ReconInfoMemDims);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [obj.HReconInfo,Error] = AllocateReconInfoGpuMem61(obj.NumGpuUsed,obj.ReconInfoMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% FreeReconInfoGpuMem
%================================================================== 
        function FreeReconInfoGpuMem(obj)    
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = FreeAllGpuMem75(obj.NumGpuUsed,obj.HReconInfo);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = FreeAllGpuMem61(obj.NumGpuUsed,obj.HReconInfo);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadReconInfoGpuMem75(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadReconInfoGpuMem61(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadReconInfoGpuMemAsync75(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadReconInfoGpuMemAsync61(obj.NumGpuUsed,obj.HReconInfo,ReconInfo);
            end
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
            obj.HSampDat = zeros([obj.NumGpuUsed,obj.NumGpuUsed],'uint64');
            for n = 1:obj.ChanPerGpu
                if str2double(obj.GpuParams.ComputeCapability) == 7.5
                    [obj.HSampDat(n,:),Error] = AllocateSampDatGpuMem75(obj.NumGpuUsed,obj.SampDatMemDims);
                elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                    [obj.HSampDat(n,:),Error] = AllocateSampDatGpuMem61(obj.NumGpuUsed,obj.SampDatMemDims);
                end
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end  

%==================================================================
% FreeSampDatGpuMem
%================================================================== 
        function FreeSampDatGpuMem(obj)    
            for n = 1:obj.ChanPerGpu
                if str2double(obj.GpuParams.ComputeCapability) == 7.5
                    [Error] = FreeAllGpuMem75(obj.NumGpuUsed,obj.HSampDat(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                    [Error] = FreeAllGpuMem61(obj.NumGpuUsed,obj.HSampDat(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadSampDatGpuMemAsyncRI75(LoadGpuNum,obj.HSampDat(GpuChanNum,:),SampDat);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadSampDatGpuMemAsyncRI61(LoadGpuNum,obj.HSampDat(GpuChanNum,:),SampDat);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end       
        
%==================================================================
% AllocateKspaceImageMatricesGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateKspaceImageMatricesGpuMem(obj,ImageMatrixMemDims)
            obj.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            obj.HKspaceMatrix = zeros([obj.NumGpuUsed,obj.NumGpuUsed],'uint64');
            obj.HImageMatrix = zeros([obj.NumGpuUsed,obj.NumGpuUsed],'uint64');
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                for n = 1:obj.ChanPerGpu
                    [obj.HImageMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [obj.HKspaceMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [obj.HTempMatrix,Error] = AllocateComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                for n = 1:obj.ChanPerGpu
                    [obj.HImageMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [obj.HKspaceMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [obj.HTempMatrix,Error] = AllocateComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end          

%==================================================================
% FreeKspaceImageMatricesGpuMem
%==================================================================                      
        function FreeKspaceImageMatricesGpuMem(obj)
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                for n = 1:obj.ChanPerGpu
                    [Error] = FreeAllGpuMem75(obj.NumGpuUsed,obj.HImageMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [Error] = FreeAllGpuMem75(obj.NumGpuUsed,obj.HKspaceMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [Error] = FreeAllGpuMem75(obj.NumGpuUsed,obj.HTempMatrix);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                for n = 1:obj.ChanPerGpu
                    [Error] = FreeAllGpuMem61(obj.NumGpuUsed,obj.HImageMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [Error] = FreeAllGpuMem61(obj.NumGpuUsed,obj.HKspaceMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [Error] = FreeAllGpuMem61(obj.NumGpuUsed,obj.HTempMatrix);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            obj.HImageMatrix = [];
            obj.HKspaceMatrix = [];
            obj.HTempMatrix = [];
        end         

%==================================================================
% AllocateSuperMatricesGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateSuperMatricesGpuMem(obj)
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [obj.HSuperLow,Error] = AllocateComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperLowConj,Error] = AllocateComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperLowSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperHighSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem75(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [obj.HSuperLow,Error] = AllocateComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperLowConj,Error] = AllocateComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperLowSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [obj.HSuperHighSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem61(obj.NumGpuUsed,obj.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end        
        
%==================================================================
% GridSampDat
%==================================================================                      
        function GridSampDat(obj,GpuNum,GpuChanNum)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = GridSampDat75(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel,obj.HKspaceMatrix(GpuChanNum,:),...
                                        obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = GridSampDat61(GpuNum,obj.HSampDat(GpuChanNum,:),obj.HReconInfo,obj.HKernel,obj.HKspaceMatrix(GpuChanNum,:),...
                                        obj.SampDatMemDims,obj.KernelMemDims,obj.ImageMatrixMemDims,obj.iKern,obj.KernHw);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [KspaceMatrix,Error] = ReturnComplexMatrixSingleGpu75(TestGpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [KspaceMatrix,Error] = ReturnComplexMatrixSingleGpu61(TestGpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 

%==================================================================
% ReturnOneImageMatrixGpuMemSpecify
%================================================================== 
        function ImageMatrix = ReturnOneImageMatrixGpuMemSpecify(obj,ImageMatrix,GpuNum,Image)
            if GpuNum > obj.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu75(GpuNum,Image,obj.ImageMatrixMemDims);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu61(GpuNum,Image,obj.ImageMatrixMemDims);
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HTempMatrix,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,Image,obj.HTempMatrix,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,Image,obj.HTempMatrix,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteInverseFourierTransformSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteInverseFourierTransformSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteInverseFourierTransformSingleGpu75(GpuNum,Image,Kspace,obj.HFourierTransformPlan,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteInverseFourierTransformSingleGpu61(GpuNum,Image,Kspace,obj.HFourierTransformPlan,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteFourierTransformSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteFourierTransformSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HKspaceMatrix(GpuChanNum,:),obj.HFourierTransformPlan);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteFourierTransformSingleGpu75(GpuNum,Image,Kspace,obj.HFourierTransformPlan);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteFourierTransformSingleGpu61(GpuNum,Image,Kspace,obj.HFourierTransformPlan);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = DivideComplexMatrixRealMatrixSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HInvFilt,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = DivideComplexMatrixRealMatrixSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),obj.HInvFilt,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyComplexMatrixRealMatrixSingleGpu75(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HSuperFilt,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyComplexMatrixRealMatrixSingleGpu61(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),obj.HSuperFilt,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,obj.HKspaceMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,obj.HImageMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,obj.HImageMatrix(GpuChanNum,:),Scale,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,Image,Scale,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,Image,Scale,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = CopyComplexMatrixSingleGpuMemAsync75(GpuNum,obj.HSuperLowConj,obj.HSuperLow,obj.ImageMatrixMemDims);  
                [Error] = ConjugateComplexMatrixSingleGpu75(GpuNum,obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = CopyComplexMatrixSingleGpuMemAsync61(GpuNum,obj.HSuperLowConj,obj.HSuperLow,obj.ImageMatrixMemDims);  
                [Error] = ConjugateComplexMatrixSingleGpu61(GpuNum,obj.HSuperLowConj,obj.ImageMatrixMemDims);   
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu75(GpuNum,obj.HSuperLowSoS,obj.HSuperLow,obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu61(GpuNum,obj.HSuperLowSoS,obj.HSuperLow,obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu75(GpuNum,obj.HSuperHighSoS,obj.HImageMatrix(GpuChanNum,:),obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu61(GpuNum,obj.HSuperHighSoS,obj.HImageMatrix(GpuChanNum,:),obj.HSuperLowConj,obj.ImageMatrixMemDims);  
            end
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
            if str2double(obj.GpuParams.ComputeCapability) == 7.5
                [Error] = CudaDeviceWait75(GpuNum);
            elseif str2double(obj.GpuParams.ComputeCapability) == 6.1
                [Error] = CudaDeviceWait61(GpuNum);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end
                
    end
end




% %==================================================================
% % TestKernelInGpuMem
% %   - Remember first GPU = 0
% %================================================================== 
%         function Kernel = TestKernelInGpuMem(obj,TestGpuNum)
%             if TestGpuNum > obj.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [Kernel,Error] = TestKernelInGpuMem(TestGpuNum,obj.HKernel,obj.KernelMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end       
%         
% %==================================================================
% % TestReconInfoInGpuMem
% %   - Remember first GPU = 0
% %================================================================== 
%         function ReconInfo = TestReconInfoInGpuMem(obj,TestGpuNum)
%             if TestGpuNum > obj.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [ReconInfo,Error] = TestReconInfoInGpuMem(TestGpuNum,obj.HReconInfo,obj.ReconInfoMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end        
% 
% %==================================================================
% % TestSampDatInGpuMem
% %   - Remember first GPU = 0
% %================================================================== 
%         function SampDat = TestSampDatInGpuMem(obj,TestGpuNum)
%             if TestGpuNum > obj.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [SampDat,Error] = TestSampDatInGpuMem(TestGpuNum,obj.HSampDat,obj.SampDatMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end 
        