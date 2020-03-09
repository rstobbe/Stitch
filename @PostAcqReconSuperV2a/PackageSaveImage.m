%==================================================
% 
%==================================================

function PARECON = PackageSaveImage(PARECON)

disp('Package and Save');
IMG.Method = PARECON.Method;
IMG.Im = PARECON.Image;
IMG.ReconInfo = PARECON.ReconInfo;
Info = PARECON.Info;
IMG.ExpPars = Info.ExpPars;

Panel(1,:) = {'','','Output'};
Panel(2,:) = {'',PARECON.Method,'Output'};
Panel(3,:) = {'',PARECON.ReconFile,'Output'};
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

%----------------------------------------------
% Save
%----------------------------------------------
IMG.path = PARECON.DataPath;
IMG.name = ['IMG_',PARECON.DataName,'_X'];
saveData.IMG = IMG;
save([IMG.path,IMG.name],'saveData');
