%==================================================
% 
%==================================================

function TestRwsImageRecon_SampDat

%--------------------------------------
% Reset Gpus
%--------------------------------------
GpuNum = gpuDeviceCount;
for n = 1:GpuNum
    gpuDevice(n);               
end

%--------------------------------------
% Test SampDat
%--------------------------------------
GpuNum = 1;
Rcvrs = 1;
%Rcvrs = 2;
Proj = 10;
SampDat = complex((1000:-1:1),(1:1000)).';
SampDat = repmat(SampDat,1,Rcvrs,Proj,1);                       % read,rcvr,proj,sets (follow mapVBVD)
for m = 1:Rcvrs
    for n = 1:Proj
        SampDat(:,m,n) = SampDat(:,m,n)+(m-1)*1000+(n-1)*100;
    end
end
SampDat = single(SampDat);     

%--------------------------------------
% Sampling Load / Test
%--------------------------------------  
RECON = RwsImageRecon(GpuNum);
RECON.AssignSampDatHandle(SampDat);
%clear SampDat;

NumProjChunk = 2;               % how many projections to do at a time    
RECON.AllocateSampDatGpuMem(NumProjChunk);

ProjStart = 3;                  % C indexing
Rcvrs = 0;
Idx = 0;
RECON.LoadSampDatGpuMem(ProjStart,Rcvrs,Idx);

TestGpuNum = 0;
SampDat2 = RECON.TestSampDatInGpuMem(TestGpuNum);
SampDat2a = SampDat2(:,1);
SampDat2b = SampDat2(:,2);

