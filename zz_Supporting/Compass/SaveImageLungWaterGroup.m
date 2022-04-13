%==================================================================
% 
%================================================================== 

function SaveImageLungWaterGroup(Recon,path,Suffix)

    IMG.Method = class(Recon);
    IMG.Im = Recon.Image;  
    Info = Recon.DataObj{1}.DataInfo;           % Base on first
    IMG.ExpPars = Info.ExpPars;

    Panel(1,:) = {'','','Output'};
    Panel(2,:) = {'Recon Function',IMG.Method,'Output'};
    PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
    IMG.PanelOutput = [PanelOutput0;Info.PanelOutput];
    IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
 
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

    %----------------------------------------------
    % Other
    %----------------------------------------------
    if isprop(Recon,'TrajMashInfo')
        IMG.TrajMashInfo = Recon.TrajMashInfo;
    end
    
    %----------------------------------------------
    % Name
    %----------------------------------------------    
    ind = strfind(Recon.DataObj{1}.DataFile,'_');
    IMG.name = ['IMG_',Recon.DataObj{1}.DataFile(1:ind(2)-1),'_',Info.Protocol(2:end),Suffix];

    %----------------------------------------------
    % Save
    %----------------------------------------------
    saveData.IMG = IMG;
    save([path,IMG.name],'saveData');
end

