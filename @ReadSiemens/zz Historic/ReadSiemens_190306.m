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
        DataReadoutSize;
        DataReadSize;
        DataComplexReadArr;
        DataReadShape;
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
            DATA = ReadSiemensDataInfo(DATA,[DATA.DataPath,DATA.DataFile]);
            DATA.DataReadoutSize = DATA.DataChannelHeaderBytes/4 + 2*DATA.DataDims.NCol;
            DATA.DataReadSize = DATA.DataDims.NCha*DATA.DataReadoutSize;
            DATA.DataComplexReadArr = [2 DATA.DataReadSize/2];
            DATA.DataReadShape = [DATA.DataChannelHeaderBytes/8+DATA.DataDims.NCol,DATA.DataDims.NCha];
        end

%==================================================================
% Allocate Data Memory
%==================================================================   
        function AllocateCpuMemoryForData(DATA,DataBlockSize)
            DATA.DataBlockSize = DataBlockSize;
            if DATA.ChanPerGpu*DATA.NumGpuUsed < DATA.DataDims.NCha
                error('ChanPerGpu * Gpus < RxChannels');
            end
            DATA.Data = complex(zeros([DATA.DataReadShape(1),DATA.DataBlockSize,DATA.ChanPerGpu*DATA.NumGpuUsed],'single'));
        end        
        
%==================================================================
% Read Data Block
%================================================================== 
        function Data = ReadSiemensDataBlock(DATA,Blk)

            Arr = Blk.Start:Blk.Stop;  
            
%             tic
%             fid = fopen(DATA.DataFile,'r','l','US-ASCII');
%             fseek(fid,0,'bof');       
%             for n = 1:length(Arr)
%                 fseek(fid,DATA.DataMem.Pos(Arr(n)) + DATA.DataScanHeaderBytes,'bof');
%                 raw = fread(fid,DATA.DataComplexReadArr,'float=>single').';
%                 DATA.Data(:,n,1:DATA.DataReadShape(2)) = reshape(complex(raw(:,1),raw(:,2)),DATA.DataReadShape);
%             end
%             Data = DATA.Data(DATA.DataChannelHeaderBytes/8+(DATA.SampStart:DATA.SampEnd),:,:);
%             if length(Arr) < DATA.DataBlockSize
%                 sz = size(Data);
%                 Data(:,length(Arr)+1:end,:) = complex(zeros([sz(1),DATA.DataBlockSize-length(Arr),sz(3)],'single'));
%             end
%             fclose(fid);
%             toc
            
            tic
            QDataMemPosArr = uint64(DATA.DataMem.Pos(Arr) + DATA.DataScanHeaderBytes);                                  
            QDataReadSize = DATA.DataChannelHeaderBytes/8 + DATA.DataDims.NCol;
            QDataStart = DATA.DataChannelHeaderBytes/8 + DATA.SampStart;
            QDataCol = DATA.NumCol;
            QDataCha = DATA.DataDims.NCha;
            QDataInfo = uint64([QDataReadSize QDataStart QDataCol QDataCha]); 
            Data0 = BuildDataArray(DATA.DataFile,QDataMemPosArr,QDataInfo);
            toc
            
            tic
            Data0Complex = complex(Data0(1:2:end,:,:),Data0(2:2:end,:,:));
            toc
            
            %Test = sum(Data0Complex(:) - Data(:));
            
            Data = Data0Complex;
                   
        end          
    end
end