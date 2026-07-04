
time_lim_s = [-Inf 0];
max_lag=0.3;
ref_event = "committime_s_all";
sessions = uberphys.load_bcl_sessions_table;
rats=unique(sessions.rat);
rat_list=sessions(logical(sessions.frozen),:).rat;
% res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',false,'frozen',false);
% res=res(logical(sessions.frozen));
% [~,corrs] = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'time_lim_s',time_lim_s,'ref_event',ref_event);

path=fileparts(which(mfilename));

[lags_sort_idx,mns_avg,sds_avg]  =    plot_xcorrs(corrs,max_lag);

clear mns sds
for i=1:numel(rats)
    figure('units','pixels','position',[1001 500 562 864]);
    [lags_sort_idx,mns{i},sds{i}] = plot_xcorrs(corrs(rat_list==rats(i)),max_lag,lags_sort_idx);
    common.savefig(gcf,fullfile(path,['fig_DVsRelativeLags_c_ed_',char(rats(i))]));
end



all_corrs=cat(1,mns{:})';
figure;imagesc(corr(all_corrs,'r','p'));set(gca,'clim',[0 1]);
corr(all_corrs,'r','p');
box off;set(gca,'xtick',[1 2 3],'ytick',[1 2 3],'yticklabel',rats,'xticklabel',rats);colorbar;
common.savefig(gcf,fullfile(path,'fig_DVsRelativeLags_ed_subject_correlation'));
