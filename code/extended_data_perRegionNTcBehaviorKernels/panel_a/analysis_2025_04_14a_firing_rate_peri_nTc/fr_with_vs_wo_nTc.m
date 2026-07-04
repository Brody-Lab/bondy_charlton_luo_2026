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
close all
nTc_step = ceil((T.committime_s_M1 - T.stereoclick_time_s)*100);
has_nTc = ~isnan(nTc_step);
colors = UBT.colors;

ynTc = firingrate_hz(has_nTc,:);
indices = repmat(1:100, size(y,1),1) > nTc_step(has_nTc);
ynTc(indices) = NaN;
ynot = firingrate_hz(~has_nTc,:);
[cinot, cinTc] = deal(nan(2,size(firingrate_hz,2)));
for t = 1:numel(timesteps_s)
    x = ynTc(:,t);
    x = x(~isnan(x));
    cinTc(:,t) = bootci(1e3, @mean, x);
    x = ynot(:,t);
    x = x(~isnan(x));
    cinot(:,t) = bootci(1e3, @mean, x);
    t
end
%%
close all
figure('pos', [100 100 300 300])
UBT.stylizeaxes
UBT.shadeplot(timesteps_s, cinot(1,:), cinot(2,:))
UBT.shadeplot(timesteps_s, cinTc(1,:), cinTc(2,:), 'facecolor', colors.nTc, 'facealpha', 0.3)
h1 = plot(timesteps_s, nanmean(ynot), 'k--', 'linewidth', 1.5);
h2 = plot(timesteps_s, nanmean(ynTc), '-', 'linewidth', 1, 'color', colors.nTc);

xlabel('time from first click (s)')
xlim([-0.02, 0.8])
ylim([3.4 4.6])
xticks([0 0.8])
ylabel('spikes/s')
% legend([h1 h2], ["no nTc", "has nTc"], 'location', 'northeast')
text(0.4, 4.5, 'no nTc', 'fontsize', get(gca, 'fontsize'))
text(0.4, 4.3, 'has nTc', 'fontsize', get(gca, 'fontsize'), 'color', colors.nTc)

print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))

