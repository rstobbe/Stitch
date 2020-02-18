%==================================================
% 
%==================================================

function TestRwsImageRecon_ReconInfo

%--------------------------------------
% Reset Gpus
%--------------------------------------
GpuNum = gpuDeviceCount;
for n = 1:GpuNum
    gpuDevice(n);               
end
                        
%--------------------------------------
% RwsImageRecon Start
%--------------------------------------         
RECON = RwsImageRecon(GpuNum);

ReconInfo = (1:1000);
ReconInfo = repmat(ReconInfo,4,1,10);
ReconInfo(1,:,1) = randn(1,1000);
ReconInfo = single(ReconInfo);

RECON.LoadReconInfoGpuMem(ReconInfo);

TestGpuNum = 1;
ReconInfo2 = RECON.TestReconInfoInGpuMem(TestGpuNum);

test = isequal(ReconInfo,ReconInfo2)
