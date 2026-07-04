clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
excluded_sessions = ["2023_12_15";
                     "2023_12_16";
                     "2023_12_20";
                     "2023_12_21";
                     "2023_12_22";
                     "2023_12_29"];
%%
sessions = UBT.tabulatesessions
sessions = sessions(sessions.perceptual==1 & sessions.rat=="C211",:);
rats = unique(sessions.rat);
figure('position', [100 100 220 200])
TZL.stylizeaxes
colors = colororder;
sessiondates = sessions.date;
PBups.plot_aggregate_psychometric(rats{i}, sessiondates, 'confidenceinterval', false, ...
    'linespec', {'.-', 'color','k', 'markersize', 12, 'linewidth', 1.5})
PBups.plot_aggregate_psychometric(rats{i}, excluded_sessions, 'confidenceinterval', false, ...
    'linespec', {'.-', 'color','r', 'markersize', 12, 'linewidth', 1.5})
xlim([-30 31])
xticks([-30 0 30])
plot(xlim, [0.5,0.5], 'k--', 'linewidth', 0.5)
plot([0,0], ylim, 'k--', 'linewidth', 0.5)

text(10, 0.8-0.2, 'excluded', 'color', 'r', 'fontsize', get(gca, 'fontsize'))
ylabel('fraction chose right')
xlabel('#right - #left clicks')
% set(gca, 'position', [0.38 0.39 0.52 0.53])
saveas(gcf, fullfile(analysispath, scriptname), 'svg')