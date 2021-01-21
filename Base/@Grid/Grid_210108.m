%================================================================
%  
%================================================================

classdef Grid < GpuInterface 

    properties (SetAccess = private)                    
        BlockLength;
        DataBlockDims;
        DataBlock;
        ReconInfoDims;
        ReconInfoBlock;
        BlockCounter;
        TrajCounter;
        FovShift;
        KernHalfWid;
        SubSamp;
        kMatCentre;
        kStep;
        DataArray;
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
% GridInitialize
%==================================================================   
        function GridInitialize(obj,StitchMetaData,log)

            %--------------------------------------
            % Initizize GPU Interface
            %--------------------------------------
            GpuParams = gpuDevice; 
            obj.InitGpuInterface(obj.StitchMetaData.GpuTot,GpuParams,obj.StitchMetaData.ChanPerGpu);

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

            %--------------------------------------
            % Initialize
            %--------------------------------------
            obj.BlockLength = StitchMetaData.BlockLength;
            obj.DataBlockDims = [StitchMetaData.NumCol StitchMetaData.BlockLength StitchMetaData.RxChannels];      
            obj.DataBlock = complex(zeros(obj.DataBlockDims,'single'),zeros(obj.DataBlockDims,'single'));
            obj.ReconInfoDims = [StitchMetaData.NumCol StitchMetaData.BlockLength 4];    
            obj.ReconInfoBlock = zeros(obj.ReconInfoDims,'single');
            obj.BlockCounter = 0;
            obj.TrajCounter = 0;
%           obj.FovShift = StitchMetaData.FovShift;
            obj.FovShift = [0 0 0];
            obj.kMatCentre = ceil(obj.SubSamp*StitchMetaData.kMaxRad/StitchMetaData.kStep) + (obj.KernHalfWid + 2);   
            obj.kStep = StitchMetaData.kStep;
            obj.DataArray = StitchMetaData.SampStart:StitchMetaData.SampEnd;
            obj.NumTraj = StitchMetaData.NumTraj;
            obj.RxChannels = StitchMetaData.RxChannels;
            
            %--------------------------------------
            % Allocate GPU Memory
            %--------------------------------------
            log.info('Allocate GPU Memory for Gridding');
            ReconInfoSize = [StitchMetaData.NumCol StitchMetaData.BlockLength 4];
            obj.AllocateReconInfoGpuMem(ReconInfoSize);                       
            SampDatSize = [StitchMetaData.NumCol StitchMetaData.BlockLength];
            obj.AllocateSampDatGpuMem(SampDatSize);
            obj.AllocateKspaceImageMatricesGpuMem([StitchMetaData.ZeroFill StitchMetaData.ZeroFill StitchMetaData.ZeroFill]);   % isotropic for now   
        end

%==================================================================
% GridRealTime
%================================================================== 
        function GridRealTime(obj,ReconInfoTraj,Data,log)
            obj.BlockCounter = obj.BlockCounter + 1;
            obj.TrajCounter = obj.TrajCounter + 1;
            
            % Do SampStart Etc -       
            Data = obj.PerformFovShift(Data,log);                         % not sure before or after filling block                                 
            ReconInfoTraj = obj.KspaceManipulate(ReconInfoTraj,log);
            
            obj.DataBlock(:,obj.BlockCounter,:) = Data(obj.DataArray,:);
            obj.ReconInfoBlock(:,obj.BlockCounter,:) = ReconInfoTraj;
            
            if obj.BlockCounter == obj.BlockLength || obj.TrajCounter == obj.NumTraj 
                %log.info('Load ReconInfo');
                obj.LoadReconInfoGpuMemAsync(obj.ReconInfoBlock);   % will write to all GPUs    

                %log.info('Load Data Gpu');
                for p = 1:obj.ChanPerGpu
                    for m = 1:obj.NumGpuUsed
                        GpuNum = m-1;
                        GpuChan = p;
                        ChanNum = (p-1)*obj.NumGpuUsed+m;
                        if ChanNum > obj.RxChannels
                            break
                        end
                        SampDat0 = obj.DataBlock(:,:,ChanNum);      
                        obj.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                 
                    end
                end    

                %log.info('Grid Chunk');
                for p = 1:obj.ChanPerGpu
                    for m = 1:obj.NumGpuUsed
                        GpuNum = m-1;
                        GpuChan = p;                                                     
                        obj.GridSampDat(GpuNum,GpuChan);
                    end
                end
                obj.BlockCounter = 0;
            end 
        end        
                  
%==================================================================
% GridFinish
%==================================================================
        function GridFinish(obj,log)
            obj.FreeReconInfoGpuMem;
            obj.FreeSampDatGpuMem;
            % free invfilt and kernel?
        end       

%==================================================================
% PerformFovShift
%================================================================== 
        function Data = PerformFovShift(obj,Data,log)  
        end        
        
%==================================================================
% KspaceManipulate
%================================================================== 
        function ReconInfoTraj = KspaceManipulate(obj,ReconInfoTraj,log)  
            ReconInfoTraj(:,:,1:3) = obj.SubSamp*(ReconInfoTraj(:,:,1:3)/obj.kStep) + obj.kMatCentre;                   
        end            
    end  
end