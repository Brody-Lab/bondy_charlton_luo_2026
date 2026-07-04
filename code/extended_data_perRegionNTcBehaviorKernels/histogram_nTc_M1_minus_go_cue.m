clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);

T = readtable(fullfile(analysispath, 'nTc_augemented.csv'), 'delimiter', ',');
figure('pos', [100 100 400 300])
UBT.stylizeaxes
x = T.committime_s_M1 - T.clicks_off_s;
x(x >0.5) = 0.51;
h = histogram(x, -1.05:0.05:0.55);
set(h, 'facecolor', 0.5*ones(1,3))
colors=UBT.colors;
regioncolors = UBT.brain_region_colors;
xlabel(sprintf('{\\color[rgb]{%f, %f, %f}nTc}-{\\color[rgb]{%f, %f, %f}M1} %s go cue (s)', ...
    colors.nTc, regioncolors.M1, char(hex2dec('2212'))))
title(sprintf('Trials with {\\color[rgb]{%f, %f, %f}nTc}-{\\color[rgb]{%f, %f, %f}M1}', ...
    colors.nTc, regioncolors.M1))
xticks([-1:0.5:0.5])
xlim([-1.1, 0.6])
theylim = ylim;
theylim(1) = -20;
ylim(theylim)
ylabel('Count')
exportgraphics(gcf, fullfile(analysispath, [scriptname '.pdf']), 'ContentType', 'Vector')
saveas(gcf, fullfile(analysispath, [scriptname '.fig']))
