clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'psthR2.mat'))
uniqueareas = ["dmFC", "mPFC", "MGB", "M1", "ADS", "TS", "BLA", "HPC", "NAc", "S1"];
DeltaR2 = struct;
nrecordings = numel(psthR2.multimode)
for i = 1:nrecordings
    deltaR2 = max(psthR2.multimode{i},0) - max(psthR2.singlemode{i},0);
    for j = 1:numel(uniqueareas)
        DeltaR2.(uniqueareas(j))(i,1) = nanmean(deltaR2(brainarea{i}==uniqueareas(j)));
    end
end
%%
figure('Position',[100 100 2000 400])
colors = UBT.brain_region_colors;
for i = 1:numel(uniqueareas)
    subplot(2,5,i)
    TZL.stylizeaxes
    x = DeltaR2.(uniqueareas(i))
    histogram(x,  -0.06:0.02:0.12, 'facecolor', colors.(uniqueareas(i)), 'linewidth', 2, ...
        'facealpha', 0.2)
    title(sprintf('%s (p=%0.0e)', uniqueareas{i},signtest(x)), 'color', colors.(uniqueareas(i)))
    % plot(median(x), max(ylim), 'v', 'color', colors.(uniqueareas(i)), ...
    %     'markerfacecolor', colors.(uniqueareas(i)), 'markersize', 10)
end
saveas(gcf, fullfile(analysispath, [scriptname '.svg']))