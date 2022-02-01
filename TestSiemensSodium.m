clear

Options = StitchStandard1aOptions(); 
Options.SetAcqInfoFile('E:\Trajectories\TPI\23NaSiemens\_Skin\F240_V1382_E010_T180_N3000_B30\TPI_F240_V1382_E10_T180_N3000_P160_ID1_X2.mat');
Options.SetFov2Return('Design'); 
Options.SetStitchSupportingPath('D:\StitchSupportingExtended\');
Options.SetZeroFill(384);

Recon = StitchStandard1a(Options);
Recon.Log.SetVerbosity(3);
Recon.Setup;

file = 'I:\220125 (23NaSkinTesting3T_BlueBottle)\meas_MID00282_FID08779_23NaSkinTest1.dat';
DataObj = SiemensDataObject(file);                        

Recon.CreateImage(DataObj);

Recon.ReturnImageCompass;






