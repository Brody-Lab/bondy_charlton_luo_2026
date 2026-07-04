
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
control_fields={'pokedR'};
approach = 'shuffle';
nresamples=50;
res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',true);
clear corrs
for i=1:numel(res)

        for k=numel(res{i}):-1:1
            res{i}(k).DV = res{i}(k).log_odds;
        end

        res{i} = DV.equalize_trials(res{i},0.7);

        %% remove all uncommitted or unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.commitment_s);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);
        [match_idx,gidx,missing_trials] = DV.find_matched_trials(res{i}(1).Trials,control_fields,'n_resamples',nresamples); 
        res{i} = DV.remove_trials_from_res(res{i},missing_trials);        

        %% realign to commitment time if necessary
        if res{1}(1).params.ref_event~="commitment_s"
            t0=res{i}(1).Trials.stateTimes.commitment_s - res{i}(1).Trials.stateTimes.(res{1}(1).params.ref_event);      
            clear DVs DVs_shuffled
            for k=numel(res{i}):-1:1
                [DVs{k},time_s] = DV.realign_DVs(res{i}(k).DV,res{i}(k).bin_params.time_s,t0);
            end
        else
            % or don't realign
            time_s = res{i}(1).bin_params.time_s;
            clear DVs DVs_shuffled        
            for k=numel(res{i}):-1:1
                DVs{k} = res{i}(k).DV;
            end        
        end

        switch approach
            case 'mean_subtract'
                % subtract group means
                for k=numel(res{i}):-1:1
                    DVs{k} = DV.subtract_group_mean(DVs{k},gidx);
                end
                args={};
            case 'shuffle'
                % calculate shuffled DVs
                for k=numel(res{i}):-1:1
                    DVs_shuffled{k} = DV.get_shuffled_DVs(DVs{k},match_idx);
                end
                args={'DVs_shuffled',DVs_shuffled};
        end

        %% calculate correlations   
        c = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf 0],args{:});
        corrs(i) = DV.add_identifiers_to_corrs(c,res{i});

end


combined_choice_only = DV.combine_corrs(corrs);




ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
control_fields={'seed'};
approach = 'shuffle';
nresamples=50;
res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',true);
clear corrs
for i=1:numel(res)

        for k=numel(res{i}):-1:1
            res{i}(k).DV = res{i}(k).log_odds;
        end

        res{i} = DV.equalize_trials(res{i},0.7);

        %% remove all uncommitted or unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.commitment_s);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);
        [match_idx,gidx,missing_trials] = DV.find_matched_trials(res{i}(1).Trials,control_fields,'n_resamples',nresamples); 
        res{i} = DV.remove_trials_from_res(res{i},missing_trials);        

        %% realign to commitment time if necessary
        if res{1}(1).params.ref_event~="commitment_s"
            t0=res{i}(1).Trials.stateTimes.commitment_s - res{i}(1).Trials.stateTimes.(res{1}(1).params.ref_event);      
            clear DVs DVs_shuffled
            for k=numel(res{i}):-1:1
                [DVs{k},time_s] = DV.realign_DVs(res{i}(k).DV,res{i}(k).bin_params.time_s,t0);
            end
        else
            % or don't realign
            time_s = res{i}(1).bin_params.time_s;
            clear DVs DVs_shuffled        
            for k=numel(res{i}):-1:1
                DVs{k} = res{i}(k).DV;
            end        
        end

        switch approach
            case 'mean_subtract'
                % subtract group means
                for k=numel(res{i}):-1:1
                    DVs{k} = DV.subtract_group_mean(DVs{k},gidx);
                end
                args={};
            case 'shuffle'
                % calculate shuffled DVs
                for k=numel(res{i}):-1:1
                    DVs_shuffled{k} = DV.get_shuffled_DVs(DVs{k},match_idx);
                end
                args={'DVs_shuffled',DVs_shuffled};
        end

        %% calculate correlations   
        c = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf 0],args{:});
        corrs(i) = DV.add_identifiers_to_corrs(c,res{i});

end


combined_seed_only = DV.combine_corrs(corrs);








control_fields={'pokedR','seed'};
approach = 'shuffle';
nresamples=50;
res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',true);
clear corrs
for i=1:numel(res)

        for k=numel(res{i}):-1:1
            res{i}(k).DV = res{i}(k).log_odds;
        end

        res{i} = DV.equalize_trials(res{i},0.7);

        %% remove all uncommitted or unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.commitment_s);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);
        [match_idx,gidx,missing_trials] = DV.find_matched_trials(res{i}(1).Trials,control_fields,'n_resamples',nresamples); 
        res{i} = DV.remove_trials_from_res(res{i},missing_trials);        

        %% realign to commitment time if necessary
        if res{1}(1).params.ref_event~="commitment_s"
            t0=res{i}(1).Trials.stateTimes.commitment_s - res{i}(1).Trials.stateTimes.(res{1}(1).params.ref_event);      
            clear DVs DVs_shuffled
            for k=numel(res{i}):-1:1
                [DVs{k},time_s] = DV.realign_DVs(res{i}(k).DV,res{i}(k).bin_params.time_s,t0);
            end
        else
            % or don't realign
            time_s = res{i}(1).bin_params.time_s;
            clear DVs DVs_shuffled        
            for k=numel(res{i}):-1:1
                DVs{k} = res{i}(k).DV;
            end        
        end

        switch approach
            case 'mean_subtract'
                % subtract group means
                for k=numel(res{i}):-1:1
                    DVs{k} = DV.subtract_group_mean(DVs{k},gidx);
                end
                args={};
            case 'shuffle'
                % calculate shuffled DVs
                for k=numel(res{i}):-1:1
                    DVs_shuffled{k} = DV.get_shuffled_DVs(DVs{k},match_idx);
                end
                args={'DVs_shuffled',DVs_shuffled};
        end

        %% calculate correlations   
        c = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf 0],args{:});
        corrs(i) = DV.add_identifiers_to_corrs(c,res{i});

end


combined = DV.combine_corrs(corrs);

raw_corrs=triu(combined.corr);
raw_corrs(raw_corrs>0.99 | raw_corrs==0)=NaN;

figure; clear g h
g(1)=scatter(raw_corrs(:),combined_seed_only.correction_factor(:),'.','SizeData',250,'CData',[1 0 0]);
r2(1)=rsquare(raw_corrs(:),combined_seed_only.correction_factor(:));
g(2)=scatter(raw_corrs(:),combined_choice_only.correction_factor(:),'.','SizeData',250,'CData',[0 1 0]);
r2(2)=rsquare(raw_corrs(:),combined_choice_only.correction_factor(:));
g(3)=scatter(raw_corrs(:),combined.correction_factor(:),'.','SizeData',250,'CData',[0 0 1]);hold on;
r2(3)=rsquare(raw_corrs(:),combined.correction_factor(:));
h=refline(1,0);
h.LineWidth=1.5;
h.LineStyle='--';
h.Color=[0 0 0];
axis square
set(gca,'xlim',[0 0.8],'ylim',[0 0.8],'tickdir','out');
xlabel('Raw DV corr.');
ylabel('DV corr. after trial shuffling');
l=legend(g,{sprintf('stimulus (R^2=%g)',round(r2(1),2)),sprintf('choice (R^2=%g)',round(r2(2),2)),"stimulus AND" + newline + "choice" + newline + string(sprintf('(R^2=%g)',round(r2(3),2)))});
l.Position=[0.2426    0.6687    0.3009    0.1833];
text(0.2587,0.796,"Shuffling preserves:",'HorizontalAlignment','center','FontSize',14.4);

for i=1:numel(ext)
    saveas(gcf,fullfile(path,['quantifying_effect_of_seed_correction','.',ext{i}]));
end