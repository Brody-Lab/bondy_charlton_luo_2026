clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
nTc = readtable(fullfile(UBT.processed_data_path, 'nTc.csv'), 'delimiter', ',');
nTc.recording_id = string(nTc.recording_id);
nneurons_fit = readtable(fullfile(UBT.processed_data_path, 'nneurons_fit_in_each_region.csv'), ...
    'delimiter', ',');
brainregions = ["M1", "ADS", "dmFC", "MGB", "mPFC", "TS", "HPC", "S1", "BLA", "NAc"];
nregions = numel(brainregions);
[phat, phat_SE] = deal(nan(nregions,1));
nsamples = 1e3;
for i = 1:nregions
    recording_with_neurons = nneurons_fit.recording_id(nneurons_fit.(brainregions(i)) > 0);
    trialindices = ismember(nTc.recording_id, recording_with_neurons);
    nTc_i = nTc.(['committime_s_' brainregions{i}])(trialindices);
    recording_id_i = nTc.recording_id(trialindices);
    hasntc = ~isnan(nTc_i);
    phat(i) = sum(hasntc) / numel(hasntc);
    nsessions = numel(recording_with_neurons);
    sampled_phat = nan(nsamples,1);
    for b = 1:nsamples
        sampled_recording_ids = datasample(recording_with_neurons,nsessions);
        sampled_ntrials = 0;
        sampled_nnTc = 0;
        for m = 1:nsessions
            bootindices = find(recording_id_i == sampled_recording_ids(m));
            sampled_ntrials = sampled_ntrials + numel(bootindices);
            sampled_indices = datasample(bootindices, numel(bootindices));
            sampled_nnTc = sampled_nnTc + sum(hasntc(sampled_indices));
        end
        sampled_phat(b) = sampled_nnTc/sampled_ntrials;
    end
    phat_SE(i) = sqrt(1/(nsamples-1))*sum((sampled_phat - phat(i)).^2);
    i
end
save(fullfile(analysispath, [scriptname '.mat']), 'brainregions', 'phat', 'phat_SE');
%%
[sorted_phat, sortindices] = sort(phat, 'descend');
sorted_phat_SE = phat_SE(sortindices);
sorted_regions = brainregions(sortindices);
figure('pos', [100 100 400 400])
UBT.stylizeaxes
colors = UBT.brain_region_colors;
for i = 1:nregions
    bar(i,sorted_phat(i), 'edgecolor', 'none', 'FaceColor',colors.(sorted_regions(i)))
    plot(i*[1,1], sorted_phat(i) + [-1 1]*sorted_phat_SE(i), ...
        'color', colors.(sorted_regions(i)), 'linewidth',3)
    custom_xticklabels{i} = sprintf('\\color[rgb]{%f, %f, %f}{\\bf{%s}}', ...
        colors.(sorted_regions(i)), sorted_regions(i));
end
ylabel('Fraction of trials with nTc')
xlabel('Brain region used')
xticks(1:nregions)
xticklabels(custom_xticklabels)
set(gca, 'XTickLabelRotation', 90)
xlim([0 nregions+0.5])
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
savefig(gcf, fullfile(analysispath, [scriptname '.fig']))