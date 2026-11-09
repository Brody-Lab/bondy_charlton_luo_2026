% 
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true);
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
      
end
figure;
all_regions = DV.get_brain_regions;

for k=1:5
sess=k;
clear ntcs
regions=unique([res{sess}.region]);
for r=1:numel(regions)

    ntcs(:,r)=res{sess}(1).Trials.stateTimes.(sprintf("committime_s_%s",regions(r))) - res{sess}(1).Trials.stateTimes.first_click;
end
ngroup = max(gidx{sess});

ntcs = DV.subtract_group_mean(ntcs,gidx{sess},'exclude_self',true);

ntc_corr{k} = corr(ntcs,'r','p');
ntc_corr{k} = SetDiag(ntc_corr{k},NaN);
%[a,b,c] = ppca(ntcs,size(ntcs,2));
%[a,b,c2] = pca(ntcs,'algorithm','als');
%subplot(1,5,k);h(1)=plot(c./sum(c));hold on;h(2)=plot(c2./sum(c2));
if k==1
    %legend(h,{'ppca','pca with als'});
    %ylabel('Frac. Var. Explained');
end
%title(sprintf('session %d',k));
%box off
%xlabel('No. PCs');
[idx,~] = find(all_regions==regions');
idx2=find(ismember(all_regions,regions));
all_corrs{k} = NaN(10);
all_corrs{k}(idx2,idx2) = ntc_corr{k}(idx,idx);
subplot(1,5,k);DV.plot_one_corr_mtx(ntc_corr{k},regions,'clim',[-0.3 0.5],'same_fig',true);


end

colors=uberphys.get_brain_region_colors([res{sess}.region]);
rs=flip([[7 16 3 11 1 9 14 8 17 6 15 4 12 5 13 2 10]]);
%rs=flip([3 4 1 2 5 6 9 7 8 10 11 14 15 12 13 16 17]);
n_regions=numel(rs);

trials = [91:100];

trials = [38 53 56 64 67 75 81 87];
regions=[res{1}.region]
seed=83;
trials = find(gidx{sess}==seed);
trials=trials([5 6  11 12 13]);