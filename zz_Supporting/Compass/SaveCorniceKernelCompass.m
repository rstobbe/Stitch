%==================================================================
% 
%================================================================== 

function SaveCorniceKernelCompass(Recon,Name)

CRN = Recon.CorniceKernel;  
CRN.name = Name;

totalgbl{1} = CRN.name;
totalgbl{2} = CRN;
from = 'CompassLoad';
Load_TOTALGBL(totalgbl,'IM',from);

saveData.CRN = CRN;
save([CRN.path,CRN.name],'saveData');
