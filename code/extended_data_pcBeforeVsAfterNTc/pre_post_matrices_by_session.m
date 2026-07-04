%proper way of doing it, static decoder

field = 'corrected';
ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
sessions = DV.get_sessions();
recording_ids = sessions.recording_id(sessions.perceptual==true);
recording_ids = strrep(recording_ids,'_','-');

%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice');

corr_fun  = @(time_lim_s)DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds','nresamples',50,...
    'ref_event','committime_s_M1','correct_first',false,'correction_type','shuffle','time_lim_s',time_lim_s);

%%[combined,corrs] = corr_fun([-Inf Inf]);
%[combined_pre,corrs_pre] = corr_fun([-Inf -0.25]);
%[combined_post,corrs_post] = corr_fun([0 Inf]);

for i=1:5

corrs_pre(i).(field) = SetDiag(corrs_pre(i).(field),NaN);
corrs_pre_hemi(i) = DV.combine_corrs_across_hemi(corrs_pre(i));
[mtx_pre_hemi,labels_pre_hemi] = DV.get_corr_mtx(corrs_pre_hemi(i),'field',field,'enforce_bilateral',true);

corrs_post(i).(field) = SetDiag(corrs_post(i).(field),NaN);
corrs_post_hemi(i) = DV.combine_corrs_across_hemi(corrs_post(i));
[mtx_post_hemi,labels_post_hemi] = DV.get_corr_mtx(corrs_post_hemi(i),'field',field,'enforce_bilateral',true);


DV.plot_two_corr_mtx(mtx_pre_hemi,mtx_post_hemi,labels_pre_hemi,labels_post_hemi,'titles',{'before commitment','after commitment'});
set(gcf,'position',[110   482   799   456]);
for k=1:numel(ext)
    saveas(gcf,fullfile(path,[field,sprintf('pre_post_mtx_%s.',recording_ids(i)),ext{k}]));
end

% figure('position',[1000         672         464         370]);
% colors=parula(3);
% h(1)=DV.plot_corr_timecourse(combined,'field',[field,'_timecourse'],'new_fig',false);
% h(1)=DV.plot_corr_timecourse(combined,'regions',["ADS" "M1" "dmFC" ],'field',[field,'_timecourse'],'new_fig',false,'color',colors(3,:));
% h(2)=DV.plot_corr_timecourse(combined,'regions',["mPFC" "S1" "TS"],'field',[field,'_timecourse'],'color',colors(2,:),'new_fig',false);
% h(3)=DV.plot_corr_timecourse(combined,'regions',["NAc" "BLA" "MGB" "HPC"],'field',[field,'_timecourse'],'color',colors(1,:),'new_fig',false);
% h(1).mainLine.LineWidth=2;
% h(2).mainLine.LineWidth=2;
% h(3).mainLine.LineWidth=2;
% 
% legend([h.mainLine],["dmFC, M1, ADS" ,"mPFC, S1, TS", "NAc, MGB, HPC, BLA"])
% set(gca,'xlim',[-0.5 0.4],'ylim',[-0.0 0.3]);
% for i=1:numel(ext)
%     %saveas(gcf,fullfile(path,[field,'_timecourse.',ext{i}]));
% end


end