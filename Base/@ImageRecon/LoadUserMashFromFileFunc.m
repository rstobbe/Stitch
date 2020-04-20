%==================================================
% 
%==================================================

function PARECON = LoadUserMashFromFileFunc(PARECON)

%--------------------------------------
% Load Kernel
%--------------------------------------
disp('Retreive UserMash From HardDrive');
load(PARECON.UserMashFile);
PARECON.UserMash = UserMash;
