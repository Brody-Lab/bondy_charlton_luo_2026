clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(analysispath, "nTc_augmented.csv"), 'delimiter', ',');
nbins_dur = 3;
nbins_ard = 4;
close all
figure('pos', [100 100 450 320])
UBT.stylizeaxes
edges = quantile(T.clicks_dur_s, 0:1/nbins_dur:1);
G_dur = discretize(T.clicks_dur_s, edges);
edges = quantile(T.absratediff, 0:1/nbins_ard:1);
G_ard = discretize(T.absratediff, edges);
x_ard = splitapply(@mean, T.absratediff, G_ard);
f = @median;
corder = colororder;
colors = UBT.colors;
colorsim = corder(5,:);
for i = 1:nbins_dur
    [y, ysim] = deal(nan(nbins_ard,1));
    cisim = nan(nbins_ard,2);
    ciobs = nan(nbins_ard,2);
    for j = 1:nbins_ard
        indices = G_dur == i & G_ard == j;
        nTc_ij = T.nTc(indices);
        nTc_ij = nTc_ij(~isnan(nTc_ij));
        y(j) = f(nTc_ij);
        ciobs(j,:) = bootci(1e3, f, nTc_ij);

        nTc_ij = T.nTc_sim(indices);
        nTc_ij = nTc_ij(~isnan(nTc_ij));
        ysim(j) = f(nTc_ij);
        cisim(j,:) = bootci(1e3, f, nTc_ij);
    end
    hsim = UBT.shadeplot(x_ard, cisim(:,1), cisim(:,2), 'facecolor', colorsim);
    plot(x_ard, ysim, '-', 'linewidth',2, 'color', colorsim)
    for j = 1:nbins_ard
        hobsv = plot(x_ard(j)*[1,1], ciobs(j,:), 'k-', 'linewidth', 1);
    end
    plot(x_ard, y, 'ko')
end
legend([hobsv, hsim], ["data 95% CI", "simulation"], 'location', 'southeast')
xlim([0 1])
% ylim([0.5 0.65])
xticks(xlim)
xlabel('difficult <-- |(R-L)/(R+L)| --> easy trials')
ylabel('nTc relative to first click (s)', 'color', colors.nTc)
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))