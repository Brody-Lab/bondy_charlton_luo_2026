
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'relaxed',false,'by_region',true);
figure('position',[   152   423   389   383]);
regions=DV.get_brain_regions;
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 1]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end

res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'by_region',false);
regions="";
color=[1 1 1]/2;
hemispheres="";
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 1]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0,h(r).mainLine.YData(end),"all",'Color',color(r,:));
end
set(gca,'xlim',[0 1],'ylim',[0.5 1],'tickdir','out');
ylabel('Choice Prediction Accuracy')
xlabel('Time after first click (s)')

ext={'pdf','png','fig'};
path=fileparts(which(mfilename));
set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['choice_prediction_accuracy.',ext{i}]));
end

print(gcf,'-vector','-dpdf',fullfile(path,['choice_prediction_accuracy.','pdf']))