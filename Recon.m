%============================================================
% Recon
%   This function defines relevant reconstruction information 
%   within the 'ReconMetaData' structure, and can be can/should 
%   be altered, renamed, and saved for specific reconstructions. 
%============================================================

function ReconMetaData = Recon

%------------------------------------------------------------
% TrajFile 
%   This file contains the trajectory information 
%   required reconstruct on image, and may be stored 
%   anywhere. Contact Rob Stobbe (rstobbe@ualberta.ca) for 
%   information regarding the creation of new trajectories. 
%------------------------------------------------------------
ReconMetaData.TrajFile = 'D:\StitchRelated\Trajectories\YB_F350_V270_E100_T15_N3362_P224_S10100_ID2106021.mat';

%------------------------------------------------------------
% ReturnFov 
%   The size of the 3D field-of-view to return in mm.  
%------------------------------------------------------------
ReconMetaData.ReturnFov = [475,475,475];        

%------------------------------------------------------------
% ZeroFill
%   In multiples of 16 (current maximum 256). 
%------------------------------------------------------------
ReconMetaData.ZeroFill = 256;                  

%------------------------------------------------------------
% ReconFunction
%   Defines which reconstruction to perform.  
%   Some reconstructions might require additional information.
%   In this case 'StitchReconTrajMash' requires that a 
%   trajectory mashing function be defined.  
%------------------------------------------------------------
ReconMetaData.ReconFunction = 'StitchReconTrajMash';
ReconMetaData.TrajMashFunc = 'TrajMash20RespPhasesGaussian';


