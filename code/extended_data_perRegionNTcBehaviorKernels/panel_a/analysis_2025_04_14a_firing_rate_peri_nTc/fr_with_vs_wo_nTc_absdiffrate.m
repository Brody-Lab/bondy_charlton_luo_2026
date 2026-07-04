clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable('C:\Users\Thomas Zhihao Luo\uberphys_paper\figure_nTcDefinition\panel_h\nTc_augmented.csv')
% nTc = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
load(fullfile(analysispath, ['firing_rates.mat']));
T = T(trial_in_recording==1,:);
firingrate_hz = firingrate_hz(trial_in_recording==1,:);
%%
t = repmat(timesteps_s,size(T,1),1);
nTc_s = T.committime_s_M1 - T.stereoclick_time_s;
has_nTc = repmat(~isnan(nTc_s), 1, size(firingrate_hz,2));
absdiffrate = repmat(T.absratediff, 1, size(firingrate_hz,2));

t = t(~isnan(firingrate_hz));
has_nTc = has_nTc(~isnan(firingrate_hz));
absdiffrate = absdiffrate(~isnan(firingrate_hz));
y = firingrate_hz(~isnan(firingrate_hz));

mdl = fitlm([has_nTc, t, absdiffrate], y, 'interactions');
C = mdl.Coefficients;

C.Properties.RowNames{2} = [C.Properties.RowNames{2} '  (has nTc)'];
C.Properties.RowNames{3} = [C.Properties.RowNames{3} '  (time from 1st click)'];
C.Properties.RowNames{4} = [C.Properties.RowNames{4} '  (abs. click rate diff.)'];
writetable(C, fullfile(analysispath, [scriptname '.csv']), 'delimiter', ',', 'WriteRowNames',true)
%%
nbins_ard = 4;
edges = quantile(T.absratediff, 0:1/nbins_ard:1);
group_ard = discretize(T.absratediff, edges);
timebinedges_s = 0:0.1:0.8;
nbins_time = numel(timebinedges_s)-1;
[ynTc, ynot] = deal(nan(nbins_ard, nbins_time));
nTc_s = T.committime_s_M1 - T.stereoclick_time_s;
nTc_step = ceil((T.committime_s_M1 - T.stereoclick_time_s)*100);
r = firingrate_hz;
indices = repmat(1:100, size(r,1),1) > nTc_step;
r(indices) = NaN;

has_nTc = ~isnan(nTc_step);
for i = 1:nbins_ard
    for j = 1:nbins_time
        indices = (group_ard == i) & ...
                  (timesteps_s >= timebinedges_s(j) & timesteps_s < timebinedges_s(j+1));
        ynTc(i,j) = nanmean(firingrate_hz(indices & has_nTc));
        ynot(i,j) = nanmean(firingrate_hz(indices & ~has_nTc));
    end
end
figure
imagesc(ynTc-ynot); colorbar
%%
T.rat = cellfun(@(x) string(x(1:4)), T.recording_id);
splitapply(@mean, T.absratediff, findgroups(T.rat))
%%
nbins_ard = 6;
group_ard = nan(size(T,1),1);
T.rat = cellfun(@(x) string(x(1:4)), T.recording_id);
for rat = unique(T.rat)'
    indices = T.rat == rat;
    edges = quantile(T.absratediff(indices), 0:1/nbins_ard:1);
    group_ard(indices) = discretize(T.absratediff(indices), edges);
end
r = firingrate_hz;
indices = repmat(1:100, size(r,1),1) > nTc_step;
r(indices) = NaN;
has_nTc = ~isnan(nTc_step);
colors = UBT.colors;
figure('pos', [300 300 300*nbins_ard, 300])
ax = [];
for i = 1:nbins_ard
    ax(i) = subplot(1,nbins_ard,i);
    UBT.stylizeaxes
    plot(timesteps_s, nanmean(r(has_nTc & group_ard==i,:)), 'color', colors.nTc, 'linewidth', 1)
    plot(timesteps_s, nanmean(firingrate_hz(~has_nTc & group_ard==i,:)), 'k', 'linewidth', 1)
    xlim([0 0.8])
    % ylim([3.5 5])
end
linkaxes(ax,'y')
%%
nbins_ard = 8;
group_ard = nan(size(T,1),1);
T.rat = cellfun(@(x) string(x(1:4)), T.recording_id);
for rat = unique(T.rat)'
    indices = T.rat == rat;
    edges = quantile(T.absratediff(indices), 0:1/nbins_ard:1);
    group_ard(indices) = discretize(T.absratediff(indices), edges);
end
x_ard = splitapply(@median, T.absratediff, group_ard);
r = firingrate_hz;
indices = repmat(1:100, size(r,1),1) > nTc_step;
r(indices) = NaN;
has_nTc = ~isnan(nTc_step);
colors = UBT.colors;
[ynTc, ynot] = deal(nan(nbins_ard,1));
for i = 1:nbins_ard
    ynTc(i) = nanmean(nanmean(r(has_nTc & group_ard==i,:)));
    ynot(i) = nanmean(nanmean(firingrate_hz(~has_nTc & group_ard==i,:)));
end
close all
figure('pos', [100 100 400 300])
UBT.stylizeaxes
plot(x_ard, ynTc, 'o-', 'color', colors.nTc, 'linewidth',1)
plot(x_ard, ynot, 'ko-', 'linewidth', 1)
ylabel('spikes/s')
xlabel('difficult <- |(R-L)/(R+L)| -> easy trials')
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))