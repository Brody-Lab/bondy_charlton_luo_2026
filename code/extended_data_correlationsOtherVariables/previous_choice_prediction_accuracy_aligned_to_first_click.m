res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'relaxed',false,'variable','previous_choice');
figure('position',[795   405   481   452]);
regions=DV.get_brain_regions;
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 0.95]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end




res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'by_region',false,'variable','previous_choice');
regions="";
color=[1 1 1]/2;
hemispheres="";
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 0.95]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
end
set(gca,'xlim',[0 h(1).mainLine.XData(end)+0.05],'ylim',[0.5 1],'tickdir','out');
ylabel('Choice Prediction Accuracy')
xlabel('Time after first click (s)')




ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['choice_prediction_accuracy.',ext{i}]));
end