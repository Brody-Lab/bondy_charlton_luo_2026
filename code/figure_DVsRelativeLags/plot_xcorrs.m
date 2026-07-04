function [lags_sort_idx,omns,osds] = plot_xcorrs(corrs,max_lag,lags_sort_idx)

    field='xcorr';
    combined = DV.combine_corrs(corrs)
    for i=1:numel(combined.lags)
        combined.(field)(:,:,i) = SetDiag(squeeze(combined.(field)(:,:,i)),NaN);
    end
    
    combined = DV.combine_corrs_across_hemi(combined);
    
    
    nregions = numel(combined.regions);
    clear pk
    for i=1:nregions
        for k=1:nregions
            pk(i,k,:) = DV.get_xcorr_peak(combined.lags,squeeze(combined.(field)(i,k,:))',...
                'xc_se',squeeze(combined.se.(field)(i,k,:))','nresamp',1000,'max_lag',max_lag,'mode',"max");
        end
    end
            pk_mn = nanmean(pk,3);
            pk_sd = nanstd(pk,0,3);
            
            
    
    pk_mn2= SetDiag(pk_mn,NaN);
    pk_sd2= SetDiag(pk_sd,NaN);
    
    %w=ones(size(pk_sd2));
    %w=(pk_sd2+1e-3)./nansum(pk_sd2+1e-3);
    %w=log(1./pk_sd2.^2);
    w=ones(size(pk_sd2));
    w=w./nansum(w);
    mns=wmean(pk_mn2,w);
    %mns=nanmean(pk_mn2);
    
        sds = sqrt(nansum((pk_sd2.*w).^2,1));
    
    
    %sds=nanmean(pk_sd)./sqrt(sum(~isnan(pk_mn)));
    labels = combined.regions;
    all_labels = strcat(combined.regions,strrep(strrep(combined.hemisphere,"left",", L"),"right",", R"));
    omns = mns;
    osds=sds;
    if  nargin<3
        [~,lags_sort_idx] = sort(mns);
    end
    mns=mns(lags_sort_idx);
    sds= sds(lags_sort_idx);
    labels = categorical(unique(labels,'stable'));
    labels = labels(lags_sort_idx);
    
    subplot(3,1,1);errorbar(mns,sds,'CapSize',eps,'Marker','.','MarkerSize',30,'Color','k','LineWidth',1.5)
    set(gca,'xtick',1:10,'xticklabel',{},'xticklabelrotation',45,'tickdir','out');box off;
        set(gca,'xlim',[0 10]+0.5,'ylim',[-.16 .16]);
    ylabel('mean relative lag (s)')
    text(4,-0.12,'leads population','FontSize',16);
    text(4,0.1,'lags population','FontSize',16);
    h=line(get(gca,'xlim'),[ 0 0],'Color','k','LineWidth',1,'LineStyle',':');


    label_count=10;
    subplot(3,1,[2 3]);
        im=imagesc(pk_mn2(lags_sort_idx,lags_sort_idx));
        frac=pk_sd./range(pk_sd(:));
        frac=frac-min(frac(:));
        for i=1:nregions
            for k=1:nregions
                if i==k
                    continue
                end
                %DV.cover_image(i,k,sqrt(frac(i,k))/3,[1 1 1]);
            end
        end
        set(gca,'xtick',1:100,'xticklabel',labels,'ytick',1:10,...
            'yticklabel',labels,'tickdir','out','XTickLabelRotation',45,'ydir','reverse',...
            'XAxisLocation','top');box off;
        g=colorbar;
        g.Position=[0.9133    0.1160    0.0300    0.1500];
        g.Label.String=["peak" "lag" "(s)"];
        g.Label.Position = [1.25 0.96 0];
        g.FontSize=12;
        g.Label.Rotation=0;
        cd = get(im,'CData'); 
        set(im,'alphadata',isfinite(cd)); 
        axis square

    set(gca,'xlim',[0 10]+0.5,'ylim',[0 10]+0.5);
    uberphys.color_tick_labels    

    colormap(diverging_map(0:0.01:1,[0.6 0 1],[1 0.7 0]));
end

