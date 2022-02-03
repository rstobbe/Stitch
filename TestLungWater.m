clear

Options = StitchLungWater1aOptions(); 

AcqInfoFile = 'D:\StitchSupportingExtended\Trajectories\YB_F350_V270_E100_T15_N3362_P224_S10100_ID2106021_X2.mat';
Options.SetAcqInfoFile(AcqInfoFile);

Options.SetFov2Return([475,475,475]); 
Options.SetStitchSupportingPath('D:\StitchSupportingExtended\');
Options.SetZeroFill(256);
Options.SetImageType('abs');
Options.SetTrajMashFunc('TrajMash10RespPhasesGaussianSig02');

Recon = StitchLungWater1a(Options);
Recon.Log.SetVerbosity(3);
Recon.Setup;

DataFile = 'I:\210628 (Moist169)\meas_MID00165_FID84159_Vent210602.dat';
DataObj = SiemensDataObject(DataFile);                        

Recon.SetData(DataObj);
Recon.Initialize;
Recon.LoadData;
Recon.TrajMash;
Recon.Process;
Recon.Finish;

Recon.ReturnImageCompass;






