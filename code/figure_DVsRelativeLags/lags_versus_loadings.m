%% run script to generate lags data
%lags_plotting_whole_trial;

% lag_mn = mns;
% lag_sd=sds(lags_sort_idx);
% lags_labels = string(combined.regions(lags_sort_idx));
% 
% 
% 
% 
% 
%  pca_res=DV.get_dv_pcs(res,'control_fields',{'seed','pokedR'},'lim_time_s',[-Inf -0.25],'kfold',20,'scale',false);

%plot_loadings(pca_res_shuffle.loading_resamp,1,true,[0 1 0]);hold on
figure;[h,mn,se]=plot_loadings(pca_res.loading_resamp,1,true,[0 0 0]);
set(gca,'xtick',1:10,'xticklabel',DV.get_brain_regions);
uberphys.color_tick_labels;
labels = pca_res.region{1}(1:2:end);

[idx,~]=find(lags_labels==labels');
lag_mn=lag_mn(idx);
lag_sd = lag_sd(idx);
lags_labels=lags_labels(idx);

figure('position',[ 1305         777         256         227]);
for i=1:numel(lags_labels)
    errorbar(lag_mn(i),mn(i),se(i),se(i),lag_sd(i),lag_sd(i),'CapSize',eps,'color',uberphys.get_brain_region_colors(lags_labels(i)),'Marker','.','MarkerSize',15);hold on;
end
xlabel('mean relative lag (s)');
ylabel('PC1 Loading');
box off;
set(gca,'tickdir','out');

function [h,mn,se]=plot_loadings(loadings,pc_idx,combine_hemi,color)
    nsess = numel(loadings);
    nboot=1000;
    for i=1:nsess
        if combine_hemi
            loadings_left{i} = squeeze(loadings{i}(1:2:end,pc_idx,:))';
            loadings_right{i} = squeeze(loadings{i}(2:2:end,pc_idx,:))';            
            loadings{i} = (loadings_left{i}+loadings_right{i})./2;
        else
            loadings{i} = squeeze(loadings{i}(:,pc_idx,:))';
        end
    end
    boots = hierarchical_bootstrp(nboot,@nanmean,loadings,false);
    mn=nanmean(boots);
    se=nanstd(boots);
    h=errorbar(1:size(boots,2),nanmean(boots),nanstd(boots),'color',color);
    h.CapSize=eps;
    %h.LineStyle='none';
    h.Marker='.';
    h.MarkerSize=20;
    h.LineWidth=2;    
    ylabel(sprintf('Loading (cos(angle with PC %d)',pc_idx));

end