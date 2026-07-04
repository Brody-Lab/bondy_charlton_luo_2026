
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
field='corrected';
%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true);
combined_pre = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds','nresamples',50,'correction_type','shuffle','ref_event','committime_s_M1','correct_first',true,'time_lim_s',[-Inf -0.25]);
combined_post = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds','nresamples',50,'correction_type','shuffle','ref_event','committime_s_M1','correct_first',true,'time_lim_s',[0 Inf]);

%combined_pre.(field) = corr2cov(combined_pre.std,combined_pre.(field));
combined_pre.(field) = SetDiag(combined_pre.(field),NaN);
combined_pre_hemi = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre_hemi,labels_pre_hemi] = DV.get_corr_mtx(combined_pre_hemi,'field',field);

%combined_post.(field) = corr2cov(combined_post.std,combined_post.(field));
combined_post.(field) = SetDiag(combined_post.(field),NaN);
combined_post_hemi = DV.combine_corrs_across_hemi(combined_post);
[mtx_post_hemi,labels_post_hemi] = DV.get_corr_mtx(combined_post_hemi,'field',field);



DV.plot_two_corr_mtx(mtx_pre_hemi,mtx_post_hemi,labels_pre_hemi,labels_post_hemi,'titles',{'before commitment','after commitment'},'clim',[0 0.32]);
set(gcf,'position',[110   482   799   456]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[field,'pre_post_mtx.',ext{i}]));
end
