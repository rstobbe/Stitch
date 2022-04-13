%================================================================
% StitchLungWaterMultiAcq1a
%   - LungWater gridding reconstruction
%   - 'AcqInfo' comes from local computer
%================================================================

classdef StitchLungWaterMultiAcq1a < handle

    properties (SetAccess = private)                                     
        Stitch
        Options
        Log
        DataObj
        AcqInfo
        NumAcqsPerReadout
        NumAverages
        NumImages
        NumTrajs
        RxChannels
        ReconRxBatches
        ReconRxBatchLen
        Image
        Data
        TrajMashInfo
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchLungWaterMultiAcq1a(Options)
            obj.Options = Options;
            obj.Log = Log('');
        end                
        
%==================================================================
% Setup
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
            obj.SetData(DataObj);
            obj.Initialize;
            obj.LoadData;
            obj.TrajMash;
            obj.Process;
            obj.Finish;
        end           
        
%==================================================================
% SetData
%================================================================== 
        function SetData(obj,DataObj) 
            obj.DataObj = DataObj;  
            for n = 1:length(DataObj)
                obj.DataObj{n}.Initialize(obj.Options);
            end
        end          

%==================================================================
% LoadData
%================================================================== 
        function LoadData(obj) 
            obj.Log.info('Load Data'); 
            test = obj.DataObj{1}.ReturnAllData(1,obj.AcqInfo{1},obj.Log);
            sz = size(test);
            obj.Data = zeros(sz(1),sz(2)*length(obj.DataObj),sz(3),'single');
            for n = 1:length(obj.DataObj)
                obj.Data(:,(n-1)*sz(2)+1:n*sz(2),:) = obj.DataObj{n}.ReturnAllData(1,obj.AcqInfo{1},obj.Log);
            end
        end          
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj)
            if isempty(obj.DataObj{1})
                error('Load Data');
            end
            if isempty(obj.AcqInfo)
                error('Run Setup');
            end
            if obj.Options.ReconTrajBlockLength > obj.DataObj{1}.TotalAcqs
                error('ReconTrajBlockLength greater than TotalAcqs');
            end 
            obj.RxChannels = obj.DataObj{1}.RxChannels;
            obj.NumTrajs = obj.AcqInfo{1}.NumTraj;
            obj.NumAverages = obj.DataObj{1}.NumAverages;
            obj.NumAverages =  obj.NumAverages * length(obj.DataObj);
            if obj.RxChannels == 1          
                obj.Options.SetGpus2Use(1);
                obj.Options.SetCoilCombine('Single');
            end       
            obj.Stitch = StitchFunctions();
            obj.Stitch.Initialize(obj.Options,obj.Log);
            obj.InitializeReconRxBatching;       
            obj.Stitch.InitializeCoilCombine(obj.Options,obj.Log);
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
            ImageMemory = obj.Stitch.ImageMatrixMemDims(1)*obj.Stitch.ImageMatrixMemDims(2)*obj.Stitch.ImageMatrixMemDims(3)*16;  

            %---------------------------------------------------
            % Data Memory (for this recon)
            %    - complex & single
            %---------------------------------------------------
            DataMemory = 0;
            DataMemory = DataMemory + obj.Options.ReconTrajBlockLength*obj.AcqInfo{1}.NumCol*8;
            
            %---------------------------------------------------
            % Available Memory
            %---------------------------------------------------
            AvailableMemory = obj.Stitch.GpuParams.AvailableMemory;
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
            obj.Stitch.SetChanPerGpu(ChanPerGpu);
            obj.ReconRxBatchLen = ChanPerGpu * obj.Options.Gpus2Use;  
        end          

%==================================================================
% InitializeImageArray
%==================================================================          
        function InitializeImageArray(obj) 
            Dim5 = obj.NumAcqsPerReadout;
            Dim6 = obj.NumImages;
            sz = size(obj.Stitch.Image);
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
% TrajMash
%   - use first acquisition if multiple
%==================================================================         
        function TrajMash(obj)
            obj.Log.info('Create TrajMash');
            NeededSeqParams{1} = 'TR';
            Values = obj.DataObj{1}.ExtractSequenceParams(NeededSeqParams);
            MetaData.TR = Values{1};
            MetaData.NumAverages = obj.NumAverages;   
            MetaData.NumTraj = obj.NumTrajs;                          
            k0 = squeeze(abs(obj.Data(1,:,:) + 1j*obj.Data(2,:,:)));
            func = str2func(obj.Options.TrajMashFunc);
            obj.TrajMashInfo = func(k0,MetaData);
            sz = size(obj.TrajMashInfo.WeightArr);
            obj.NumImages = sz(2);
        end
        
%==================================================================
% Process
%================================================================== 
        function Process(obj)
            obj.InitializeImageArray;
            %------------------------------------------------------
            % Images 
            %------------------------------------------------------
            for ImNum = 1:obj.NumImages
                obj.Log.info('Create Image %i of %i',ImNum,obj.NumImages);  
                if strcmp(obj.Options.CoilCombine,'Super')
                    obj.Stitch.SuperInit(obj.Log);
                end          
                %------------------------------------------------------
                % ReconRxBatches
                %   - for limited memory GPUs (and many RxChannels)
                %------------------------------------------------------
                for q = 1:obj.ReconRxBatches 
                    obj.Stitch.GridInitialize(obj.Options,obj.AcqInfo{1},obj.DataObj{1},obj.Log);        % done each time making new images
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
                        if length(Trajs) < obj.Options.ReconTrajBlockLength
                            ReconInfoBlock = zeros(obj.AcqInfo{1}.NumCol,obj.Options.ReconTrajBlockLength,4,'single');
                            ReconInfoBlock(:,1:length(Trajs),:) = obj.AcqInfo{1}.ReconInfo(:,Trajs,:);
                        else
                            ReconInfoBlock = obj.AcqInfo{1}.ReconInfoMat(:,Trajs,:);
                        end
                        RbSize = obj.ReconRxBatchLen;
                        TbSize = obj.Options.ReconTrajBlockLength;
                        DataBlock = DoTrajMash(obj.Data,obj.TrajMashInfo.WeightArr(:,ImNum),obj.NumAverages,TbStart,TbStop,TbSize,RbStart,RbStop,RbSize);
                        obj.Stitch.StitchGridDataBlock(ReconInfoBlock,DataBlock,obj.Log);
                    end
                    obj.Stitch.StitchFft(obj.Options,obj.Log);        
                    if strcmp(obj.Options.CoilCombine,'ReturnAll') || strcmp(obj.Options.CoilCombine,'Single')
                        obj.Stitch.ReturnAllImages(obj.Options,obj.Log);
                        obj.Image(:,:,:,Rcvrs,AcqNum,ImNum) = obj.Stitch.Image;
                    elseif strcmp(obj.Options.CoilCombine,'Super')
                        obj.Stitch.SuperCombinePartial(obj.Log);
                    end            
                end
                if strcmp(obj.Options.CoilCombine,'Super')
                    obj.Stitch.SuperCombineFinish(obj.Options,obj.Log);
                    obj.Image(:,:,:,1,1,ImNum) = obj.Stitch.Image;
                end 
            end
        end       
        
%==================================================================
% Finish
%================================================================== 
        function Finish(obj)
            obj.Stitch.StitchFreeGpuMemory(obj.Log);
        end
        
        
    end
end
