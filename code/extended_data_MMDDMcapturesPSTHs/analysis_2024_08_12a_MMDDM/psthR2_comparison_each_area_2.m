clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'psthR2.mat'))
%%
uniqueareas = ["dmFC", "M1", "ADS",  "S1", "mPFC", "HPC", "NAc", "TS",  "MGB", "BLA"];
DeltaR2 = struct;
nrecordings = numel(psthR2.multimode);
for i = 1:nrecordings
    deltaR2 = max(psthR2.multimode{i},0) - max(psthR2.singlemode{i},0);
    for j = 1:numel(uniqueareas)
        DeltaR2.(uniqueareas(j))(i,1) = nanmean(deltaR2(brainarea{i}==uniqueareas(j)));
    end
end
%
nareas = numel(uniqueareas);
deltaR2_mean = nan(nareas,1);
deltaR2_std = nan(nareas,1);
for i = 1:nareas
    R2 = DeltaR2.(uniqueareas(i));
    R2 = R2(~isnan(R2));
    deltaR2_mean(i) = mean(R2);
    deltaR2_std(i) = std(bootstrp(1e3, @mean, R2));
end
%
[deltaR2_mean, sortindex] = sort(deltaR2_mean, 'descend')
deltaR2_std = deltaR2_std(sortindex);
uniqueareas = uniqueareas(sortindex);
close all
figure('Position',[100 100 400 300])
UBT.stylizeaxes
colors = UBT.brain_region_colors;
for i = 1:numel(uniqueareas)
    plot(i*[1,1], deltaR2_mean(i) + [-1,1]*deltaR2_std(i), 'linewidth', 2, 'color', colors.(uniqueareas(i)))
    plot(i, deltaR2_mean(i), 'o', 'markeredgecolor', 'w', 'markerfacecolor', colors.(uniqueareas(i)))
end
ylabel('Delta PSTH R2')
set(gca, 'XTick', 1:nareas, 'xticklabel', uniqueareas, 'XTickLabelRotation', 90)
xlim([0 nareas])
saveas(gcf, fullfile(analysispath, [scriptname '.svg']))
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