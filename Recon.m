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
%ReconMetaData.TrajFile = 'C:\Users\Justin\Documents\MATLAB\Stitch\Trajectories\YB_F300_V156_E100_T13_N6555_P304_S10100_ID210212_X.mat';
%ReconMetaData.TrajFile = 'C:\Users\Justin\Documents\MATLAB\Stitch\Trajectories\YB_F350_V270_E100_T15_N3362_P224_S10100_ID2106021.mat';
%ReconMetaData.TrajFile = 'C:\Users\Justin\Documents\MATLAB\Stitch\Trajectories\YB_F400_V429_E100_T13_N3362_P228_S10100_ID20211005.mat';
ReconMetaData.TrajFile = 'C:\Users\Justin\Documents\MATLAB\Stitch\Trajectories\YB_F350_V429_E100_T13_N2738_P236_S10100_ID20210824.mat';
%ReconMetaData.TrajFile = 'C:\Users\Justin\Documents\MATLAB\Stitch\Trajectories\YB_F350_V270_E100_T13_N4050_P246_S10100_ID210729.mat';
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
%ReconMetaData.ReconFunction = 'StitchReconT1';
  ReconMetaData.ReconFunction = 'StitchReconTrajMash';
%ReconMetaData.ReconFunction = 'StitchReconStandard';
%ReconMetaData.SeqName = 'YUT1sa3f_v1k_DynSat';
ReconMetaData.SeqName = 'YUTEsa3f_v1k';
%ReconMetaData.UseAverages=[8];
%ReconMetaData.TrajMashFunc = 'TrajMash20RespPhasesGaussian_SpecAverages';
ReconMetaData.TrajMashFunc = 'TrajMash20RespPhasesGaussian';
%ReconMetaData.TrajMashFunc = 'TrajMash20RespPhasesGaussianWithMask';
%ReconMetaData.TrajMashFunc = 'TrajMashMinMax';
%ReconMetaData.TrajMashFunc = 'TrajMashT1_DynSat';


