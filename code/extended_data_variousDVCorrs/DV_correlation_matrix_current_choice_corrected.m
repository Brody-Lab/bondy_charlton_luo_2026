%proper way of doing it, static decoder

field = 'corrected';
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));


%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice');

corr_fun  = @(time_lim_s)DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds','nresamples',50,...
    'ref_event','committime_s_M1','correct_first',false,'correction_type','shuffle','time_lim_s',time_lim_s);

%combined = corr_fun([-Inf Inf]);
%combined_pre = corr_fun([-Inf -0.25]);

combined_pre.(field) = SetDiag(combined_pre.(field),NaN);
combined_pre_hemi = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre_hemi,labels_pre_hemi] = DV.get_corr_mtx(combined_pre_hemi,'field',field,'order_by_hemi',true);


DV.plot_one_corr_mtx(mtx_pre_hemi,labels_pre_hemi,'clim',[0 0.35]);
set(gcf,'position',[110   482   799   456]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[field,[mfilename,'.'],ext{i}]));
end
