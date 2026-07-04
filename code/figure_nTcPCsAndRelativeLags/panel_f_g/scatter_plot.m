clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
load(fullfile(analysispath, 'mean_lag.mat'))
load(fullfile(analysispath, 'trial_fraction_with_nTc_vs_brain_region_used.mat'))
%%
close all
figure('pos', [1e3 1e3 400 350])
UBT.stylizeaxes
nregions = numel(brainregions);
colors = UBT.brain_region_colors;
for i = 1:nregions
    plot(lag(i) + [-1 1]*lag_SE(i), phat(i)*[1,1], 'color', colors.(brainregions(i)), 'linewidth', 2)
    plot(lag(i)*[1,1], phat(i)+[-1,1]*phat_SE(i), 'color', colors.(brainregions(i)), 'linewidth', 2)
    plot(lag(i), phat(i), 'o',  'markersize', 8, 'color', colors.(brainregions(i)), ...
        'markerfacecolor', colors.(brainregions(i)))
end
xlabel('average lag (s)')
ylabel('trial fraction with nTc')
xlim([-0.12 0.11])
xticks(-0.1:0.05:0.1)
set(gca, 'XTickLabelRotation', 30)
text(0.09, 0.6, 'M1', 'FontSize', get(gca, 'fontsize'), 'color', colors.M1)
text(lag(2), 0.45, 'ADS', 'FontSize', get(gca, 'fontsize'), 'color', colors.ADS)
text(lag(3)-0.05, 0.42, 'dmFC', 'FontSize', get(gca, 'fontsize'), 'color', colors.dmFC)
text(0.05, 0.28, 'MGB', 'FontSize', get(gca, 'fontsize'), 'color', colors.MGB)
text(0.005, 0.21, 'mPFC', 'FontSize', get(gca, 'fontsize'), 'color', colors.mPFC)
text(-0.01, 0.3, 'TS', 'FontSize', get(gca, 'fontsize'), 'color', colors.TS)
text(-0.01, 0.1, 'HPC', 'FontSize', get(gca, 'fontsize'), 'color', colors.HPC)
text(-0.06, 0.3, 'S1', 'FontSize', get(gca, 'fontsize'), 'color', colors.S1)
text(-0.06, 0.08, 'BLA', 'FontSize', get(gca, 'fontsize'), 'color', colors.BLA)
text(-0.11, 0.2, 'NAc', 'FontSize', get(gca, 'fontsize'), 'color', colors.NAc)
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
save(fullfile(analysispath, [scriptname '.mat']), 'brainregions', 'lag', 'lag_SE');
