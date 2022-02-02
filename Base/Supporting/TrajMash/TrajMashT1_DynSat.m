%=================================================================================
% WeightArr = [Traj1_Ave1 Traj1_Ave2 ... TrajN_AveN 
%  - sum of weights over averages for each trajectory must equal 1.
%=================================================================================

function TrajMashInfo = TrajMashT1_DynSat(k0,MetaData)

%------------------------------------------------
% Drop Zeros
%------------------------------------------------
if length(k0) ~= MetaData.NumTraj * MetaData.NumAverages
    error('array length does not match metadata info');
end
NumAcqs = MetaData.NumAverages * MetaData.NumTraj;
skip_value=MetaData.skip;

sat_repeat=400;
TR=MetaData.TR;

sat_time=zeros(1,NumAcqs);
counter=1;
for(Acq=1:NumAcqs)
    sat_time(Acq)=counter*TR;
    if counter==sat_repeat-1
        counter=0;
        sat_repeat=sat_repeat+skip_value;
    end
    counter=counter+1;
   
end
        

%------------------------------------------------
% Filter
%------------------------------------------------
startSkip = 2000; 
Fst1 = 0.025;
Fp1 = 0.05;
Fp2 = 0.5;
Fst2 = 0.6;
TR = MetaData.TR;
nCoil = size(k0,2);
y6 = zeros(size(k0));
range = zeros(1,nCoil);
sample_rate = 1/(TR/1000);
d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',Fst1,Fp1,Fp2,Fst2,60,1,60,sample_rate);                   
Hd = design(d,'cheby2');
for i = 1:nCoil
    y1 = abs(k0(:,i));
    y1 = y1-mean(y1);
    y2 = filter(Hd,y1);
    y3 = flip(y2);
    y4 = filter(Hd,y3);
    y5 = flip(y4);
    range(i) = max(y5((startSkip+1):end)) - min(y5((startSkip+1):end));                         
    y6(startSkip:end,i) = y5(startSkip:end)';
end

%------------------------------------------------
% Drop irrelevant channels
%------------------------------------------------
skip = 5*MetaData.NumAverages;                                         
cc = zeros(nCoil,nCoil);
if(nCoil>2)
    for j = 1:nCoil
        for k = 1:nCoil
            ttt = corrcoef(y6(5000:skip:end,j),y6(5000:skip:end,k));
            cc(j,k) = ttt(1,2);
        end
    end
    for j = 1:nCoil
        inds(j) = length(find(abs(cc(:,j))>0.80));
    end
    indsToUse=find(inds>(nCoil/4));
      if(isempty(indsToUse))
        indsToUse=find(inds>(0.5*max(inds)));
    end
else
    indsToUse=[1,2];
end
RespData=y6(:,indsToUse);

%------------------------------------------------
% PCA covariance method
%------------------------------------------------
X = RespData;
u = mean(X,1);
h = ones(length(X),1);
B = X-h*u;
C = cov(B);
[V,D] = eig(C);
[d,ind] = sort(diag(D));
W = V(:,ind(end));                      % weight the most correlated one the most (and get signs right)
%----
Z1 = zscore(X,[],2);                    % across coils       
T1 = Z1*W;
[a b] = sort(abs(T1));
T1 = T1' / mean(a(end-20:end));
%----
Z2 = zscore(X,[],1);                    % across acquisitions      
T2 = Z2*W;
[a b] = sort(abs(T2));
T2 = T2' / mean(a(end-20:end));
%----
NavSig = T2;


%------------------------------------------------
% Get Gaussian Weighting
%------------------------------------------------
peaks = peakfinder(NavSig);
peaks_diff = diff(peaks);
%figure(10001); hold on; plot(NavSig); plot(T1); plot(peaks,NavSig(peaks),'ro')

RespPhaseOfAcq = zeros(1,NumAcqs);
for j = 1:length(peaks_diff)
  inds = (peaks(j)+1):peaks(j+1);
  RespPhaseOfAcq(inds) = (inds-inds(1))/(length(inds)-1);
end
RespPhaseOfAcq(1:startSkip) = -1;
RespPhaseOfAcq(end:NumAcqs) = -1;
%figure(10002); hold on; plot(RespPhaseOfAcq); 

%SatRange = [0 500 800 1200 1700 2300 3000 4000 5700];
%SatRange = [0 100 300 500 800 1200 1700 2300 3000 4000 5700];
SatRange = [0 500 1000 1500 2250 4500 7800]; 


gauss_std=0.05;
RespPhaseImage=[0:0.1:0.95];
NumImages = (length(SatRange)-1)*length(RespPhaseImage);
%NumImages = length(SatRange)-1;
NormWeightArr = zeros(NumAcqs,NumImages);
SatTimesTotal=zeros(MetaData.NumTraj,NumImages);
for Resp_phase=1:length(RespPhaseImage)
    for SatTime=1:length(SatRange)-1
        miss=0;
        for(Traj=1:MetaData.NumTraj)
            AcqNum = Traj:MetaData.NumTraj:MetaData.NumTraj*MetaData.NumAverages;
            SatTimeAcrossAves=sat_time(AcqNum);
            Weight=zeros(1,length(SatTimeAcrossAves));
            if(0.5+RespPhaseImage(Resp_phase)<1)
                x=[0.05+0.005+RespPhaseImage(Resp_phase):0.005:1 0:0.005:0.05+RespPhaseImage(Resp_phase)];
            else
                x=[RespPhaseImage(Resp_phase)-0.05:0.005:1 0:0.005:RespPhaseImage(Resp_phase)-0.05-0.005];
            end
            %x=[0.025+0.005+RespPhaseImage:0.005:1 0:0.005:0.025+RespPhaseImage];
            RespPhases=RespPhaseOfAcq(AcqNum);
            good_ind=find((SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1)));

            GaussWin = gaussmf(0:0.005:1,[gauss_std 0.5]);
            Weight(good_ind)=interp1(x,GaussWin,RespPhases(good_ind));
            SatTimesTotal(Traj,(Resp_phase-1)*(length(SatRange)-1)+SatTime)=mean(SatTimeAcrossAves(good_ind));
            
            %Weight(SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1))=1;
            if(sum(Weight)==0)
                miss=miss+1;
            end
            NormWeight = Weight / (sum(Weight));
            NormWeight(isnan(NormWeight))=0;
            %NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,SatTime) = NormWeight;  
            NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,(Resp_phase-1)*(length(SatRange)-1)+SatTime) = NormWeight;  
        end
        SatTimeMeans((Resp_phase-1)*(length(SatRange)-1)+SatTime)=mean(SatTimesTotal(:,(Resp_phase-1)*(length(SatRange)-1)+SatTime));
        miss
    end
end
% 
% 
% for SatTime=1:NumImages
%     miss=0;
%     for(Traj=1:MetaData.NumTraj)
%         AcqNum = Traj:MetaData.NumTraj:MetaData.NumTraj*MetaData.NumAverages;
%         SatTimeAcrossAves=sat_time(AcqNum);
%         Weight=zeros(1,length(SatTimeAcrossAves));
%         x=[0.025+0.005+RespPhaseImage:0.005:1 0:0.005:0.025+RespPhaseImage];
%         RespPhases=RespPhaseOfAcq(AcqNum);
%         good_ind=find((SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1)));
%           
%         GaussWin = gaussmf(0:0.005:1,[gauss_std 0.5]);
%         Weight(good_ind)=interp1(x,GaussWin,RespPhases(good_ind));
%         %Weight(SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1))=1;
%         if(sum(Weight)==0)
%             miss=miss+1;
%         end
%         NormWeight = Weight / (sum(Weight));
%         NormWeight(isnan(NormWeight))=0;
%         NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,SatTime) = NormWeight;  
%     end
%     miss
% end
% 
% 
% for SatTime=1:NumImages
%     miss=0;
%     for(Traj=1:MetaData.NumTraj)
%         AcqNum = Traj:MetaData.NumTraj:MetaData.NumTraj*MetaData.NumAverages;
%         SatTimeAcrossAves=sat_time(AcqNum);
%         Weight=zeros(1,length(SatTimeAcrossAves));
%         %good_ind=find((RespPhaseOfAcq(AcqNum)>0.7 | RespPhaseOfAcq(AcqNum) < 0.3) & ...
%         good_ind=find((RespPhaseOfAcq(AcqNum)>0.3 & RespPhaseOfAcq(AcqNum) < 0.7) & ...
%         (SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1)));
%         Weight(good_ind)=1;
%         %Weight(SatTimeAcrossAves >=SatRange(SatTime) & SatTimeAcrossAves <=SatRange(SatTime+1))=1;
%         if(sum(Weight)==0)
%             miss=miss+1;
%         end
%         NormWeight = Weight / (sum(Weight));
%         NormWeight(isnan(NormWeight))=0;
%         NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,SatTime) = NormWeight;  
%     end
%     miss
% end

        
% for RespPhaseNum = 1:NumImages  
%     GaussWin = gaussmf(0:0.005:1,[0.05 0.5]);
%     if(0.5+RespPhaseImages(RespPhaseNum)<1)
%         x=[0.025+0.005+RespPhaseImages(RespPhaseNum):0.005:1 0:0.005:0.025+RespPhaseImages(RespPhaseNum)];
%     else
%         x=[RespPhaseImages(RespPhaseNum)-0.025:0.005:1 0:0.005:RespPhaseImages(RespPhaseNum)-0.025-0.005];
%     end
%     for Traj = 1:MetaData.NumTraj
%         AcqNum = Traj:MetaData.NumTraj:MetaData.NumTraj*MetaData.NumAverages;
%         RelBreathPhaseAcrossAves = RespPhaseOfAcq(AcqNum);
%         figure(10002); plot(AcqNum,RelBreathPhaseAcrossAves,'*');
%         Weight = interp1(x,GaussWin,RelBreathPhaseAcrossAves);
%         Weight(isnan(Weight)) = 0;
%         NormWeight = Weight / (sum(Weight));
%         NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,RespPhaseNum) = NormWeight;  
%     end
% end

%NumImages = MetaData.NumAverages;
%NormWeightArr = ones(NumAcqs,NumImages);

% 
% 
% counter=1;
% for(sat=1:NumImages)
% %     for(ave=1:NumImages)
%         test=zeros(1,MetaData.NumAverages);
%         test(sat)=1;
%         for Traj = 1:MetaData.NumTraj           
% %         NormWeightArr(MetaData.NumTraj*(ave-1)+(sat-1)*shift_value+1:MetaData.NumTraj*(ave-1)+sat*shift_value,sat)=1;
%            NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,sat)=test;          
%         end
% % end
% 
% NormWeightArr = zeros(NumAcqs,NumImages);
% counter=1;
% for(sat=1:NumImages)
%     for(ave=1:NumImages)
%         test=zeros(1,MetaData.NumAverages);
%         %test(mod(1-ave,NumImages)+1)=1;
%         %test(mod(1-sat+ave,NumImages))=1;
%         test(ave)=1;
%         for Traj=mod(floor((sat-1)*shift_value)+floor((ave-1)*shift_value)-1:floor((sat-1)*shift_value)+floor((ave)*shift_value)-1,MetaData.NumTraj)+1% Traj = mod(floor((sat-1)*shift_value)+floor((ave-1)*shift_value)+1:floor((sat-1)*shift_value)+floor((ave)*shift_value),MetaData.NumTraj-1)+1           
%              NormWeightArr((Traj-1)*MetaData.NumAverages+1:Traj*MetaData.NumAverages,sat)=test;
%         end
%      
%     end
% end

%NormWeightArr=NormWeightArr(reorg_index,:);

TrajMashInfo.WeightArr = single(NormWeightArr);
TrajMashInfo.NavSig=single(NavSig);
TrajMashInfo.Time=single(TR/1000*[1:length(NavSig)]);
TrajMashInfo.SatRange=SatRange;
TrajMashInfo.MeanSatTime=SatTimeMeans;
%TrajMashInfo.reorg_index=reorg_index;


