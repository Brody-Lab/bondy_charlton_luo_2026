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
res(1).Trials=Trials;

%% calculate SD across trials for mean DV and residuals
clear DVs
for k=n_regions:-1:1
    DVs{k} = res(k).eta;
    bad = abs(DVs{k})>10;
    DVs{k}(bad)=NaN;
    DVs_sub{k} = DV.subtract_group_mean(DVs{k},gidx);
    DVs_mn{k} = DV.replace_with_group_mean(DVs{k},gidx);    
    sub_var{k} = bootstrp(100,@(x)nanstd(x(:)),DVs_sub{k});
    mn_var{k} = bootstrp(100,@(x)nanstd(x(:)),DVs_mn{k});        
end

%% plot
regions=[res.region];
figure('position',[584 354 351 528]);hold on;

% mean DV
subplot(1,2,1);
for i=1:n_regions
    barh(i,nanmean(mn_var{i}),'facecolor',common.get_brain_region_colors(res(i).region));hold on;
end
set(gca,'ytick',1:numel(regions),'yticklabel',regions,'xlim',[0 3],'xtick',[0 2],'xgrid','on','YDir','reverse');
common.color_tick_labels;
set(gca,'tickdir','out','box','off');
set(gcf,'renderer','painters')
text(-0.2,-1,'Mean DV');
text(2,20,'S.D. across trials');

% DV residuals
subplot(1,2,2);
for i=1:n_regions
    barh(i,nanmean(sub_var{i}),'facecolor',common.get_brain_region_colors(res(i).region));hold on;
end
set(gca,'ytick',1:numel(regions),'yticklabel',regions,'xlim',[0 3],'xtick',[0 2],'xgrid','on','ydir','reverse');
common.color_tick_labels;
set(gca,'tickdir','out','box','off');
set(gcf,'renderer','painters')
text(-0.2,-1,'DV residuals');

%% save output
common.savefig(gcf,mfilename);

