clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
nTc = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
sessions = UBT.tabulatesessions;
sessions = sessions(ismember(sessions.recording_id, nTc.recording_id),:);
nsessions = size(sessions,1);
%%
dt = 0.01;
t_end = 1;
timesteps_s = dt:dt:t_end;
ntimesteps = numel(timesteps_s);
[firingrate_hz,trial_in_recording] = deal(cell(nsessions,1));
%%
for i = 20:size(sessions,1)
    Cells = uberphys.load_Cells_files(sessions.recording_id{i});
    trials = PBups.gettrials(sessions.rat{i}, sessions.date{i})
    filtered_nTc = nTc(string(nTc.recording_id) == sessions.recording_id(i),:);
    indices = ismember(trials.stereoclick_s, filtered_nTc.stereoclick_time_s);
    assert(all(trials.stereoclick_s(indices)==filtered_nTc.stereoclick_time_s));
    spks = cell(numel(Cells),1);
    nneurons = 0;
    for j = 1:numel(Cells)
        indices = uberphys.apply_inclusion_criteria(Cells{j});
        nneurons = nneurons + sum(indices);
        spks{j} = cell2mat(Cells{j}.raw_spike_time_s(indices));
    end
    spks = sort(cell2mat(spks));
    ntrials = size(filtered_nTc,1);
    firingrate_hz{i} = nan(ntrials, ntimesteps);
    trial_in_recording{i} = false(ntrials,1);
    for m = 1:ntrials
        tref = filtered_nTc.stereoclick_time_s(m);
        filtered_spks = spks(spks > tref & spks<(tref + t_end));
        if sum(filtered_spks) > 0
            trial_in_recording{i}(m) = true;
        end
        lastindex = ceil((filtered_nTc.movementtime_s(m) - tref)/dt);
        for k = 1:min(lastindex,ntimesteps)
            bin_s = tref + [k-1, k]*dt;
            firingrate_hz{i}(m,k) = sum(filtered_spks >= bin_s(1) & filtered_spks < bin_s(2));
        end
        fprintf('\n%i-%i',i,m)
    end
    firingrate_hz{i} = firingrate_hz{i}/nneurons/dt;
end
firingrate_hz = cell2mat(firingrate_hz);
trial_in_recording = cell2mat(trial_in_recording);
save(fullfile(analysispath, [scriptname '.mat']), "firingrate_hz", "trial_in_recording", "timesteps_s")
%%
tic
for t = (0:0.01:1)
    sum(spks > 7000 & spks<(7000 + t));
end
toc
%%
tic
filtered_spks = spks(spks > 7000 & spks<(7000 + 1));
for t = (0:0.01:1)
    sum(filtered_spks > 7000 & filtered_spks<(7000 + t));
end
toc