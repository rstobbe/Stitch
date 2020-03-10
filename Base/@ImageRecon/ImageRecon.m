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
% GridDatFileStandard
%==================================================================   
        function GridDatFileStandard(PARECON)
            GridDatFileStandardFunc(PARECON);
        end 

%==================================================================
% GridDatFileUserMash
%==================================================================   
        function GridDatFileUserMash(PARECON)
            GridDatFileUserMashFunc(PARECON);
        end         

%==================================================================
% LoadUserMashFromFile
%==================================================================   
        function LoadUserMashFromFile(PARECON,UserMashFile)
            PARECON.UserMashFile = UserMashFile; 
            GridDatFileUserMashFunc(PARECON);
        end            
        
    end  
end