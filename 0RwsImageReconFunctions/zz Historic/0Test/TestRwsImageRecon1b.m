%==================================================
% 
%==================================================

clear
%--------------------------------------
% Reset Gpus
%--------------------------------------
NumberOfGpus = gpuDeviceCount;
for n = 1:NumberOfGpus
    gpuDevice(n);               
end

%--------------------------------------
% RwsImageRecon Start
%--------------------------------------         
whos
NumberOfGpus = 1;
RECON = RwsImageRecon(NumberOfGpus);

%--------------------------------------
% Load Data
%--------------------------------------
twix = mapVBVD('D:\Compass\1 Scripts\zs Shared\2 Image Construction\0GpuReconFunctions\0Test\meas_MID00150_FID161070_23Na_Tr20.dat');
fclose('all');
if length(twix) == 2
    twix = twix{2};                         % 2nd 'image' is the relevant one if 'setup' performed as well
elseif length(twix) == 3
    twix = twix{3};                         % don't know why there would be 3 images
end
DataInfo = twix.image;
Phoenix = twix.hdr.Phoenix;                 % seems to have the most info neatly organized
MrProt = Phoenix;

%---------------------------------------------
% Rearrange
%---------------------------------------------        
SampDat = twix.image(); 
RECON.AssignSampDatHandle(SampDat);
sz = size(SampDat);
NumProjChunk = sz(3);  
RECON.AllocateSampDatGpuMem(NumProjChunk);

%--------------------------------------
% Load
%--------------------------------------
load('D:\Compass\3 ReconFiles\TPI_F280_V1162_E100_T200_N3000_P150_ID1010.mat');
Kmat = saveData.IMP.Kmat;
SampStart = saveData.IMP.KSMP.DiscardStart+1;
Sdc = saveData.IMP.SDC;
kstep = saveData.IMP.PROJdgn.kstep;
clear saveData;
Kmat = permute(Kmat,[3 2 1]);
Sdc = permute(Sdc,[3 2 1]);
ReconInfo = cat(1,Kmat,Sdc);
clear Kmat;
clear Sdc;
ReconInfo = single(ReconInfo);
%---
load('D:\Compass\4 OtherFiles\Gridding\Kernels\Kern_KBCw2b5p5ss1p6.mat');
KRNprms = saveData.KRNprms;
Kernel = KRNprms.Kern;
iKern = round(1e9*(1/(KRNprms.res*KRNprms.DesforSS)))/1e9;
KernHw = ceil(((KRNprms.W*KRNprms.DesforSS)-2)/2); 
clear saveData;
%---
rad = sqrt(ReconInfo(1,:,:).^2 + ReconInfo(2,:,:).^2 + ReconInfo(3,:,:).^2);
kmax = max(rad(:));
centre = ceil(KRNprms.DesforSS*kmax/kstep) + (KernHw + 2);   
ReconInfo(1:3,:,:) = KRNprms.DesforSS*(ReconInfo(1:3,:,:)/kstep) + centre;
Ksz = centre*2 - 1;
clear KRNprms;
clear rad;
%---
ZeroFill = 112;
shift = (ZeroFill/2+1)-((Ksz+1)/2);
ReconInfo(1:3,:,:) = ReconInfo(1:3,:,:)+shift;

%-------------------------------------- 
% Load
%-------------------------------------- 
RECON.LoadReconInfoGpuMem(ReconInfo);
RECON.LoadKernelGpuMem(Kernel,iKern,KernHw);
RECON.AllocateImageMatrixGpuMem([ZeroFill,ZeroFill,ZeroFill]);

%--------------------------------------
% Sampling Load 
%--------------------------------------  
sz = size(ReconInfo);
SampDat = ones(sz(2),1,sz(3),'single') + 1i*ones(sz(2),1,sz(3),'single');
RECON.AssignSampDatHandle(SampDat);
NumProjChunk = sz(3);  
RECON.AllocateSampDatGpuMem(NumProjChunk);
ProjStart = 0;                  % C indexing
Rcvrs = 0;
Idx = 0;
RECON.LoadSampDatGpuMem(ProjStart,Rcvrs,Idx);

%--------------------------------------
% Grid
%--------------------------------------  
tic
RECON.GridSampDat;
toc

TestGpuNum = 0;
ImageMatrix = RECON.ReturnImageMatrixGpuMem(TestGpuNum);

figure(12341234);
plot(real(squeeze(ImageMatrix(57,57,:))));

