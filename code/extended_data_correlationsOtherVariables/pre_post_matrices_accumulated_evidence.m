%proper way of doing it, static decoder

field = 'corrected';
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
control_fields={'seed','pokedR'};
approach = 'shuffle';
nresamples=50;
%ref_event="commitment_s";
ref_event="commitment_s";

res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','accumulated_evidence','resolution_s',0.1);
clear corrs corrs_pre corrs_post
for i=1:numel(res)

        for k=numel(res{i}):-1:1
            res{i}(k).DV = res{i}(k).log_odds;
        end
    
        res{i} = DV.equalize_trials(res{i},0.7);

        if ref_event=="shuffled_commitment_s"
            res{i}(1).Trials = uberphys.shuffle_commitment_times(res{i}(1).Trials);
        end
            %% remove all uncommitted and unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.commitment_s);
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);
        [match_idx,gidx,missing_trials] = DV.find_matched_trials(res{i}(1).Trials,control_fields,'n_resamples',nresamples); 
        res{i} = DV.remove_trials_from_res(res{i},missing_trials);        
        
        %% realign to commitment time if necessary
        if res{1}(1).params.ref_event~=ref_event
            t0=res{i}(1).Trials.stateTimes.(ref_event)- res{i}(1).Trials.stateTimes.(res{1}(1).params.ref_event);      
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
        cpre = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf 0],args{:});
        cpost = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[0 Inf],args{:});
        c = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf Inf],args{:});

        corrs(i) = DV.add_identifiers_to_corrs(c,res{i});
        corrs_pre(i) = DV.add_identifiers_to_corrs(cpre,res{i});
        corrs_post(i) = DV.add_identifiers_to_corrs(cpost,res{i});        
 
end


combined_pre = DV.combine_corrs(corrs_pre);
combined_pre.(field) = SetDiag(combined_pre.(field),NaN);
combined_pre_hemi = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre_hemi,labels_pre_hemi] = DV.get_corr_mtx(combined_pre_hemi,'field',field);

combined_post = DV.combine_corrs(corrs_post);
combined_post.(field) = SetDiag(combined_post.(field),NaN);
combined_post_hemi = DV.combine_corrs_across_hemi(combined_post);
[mtx_post_hemi,labels_post_hemi] = DV.get_corr_mtx(combined_post_hemi,'field',field);

combined = DV.combine_corrs(corrs);
combined.(field) = SetDiag(combined.(field),NaN);
combined_hemi = DV.combine_corrs_across_hemi(combined);

DV.plot_two_corr_mtx(mtx_pre_hemi,mtx_post_hemi,labels_pre_hemi,labels_post_hemi,'titles',{'before commitment','after commitment'},'clim',[0 0.25]);
set(gcf,'position',[110   482   799   456]);
for i=1:numel(ext)
    %saveas(gcf,fullfile(path,[field,'pre_post_mtx.',ext{i}]));
end
figure('position',[869   715   589   400]);
subplot(1,2,1);
field='corr';
DV.plot_corr_timecourse(combined_hemi,'regions',["ADS" "M1" "dmFC" ],'field',[field,'_timecourse'],'color',[1 1 0],'new_fig',false);
%DV.plot_corr_timecourse(combined,'regions',["mPFC" "TS" "BLA" "MGB" "NAc" "HPC"],'field',[field,'_timecourse'],'new_fig',false);
field='correction_factor';
DV.plot_corr_timecourse(combined_hemi,'regions',["ADS" "M1" "dmFC" ],'field',[field,'_timecourse'],'color',[1 1 0],'new_fig',false);
%DV.plot_corr_timecourse(combined,'regions',["mPFC" "TS" "BLA" "MGB" "NAc" "HPC"],'field',[field,'_timecourse'],'new_fig',false);
% 
figure('position',[1000         672         464         370]);
field='corrected';
colors=parula(3);
h(1)=DV.plot_corr_timecourse(combined,'regions',["ADS" "M1" "dmFC" ],'field',[field,'_timecourse'],'new_fig',false,'color',colors(3,:));
h(2)=DV.plot_corr_timecourse(combined,'regions',["mPFC" "S1" "TS"],'field',[field,'_timecourse'],'color',colors(2,:),'new_fig',false);
h(3)=DV.plot_corr_timecourse(combined,'regions',["NAc" "BLA" "MGB" "HPC"],'field',[field,'_timecourse'],'color',colors(1,:),'new_fig',false);
h(1).mainLine.LineWidth=2;
h(2).mainLine.LineWidth=2;
h(3).mainLine.LineWidth=2;
%h(2).mainLine.Color=[0.7 0.7 0.7];
%h(1).patch.FaceColor=[0.5 0.5 0.5];
legend([h.mainLine],["dmFC, M1, ADS" ,"mPFC, S1, TS", "NAc, MGB, HPC, BLA"])
set(gca,'xlim',[-0.55 0.55],'ylim',[-0.0 0.4]);
for i=1:numel(ext)
    %saveas(gcf,fullfile(path,[field,'_timecourse.',ext{i}]));
end

