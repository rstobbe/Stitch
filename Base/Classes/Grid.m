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
        function GridKernelLoad(obj,Options,log)        
            log.trace('Load Kernel All GPUs');
            iKern = round(1e9*(1/(Options.Kernel.res*Options.Kernel.DesforSS)))/1e9;
            Kern = Options.Kernel.Kern;
            chW = ceil(((Options.Kernel.W*Options.Kernel.DesforSS)-2)/2);                    
            if (chW+1)*iKern > length(Kern)
                error;
            end
            obj.LoadKernelGpuMem(Kern,iKern,chW,Options.Kernel.convscaleval);
            obj.SubSamp = Options.Kernel.DesforSS;
            obj.KernHalfWid = chW;
        end

%==================================================================
% GridComplexKernelLoad
%==================================================================   
        function GridComplexKernelLoad(obj,Options,log)        
            log.trace('Load Complex Kernel All GPUs');
            iKern = round(1e9*(1/(Options.Kernel.res*Options.Kernel.DesforSS)))/1e9;
            Kern = Options.Kernel.Kern;
            chW = ceil(((Options.Kernel.W*Options.Kernel.DesforSS)-2)/2);                    
            if (chW+1)*iKern > length(Kern)
                error;
            end
            obj.LoadComplexKernelGpuMem(Kern,iKern,chW,Options.Kernel.convscaleval);
            obj.SubSamp = Options.Kernel.DesforSS;
            obj.KernHalfWid = chW;
        end 
        
%==================================================================
% GridCorniceKernelLoad
%==================================================================   
        function GridCorniceKernelLoad(obj,Options,log)        
            log.trace('Load Complex Kernel All GPUs');
            iKern = round(1e9*(1/(Options.Kernel.res*Options.Kernel.DesforSS)))/1e9;
            Kern = Options.Kernel.Kern;
            chW = ceil(((Options.Kernel.W*Options.Kernel.DesforSS)-2)/2);                    
            if (chW+1)*iKern > length(Kern)
                error;
            end
            obj.LoadCorniceKernelGpuMem(Kern,iKern,chW,Options.Kernel.convscaleval);
            obj.SubSamp = Options.Kernel.DesforSS;
            obj.KernHalfWid = chW;
        end          
        
%==================================================================
% InvFiltLoad
%==================================================================   
        function InvFiltLoad(obj,Options,log)        
            log.trace('Load InvFilt All GPUs');
            obj.LoadInvFiltGpuMem(Options.InvFilt.V);   
        end        
       
%==================================================================
% FftInitialize
%==================================================================   
        function FftInitialize(obj,Options,log)        
            log.trace('Setup Fourier Transform');
            ZeroFillArray = [Options.ZeroFill Options.ZeroFill Options.ZeroFill];          % isotropic for now
            if not(isempty(obj.HFourierTransformPlan))
                obj.ReleaseFourierTransform;
            end 
            obj.SetupFourierTransform(ZeroFillArray);
        end           
        
%==================================================================
% GridInitialize
%==================================================================   
        function GridInitialize(obj,Options,AcqInfo,DataObj,log)
            
            %--------------------------------------
            % General Init
            %--------------------------------------
            log.trace('Gridding Initialize');
            obj.FovShift = DataObj.FovShift;
            obj.kStep = AcqInfo.kStep;
            obj.NumTraj = AcqInfo.NumTraj; 
            obj.kMatCentre = ceil(obj.SubSamp*AcqInfo.kMaxRad/AcqInfo.kStep) + (obj.KernHalfWid + 2); 
            obj.kSz = obj.kMatCentre*2 - 1;
            if obj.kSz > Options.ZeroFill
                error(['Zero-Fill is to small. kSz = ',num2str(obj.kSz)]);
            end 
            obj.kShift = (Options.ZeroFill/2+1)-((obj.kSz+1)/2);

            %--------------------------------------
            % Allocate GPU Memory
            %--------------------------------------
            log.trace('Allocate GPU Memory');
            if not(isempty(obj.HReconInfo))
                obj.FreeReconInfoGpuMem;
            end
            ReconInfoSize = [AcqInfo.NumCol Options.ReconTrajBlockLength 4];
            obj.AllocateReconInfoGpuMem(ReconInfoSize);                       
            if not(isempty(obj.HSampDat))
                obj.FreeSampDatGpuMem;
            end
            SampDatSize = [AcqInfo.NumCol Options.ReconTrajBlockLength];
            obj.AllocateSampDatGpuMem(SampDatSize);
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesGpuMem;
            end
            obj.AllocateKspaceImageMatricesGpuMem([Options.ZeroFill Options.ZeroFill Options.ZeroFill]);   % isotropic for now   
        end

%==================================================================
% GridInitializeCornice
%==================================================================   
        function GridInitializeCornice(obj,Options,AcqInfo,DataObj,log)
            
            %--------------------------------------
            % General Init
            %--------------------------------------
            log.trace('Gridding Initialize');
            obj.FovShift = DataObj.FovShift;
            obj.kStep = AcqInfo.kStep;
            obj.NumTraj = AcqInfo.NumTraj; 
            obj.kMatCentre = ceil(obj.SubSamp*AcqInfo.kMaxRad/AcqInfo.kStep) + (obj.KernHalfWid + 2); 
            obj.kSz = obj.kMatCentre*2 - 1;
            if obj.kSz > Options.ZeroFill
                error(['Zero-Fill is to small. kSz = ',num2str(obj.kSz)]);
            end 
            obj.kShift = (Options.ZeroFill/2+1)-((obj.kSz+1)/2);

            %--------------------------------------
            % Allocate GPU Memory
            %--------------------------------------
            log.trace('Allocate GPU Memory');
            if not(isempty(obj.HReconInfo))
                obj.FreeReconInfoGpuMem;
            end
            ReconInfoSize = [AcqInfo.NumCol Options.ReconTrajBlockLength 4];
            obj.AllocateReconInfoGpuMem(ReconInfoSize);                       
            if not(isempty(obj.HSampDat))
                obj.FreeSampDatGpuMem;
            end
            SampDatSize = [AcqInfo.NumCol Options.ReconTrajBlockLength];
            obj.AllocateSampDatGpuMem(SampDatSize);
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesGpuMem;
            end
            obj.AllocateKspaceImageMatricesCorniceGpuMem([Options.ZeroFill Options.ZeroFill Options.ZeroFill]); 
            %obj.AllocateKspaceImageMatricesGpuMem([Options.ZeroFill Options.ZeroFill Options.ZeroFill]);               % For creating images separately
        end        
        
%==================================================================
% PhaseCorrInitialize
%==================================================================          
        function PhaseCorrInitialize(obj,log)
            log.trace('Phase Correction Initialize');
            obj.AllocateComplexPhaseImageGpuMem;
        end

%==================================================================
% LoadStaticPhaseImage
%==================================================================          
        function LoadStaticPhaseImage(obj,log)
            log.trace('Load Static Phase Image');
            obj.LoadComplexPhaseImageGpuMem(obj,LoadGpuNum,GpuChanNum,PhaseImage)
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
% GpuGridFullKern
%================================================================== 
        function GpuGridFullKern(obj,ReconInfoBlock,DataBlock,log)

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
                    obj.GridSampDatFullKern(GpuNum,GpuChan);
                end
            end
        end         

%==================================================================
% GpuGridComplexKern
%================================================================== 
        function GpuGridComplexKern(obj,ReconInfoBlock,DataBlock,log)

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
                    obj.GridSampDatComplexKern(GpuNum,GpuChan);
                end
            end
        end  
        
%==================================================================
% GpuGridCornice
%================================================================== 
        function GpuGridCornice(obj,ReconInfoBlock,DataBlock,log)

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
                    SampDat0 = ones(size(SampDat0),'single');
                    error
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
                    obj.GridSampDatCornice(GpuNum,GpuChan);
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
% ReleaseGriddingCorniceGpuMem
%==================================================================
        function ReleaseGriddingCorniceGpuMem(obj,log)
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesCorniceGpuMem;
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