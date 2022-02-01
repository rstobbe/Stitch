%==================================================================
% ReturnOneImage
%================================================================== 

function IMG = ReturnOneImage(Recon)

    IMG.Method = class(Recon);
    IMG.Im = Recon.Image;  
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
    PixDims = Recon.Stitch{1}.PixDims;
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
    IMG.name = ['IMG_',Recon.DataObj.DataName];

end

