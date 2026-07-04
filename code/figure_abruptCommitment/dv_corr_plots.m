fig_path=fileparts(which(mfilename));
params.thre_trial = 1200;
%make_dv_corr_data_fig_abruptCommitment;
%trilinear_fits;
regions = DV.get_brain_regions;
region_idx = regions=="M1"; % example region
x = output(1).click_times;
color{1}=ones(1,3)*0;
color{2} = ones(1,3)*0.7;
color{3}=ones(1,3)*0.9;
cbar = common.customcolormap([ 0 0.5 1 ], cellstr(cellfun(@rgb2hex,color)),15);
cbar_long = common.customcolormap([0 0.5  1], cellstr(cellfun(@rgb2hex,color)),500);

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
    plot(ones(1,1),mean(output(region_idx).col_mean(:,k)),'.','MarkerSize',20);hold on;
end
colororder(cbar);
set(gca,'ylim',[-0.05 0.15]);
set(gca,'xtick',[]);
line(get(gca,'xlim'),[0 0],'color','k');

subplot(1,3,3);
z = zeros(size(x));
y=mean(output(region_idx).col_mean,1);
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
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_ij'));


%three diff ways of plotting
%figure;for i=1:10;colororder(redblue(15)*0.8);for k=1:15;if k<9;offset=0;else;offset=0.2;end;plot(ones(1,1)*i+offset,output(i).col_mean(k)./nanmean(output(i).col_mean(1:8)),'.','MarkerSize',20);hold on;end;end


figure('position',[1000 827 346 412]);
factor=0.1;
for i=1:10
z = zeros(size(x));
y=mean(output(i).col_mean) + (10-i)*factor;hold on
line([-1 1],[1 1].*(10-i)*factor,'color','k');
y_lower = output(i).col_mean_lower + (10-i)*factor;
y_upper = output(i).col_mean_upper + (10-i)*factor;
col = x;  % This is the color, vary with x in this case.
shadedErrorBar(x,y,[y-y_lower;y_upper-y],{'color',uberphys.get_brain_region_colors(regions(i)),'LineWidth',2});
for  k=1:numel(x)
    %scatter(x(k),y(k),'marker','o','markerfacecolor',cbar(k,:),'markeredgecolor','none');
end
plot(t_fine,(10-i)*factor+tl_means(i).evaluate(t_fine));
% surface([x;x],[y;y],[z;z],[col;col],...
%         'facecol','no',...
%         'edgecol','interp',...
%         'linew',2);
end
grid on;set(gca,'ytick',(1:10)*factor,'yticklabel',flip(regions));
colormap(cbar);
set(gca,'xlim',[min(x),max(x)],'ylim',[0 10.5*factor]);
xlabel('Time relative to nTc (s)');
uberphys.color_tick_labels;
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_k'));
line([0 0],get(gca,'ylim'),'color','k');

for i=1:10
    img(i,:) = squeeze(mean(output(i).col_mean))';
end
figure;h=imagesc(x,1:10,img);colormap(bone);
grid on;set(gca,'ytick',1:10,'yticklabel',regions);
set(gca,'xlim',[min(x)-0.025,max(x)+0.025]);
set(gca,'ylim',[0.5 10.5]);
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

common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_cbar'));

figure('position',[70  917 444 359]);
avg_output=output;
for i=1:10;
    avg_output(i).col_mean = mean(output(i).col_mean);
end
for i=10:-1:1
    before_boots = nanmean(output(i).col_mean(:,1:max(col_before_idx)),2);
    after_boots = nanmean(output(i).col_mean(:,(max(col_before_idx)+1):end),2);
    nans = isnan(after_boots) | isnan(before_boots);
    after_boots = after_boots(~nans);
    before_boots = before_boots(~nans);    
    fold(i) = mean(after_boots)./mean(before_boots);
    p(i)=empirical_p(0,after_boots,'both'); 
    %errorbar([1 2]+i,[mean(before_boots) mean(after_boots)],[std(before_boots) std(after_boots)],'CapSize',eps,'color',uberphys.get_brain_region_colors(regions(i)),'Marker','.','MarkerSize',30,'LineWidth',2);hold on
    errorbar(mean(before_boots),mean(after_boots),std(after_boots),std(after_boots),std(before_boots),std(before_boots),'CapSize',eps,'color',uberphys.get_brain_region_colors(regions(i)),'Marker','.','MarkerSize',30);hold on    
end
set(gca,'ylim',[-0.025 0.1],'ytick',[0 0.1],'xtick',[0 0.1],'xlim',[-0.025 0.1]);
h=refline(1,0);
grid on;
axis equal
set(gca,'ylim',[-0.025 0.1],'ytick',[0 0.1],'xtick',[0 0.1],'xlim',[-0.025 0.1]);
xlabel('Before nTc');ylabel('After nTc');
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_l'));


plot_trilinear_summary;
common.savefig(gcf,fullfile(fig_path,'fig_abruptCommitment_m'));
