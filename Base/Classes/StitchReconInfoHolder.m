%==================================================================
% (v2a)
%   - Convert to Object
%==================================================================

classdef StitchReconInfoHolder < handle

properties (SetAccess = private)                   
    name
    kStep
%     npro
    Dummies
    NumTraj
    NumCol
    SampStart
    SampEnd
    Fov
    Vox
    kMaxRad
    ReconInfoMat
end

methods 
   
%==================================================================
% Constructor
%==================================================================  
function STCH = StitchReconInfoHolder               
end

%==================================================================
% Set
%==================================================================  
function SetName(STCH,name)     
    STCH.name = name;
end
function SetkStep(STCH,kStep)     
    STCH.kStep = kStep;
end
% function Setnpro(STCH,npro)                   % test / remove   
%     STCH.npro = npro;
% end
function SetDummies(STCH,Dummies)     
    STCH.Dummies = Dummies;
end
function SetNumTraj(STCH,NumTraj)     
    STCH.NumTraj = NumTraj;
end
function SetNumCol(STCH,NumCol)     
    STCH.NumCol = NumCol;
end
function SetSampStart(STCH,SampStart)     
    STCH.SampStart = SampStart;
end
function SetSampEnd(STCH,SampEnd)     
    STCH.SampEnd = SampEnd;
end
function SetFov(STCH,Fov)     
    STCH.Fov = Fov;
end
function SetVox(STCH,Vox)     
    STCH.Vox = Vox;
end
function SetkMaxRad(STCH,kMaxRad)     
    STCH.kMaxRad = kMaxRad;
end
function SetReconInfoMat(STCH,ReconInfoMat)     
    STCH.ReconInfoMat = ReconInfoMat;
end


end
end