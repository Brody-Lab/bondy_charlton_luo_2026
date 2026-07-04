function [Trials,missing] = add_Tc_to_Trials(Trials) 

% add commitment times inferred by MMDDM to a Trials structure of an
% UberPhys Cells file
%
% Add the commitment times inferred by MMDDM to a Trials structure (as a field of the "Trials.stateTimes" field).
% Removes any trials from the Trials structure and from the event-aligned spike times not present in the
% commitment times table (these are incomplete trials to which the model
% cannot be fit).
%
% ARGUMENT
%
%   Trials: a scalar struct


    %% parse and validate inputs
    if ~isstruct(Trials) || ~isfield(Trials,'stateTimes') || ~isfield(Trials,'sessid') || ...
            ~isfield(Trials,'leftBups') || ~isfield(Trials,'rightBups') 
        error('Trials structure is missing some needed fields.');
    end
    % load commitment times table
    recording_id = strcat(Trials.rat(1),'_',strrep(string(Trials.sess_date(1)),'-','_'));
    T = uberphys.get_commitment_times(recording_id);                


    %% get stereoclick and commitment fields from table
    timestamp = round(T.stereoclick_time_s,2);
    commit_fields = T.Properties.VariableNames(contains(T.Properties.VariableNames,"commit"));
    
    %% get commitment times for each trial, matching up trials by first click
    nTrials = numel(Trials.leftBups);        
    Trials.stateTimes.commitment_s = NaN(nTrials,1);
    Trials = add_first_click_state_to_Trials(Trials);    
    Trials.stateTimes.first_click = round(Trials.stateTimes.first_click,2);
    [idx_table,idx_trials] = find(timestamp==Trials.stateTimes.first_click');   
    missing=~ismember(1:nTrials,idx_trials);    
    if any(diff(idx_table)<1)
        error('Duplicates of a trial in the commitment times table!?!');
    end
    if any( T.gamma(idx_table) ~= Trials.gamma(idx_trials) )
        error('At least one trial matches for first click time but not gamma.');
    end    
    for f=1:numel(commit_fields)                 
        Trials.stateTimes.(commit_fields{f}) = NaN(nTrials,1);
        commit = round(T.(commit_fields{f})(idx_table),3);
        if any( commit < Trials.stateTimes.first_click(idx_trials) )
            error('Commitment before the first click on at least one trial.');
        end

        Trials.stateTimes.(commit_fields{f})(idx_trials) = commit;
    end   

    
    %% report missing trials and remove them
    if any(missing)
        fprintf('%d trials not found in the commitment table. Removing them.\n',sum(missing));
        Trials = remove_trials(Trials,missing);  
    end
    
    %% report fraction of trials in which threshold not reached
    nans = sum(isnan(Trials.stateTimes.committime_s_all));
    if nans
        fprintf('%d trials (%d%%) in which commitment probability did not reach threshold when using all regions.\n',nans,round(100*nans/numel(Trials.stateTimes.committime_s_all)));
    end
    
    if any(~ismember(timestamp,Trials.stateTimes.first_click))
        warning('%d Trials in the commitment times table that could not be matched to a trial.',sum(~ismember(timestamp,Trials.stateTimes.first_click)));
    end
    
end