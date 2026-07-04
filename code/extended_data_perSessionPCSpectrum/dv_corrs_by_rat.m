% figre 2 matrix (all timepoints, both with and without combining across hgemisphres)

%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'alpha',0.95,'frozen',false,'ref_event',ref_event,'by_hemisphere',true,'causal',false,'by_region',true);
%res=res(sessions.frozen==1);

sessions = uberphys.load_bcl_sessions_table;


rat="A324";
idx = sessions.rat(sessions.frozen==1)==rat;

combined = DV.corrs_from_res(res(idx),'control_for',{'seed','pokedR'},'field','log_odds_same_lambda','nresamples',50,'correction_type','mean_subtract');
combined.corr = SetDiag(combined.corr,NaN);
[mtx,labels] = DV.get_corr_mtx(combined,'field','corr');


figure;
subplot(1,2,1);
DV.plot_one_corr_mtx(mtx,labels,'clim',[0 0.35],'same_fig',true);
set(gcf,'position',[110   482   799   456]);



combined_hemi = DV.combine_corrs_across_hemi(combined);
[mtx,labels] = DV.get_corr_mtx(combined_hemi,'field','corr');

subplot(1,2,2);
DV.plot_one_corr_mtx(mtx,labels,'clim',[0 0.35],'same_fig',true);
set(gcf,'position',[110         478        1262         460]);


ext={'pdf','png','fig'};
path=fileparts(which(mfilename));


set(gcf,'renderer','painters')
for i=1:numel(ext)
    saveas(gcf,fullfile(path,strjoin(['dv_corr_matrix_',rat,'.',ext{i}],"")));
end
