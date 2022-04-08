%================================================================
% StitchStandardComplexKern1a
%   - Standard gridding reconstruction
%   - 'AcqInfo' comes from local computer
%   - All images reconstructed with same 'Options'
%================================================================

classdef StitchStandardComplexKern1a < handle

    properties (SetAccess = private)                                     
        Stitch
        Options
        Log
        DataObj
        AcqInfo
        NumAcqsPerReadout
        NumImageAverages
        NumTrajs
        RxChannels
        ReconRxBatches
        ReconRxBatchLen
        Image
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchStandardComplexKern1a(Options)
            obj.Options = Options;
            obj.Log = Log('');
        end                
        
%==================================================================
% Setup
%   - some recons may have different 'Options' for different Acqs 
%   - here the same 'Options' are used for all Acqs 
%       - parameters are based off of the first Acq
%==================================================================         
        function Setup(obj)
            if isempty(obj.Options.AcqInfoFile)
                error('Run ''Options.SetAcqInfoFile''');
            end
            warning 'off';                                  
            load(obj.Options.AcqInfoFile);
            warning 'on';
            obj.AcqInfo = saveData.WRT.STCH;
            obj.NumAcqsPerReadout = length(obj.AcqInfo);
            obj.Options.Initialize(obj.AcqInfo{1});
        end

%==================================================================
% CreateImage
%================================================================== 
        function CreateImage(obj,DataObj) 
            obj.LoadData(DataObj);
            obj.Initialize;
            obj.Process;
            obj.Finish;
        end           
        
%==================================================================
% LoadData
%================================================================== 
        function LoadData(obj,DataObj) 
            obj.DataObj = DataObj;  
            obj.DataObj.Initialize(obj.Options);
        end          
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj)
            if isempty(obj.DataObj)
                error('Load Data');
            end
            if isempty(obj.AcqInfo)
                error('Run Setup');
            end
            if obj.Options.ReconTrajBlockLength > obj.DataObj.TotalAcqs
                error('ReconTrajBlockLength greater than TotalAcqs');
            end 
            obj.RxChannels = obj.DataObj.RxChannels;
            obj.NumTrajs = obj.AcqInfo{1}.NumTraj;
            obj.NumImageAverages = obj.DataObj.NumAverages;
            if obj.RxChannels == 1          
                obj.Options.SetGpus2Use(1);
                obj.Options.SetCoilCombine('Single');
            end
            for AcqNum = 1:obj.NumAcqsPerReadout         
                obj.Stitch{AcqNum} = StitchFunctions();
                %obj.Stitch{AcqNum}.Initialize(obj.Options,obj.Log);
                %--
                obj.Stitch{AcqNum}.StitchFreeGpuMemory(obj.Log);
                obj.Stitch{AcqNum}.GpuInit(obj.Options.Gpus2Use);
                obj.Stitch{AcqNum}.GridComplexKernelLoad(obj.Options,obj.Log);
                obj.Stitch{AcqNum}.InvFiltLoad(obj.Options,obj.Log);
                obj.Stitch{AcqNum}.FftInitialize(obj.Options,obj.Log);
                %--
            end
            obj.InitializeReconRxBatching;
            for AcqNum = 1:obj.NumAcqsPerReadout         
                obj.Stitch{AcqNum}.InitializeCoilCombine(obj.Options,obj.Log);
            end
            obj.InitializeImageArray;
        end
      
%==================================================================
% InitializeReconRxBatching
%==================================================================   
        function InitializeReconRxBatching(obj)    
            obj.Log.trace('Initialize Receiver Batching');
            %---------------------------------------------------
            % Image Memory (for this recon)
            %   - All images the same size
            %   - Memory = k-space + image (complex & single)
            %---------------------------------------------------
            ImageMemory = obj.Stitch{1}.ImageMatrixMemDims(1)*obj.Stitch{1}.ImageMatrixMemDims(2)*obj.Stitch{1}.ImageMatrixMemDims(3)*16;  

            %---------------------------------------------------
            % Data Memory (for this recon)
            %    - complex & single
            %---------------------------------------------------
            DataMemory = 0;
            for AcqNum = 1:length(obj.AcqInfo)
                DataMemory = DataMemory + obj.Options.ReconTrajBlockLength*obj.AcqInfo{AcqNum}.NumCol*8;
            end
            
            %---------------------------------------------------
            % Available Memory
            %---------------------------------------------------
            AvailableMemory = obj.Stitch{1}.GpuParams.AvailableMemory;
            for n = 1:20
                obj.ReconRxBatches = n;
                ChanPerGpu = ceil(obj.RxChannels/(obj.Options.Gpus2Use*obj.ReconRxBatches));
                MemoryNeededImages = ChanPerGpu*ImageMemory*obj.NumAcqsPerReadout; 
                MemoryNeededData = ChanPerGpu*DataMemory;  
                MemoryNeededTotal = MemoryNeededImages + MemoryNeededData;
                if MemoryNeededTotal*1.1 < AvailableMemory
                    break
                end
            end
            for n = 1:length(obj.Stitch)
                obj.Stitch{n}.SetChanPerGpu(ChanPerGpu);
            end
            obj.ReconRxBatchLen = ChanPerGpu * obj.Options.Gpus2Use;  
        end          

%==================================================================
% InitializeImageArray
%==================================================================          
        function InitializeImageArray(obj) 
            Dim5 = obj.NumAcqsPerReadout;
            Dim6 = obj.NumImageAverages;
            sz = size(obj.Stitch{1}.Image);
            if strcmp(obj.Options.CoilCombine,'Super')
                if strcmp(obj.Options.ImageType,'complex')
                    obj.Image = complex(zeros([sz(1:3),1,Dim5,Dim6],obj.Options.ImagePrecision),0);
                elseif strcmp(obj.Options.ImageType,'abs')
                    obj.Image = zeros([sz(1:3),1,Dim5,Dim6],obj.Options.ImagePrecision);
                end
            elseif strcmp(obj.Options.CoilCombine,'ReturnAll') || strcmp(obj.Options.CoilCombine,'Single')
                if strcmp(obj.Options.ImageType,'complex')
                    obj.Image = complex(zeros([sz(1:3),obj.RxChannels,Dim5,Dim6],obj.Options.ImagePrecision),0);
                elseif strcmp(obj.Options.ImageType,'abs')
                    obj.Image = zeros([sz(1:3),obj.RxChannels,Dim5,Dim6],obj.Options.ImagePrecision);
                end    
            end
        end         
        
%==================================================================
% Process
%================================================================== 
        function Process(obj)
            %------------------------------------------------------
            % Averages 
            %------------------------------------------------------
            for AveNum = 1:obj.NumImageAverages
                obj.Log.info('Create Image %i of %i',AveNum,obj.NumImageAverages);  
                if strcmp(obj.Options.CoilCombine,'Super')
                    for AcqNum = 1:obj.NumAcqsPerReadout
                        obj.Stitch{AcqNum}.SuperInit(obj.Log);
                    end
                end          
                %------------------------------------------------------
                % ReconRxBatches
                %   - for limited memory GPUs (and many RxChannels)
                %------------------------------------------------------
                for q = 1:obj.ReconRxBatches 
                    for AcqNum = 1:obj.NumAcqsPerReadout
                        obj.Stitch{AcqNum}.GridInitialize(obj.Options,obj.AcqInfo{AcqNum},obj.DataObj,obj.Log);        % done each time making new images
                    end
                    RbStart = (q-1)*obj.ReconRxBatchLen + 1;
                    RbStop = q*obj.ReconRxBatchLen;
                    if RbStop > obj.RxChannels
                        RbStop = obj.RxChannels;
                    end
                    Rcvrs = RbStart:RbStop;
                    %------------------------------------------------------
                    % ReconTrajBlocksPerImage
                    %   - typical use in 'simultaneous' acq/read/grid context
                    %------------------------------------------------------
                    for n = 1:obj.Options.ReconTrajBlocksPerImage
                        TbStart = (n-1)*obj.Options.ReconTrajBlockLength + 1;
                        TbStop = n*obj.Options.ReconTrajBlockLength;
                        if TbStop > obj.NumTrajs                     % in this recon all DataObjs / Acqs should have the same number of trajectories
                            TbStop = obj.NumTrajs;                                                              
                        end
                        Trajs = TbStart:TbStop;
                        %------------------------------------------------------
                        % NumAcqsPerReadout
                        %   - example: multiple-echo waveforms
                        %   - be at bottom of looping for 'simultaneous' acq/read/grid context 
                        %------------------------------------------------------
                        for AcqNum = 1:obj.NumAcqsPerReadout
                            if length(Trajs) < obj.Options.ReconTrajBlockLength
                                ReconInfoBlock = zeros(obj.AcqInfo{AcqNum}.NumCol,obj.Options.ReconTrajBlockLength,4,'single');
                                ReconInfoBlock(:,1:length(Trajs),:) = obj.AcqInfo{AcqNum}.ReconInfo(:,Trajs,:);
                            else
                                ReconInfoBlock = obj.AcqInfo{AcqNum}.ReconInfoMat(:,Trajs,:);
                            end
                            obj.DataObj.ReadDataBlock(Trajs,Rcvrs,AveNum,AcqNum,obj.AcqInfo{AcqNum},obj.Log);
                            obj.Stitch{AcqNum}.StitchGridDataBlockComplexKern(ReconInfoBlock,obj.DataObj.DataBlock,obj.Log);
                        end
                    end
                    for AcqNum = 1:obj.NumAcqsPerReadout
                        obj.Stitch{AcqNum}.StitchFft(obj.Options,obj.Log);        
                        if strcmp(obj.Options.CoilCombine,'ReturnAll') || strcmp(obj.Options.CoilCombine,'Single')
                            obj.Stitch{AcqNum}.ReturnAllImages(obj.Options,obj.Log);
                            obj.Image(:,:,:,Rcvrs,AcqNum,AveNum) = obj.Stitch{AcqNum}.Image;
                        elseif strcmp(obj.Options.CoilCombine,'Super')
                            obj.Stitch{AcqNum}.SuperCombinePartial(obj.Log);
                        end
                    end               
                end
                for AcqNum = 1:obj.NumAcqsPerReadout
                    if strcmp(obj.Options.CoilCombine,'Super')
                        obj.Stitch{AcqNum}.SuperCombineFinish(obj.Log);
                        obj.Stitch{AcqNum}.BuildImageArray(1,AcqNum,AveNum);
                    end 
                end
            end
        end

%==================================================================
% ReturnImageCompass
%==================================================================         
        function ReturnImageCompass(obj)
            ReturnOneImageCompass(obj);
        end

%==================================================================
% ReturnIMG
%==================================================================         
        function IMG = ReturnIMG(obj)
            IMG = ReturnOneImage(obj);
        end        
        
%==================================================================
% Finish
%================================================================== 
        function Finish(obj)
            for AcqNum = 1:obj.NumAcqsPerReadout
                obj.Stitch{AcqNum}.StitchFreeGpuMemory(obj.Log);
            end
        end
        
        
    end
end
