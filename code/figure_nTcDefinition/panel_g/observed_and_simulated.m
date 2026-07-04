clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_18b_nTc', 'nTc_all.csv'), ...
    'delimiter', ',');
T.recording_id = categorical(string(T.recording_id));
%
T.left_click_times = cellfun(@str2num, T.left_click_times, 'UniformOutput', false);
T.right_click_times = cellfun(@str2num, T.right_click_times, 'UniformOutput', false);
T.choice = cellfun(@(x) strcmp(x, 'true'), T.choice);
T.R_minus_L = cellfun(@(R,L) numel(R)-numel(L), ...
    T.right_click_times, T.left_click_times);
T.commitment_time_s(T.commitment_timestep==0) = NaN;
T.commitment_timestep(T.commitment_timestep==0) = NaN;
Tsim = readtable(fullfile(TZL.analysis_data_path, 'analysis_2024_08_18b_nTc', 'simulated_nTc_all.csv'), ...
    'delimiter', ',');
Tsim.commitment_time_s(Tsim.commitment_timestep==0) = NaN;
Tsim.commitment_timestep(Tsim.commitment_timestep==0) = NaN;
T.simulated_commitment_timestep = Tsim.commitment_timestep;
T.simulated_choice = string(Tsim.choice)=="true";
T.simulated_commitment_time_s = Tsim.commitment_time_s;
save(fullfile(analysispath, [scriptname '.mat']), 'T')