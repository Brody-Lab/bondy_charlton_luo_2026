%% preliminaries
clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~,analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'psthR2.mat'))
psthR2 = vertcat(psthR2.multimode{:});
brainarea = vertcat(brainarea{:});
%%
uniqueareas = ["dmFC", "mPFC", "MGB", "M1", "ADS", "TS", "BLA", "HPC", "NAc", "S1"];
figure('Position',[100 100 2000 400])
colors = UBT.brain_region_colors;
for i = 1:numel(uniqueareas)
    R2 = psthR2(brainarea == uniqueareas(i));
    R2(R2 < 0) = -0.01;
    subplot(2,5,i)
    TZL.stylizeaxes
    histogram(R2, -0.1:0.1:1, 'facecolor', colors.(uniqueareas(i)), 'linewidth', 2, 'facealpha', 0.2)
    title(uniqueareas{i},'color', colors.(uniqueareas(i)))
    plot(median(R2), max(ylim), 'v', 'color', colors.(uniqueareas(i)), ...
        'markerfacecolor', colors.(uniqueareas(i)), 'markersize', 10)
    xlim([-0.1, 1])
    xticks([0 1])
end
saveas(gcf, fullfile(analysispath, [scriptname '.svg']))