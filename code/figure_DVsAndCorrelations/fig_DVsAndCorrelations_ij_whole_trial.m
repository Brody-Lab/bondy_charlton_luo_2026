% % % 



 sessions=uberphys.load_bcl_sessions_table();

field = 'log_odds_same_lambda';
ref_event = "first_click";
time_lim_s = [0 Inf];
 res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true,'smooth_sd',0.05,'frozen',false);
 res=res(logical(sessions.frozen)); 
% res_shuffle = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true,'shuffle_cells',true,'frozen',false);
%  res_shuffle=res_shuffle(logical(sessions.frozen));
%pca_res_scaled=DV.get_dv_pcs(res,'control_fields',{'seed','pokedR'},'lim_time_s',[-Inf -0.25],'kfold',20,'scale',true,'field','log_odds');
  pca_res=DV.get_dv_pcs(res,'control_fields',{'seed','pokedR'},'lim_time_s',time_lim_s,'kfold',1,'scale',false,'field',field,'lim_event',ref_event);
   pca_res2=DV.get_dv_pcs(res,'control_fields',{'seed','pokedR'},'lim_time_s',time_lim_s,'kfold',1,'scale',false,'n_resample_groups',2,'field',field,'lim_event',ref_event);
  pca_res_shuffle=DV.get_dv_pcs(res_shuffle,'control_fields',{'seed','pokedR'},'lim_time_s',time_lim_s,'kfold',1,'scale',false,'field',field,'lim_event',ref_event);
% % 

figure('position',[1000         976        1264         263]);
% subplot(1,3,2);
% nboot=100;
% clear boots x
% yl=5;
% for k=1:numel(pca_res.cross_val_err{1})
%     rng(1);    
%     for i=1:numel(pca_res.cross_val_err)
%         x{i} = pca_res.cross_val_err{i}{k};
%         x{i} = bootstrp(nboot,@(x)nanmean(x(:).^2),x{i});  
%     end
%     rng(1);
%     boots(:,k) = hierarchical_bootstrp(nboot,@(x)nanmean(x),x,true);
% end
% boots=boots./boots(:,1);
% %boots(boots>yl)=yl;
% mn=mean(boots);
% sd=std(boots);
% clear h
% h(1)=errorbar(0:3,mn./mn(1),sd./mn(1),'color',[0 0 0]);
% set(gca,'xgrid','on','xtick',[0 1 2 5 10],'xlim',[0 5],'xticklabel',{'intercept-only','1 PC','2 PCs','5 PCs','10 PCs'})
% 
% ylabel('m.s.e. relative to null model');
% g=refline(0,1);
% g.LineWidth=2;
% g.LineStyle=':';
% g.Color=[1 1 1]/2;
% title('Corrected DVs, pre-nTc');
% drawnow;
% 
% hold on;
% nboot=100;
% clear boots x
% for k=1:numel(pca_res.cross_val_err{1})
%     rng(1);    
%     for i=1:numel(pca_res.cross_val_err_null)
%         x{i} = pca_res.cross_val_err_null{i}{k};
%         x{i} = bootstrp(nboot,@(x)nanmean(x(:).^2),x{i});   
%     end
%     rng(1);
%     boots(:,k) = hierarchical_bootstrp(nboot,@(x)nanmean(x),x,true);
% end
% boots=boots./boots(:,1);
% %boots(boots>yl)=yl;
% mn=mean(boots);
% sd=std(boots);
% h(2)=errorbar(0:3,mn./mn(1),sd./mn(1),'color',[1 1 1]/2);
% title('Corrected DVs, pre-nTc');
% drawnow;
% 
% 
% nboot=100;
% clear boots x
% for k=1:numel(pca_res.cross_val_err{1})
%     rng(1);    
%     for i=1:numel(pca_res2.cross_val_err)
%         x{i} = pca_res2.cross_val_err_null{i}{k};
%         x{i} = bootstrp(nboot,@(x)nanmean(x(:).^2),x{i});   
%     end
%     rng(1);
%     boots(:,k) = hierarchical_bootstrp(nboot,@(x)nanmean(x),x,true);
% end
% boots=boots./boots(:,1);
% %boots(boots>yl)=yl;
% mn=mean(boots);
% sd=std(boots);
% h(3)=errorbar(0:3,mn./mn(1),sd./mn(1),'color',[1 0 0]);
% title('Corrected DVs, pre-nTc');
% drawnow;
% 
% 
% nboot=100;
% clear boots x
% for k=1:numel(pca_res.cross_val_err{1})
%     rng(1);    
%     for i=1:numel(pca_res_shuffle.cross_val_err)
%         x{i} = pca_res_shuffle.cross_val_err{i}{k};
%         x{i} = bootstrp(nboot,@(x)nanmean(x(:).^2),x{i});   
%     end
%     rng(1);
%     boots(:,k) = hierarchical_bootstrp(nboot,@(x)nanmean(x),x,true);
% end
% boots=boots./boots(:,1);
% %boots(boots>yl)=yl;
% mn=mean(boots);
% sd=std(boots);
% h(4)=errorbar(0:3,mn./mn(1),sd./mn(1),'color',[0 1 0]);
% title('Corrected DVs, pre-nTc');
% drawnow;
% 
% 
% 
% legend(h,{'Observed','Independent Decision Processes','2 groups','regions shuffled'});
% set(gca,'ylim',[3e-1 30],'yscale','log');
% for i=1:4
%     h(i).CapSize=eps;
%     %h(i).LineStyle='none';
%     h(i).Marker='.';
%     h(i).MarkerSize=20;
%     h(i).LineWidth=2;    
% end
% 




subplot(1,3,1);
clear h
h(1)=plot_pca_spectrum(pca_res,16,false,[0 0 0]);hold on;
h(2)=plot_pca_spectrum(pca_res,16,true,[1 1 1]/2);hold on;
h(3)=plot_pca_spectrum(pca_res2,16,true,[1 0 0]);
h(4)=plot_pca_spectrum(pca_res_shuffle,16,false,[0 1 0]);
legend(h,{'Observed','Independent Decision Processes','2 groups','regions shuffled'});
box off;


% figure;
% plot_cv_stat(pca_res.r2,1,true);
% hold on;plot_cv_stat(pca_res.r2_null,1,true);

subplot(1,3,3);cla;
%plot_loadings(pca_res_shuffle.loading_resamp,1,true,[0 1 0]);hold on
[h,boots] = plot_loadings(pca_res.loading_resamp,1,pca_res.region{1},pca_res.hemisphere{1});
mns = nanmean(boots);
sds=nanstd(boots);
mns = (mns(1:10)+mns(11:20))/2;
sds=(sds(1:10)+sds(11:20))/2;
uberphys.color_tick_labels;
set(gca,'ylim',[0 0.85],'ytick',[0:0.2:0.8]);box off

common.savefig(gcf,mfilename);

function h=plot_pca_spectrum(pca_res,max_pcs,null,color)

% explained should be a cell array of length nsess

% each element should be npcs X nresamps matrix

nsess=numel(pca_res.explained_resamp);
for i=1:nsess
    sz = size(pca_res.explained_resamp{i});    
    sz(1) = min(sz(1),max_pcs);
    explained{i} = NaN(max_pcs,sz(2))';
    explained_null{i} = NaN(max_pcs,1)';    
    explained{i}(:,1:sz(1)) = pca_res.explained_resamp{i}(1:sz(1),:)';
    explained_null{i}(1:sz(1)) = nanmean(pca_res.explained_null{i}(1:sz(1),:)');
end

boots=hierarchical_bootstrp(1000,@nanmean,explained,true);    
boots_null=hierarchical_bootstrp(1000,@nanmean,explained_null,true);

if ~null
    h = errorbar(1:max_pcs,nanmean(boots),nanstd(boots),'color',color);
else
    h = errorbar(1:max_pcs,nanmean(boots_null),nanstd(boots_null),'color',color);
end
h.CapSize=0;
%h.LineStyle='none';
h.Marker='.';
h.MarkerSize=20;
h.LineWidth=2;
set(gca,'xlim',[1 max_pcs]);
ylabel('Fraction Variance Explained');
xlabel('Number of PCs');

set(gca,'xgrid','on','xtick',[1 2 5 10 15],'xlim',[0.5 max_pcs])

end


function [h,boots]=plot_loadings(loadings,pc_idx,regions,hemispheres)
    nsess = numel(loadings);
    nboot=1000;
    [~,idx] = sort(hemispheres);
    hemispheres=hemispheres(idx);
    regions=regions(idx);
    colors=uberphys.get_brain_region_colors(regions);
    for i=1:nsess
        loadings{i} = squeeze(loadings{i}(idx,pc_idx,:))';
    end
    boots = hierarchical_bootstrp(nboot,@nanmean,loadings,true);
    for  r=1:numel(hemispheres)
        h(r)=errorbar(r,nanmean(boots(:,r)),nanstd(boots(:,r)),'color',colors(r,:));hold on
        h(r).CapSize=eps;
        h(r).Marker='none';
        h(r).LineWidth=2;   
        h(r)=bar(r,nanmean(boots(:,r)),'facecolor',colors(r,:),'edgecolor','none');        
    end
    set(gca,'xtick',1:numel(hemispheres),'xticklabel',regions);
    ylabel(sprintf('Loading (cos(angle with PC %d)',pc_idx));

end

function h=plot_cv_stat(stat,pc_idx,combine_hemi,color)
    nsess = numel(stat);
    nboot=1000;
    for i=1:nsess
        if combine_hemi
            stat_left{i} = stat{i}{pc_idx+1}(1:2:end);    
            stat_right{i} = stat{i}{pc_idx+1}(2:2:end);                                  
            stat{i} = (stat_left{i}+stat_right{i})./2;
        else
            stat{i} = stat{i}{pc_idx+1};
        end
    end
    boots = hierarchical_bootstrp(nboot,@nanmean,stat,true);
    h=errorbar(1:size(boots,2),nanmean(boots),nanstd(boots),'color',color);
    h.CapSize=eps;

end


function combine_and_plot_loadings(pca_res,pc_idx)
    n_sess = numel(pca_res.explained);
    n_resamp=1000;
    max_pcs=14;
    loadings = NaN(n_resamp,20,max_pcs);   
    loadings_other = NaN(n_resamp,20);        
    colors = parula(max_pcs);
    for i=1:n_resamp
        sess_idx = randsample(n_sess,n_sess,true);
        samps=NaN(n_sess,20,max_pcs);
        samps_other=NaN(n_sess,20);
        k=randsample(max_pcs,1)+1;        % to exclude PC1 
        for s=1:n_sess
            samps(s,:,:) = squeeze(pca_res.loading_null{sess_idx(s)}(:,pc_idx,randsample(100,1)));
        end
        loadings(i,:,:) = squeeze(nanmean(samps,1));
    end

        h(1)=shadedErrorBar(1:20,squeeze(loadings),{@nanmean,@nanstd});hold on;
        legend([h.mainLine],["PC 1","other PCs"]);
        ylabel('Loading (a.u.)');
    labels = strcat(pca_res.region{1},", ",pca_res.hemisphere{1});
    labels = strrep(labels,"left","L");
    labels = strrep(labels,"right","R");
    set(gca,'xtick',1:20,'xticklabels',labels,'XTickLabelRotation',50);
    uberphys.color_tick_labels;
    ax=gca;
    ax.XAxis.FontSize=12;    
end