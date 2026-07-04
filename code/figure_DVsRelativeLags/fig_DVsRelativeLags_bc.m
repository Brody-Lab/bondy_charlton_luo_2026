
time_lim_s = [-Inf 0];
max_lag=0.3;
 % res2 = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true,'frozen',false);
 % sessions = uberphys.load_bcl_sessions_table;
 % res2=res2(logical(sessions.frozen));

%clear corrs lags_sort_idx mns_lags sds_lags
for i=394:500
    for s=1:numel(res2)
        [match_idx,gidx,missing_trials] = DV.find_matched_trials(res2{s}{1}(1).Trials,{'seed','pokedR'},'n_resamples',3); 
        res2{s}{1} = DV.remove_trials_from_res(res2{s}{1},missing_trials);  
        if i==1
            res_resamp{s}{1} = res2{s}{1};
        else        
            nt=numel(res2{s}{1}(1).Y);
            res_resamp{s}{1} = keep_trials_from_res(res2{s}{1},nt,randsample(nt,nt,true));
        end
        for k=1:numel(res_resamp{s}{1})
            %res_resamp{s}{1}(k).log_odds_same_lambda(:,1)=NaN;
        end
    end
[~,corrs{i}] = DV.corrs_from_res(res_resamp,'control_for',{'seed','pokedR'},'time_lim_s',time_lim_s,'ref_event','committime_s_all');

% path=fileparts(which(mfilename));
% 
% figure;plot_example_xcorr(corrs,max_lag,"ADS");
% set(gca,'xlim',[-0.5 0.5]);
% common.savefig(gcf,fullfile(path,'fig_DVsRelativeLags_b'));

%figure('units','pixels','position',[1001 500 562 864]);
[lags_sort_idx{i},mns_lags{i},sds_lags{i}]=plot_xcorrs(corrs{i},max_lag);
end
%common.savefig(gcf,fullfile(path,'fig_DVsRelativeLags_c'));
sds_lags_resamp = std(cat(1,mns_lags{2:end}));
mns_lags_resamp = mns_lags{1};

function res = keep_trials_from_res(res,sz,keep)  
    if isscalar(res)
        fields=fieldnames(res);
        for f=1:numel(fields)
            if size(res.(fields{f}),1)==sz
                res.(fields{f}) = res.(fields{f})(keep,:);
            end
        end
        if isfield(res,'Trials')
            res.Trials = keep_trials(res.Trials,sz,keep);
        end
    else
        for i=1:numel(res)
            res(i) = keep_trials_from_res(res(i),sz,keep); 
        end
    end
end

function Trials = keep_trials(Trials,nt,keep)
    fields = string(fieldnames(Trials));
    for f = fields(:)'
        if numel(Trials.(f))==nt
            if istable(Trials.(f))
                Trials.(f) = Trials.(f)(keep,:);                
            else
                Trials.(f) = Trials.(f)(keep);
            end
        elseif any(strcmp({'pharma','laser','stateTimes'},f))
            Trials.(f) = keep_trials(Trials.(f),nt,keep);
        end
    end
end
