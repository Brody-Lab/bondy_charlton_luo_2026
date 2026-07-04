clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'psthR2.mat'))
nrecordings = numel(psthR2.multimode)
DeltaR2 = cellfun(@(x,y) mean(max(x,0)-max(y,0)), psthR2.multimode, psthR2.singlemode)
%%
figure('position', [100 100 300 275])
TZL.stylizeaxes
histogram(DeltaR2, -0.01:0.01:0.1, 'facecolor', 'k', ...
    'facealpha', 0.2, 'linewidth', 1)
ylabel('sessions')
xlabel('DeltaR2')
title('multi - single mode')
xlim([0 0.08])
xticks([0 0.05])
yticks(ylim)
pval = signtest(DeltaR2);
text(0.05, 8, sprintf('p=%0.0e', pval), 'FontSize',get(gca, 'Fontsize'))
saveas(gcf, fullfile(analysispath, [scriptname '.svg']))