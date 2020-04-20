%==================================================
% 
%==================================================

function PerformPostAcqReconReturnAll(PARECON,DataFile)

%--------------------------------------
% Get Siemens Data Info
%--------------------------------------  
disp('Read Siemens Header');
DATA = ReadSiemens(DataFile,PARECON.BlockSize);
PARECON.Info = DATA.Info;

%--------------------------------------
% Allocate Host Memory
%--------------------------------------  
disp('Allocate Host Space for Image');
Channels = DATA.Dims.NCha;
PARECON.InitializeImage(Channels);

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
            GpuChan = p;
            ChanNum = (p-1)*PARECON.RECON.NumGpuUsed+m;
            SampDat0 = SampDat(:,:,ChanNum);                                                % this operation is a bit slow...
            PARECON.RECON.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                  % write different channels to different GPUs
            PARECON.RECON.GridSampDat(GpuNum,GpuChan);
            disp(['Grid:  GPU ',num2str(m),', RxChannel ',num2str(ChanNum)]);
        end
    end
end
PARECON.RECON.CudaDeviceWait(PARECON.RECON.NumGpuUsed-1);

%--------------------------------------
% Fourier Transform
%-------------------------------------- 
for p = 1:PARECON.ChanPerGpu
    for m = 1:PARECON.RECON.NumGpuUsed
        GpuNum = m-1;
        GpuChan = p;
        ChanNum = (p-1)*PARECON.RECON.NumGpuUsed+m;
        PARECON.RECON.KspaceScaleCorrect(GpuNum,GpuChan); 
        PARECON.RECON.KspaceFourierTransformShift(GpuNum,GpuChan);                 
        PARECON.RECON.InverseFourierTransform(GpuNum,GpuChan);
        PARECON.RECON.ImageFourierTransformShift(GpuNum,GpuChan);          
        PARECON.RECON.MultInvFilt(GpuNum,GpuChan);  
        disp(['Fourier Transform:  GPU ',num2str(m),', RxChannel ',num2str(ChanNum)]);
    end
end

%--------------------------------------
% Return Data
%-------------------------------------- 
Scale = 1e10;  % for Siemens
for p = 1:PARECON.ChanPerGpu
    for m = 1:PARECON.RECON.NumGpuUsed
        GpuNum = m-1;
        GpuChan = p;
        ChanNum = (p-1)*PARECON.RECON.NumGpuUsed+m;
        PARECON.RECON.ScaleImage(GpuNum,GpuChan,Scale); 
        PARECON.Image(:,:,:,:,ChanNum) = PARECON.RECON.ReturnOneImageMatrixGpuMem(GpuNum,GpuChan);
        disp(['Return Image:  GPU ',num2str(m),', RxChannel ',num2str(ChanNum)]);
    end
end

disp('Permute/Flip');
PARECON.Image = permute(PARECON.Image,[2 1 3 4 5 6 7]);
PARECON.Image = flip(PARECON.Image,2);

%--------------------------------------
% Free GPU Memory
%-------------------------------------- 
disp('Free GPU Memory');
PARECON.RECON.FreeReconInfoGpuMem;
PARECON.RECON.FreeSampDatGpuMem; 
PARECON.RECON.FreeKspaceImageMatricesGpuMem;




    
