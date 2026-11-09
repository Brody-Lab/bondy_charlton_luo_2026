fig_path=fileparts(which(mfilename));
params.thre_trial = 1200;
if ~exist('rat','var'), rat="C211"; end % rat to plot; set it before running to choose another
make_dv_corr_data_fig_abruptCommitment_ed; % selects this rat's sessions

regions = [output.region];
[a,b] = ismember(DV.get_brain_regions,regions);
regions=regions(b(a));
output=output(b(a));
region_idx = regions=="M1"; % example region
x = output(1).click_times;
color{1}=hex2rgb("#ffb600");
color{1} = 1-(1-color{1})*0.88;
color{3}=hex2rgb("#bf52ff");
color{3} = 1-(1-color{3})*0.88;
color{2} = [0.85 0.85 0.85];
cbar = common.customcolormap([0  0.5 1], cellstr(cellfun(@rgb2hex,color)),15);
cbar_long = common.customcolormap([0  0.5 1], cellstr(cellfun(@rgb2hex,color)),500);

figure('position',[1000 916 1367 323]);
subplot(1,3,1);
cla;colororder(cbar);
plot(output(region_idx).src_times,output(region_idx).src,'linewidth',2);hold on
set(gca,'xlim',[0,max(output(2).src_times)]);
xlabel('Time after click (s)');
box off;
ylabel({'Influence of','Clicks on M1 DV','(correlation)'});
line(get(gca,'xlim'),[0 0],'color','k');
set(gca,'ylim',[-0.05 0.15]);
colororder(cbar);
subplot(1,3,2);
cla;colororder(cbar);
for k=1:15
    plot(ones(1,1),output(region_idx).col_mean(k),'.','MarkerSize',20);hold on;
end
colororder(cbar);
set(gca,'ylim',[-0.05 0.15]);
set(gca,'xtick',[]);
line(get(gca,'xlim'),[0 0],'color','k');

subplot(1,3,3);
z = zeros(size(x));
y=output(region_idx).col_mean';
y_lower = output(region_idx).col_mean_lower';
y_upper = output(region_idx).col_mean_upper';
col = x;  % This is the color, vary with x in this case.
for i=1:numel(x)
    errorbar(x(i),y(i),y(i) - y_lower(i),y_upper(i) - y(i),'color',cbar(i,:),'LineWidth',2,'CapSize',eps,'Marker','.','MarkerSize',20);hold on
end
line(get(gca,'xlim'),[0 0],'color','k');
surface([x;x],[y;y],[z;z],[col;col],...
        'facecol','no',...
        'edgecol','interp',...
        'linew',2);
colormap(cbar_long);
xlabel('Time relative to nTc (s)');
ylabel({'Average Influence of','Clicks on M1 DV','(correlation)'});
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_i_'+rat));


%three diff ways of plotting
%figure;for i=1:10;colororder(redblue(15)*0.8);for k=1:15;if k<9;offset=0;else;offset=0.2;end;plot(ones(1,1)*i+offset,output(i).col_mean(k)./nanmean(output(i).col_mean(1:8)),'.','MarkerSize',20);hold on;end;end


figure('position',[1000 827 346 412]);
factor=0.15;
n = numel(regions); % 9 for rats missing a region (A324 BLA, A327 S1, C211 TS); was hard-coded 10
for i=1:numel(regions)
z = zeros(size(x));
y=output(i).col_mean' + (n-i)*factor;hold on
line([-1 1],[1 1].*(n-i)*factor,'color','k');
y_lower = output(i).col_mean_lower' + (n-i)*factor;
y_upper = output(i).col_mean_upper' + (n-i)*factor;
col = x;  % This is the color, vary with x in this case.
h=shadedErrorBar(x,y,[y-y_lower;y_upper-y],{'color',uberphys.get_brain_region_colors(regions(i)),'LineWidth',2});
for  k=1:numel(x)
    %scatter(x(k),y(k),'marker','o','markerfacecolor',cbar(k,:),'markeredgecolor','none');
end
h.patch.FaceAlpha=0;
% surface([x;x],[y;y],[z;z],[col;col],...
%         'facecol','no',...
%         'edgecol','interp',...
%         'linew',2);
end
grid on;set(gca,'ytick',(1:n)*factor,'yticklabel',flip(regions));
colormap(cbar);
set(gca,'xlim',[min(x),max(x)],'ylim',[0 (n+0.5)*factor]);
xlabel('Time relative to nTc (s)');
uberphys.color_tick_labels;
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_j'+rat));
line([0 0],get(gca,'ylim'),'color','k');

d=[output.col_mean];
img=d';
figure;h=imagesc(x,1:numel(regions),img);colormap(bone);
grid on;set(gca,'ytick',1:n,'yticklabel',regions);
set(gca,'xlim',[min(x)-0.025,max(x)+0.025]);
set(gca,'ylim',[0.5 n+0.5]);
xlabel('Time relative to nTc (s)');
uberphys.color_tick_labels;
grid off;box off;
colorbar();
%set(gca,'clim',[-0.25 1.25]);
set(gca,'clim',[-0.025 0.1]);
set(h,'AlphaData',~isnan(img));
set(gca,'ydir','reverse');



figure('position',[1000 1165 573 73]);
imagesc(1:15);colormap(cbar);axis equal;axis off;box off;

common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_cbar'+rat));

figure('position',[70  883 263 392]);
for i=numel(regions):-1:1
    [corr_before_after(i,1),corr_before_after_err(i,1)] = DV.average_corrs(output(i).col_mean(1:max(col_before_idx)),output(i).col_mean_upper(1:max(col_before_idx)) - output(i).col_mean(1:max(col_before_idx)),1,'weighted',true);
    [corr_before_after(i,2),corr_before_after_err(i,2)] = DV.average_corrs(output(i).col_mean((max(col_before_idx)+1):end),output(i).col_mean_upper((max(col_before_idx)+1):end) - output(i).col_mean((max(col_before_idx)+1):end),1,'weighted',true);    
    errorbar([1 2],corr_before_after(i,:),corr_before_after_err(i,:),'CapSize',eps,'color',uberphys.get_brain_region_colors(regions(i)),'Marker','.','MarkerSize',30,'LineWidth',2);hold on
end
line(get(gca,'xlim'),[ 0 0],'LineWidth',2,'color','k');
set(gca,'ylim',[-0.05 0.125],'ytick',[0 0.1],'xtick',[1 2],'xticklabel',{'before nTc','after nTc'},'box','off','xlim',[0.5 2.5]);
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_k'+rat));
