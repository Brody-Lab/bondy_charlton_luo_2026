clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
sessions = UBT.tabulatesessions
sessions = sessions(sessions.perceptual==1,:);
rats = unique(sessions.rat);
figure('position', [100 100 220 200])
TZL.stylizeaxes
colors = ["#ea8d1f", "#d154ef" , "#32DDCD"];
for i = numel(rats):-1:1
    sessiondates = sessions.date(sessions.rat==rats(i));
    PBups.plot_aggregate_psychometric(rats{i}, sessiondates, 'confidenceinterval', false, ...
        'linespec', {'.-', 'color', colors{i}, 'markersize', 12, 'linewidth', 1.5})
end
xlim([-30 31])
xticks([-30 0 30])
plot(xlim, [0.5,0.5], 'k--', 'linewidth', 0.5)
plot([0,0], ylim, 'k--', 'linewidth', 0.5)
for i = 1:numel(rats)
    text(10, 0.8-0.2*i, sprintf('rat %i',i), 'fontsize', get(gca, 'fontsize'), ...
       'color', colors{i})
end
ylabel('fraction\newlinechose\newlineright', 'rotation', 0)
xlabel('#right - #left\newline     clicks')

set(gca, 'position', [0.38 0.39 0.52 0.53])
saveas(gcf, fullfile(analysispath, scriptname), 'svg')