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

ChunkNumber = 0;
for n = 1:PARECON.NumRuns
    ChunkNumber = ChunkNumber+1;    
    disp(['Chunk ',num2str(ChunkNumber)]);
    
    %--------------------------------------
    % Load ReconInfo
    %--------------------------------------          
    disp('Load ReconInfo');
    ReconInfo = PARECON.TrajData(:,(n-1)*PARECON.DataBlockSize+1:n*PARECON.DataBlockSize,:);
    PARECON.LoadReconInfoGpuMemAsync(ReconInfo);   % will write to all GPUs

    %--------------------------------------
    % ReadSiemensData
    %--------------------------------------      
    disp('Read Siemens');
    Blk.Start = (n-1)*PARECON.DataBlockSize+PARECON.Dummies+1;
    Blk.Stop = n*PARECON.DataBlockSize+PARECON.Dummies;
    if Blk.Stop > PARECON.NumTraj
        Blk.Stop = PARECON.NumTraj;
    end
    Blk.Lines = Blk.Stop-Blk.Start+1;
    PARECON.ReadSiemensDataBlock(Blk);
    for p = 1:PARECON.ChanPerGpu
        for m = 1:PARECON.NumGpuUsed
            GpuNum = m-1;
            GpuChan = p;
            ChanNum = (p-1)*PARECON.NumGpuUsed+m;
            SampDat0 = PARECON.Data(:,:,ChanNum);                                                
            PARECON.LoadSampDatGpuMemAsync(GpuNum,GpuChan,SampDat0);                 
            PARECON.GridSampDat(GpuNum,GpuChan);
            disp(['Grid:  GPU ',num2str(m),', RxChannel ',num2str(ChanNum)]);
        end
    end
end
PARECON.CudaDeviceWait(PARECON.NumGpuUsed-1);

%--------------------------------------
% Free GPU Memory
%-------------------------------------- 
disp('Free GPU Memory');
PARECON.FreeReconInfoGpuMem;
PARECON.FreeSampDatGpuMem; 





    
