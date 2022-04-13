%==================================================================
% CompassImageCompass
%================================================================== 

function ReturnOneImageCompass(Recon)

    IMG.Method = class(Recon);
    IMG.Im = Recon.Image;             
    Panel(1,:) = {'','','Output'};
    Panel(2,:) = {'Recon Function',IMG.Method,'Output'};
    PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
    for i = 1: size(Recon.DataObj,2)
        Info(i) = Recon.DataObj{i}.DataInfo;
        %Info = Recon.DataObj.DataInfo;           % Base on first
        IMG.ExpPars(i) = Info(i).ExpPars;
        IMG.PanelOutput{i} = [PanelOutput0;Info(i).PanelOutput];
        IMG.ExpDisp{i} = PanelStruct2Text(IMG.PanelOutput{i});

    end
        
        
    %{    
    %Info = Recon.DataObj.DataInfo;           % Base on first
    IMG.ExpPars = Info.ExpPars;

    Panel(1,:) = {'','','Output'};
    Panel(2,:) = {'Recon Function',IMG.Method,'Output'};
    PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
    IMG.PanelOutput = [PanelOutput0;Info.PanelOutput];
    IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
 %}
    %----------------------------------------------
    % Set Up Compass Display
    %----------------------------------------------
    PixDims = Recon.Stitch.PixDims;
    MSTRCT.type = 'abs';
    MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
    MSTRCT.ImInfo.pixdim = PixDims;
    MSTRCT.ImInfo.vox = PixDims(1)*PixDims(2)*PixDims(3);
    MSTRCT.ImInfo.info = IMG.ExpDisp;
    MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
    INPUT.Image = IMG.Im;
    INPUT.MSTRCT = MSTRCT;
    IMDISP = ImagingPlotSetup(INPUT);
    IMG.IMDISP = IMDISP;
    IMG.type = 'Image';
    IMG.path = Recon.DataObj{1}.DataPath;

%     ind = strfind(Recon.DataObj{1}.DataName,'_');
%     Mid = Recon.DataObj{1}.DataName(1:ind(1)-1);
%     ind = strfind(Info.VolunteerID,'.');
%     if not(isempty(ind))
%         Info.VolunteerID2 = Info.VolunteerID(ind(end)+1:end);
%     else
%         Info.VolunteerID2 = Info.VolunteerID;
%     end
%     IMG.name = ['IMG_',Info.VolunteerID2,'_',Mid,'_',Info.Protocol,'_X'];
    IMG.name = ['IMG_',Recon.DataObj{1}.DataName];

    %----------------------------------------------
    % Load Compass
    %----------------------------------------------
    totalgbl{1} = IMG.name;
    totalgbl{2} = IMG;
    from = 'CompassLoad';
    Load_TOTALGBL(totalgbl,'IM',from);
end

