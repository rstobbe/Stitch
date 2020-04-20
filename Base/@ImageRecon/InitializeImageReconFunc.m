%==================================================
% 
%==================================================

function PARECON = InitializeImageReconFunc(PARECON)

%--------------------------------------
% Load ReconInfo
%--------------------------------------
GpuTot = gpuDeviceCount;
addpath(PARECON.ReconPath);
if not(exist(PARECON.ReconFile,'file'))
    error(['Abort - ReconFile: ',PARECON.ReconFile,' does not exist']);
end
ReconInfoFunc = str2func(PARECON.ReconFile);
ReconInfo = ReconInfoFunc(PARECON.DataInfo,GpuTot);
PARECON.ReconInfo = ReconInfo;

%--------------------------------------
% Initizize RwsImageRecon Object
%--------------------------------------
GpuParams = gpuDevice; 
PARECON.InitGpuInterface(GpuTot,GpuParams,ReconInfo.ChanPerGpu);

%--------------------------------------
% Load Kernel
%--------------------------------------
disp('Retreive Kernel From HardDrive');
load(ReconInfo.Kernel);
KRNprms = saveData.KRNprms;
iKern = round(1e9*(1/(KRNprms.res*KRNprms.DesforSS)))/1e9;
Kern = KRNprms.Kern;
chW = ceil(((KRNprms.W*KRNprms.DesforSS)-2)/2);                    
if (chW+1)*iKern > length(Kern)
    error;
end
disp('Load Kernel All GPUs');
PARECON.LoadKernelGpuMem(Kern,iKern,chW,KRNprms.convscaleval);

%--------------------------------------
% Load Inverse Filter
%--------------------------------------
disp('Retreive InvFilt From HardDrive');
load(ReconInfo.InvFilt);
disp('Load InvFilt All GPUs');
IFprms = saveData.IFprms;
ZF = IFprms.ZF;
InvFilt = IFprms.V;
PARECON.LoadInvFiltGpuMem(InvFilt);

%--------------------------------------
% Load Trajectory
%--------------------------------------
disp('Retreive Trajectory Info From HardDrive');
warning 'off';                          % because trys to find functions not on path
load(ReconInfo.Trajectory);
warning 'on';
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
% Return ReconPars
%--------------------------------------
ReconPars.Imfovx = SS*IMP.PROJdgn.fov;
ReconPars.Imfovy = SS*IMP.PROJdgn.fov;                 
ReconPars.Imfovz = SS*IMP.PROJdgn.fov;
ReconPars.ImvoxLR = ReconPars.Imfovy/ZF;
ReconPars.ImvoxTB = ReconPars.Imfovx/ZF;
ReconPars.ImvoxIO = ReconPars.Imfovz/ZF;
ReconPars.ImszLR = ZF;
ReconPars.ImszTB = ZF;
ReconPars.ImszIO = ZF;
ReconPars.SubSamp = SS;
PARECON.ReconPars = ReconPars;

%--------------------------------------
% Return Sampling
%--------------------------------------
PARECON.NumCol = KSMP.nproRecon;
PARECON.NumTraj = PROJimp.nproj;
PARECON.Dummies = IMP.dummies;
PARECON.SampStart = KSMP.SampStart;
PARECON.SampEnd = PARECON.SampStart+PARECON.NumCol-1;

%--------------------------------------
% Determine Number of Averages
%--------------------------------------
PARECON.NumAverages = PARECON.DataDims.Lin/PARECON.NumTraj;
if round(PARECON.NumAverages)*PARECON.NumTraj ~= PARECON.DataDims.Lin
    error
end

%--------------------------------------
% Set DataBlockSize
%--------------------------------------
PARECON.SetDataBlockSize(ReconInfo.BlockSize);                

%---------------------------------------------
% Normalize Trajectories to Grid
%---------------------------------------------
disp('Normalize Trajectories to Grid');
[Ksz,Kx,Ky,Kz,C] = NormProjGrid_v4c(Kmat,nproj,npro,kstep,chW,SS,'M2M');       % this is slow - fix...
clear Kmat

%---------------------------------------------
% Test
%---------------------------------------------
if Ksz > ZF
    error(['Zero-Fill is to small. Ksz = ',num2str(Ksz)]);
end

%---------------------------------------------
% k-Samp Shift
%---------------------------------------------
disp('Manipulate Trajectories');
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
PARECON.NumRuns = ceil(sz(2)/PARECON.DataBlockSize);
PARECON.TrajData = C*ones([sz(1),PARECON.NumRuns*PARECON.DataBlockSize,4],'single');
PARECON.TrajData(:,1:sz(2),:) = TrajData0;

%---------------------------------------------
% Return Image Size / Setup FFT
%---------------------------------------------
disp('Setup Fourier Transform');
PARECON.ZeroFill = [ZF ZF ZF];
PARECON.SetupFourierTransform(PARECON.ZeroFill);


