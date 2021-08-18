%================================================================
%  
%================================================================

classdef ReadSiemens < handle

    properties (SetAccess = private)                    
        DataFile; DataPath; DataName;
        DataScanHeaderBytes = 192;
        DataChannelHeaderBytes = 32; 
        DataHdr;
        DataDims;
        DataMem;
        DataInfo;
        DataBlockLength = 500;          % Default
        DataBlockNumber;
        TotalBlockReads;
        TotalAcqs;
        AcqsPerImage;
        RxChannels;
        ScanDummies;
        SampStart;
        NumCol;
        NumAverages;
        Format;
        DataBlockAcqStartNumber;
        DataBlockAcqStopNumber;
        DataBlock;
        ReadSiemensDataBlockFinished;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function obj = ReadSiemens()
        end        

%==================================================================
% SetSiemensDataFile
%==================================================================   
        function SetSiemensDataFile(obj,DataFile)
            ind = strfind(DataFile,'\');
            if isempty(ind)
                error('Data path not specified properly');
            end
            obj.DataPath = DataFile(1:ind(end));
            obj.DataFile = DataFile(ind(end)+1:end);
            if strcmp(DataFile(ind(end)+1:ind(end)+4),'meas')
                obj.DataName = DataFile(ind(end)+6:end-4);
            else
                obj.DataName = DataFile(ind(end)+1:end-4);
            end
        end           

%==================================================================
% SetDataBlockLength
%==================================================================           
        function SetDataBlockLength(obj,BlockLength)
            obj.DataBlockLength = BlockLength;
        end

%==================================================================
% SetDataBlockLengthFull
%==================================================================           
        function SetDataBlockLengthFull(obj)
            obj.DataBlockLength = obj.DataDims.Lin * obj.DataDims.NAve;
        end        
        
%==================================================================
% ReadSiemensHeader
%==================================================================   
        function ReadSiemensHeader(obj)
            ReadSiemensDataInfo(obj,[obj.DataPath,obj.DataFile]);
            %obj.NumAverages = obj.DataHdr.lAverages;
            obj.NumAverages = obj.DataDims.NAve;                % number of averages not being recorded in MDH properly (fix)
        end        

%==================================================================
% ReadSiemensDataBlockInit
%================================================================== 
        function ReadSiemensDataBlockInit(obj,DataReadInfo)
            obj.ScanDummies = DataReadInfo.ScanDummies;
            obj.SampStart = DataReadInfo.SampStart;
            obj.Format = DataReadInfo.Format;
            obj.NumCol = DataReadInfo.NumCol;
            obj.AcqsPerImage = obj.DataDims.Lin;                % includes dummies
            if isempty(obj.DataBlockLength)
                obj.DataBlockLength = obj.DataDims.Lin;
            end
            obj.TotalAcqs = obj.DataDims.Lin * obj.DataDims.NAve;
            obj.TotalBlockReads = ceil(obj.TotalAcqs/obj.DataBlockLength);
            obj.DataBlockNumber = 0;
            obj.ReadSiemensDataBlockFinished = 0;
        end        
        
%==================================================================
% ReadSiemensDataBlock
%================================================================== 
        function ReadSiemensDataBlock(obj)
            obj.DataBlockNumber = obj.DataBlockNumber + 1;
            obj.DataBlockAcqStartNumber = (obj.DataBlockNumber-1)*obj.DataBlockLength + 1;
            obj.DataBlockAcqStopNumber = obj.DataBlockNumber*obj.DataBlockLength;
            Blk.Start = obj.DataBlockAcqStartNumber;
            Blk.Stop = obj.DataBlockAcqStopNumber;
            if Blk.Stop > obj.TotalAcqs
                Blk.Stop = obj.TotalAcqs;
                obj.DataBlockAcqStopNumber = obj.TotalAcqs;
            end
            Blk.Lines = Blk.Stop-Blk.Start+1;
            obj.ReadSiemensData(Blk); 
            if obj.DataBlockNumber == obj.TotalBlockReads
                obj.ReadSiemensDataBlockFinished = 1;
            end
        end
              
%==================================================================
% ReadSiemensData
%================================================================== 
        function ReadSiemensData(obj,Blk)
            Arr = Blk.Start:Blk.Stop;  
            QDataMemPosArr = uint64(obj.DataMem.Pos(Arr) + obj.DataScanHeaderBytes);                                  
            QDataReadSize = obj.DataChannelHeaderBytes/8 + obj.DataDims.NCol;
            QDataStart = obj.DataChannelHeaderBytes/8 + obj.SampStart;
            QDataCol = obj.NumCol;
            QDataCha = obj.DataDims.NCha;
            QDataBlockLength = obj.DataBlockLength;
            QDataInfo = uint64([QDataReadSize QDataStart QDataCol QDataCha QDataBlockLength]);
            if strcmp(obj.Format,'SingleArray')
                obj.DataBlock = BuildDataArray([obj.DataPath,obj.DataFile],QDataMemPosArr,QDataInfo);
            elseif strcmp(obj.Format,'Complex')
                error('finish');
            end
        end
 
%==================================================================
% ExtractSequenceParams
%==================================================================         
        function Params = ExtractSequenceParams(obj,SeqParams)
            for n = 1:length(SeqParams)
                switch SeqParams{n}
                    case 'TR'
                        Params{n} = obj.DataHdr.alTR{1}/1000;
                    case 'NumAverages'
                        obj.NumAverages = obj.DataHdr.lAverages;                % something wrong with 'obj.DataDims.NAve' 
                        Params{n} = obj.DataHdr.lAverages;
                end
            end
        end

%==================================================================
% ZeroData
%==================================================================         
        function ZeroData(obj,ZeroDataInds)
            obj.DataBlock(:,ZeroDataInds,:) = 0;
        end        
        
    end
end