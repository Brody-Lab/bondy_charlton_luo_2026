clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
models = readtable(fullfile(TZL.analyses_path, analysisname, 'models.csv'), 'delimiter',',');
models.datapath = string(TZL.cup2windows(models.datapath))
models.outputpath = string(TZL.cup2windows(models.outputpath))
models.recording_id = string(TZL.cup2windows(models.recording_id))
models.multimode = models.fit__;
[~, sortindex] = sort(models.recording_id);
models = models(sortindex,:);
%%
nmodels = size(models,1);
R2_timestep = cell(nmodels,1);
R2_trial = cell(nmodels,1);
recording_id = cell(nmodels,1);
multimode = cell(nmodels,1);
brainarea = cell(nmodels,1);
probeserial = cell(nmodels,1);
index_in_probe = cell(nmodels,1);
parfor j = 1:size(models,1)
    % clear neurons trials expectedemissions
    S1 = load(models.datapath{j});
    trials = S1.trials;
    neurons = S1.neurons;
    S = load(fullfile(models.outputpath{j}, 'crossvalidation', 'expectedemissions.mat'));
    expectedemissions = S.expectedemissions;
    ntrials = numel(trials);
    nneurons = numel(trials{1}.spiketrains);
    recording_id{j} = repmat(models.recording_id(j), nneurons,1);
    multimode{j} = repmat(models.multimode(j), nneurons,1);
    brainarea{j} = cellfun(@(neuron) string(neuron.brainarea), neurons);
    probeserial{j} = cellfun(@(neuron) neuron.probeserial, neurons);
    index_in_probe{j} = cellfun(@(neuron) neuron.index_in_probe, neurons);
    obsv = cell(nneurons,1);
    for n = 1:nneurons
        obsv{n} = cellfun(@(trial) double(trial.spiketrains{n})', trials, 'uni', 0);
    end
    pred = cell(nneurons,1);
    for n = 1:nneurons
        pred{n} = cell(ntrials,1);
        for i = 1:ntrials
            pright = expectedemissions{1}{i}.rightchoice;
            pred{n}{i} = expectedemissions{1}{i}.spiketrain_rightchoice{n}*pright + ...
                            expectedemissions{1}{i}.spiketrain_leftchoice{n}*(1-pright);
        end
    end
    R2_timestep{j} = nan(nneurons,1);
    R2_trial{j} = nan(nneurons,1);
    for n = 1:nneurons
        obsvcat = cell2mat(obsv{n});
        predcat = cell2mat(pred{n});
        ss_total = sum((obsvcat-mean(obsvcat)).^2);
        ss_res = sum((obsvcat-predcat).^2);
        R2_timestep{j}(n) = 1 - ss_res/ss_total;
    
        obsvtrial = cellfun(@mean, obsv{n});
        predtrial = cellfun(@mean, pred{n});
        ss_total = sum((obsvtrial-mean(obsvtrial)).^2);
        ss_res = sum((obsvtrial-predtrial).^2);
        R2_trial{j}(n) = 1 - ss_res/ss_total;
    end
    fprintf('\n %i', j)
end
T = struct;
T.R2_timestep = R2_timestep;
T.R2_trial = R2_trial;
T.recording_id = recording_id;
T.multimode = multimode;
T.brainarea = brainarea;
T.probeserial = probeserial;
T.index_in_probe = index_in_probe;
T = struct2table(T)
save(fullfile(analysispath, [scriptname '.mat']), 'T', 'models')