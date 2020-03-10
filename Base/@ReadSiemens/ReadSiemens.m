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
        DataBlockSize;
        RxChannels;
        Data;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function DATA = ReadSiemens()
        end        

%==================================================================
% Define Data File
%==================================================================   
        function DefineDataFile(DATA,DataFile)
            ind = strfind(DataFile,'\');
            DATA.DataPath = DataFile(1:ind(end));
            DATA.DataFile = DataFile(ind(end)+1:end);
            DATA.DataName = DataFile(ind(end)+6:end-4);
        end        
        
%==================================================================
% Read Header
%==================================================================   
        function ReadSiemensHeader(DATA)
            ReadSiemensDataInfo(DATA,[DATA.DataPath,DATA.DataFile]);
        end
        
%==================================================================
%  SetDataBlockSize
%==================================================================   
        function SetDataBlockSize(DATA,DataBlockSize)
            DATA.DataBlockSize = DataBlockSize;
        end
               
       
%==================================================================
% Read Data Block
%================================================================== 
        function ReadSiemensDataBlock(DATA,Blk)
            Arr = Blk.Start:Blk.Stop;  
            QDataMemPosArr = uint64(DATA.DataMem.Pos(Arr) + DATA.DataScanHeaderBytes);                                  
            QDataReadSize = DATA.DataChannelHeaderBytes/8 + DATA.DataDims.NCol;
            QDataStart = DATA.DataChannelHeaderBytes/8 + DATA.SampStart;
            QDataCol = DATA.NumCol;
            QDataCha = DATA.DataDims.NCha;
            QDataBlockSize = DATA.DataBlockSize;
            QDataInfo = uint64([QDataReadSize QDataStart QDataCol QDataCha QDataBlockSize]); 
            DATA.Data = BuildDataArray([DATA.DataPath,DATA.DataFile],QDataMemPosArr,QDataInfo);
        end          
    end
end