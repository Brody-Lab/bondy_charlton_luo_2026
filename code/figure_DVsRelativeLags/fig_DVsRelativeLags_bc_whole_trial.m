
time_lim_s = [0.2 Inf];
max_lag=0.3;
% res_hemi = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true,'frozen',false);
% sessions = uberphys.load_bcl_sessions_table;
% res_hemi=res_hemi(logical(sessions.frozen));
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',false,'frozen',false);
sessions = uberphys.load_bcl_sessions_table;
res=res(logical(sessions.frozen));
[~,corrs] = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'time_lim_s',time_lim_s);

path=fileparts(which(mfilename));

figure;plot_example_xcorr(corrs,max_lag,"M1");
common.savefig(gcf,fullfile(path,'fig_DVsRelativeLags_b_whole_trial'));

figure('units','pixels','position',[1001 500 562 864]);
[lags_sort_idx,mns_lags,sds_lags]=plot_xcorrs(corrs,max_lag);
common.savefig(gcf,fullfile(path,'fig_DVsRelativeLags_c_whole_trial'));




