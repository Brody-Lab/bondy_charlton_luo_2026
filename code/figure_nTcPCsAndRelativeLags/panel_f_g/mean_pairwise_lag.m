clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
nTc = readtable(fullfile(UBT.processed_data_path, 'nTc.csv'), 'delimiter', ',');
nTc.recording_id = string(nTc.recording_id);
brainregions = ["M1", "ADS", "dmFC", "MGB", "mPFC", "TS", "HPC", "S1", "BLA", "NAc"];
nregions = numel(brainregions);
npairs = nchoosek(nregions,2);
X = nan(nregions);
Xboot = cell(nregions);
nsamples = 1e3;
[Xboot{:}] = deal(nan(nsamples,1));
for i = 1:nregions-1
    for j = i+1:nregions
        t1 = nTc.(['committime_s_' brainregions{i}]);
        t2 = nTc.(['committime_s_' brainregions{j}]);
        indices = ~isnan(t1) & ~isnan(t2);
        X(i,j) = mean(t1(indices) - t2(indices));
        X(j,i) = -X(i,j);
        % compute bootstrap samples
        recording_ids = unique(nTc.recording_id(indices));
        nsessions = numel(recording_ids);
        for b = 1:nsamples
            sampled_nTc_diff = 0;
            sampled_recording_ids = datasample(recording_ids,nsessions);
            sampled_ntrials = 0;
            for m = 1:nsessions
                trialindices = find(nTc.recording_id == sampled_recording_ids(m) & indices);
                ntrials = numel(trialindices);
                sampled_ntrials = sampled_ntrials + ntrials;
                sampled_trials = datasample(trialindices, ntrials);
                sampled_nTc_diff = sampled_nTc_diff + sum(t1(trialindices) - t2(trialindices));
            end
            Xboot{i,j}(b) = sampled_nTc_diff/sampled_ntrials;
        end
        Xboot{j,i} = -Xboot{i,j};
        fprintf('\n%i %i',i,j)
    end
end
y = nanmean(X);
ci = nan(2,nregions);
for i = 1:nregions
    diffboot = nan(nsamples,1);
    for b = 1:nsamples
        diffboot(b) = nanmean(cellfun(@(x) x(b), Xboot(:,i)));
    end
    ci(1,i) = 2*y(i) - quantile(diffboot, 0.975);
    ci(2,i) = 2*y(i) - quantile(diffboot, 0.025);
end
save(fullfile(analysispath, [scriptname '.mat']), 'X', 'Xboot', 'ci', 'brainregions')