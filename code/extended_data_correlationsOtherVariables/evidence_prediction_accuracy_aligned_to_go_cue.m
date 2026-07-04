res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','cpoke_req_end','alpha',0.95,'by_hemisphere',false,'relaxed',false,'variable','evidence','resolution_s',0.1);
figure('position',[795   405   481   452]);
regions=DV.get_brain_regions;
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'R2',regions(r),hemispheres,color(r,:));hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end




res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','cpoke_req_end','alpha',0.95,'by_hemisphere',false,'by_region',false,'variable','evidence','resolution_s',0.1);
color=[1 1 1]/2;
hemispheres="";
regions="";
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'R2',regions(r),hemispheres,color);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
end
set(gca,'ylim',[0 1],'tickdir','out');
ylabel('Prediction Accuracy (R^2)')
xlabel('Time relative to go cue (s)')




ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['evidence_prediction_accuracy_aligned_to_go_cue.',ext{i}]));
end