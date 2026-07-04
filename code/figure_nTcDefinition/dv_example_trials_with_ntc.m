% 
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','committime_s_M1','variable','choice','by_hemisphere',false);
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
        tmp = DV.subtract_group_mean(res{i}(k).DV,gidx{i});
        tmp2 = res{i}(k).DV;
        DVs_corrected{i}(:,:,k) = tmp; 
        DVs{i}(:,:,k) = tmp2;         
    end        
end
sess=5;
logistic= @(x) (1./(1+exp(-x)));

ntc=0;
colors=uberphys.get_brain_region_colors([res{sess}.region]);


[~,idx] = ismember([res{5}.region]',DV.get_brain_regions);
[~,idx] = sort(idx);
rs=flip(idx);
n_regions=numel(rs);


regions=[res{5}.region]
seed=33;
trials = find(gidx{sess}==seed);

nt=numel(trials);
factor=3
xlim=1;
figure;
set(gcf,'position',[600 437 671 700]);
good=1:24;
for i=1:nt
    subplot(1,nt,i);

    rbups=res{sess}(1).Trials.rightBups{trials(i)};
    rbups=rbups-rbups(1);
    lbups=res{sess}(1).Trials.leftBups{trials(i)};
    lbups=lbups-lbups(1);        
    scatter(rbups,(n_regions+1)*factor,'|k')   ; hold on
    scatter(lbups,(n_regions+1)*factor-1.5,'|k')   ;         
    %stimdur = res{sess}(1).Trials.stateTimes.cpoke_out(trials(i)) - res{sess}(1).Trials.stateTimes.first_click(trials(i));
    %good = res{sess}(1).bin_params.time_s<stimdur;
    h=plot(res{sess}(1).bin_params.time_s(good),[0:n_regions-1]*factor +logistic(squeeze(DVs{sess}(trials(i),good,rs)) ),'LineWidth',2);
    set(gca,'ylim',[-4 45],'xlim',[- 1 1]);hold on;
    g=plot(res{sess}(1).bin_params.time_s,repmat([0:n_regions-1]'*factor,1,numel(res{sess}(1).bin_params.time_s)),'k:');

    for k=1:n_regions
        h(k).Color = colors(rs(k),:);        
        g(k).Color = colors(rs(k),:);       
        if i==1
            text(-1,k*factor-3,regions(rs(k)),'color',colors(rs(k),:));
        end

    end
    axis off
    line([0 0],get(gca,'ylim'));
end

% real seed for 69 is 4001501004, went right