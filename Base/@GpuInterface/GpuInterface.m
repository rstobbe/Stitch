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
        function RECON = GpuInterface()
        end        
        
%==================================================================
% Init
%==================================================================   
        function InitGpuInterface(RECON,NumGpuUsed,GpuParams,ChanPerGpu)
            RECON.NumGpuUsed = uint64(NumGpuUsed);
            RECON.GpuParams = GpuParams;
            RECON.ChanPerGpu = ChanPerGpu;
        end

%==================================================================
% SetupFourierTransform
%   - All GPUs
%==================================================================         
        function SetupFourierTransform(RECON,ImageMatrixMemDims)
            RECON.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HFourierTransformPlan,Error] = CreateFourierTransformPlanAllGpu75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [RECON.HFourierTransformPlan,Error] = CreateFourierTransformPlanAllGpu61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end
      
%==================================================================
% LoadKernelGpuMem
%   - All GPUs
%================================================================== 
        function LoadKernelGpuMem(RECON,Kernel,iKern,KernHw,ConvScaleVal)
            if ~isa(Kernel,'single')
                error('Kernel must be in single format');
            end
            RECON.ConvScaleVal = ConvScaleVal;
            RECON.iKern = uint64(iKern);
            RECON.KernHw = uint64(KernHw);
            sz = size(Kernel);
            RECON.KernelMemDims = uint64(sz);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HKernel,Error] = AllocateLoadRealMatrixAllGpuMem75(RECON.NumGpuUsed,Kernel);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1 
                [RECON.HKernel,Error] = AllocateLoadRealMatrixAllGpuMem61(RECON.NumGpuUsed,Kernel);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% LoadInvFiltGpuMem
%   - All GPUs
%================================================================== 
        function LoadInvFiltGpuMem(RECON,InvFilt)
            if ~isa(InvFilt,'single')
                error('InvFilt must be in single format');
            end 
            sz = size(InvFilt);
            RECON.ImageMatrixMemDims = uint64(sz);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HInvFilt,Error] = AllocateLoadRealMatrixAllGpuMem75(RECON.NumGpuUsed,InvFilt);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1 
                [RECON.HInvFilt,Error] = AllocateLoadRealMatrixAllGpuMem61(RECON.NumGpuUsed,InvFilt);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% LoadSuperFiltGpuMem
%   - All GPUs
%================================================================== 
        function LoadSuperFiltGpuMem(RECON,SuperFilt)
            if ~isa(SuperFilt,'single')
                error('SuperFilt must be in single format');
            end 
            sz = size(SuperFilt);
            RECON.ImageMatrixMemDims = uint64(sz);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HSuperFilt,Error] = AllocateLoadRealMatrixAllGpuMem75(RECON.NumGpuUsed,SuperFilt);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1 
                [RECON.HSuperFilt,Error] = AllocateLoadRealMatrixAllGpuMem61(RECON.NumGpuUsed,SuperFilt);
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
        function AllocateReconInfoGpuMem(RECON,ReconInfoMemDims)    
            if ReconInfoMemDims(3) ~= 4
                error('ReconInfo dimensionality problem');  
            end
            RECON.ReconInfoMemDims = uint64(ReconInfoMemDims);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HReconInfo,Error] = AllocateReconInfoGpuMem75(RECON.NumGpuUsed,RECON.ReconInfoMemDims);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [RECON.HReconInfo,Error] = AllocateReconInfoGpuMem61(RECON.NumGpuUsed,RECON.ReconInfoMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% FreeReconInfoGpuMem
%================================================================== 
        function FreeReconInfoGpuMem(RECON)    
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = FreeAllGpuMem75(RECON.NumGpuUsed,RECON.HReconInfo);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = FreeAllGpuMem61(RECON.NumGpuUsed,RECON.HReconInfo);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            RECON.HReconInfo = [];
        end          
              
%==================================================================
% LoadReconInfoGpuMem
%   - kMat -> already normalized
%   - ReconInfo: read x proj x 4 [x,y,z,sdc]
%   - function loads ReconInfo on all GPUs
%================================================================== 
        function LoadReconInfoGpuMem(RECON,ReconInfo)
            if ~isa(ReconInfo,'single')
                error('ReconInfo must be in single format');
            end       
            sz = size(ReconInfo);
            for n = 1:length(sz)
                if sz(n) ~= RECON.ReconInfoMemDims(n)
                    error('ReconInfo dimensionality problem');  
                end
            end
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadReconInfoGpuMem75(RECON.NumGpuUsed,RECON.HReconInfo,ReconInfo);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadReconInfoGpuMem61(RECON.NumGpuUsed,RECON.HReconInfo,ReconInfo);
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
        function LoadReconInfoGpuMemAsync(RECON,ReconInfo)
            if ~isa(ReconInfo,'single')
                error('ReconInfo must be in single format');
            end       
            sz = size(ReconInfo);
            for n = 1:length(sz)
                if sz(n) ~= RECON.ReconInfoMemDims(n)
                    error('ReconInfo dimensionality problem');  
                end
            end
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadReconInfoGpuMemAsync75(RECON.NumGpuUsed,RECON.HReconInfo,ReconInfo);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadReconInfoGpuMemAsync61(RECON.NumGpuUsed,RECON.HReconInfo,ReconInfo);
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
        function AllocateSampDatGpuMem(RECON,SampDatMemDims)    
            for n = 1:length(SampDatMemDims)
                if isempty(RECON.ReconInfoMemDims)
                    error('AllocateReconInfoGpuMem first');
                end
                if SampDatMemDims(n) ~= RECON.ReconInfoMemDims(n)
                    error('SampDat dimensionality problem');  
                end
            end
            RECON.SampDatMemDims = uint64(SampDatMemDims);
            RECON.HSampDat = zeros([RECON.NumGpuUsed,RECON.NumGpuUsed],'uint64');
            for n = 1:RECON.ChanPerGpu
                if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                    [RECON.HSampDat(n,:),Error] = AllocateSampDatGpuMem75(RECON.NumGpuUsed,RECON.SampDatMemDims);
                elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                    [RECON.HSampDat(n,:),Error] = AllocateSampDatGpuMem61(RECON.NumGpuUsed,RECON.SampDatMemDims);
                end
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end  

%==================================================================
% FreeSampDatGpuMem
%================================================================== 
        function FreeSampDatGpuMem(RECON)    
            for n = 1:RECON.ChanPerGpu
                if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                    [Error] = FreeAllGpuMem75(RECON.NumGpuUsed,RECON.HSampDat(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                    [Error] = FreeAllGpuMem61(RECON.NumGpuUsed,RECON.HSampDat(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
            end
            RECON.HSampDat = [];
        end       
        
%==================================================================
% LoadSampDatGpuMemAsync
%   - SampDat: read x proj
%   - function loads SampDat on one GPU asynchronously
%================================================================== 
        function LoadSampDatGpuMemAsync(RECON,LoadGpuNum,GpuChanNum,SampDat)
            if LoadGpuNum > RECON.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            LoadGpuNum = uint64(LoadGpuNum);
            if ~isa(SampDat,'single')
                error('SampDat must be in single format');
            end       
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = LoadSampDatGpuMemAsyncRI75(LoadGpuNum,RECON.HSampDat(GpuChanNum,:),SampDat);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = LoadSampDatGpuMemAsyncRI61(LoadGpuNum,RECON.HSampDat(GpuChanNum,:),SampDat);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end       
        
%==================================================================
% AllocateKspaceImageMatricesGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateKspaceImageMatricesGpuMem(RECON,ImageMatrixMemDims)
            RECON.ImageMatrixMemDims = uint64(ImageMatrixMemDims);
            RECON.HKspaceMatrix = zeros([RECON.NumGpuUsed,RECON.NumGpuUsed],'uint64');
            RECON.HImageMatrix = zeros([RECON.NumGpuUsed,RECON.NumGpuUsed],'uint64');
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                for n = 1:RECON.ChanPerGpu
                    [RECON.HImageMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [RECON.HKspaceMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [RECON.HTempMatrix,Error] = AllocateComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                for n = 1:RECON.ChanPerGpu
                    [RECON.HImageMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [RECON.HKspaceMatrix(n,:),Error] = AllocateComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [RECON.HTempMatrix,Error] = AllocateComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end          

%==================================================================
% FreeKspaceImageMatricesGpuMem
%==================================================================                      
        function FreeKspaceImageMatricesGpuMem(RECON)
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                for n = 1:RECON.ChanPerGpu
                    [Error] = FreeAllGpuMem75(RECON.NumGpuUsed,RECON.HImageMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [Error] = FreeAllGpuMem75(RECON.NumGpuUsed,RECON.HKspaceMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [Error] = FreeAllGpuMem75(RECON.NumGpuUsed,RECON.HTempMatrix);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                for n = 1:RECON.ChanPerGpu
                    [Error] = FreeAllGpuMem61(RECON.NumGpuUsed,RECON.HImageMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                    [Error] = FreeAllGpuMem61(RECON.NumGpuUsed,RECON.HKspaceMatrix(n,:));
                    if not(strcmp(Error,'no error'))
                        error(Error);
                    end
                end
                [Error] = FreeAllGpuMem61(RECON.NumGpuUsed,RECON.HTempMatrix);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
            RECON.HImageMatrix = [];
            RECON.HKspaceMatrix = [];
            RECON.HTempMatrix = [];
        end         

%==================================================================
% AllocateSuperMatricesGpuMem
%   - inpute = array of 3 dimension sizes
%==================================================================                      
        function AllocateSuperMatricesGpuMem(RECON)
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [RECON.HSuperLow,Error] = AllocateComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperLowConj,Error] = AllocateComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperLowSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperHighSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem75(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [RECON.HSuperLow,Error] = AllocateComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperLowConj,Error] = AllocateComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperLowSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
                [RECON.HSuperHighSoS,Error] = AllocateInitializeComplexMatrixAllGpuMem61(RECON.NumGpuUsed,RECON.ImageMatrixMemDims);
                if not(strcmp(Error,'no error'))
                    error(Error);
                end
            end
        end        
        
%==================================================================
% GridSampDat
%==================================================================                      
        function GridSampDat(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''LoadGpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = GridSampDat75(GpuNum,RECON.HSampDat(GpuChanNum,:),RECON.HReconInfo,RECON.HKernel,RECON.HKspaceMatrix(GpuChanNum,:),...
                                        RECON.SampDatMemDims,RECON.KernelMemDims,RECON.ImageMatrixMemDims,RECON.iKern,RECON.KernHw);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = GridSampDat61(GpuNum,RECON.HSampDat(GpuChanNum,:),RECON.HReconInfo,RECON.HKernel,RECON.HKspaceMatrix(GpuChanNum,:),...
                                        RECON.SampDatMemDims,RECON.KernelMemDims,RECON.ImageMatrixMemDims,RECON.iKern,RECON.KernHw);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end            
                       
%==================================================================
% ReturnOneKspaceMatrixGpuMem
%================================================================== 
        function KspaceMatrix = ReturnOneKspaceMatrixGpuMem(RECON,TestGpuNum,GpuChanNum)
            if TestGpuNum > RECON.NumGpuUsed-1
                error('Specified ''TestGpuNum'' beyond number of GPUs used');
            end
            TestGpuNum = uint64(TestGpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [KspaceMatrix,Error] = ReturnComplexMatrixSingleGpu75(TestGpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.ImageMatrixMemDims);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [KspaceMatrix,Error] = ReturnComplexMatrixSingleGpu61(TestGpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 
        
%==================================================================
% ReturnOneImageMatrixGpuMem
%================================================================== 
        function ImageMatrix = ReturnOneImageMatrixGpuMem(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.ImageMatrixMemDims);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 

%==================================================================
% ReturnOneImageMatrixGpuMemSpecify
%================================================================== 
        function ImageMatrix = ReturnOneImageMatrixGpuMemSpecify(RECON,ImageMatrix,GpuNum,Image)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu75(GpuNum,Image,RECON.ImageMatrixMemDims);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [ImageMatrix,Error] = ReturnComplexMatrixSingleGpu61(GpuNum,Image,RECON.ImageMatrixMemDims);
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% KspaceFourierTransformShift
%==================================================================         
        function KspaceFourierTransformShift(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.HTempMatrix,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.HTempMatrix,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end     

%==================================================================
% ImageFourierTransformShift
%==================================================================         
        function ImageFourierTransformShift(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HTempMatrix,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HTempMatrix,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
 
%==================================================================
% ImageFourierTransformShiftSpecify
%==================================================================         
        function ImageFourierTransformShiftSpecify(RECON,GpuNum,Image)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = FourierTransformShiftSingleGpu75(GpuNum,Image,RECON.HTempMatrix,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = FourierTransformShiftSingleGpu61(GpuNum,Image,RECON.HTempMatrix,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% InverseFourierTransform
%==================================================================         
        function InverseFourierTransform(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteInverseFourierTransformSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HKspaceMatrix(GpuChanNum,:),RECON.HFourierTransformPlan,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteInverseFourierTransformSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HKspaceMatrix(GpuChanNum,:),RECON.HFourierTransformPlan,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end 
        
%==================================================================
% InverseFourierTransformSpecify
%==================================================================         
        function InverseFourierTransformSpecify(RECON,GpuNum,Image,Kspace)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteInverseFourierTransformSingleGpu75(GpuNum,Image,Kspace,RECON.HFourierTransformPlan,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteInverseFourierTransformSingleGpu61(GpuNum,Image,Kspace,RECON.HFourierTransformPlan,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% FourierTransform
%==================================================================         
        function FourierTransform(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteFourierTransformSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HKspaceMatrix(GpuChanNum,:),RECON.HFourierTransformPlan);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteFourierTransformSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HKspaceMatrix(GpuChanNum,:),RECON.HFourierTransformPlan);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         
        
%==================================================================
% FourierTransformSpecify
%==================================================================         
        function FourierTransformSpecify(RECON,GpuNum,Image,Kspace)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ExecuteFourierTransformSingleGpu75(GpuNum,Image,Kspace,RECON.HFourierTransformPlan);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ExecuteFourierTransformSingleGpu61(GpuNum,Image,Kspace,RECON.HFourierTransformPlan);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% MultInvFilt
%==================================================================         
        function MultInvFilt(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = DivideComplexMatrixRealMatrixSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HInvFilt,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = DivideComplexMatrixRealMatrixSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),RECON.HInvFilt,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% SuperKspaceFilter
%==================================================================         
        function SuperKspaceFilter(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyComplexMatrixRealMatrixSingleGpu75(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.HSuperFilt,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyComplexMatrixRealMatrixSingleGpu61(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),RECON.HSuperFilt,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          

%==================================================================
% KspaceScaleCorrect
%==================================================================         
        function KspaceScaleCorrect(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(1/RECON.ConvScaleVal);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),Scale,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,RECON.HKspaceMatrix(GpuChanNum,:),Scale,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% ScaleImage
%==================================================================         
        function ScaleImage(RECON,GpuNum,GpuChanNum,Scale)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(Scale);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,RECON.HImageMatrix(GpuChanNum,:),Scale,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,RECON.HImageMatrix(GpuChanNum,:),Scale,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% ScaleImageSpecify
%==================================================================         
        function ScaleImageSpecify(RECON,GpuNum,Image,Scale)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            Scale = single(Scale);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = ScaleComplexMatrixSingleGpu75(GpuNum,Image,Scale,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = ScaleComplexMatrixSingleGpu61(GpuNum,Image,Scale,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end         

%==================================================================
% CreateLowImageConjugate
%==================================================================         
        function CreateLowImageConjugate(RECON,GpuNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = CopyComplexMatrixSingleGpuMemAsync75(GpuNum,RECON.HSuperLowConj,RECON.HSuperLow,RECON.ImageMatrixMemDims);  
                [Error] = ConjugateComplexMatrixSingleGpu75(GpuNum,RECON.HSuperLowConj,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = CopyComplexMatrixSingleGpuMemAsync61(GpuNum,RECON.HSuperLowConj,RECON.HSuperLow,RECON.ImageMatrixMemDims);  
                [Error] = ConjugateComplexMatrixSingleGpu61(GpuNum,RECON.HSuperLowConj,RECON.ImageMatrixMemDims);   
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end           
 
%==================================================================
% BuildLowSosImage
%==================================================================         
        function BuildLowSosImage(RECON,GpuNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu75(GpuNum,RECON.HSuperLowSoS,RECON.HSuperLow,RECON.HSuperLowConj,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu61(GpuNum,RECON.HSuperLowSoS,RECON.HSuperLow,RECON.HSuperLowConj,RECON.ImageMatrixMemDims);  
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end        

%==================================================================
% BuildHighSosImage
%==================================================================         
        function BuildHighSosImage(RECON,GpuNum,GpuChanNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu75(GpuNum,RECON.HSuperHighSoS,RECON.HImageMatrix(GpuChanNum,:),RECON.HSuperLowConj,RECON.ImageMatrixMemDims);  
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
                [Error] = MultiplyAccumComplexMatrixComplexMatrixSingleGpu61(GpuNum,RECON.HSuperHighSoS,RECON.HImageMatrix(GpuChanNum,:),RECON.HSuperLowConj,RECON.ImageMatrixMemDims);  
            end
            if not(strcmp(Error,'no error'))
                error(Error);
            end
        end          
        
%==================================================================
% CudaDeviceWait
%================================================================== 
        function CudaDeviceWait(RECON,GpuNum)
            if GpuNum > RECON.NumGpuUsed-1
                error('Specified ''GpuNum'' beyond number of GPUs used');
            end
            GpuNum = uint64(GpuNum);
            if str2double(RECON.GpuParams.ComputeCapability) == 7.5
                [Error] = CudaDeviceWait75(GpuNum);
            elseif str2double(RECON.GpuParams.ComputeCapability) == 6.1
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
%         function Kernel = TestKernelInGpuMem(RECON,TestGpuNum)
%             if TestGpuNum > RECON.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [Kernel,Error] = TestKernelInGpuMem(TestGpuNum,RECON.HKernel,RECON.KernelMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end       
%         
% %==================================================================
% % TestReconInfoInGpuMem
% %   - Remember first GPU = 0
% %================================================================== 
%         function ReconInfo = TestReconInfoInGpuMem(RECON,TestGpuNum)
%             if TestGpuNum > RECON.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [ReconInfo,Error] = TestReconInfoInGpuMem(TestGpuNum,RECON.HReconInfo,RECON.ReconInfoMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end        
% 
% %==================================================================
% % TestSampDatInGpuMem
% %   - Remember first GPU = 0
% %================================================================== 
%         function SampDat = TestSampDatInGpuMem(RECON,TestGpuNum)
%             if TestGpuNum > RECON.NumGpuUsed-1
%                 error('Specified ''TestGpuNum'' beyond number of GPUs used');
%             end
%             TestGpuNum = uint64(TestGpuNum);
%             [SampDat,Error] = TestSampDatInGpuMem(TestGpuNum,RECON.HSampDat,RECON.SampDatMemDims);
%             if not(strcmp(Error,'no error'))
%                 error(Error);
%             end
%         end 
        