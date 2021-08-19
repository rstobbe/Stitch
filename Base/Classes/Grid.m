%================================================================
%  
%================================================================

classdef Grid < GpuInterface 

    properties (SetAccess = private)                    
        FovShift;
        KernHalfWid;
        SubSamp;
        kMatCentre;
        kSz;
        kShift;
        kStep;
        NumTraj;
        RxChannels;
        ReconBlockLength;
        ReconBlocksPerImage;
        ReconGpuBatches;
        ReconGpuBatchRxLen;
    end
    methods 

        
%==================================================================
% Constructor
%==================================================================   
        function obj = Grid()
            obj@GpuInterface;
        end        

%==================================================================
% GridKernelLoad
%==================================================================   
        function GridKernelLoad(obj,log)        
            %log.info('Retreive Kernel From HardDrive');
            load(obj.StitchMetaData.KernelFile);
            KRNprms = saveData.KRNprms;
            iKern = round(1e9*(1/(KRNprms.res*KRNprms.DesforSS)))/1e9;
            Kern = KRNprms.Kern;
            chW = ceil(((KRNprms.W*KRNprms.DesforSS)-2)/2);                    
            if (chW+1)*iKern > length(Kern)
                error;
            end
            %log.info('Load Kernel All GPUs');
            obj.LoadKernelGpuMem(Kern,iKern,chW,KRNprms.convscaleval);
            obj.SubSamp = KRNprms.DesforSS;
            obj.KernHalfWid = chW;
        end

%==================================================================
% InvFiltLoad
%==================================================================   
        function InvFiltLoad(obj,log)        
            %log.info('Retreive InvFilt From HardDrive');
            load(obj.StitchMetaData.InvFiltFile);
            %log.info('Load InvFilt All GPUs');
            obj.LoadInvFiltGpuMem(saveData.IFprms.V);   
        end        
    
%==================================================================
% TestMinimumZeroFill
%==================================================================           
        function TestMinimumZeroFill(obj,log)
            TestkMatCentre = ceil(obj.SubSamp*obj.StitchMetaData.kMaxRad/obj.StitchMetaData.kStep) + (obj.KernHalfWid + 2); 
            TestkSz = TestkMatCentre*2 - 1;
            if TestkSz > obj.StitchMetaData.ZeroFill
                error(['Zero-Fill is to small. kSz = ',num2str(TestkSz)]);
            end 
        end

%==================================================================
% InitializeReconGpuBatching
%==================================================================   
        function InitializeReconGpuBatching(obj,log) 
            obj.RxChannels = obj.StitchMetaData.RxChannels; 
            for n = 1:20
                obj.ReconGpuBatches = n;
                ChanPerGpu = ceil(obj.StitchMetaData.RxChannels/(obj.StitchMetaData.GpuTot*obj.ReconGpuBatches));
                MemoryNeededImages = ChanPerGpu*obj.ImageMatrixMemDims(1)*obj.ImageMatrixMemDims(2)*obj.ImageMatrixMemDims(3)*16;  % k-space + image (complex & single)  
                MemoryNeededData = ChanPerGpu*obj.StitchMetaData.ReconBlockLength*obj.StitchMetaData.NumCol*8;  % complex & single
                MemoryNeededTotal = MemoryNeededImages + MemoryNeededData;
                if MemoryNeededTotal*1.1 < obj.GpuParams.AvailableMemory
                    break
                end
            end
            obj.SetChanPerGpu(ChanPerGpu);
            obj.ReconGpuBatchRxLen = ChanPerGpu * obj.StitchMetaData.GpuTot;  
        end        

%==================================================================
% FftInitialize
%==================================================================   
        function FftInitialize(obj,log)        
            %log.info('Setup Fourier Transform');
            ZeroFillArray = [obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill];          % isotropic for now
            if not(isempty(obj.HFourierTransformPlan))
                obj.ReleaseFourierTransform;
            end 
            obj.SetupFourierTransform(ZeroFillArray);
        end           
        
%==================================================================
% GridInitialize
%==================================================================   
        function GridInitialize(obj,log)

            %--------------------------------------
            % General Init
            %--------------------------------------
            obj.FovShift = [0 0 0];
            obj.kMatCentre = ceil(obj.SubSamp*obj.StitchMetaData.kMaxRad/obj.StitchMetaData.kStep) + (obj.KernHalfWid + 2); 
            obj.kSz = obj.kMatCentre*2 - 1;
            if obj.kSz > obj.StitchMetaData.ZeroFill
                error(['Zero-Fill is to small. kSz = ',num2str(obj.kSz)]);
            end 
            obj.kStep = obj.StitchMetaData.kStep;
            obj.kShift = (obj.StitchMetaData.ZeroFill/2+1)-((obj.kSz+1)/2);
            obj.NumTraj = obj.StitchMetaData.NumTraj;
            
            %--------------------------------------
            % Allocate GPU Memory
            %--------------------------------------
            obj.GpuInit;
            if not(isempty(obj.HReconInfo))
                obj.FreeReconInfoGpuMem;
            end
            ReconInfoSize = [obj.StitchMetaData.NumCol obj.StitchMetaData.ReconBlockLength 4];
            obj.AllocateReconInfoGpuMem(ReconInfoSize);                       
            if not(isempty(obj.HSampDat))
                obj.FreeSampDatGpuMem;
            end
            SampDatSize = [obj.StitchMetaData.NumCol obj.StitchMetaData.ReconBlockLength];
            obj.AllocateSampDatGpuMem(SampDatSize);
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesGpuMem;
            end
            obj.AllocateKspaceImageMatricesGpuMem([obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill]);   % isotropic for now   
            
            %--------------------------------------
            % BlocksPerImage
            %--------------------------------------
            obj.ReconBlockLength = obj.StitchMetaData.ReconBlockLength;
            obj.ReconBlocksPerImage = ceil(obj.NumTraj/obj.ReconBlockLength);
        end
          
%==================================================================
% GpuGrid
%================================================================== 
        function GpuGrid(obj,ReconInfoBlock,DataBlock,log)

            %------------------------------------------------------
            % Manipulation
            %------------------------------------------------------    
            [ReconInfoBlock,DataBlock] = obj.PerformFovShift(ReconInfoBlock,DataBlock,log);                                                       
            [ReconInfoBlock] = obj.KspaceManipulate(ReconInfoBlock,log);
            
            %------------------------------------------------------
            % Write Gpus
            %------------------------------------------------------   
            obj.LoadReconInfoGpuMemAsync(ReconInfoBlock);                   % will write to all GPUs    
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;
                    ChanNum = (p-1)*obj.NumGpuUsed+m;
                    if ChanNum > size(DataBlock,3)
                        break
                    end
                    SampDat0 = DataBlock(:,:,ChanNum);      
                    obj.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                 
                end
            end 
            
            %------------------------------------------------------
            % Grid
            %------------------------------------------------------  
            for p = 1:obj.ChanPerGpu
                for m = 1:obj.NumGpuUsed
                    GpuNum = m-1;
                    GpuChan = p;                                                     
                    obj.GridSampDat(GpuNum,GpuChan);
                end
            end
        end        
                  
%==================================================================
% ReleaseGriddingGpuMem
%==================================================================
        function ReleaseGriddingGpuMem(obj,log)
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesGpuMem;
            end
            if not(isempty(obj.HReconInfo))
                obj.FreeReconInfoGpuMem;
            end
            if not(isempty(obj.HSampDat))
                obj.FreeSampDatGpuMem;
            end
            if not(isempty(obj.HKernel))
                obj.FreeKernelGpuMem;
            end
            if not(isempty(obj.HInvFilt))
                obj.FreeInvFiltGpuMem;
            end
            if not(isempty(obj.HFourierTransformPlan))
                obj.ReleaseFourierTransform;
            end
        end       

%==================================================================
% PerformFovShift
%================================================================== 
        function [ReconInfoBlock,DataBlock] = PerformFovShift(obj,ReconInfoBlock,DataBlock,log)  
        end        
        
%==================================================================
% KspaceManipulate
%================================================================== 
        function [ReconInfoBlock] = KspaceManipulate(obj,ReconInfoBlock,log)  
            ReconInfoBlock(:,:,1:3) = obj.SubSamp*(ReconInfoBlock(:,:,1:3)/obj.kStep) + obj.kMatCentre + obj.kShift;                   
        end            
    end  
end