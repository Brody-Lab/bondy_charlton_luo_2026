clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
recording_ids = string(unique(T.recording_id));
%%
[spoke_s, clicks_off_s] = deal(cell(numel(recording_ids),1));
for i = 1:numel(recording_ids)
    trials = PBups.gettrials(recording_ids{i}(1:4), recording_ids{i}(6:15));
    stereoclick_s = T.stereoclick_time_s(T.recording_id == recording_ids(i));
    [~,ia,ib] = intersect(trials.stereoclick_s, stereoclick_s);
    assert(all(ib==sort(ib)))
    spoke_s{i} = trials.spoke_s(ia);
    clicks_off_s{i} = trials.clicks_off_s(ia);
end
T.clicks_off_s = cell2mat(clicks_off_s);
T.spoke_s = cell2mat(spoke_s);
writetable(T, fullfile(analysispath, [scriptname, '.csv']))
%%
deltat = T.spoke_s - T.movementtime_s;
deltat_hasnTc = deltat(~isnan(T.committime_s_M1));
deltat_nonTc = deltat(isnan(T.committime_s_M1));

mean(deltat_hasnTc)
mean(deltat_nonTc)

