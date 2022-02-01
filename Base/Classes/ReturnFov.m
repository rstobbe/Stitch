%================================================================
% Required Options:
%   Fov2Return      {'All,'Design','HeadBig',values}
%================================================================

classdef ReturnFov < handle

    properties (SetAccess = private)                    
        ObDimStart;
        ObDimStop;
        ImageReturnDims;
        PixDims;
    end
    methods 

%==================================================================
% Constructor
%==================================================================   
        function [obj] = ReturnFov()
        end
        
%==================================================================
% GetFinalMatrixDimensions
%==================================================================              
        function GetFinalMatrixDimensions(obj,Options)
            if strcmp(Options.Fov2Return,'All')
                obj.ImageReturnDims = obj.ImageMatrixMemDims;
            elseif strcmp(Options.Fov2Return,'Design')
                obj.ObDimStart = obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2+1;
                obj.ObDimStop = obj.ImageMatrixMemDims - obj.ImageMatrixMemDims*(1-1/obj.SubSamp)/2;
                obj.ImageReturnDims = obj.ObDimStop-obj.ObDimStart+1;
            elseif strcmp(Options.Fov2Return,'HeadBig')
                FoV(1) = 260;
                FoV(2) = 220;                 
                FoV(3)= 220;
                NewImSize = 2*round((FoV/(Options.SubSampFov)).*obj.ImageMatrixMemDims/2);
                obj.ObDimStart = ImSize/2 - NewImSize/2 + 1;
                obj.ObDimStop = ImSize/2 + NewImSize/2;                
                obj.ImageReturnDims = obj.ObDimStop-obj.ObDimStart+1;
            else
                FoV(1) = Options.Fov2Return(1);
                FoV(2) = Options.Fov2Return(2);                
                FoV(3) = Options.Fov2Return(3);
                NewImSize = round((FoV/(Options.SubSampFov)).*double(obj.ImageMatrixMemDims));
                obj.ObDimStart = double(obj.ImageMatrixMemDims)/2 - ceil(NewImSize/2) + 1;
                obj.ObDimStop = double(obj.ImageMatrixMemDims)/2 + floor(NewImSize/2);                
                obj.ImageReturnDims = obj.ObDimStop-obj.ObDimStart+1;
            end
            obj.PixDims = (Options.SubSampFov)./double(obj.ImageMatrixMemDims);
        end
        
%==================================================================
% ReturnFoV
%==================================================================          
        function ReturnImage = ReturnFoV(obj,Options,FullImage)                   
            if strcmp(Options.Fov2Return,'All')
                ReturnImage = FullImage;
            else
                ReturnImage = FullImage(obj.ObDimStart(1):obj.ObDimStop(1),obj.ObDimStart(2):obj.ObDimStop(2),obj.ObDimStart(3):obj.ObDimStop(3));
            end 
        end
        
    end
end