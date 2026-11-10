res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','committime_s_M1','variable','choice','by_hemisphere',false);

clear ntc_click_aligned ntc_cpoke_out_aligned
for i=1:5
   ntc_click_aligned{i} = res{i}{1}(1).Trials.stateTimes.committime_s_M1 -  res{i}{1}(1).Trials.stateTimes.first_click;
   ntc_cpoke_out_aligned{i} = res{i}{1}(1).Trials.stateTimes.committime_s_M1 -  res{i}{1}(1).Trials.stateTimes.cpoke_out;   
end

ntc_click_aligned = cat(1,ntc_click_aligned{:});
ntc_cpoke_out_aligned = cat(1,ntc_cpoke_out_aligned{:});

ntc_cpoke_out_aligned(ntc_cpoke_out_aligned<-1) = -0.99;

figure('position',[936 1136 624 102]);
subplot(1,2,1);
histogram(ntc_click_aligned,'NumBins',15,'BinLimits',[0 1],'Normalization','probability');
set(gca,'xlim',[0 1],'tickdir','out');
xlabel('Time (s) relative to first click');
subplot(1,2,2);
histogram(ntc_cpoke_out_aligned,'NumBins',15,'BinLimits',[-1 0],'Normalization','probability');
set(gca,'xlim',[-1 0],'tickdir','out');
xlabel('Time (s) relative to response onset');
