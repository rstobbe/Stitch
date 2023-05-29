%==================================================================
% ReturnOneKspaceCompass
%================================================================== 

function ReturnOneKspaceCompass(Recon,Name)

    IMG.Method = class(Recon);
    IMG.Im = Recon.Kspace;  
    Info = Recon.DataObj.DataInfo;           % Base on first
    IMG.ExpPars = Info.ExpPars;

    Panel(1,:) = {'','','Output'};
    Panel(2,:) = {'Recon Function',IMG.Method,'Output'};
    PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
    IMG.PanelOutput = [PanelOutput0;Info.PanelOutput];
    IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
 
    %----------------------------------------------
    % Set Up Compass Display
    %----------------------------------------------
    MSTRCT.type = 'abs';
    MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
    MSTRCT.ImInfo.pixdim = [1 1 1];
    MSTRCT.ImInfo.vox = 1;
    MSTRCT.ImInfo.info = IMG.ExpDisp;
    MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
    INPUT.Image = IMG.Im;
    INPUT.MSTRCT = MSTRCT;
    IMDISP = ImagingPlotSetup(INPUT);
    IMG.IMDISP = IMDISP;
    IMG.type = 'Image';
    IMG.path = Recon.DataObj.DataPath;

%     ind = strfind(Recon.DataObj{1}.DataName,'_');
%     Mid = Recon.DataObj{1}.DataName(1:ind(1)-1);
%     ind = strfind(Info.VolunteerID,'.');
%     if not(isempty(ind))
%         Info.VolunteerID2 = Info.VolunteerID(ind(end)+1:end);
%     else
%         Info.VolunteerID2 = Info.VolunteerID;
%     end
%     IMG.name = ['IMG_',Info.VolunteerID2,'_',Mid,'_',Info.Protocol,'_X'];
    if nargin == 1
        IMG.name = ['KSP_',Recon.DataObj.DataName];
    elseif nargin == 2
        IMG.name = ['KSP_',Name];
    end

    %----------------------------------------------
    % Load Compass
    %----------------------------------------------
    totalgbl{1} = IMG.name;
    totalgbl{2} = IMG;
    from = 'CompassLoad';
    Load_TOTALGBL(totalgbl,'IM',from);
end

