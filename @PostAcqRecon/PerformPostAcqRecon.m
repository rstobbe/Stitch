%==================================================
% 
%==================================================

function Image = PerformPostAcqRecon(PARECON,DataFile)

%--------------------------------------
% Get Siemens Data Info
%--------------------------------------  
disp('Read Siemens Header');
DATA = ReadSiemens(DataFile,PARECON.BlockSize);

%--------------------------------------
% Allocate memory (on all GPUs)
%--------------------------------------  
disp('Allocate GPU Memory');
ReconInfoSize = [PARECON.NumCol PARECON.BlockSize 4];
PARECON.RECON.AllocateReconInfoGpuMem(ReconInfoSize);                       
SampDatSize = [PARECON.NumCol PARECON.BlockSize];
PARECON.RECON.AllocateSampDatGpuMem(SampDatSize);  
PARECON.RECON.AllocateKspaceImageMatricesGpuMem(PARECON.ZeroFill);

ChunkNumber = 0;
for n = 1:PARECON.NumRuns
    ChunkNumber = ChunkNumber+1;    
    disp(['Chunk ',num2str(ChunkNumber)]);
    
    %--------------------------------------
    % Load ReconInfo
    %--------------------------------------          
    disp('Load ReconInfo');
    ReconInfo = PARECON.TrajData(:,(n-1)*PARECON.BlockSize+1:n*PARECON.BlockSize,:);
    PARECON.RECON.LoadReconInfoGpuMemAsync(ReconInfo);   % will write to all GPUs

    %--------------------------------------
    % ReadSiemensData
    %--------------------------------------      
    disp('Read Siemens');
    Blk.Start = (n-1)*PARECON.BlockSize+1;
    Blk.Stop = n*PARECON.BlockSize;
    if Blk.Stop > PARECON.NumTraj
        Blk.Stop = PARECON.NumTraj;
    end
    Blk.Lines = Blk.Stop-Blk.Start+1;
    Samp.Start = PARECON.SampStart;
    Samp.End = PARECON.SampStart+PARECON.NumCol-1;
    SampDat = DATA.ReadSiemensDataBlock(Blk,Samp);
    for p = 1:PARECON.ChanPerGpu
        for m = 1:PARECON.RECON.NumGpuUsed
            GpuNum = m-1;
            ChanNum = p;
            SampDat0 = SampDat(:,:,m);                                              % this operation is a bit slow...
            disp(['Grid GPU ',num2str(m),'; Channel ',num2str(p)]);
            PARECON.RECON.LoadSampDatGpuMemAsync(GpuNum,ChanNum,SampDat0);          % write different channels to different GPUs
            PARECON.RECON.GridSampDat(GpuNum,ChanNum);
        end
    end
end
PARECON.RECON.CudaDeviceWait(PARECON.RECON.NumGpuUsed-1);

%--------------------------------------
% Finish
%-------------------------------------- 
disp('Return Gridding');
Image = PARECON.RECON.ReturnOneKspaceMatrixGpuMem(1,1);
disp('Fourier Transform');
Image = ifftshift(ifftn(ifftshift(Image)));

% todo - allocate host memory with mex...
% ImageMatrix = single(complex(zeros(ImageMatrixSize),zeros(ImageMatrixSize)));    
% for m = 1:Info.Nchan
%     GpuNum = m-1;
%     ImageMatrix(:,:,:,m) = RECON.ReturnImageMatrixGpuMem(GpuNum);
%     ImageMatrix(:,:,:,m) = ifftshift(ifftn(ifftshift(ImageMatrix(:,:,:,m))));             % Fourier Transform
% end

%--------------------------------------
% Test
%-------------------------------------- 
figure(12341235);
test = max(abs(Image(:)))
sz = size(Image);
imshow(squeeze(abs(Image(:,:,sz(3)/2)))/test);





    
