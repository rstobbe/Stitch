%================================================================
%  Stitch reconstruction script example
%     - this can be modified for batch processing etc.
%================================================================

%----------------------------------------------------------------
% Define the data path and file
%----------------------------------------------------------------
DataPath = 'I:\210805 (MoistReconTesting)\';
DataFile = 'MOIST_163_meas_MID00203_FID87728_Vent210602.dat';

%----------------------------------------------------------------
% Remove previous reconstruction ('Handler') objects if they exist
%----------------------------------------------------------------
disp('=====================================================================');
disp(['Reconstruct ',DataPath,DataFile]);
if exist('Handler','class')
    delete(Handler);
end

%----------------------------------------------------------------
% The RwsSiemensHandler is intended for local *.dat files. 
%   This is currently the only supported 'Handler' 
%----------------------------------------------------------------
Handler = RwsSiemensHandler();

%----------------------------------------------------------------
% The RwsSiemensHandler supports other reconstructions. 
%   'SetStitch' defines a Stitch reconstruction. 
%----------------------------------------------------------------
Handler.SetStitch;

%----------------------------------------------------------------
% Load reconstruction information from the 'Recon' file.  Note
%   that the ReconMetaData structure can also be modified from the
%   Matlab command line if desired.
%----------------------------------------------------------------
ReconMetaData = Recon();

%----------------------------------------------------------------
% These methods load/setup/and process data.  
%----------------------------------------------------------------
Handler.LoadData([DataPath,DataFile],ReconMetaData);
Handler.ProcessSetup(ReconMetaData);
Handler.Process;

%----------------------------------------------------------------
% Data is currently saved in a format intended for the 
%   MRI software tool labelled 'Compass' (https://github.com/rstobbe/Compass)
%   The 'Suffix' is appended onto the end of the reconstructed image file. 
%----------------------------------------------------------------
Suffix = '_Test';
Handler.SaveImageCompass(DataPath,Suffix);
