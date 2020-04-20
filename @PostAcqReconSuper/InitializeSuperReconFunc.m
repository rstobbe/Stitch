%==================================================
% 
%==================================================

function PARECON = InitializeSuperReconFunc(PARECON)

%--------------------------------------
% Super Filter
%-------------------------------------- 
disp('Create Super Filter');
SUPER.ProfRes = PARECON.ReconInfo.Super.ProfRes;
SUPER.ProfFilt = PARECON.ReconInfo.Super.ProfFilt;
SUPER.ImDims = PARECON.ImageMatrixMemDims;
SuperFilt = CreateSuperFilter(PARECON.ReconPars,SUPER);
PARECON.LoadSuperFiltGpuMem(SuperFilt);

