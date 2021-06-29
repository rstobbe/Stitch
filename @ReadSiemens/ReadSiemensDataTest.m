function ReadSiemensDataTest(filename)

ScanHeaderBytes    = 192; 
ChannelHeaderBytes =  32; 

[Hdr,Dims,Mem] = ReadSiemensDataInfo(filename);

fid = fopen(filename,'r','l','US-ASCII');
fseek(fid,0,'bof');

ReadSize = Dims.NCha*(ChannelHeaderBytes/4 + 2*Dims.NCol);
ComplexReadArr = [2 ReadSize/2];
ReadShape = [ChannelHeaderBytes/8+Dims.NCol,Dims.NCha];

%Lines = Dims.Lin;
Lines = 200;
Data0 = complex(zeros([ReadShape(1),Lines,ReadShape(2)],'single'));
for n = 1:Lines
    fseek(fid,Mem.Pos(n) + ScanHeaderBytes,'bof');
    raw = fread(fid,ComplexReadArr,'float=>single').';
    Data0(:,n,:) = reshape(complex(raw(:,1),raw(:,2)),ReadShape);
end
Data = Data0(ChannelHeaderBytes/8+1:end,:,:);

%---------------------------------
% Test
%---------------------------------
twix = mapVBVD(filename);
FIDmat = twix{2}.image();
FIDmat = permute(FIDmat,[1 3 2]);
Test0 = Data - FIDmat(:,1:Lines,:);
Test = sum(Test0(:))
%---------------------------------