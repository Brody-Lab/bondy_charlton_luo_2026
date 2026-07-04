clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
recording_ids = string(unique(T.recording_id));
[nL, nR, clicks_dur_s] = deal(cell(numel(recording_ids),1));
for i = 1:numel(recording_ids)
    trials = PBups.gettrials(recording_ids{i}(1:4), recording_ids{i}(6:15));
    R = cellfun(@numel,trials.rightclick_s)-1;
    L = cellfun(@numel,trials.leftclick_s)-1;
    trialdur_s = trials.cpoke_req_end_s-trials.stereoclick_s;
    stereoclick_s = T.stereoclick_time_s(T.recording_id == recording_ids(i));
    [~,ia,ib] = intersect(trials.stereoclick_s, stereoclick_s);
    assert(all(ib==sort(ib)))
    nR{i} = R(ia);
    nL{i} = L(ia);
    clicks_dur_s{i} = trialdur_s(ia);
    i
end
T.n_L_clicks = cell2mat(nL);
T.n_R_clicks = cell2mat(nR);
T.clicks_dur_s = cell2mat(clicks_dur_s);
Tsim = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc_simulated.csv'), 'delimiter', ',');
T.nTc = T.committime_s_M1 - T.stereoclick_time_s;
T.nTc_sim = Tsim.simulated_committime_s_M1 - T.stereoclick_time_s;
T.rat = cellfun(@(x) string(x(1:4)), T.recording_id);
T.absratediff = abs(T.n_R_clicks-T.n_L_clicks)./(T.n_R_clicks+T.n_L_clicks);
writetable(T, fullfile(analysispath, [scriptname, '.csv']))