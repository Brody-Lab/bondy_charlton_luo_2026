clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
%%
close all
figure('pos', [1e3 1e3 400 250])
UBT.stylizeaxes
colors = UBT.colors;
nTc_s = T.committime_s_M1-T.stereoclick_time_s;
h = histogram(nTc_s, 0:1/20:1)
set(h, 'facecolor', colors.nTc, 'facealpha', 0.2, 'edgecolor', colors.nTc , 'linewidth', 1)
ylabel('trials with nTc-M1')
xlabel('time from first click (s)')
% xlim([0 1])
xticks([0 1])
yticks(ylim)
yyaxis right
x0 = 1.35;
nTc_s(isnan(nTc_s)) = x0;
h = histogram(nTc_s, (x0-0.05):0.05:x0+0.05, 'facecolor', 'k', 'facealpha', 0.2, 'edgecolor', 'k', 'linewidth', 1)
ylim([0 sum(nTc_s==x0)])
yticks(ylim)
ylabel(sprintf('%0.1f%% without nTc-M1', mean(nTc_s==x0)*100))
ax = gca;
ax.YAxis(1).Color = colors.nTc;
ax.YAxis(2).Color = 'k';
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))