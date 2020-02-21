%================================================================
%  
%================================================================

classdef PostAcqReconSuperV1a < handle

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
        ImageHighSoS; ImageHighSoSArr;
        ImageLowSoS; ImageLowSoSArr;
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
        function PARECON = PostAcqReconSuperV1a(ReconInfo)
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
            PARECON.Image = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'));
            PARECON.ImageHighSoS = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single'));
            PARECON.ImageLowSoS = zeros([PARECON.RECON.ImageMatrixMemDims,NumExp],'single');
            PARECON.ImageHighSoSArr = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'));
            PARECON.ImageLowSoSArr = complex(zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'),zeros([PARECON.RECON.ImageMatrixMemDims,NumExp,Channels],'single'));
        end           
        
%==================================================================
% CreateImage
%================================================================== 
        function CreateImage(PARECON,DataFile)
            ind = strfind(DataFile,'\');
            PARECON.DataPath = DataFile(1:ind(end));
            PARECON.DataFile = DataFile(ind(end)+1:end);
            PARECON.DataName = DataFile(ind(end)+6:end-4);
            PerformPostAcqReconSuper(PARECON,DataFile);
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