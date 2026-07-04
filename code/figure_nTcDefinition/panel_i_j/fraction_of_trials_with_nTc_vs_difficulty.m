clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
nbins = 4;
T = readtable(fullfile(analysispath, "nTc_augmented.csv"), 'delimiter', ',');
Q = quantile(T.clicks_dur_s,0:1/3:1)
T = T(T.clicks_dur_s>Q(3),:);
T.nTc_obsv = T.nTc;
T.nTc_pred = T.nTc_sim;
T.recording_id = string(T.recording_id);
recording_ids = unique(T.recording_id);
nrecordings = numel(recording_ids);
G = discretize(T.absratediff, nbins);
x = splitapply(@mean, T.absratediff,G);
Y = struct;
for i = 1:nrecordings
    indices = T.recording_id == recording_ids(i);
    for cond = ["obsv", "pred"]
        colname = string(['nTc_' char(cond)]);
        has_nTc = ~isnan(T.(colname)(indices));
        binedges = quantile(T.absratediff(indices), 0:1/nbins:1);
        G = discretize(T.absratediff(indices),binedges);
        Y.(cond)(i,:) = splitapply(@mean,has_nTc, G);
    end
end
%
colors = UBT.colors;
close all
figure('pos', [100 100 300 325])

UBT.stylizeaxes
X = Y.pred;
ci = bootci(1e3, @mean, X);
UBT.shadeplot(x, ci(1,:), ci(2,:), 'facecolor', colors.pred)
plot(x, mean(X), '-', 'linewidth',1, 'color', colors.pred)

X = Y.obsv;
ci = bootci(1e3, @mean, X);
plot(x, mean(X),'o', 'linewidth',1, 'color', colors.obsv, 'markersize', 10)
for i = 1:nbins
    plot(x(i)*[1,1], ci(:,i), '-', 'linewidth', 1, 'color', colors.obsv)
end
ylim([0.17 0.85])
xlim([-0.05 1])

mdl = fitglm(T.absratediff, ~isnan(T.nTc_obsv), 'distribution', 'binomial');
pval = mdl.Coefficients.pValue(2);
text(0, 0.8, sprintf('p=%0.0e', pval), 'fontsize', get(gca, 'fontsize'))


xticks([0 1])
yticks([0.2:0.2:0.8])
ylabel(sprintf('trial fraction with \\color[rgb]{%f,%f,%f}nTc', colors.nTc))
xlabel(sprintf('|{\\color[rgb]{%f,%f,%f}#R} - {\\color[rgb]{%f,%f,%f}#L}|/({\\color[rgb]{%f,%f,%f}#R} + {\\color[rgb]{%f,%f,%f}#L})', ...
    colors.rightchoice, colors.leftchoice, colors.rightchoice, colors.leftchoice))
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))