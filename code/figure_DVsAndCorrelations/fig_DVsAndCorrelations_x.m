
% plot by signal strength

%res = DV.load_DVs('fit_average',false,'reward_reversal',false,'ref_event','first_click','variable','choice','by_hemisphere',false,'frozen',false);


for s=1:numel(res)
    r = [res{i}{1}.region]=="dmFC";
gamma{s} = log(cellfun(@numel,res{s}{1}(1).Trials.rightBups)) - log(cellfun(@numel,res{s}{1}(1).Trials.leftBups));
edges=[-Inf -1.5 -0.5 0.5 1.5 Inf];
idx = discretize(gamma{s},edges);
a=arrayfun(@(x,y)linspace(x,y,numel(unique(idx))),left_color,right_color,'UniformOutput',false);
colors=cat(1,a{:})';
for i=1:numel(unique(idx))log(cellfun(@numel,res{s}{1}(1).Trials.rightBups)) - log(cellfun(@numel,res{s}{1}(1).Trials.leftBups));
    dvs{i}{s} = (res{s}{1}(r).log_odds(idx==i,:));
end
end
figure;

for i=1:numel(unique(idx))
boots=hierarchical_bootstrp(1000,@nanmean, dvs{i});
shadedErrorBar(res{s}{1}(1).bin_params.time_s,boots,{@nanmean,@nanstd},{'color',colors(i,:),'linewidth',2});hold on
end

h=colorbar;
colormap(colors)
set(gca,'clim',[0 1]);
h.Ticks=[0 0.2 0.4 0.6 0.8 1];
h.TickLabels=string(edges);
xlim([0 0.95]);
xlabel('Time since first click (s)');
ylabel('dmFC DV');
set(gca,'xtick',[0.1 0.3 0.8],'xgrid','on','ylim',[-5 5],'box','off');


%% save output
common.savefig(gcf,which(mfilename));