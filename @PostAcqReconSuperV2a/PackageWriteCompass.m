%==================================================
% 
%==================================================

function PARECON = PackageWriteCompass(PARECON)

disp('Package and Write Compass');
IMG.Method = PARECON.Method;
IMG.Im = PARECON.Image;
IMG.ReconInfo = PARECON.ReconInfo;
Info = PARECON.DataInfo;
IMG.ExpPars = Info.ExpPars;

Panel(1,:) = {'','','Output'};
Panel(2,:) = {'Stitch Function',PARECON.Method,'Output'};
Panel(3,:) = {'Recon Function',PARECON.ReconFile,'Output'};
PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
IMG.PanelOutput = [Info.PanelOutput;PanelOutput0];
IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);

%----------------------------------------------
% Set Up Compass Display
%----------------------------------------------
MSTRCT.type = 'abs';
MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
MSTRCT.ImInfo.pixdim = [PARECON.ReconPars.ImvoxTB,PARECON.ReconPars.ImvoxLR,PARECON.ReconPars.ImvoxIO];
MSTRCT.ImInfo.vox = PARECON.ReconPars.ImvoxTB*PARECON.ReconPars.ImvoxLR*PARECON.ReconPars.ImvoxIO;
MSTRCT.ImInfo.info = IMG.ExpDisp;
MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
INPUT.Image = IMG.Im;
INPUT.MSTRCT = MSTRCT;
IMDISP = ImagingPlotSetup(INPUT);
IMG.IMDISP = IMDISP;
IMG.type = 'Image';
IMG.path = PARECON.DataPath;

ind = strfind(PARECON.DataName,'_');
Mid = PARECON.DataName(1:ind(1)-1);
ind = strfind(Info.VolunteerID,'.');
if not(isempty(ind))
    Info.VolunteerID2 = Info.VolunteerID(ind(end)+1:end);
else
    Info.VolunteerID2 = Info.VolunteerID;
end

IMG.name = ['IMG_',Info.VolunteerID2,'_',Mid,'_',Info.Protocol,'_X'];

%----------------------------------------------
% Load Compass
%----------------------------------------------
totalgbl{1} = IMG.name;
totalgbl{2} = IMG;
from = 'CompassLoad';
Load_TOTALGBL(totalgbl,'IM',from);