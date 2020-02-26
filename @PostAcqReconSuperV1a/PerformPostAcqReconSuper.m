%==================================================
% 
%==================================================

function PerformPostAcqReconSuper(PARECON)

%--------------------------------------
% Allocate Host Memory
%--------------------------------------  
disp('Allocate CPU Memory for Scanner Data');
PARECON.DATA.AllocateDataMemory(PARECON.BlockSize,PARECON.ChanPerGpu,PARECON.GpuNum);
disp('Allocate CPU Memory for Image');
NumExp = 1;
PARECON.Image = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'));
PARECON.ImageHighSoS = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'));
PARECON.ImageLowSoS = zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single');
PARECON.ImageHighSoSArr = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,PARECON.GpuNum],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,PARECON.GpuNum],'single'));
PARECON.ImageLowSoSArr = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,PARECON.GpuNum],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,PARECON.GpuNum],'single'));

%--------------------------------------
% Allocate memory (on all GPUs)
%--------------------------------------  
disp('Allocate GPU Memory');
ReconInfoSize = [PARECON.NumCol PARECON.BlockSize 4];
PARECON.RECON.AllocateReconInfoGpuMem(ReconInfoSize);                       
SampDatSize = [PARECON.NumCol PARECON.BlockSize];
PARECON.RECON.AllocateSampDatGpuMem(SampDatSize);  
PARECON.RECON.AllocateKspaceImageMatricesGpuMem(PARECON.ZeroFill);
PARECON.RECON.AllocateSuperMatricesGpuMem;

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
    Blk.Start = (n-1)*PARECON.BlockSize+PARECON.Dummies+1;
    Blk.Stop = n*PARECON.BlockSize+PARECON.Dummies;
    if Blk.Stop > PARECON.NumTraj
        Blk.Stop = PARECON.NumTraj;
    end
    Blk.Lines = Blk.Stop-Blk.Start+1;
    Samp.Start = PARECON.SampStart;
    Samp.End = PARECON.SampStart+PARECON.NumCol-1;
    tic
    SampDat = PARECON.DATA.ReadSiemensDataBlock(Blk,Samp);
    toc
    for p = 1:PARECON.ChanPerGpu
        for m = 1:PARECON.RECON.NumGpuUsed
            GpuNum = m-1;
            GpuChan = p;
            ChanNum = (p-1)*PARECON.RECON.NumGpuUsed+m;
            SampDat0 = SampDat(:,:,ChanNum);                                                
            PARECON.RECON.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                 
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
% Super
%-------------------------------------- 
for p = 1:PARECON.ChanPerGpu
    for m = 1:PARECON.RECON.NumGpuUsed
        GpuNum = m-1;
        GpuChan = p;
        ChanNum = (p-1)*PARECON.RECON.NumGpuUsed+m;
        PARECON.RECON.ImageFourierTransformShift(GpuNum,GpuChan);
        PARECON.RECON.FourierTransform(GpuNum,GpuChan);
        PARECON.RECON.ImageFourierTransformShift(GpuNum,GpuChan);       % return to normal
        PARECON.RECON.KspaceFourierTransformShift(GpuNum,GpuChan); 
        PARECON.RECON.SuperKspaceFilter(GpuNum,GpuChan);
        PARECON.RECON.KspaceFourierTransformShift(GpuNum,GpuChan);         
        PARECON.RECON.InverseFourierTransformSpecify(GpuNum,PARECON.RECON.HSuperLow,PARECON.RECON.HKspaceMatrix(GpuChan,:));    
        PARECON.RECON.ImageFourierTransformShiftSpecify(GpuNum,PARECON.RECON.HSuperLow);          
        PARECON.RECON.CreateLowImageConjugate(GpuNum);
        PARECON.RECON.BuildLowSosImage(GpuNum);   
        PARECON.RECON.BuildHighSosImage(GpuNum,GpuChan);    
        disp(['Super Combine:  GPU ',num2str(m),', RxChannel ',num2str(ChanNum)]);         
    end
end

%--------------------------------------
% Return Data / Finish Super
%-------------------------------------- 
for m = 1:PARECON.RECON.NumGpuUsed
    GpuNum = m-1;
    PARECON.RECON.ReturnOneImageMatrixGpuMemSpecify(PARECON.ImageHighSoSArr(:,:,:,:,m),GpuNum,PARECON.RECON.HSuperHighSoS);
    disp(['Return Super High Images:  GPU ',num2str(m)]);
end
for m = 1:PARECON.RECON.NumGpuUsed
    GpuNum = m-1;
    PARECON.ImageLowSoSArr(:,:,:,:,m) = PARECON.RECON.ReturnOneImageMatrixGpuMemSpecify(GpuNum,PARECON.RECON.HSuperLowSoS);
    disp(['Return Super Low Images:  GPU ',num2str(m)]);
end

PARECON.RECON.CudaDeviceWait(PARECON.RECON.NumGpuUsed-1);

disp('Combine GPUs / Finish Super');
for m = 1:PARECON.RECON.NumGpuUsed
    PARECON.ImageHighSoS = PARECON.ImageHighSoS + PARECON.ImageHighSoSArr(:,:,:,:,m);
    PARECON.ImageLowSoS = PARECON.ImageLowSoS + real(PARECON.ImageLowSoSArr(:,:,:,:,m));
end
PARECON.Image = PARECON.ImageHighSoS./(sqrt(PARECON.ImageLowSoS));

disp('Permute/Flip');
PARECON.Image = permute(PARECON.Image,[2 1 3 4 5 6 7]);
PARECON.Image = flip(PARECON.Image,2);
Scale = 1e10;  % for Siemens
PARECON.Image = PARECON.Image*Scale/(PARECON.ReconPars.SubSamp^3);

%--------------------------------------
% Free GPU Memory
%-------------------------------------- 
disp('Free GPU Memory');
PARECON.RECON.FreeReconInfoGpuMem;
PARECON.RECON.FreeSampDatGpuMem; 
PARECON.RECON.FreeKspaceImageMatricesGpuMem;




    
