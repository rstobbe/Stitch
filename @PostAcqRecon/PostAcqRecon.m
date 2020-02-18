%================================================================
%  
%================================================================

classdef PostAcqRecon < handle

    properties (SetAccess = private)                    
        TrajData;
        RECON;
        BlockSize;
        ChanPerGpu;
        ZeroFill;
        NumRuns;
        NumCol;
        NumTraj;
        SampStart;
    end
    methods 

%==================================================================
% Init
%==================================================================   
        function PARECON = PostAcqRecon(ReconInfo)
            PARECON = InitializePostAcqRecon(PARECON,ReconInfo);
        end

%==================================================================
% CreateImage
%================================================================== 
        function Image = CreateImage(PARECON,DataFile)
            Image = PerformPostAcqRecon(PARECON,DataFile);
        end          
    end
end