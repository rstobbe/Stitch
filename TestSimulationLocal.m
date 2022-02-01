clear

Options = StitchStandard1aOptions(); 
%Options.SetAcqInfoFile('E:\Trajectories\SpaceY\F230_V0080_E100_T050_N1152_SW100_SEOR\YB_F230_V80_E100_T50_N1152_P133_S10100_ID1.mat');
Options.SetAcqInfoFile('E:\Trajectories\TPI\23NaSiemens\_Skin\F240_V2700_E010_T090_N6000_B0\TPI_F240_V2700_E10_T90_N6000_P300_ID1_X2.mat');

Options.SetFov2Return('All'); 
Options.SetStitchSupportingPath('D:\StitchSupportingExtended\');
Options.SetZeroFill(384);
Options.SetCoilCombine('Single');

Recon = StitchStandard1a(Options);
Recon.Log.SetVerbosity(3);
Recon.Setup;

%load('E:\Trajectories\SpaceY\F230_V0080_E100_T050_N1152_SW100_SEOR\_Testing\KSMP_Sphere200.mat');
file = 'E:\Trajectories\TPI\23NaSiemens\_Skin\F240_V2700_E010_T090_N6000_B0\zz Testing\KSMP_Plane12120_T049.mat';
DataObj = SimulationDataObject(file);                            

Recon.CreateImage(DataObj);

Recon.ReturnImageCompass;






