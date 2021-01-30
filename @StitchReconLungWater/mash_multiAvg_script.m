%%
[filename pathname] = uigetfile('*.dat','Select the zip-files');
%save_folder='M:\ThompsonLab\studies\MEADUS\JGG_Analysis\Data\FreeBreathing\Test5_SingleEcho\';
save_folder='E:\Yarnball\NewSite\1st_scan\post_gad\'
dP = mapVBVD(fullfile(pathname,filename)); %necessary function to extract raw data


% k = dP{2}.image(1,:,:,1,1,:);%[2060 30 7381 1 1 5 1 1 1 1 1 1 1 1 1 1]

tic
if(iscell(dP))
%ksp = dP{2}.image.unsorted;
TR=dP{2}.hdr.Config.TR/1000;
max_averages=dP{2}.hdr.Config.NAve;
Lines=dP{2}.hdr.Config.NLinMeas;
else
    ksp = dP.image.unsorted;
TR=dP.hdr.Config.TR/1000;
max_averages=dP.hdr.Config.NAve;
Lines=dP.hdr.Config.NLinMeas;
end
toc
%ksp = dP.image.unsorted;
%TR=dP.hdr.Config.TR/1000;

%  aaa=squeeze(dP{2}.image(1,:,:,:,:));
%  aaa=abs(reshape(aaa,size(aaa,1),size(aaa,2)*size(aaa,3)));
%  k0(1,:,:)=aaa;
%  clear aaa



k0 = abs(ksp(1,:,:)); %selecting the first point of k-space

filt_offset=0.003;
% max_averages=[5:5];
%%
options.TR=TR;

options.Fst1=0.025;
options.Fp1=0.05;
options.Fp2=0.5;
options.Fst2=0.6;
%min_average=[2:4];
%averages=[2:max_averages];
averages=max_averages;
%options.min_average=5;

for(avg=1:length(averages))

    %UserMash=mash_JGG_maxAvg(k0,7381,filt_offset,max_averages(avg),options);
    %options.min_average=min_average(avg);

    UserMash_bothPhases=mash_JGG_maxAvg(k0,Lines,filt_offset,averages(avg),options);
    
  %  pause
    
    %save(strcat(save_folder,'UserMash_MaxAvg_',num2str(averages(avg)),'RPT_',filename(end-20:end-4)),'UserMash');
    %save(strcat(save_folder,'UserMash_MaxAvg_',num2str(options.min_average),'To',num2str(averages(avg)),'RPT_',filename(end-20:end-4)),'UserMash');
    
    UserMash=UserMash_bothPhases{1};
    save(strcat(save_folder,'UserMash_',filename(15:end-4),'_exp'),'UserMash');
    UserMash=UserMash_bothPhases{2};
    save(strcat(save_folder,'UserMash_',filename(15:end-4),'_insp'),'UserMash');
    
    %save(strcat(save_folder,'UserMash_',filename(15:end-4)),'UserMash')
    %save(filename(end-10:end-4),'UserMash')
end

