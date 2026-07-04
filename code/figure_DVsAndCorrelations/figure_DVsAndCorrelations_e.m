
%% load data
choice_prediction_path = fullfile(repo_path,"data","common","choice_prediction");
res = common.load_DVs_in_run(choice_prediction_path,"2025_03_12_15_49_41");

%% set session and trials
sess_id=1;
res=res{sess_id}{1};
n_regions = numel(res);        
[~,gidx,missing_trials] = DV.find_matched_trials(res(1).Trials,{'seed','pokedR'}); 
res = DV.remove_trials_from_res(res,missing_trials);      
Trials = res(1).Trials;
idx = common.sort_items([res.hemisphere],["left","right"]);
res=res(idx);
idx = common.sort_items([res.region],common.get_brain_regions);
res=res(idx);
res=flip(res);
res(1).Trials=Trials;
seed=83;
trials = find(gidx==seed);
trials=trials([6 7 11 12 13]);
nt=numel(trials);

%% subtract groups means of DVs
clear DVs DVs_corrected
for k=n_regions:-1:1
    DVs(:,:,k) = res(k).log_odds;    
    DVs_corrected(:,:,k) = DV.subtract_group_mean(res(k).log_odds,gidx);         
end        
mean_dvs = squeeze(nanmean(DVs(trials,:,:)));


%% set up plotting parameters
colors=common.get_brain_region_colors([res.region]);
factor=4;
xlim=0.65;
plot_timepts=1:12;

%% plot
figure('position',[600 437 671 700]);hold on;
for i=0:nt
    subplot(1,nt+1,i+1);
    if i==0
        patch([0 1 1 0],[0 0 73 73],'k','facealpha',0.2,'edgecolor','none');hold on;
        text(-0.2,77,'Mean DV','Color',[1 1 1]/2);
        h=plot(res(1).bin_params.time_s(plot_timepts),[0:n_regions-1]*factor + mean_dvs(plot_timepts,:),'LineWidth',2);
        set(gca,'ylim',[-4 75],'xlim',[0  xlim]);hold on;
        g=plot(res(1).bin_params.time_s,repmat([0:n_regions-1]'*factor,1,numel(res(1).bin_params.time_s)),'k:');
        for k=1:n_regions
            h(k).Color = colors(k,:);        
            g(k).Color = colors(k,:);        
        end
        for n=1:n_regions
            label = strjoin([res(n).region,', ',upper(res(n).hemisphere{1}(1))]);
            text(-0.5,(n-1)*factor,label,'color',colors(n,:),'HorizontalAlignment','center','VerticalAlignment','middle');
        end
        axis off
    end
    if i==2
        text(-0.1,77,'Single trial DV residuals');hold on;
        text(-0.1,-8,'Time since first click (s)');
    end
    rbups=res(1).Trials.rightBups{trials(max(i,1))};
    rbups=rbups-rbups(1);
    lbups=res(1).Trials.leftBups{trials(max(i,1))};
    lbups=lbups-lbups(1);        
    scatter(rbups,(n_regions+1)*factor,'|k')   ; hold on
    scatter(lbups,(n_regions+1)*factor-1.5,'|k')   ;   
    line([0 0],[0 73],'color','k');
    text(-0.05,-1.5,'0');
    
    if i==0
        text(-1,(n_regions+1)*factor,'R clicks');
        text(-1,(n_regions+1)*factor-1.5,'L clicks');        
        continue
    end
    h=plot(res(1).bin_params.time_s(plot_timepts),[0:n_regions-1]*factor + squeeze(DVs_corrected(trials(i),plot_timepts,:)) ,'LineWidth',2);
    set(gca,'ylim',[-4 75],'xlim',[0  xlim]);hold on;
    g=plot(res(1).bin_params.time_s,repmat([0:n_regions-1]'*factor,1,numel(res(1).bin_params.time_s)),'k:');
    for k=1:n_regions
        h(k).Color = colors(k,:);        
        g(k).Color = colors(k,:);        
    end
    axis off
end

%% save output
common.savefig(gcf,mfilename);