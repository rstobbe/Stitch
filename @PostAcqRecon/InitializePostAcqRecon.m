%==================================================
% 
%==================================================

function PARECON = InitializePostAcqRecon(PARECON,ReconInfo)

%--------------------------------------
% Reset Gpus
%--------------------------------------
reset = 1;
if reset == 1
    disp('Reset GPUs');
    GpuTot = gpuDeviceCount;
    for n = 1:GpuTot
        GpuParams = gpuDevice(n);               
    end
end

%--------------------------------------
% Build Object
%--------------------------------------
GpuTot = gpuDeviceCount;
PARECON.RECON = RwsImageRecon(GpuTot,GpuParams);

%--------------------------------------
% Load ReconInfo
%--------------------------------------
addpath(ReconInfo.Path);
ReconInfoFunc = str2func(ReconInfo.File);
ReconInfo = ReconInfoFunc();

%--------------------------------------
% Save Parameters
%--------------------------------------
PARECON.BlockSize = ReconInfo.BlockSize;
PARECON.ChanPerGpu = ReconInfo.ChanPerGpu;
PARECON.RECON.SetChanPerGpu(ReconInfo.ChanPerGpu);

%--------------------------------------
% Load Kernel
%--------------------------------------
load(ReconInfo.Kernel);
KRNprms = saveData.KRNprms;
iKern = round(1e9*(1/(KRNprms.res*KRNprms.DesforSS)))/1e9;
Kern = KRNprms.Kern;
chW = ceil(((KRNprms.W*KRNprms.DesforSS)-2)/2);                    
if (chW+1)*iKern > length(Kern)
    error;
end
disp('Load Kernel All GPUs');
PARECON.RECON.LoadKernelGpuMem(Kern,iKern,chW);

%--------------------------------------
% Load Trajectory
%--------------------------------------
disp('Load Trajectory Data');
load(ReconInfo.Trajectory);
IMP = saveData.IMP;
PROJdgn = IMP.PROJdgn;
PROJimp = IMP.PROJimp;
kstep = PROJdgn.kstep;
npro = PROJimp.npro;
nproj = PROJimp.nproj;
SS = KRNprms.DesforSS;
Kmat = IMP.Kmat;
SDC = IMP.SDC;
KSMP = IMP.KSMP;

%--------------------------------------
% Return Sampling
%--------------------------------------
PARECON.SampStart = KSMP.SampStart;
PARECON.NumCol = KSMP.nproRecon;
PARECON.NumTraj = PROJimp.nproj;

%---------------------------------------------
% Normalize Trajectories to Grid
%---------------------------------------------
[Ksz,Kx,Ky,Kz,C] = NormProjGrid_v4c(Kmat,nproj,npro,kstep,chW,SS,'M2M');       % this is slow - fix...
clear Kmat

%---------------------------------------------
% Test
%---------------------------------------------
ZF = 0;
ZFrel = 1;
if ZF == 0
    ZF = 2*round(ZFrel*Ksz/2);
end
if rem(ZF,2)
    error('Use a factor of 2 for Zero-Fill');
end
if Ksz > ZF
    error(['Zero-Fill is to small. Ksz = ',num2str(Ksz)]);
end

%---------------------------------------------
% k-Samp Shift
%---------------------------------------------
shift = (ZF/2+1)-((Ksz+1)/2);
Kx = Kx+shift;
Ky = Ky+shift;
Kz = Kz+shift;

%---------------------------------------------
% Merge - get order right
%---------------------------------------------
sz = size(Kx);
Kx = single(reshape(Kx,[1 sz]));
Ky = single(reshape(Ky,[1 sz]));
Kz = single(reshape(Kz,[1 sz]));
SDC = single(reshape(SDC,[1 sz]));
TrajData0 = cat(1,Kx,Ky,Kz,SDC);
TrajData0 = permute(TrajData0,[3 2 1]);

%---------------------------------------------
% Make multiple of block size
%---------------------------------------------
sz = size(TrajData0);
PARECON.NumRuns = ceil(sz(2)/PARECON.BlockSize);
PARECON.TrajData = C*ones([sz(1),PARECON.NumRuns*PARECON.BlockSize,4],'single');
PARECON.TrajData(:,1:sz(2),:) = TrajData0;

%---------------------------------------------
% Return Image Size / Setup FFT
%---------------------------------------------
PARECON.ZeroFill = [ZF ZF ZF];
PARECON.RECON.SetupFourierTransform(PARECON.ZeroFill);

