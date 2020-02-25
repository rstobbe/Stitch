%================================================================
%  
%================================================================

classdef ReadSiemens < handle

    properties (SetAccess = private)                    
        DataFile;
        ScanHeaderBytes = 192;
        ChannelHeaderBytes = 32; 
        Hdr;
        Dims;
        Mem;
        Info;
        ReadSize;
        ComplexReadArr;
        ReadShape;
        BlockSize;
        Data;
    end
    methods 

%==================================================================
% Define
%==================================================================   
        function DATA = ReadSiemens(DataFile,BlockSize,ChanPerGpu,GpuNum)
            DATA.DataFile = DataFile;
            DATA = ReadSiemensDataInfo(DATA,DataFile);
            DATA.ReadSize = DATA.Dims.NCha*(DATA.ChannelHeaderBytes/4 + 2*DATA.Dims.NCol);
            DATA.ComplexReadArr = [2 DATA.ReadSize/2];
            DATA.ReadShape = [DATA.ChannelHeaderBytes/8+DATA.Dims.NCol,DATA.Dims.NCha]; 
            DATA.BlockSize = BlockSize;
            if ChanPerGpu*GpuNum < DATA.ReadShape(2)
                error('ChanPerGpu * Gpus < RxChannels');
            end
            %DATA.Data = complex(zeros([DATA.ReadShape(1),DATA.BlockSize,DATA.ReadShape(2)],'single'));
            DATA.Data = complex(zeros([DATA.ReadShape(1),DATA.BlockSize,ChanPerGpu*GpuNum],'single'));
        end

%==================================================================
% CreateImage
%================================================================== 
        function Data = ReadSiemensDataBlock(DATA,Blk,Samp)
            fid = fopen(DATA.DataFile,'r','l','US-ASCII');
            fseek(fid,0,'bof');
            Arr = Blk.Start:Blk.Stop;
            for n = 1:length(Arr)
                fseek(fid,DATA.Mem.Pos(Arr(n)) + DATA.ScanHeaderBytes,'bof');
                raw = fread(fid,DATA.ComplexReadArr,'float=>single').';
                DATA.Data(:,n,1:DATA.ReadShape(2)) = reshape(complex(raw(:,1),raw(:,2)),DATA.ReadShape);
            end
            Data = DATA.Data(DATA.ChannelHeaderBytes/8+(Samp.Start:Samp.End),:,:);
            if length(Arr) < DATA.BlockSize
                sz = size(Data);
                Data(:,length(Arr)+1:end,:) = complex(zeros([sz(1),DATA.BlockSize-length(Arr),sz(3)],'single'));
            end
            fclose(fid);
        end          
    end
end