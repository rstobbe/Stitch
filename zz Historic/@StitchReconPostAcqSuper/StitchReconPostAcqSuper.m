%================================================================
%  
%================================================================

classdef StitchReconPostAcqSuper < StitchReconSuper

    properties (SetAccess = private)                    
        Data;
        %ReconInfoMat
        DataBlockLength;
        TotalBlockReads;
        TotalAcqs;
        NumCol;
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconPostAcqSuper()
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
        function StitchPostAcqProcess(obj,log)
            %--
            % build usermash here
            %--
            for n = 1:obj.TotalBlockReads
                Start = (n-1)*obj.DataBlockLength + 1;
                Stop = n*obj.DataBlockLength;
                if Stop > obj.TotalAcqs
                    Stop = obj.TotalAcqs;
                end
                DataObj.Data = obj.Data(:,Start:Stop,:);
                %DataObj.ReconInfoMat = obj.Data(:,Start:Stop,:);            % future
                DataObj.DataBlockAcqStartNumber = Start;
                DataObj.DataBlockAcqStopNumber = Stop;
                DataObj.DataBlockLength = obj.DataBlockLength;
                DataObj.NumCol = obj.NumCol;
                StitchGridDataBlock(obj,DataObj,log); 
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