%proper way of doing it, static decoder

field = 'corrected';
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));


res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','firing_rate');

corr_fun  = @(time_lim_s)DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','DV','nresamples',50,...
    'ref_event','committime_s_M1','correct_first',false,'correction_type','shuffle','time_lim_s',time_lim_s);

combined = corr_fun([-Inf Inf]);
combined_pre = corr_fun([-Inf -0.25]);
combined_post = corr_fun([0 Inf]);

combined_pre.(field) = SetDiag(combined_pre.(field),NaN);
combined_pre_hemi = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre_hemi,labels_pre_hemi] = DV.get_corr_mtx(combined_pre_hemi,'field',field);

combined_post.(field) = SetDiag(combined_post.(field),NaN);
combined_post_hemi = DV.combine_corrs_across_hemi(combined_post);
[mtx_post_hemi,labels_post_hemi] = DV.get_corr_mtx(combined_post_hemi,'field',field);


DV.plot_two_corr_mtx(mtx_pre_hemi,mtx_post_hemi,labels_pre_hemi,labels_post_hemi,'titles',{'before commitment','after commitment'},'clim',[0 0.35]);
set(gcf,'position',[110   482   799   456]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[field,'pre_post_mtx_fr.',ext{i}]));
end

figure('position',[1000         672         464         370]);
field='corrected';
colors=parula(3);
h(1)=DV.plot_corr_timecourse(combined,'regions',["ADS" "M1" "dmFC" ],'field',[field,'_timecourse'],'new_fig',false,'color',colors(3,:));
h(2)=DV.plot_corr_timecourse(combined,'regions',["mPFC" "S1" "TS"],'field',[field,'_timecourse'],'color',colors(2,:),'new_fig',false);
h(3)=DV.plot_corr_timecourse(combined,'regions',["NAc" "BLA" "MGB" "HPC"],'field',[field,'_timecourse'],'color',colors(1,:),'new_fig',false);
h(1).mainLine.LineWidth=2;
h(2).mainLine.LineWidth=2;
h(3).mainLine.LineWidth=2;

legend([h.mainLine],["dmFC, M1, ADS" ,"mPFC, S1, TS", "NAc, MGB, HPC, BLA"])
set(gca,'xlim',[-0.7 0.5],'ylim',[-0.0 0.4]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,[field,'_timecourse_fr.',ext{i}]));
end

