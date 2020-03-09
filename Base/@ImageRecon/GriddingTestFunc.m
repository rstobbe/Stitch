%==================================================
% 
%==================================================

function GriddingTestFunc(PARECON)

%--------------------------------------
% Allocate memory (on all GPUs)
%--------------------------------------  
disp('Allocate GPU Memory for Gridding');
ReconInfoSize = [PARECON.NumCol PARECON.DataBlockSize 4];
PARECON.AllocateReconInfoGpuMem(ReconInfoSize);                       
SampDatSize = [PARECON.NumCol PARECON.DataBlockSize];
PARECON.AllocateSampDatGpuMem(SampDatSize);  
PARECON.AllocateKspaceImageMatricesGpuMem(PARECON.ZeroFill);

%--------------------------------------
% GPU Recon
%-------------------------------------- 
ChunkNumber = 0;
fprintf('Chunk ');
for n = 1:PARECON.NumRuns
    ChunkNumber = ChunkNumber+1;
    fprintf(num2str(ChunkNumber));
        
    %disp('Read Siemens');
    Blk.Start = (n-1)*PARECON.DataBlockSize+PARECON.Dummies+1;
    Blk.Stop = n*PARECON.DataBlockSize+PARECON.Dummies;
    if Blk.Stop > PARECON.NumTraj
        Blk.Stop = PARECON.NumTraj;
    end
    Blk.Lines = Blk.Stop-Blk.Start+1;
    PARECON.ReadSiemensDataBlock(Blk);
            
    %disp('Load ReconInfo');
    ReconInfo = PARECON.TrajData(:,(n-1)*PARECON.DataBlockSize+1:n*PARECON.DataBlockSize,:);
    PARECON.LoadReconInfoGpuMemAsync(ReconInfo);   % will write to all GPUs    
    
    %disp('Load Data Gpu');
    for p = 1:PARECON.ChanPerGpu
        for m = 1:PARECON.NumGpuUsed
            GpuNum = m-1;
            GpuChan = p;
            ChanNum = (p-1)*PARECON.NumGpuUsed+m;
            SampDat0 = PARECON.Data(:,:,ChanNum);                                                
            PARECON.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                 
        end
    end    
    
    %disp('Grid Chunk');
    for p = 1:PARECON.ChanPerGpu
        for m = 1:PARECON.NumGpuUsed
            GpuNum = m-1;
            GpuChan = p;                                                     
            PARECON.GridSampDat(GpuNum,GpuChan);
        end
    end
    if n == PARECON.NumRuns
        fprintf('\n');
    elseif n < 10
        fprintf('\b');
    elseif n < 100
        fprintf('\b\b');
    elseif n < 1000
        fprintf('\b\b\b');
    end
end
PARECON.CudaDeviceWait(PARECON.NumGpuUsed-1);

%--------------------------------------
% Free GPU Memory
%-------------------------------------- 
PARECON.FreeReconInfoGpuMem;
PARECON.FreeSampDatGpuMem; 





    
