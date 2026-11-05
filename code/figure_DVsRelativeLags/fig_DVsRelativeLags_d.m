%must run fig_DVsRelativeLags_bc and fig_DVsAndCorrelations_ij first
regions=common.get_brain_regions;
colors=uberphys.get_brain_region_colors(regions);
figure;
ggg=mean(cat(1,mns_lags{2:end}));
for i=1:10
    errorbar(a(i),mns(i),sds(i),sds(i),sds_lags_resamp(i),sds_lags_resamp(i),'capsize',0,'color',colors(i,:));
end
ylabel('PC1 Loading');sds

xlabel('Relative Lag');

common.savefig(gcf,mfilename);

