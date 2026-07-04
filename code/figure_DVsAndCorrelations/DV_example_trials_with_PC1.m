% 
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true);
pca_res=DV.get_dv_pcs(res,'control_fields',{'seed','pokedR'},'kfold',1,'scale',false);
clear DVs DVs_corrected gidx
for i=1:numel(res)

    %% reformat res structs
    res{i} = res{i}{1};
     n_regions = numel(res{i});        
    res{i}(1).Trials = uberphys.add_Tc_to_Trials(res{i}(1).Trials);    
    for k=n_regions:-1:1
        res{i}(k).DV = res{i}(k).log_odds;
    end
    %res{i} = DV.equalize_trials(res{i},0.7); % only needed for legacy res

    [~,gidx{i},missing_trials] = DV.find_matched_trials(res{i}(1).Trials,{'seed','pokedR'}); 
    res{i} = DV.remove_trials_from_res(res{i},missing_trials);        

    %% subtract groups means
    for k=n_regions:-1:1
        DVs{i}(:,:,k) = res{i}(k).DV;         
    end        
end
colors=uberphys.get_brain_region_colors([res{1}.region]);
sess=1;
rs=flip([[7 16 3 11 1 9 14 8 17 6 15 4 12 5 13 2 10]]);
n_regions=numel(rs);

% predicted DV residuals from PC1
DV_pred = tensorprod(pca_res.score{1}(:,:,1),(pca_res.coeff{1}(:,1))',3,1);
rs_pred=[19    20    17    18    15    16    13    14     9 10 7 5 6 3 4 1 2];
colors_pred=uberphys.get_brain_region_colors(pca_res.region{1});

seed=83;
% matched trials
%seed=58; % 35 13 28 40 48 57  64 69 is best yet (28 is what was used in
%the in house talk)
trials = find(gidx{sess}==seed);
mean_dvs = squeeze(nanmean(DVs{1}(trials,:,rs)));
mean_dvs_pred = squeeze(nanmean(DV_pred(trials,:,rs_pred)));

%trials=trials([ 7 8 10 13 14]);% 57
%trials = trials([13 17 14 15 16]); 69
%trials=trials([6 9 13 14]); 35
trials=trials([6 7 11 12 13]);
nt=numel(trials);
factor=4
xlim=0.65;
figure;
set(gcf,'position',[600 437 671 700]);
good=1:12;
for i=0:nt
    subplot(1,nt+1,i+1);

    if i==0
        h=plot(res{1}(1).bin_params.time_s(good),[0:n_regions-1]*factor + mean_dvs(good,:),'LineWidth',2);
        set(gca,'ylim',[-4 75],'xlim',[0  xlim]);hold on;
        g=plot(res{1}(1).bin_params.time_s,repmat([0:n_regions-1]'*factor,1,numel(res{1}(1).bin_params.time_s)),'k:');
        for k=1:n_regions
            h(k).Color = colors(rs(k),:);        
            g(k).Color = colors(rs(k),:);        
        end
        for n=1:n_regions
            %text(-0.3,(n-1)*factor,labels(rs(n)),'color',colors(rs(n),:),'HorizontalAlignment','center','VerticalAlignment','middle');
        end
    axis off
        
        continue
    end
    i
    rbups=res{1}(1).Trials.rightBups{trials(i)};
    res{1}(1).Trials.seed(trials)
    rbups=rbups-rbups(1);
    lbups=res{1}(1).Trials.leftBups{trials(i)};
    lbups=lbups-lbups(1);        
    scatter(rbups,(n_regions+1)*factor,'|k')   ; hold on
    scatter(lbups,(n_regions+1)*factor-1.5,'|k')   ;         
    %stimdur = res{1}(1).Trials.stateTimes.cpoke_out(trials(i)) - res{1}(1).Trials.stateTimes.first_click(trials(i));
    %good = res{1}(1).bin_params.time_s<stimdur;
    h=plot(res{1}(1).bin_params.time_s(good),[0:n_regions-1]*factor + squeeze(DVs{1}(trials(i),good,rs)) - mean_dvs(good,:),'LineWidth',2);
    h2=plot(res{1}(1).bin_params.time_s(good),[0:n_regions-1]*factor + squeeze(DV_pred(trials(i),good,rs_pred)) - mean_dvs_pred(good,:),'LineWidth',2);        

    set(gca,'ylim',[-4 75],'xlim',[0  xlim]);hold on;
    g=plot(res{1}(1).bin_params.time_s,repmat([0:n_regions-1]'*factor,1,numel(res{1}(1).bin_params.time_s)),'k:');
    for k=1:n_regions
        h(k).Color = colors(rs(k),:);        
        g(k).Color = colors(rs(k),:);        
        h2(k).Color = colors_pred(rs_pred(k),:);
        h(k).LineWidth=1;
    end
    axis off
    
end

% real seed for 69 is 4001501004, went right

% real seed for 83 is 4003501005, went right