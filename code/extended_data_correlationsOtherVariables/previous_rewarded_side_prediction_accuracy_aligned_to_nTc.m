res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','commitment_s','alpha',0.95,'by_hemisphere',false,'variable','previous_rewardxchoice');
figure('position',[795   405   481   452]);
regions=DV.get_brain_regions;
xlim=[-0.62 0.62];
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
h=line([0 0],[0.5 1], 'color','k','linestyle','--','linewidth',1);
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),xlim);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(xlim(2)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end




res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','commitment_s','alpha',0.95,'by_hemisphere',false,'by_region',false,'variable','previous_rewardxchoice');
regions="";
color=[1 1 1]/2;
hemispheres="";
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),xlim);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(xlim(2)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
end
set(gca,'ylim',[0.5 1],'tickdir','out');
ylabel('Prediction Accuracy')
xlabel('Time after nT_c (s)')


ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['previous_rewarded_side_prediction_accuracy_commitment_aligned.',ext{i}]));
end