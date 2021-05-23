%================================================================
%  Add coil selection
%================================================================

classdef StitchReconFreeBreathingReturnAll < StitchReconSimple

    properties (SetAccess = private)                    
        DataSeqParams;
        Data;
        %ReconInfoMat;
        TrajMashInfo;
        Figs2Save;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconFreeBreathingReturnAll()
            obj@StitchReconSimple;
        end
        
%==================================================================
% StitchInit 
%==================================================================   
        function StitchInit(obj,StitchMetaData,ReconInfoMat,log)
            if StitchMetaData.Dummies > 0
                log.error('Recon does not work with dummies');
            end
            obj.StitchBasicInit(StitchMetaData,ReconInfoMat,log);          
        end
        
%==================================================================
% UpdateStitchMetaData (subclass)
%==================================================================          

%==================================================================
% StitchReconDataProcessInit
%==================================================================  
        function StitchReconDataProcessInit(obj,DataObj,log) 
            obj.Data = zeros(obj.StitchMetaData.NumCol*2,DataObj.TotalBlockReads*DataObj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
            %obj.ReconInfoMat = zeros(obj.StitchMetaData.NumCol*2,obj.StitchMetaData.NumTraj,4,'single');    % future 
            NeededSeqParams{1} = 'TR';
            NeededSeqParams{2} = 'NumAverages';
            Values = DataObj.ExtractSequenceParams(NeededSeqParams);
            obj.DataSeqParams.TR = Values{1};
            obj.DataSeqParams.NumAverages = Values{2};
        end      

%==================================================================
% StitchIntraAcqProcess
%==================================================================           
        function StitchIntraAcqProcess(obj,DataObj,log)
            if strcmp(DataObj.ReconHandlerName,'StitchSiemensLocal')
                if DataObj.DataBlockNumber == 1
                    fprintf('\b');
                else
                    fprintf('\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b');
                end
                fprintf(' (%03.1d of %03.1d blocks read)',DataObj.DataBlockNumber,DataObj.TotalBlockReads);
            end
            start = (DataObj.DataBlockNumber-1)*DataObj.DataBlockLength+1;
            stop = DataObj.DataBlockNumber*DataObj.DataBlockLength;
            obj.Data(:,start:stop,:) = DataObj.DataBlock;
            %obj.ReconInfoMat(:,start:stop,:);       % future     
            if DataObj.DataBlockNumber == DataObj.TotalBlockReads
                if strcmp(DataObj.ReconHandlerName,'StitchSiemensLocal')
                    fprintf('\n');
                end
            end
        end        
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)

            if not(isfield(obj.StitchMetaData,'Coils'))
                include_coils = 1:obj.StitchMetaData.RxChannels;
            else
                if strcmp(obj.StitchMetaData.Coils,'All')
                    include_coils = 1:obj.StitchMetaData.RxChannels;
                else
                    include_coils = obj.StitchMetaData.Coils;
                end
            end
            log.info('Create TrajMash');
            if isempty(obj.Data)
                error('Reload Data');
            end
            k0 = squeeze(abs(obj.Data(1,:,:) + 1j*obj.Data(2,:,:)));
            func = str2func(obj.StitchMetaData.TrajMashFunc);
            MetaData.TR = obj.DataSeqParams.TR;
            MetaData.NumAverages = obj.DataSeqParams.NumAverages;
            MetaData.NumTraj = obj.StitchMetaData.NumTraj;
            obj.TrajMashInfo = func(k0,MetaData);
            obj.Figs2Save = obj.TrajMashInfo.Figs;
            NumImages = length(obj.TrajMashInfo.TrajMashLocs);
            if NumImages > 1
                log.info('Allocate Multiple Image Array');
                obj.ImageArray = complex(zeros([size(obj.Image),NumImages],'single'),0);
            end

            for m = 1:NumImages
                log.info('Initialize Gridding');
                obj.StitchGridInit(log);        
                log.info('Grid Image %i of %i',m,NumImages);
                BlocksPerImage = ceil(DataObj.TotalBlockReads/DataObj.NumAverages);
                for n = 1:BlocksPerImage
                    Start = (n-1)*DataObj.DataBlockLength + 1;
                    Stop = n*DataObj.DataBlockLength;
                    if Stop > obj.NumTraj
                        Stop = obj.NumTraj;
                        TempDataObj.DataBlock = zeros(obj.StitchMetaData.NumCol*2,DataObj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
                        counter=1;
                        for j=Start:Stop
                            tempmash=find(obj.TrajMashInfo.TrajMash{m}(:,1)==j);
                            temploc=obj.TrajMashInfo.TrajMashLocs{m}(tempmash);
                            tempData=mean(obj.Data(:,temploc,include_coils),2);
                            TempDataObj.DataBlock(:,counter,include_coils) = tempData;
                            counter=counter+1;
                        end
                    else
                        TempDataObj.DataBlock = zeros(obj.StitchMetaData.NumCol*2,DataObj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
                        counter=1;
                        for j=Start:Stop
                            tempmash=find(obj.TrajMashInfo.TrajMash{m}(:,1)==j);
                            temploc=obj.TrajMashInfo.TrajMashLocs{m}(tempmash);
                            tempData=mean(obj.Data(:,temploc,include_coils),2);
                            TempDataObj.DataBlock(:,counter,include_coils) = tempData;
                            counter=counter+1;
                        end
                        %TempDataObj.ReconInfoMat            % future
                    end
                    Info.TrajAcqStart = Start;
                    Info.TrajAcqStop = Stop;
                    TempDataObj.DataBlockLength = DataObj.DataBlockLength;
                    TempDataObj.NumCol = DataObj.NumCol;
                    obj.StitchGridDataBlock(TempDataObj,Info,log); 
                end
                obj.StitchFft(log); 
                obj.StitchReturnImages(m,log); 
            end
        end

%==================================================================
% StitchFinishAcqProcess
%================================================================== 
        function StitchFinishAcqProcess(obj,DataObj,log)
            obj.StitchFreeGpuMemory;
        end          
        
%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 
            Image = obj.StitchReturnIndividualImages(log);
        end            

%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            obj.StitchFreeGpuMemory;
        end         

    end
end
