% FIGURE 2D
% choice prediction accuracy curves for each region

%% load results of choice prediction, with regions separate and pooled across hemispheres
 res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true,'frozen',false);
%% load results of choice prediction, with all neurons pooled together
 %res_all = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true,'frozen',false,'by_region',false);

%% combine choice prediction accuracy across sessions and plot for each region
figure('position',[   152   423   389   383]);hold on;

for i=1:2
    subplot(1,2,i);
    if i==1
        hemispheres="left";
    else
        hemispheres="right";        
    end
    regions=common.get_brain_regions;
    color=common.get_brain_region_colors(regions);
    clear h
    for r=numel(regions):-1:1
        h(r)=common.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 1]);hold on;
        h(r).patch.FaceAlpha=1;    
        text(h(r).mainLine.XData(end)+0,1-0.05*r,regions(r),'Color',color(r,:));
    end
    
    
    %% combine choice prediction accuracy across sessions and plot
    regions="";
    color=[1 1 1]/2;
    clear h
    for r=numel(regions):-1:1
        h(r)=common.plot_combined_metric(res_all,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 1]);hold on;
        h(r).patch.FaceAlpha=1;    
        text(h(r).mainLine.XData(end)+0,1,"all",'Color',color(r,:));
    end
    
    %% set axis properties
    set(gca,'xlim',[0 1],'ylim',[0.5 1],'tickdir','out','xtick',[0.1 0.3 0.8],'ytick',[0.5 0.75 1]);
    ylabel('Choice Prediction Accuracy')
    xlabel('Time since first click (s)')
    if i==1
        title('Left Hemisphere');
    else
        title('Right Hemisphere');
    end
end

%% save output
common.savefig(gcf,which(mfilename));