%================================================================
%  
%================================================================

classdef StitchMatLocal < StitchRecon
    
    properties (SetAccess = private)                    
        ReconMetaData;
    end    
    methods

%==================================================================
% Constructor
%==================================================================   
        function obj = StitchMatLocal()
            obj@StitchRecon();          
        end 

%==================================================================
% DataLoadInit
%==================================================================   
        function DataLoadInit(obj,ReconMetaData,log)       
            ReconMetaData.DataSource = 'MatLocal';
            ReconMetaData.PullReconLocal = 1;               % do again
            ReconMetaData.LoadTrajLocal = 1;
            obj.StitchLoadTrajInfo(ReconMetaData,log); 
        end        
        
%==================================================================
% Initialize
%==================================================================   
        function Initialize(obj,ReconMetaData,log)       
            ReconMetaData.DataSource = 'MatLocal';
            ReconMetaData.PullReconLocal = 1;               % do again
            ReconMetaData.LoadTrajLocal = 1;
            obj.StitchInit(ReconMetaData,log); 
        end
        
%==================================================================
% LocalDataBlockInit
%==================================================================          
        function LocalDataBlockInit(obj,RwsMatHandler,log)
            obj.StitchDataProcessInit(RwsMatHandler,log);
        end  

%==================================================================
% GetDataReadInfo
%==================================================================             
        function DataReadInfo = GetDataReadInfo(obj)
            DataReadInfo.ScanDummies = obj.StitchMetaData.Dummies;
            DataReadInfo.SampStart = obj.StitchMetaData.SampStart;
            DataReadInfo.Format = 'SingleArray';                                % other option = 'Complex'. 
            DataReadInfo.NumCol = obj.StitchMetaData.NumCol;
        end 

%==================================================================
% IntraAcqProcess
%==================================================================   
        function IntraAcqProcess(obj,RwsMatHandler,log)                 
            obj.UpdateTestStitchMetaData(obj.ReconMetaData,log);
            obj.StitchIntraAcqProcess(RwsMatHandler,log); 
        end

%==================================================================
% PostAcqProcess
%==================================================================   
        function PostAcqProcess(obj,RwsMatHandler,log)
            obj.UpdateTestStitchMetaData(obj.ReconMetaData,log);
            obj.StitchPostAcqProcess(RwsMatHandler,log);
        end

%==================================================================
% FinishAcqProcess
%==================================================================   
        function FinishAcqProcess(obj,RwsMatHandler,log)
            obj.StitchFinishAcqProcess(RwsMatHandler,log);
        end        
        
%==================================================================
% ReturnImage
%==================================================================   
        function Image = ReturnImage(obj,log)
            Image = obj.StitchReturnImage(log);
        end        

%==================================================================
% Destructor
%================================================================== 
        % done below
        
    end
end
