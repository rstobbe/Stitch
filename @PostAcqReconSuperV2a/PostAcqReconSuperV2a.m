%================================================================
%  
%================================================================

classdef PostAcqReconSuperV2a < ReadSiemens & ImageRecon

    properties (SetAccess = private)                    
        Method;
        Image;
        ImageHighSoS; ImageHighSoSArr;
        ImageLowSoS; ImageLowSoSArr;
    end
    methods 

        
%==================================================================
% Constructor
%==================================================================   
        function PARECON = PostAcqReconSuperV2a(DataFile)
            PARECON@ReadSiemens;
            PARECON@ImageRecon;
            PARECON.DefineDataFile(DataFile);
            disp('Read Siemens Header');
            PARECON.ReadSiemensHeader;
            PARECON.Method = 'PostAcqReconSuperV2a';
        end                   

%==================================================================
% InitializeSuperRecon
%================================================================== 
        function InitializeSuperRecon(PARECON,ReconInfo)
            if nargin == 1
                PARECON.InitializeDefaultRecon;
            elseif nargin == 2
                PARECON.InitializeUserRecon(ReconInfo);
            end
            InitializeSuperReconFunc(PARECON);
        end         
        
%==================================================================
% CreateSuperImage
%================================================================== 
        function CreateSuperImage(PARECON)
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