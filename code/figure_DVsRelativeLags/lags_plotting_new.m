

ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
field='xcorr';
  %  res_hemi = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true,'frozen',false);
  %  sessions = uberphys.load_bcl_sessions_table;
  %  res_hemi=res_hemi(logical(sessions.frozen));
  % res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',false,'frozen',false);
  %  sessions = uberphys.load_bcl_sessions_table;
  %  res=res(logical(sessions.frozen));
 [combined,corrs] = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds_same_lambda','nresamples',50,'time_lim_s',[0.35 Inf]);
for i=1:numel(combined.lags)
    combined.(field)(:,:,i) = SetDiag(squeeze(combined.(field)(:,:,i)),NaN);
end

%combined.(field) = corr2cov(combined.std,combined.(field));
combined = DV.combine_corrs_across_hemi(combined);


nregions = numel(combined.regions);
clear pk
for i=1:nregions
    for k=1:nregions
        pk(i,k,:) = DV.get_xcorr_peak(combined.lags,squeeze(combined.(field)(i,k,:))',...
            'xc_se',squeeze(combined.se.(field)(i,k,:))','nresamp',1000,'max_lag',0.3,'mode',"max");
    end
end
        pk_mn = nanmean(pk,3);
        pk_sd = nanstd(pk,0,3);
        
        

pk_mn2= SetDiag(pk_mn,NaN);
pk_sd2= SetDiag(pk_sd,NaN);

%w=ones(size(pk_sd2));
w=log(1./pk_sd2.^2);
%w=ones(size(pk_sd2));
w=w./nansum(w);
mns=wmean(pk_mn2,w);
%mns=nanmean(pk_mn2);

    sds = sqrt(nansum((pk_sd2.*w).^2,1));


%sds=nanmean(pk_sd)./sqrt(sum(~isnan(pk_mn)));
labels = combined.regions;
all_labels = strcat(combined.regions,strrep(strrep(combined.hemisphere,"left",", L"),"right",", R"));


[mns,lags_sort_idx] = sort(mns);

labels = categorical(unique(labels,'stable'));
labels = labels(lags_sort_idx);
   figure('units','pixels','position',[1001 500 562 864]);

subplot(3,1,1);errorbar(mns,2*sds(lags_sort_idx),'CapSize',eps,'Marker','.','MarkerSize',30,'Color','k','LineWidth',1.5)
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

% 



figure;
regions=["M1" "ADS" "dmFC"];
for k=1:3
    subplot(1,3,k);
    idx=combined.regions==regions(k);
    xcorrs=squeeze(combined.(field)(idx,~idx,:));    
    xcorrs_se=squeeze(combined.se.(field)(idx,~idx,:));        
    these_regions = combined.regions(~idx);
    [~,sort_idx] = sort(pk_mn(idx,~idx));
    xcorrs=xcorrs(sort_idx,:);
    xcorrs_se=xcorrs_se(sort_idx,:);    
    these_regions=these_regions(sort_idx);
    pks=pk_mn(idx,~idx);
    sds=pk_sd(idx,~idx);
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