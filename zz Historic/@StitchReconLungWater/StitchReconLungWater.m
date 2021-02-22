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
            log.info('Initialize Gridding');
            obj.StitchGridInit(log);  
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
            obj.TrajMashInfo = func(k0,obj.StitchMetaData);
            obj.NumImages = length(obj.TrajMashInfo.TrajMashLocs(1,:));
            if obj.NumImages > 1
                log.info('Allocate Multiple Image Array');
                obj.ImageArray = complex(zeros([size(obj.Image),obj.NumImages],'single'),0);
            end

            for m = 1:obj.NumImages
                log.info('Grid Image %i of %i',m,obj.NumImages);
                BlocksPerImage = ceil(DataObj.TotalBlockReads/DataObj.NumAverages);
                for n = 1:BlocksPerImage
                    Start = (n-1)*DataObj.DataBlockLength + 1;
                    Stop = n*DataObj.DataBlockLength;
                    if Stop > obj.NumTraj
                        Stop = obj.NumTraj;
                        TempDataObj.Data = zeros(obj.StitchMetaData.NumCol*2,DataObj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
                        TempDataObj.Data(:,1:Stop-Start+1,:) = obj.Data(:,obj.TrajMashInfo.TrajMashLocs(Start:Stop,m),:);
                    else
                        TempDataObj.Data = obj.Data(:,obj.TrajMashInfo.TrajMashLocs(Start:Stop,m),:);
                        %TempDataObj.ReconInfoMat            % future
                    end
                    TempDataObj.DataBlockAcqStartNumber = Start;
                    TempDataObj.DataBlockAcqStopNumber = Stop;
                    TempDataObj.DataBlockLength = DataObj.DataBlockLength;
                    TempDataObj.NumCol = DataObj.NumCol;
                    obj.StitchGridDataBlock(TempDataObj,log); 
                    
                    %***
                    % do I need an initialization here...?
                    %***
                    
                end
                obj.StitchFftCombine(log); 
                obj.ImageArray(:,:,:,m) = obj.StitchReturnSuperImage;
            end
        end

%==================================================================
% StitchReturnImage
%==================================================================           
        function Image = StitchReturnImage(obj,log) 

        end            

%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            obj.StitchFreeGpuMemory;
        end         

    end
end
