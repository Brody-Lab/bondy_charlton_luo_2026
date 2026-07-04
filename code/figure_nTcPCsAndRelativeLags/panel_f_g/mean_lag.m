clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'mean_pairwise_lag.mat'))
lag  = nanmean(X);
nregions = numel(brainregions);
lag_SE = nan(nregions,1);
nsamples = numel(Xboot{1});
for i = 1:nregions
    diffboot = nan(nsamples,1);
    for b = 1:nsamples
        diffboot(b) = nanmean(cellfun(@(x) x(b), Xboot(:,i)));
    end
    lag_SE(i) = sqrt(sum((lag(i) - diffboot).^2)/(nsamples-1))
end

[lag, sortindices] = sort(lag, 'descend');
brain_region_labels  = brainregions(sortindices);
close all
figure('pos', [100 100 400 400])
UBT.stylizeaxes
nregions = numel(brain_region_labels);
colors = UBT.brain_region_colors;
plot(1:nregions, lag, '-', 'color', 0.5*ones(1,3))
for i = 1:nregions
    plot(i*[1,1], lag(i)+[-1 1]*lag_SE(i), '-', 'linewidth', 2, 'color', colors.(brain_region_labels(i)))
    plot(i, lag(i), 'o', 'markersize', 8, 'markerfacecolor',  colors.(brain_region_labels(i)), ...
         'markeredgecolor',  colors.(brain_region_labels(i)), 'linewidth', 0.5)
end
xticks(1:nregions)
custom_xticklabels = strings(nregions,1);
for i = 1:nregions
    custom_xticklabels{i} = sprintf('\\color[rgb]{%f, %f, %f}{\\bf{%s}}', ...
        colors.(brain_region_labels(i)), brain_region_labels(i));
end
xticklabels(custom_xticklabels)
plot([1, nregions], [0,0], '--', 'linewidth', 0.5, 'color', 0.5*ones(1,3))
xlim([0 nregions+1])
ylim([-0.14, 0.14])
yticks(-0.15:0.05:0.15)
ylim([-0.12, 0.12])
ylabel('average lag (s)')
text(2.5, 0.1, 'leads', 'FontWeight','bold', 'fontsize', get(gca, 'fontsize'))
text(6.5, -0.08, 'lags', 'FontWeight','bold', 'fontsize', get(gca, 'fontsize'))
set(gca, 'XTickLabelRotation',90)
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
save(fullfile(analysispath, [scriptname '.mat']), 'brainregions', 'lag', 'lag_SE');
