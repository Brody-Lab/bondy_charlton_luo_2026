clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
nTc = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
load(fullfile(analysispath, ['firing_rates.mat']));
nTc = nTc(trial_in_recording==1,:);
firingrate_hz = firingrate_hz(trial_in_recording==1,:);
%%
nTc_step = round((nTc.committime_s_M1 - nTc.stereoclick_time_s)*100);
[ntrials, nsteps] = size(firingrate_hz)
X = nan(ntrials, 2*nsteps-1);
for i = 1:size(firingrate_hz,1)
    if ~isnan(nTc_step(i))       
        startidx = nsteps - nTc_step(i) + 1;
        endidx = startidx + nsteps - 1;
        X(i,startidx:endidx) = firingrate_hz(i,:);
    end
end
ci = nan(2,size(X,2));
ntrials_per_bin = sum(~isnan(X));
mintrials = 100;
for i = 1:size(ci,2)
    if ntrials_per_bin(i) > mintrials
        x = X(:,i);
        x = x(~isnan(x));
        ci(:,i) = bootci(1e3, @mean,x);
    end
    i
end
%%
nTc_step = round((nTc.committime_s_M1 - nTc.stereoclick_time_s)*100);
nperm = 1000;
avgperm = zeros(1,size(X,2));
for j = 1:nperm
    permuted_nTc_step = nTc_step;
    recording_ids = string(unique(nTc.recording_id));
    for i = 1:numel(recording_ids)
        trialindices = nTc.recording_id == recording_ids(i);
        filtered_nTc_step = nTc_step(trialindices);
        x = filtered_nTc_step(~isnan(filtered_nTc_step));
        x = x(randperm(length(x)));
        filtered_nTc_step(~isnan(filtered_nTc_step)) = x;
        permuted_nTc_step(trialindices) = filtered_nTc_step;
    end
    [ntrials, nsteps] = size(firingrate_hz);
    Xperm = nan(ntrials, 2*nsteps-1);
    for i = 1:size(firingrate_hz,1)
        if ~isnan(permuted_nTc_step(i))       
            startidx = nsteps - permuted_nTc_step(i) + 1;
            endidx = startidx + nsteps - 1;
            Xperm(i,startidx:endidx) = firingrate_hz(i,:);
        end
    end
    avgperm = avgperm+ nanmean(Xperm)/nperm;
    j
end
%%
t = (1:size(X,2))*0.01 - 1;
figure('pos', [1e2 1e2 430 330])
UBT.stylizeaxes
h(1) = UBT.shadeplot(t, ci(1,:), ci(2,:));
indices = ntrials_per_bin<mintrials;
avg = nanmean(X);
avg(indices) = NaN;
avgperm(indices) = NaN;
% plot(t, avg, 'k-', 'linewidth', 1)
h(2) = plot(t, avgperm, 'k--', 'linewidth', 1);
legend(h, ["observed 95% CI", "shuffled"])
xlim([-0.5, 0.5])
ylim([3.4 3.8])
ylabel('firing rate (hz)')
xlabel('time relative to nTc (s)')
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, scriptname))
%%
idx = ceil(nanmean(nTc_step));
figure
% subplot(2,1,1)
% UBT.stylizeaxes
% histogram(nTc.committime_s_M1 - nTc.stereoclick_time_s, 0:1/11:1)
% subplot(2,1,2)
UBT.stylizeaxes
colors = UBT.colors;
plot(timesteps_s, nanmean(firingrate_hz(~isnan(nTc_step),:)), 'linewidth', 1, 'color', colors.nTc)
plot(timesteps_s, nanmean(firingrate_hz(isnan(nTc_step),:)), 'k--', 'linewidth', 1)
xlabel('time from first click (s)')
