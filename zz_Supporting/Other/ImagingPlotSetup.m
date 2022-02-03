%=========================================================
% 
%=========================================================

function IMDISP = ImagingPlotSetup(INPUT)

Image = INPUT.Image;
MSTRCT = INPUT.MSTRCT;
clear INPUT

%----------------------------------------
% Image Dimensions
%----------------------------------------
sz = size(Image);
IMDIM.x1 = 1;
IMDIM.y1 = 1;
IMDIM.z1 = 1;
IMDIM.x2 = sz(2);
IMDIM.y2 = sz(1);
if length(sz)>2
    IMDIM.z2 = sz(3);
else
    IMDIM.z2 = 1;
end
IMDIM.slice = 1;
if length(sz)>3
    IMDIM.sz4 = sz(4);
    if length(sz)>4
        IMDIM.sz5 = sz(5);
        if length(sz)>5
            IMDIM.sz5 = sz(6);
        end
    end
end

%----------------------------------------
% Scale 
%----------------------------------------
if length(sz) == 2
    sz(3) = 1;
end
SCALE.xmax = sz(2)+0.5;            
SCALE.ymax = sz(1)+0.5;
SCALE.zmax = sz(3)+0.5;
SCALE.xmin = 0.5;
SCALE.ymin = 0.5;
SCALE.zmin = 0.5;

%----------------------------------------
% Default Display
%----------------------------------------
if isfield(MSTRCT,'type')
    DEFDISP.type = MSTRCT.type;
else
    DEFDISP.type = 'abs';
end
if isfield(MSTRCT,'dispwid')
    DEFDISP.dispwid = MSTRCT.dispwid;
else
    DEFDISP.dispwid = [0 max(abs(Image(:)))];
end
if isfield(MSTRCT,'colour')
    DEFDISP.colour = MSTRCT.colour;
else
    DEFDISP.colour = 'No';
end

%----------------------------------------
% Build Image Display Structure
%----------------------------------------
IMDISP.DEFDISP = DEFDISP;
IMDISP.IMDIM = IMDIM;  
IMDISP.SCALE = SCALE;   
IMDISP.ImInfo = MSTRCT.ImInfo;
IMDISP.dispfunc = @StandardPlot;                % compared to overlay plot
IMDISP.tab = 'Imaging';



