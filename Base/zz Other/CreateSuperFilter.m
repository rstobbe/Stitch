%==================================================
% 
%==================================================

function [F] = CreateSuperFilter(ReconPars,SUPER)

fwidx = 2*round((ReconPars.Imfovx/SUPER.ProfRes)/2);
fwidy = 2*round((ReconPars.Imfovy/SUPER.ProfRes)/2);
fwidz = 2*round((ReconPars.Imfovz/SUPER.ProfRes)/2);
F0 = Kaiser_v1b(fwidx,fwidy,fwidz,SUPER.ProfFilt,'unsym');
x = SUPER.ImDims(1);
y = SUPER.ImDims(2);
z = SUPER.ImDims(3);
F = zeros(x,y,z,'single');
F(x/2-fwidx/2+1:x/2+fwidx/2,y/2-fwidy/2+1:y/2+fwidy/2,z/2-fwidz/2+1:z/2+fwidz/2) = F0;