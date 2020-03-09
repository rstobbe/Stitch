%==================================================
% 
%==================================================

function PerformPostAcqReconSuper(PARECON)

%--------------------------------------
% Allocate Host Memory
%--------------------------------------  
disp('Allocate CPU Memory for Image');
NumExp = 1;
PARECON.Image = complex(zeros([PARECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.ImageMatrixMemDims,NumExp],'single'));
PARECON.ImageHighSoS = complex(zeros([PARECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.ImageMatrixMemDims,NumExp],'single'));
PARECON.ImageLowSoS = zeros([PARECON.ImageMatrixMemDims,NumExp],'single');
PARECON.ImageHighSoSArr = complex(zeros([PARECON.ImageMatrixMemDims,NumExp,PARECON.NumGpuUsed],'single'),zeros([PARECON.ImageMatrixMemDims,NumExp,PARECON.NumGpuUsed],'single'));
PARECON.ImageLowSoSArr = complex(zeros([PARECON.ImageMatrixMemDims,NumExp,PARECON.NumGpuUsed],'single'),zeros([PARECON.ImageMatrixMemDims,NumExp,PARECON.NumGpuUsed],'single'));

%--------------------------------------
% Allocate memory (on all GPUs)
%--------------------------------------  
PARECON.AllocateSuperMatricesGpuMem;

%--------------------------------------
% Grid
%--------------------------------------  
PARECON.GriddingTest;

%--------------------------------------
% Fourier Transform
%-------------------------------------- 
disp('Fourier Transform');
for p = 1:PARECON.ChanPerGpu
    for m = 1:PARECON.NumGpuUsed
        GpuNum = m-1;
        GpuChan = p;
        PARECON.KspaceScaleCorrect(GpuNum,GpuChan); 
        PARECON.KspaceFourierTransformShift(GpuNum,GpuChan);                 
        PARECON.InverseFourierTransform(GpuNum,GpuChan);
        PARECON.ImageFourierTransformShift(GpuNum,GpuChan);          
        PARECON.MultInvFilt(GpuNum,GpuChan); 
    end
end

%--------------------------------------
% Super
%-------------------------------------- 
disp('Super Combine');
for p = 1:PARECON.ChanPerGpu
    for m = 1:PARECON.NumGpuUsed
        GpuNum = m-1;
        GpuChan = p;
        PARECON.ImageFourierTransformShift(GpuNum,GpuChan);
        PARECON.FourierTransform(GpuNum,GpuChan);
        PARECON.ImageFourierTransformShift(GpuNum,GpuChan);       % return to normal
        PARECON.KspaceFourierTransformShift(GpuNum,GpuChan); 
        PARECON.SuperKspaceFilter(GpuNum,GpuChan);
        PARECON.KspaceFourierTransformShift(GpuNum,GpuChan);         
        PARECON.InverseFourierTransformSpecify(GpuNum,PARECON.HSuperLow,PARECON.HKspaceMatrix(GpuChan,:));    
        PARECON.ImageFourierTransformShiftSpecify(GpuNum,PARECON.HSuperLow);          
        PARECON.CreateLowImageConjugate(GpuNum);
        PARECON.BuildLowSosImage(GpuNum);   
        PARECON.BuildHighSosImage(GpuNum,GpuChan);           
    end
end

%--------------------------------------
% Return Data / Finish Super
%-------------------------------------- 
disp('Combine GPUs / Finish Super');
for m = 1:PARECON.NumGpuUsed
    GpuNum = m-1;
    PARECON.ImageHighSoSArr(:,:,:,:,m) = PARECON.ReturnOneImageMatrixGpuMemSpecify(PARECON.ImageHighSoSArr(:,:,:,:,m),GpuNum,PARECON.HSuperHighSoS);
end
for m = 1:PARECON.NumGpuUsed
    GpuNum = m-1;
    PARECON.ImageLowSoSArr(:,:,:,:,m) = PARECON.ReturnOneImageMatrixGpuMemSpecify(PARECON.ImageLowSoSArr(:,:,:,:,m),GpuNum,PARECON.HSuperLowSoS);
end
PARECON.CudaDeviceWait(PARECON.NumGpuUsed-1);
for m = 1:PARECON.NumGpuUsed
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
PARECON.FreeKspaceImageMatricesGpuMem;




    
