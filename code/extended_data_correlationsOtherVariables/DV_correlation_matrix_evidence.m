% plot the across-region correlation matrix of DVs (i.e. log-odds of
% current choice given neural activity), corrected for stimulus seed and
% choice.

% only pre-commitment timepoints are included

field = 'corrected';
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
control_fields={'seed','pokedR'};
approach = 'shuffle';
nresamples=50;
res = DV.load_DVs('fit_mode',"",'fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'by_hemisphere',true,'variable','evidence','resolution_s',0.1);
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
        % if res{1}(1).params.ref_event~="commitment_s"
        %     t0=res{i}(1).Trials.stateTimes.commitment_s - res{i}(1).Trials.stateTimes.(res{1}(1).params.ref_event);      
        %     clear DVs DVs_shuffled
        %     for k=numel(res{i}):-1:1
        %         [DVs{k},time_s] = DV.realign_DVs(res{i}(k).DV,res{i}(k).bin_params.time_s,t0);
        %     end
        % else
            % or don't realign
            time_s = res{i}(1).bin_params.time_s;
            clear DVs DVs_shuffled        
            for k=numel(res{i}):-1:1
                DVs{k} = res{i}(k).DV;
            end        
        % end
        
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
        c = DV.DV_correlation_new(DVs,time_s,'time_lim_s',[-Inf Inf],args{:});
        corrs(i) = DV.add_identifiers_to_corrs(c,res{i});

end


combined = DV.combine_corrs(corrs);
combined.(field) = SetDiag(combined.(field),NaN);
combined_hemi = DV.combine_corrs_across_hemi(combined);
[mtx,labels] = DV.get_corr_mtx(combined,'field',field);
[mtx_hemi,labels_hemi] = DV.get_corr_mtx(combined_hemi,'field',field);
mtx = SetDiag(mtx,NaN);
mat = SetDiag(nearestSPD(SetDiag(mtx_hemi,1)),1);mat(mat>1)=1;mat=1-mat;figure;mds_coord=cmdscale(mat,1);

[~,idx_hemi] = sort(mds_coord);
%idx = ones(size(mtx,1),1);
%idx(1:2:end) = idx_hemi*2-1;
%idx(2:2:end) = idx_hemi*2;
%DV.plot_one_corr_mtx(mtx(idx,idx),labels(idx),'clim',prctile(mtx(:),[1 99]));

g=DV.plot_one_corr_mtx(mtx_hemi,labels_hemi,'clim',prctile(mtx_hemi(:),[1 99]));
set(gcf,'position',[219   270   615   464]);
g.Position=[0.8253    0.1112    0.0412    0.3000];
g.Label.Position =[1.4891 0.33 0];
set(gca,'clim',[0 0.25]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[mfilename,'.',ext{i}]));
end

figure;
plot(mds_coord(:,end),'.k','MarkerSize',30);
set(gca,'xtick',1:numel(mds_coord),'xticklabel',labels_hemi,'tickdir','out','ytick',[]);
box off;
uberphys.color_tick_labels();
ylabel('MDS Coordinate');set(gcf,'position',[284   684   417   283]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[mfilename,'_mds.',ext{i}]));
end


