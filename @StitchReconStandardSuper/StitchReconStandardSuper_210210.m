%================================================================
%  
%================================================================

classdef StitchReconStandardSuper < StitchReconSuper

    properties (SetAccess = private)                    
    end
    
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = StitchReconStandardSuper()
            obj@StitchReconSuper;   
        end
        
%==================================================================
% StitchInit 
%==================================================================   
        function StitchInit(obj,StitchMetaData,ReconInfoMat,log)
            obj.StitchBasicInit(StitchMetaData,ReconInfoMat,log);          
        end

%==================================================================
% UpdateStitchMetaData (subclass)
%==================================================================          

%==================================================================
% StitchGridInitTop 
%==================================================================  
        function StitchGridInitTop(obj,DataObj,log) 
            obj.StitchGridInit(log);  
        end   

%==================================================================
% StitchIntraAcqProcess
%==================================================================           
        function StitchIntraAcqProcess(obj,DataObj,log)
            StitchGridDataBlock(obj,DataObj,log);   
        end        
        
%==================================================================
% StitchPostAcqProcess
%================================================================== 
        function StitchPostAcqProcess(obj,log)
            StitchFftCombine(obj,log);   
        end     
        
%==================================================================
% StitchFftCombine (subclass)
%==================================================================      

%==================================================================
% StitchReturnImage (subclass)
%==================================================================                    
        
%==================================================================
% CreateLoadSuperFilter (subclass)
%==================================================================         
    end
end