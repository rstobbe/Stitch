%================================================================
%  
%================================================================

classdef RwsSiemensHandler < ReadSiemens & ReturnImage

    properties
        ReconFile;
        ReconHandler;
        ReconHandlerName;
        log;
    end

    methods

%==================================================================
% Constructor
%==================================================================           
        function obj = RwsSiemensHandler(varargin)
            obj@ReadSiemens;
            obj@ReturnImage;
            if isempty(varargin)
                LogFile = '';
            else
                LogFile = varargin{1};
            end
            obj.log = logging.createLog(LogFile); 
        end

%==================================================================
% SetStitch
%==================================================================           
        function SetStitch(obj)
            obj.ReconHandlerName = 'StitchSiemensLocal';
            obj.ReconHandler = StitchSiemensLocal();
        end                       

%==================================================================
% LoadData
%================================================================== 
        function LoadData(obj,DataFile,ReconMetaData) 

            obj.log.info('Read Siemens Data');
            %--------------------------------------------
            % Defaults
            %--------------------------------------------
            if ~isfield(ReconMetaData,'UseLocal')
                ReconMetaData.UseLocal = 1;
            end
            if ~isfield(ReconMetaData,'LoadTrajectoryLocal')
                ReconMetaData.LoadTrajectoryLocal = 1;
            end
            
            %--------------------------------------------
            % Get Siemens MetaData
            %--------------------------------------------
            obj.SetSiemensDataFile(DataFile);
            obj.ReadSiemensHeader();

            %--------------------------------------------
            % Process Siemens Info for Recon
            %--------------------------------------------
            obj.ReconHandler.ProcessSiemensHeaderInfo(obj,obj.log);

            %--------------------------------------------
            % Prepare for Data Load 
            %--------------------------------------------            
            obj.ReconHandler.Prepare(ReconMetaData,obj.log);
            
            %--------------------------------------------
            % Read Data 
            %--------------------------------------------    
            obj.SetDataBlockLengthFull;
            obj.ReadSiemensDataBlockInit(obj.ReconHandler.GetDataReadInfo);
            obj.ReadSiemensDataBlock;
        end         

%==================================================================
% ProcessSetup
%==================================================================         
        function ProcessSetup(obj,ReconMetaData)
            obj.log.info('Setup Image Reconstruction');
            obj.ReconHandler.ProcessSetup(ReconMetaData,obj.log);
        end        
                 
%==================================================================
% Process
%==================================================================         
        function Process(obj)
            obj.log.info('Reconstruct Image');
            obj.ReconHandler.PostAcqProcess(obj,obj.log);
        end        
        
%==================================================================
% LoadDataIntraProcess
%================================================================== 
        function LoadDataIntraProcess(obj,DataFile,ReconMetaData) 
                
            %--------------------------------------------
            % Get Siemens MetaData
            %--------------------------------------------
            obj.SetSiemensDataFile(DataFile);
            obj.ReadSiemensHeader(ReconMetaData.SeqName);

            %--------------------------------------------
            % Process Siemens Info for Recon
            %--------------------------------------------
            obj.ReconHandler.ProcessSiemensHeaderInfo(obj,obj.log);

            %--------------------------------------------
            % Prepare for Data Load and Process
            %--------------------------------------------            
            obj.ReconHandler.Prepare(ReconMetaData,obj.log);
            
            %--------------------------------------------
            % Read Data and Process
            %--------------------------------------------    
            obj.ReadSiemensDataBlockInit(obj.ReconHandler.GetDataReadInfo);
            obj.ReconHandler.IntraAcqProcessInit(obj,obj.log);
            obj.log.info('Read (/Process) Siemens Data');
            while not(obj.ReadSiemensDataBlockFinished)
                obj.ReadSiemensDataBlock;
                obj.ReconHandler.IntraAcqProcess(obj,obj.log);
            end
        end              

%==================================================================
% ReturnImageWorkspace
%================================================================== 
        function Image = ReturnImageWorkspace(obj)
            obj.log.info('Return Image Workspace');
            Image = obj.WorkspaceReturn; 
        end

%==================================================================
% ReturnIMG
%================================================================== 
        function IMG = ReturnIMG(obj)
            obj.log.info('Return IMG');
            IMG = obj.CompassReturnIMG;  
        end        
        
%==================================================================
% ReturnImageCompass
%================================================================== 
        function ReturnImageCompass(obj)
            obj.log.info('Return Image Compass');
            obj.CompassReturnFile; 
        end        

%==================================================================
% SaveImageCompass
%================================================================== 
        function SaveImageCompass(obj,path,Suffix)
            obj.log.info('Save Image Compass');
            obj.CompassSaveFile(path,Suffix); 
        end                
        
%==================================================================
% ReturnHandler
%================================================================== 
        function Handler = ReturnHandler(obj)
            Handler = 'RwsSiemensHandler';
        end        

%==================================================================
% Destructor
%================================================================== 
        function delete(obj)
            delete(obj.ReconHandler);
        end          
    end  
end
