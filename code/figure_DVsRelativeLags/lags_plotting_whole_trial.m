% weighted averaged = true
% not using covs, using corrs loop
% only using trials with commitment

ext = {'pdf','fig','png'};
path=fileparts(which(mfilename));
field='xcorr';
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','alpha',0.95,'variable','choice','by_hemisphere',true);
combined = DV.corrs_from_res(res,'control_for',{'seed','pokedR'},'field','log_odds_same_lambda','nresamples',50,'correction_type','mean_subtract','correct_first',true,'time_lim_s',[0.1 1]);%'time_lim_s',[-0.65 -0.25],'ref_event','committime_s_M1');
for i=1:numel(combined.lags)
    combined.(field)(:,:,i) = SetDiag(squeeze(combined.(field)(:,:,i)),NaN);
end

%combined_pre.(field) = corr2cov(combined_pre.std,combined_pre.(field));
combined = DV.combine_corrs_across_hemi(combined);


nregions = numel(combined.regions);
clear pk
for i=1:nregions
    for k=1:nregions
        pk(i,k,:) = DV.get_xcorr_peak(combined.lags,squeeze(combined.(field)(i,k,:))',...
            'xc_se',squeeze(combined.se.(field)(i,k,:))','nresamp',5000,'max_lag',0.35,'mode',"max");
    end
end
        pk_mn = nanmean(pk,3);
        pk_sd = nanstd(pk,0,3);
        
        

%pk_mn= SetDiag(pk_mn,NaN);
%pk_sd= SetDiag(pk_sd,NaN);

%[mns,sds] = DV.average_corrs(pk_mn,pk_sd,1);
mns=wmean(pk_mn,pk_sd);
sds=nanmean(pk_sd)./sqrt(sum(~isnan(pk_mn)));
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
    im=imagesc(pk_mn(lags_sort_idx,lags_sort_idx));
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