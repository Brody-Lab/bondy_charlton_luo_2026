%must run fig_DVsRelativeLags_bc and fig_DVsAndCorrelations_ij first
regions=common.get_brain_regions;
colors=uberphys.get_brain_region_colors(regions);
figure;
for i=1:10
    errorbar(mns_lags(i),mns(i),sds(i),sds(i),sds_lags(i),sds_lags(i),'capsize',0,'color',colors(i,:));
end
ylabel('PC1 Loading');
xlabel('Relative Lag');

common.savefig(gcf,mfilename);

