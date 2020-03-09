%==================================================
% 
%==================================================

function TestRwsImageRecon_Kernel

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

Kernel = randn(400,400,400);
Kernel = single(Kernel);

iKern = 1;
cHw = 2;
tic
RECON.LoadKernelGpuMem(Kernel,iKern,cHw);
toc

TestGpuNum = 0;
tic
Kernel2 = RECON.TestKernelInGpuMem(TestGpuNum);
toc

test = isequal(Kernel,Kernel2)