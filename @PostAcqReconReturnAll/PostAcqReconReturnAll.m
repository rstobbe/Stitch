%================================================================
%  
%================================================================

classdef PostAcqReconReturnAllV1a < handle

    properties (SetAccess = private)                    
        Method;
        TrajData;
        RECON;
        BlockSize;
        ChanPerGpu;
        ZeroFill;
        NumRuns;
        NumCol;
        NumTraj;
        SampStart;
        Image;
        Info;
        ReconInfo;
        ReconPars;
        DataFile; DataPath; DataName;
        ReconFile;
    end
    methods 
        
%==================================================================
% Init
%==================================================================   
        function PARECON = PostAcqReconReturnAllV1a(ReconInfo)
            PARECON.ReconFile = ReconInfo.File;
            PARECON.Method = 'PostAcqPreconV1a';
            PARECON = InitializePostAcqRecon(PARECON,ReconInfo);
        end

%==================================================================
% InitializeImage
%   - Host Memory
%==================================================================         
        function InitializeImage(PARECON,Channels)
            NumExp = 1;
            PARECON.Image = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'));
        end           
        
%==================================================================
% CreateImage
%================================================================== 
        function CreateImage(PARECON,DataFile)
            ind = strfind(DataFile,'\');
            PARECON.DataPath = DataFile(1:ind(end));
            PARECON.DataFile = DataFile(ind(end)+1:end);
            PARECON.DataName = DataFile(ind(end)+6:end-4);
            PerformPostAcqReconReturnAll(PARECON,DataFile);
        end 
        
%==================================================================
% PackageAndSaveImage
%================================================================== 
        function PackageAndSaveImage(PARECON)
            PackageSaveImage(PARECON);
        end 
        
%==================================================================
% PackageAndWriteCompass
%================================================================== 
        function PackageAndWriteCompass(PARECON)
            PackageWriteCompass(PARECON);
        end         
    end
end