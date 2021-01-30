%================================================================
%  Eum - External UserMash
%================================================================

classdef StitchReconLungWaterEum < StitchReconSuper

    properties (SetAccess = private)                    
        Data;
        %ReconInfoMat
        DataBlockLength;
        TotalBlockReads;
        TotalAcqs;
        NumCol;
        Aves;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconLungWaterEum()
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
% StitchGridInitTop 
%==================================================================  
        function StitchGridInitTop(obj,DataObj,log) 
            obj.Data = zeros(obj.StitchMetaData.NumCol*2,DataObj.TotalBlockReads*DataObj.DataBlockLength,obj.StitchMetaData.RxChannels,'single');
            %obj.ReconInfoMat = zeros(obj.StitchMetaData.NumCol*2,obj.StitchMetaData.NumTraj,4,'single');
            obj.StitchGridInit(log);  
        end      

%==================================================================
% StitchIntraAcqProcess
%==================================================================           
        function StitchIntraAcqProcess(obj,DataObj,log)
            if DataObj.DataBlockNumber > 1
                fprintf('\b\b\b\b\b\b\b\b\b\b');
            end
            fprintf('%03.1d of %03.1d',DataObj.DataBlockNumber,obj.TotalBlockReads);
            obj.DataBlockLength = DataObj.DataBlockLength;
            obj.TotalBlockReads = DataObj.TotalBlockReads;
            obj.TotalAcqs = DataObj.TotalAcqs;
            obj.NumCol = DataObj.NumCol;
            start = (DataObj.DataBlockNumber-1)*DataObj.DataBlockLength+1;
            stop = DataObj.DataBlockNumber*DataObj.DataBlockLength;
            obj.Data(:,start:stop,:) = DataObj.Data;
            %obj.ReconInfoMat(:,DataObj.DataBlockAcqStartNumber:DataObj.DataBlockAcqStopNumber,:);       % future     
        end        
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,DataObj,log)
            obj.Aves = floor(obj.TotalAcqs/obj.NumTraj);
            BlocksPerImage = obj.TotalBlockReads/obj.Aves;
            %--
            Struct = load(obj.StitchMetaData.Eum);
            UserMash = Struct.UserMash;
            %--
            for n = 1:BlocksPerImage
                Start = (n-1)*obj.DataBlockLength + 1;
                Stop = n*obj.DataBlockLength;
                if Stop > obj.NumTraj
                    Stop = obj.NumTraj;
                end
                TrajInd = Start:Stop;
                AcqUse = (UserMash(TrajInd,2).'-1)*obj.NumTraj + TrajInd;
                TempDataObj.Data = obj.Data(:,AcqUse,:);
                %TempDataObj.ReconInfoMat = obj.Data(:,Start:Stop,:);            % future
                TempDataObj.DataBlockAcqStartNumber = Start;
                TempDataObj.DataBlockAcqStopNumber = Stop;
                TempDataObj.DataBlockLength = obj.DataBlockLength;
                TempDataObj.NumCol = obj.NumCol;
                StitchGridDataBlock(obj,TempDataObj,log); 
            end
            StitchFftCombine(obj,log);   
        end     
        
%==================================================================
% StitchFftCombine (subclass)
%==================================================================      

%==================================================================
% StitchReturnImage (subclass)
%==================================================================                    
        
%==================================================================
% CreateLoadSuperFilter (subclass)
%==================================================================         
    end
end