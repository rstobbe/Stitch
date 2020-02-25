%================================================================
%  
%================================================================

classdef PostAcqReconSuperV1a < handle

    properties (SetAccess = private)                    
        Method;
        TrajData;
        DATA;
        RECON;
        BlockSize;
        ChanPerGpu;
        GpuNum;
        RxChannels;
        ZeroFill;
        NumRuns;
        NumCol;
        NumTraj;
        SampStart;
        Dummies;
        Image;
        ImageHighSoS; ImageHighSoSArr;
        ImageLowSoS; ImageLowSoSArr;
        Info;
        ReconInfo;
        ReconPars;
        DataFile; DataPath; DataName;
        ReconFile;
        ReconPath;
    end
    methods 

        
%==================================================================
% Init
%==================================================================   
        function PARECON = PostAcqReconSuperV1a(DataFile)
            disp('Read Siemens Header');
            ind = strfind(DataFile,'\');
            PARECON.DataPath = DataFile(1:ind(end));
            PARECON.DataFile = DataFile(ind(end)+1:end);
            PARECON.DataName = DataFile(ind(end)+6:end-4);
            PARECON.DATA = ReadSiemens(DataFile);
            PARECON.Info = PARECON.DATA.Info;
            PARECON.Method = 'PostAcqReconSuperV1a';
        end        

%==================================================================
% DefaultRecon
%==================================================================   
        function DefaultRecon(PARECON)
            PARECON.ReconFile = PARECON.Info.Protocol;
            PARECON.ReconPath = 'D:\StitchRelated\DefaultReconstructions\';
            InitializePostAcqRecon(PARECON);
        end          

%==================================================================
% ResetGpus
%==================================================================   
        function ResetGpus(PARECON)
            GpuTot = gpuDeviceCount;
            disp('Reset GPUs');
            for n = 1:GpuTot
                gpuDevice(n);               
            end
        end
        
%==================================================================
% UserRecon
%==================================================================   
        function UserRecon(PARECON,ReconInfo)
            PARECON.ReconFile = ReconInfo.File;
            PARECON.ReconPath = ReconInfo.ReconPath;
            InitializePostAcqRecon(PARECON);
        end        
        
%==================================================================
% CreateImage
%================================================================== 
        function CreateImage(PARECON)
            PerformPostAcqReconSuper(PARECON);
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