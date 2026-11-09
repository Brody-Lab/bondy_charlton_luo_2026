res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',true);
regions=DV.get_brain_regions;
ntcs=cell(numel(regions),1);
for i=1:numel(res)

    %% reformat res structs
    %res{i} = res{i}{1};
    these_regions = unique([res{i}.region]);
    %res{i}(1).Trials = uberphys.add_Tc_to_Trials(res{i}(1).Trials);      
    for r=1:numel(regions)
        if ismember(regions(r),these_regions)
            ntcs{r}{i} = double(~isnan(res{i}(1).Trials.stateTimes.(sprintf('committime_s_%s',regions(r)))));
        end
    end

end

clear n
for i=1:numel(regions)
    empty = cellfun(@isempty,ntcs{i});
    boots{i} = hierarchical_bootstrp(200,@nanmean,ntcs{i}(~empty));
    n(i)=nanmean(boots{i});
    sd(i) = nanstd(boots{i});
end

[~,idx] = sort(n,'descend');
figure;bar(1:10,n(idx));set(gca,'xtick',[1:10],'xticklabels',regions(idx));hold on
errorbar(1:10,n(idx),sd(idx));set(gca,'xtick',[1:10],'xticklabels',regions(idx));
uberphys.color_tick_labels;
box off;
ylabel('Fraction of trials with nTc');
xlabel('Brain region used');
