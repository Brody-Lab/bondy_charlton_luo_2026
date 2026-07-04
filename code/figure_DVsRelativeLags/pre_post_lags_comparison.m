%% run script to generate lags data
lags_plotting_pre_ntc;

lag_mn_pre = mns;
lag_sd_pre=sds(lags_sort_idx);
lags_labels_pre = string(labels);

lags_plotting_post_ntc;

lag_mn_post = mns;
lag_sd_post=sds(lags_sort_idx);
lags_labels_post = string(labels);

[idx,~]=find(lags_labels_pre==lags_labels_post');
lag_mn_pre=lag_mn_pre(idx);
lag_sd_pre = lag_sd_pre(idx);
lags_labels_pre=lags_labels_pre(idx);


figure('position',[ 1305         777         256         227]);
for i=1:numel(lags_labels)
    errorbar(-lag_mn_pre(i),-lag_mn_post(i),lag_sd_post(i),lag_sd_post(i),lag_sd_pre(i),lag_sd_pre(i),'CapSize',eps,'color',uberphys.get_brain_region_colors(lags_labels_pre(i)),'Marker','.','MarkerSize',15);hold on;
    text(-lag_mn_pre(i),-lag_mn_post(i),lags_labels_pre(i),'color',uberphys.get_brain_region_colors(lags_labels_pre(i)));
end
xlabel('mean relative lag pre (s)');
ylabel('mean relative lag post (s)');
box off;
set(gca,'tickdir','out');
set(gca,'xlim',[-0.15 0.2],'ylim',[-0.15 0.2]);
refline(1,0);
