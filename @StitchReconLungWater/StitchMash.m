function obj = StitchMash(obj,DataObj)

k0 = squeeze(abs(obj.Data(1,:,:) + 1j*obj.Data(2,:,:))).'; %selecting the first point of k-space
k0 = reshape(k0,[1,size(k0)]);

if strcmp(DataObj.ReturnHandler,'RwsSiemensHandler')
    TR = DataObj.DataHdr.alTR{1};
    Lines = DataObj.TotalAcqs/obj.Aves;
end
 
averages = obj.Aves;
filt_offset = 0.003;
options.TR = TR/1000;
options.Fst1 = 0.025;
options.Fp1 = 0.05;
options.Fp2 = 0.5;
options.Fst2 = 0.6;

UserMash_bothPhases = mash_JGG_maxAvg(obj,k0,Lines,filt_offset,averages,options);

obj.UserMash = UserMash_bothPhases{1};              % Expiration
%obj.UserMash = UserMash_bothPhases{2};              % Inpiration

    
