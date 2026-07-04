name=mfilename;
path=fileparts(which(mfilename));
figure('position',[330 630 2000 364]);



subplot(1,3,1);
%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'relaxed',false,'frozen',false);
res=res_click;
    clear bad
    for i=numel(res):-1:1
        if res{i}{1}(1).params.recording_id=="C211_2024_01_01" || res{i}{1}(1).params.recording_id=="C211_2024_01_02"
            bad(i)=true;
        else
            bad(i)=false;
        end
    end
    res=res(~bad);
    clear bad
for i=1:numel(res)
        if iscell(res{i})
            res{i} = res{i}{1};
        end
        %% remove all unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_all);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);  
end
regions=DV.get_brain_regions;
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 0.95]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end
box off




% res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',false,'by_region',false);
% for i=1:numel(res)
% 
%         if iscell(res{i})
%             res{i} = res{i}{1};
%         end
%         %% remove all unmatched trials
%         remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_M1);
%         res{i} = DV.remove_trials_from_res(res{i},remove_trial);  
% end
% regions="";
% color=[1 1 1]/2;
% hemispheres="";
% clear h
% for r=numel(regions):-1:1
%     h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[0 0.95]);hold on;
%     h(r).patch.FaceAlpha=0.75;    
%     text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
% end
set(gca,'xlim',[0 h(1).mainLine.XData(end)+0.05],'ylim',[0.5 1],'tickdir','out','ygrid','on');
ylabel('Choice Prediction Accuracy')
xlabel({'time (s) relative to','first click'})





%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','cpoke_out','alpha',0.95,'by_hemisphere',false,'relaxed',false);
res=res_cpoke_out;
    clear bad
    for i=numel(res):-1:1
        if res{i}{1}(1).params.recording_id=="C211_2024_01_01" || res{i}{1}(1).params.recording_id=="C211_2024_01_02"
            bad(i)=true;
        else
            bad(i)=false;
        end
    end
    res=res(~bad);
    clear bad
for i=1:numel(res)
        
        if iscell(res{i})
            res{i} = res{i}{1};
        end
        %% remove all unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_all);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);  
end
subplot(1,3,3);
regions=DV.get_brain_regions;
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[-Inf 0]);hold on;
    h(r).patch.FaceAlpha=0.75;    
    %text(h(r).mainLine.XData(end)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end
box off


% 
% res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','cpoke_out','alpha',0.95,'by_hemisphere',false,'by_region',false);
% for i=1:numel(res)
%         if iscell(res{i})
%             res{i} = res{i}{1};
%         end
%         %% remove all unmatched trials
%         remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_M1);
%         res{i} = DV.remove_trials_from_res(res{i},remove_trial);  
% end
% regions="";
% color=[1 1 1]/2;
% hemispheres="";
% clear h
% for r=numel(regions):-1:1
%     h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),[-Inf 0]);hold on;
%     h(r).patch.FaceAlpha=0.75;    
%     %text(xlim(2)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
% end
set(gca,'xlim',[-0.8 0],'ylim',[0.5 1],'tickdir','out','ygrid','on');
ax=gca;
ax.YAxis.Visible='off';
xlabel({'time (s) relative to','movement onset'})






%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','committime_s_M1','alpha',0.95,'by_hemisphere',false);
res=res_commit;
    clear bad
    for i=numel(res):-1:1
        if res{i}{1}(1).params.recording_id=="C211_2024_01_01" || res{i}{1}(1).params.recording_id=="C211_2024_01_02"
            bad(i)=true;
        else
            bad(i)=false;
        end
    end
    res=res(~bad);
    clear bad
for i=1:numel(res)
        
        if iscell(res{i})
            res{i} = res{i}{1};
        end
        %% remove all unmatched trials
        %remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_M1);
        %res{i} = DV.remove_trials_from_res(res{i},remove_trial);  
end
subplot(1,3,2);
regions=DV.get_brain_regions;
xlim=[-0.55 0.45];
color=uberphys.get_brain_region_colors(regions);
hemispheres=["right" "left" ""];
clear h
h=line([0 0],[0.5 1], 'color','k','linestyle','--','linewidth',1);
clear h
for r=numel(regions):-1:1
    h(r)=DV.plot_combined_metric(res,'balanced_accuracy',regions(r),hemispheres,color(r,:),xlim);hold on;
    h(r).patch.FaceAlpha=0.75;    
    %text(xlim(2)+0.01,h(r).mainLine.YData(end),regions(r),'Color',color(r,:));
end
box off




% res2 = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','committime_s_M1','alpha',0.95,'by_hemisphere',false,'by_region',false);
% for i=1:numel(res2)
%         if iscell(res2{i})
%             res2{i} = res2{i}{1};
%         end
%         %% remove all unmatched trials
%         remove_trial = isnan(res{i}(1).Trials.stateTimes.committime_s_M1);
%         res2{i} = DV.remove_trials_from_res(res2{i},remove_trial);  
% end
% regions="";
% color=[1 1 1]/2;
% hemispheres="";
% clear h
% for r=numel(regions):-1:1
%     h(r)=DV.plot_combined_metric(res2,'balanced_accuracy',regions(r),hemispheres,color(r,:),xlim);hold on;
%     h(r).patch.FaceAlpha=0.75;    
%     %text(xlim(2)+0.01,h(r).mainLine.YData(end),"all",'Color',color(r,:));
% end
set(gca,'ylim',[0.5 1],'tickdir','out','ytick',0.5:0.1:1,'ygrid','on','xlim',[-0.4 0.4]);
xlabel({'time (s) relative to','nTc'})
text(-0.3,0.95,'Data','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',14);
ax=gca;
ax.YAxis.Visible='off';

ax_data=gca;
drawnow;
%plot_bilinear_fit(ax_fit,ax_slope,ax_break,res,res2,xlim,ax_data.Position(3:4));

ext = {'pdf','fig','png'};
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[name,'.',ext{i}]));
end