function UserMash_bothResp=mash_JGG_maxAvg(obj,k0,lin,filt_offset,max_average,options)
% mash(k0,ID,lin,ave,filt_offset) is used to make a 'UserMash' file.
% This file determines what data to use in a reconstruction, based on
% respiratory position (retrospective gating). One of each trajectory
% falling closest to end expiration is used.
%
% k0 == extracted k-space centers (from k0 extract)
% ID == to label save data, mash_ID is generated
% lin == number of trajectories in data
% ave == number of averages in data
% filt_offset == to adjust where the upper bound of the bandpass filter
% lies, can be adjusted to clean up waveforms depending on the sequence
% used and the volunteers breathing rate
%
% W. Quinn Meadus, June 2019

%Base sequence parameter info, set for final free breathing yarn ball sequence
%lin = 7381;
%ave=5;
min_average=1;
if(isfield(options,'min_average'))
    min_average=options.min_average;
end
ave = max_average-min_average+1;

%Map of all k-space lines acquired
mashAll = zeros(lin*ave,2);
for j = 1:ave
    mashAll((1:lin)+lin*(j-1),1) = [1:lin];
    mashAll((1:lin)+lin*(j-1),2) = min_average+j-1;
end

% Multi-Coil Filtering
nCoil = size(k0,2);
delayComp = 10000; %adds zeros so the filtered data reaches the end despite the delay
y6 = zeros(lin*ave,nCoil);
%y6 = -1*ones(lin*ave,nCoil);
startSkip = 3000; %to ignore non-settled data
range = zeros(1,nCoil);

if nargin < 5
    filt_offset = 0;
end

% sample rate is 3.54 ms / sample  = 282 Hz sample rate
sample_rate=1/(options.TR/1000);

for i = 1:nCoil
    y1 = squeeze(abs(k0(1,i,lin*(min_average-1)+1:lin*max_average)))';
    y1 = y1-mean(y1);
    %y1 = [y1,zeros(1,delayComp)];
    
    %d = fdesign.lowpass('Fp,Fst,Ap,Ast',0.003,0.01,1,60); %cut off frequencies in half-cycles/sample
    %d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',0.0001,0.0003,0.007+filt_offset,0.009+filt_offset,60,1,60); %cut off frequencies in half-cycles/sample
   % d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',0.0001,0.0003,0.003,0.009,60,1,60); %cut off frequencies in half-cycles/sample
    d = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',options.Fst1,options.Fp1,options.Fp2,options.Fst2,60,1,60,sample_rate); %cut off frequencies in half-cycles/sample

    Hd = design(d,'cheby2');
    y2 = filter(Hd,y1);
    y3 = flip(y2);
    y4 = filter(Hd,y3);
    y5 = flip(y4);
    
    range(i) = max(y5((startSkip+1):end)) - min(y5((startSkip+1):end)); %finds the absolute signal variation (not including the early unstable values)
    y6(startSkip:end,i) = y5(startSkip:end)';

    
    
end
%%
if(nCoil>2)
    for j = 1:nCoil
        for k = 1:nCoil
            ttt =     corrcoef(y6(5000:end,j),y6(5000:end,k));
            cc(j,k) = ttt(1,2);
        end
    end
    
    for j = 1:nCoil
        inds(j) = length(find(abs(cc(:,j))>0.85));
        %inds(j) = length(find(cc(:,j)>0.85));
    end
    indsToUse=find(inds>17);
else
    indsToUse=[1,2];
end

RespData=y6(:,indsToUse);

% PCA covariance method
n = lin*ave;
p = nCoil;
X = RespData;

u = mean(X,1);
h = ones(n,1);
B = X-h*u;

C = cov(B);

[V,D] = eig(C);

[d,ind] = sort(diag(D));

W = V(:,ind(end));

Z = zscore(X,[],2);

T = Z*W;

[a b] = sort(abs(T));
T = T' / mean(a(end-20:end));

% Taking 1 of each line found closest to the minimum of the PCA waveform
%(end expiration)
UserMash = [];
f = T;

f(1:startSkip)=max(f);
%f(1:startSkip)=min(f);
% %%
% TT = smoothn(T,1e8);
% [pp bb1] = peakfinder(TT);
% [pn bb2] = peakfinder(-TT);
% 
% pp = pp(2:end);
% pn = pn(2:end);
% 
% for j =1:length(pp)
% dd(:,j) = abs([1:length(TT)]-pp(j));
% end
% ddd = min(dd,[],2);
% 
% for j =1:length(pn)
% dd2(:,j) = abs([1:length(TT)]-pn(j));
% end
% ddd2 = min(dd2,[],2);
% 
% trajToFill = 1:lin;
% %%
% thresh=4;
% thresh_factor=0.9;
% i=1;
% while(1)
%     if(i>length(trajToFill))
%         break;
%     end
% 
%     t=trajToFill(i);
%     potentialT = find(mashAll(:,1) == t);
%     [f1 f2] = sort(ddd(potentialT));
%     %find the minimim value of this for usermash ddd(potentialT)
%     
%     UserMash(i,:) = mashAll(potentialT(f2(1)),:);
%     
%     %[~,T_below_thresh]=min(f(potentialT));
%     %T_below_thresh=find(f(potentialT)<thresh_factor*min(f(potentialT)));
%     %trajToAdd=mashAll(potentialT(T_below_thresh),:);
%     %UserMash=[UserMash;trajToAdd];
%         i=i+1;
% end
% 
% %Diagnostic plots
% mashLoc = UserMash(:,1)+(UserMash(:,2)-1)*lin;
% figure
% plot(y6(:,25))
% hold on
% plot(mashLoc, y6(mashLoc,25),'*')
% hold on
% plot(f*5e-5)



%f=smoothn(T,100000000);
trajToFill = 1:lin;

% for i = 1:length(trajToFill)
%     t = trajToFill(i);
%     potentialT = find(mashAll(:,1) == t);
%     [~,n] = min(f(potentialT));
%     
%     [a1 b1] = sort(f(potentialT));
%     
%     
%     data_all_sort(i,:,1) = a1;
%     data_all_sort(i,:,2) = b1;
%     
%     % select different criteria for which averages to include
%     
%     trajToAdd = mashAll(potentialT(n),:);
%     UserMash = [UserMash;trajToAdd];
% end

UserMash=[];
thresh=-0.95;
thresh_factor=-0.95;
i=1;
f(1:startSkip)=max(f);

while(1)
    if(i>length(trajToFill))
        break;
    end
    t=trajToFill(i);
    i=i+1;
    potentialT = find(mashAll(:,1) == t);
    %T_below_thresh=find(f(potentialT)<thresh);
    %T_below_thresh=find(f(potentialT)>thresh);
    %[~,T_below_thresh]=max(f(potentialT));
    [~,T_below_thresh]=min(f(potentialT));
    %T_below_thresh=find(f(potentialT)<thresh_factor*min(f(potentialT)));
    trajToAdd=mashAll(potentialT(T_below_thresh),:);
    UserMash=[UserMash;trajToAdd];
end
%%
%Diagnostic plots
figure
mashLoc = UserMash(:,1)+(UserMash(:,2)-1)*lin;
plot(RespData(:,1))
hold on
plot(mashLoc-(min_average-1)*lin, RespData(mashLoc-(min_average-1)*lin,1),'*')
hold on
plot(f*5e-5)

%First Resp Phase
UserMash_bothResp{1}=UserMash;

UserMash=[];
thresh=0.95;
thresh_factor=0.9;
i=1;
f(1:startSkip)=min(f);

while(1)
    if(i>length(trajToFill))
        break;
    end
    t=trajToFill(i);
    i=i+1;
    potentialT = find(mashAll(:,1) == t);
    %T_below_thresh=find(f(potentialT)<thresh);
    %T_below_thresh=find(f(potentialT)>thresh);
    [~,T_below_thresh]=max(f(potentialT));
    %[~,T_below_thresh]=min(f(potentialT));
    %T_below_thresh=find(f(potentialT)<thresh_factor*min(f(potentialT)));
    trajToAdd=mashAll(potentialT(T_below_thresh),:);
    UserMash=[UserMash;trajToAdd];
end
%%
%Diagnostic plots
figure
mashLoc = UserMash(:,1)+(UserMash(:,2)-1)*lin;
plot(RespData(:,1))
hold on
plot(mashLoc-(min_average-1)*lin, RespData(mashLoc-(min_average-1)*lin,1),'*')
hold on
plot(f*5e-5)

UserMash_bothResp{2}=UserMash;


