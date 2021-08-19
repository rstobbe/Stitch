%================================================================
%  
%================================================================

classdef ReturnImage < handle

    properties
    end

    methods

%==================================================================
% Constructor
%==================================================================           
        function obj = ReturnImage()
        end
        
%==================================================================
% WorkspaceReturn
%================================================================== 
        function Image = WorkspaceReturn(obj)
            Image = obj.ReconHandler.ReturnImage(obj.log);   
        end
        
%==================================================================
% CompassReturnIMG
%================================================================== 
        function IMG = CompassReturnIMG(obj)

            IMG.Method = obj.ReconHandler.StitchMetaData.ReconFunction;
            IMG.Im = obj.ReconHandler.ReturnImage(obj.log);  
            IMG.ReconInfo = obj.ReconFile;
            Info = obj.DataInfo;
            IMG.ExpPars = Info.ExpPars;

            Panel(1,:) = {'','','Output'};
            Panel(2,:) = {'Stitch Function',obj.ReconHandler.StitchMetaData.ReconFunction,'Output'};
            PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
            IMG.PanelOutput = [Info.PanelOutput;PanelOutput0];
            IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
            
            %----------------------------------------------
            % Set Up Compass Display
            %----------------------------------------------
            MSTRCT.type = 'abs';
            MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
            MSTRCT.ImInfo.pixdim = obj.ReconHandler.PixDims;
            MSTRCT.ImInfo.vox = obj.ReconHandler.PixDims(1)*obj.ReconHandler.PixDims(2)*obj.ReconHandler.PixDims(3);
            MSTRCT.ImInfo.info = IMG.ExpDisp;
            MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
            INPUT.Image = IMG.Im;
            INPUT.MSTRCT = MSTRCT;
            IMDISP = ImagingPlotSetup(INPUT);
            IMG.IMDISP = IMDISP;
            IMG.type = 'Image';
            IMG.path = obj.DataPath;

            ind = strfind(obj.DataName,'_');
            Mid = obj.DataName(1:ind(1)-1);
            ind = strfind(Info.VolunteerID,'.');
            if not(isempty(ind))
                Info.VolunteerID2 = Info.VolunteerID(ind(end)+1:end);
            else
                Info.VolunteerID2 = Info.VolunteerID;
            end
            IMG.name = ['IMG_',Info.VolunteerID2,'_',Mid,'_',Info.Protocol];
        end        
        
%==================================================================
% CompassReturnFile
%================================================================== 
        function CompassReturnFile(obj)

            IMG.Method = obj.ReconHandler.StitchMetaData.ReconFunction;
            IMG.Im = obj.ReconHandler.ReturnImage(obj.log);  
            IMG.ReconInfo = obj.ReconFile;
            Info = obj.DataInfo;
            IMG.ExpPars = Info.ExpPars;

            Panel(1,:) = {'','','Output'};
            Panel(2,:) = {'Stitch Function',obj.ReconHandler.StitchMetaData.ReconFunction,'Output'};
            PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
            IMG.PanelOutput = [Info.PanelOutput;PanelOutput0];
            IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
            
            %----------------------------------------------
            % Set Up Compass Display
            %----------------------------------------------
            MSTRCT.type = 'abs';
            MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
            MSTRCT.ImInfo.pixdim = obj.ReconHandler.PixDims;
            MSTRCT.ImInfo.vox = obj.ReconHandler.PixDims(1)*obj.ReconHandler.PixDims(2)*obj.ReconHandler.PixDims(3);
            MSTRCT.ImInfo.info = IMG.ExpDisp;
            MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
            INPUT.Image = IMG.Im;
            INPUT.MSTRCT = MSTRCT;
            IMDISP = ImagingPlotSetup(INPUT);
            IMG.IMDISP = IMDISP;
            IMG.type = 'Image';
            IMG.path = obj.DataPath;

            ind = strfind(obj.DataName,'_');
            Mid = obj.DataName(1:ind(1)-1);
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
        end

%==================================================================
% CompassSaveFile
%================================================================== 
        function CompassSaveFile(obj,path,Suffix)
           
            IMG.Method = obj.ReconHandler.StitchMetaData.ReconFunction;
            IMG.Im = obj.ReconHandler.ReturnImage(obj.log);  
            IMG.ReconInfo = obj.ReconFile;
            Info = obj.DataInfo;
            IMG.ExpPars = Info.ExpPars;

            Panel(1,:) = {'','','Output'};
            Panel(2,:) = {'Stitch Function',obj.ReconHandler.StitchMetaData.ReconFunction,'Output'};
            PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
            IMG.PanelOutput = [Info.PanelOutput;PanelOutput0];
            IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);

            %----------------------------------------------
            % Set Up Compass Display
            %----------------------------------------------
            MSTRCT.type = 'abs';
            MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
            MSTRCT.ImInfo.pixdim = obj.ReconHandler.PixDims;
            MSTRCT.ImInfo.vox = obj.ReconHandler.PixDims(1)*obj.ReconHandler.PixDims(2)*obj.ReconHandler.PixDims(3);
            MSTRCT.ImInfo.info = IMG.ExpDisp;
            MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
            INPUT.Image = IMG.Im;
            INPUT.MSTRCT = MSTRCT;
            IMDISP = ImagingPlotSetup(INPUT);
            IMG.IMDISP = IMDISP;
            IMG.type = 'Image';
            IMG.path = obj.DataPath;

            ind = strfind(obj.DataName,'_');
            Mid = obj.DataName(1:ind(1)-1);
            ind = strfind(Info.VolunteerID,'.');
            if not(isempty(ind))
                Info.VolunteerID2 = Info.VolunteerID(ind(end)+1:end);
            else
                Info.VolunteerID2 = Info.VolunteerID;
            end

            ind=strfind(obj.DataFile,'_');%JGG used name of file
            IMG.name = ['IMG_',obj.DataFile(1:ind(2)-1),'_',Info.Protocol(2:end),Suffix];
            %IMG.name = ['IMG_',Info.VolunteerID2,'_',Mid,'_',Info.Protocol,Suffix];
            %IMG.name = ['IMG_',Mid,'_',Info.Protocol,Suffix];
            %IMG.name = ['IMG_',Mid,Suffix];
            
            %----------------------------------------------
            % Save
            %----------------------------------------------
            IMG.Im = single(IMG.Im);            % just to make sure
             if( isprop(obj.ReconHandler.Recon,'TrajMashInfo'))
                IMG.TrajMashInfo=obj.ReconHandler.Recon.TrajMashInfo;
            end
            saveData.IMG = IMG;
            save([path,IMG.name],'saveData');
            
            %----------------------------------------------
            % Save Figures
            %----------------------------------------------
%             for n = 1:length(obj.ReconHandler.Recon.Figs2Save)
%                 print(obj.ReconHandler.Recon.Figs2Save(n).hFig,[path,Mid,'_',obj.ReconHandler.Recon.Figs2Save(n).Name],'-dpng','-r0');            % -r0 is screen resolution 
%             end
        end        
        
%==================================================================
% CompassReturnFire
%================================================================== 
        function CompassReturnFire(obj,RwsFireServer,FireRecon,log)

            IMG.Method = FireRecon.StitchMetaData.ReconFunction;
            IMG.Im = FireRecon.ReturnImage(log); 

            Panel(1,:) = {'','','Output'};
            Panel(2,:) = {'Measurement ID',RwsFireServer.MetaData.measurementInformation.measurementID,'Output'};
            Panel(3,:) = {'Protocol',RwsFireServer.MetaData.measurementInformation.protocolName,'Output'};
            Panel(4,:) = {'Scan Time',RwsFireServer.MetaData.studyInformation.studyTime,'Output'};
            Panel(5,:) = {'Stitch Function',FireRecon.StitchMetaData.ReconFunction,'Output'};
            PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
            IMG.PanelOutput = PanelOutput0;
            IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
            
            %----------------------------------------------
            % Set Up Compass Display
            %----------------------------------------------
            MSTRCT.type = 'abs';
            MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
            MSTRCT.ImInfo.pixdim = obj.ReconHandler.PixDims;
            MSTRCT.ImInfo.vox = obj.ReconHandler.PixDims(1)*obj.ReconHandler.PixDims(2)*obj.ReconHandler.PixDims(3);
            MSTRCT.ImInfo.info = IMG.ExpDisp;
            MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
            INPUT.Image = IMG.Im;
            INPUT.MSTRCT = MSTRCT;
            IMDISP = ImagingPlotSetup(INPUT);
            IMG.IMDISP = IMDISP;
            IMG.type = 'Image';

            IMG.name = ['IMG_',RwsFireServer.MetaData.measurementInformation.measurementID];

            %----------------------------------------------
            % Load Compass
            %----------------------------------------------
            totalgbl{1} = IMG.name;
            totalgbl{2} = IMG;
            from = 'CompassLoad';
            Load_TOTALGBL(totalgbl,'IM',from);
        end
        
%==================================================================
% CompassSaveFire
%================================================================== 
        function CompassSaveFire(obj,RwsFireServer,FireRecon,log)

            IMG.Method = FireRecon.StitchMetaData.ReconFunction;
            IMG.Im = FireRecon.ReturnImage(log); 

            Panel(1,:) = {'','','Output'};
            Panel(2,:) = {'Measurement ID',RwsFireServer.MetaData.measurementInformation.measurementID,'Output'};
            Panel(3,:) = {'Protocol',RwsFireServer.MetaData.measurementInformation.protocolName,'Output'};
            Panel(4,:) = {'Scan Time',RwsFireServer.MetaData.studyInformation.studyTime,'Output'};
            Panel(5,:) = {'Stitch Function',FireRecon.StitchMetaData.ReconFunction,'Output'};
            PanelOutput0 = cell2struct(Panel,{'label','value','type'},2);
            IMG.PanelOutput = PanelOutput0;
            IMG.ExpDisp = PanelStruct2Text(IMG.PanelOutput);
            
            %--------------------------------------
            % ReconPars
            %--------------------------------------
            ReconPars.Imfovx = FireRecon.Recon.SubSamp*FireRecon.StitchMetaData.Fov;
            ReconPars.Imfovy = FireRecon.Recon.SubSamp*FireRecon.StitchMetaData.Fov;                 
            ReconPars.Imfovz = FireRecon.Recon.SubSamp*FireRecon.StitchMetaData.Fov;
            ReconPars.ImvoxLR = ReconPars.Imfovy/FireRecon.StitchMetaData.ZeroFill;
            ReconPars.ImvoxTB = ReconPars.Imfovx/FireRecon.StitchMetaData.ZeroFill;
            ReconPars.ImvoxIO = ReconPars.Imfovz/FireRecon.StitchMetaData.ZeroFill;
            ReconPars.ImszLR = FireRecon.StitchMetaData.ZeroFill;
            ReconPars.ImszTB = FireRecon.StitchMetaData.ZeroFill;
            ReconPars.ImszIO = FireRecon.StitchMetaData.ZeroFill;
            ReconPars.SubSamp = FireRecon.Recon.SubSamp;
            
            %----------------------------------------------
            % Set Up Compass Display
            %----------------------------------------------
            MSTRCT.type = 'abs';
            MSTRCT.dispwid = [0 max(abs(IMG.Im(:)))];
            MSTRCT.ImInfo.pixdim = [ReconPars.ImvoxTB,ReconPars.ImvoxLR,ReconPars.ImvoxIO];
            MSTRCT.ImInfo.vox = ReconPars.ImvoxTB*ReconPars.ImvoxLR*ReconPars.ImvoxIO;
            MSTRCT.ImInfo.info = IMG.ExpDisp;
            MSTRCT.ImInfo.baseorient = 'Axial';             % all images should be oriented axially
            INPUT.Image = IMG.Im;
            INPUT.MSTRCT = MSTRCT;
            IMDISP = ImagingPlotSetup(INPUT);
            IMG.IMDISP = IMDISP;
            IMG.type = 'Image';

            IMG.name = ['IMG_',RwsFireServer.MetaData.measurementInformation.measurementID];

            %----------------------------------------------
            % Save
            %----------------------------------------------
            saveData.IMG = IMG;
            save([RwsFireServer.SavePath,IMG.name],'saveData');
        end
        
    end
end
