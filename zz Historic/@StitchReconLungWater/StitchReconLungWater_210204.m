%================================================================
%  
%================================================================

classdef StitchReconLungWater < StitchReconSuper

    properties (SetAccess = private)                    
        Data;
        %ReconInfoMat
        TrajMashInfo;
        NumImages;
        ImageArray;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconLungWater()
            obj@StitchReconSuper;
        end
        
%==================================================================
% StitchInit 
%==================================================================   
        function StitchInit(obj,StitchMetaData,ReconInfoMat,log)
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
            %obj.ReconInfoMat = zeros(obj.StitchMetaData.NumCol*2,obj.StitchMetaData.NumTraj,4,'single');
            NeededSeqParams{1} = 'TR';
            Values = DataObj.ExtractSequenceParams(NeededSeqParams);
            NeededSeqParams{2} = 'NumAverages';
            Values{2} = DataObj.NumAverages;
            obj.AddToStitchMetaData(NeededSeqParams,Values);
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
            %obj.ReconInfoMat(:,DataObj.DataBlockAcqStartNumber:DataObj.DataBlockAcqStopNumber,:);       % future     
            if DataObj.DataBlockNumber == DataObj.TotalBlockReads
                fprintf('\n');
            end
        end        
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)

            log.info('Create TrajMash');
            k0 = squeeze(abs(obj.Data(1,:,:) + 1j*obj.Data(2,:,:)));
            func = str2func(obj.StitchMetaData.TrajMashFunc);
            tic
            obj.TrajMashInfo = func(k0,obj.StitchMetaData);
            toc
            
            log.info('Sort out TrajMash');
            obj.NumImages = length(obj.TrajMashInfo.TrajMashLocs(1,:));
            if length(obj.TrajMashInfo.TrajMash) ~= obj.NumTraj
                  error('Not set up for TrajMash averaging');
%                 SortedData = zeros(obj.StitchMetaData.NumCol*2,obj.NumTraj,obj.StitchMetaData.RxChannels,'single');
%                 multiusearray = zeros([obj.NumTraj,1]);
%                 for n = 1:length(obj.TrajMash)
%                     AcqUse = (obj.TrajMash(n,2).'-1)*obj.NumTraj + obj.TrajMash(n,1);
%                     SortedData(:,obj.TrajMash(n,1),:) = SortedData(:,obj.TrajMash(n,1),:) + obj.Data(:,AcqUse,:);
%                     multiusearray(obj.TrajMash(n,1)) = multiusearray(obj.TrajMash(n,1)) + 1;
%                 end
%                 multiusearray(multiusearray == 0) = 1;
%                 for n = 1:obj.NumTraj
%                     SortedData(:,n,:) = SortedData(:,n,:)/multiusearray(n);
%                 end
            end

            log.info('Initialize Gridding');
            obj.StitchGridInit(log);  

            for m = 1:obj.NumImages
                log.info('Grid');
                BlocksPerImage = ceil(DataObj.TotalBlockReads/DataObj.NumAverages);
                for n = 1:BlocksPerImage
                    Start = (n-1)*obj.DataBlockLength + 1;
                    Stop = n*obj.DataBlockLength;
                    if Stop > obj.NumTraj
                        Stop = obj.NumTraj;
                        TempDataObj.Data = zeros(obj.StitchMetaData.NumCol*2,obj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
                        TempDataObj.Data(:,1:Stop-Start+1,:) = obj.Data(:,obj.TrajMashInfo.TrajMashLocs(Start:Stop,n),:);
                    else
                        TempDataObj.Data = obj.Data(:,obj.TrajMashInfo.TrajMashLocs(Start:Stop,n),:);
                        %TempDataObj.ReconInfoMat            % future
                    end
                    TempDataObj.DataBlockAcqStartNumber = Start;
                    TempDataObj.DataBlockAcqStopNumber = Stop;
                    TempDataObj.DataBlockLength = obj.DataBlockLength;
                    TempDataObj.NumCol = obj.NumCol;
                    obj.StitchGridDataBlock(TempDataObj,log); 
                end
                obj.StitchFftCombine(log); 
                Image = obj.StitchReturnSuperImage
            end
        end

%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 

        end            
               

    end
end
