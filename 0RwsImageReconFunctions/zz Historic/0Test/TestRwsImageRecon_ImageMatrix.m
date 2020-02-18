%==================================================
% 
%==================================================

function TestRwsImageRecon_ImageMatrix

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
NumberOfGpus = 1;
RECON = RwsImageRecon(NumberOfGpus);

ZeroFill = 1000;
RECON.AllocateImageMatrixGpuMem([ZeroFill,ZeroFill,ZeroFill]);

TestGpuNum = 0;
tic
ImageMatrix = RECON.ReturnImageMatrixGpuMem(TestGpuNum);
toc

test = sum(ImageMatrix(:))