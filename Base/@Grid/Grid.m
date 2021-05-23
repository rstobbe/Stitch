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
        %DataArray;
        NumTraj;
        RxChannels;
    end
    methods 

        
%==================================================================
% Constructor
%==================================================================   
        function obj = Grid()
            obj@GpuInterface;
        end        

%==================================================================
% GridKernelInvFiltLoad
%==================================================================   
        function GridKernelInvFiltLoad(obj,log)        
            
            %--------------------------------------
            % Load Kernel
            %--------------------------------------
            log.info('Retreive Kernel From HardDrive');
            load(obj.StitchMetaData.KernelFile);
            KRNprms = saveData.KRNprms;
            iKern = round(1e9*(1/(KRNprms.res*KRNprms.DesforSS)))/1e9;
            Kern = KRNprms.Kern;
            chW = ceil(((KRNprms.W*KRNprms.DesforSS)-2)/2);                    
            if (chW+1)*iKern > length(Kern)
                error;
            end
            log.info('Load Kernel All GPUs');
            obj.LoadKernelGpuMem(Kern,iKern,chW,KRNprms.convscaleval);
            obj.SubSamp = KRNprms.DesforSS;
            obj.KernHalfWid = chW;
            
            %--------------------------------------
            % Load Inverse Filter
            %--------------------------------------
            log.info('Retreive InvFilt From HardDrive');
            load(obj.StitchMetaData.InvFiltFile);
            log.info('Load InvFilt All GPUs');
            obj.LoadInvFiltGpuMem(saveData.IFprms.V);   
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
            %obj.DataArray = obj.StitchMetaData.SampStart:obj.StitchMetaData.SampEnd;
            obj.NumTraj = obj.StitchMetaData.NumTraj;
            obj.RxChannels = obj.StitchMetaData.RxChannels; 
            
            %--------------------------------------
            % Allocate GPU Memory
            %--------------------------------------
            log.info('Allocate GPU Memory for Gridding');
            obj.InitGpuInterface(obj.StitchMetaData.GpuTot,obj.StitchMetaData.ChanPerGpu);
            if not(isempty(obj.HReconInfo))
                obj.FreeReconInfoGpuMem;
            end
            ReconInfoSize = [obj.StitchMetaData.NumCol obj.StitchMetaData.BlockLength 4];
            obj.AllocateReconInfoGpuMem(ReconInfoSize);                       
            if not(isempty(obj.HSampDat))
                obj.FreeSampDatGpuMem;
            end
            SampDatSize = [obj.StitchMetaData.NumCol obj.StitchMetaData.BlockLength];
            obj.AllocateSampDatGpuMem(SampDatSize);
            if not(isempty(obj.HImageMatrix))
                obj.FreeKspaceImageMatricesGpuMem;
            end
            obj.AllocateKspaceImageMatricesGpuMem([obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill obj.StitchMetaData.ZeroFill]);   % isotropic for now   
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
                    if ChanNum > obj.RxChannels
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