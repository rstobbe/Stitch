%================================================================
%  
%================================================================

classdef ImageRecon < GpuInterface

    properties (SetAccess = private)                    
        % General
        TrajData;
        ZeroFill;
        NumRuns;
        NumCol;
        NumTraj;
        NumAverages;
        SampStart;
        SampEnd;
        Dummies;
        ReconInfo;
        ReconPars;
        ReconFile;
        ReconPath;
        GridMethod = 'GridDatFileStandard';
        % GridDatFileUserMash
        UserMashFile;
        UserMash;
    end
    methods 

        
%==================================================================
% Init
%==================================================================   
        function PARECON = ImageRecon()
            PARECON@GpuInterface;
        end        

%==================================================================
% DefaultRecon
%==================================================================   
        function InitializeDefaultRecon(PARECON)
            PARECON.ReconFile = PARECON.DataInfo.Protocol;
            PARECON.ReconPath = 'D:\StitchRelated\DefaultReconstructions\';
            InitializeImageReconFunc(PARECON);
        end          
      
%==================================================================
% UserRecon
%==================================================================   
        function InitializeUserRecon(PARECON,ReconInfo)
            PARECON.ReconFile = ReconInfo.File;
            PARECON.ReconPath = ReconInfo.Path;
            InitializeImageReconFunc(PARECON);
        end             

%==================================================================
% GridDatFile
%==================================================================   
        function GridDatFile(PARECON)
            if isempty(PARECON.UserMash)
                GridDatFileStandardFunc(PARECON);
            else
                GridDatFileUserMashFunc(PARECON);
            end
        end               

%==================================================================
% LoadUserMashFromFile
%==================================================================   
        function LoadUserMashFromFile(PARECON,UserMashFile)
            PARECON.UserMashFile = UserMashFile; 
            LoadUserMashFromFileFunc(PARECON);
            PARECON.GridMethod = 'GridDatFileUserMash';
        end            
        
    end  
end