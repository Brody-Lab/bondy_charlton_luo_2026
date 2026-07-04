clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
load(fullfile(analysispath, 'variance_explained.mat'));
%%
T.multimode = cellfun(@unique, T.multimode);
T.recording_id = cellfun(@unique, T.recording_id);
%%
recording_ids = unique(models.recording_id);
S = struct;
for j = 1:numel(recording_ids)
    index_multimode = T.recording_id == recording_ids(j) & T.multimode == 1;
    index_singlemode = T.recording_id == recording_ids(j) & T.multimode == 0;
    S.R2_timestep_singlemode{j,1} = T.R2_timestep{index_singlemode};
    S.R2_timestep_multimode{j,1} = T.R2_timestep{index_multimode};
    S.R2_trial_singlemode{j,1} = T.R2_trial{index_singlemode};
    S.R2_trial_multimode{j,1} = T.R2_trial{index_multimode};
    nneurons = numel(T.brainarea{index_multimode});
    S.recording_id{j,1} = repmat(T.recording_id(index_multimode), nneurons,1);
    S.multimode{j,1} = repmat(T.multimode(index_multimode), nneurons,1);
    S.brainarea(j) = T.brainarea(index_multimode);
    S.probeserial(j) = T.probeserial(index_multimode);
    S.index_in_probe(j) = T.index_in_probe(index_multimode);
end
for v = string(fieldnames(S))'
    S.(v) = vertcat(S.(v){:});
end
S = struct2table(S);
%%
clc
fprintf('\nThe out-of-sample fraction of variance across time steps explained by MMDDM is %f', ...
    mean(S.R2_timestep_multimode))
fprintf('\nThe out-of-sample fraction of variance across time steps explained by DDM is %f', ...
    mean(S.R2_timestep_singlemode));
fprintf('\nThe difference is %f (p=%e)', ...
    mean(S.R2_timestep_multimode-S.R2_timestep_singlemode), ...
    signrank(S.R2_timestep_multimode, S.R2_timestep_singlemode));