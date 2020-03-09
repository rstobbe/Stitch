%================================================================
%  
%================================================================

classdef ImageRecon < GpuInterface

    properties (SetAccess = private)                    
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
% GriddingTest
%==================================================================   
        function GriddingTest(PARECON)
            GriddingTestFunc(PARECON);
        end 
        
    end  
end