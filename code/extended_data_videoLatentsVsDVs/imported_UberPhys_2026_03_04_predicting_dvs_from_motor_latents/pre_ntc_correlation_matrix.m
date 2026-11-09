%load('C:\github\UberPhys\adrian\analysis\2026_03_04_predicting_dvs_from_motor_latents\dv_residual_predictions_by_hemi.mat')

ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));

%  add Y and  Yhat
for  i=1:length(res)
    for r=1:length(res{i})
        res{i}(r).Y=[res{i}(r).fit.Y];
        res{i}(r).resid=[res{i}(r).fit.Y] - [res{i}(r).fit.Y_hat];
    end
end        

combined_pre = DV.corrs_from_res(res,'control_for',{},'field','Y','nresamples',50,'correction_type','mean_subtract','ref_event','committime_s_M1','correct_first',true,'time_lim_s',[-Inf -0.25]);
combined_pre.corr = SetDiag(combined_pre.corr,NaN);
combined_pre = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre,labels_pre] = DV.get_corr_mtx(combined_pre,'field','corr');

x=combined_pre.corr;
x_err = combined_pre.se.corr;


combined_pre = DV.corrs_from_res(res,'control_for',{},'field','resid','nresamples',50,'correction_type','mean_subtract','ref_event','committime_s_M1','correct_first',true,'time_lim_s',[-Inf -0.25]);
combined_pre.corr = SetDiag(combined_pre.corr,NaN);
combined_pre = DV.combine_corrs_across_hemi(combined_pre);
[mtx_pre_pred,labels_pre] = DV.get_corr_mtx(combined_pre,'field','corr');

y=combined_pre.corr;
y_err = combined_pre.se.corr;

DV.plot_two_corr_mtx(mtx_pre,mtx_pre_pred,labels_pre,labels_pre,'titles',{'w/ video latent component','w/o video latent component'},'clim',[0 0.35]);
set(gcf,'position',[110   482   799   456]);
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['corr_mtx_before_and_after_video_correction.',ext{i}]));
end

figure;errorbar(x,y,y_err,y_err,x_err,x_err,'Marker','.','MarkerSize',20,'LineStyle','none','color','k','CapSize',eps,'LineWidth',1);
h=refline(1,0);
h.Color='k';
xlabel('DV residual correlation');
ylabel({'DV residual correlation','minus video prediction'});
axis square
set(gca,'xlim',[-0.1 0.4]);set(gca,'ylim',[-0.1 0.4]);
box off;
yl=ylim;
xl=xlim;
h=line([0 0],yl);
h.Color='k';
h=line(xl,[ 0 0]);
h.Color='k';
text(0.1,0.35,sprintf('r = %0.2g',corr(x(:),y(:))),'FontAngle','italic');
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['scatter plot before after.',ext{i}]));
end
