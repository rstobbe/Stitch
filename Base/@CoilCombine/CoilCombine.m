%================================================================
%  
%================================================================

classdef CoilCombine

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
        function COILCOMB = CoilCombine(Selector)
            % cases...
            % initialize cases
        end                   

      
        
%==================================================================
% CreateSuperImage
%================================================================== 
        function CreateSuperImage(COILCOMB)
            PerformPostAcqReconSuper(COILCOMB);
        end 
        
%==================================================================
% PackageAndSaveImage
%================================================================== 
        function PackageAndSaveImage(COILCOMB)
            PackageSaveImage(COILCOMB);
        end 
        
%==================================================================
% PackageAndWriteCompass
%================================================================== 
        function PackageAndWriteCompass(COILCOMB)
            PackageWriteCompass(COILCOMB);
        end         
    end
end