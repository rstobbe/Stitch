clear

Options = StitchLungWaterMultiAcq1aOptions(); 

AcqInfoFile = 'D:\StitchNew\StitchRelated\Trajectories\ReadoutTest_VaryVOX_210824\130\YB_F350_V429_E100_T13_N2738_P236_S10100_ID20210824_X2.mat';
Options.SetAcqInfoFile(AcqInfoFile);

Options.SetFov2Return([475,475,475]); 
Options.SetStitchSupportingPath('D:\Stitch22\StitchSupportingExtended\');
Options.SetZeroFill(256);
Options.SetImageType('abs');
Options.SetTrajMashFunc('TrajMash20RespPhasesGaussian');

Recon = StitchLungWaterMultiAcq1a(Options);
Recon.Log.SetVerbosity(3);
Recon.Setup;

%---- all your files that you're joining ---
DataObj{1} = SiemensDataObject('D:\testing\2022_02_24_SST_AB\scans\meas_MID00224_FID12528_FOV350_VOX350_FB.dat');                        
DataObj{2} = SiemensDataObject('D:\testing\2022_02_24_SST_AB\scans\meas_MID00224_FID12528_FOV350_VOX350_FB.dat');                        

Recon.SetData(DataObj);
Recon.Initialize;
Recon.LoadData;
Recon.TrajMash;
Recon.Process;
Recon.Finish;
SaveImageLungWaterGroup(Recon, 'D:\testing\2022_02_24_SST_AB', '_1');








