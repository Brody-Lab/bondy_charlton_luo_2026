function plot_example_xcorr(corrs,max_lag,region)
    field='xcorr';
    combined = DV.combine_corrs(corrs);

    for i=1:numel(combined.lags)
        combined.(field)(:,:,i) = SetDiag(squeeze(combined.(field)(:,:,i)),NaN);
    end    
    combined = DV.combine_corrs_across_hemi(combined);
    idx=combined.regions==region;


    nregions = numel(combined.regions);
    clear pk
        for k=1:nregions
            pk(k,:) = DV.get_xcorr_peak(combined.lags,squeeze(combined.(field)(find(idx),k,:))',...
                'xc_se',squeeze(combined.se.(field)(find(idx),k,:))','nresamp',1000,'mode',"max",'max_lag',max_lag);
        end
            pk_mn = nanmean(pk,2);
            pk_sd = nanstd(pk,0,2);




    xcorrs=squeeze(combined.(field)(idx,~idx,:));    
    xcorrs_se=squeeze(combined.se.(field)(idx,~idx,:));        
    these_regions = combined.regions(~idx);
    [~,sort_idx] = sort(pk_mn(~idx));
    xcorrs=xcorrs(sort_idx,:);
    xcorrs_se=xcorrs_se(sort_idx,:);    
    these_regions=these_regions(sort_idx);
    pks=pk_mn(~idx);
    sds=pk_sd(~idx);
    pks = pks(sort_idx);
    sds=sds(sort_idx);
    clear h 
    count=0;
    for i=1:numel(these_regions)
        h(i)=shadedErrorBar(combined.lags,xcorrs(i,:),2*xcorrs_se(i,:),{'color',uberphys.get_brain_region_colors(these_regions(i)),'linewidth',2});hold on;
        line(pks(i)*[1 1],[0 0.012]+0.45 - i*0.016 ,'color',uberphys.get_brain_region_colors(these_regions(i)),'linewidth',2);
        patch(pks(i)+[-1 1 1 -1]*sds(i),[0 0 0.012 0.012]+0.45 - i*0.016 ,uberphys.get_brain_region_colors(these_regions(i)),'facealpha',0.5,'edgecolor','none');
    end

    if k==3
        legend([h.mainLine],combined.regions(~idx));
    end
    set(gca,'xlim',[-1 1],'ylim',[-0.2 0.5],'box','off');
    xlabel('Lag (s)');
    ylabel('DV residual correlation');
end
