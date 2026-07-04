function [t_feedback, t_error, t_left_reward, t_right_reward] = get_feedback_time(PEH)
% GET_FEEDBACK_TIME return the time in each when feedback is given
%
%=INPUT
%
%   PEH
%       parsed event history
%
%=OUTPUT
%
%   t_feedback
%       time in each trial when feedback is provided
%
%   t_error
%       time in each trial when the state "error_state1" state begins
%
%   t_left_reward
%       time in each trial when the state "left_reward" state begins
%
%   t_right_reward
%       time in each trial when the state "right_reward" state begins

if isfield(PEH(1).waves, 'direct_left_reward')
    t_left_reward = arrayfun(@(x) x.waves.direct_left_reward, PEH, 'uni', 0);
    t_right_reward = arrayfun(@(x) x.waves.direct_right_reward, PEH, 'uni', 0);
    t_error = arrayfun(@(x) x.states.error_state1, PEH, 'uni', 0);
    
    t_left_reward(cellfun(@isempty, t_left_reward)) = {nan};
    t_right_reward(cellfun(@isempty, t_right_reward)) = {nan};
    t_error(cellfun(@isempty, t_error)) = {nan};
    
    t_left_reward = cellfun(@min, t_left_reward);
    t_right_reward = cellfun(@min, t_right_reward);
    t_error = cellfun(@min, t_error);
    
    n_feedback_per_trial = sum(~isnan([t_left_reward, t_right_reward, t_error]),2);
    if ~all(n_feedback_per_trial <= 1)
        warning('multiple feedback per trial')
    end
else
    t_reward = arrayfun(@(x) x.waves.direct_reward, PEH, 'uni', 0);
    t_error = arrayfun(@(x) x.states.error_state1, PEH, 'uni', 0);
    
    t_reward(cellfun(@isempty, t_reward)) = {nan};
    t_error(cellfun(@isempty, t_error)) = {nan};
    
    t_reward = cellfun(@min, t_reward);
    t_error = cellfun(@min, t_error);
    
    n_feedback_per_trial = sum(~isnan([t_reward, t_error]),2);
    if ~all(n_feedback_per_trial <= 1)
        warning('multiple feedback per trial')
    end
    rewardside = nan(size(t_reward));
    for i = 1:numel(PEH)
        first_poke_L = min(PEH(i).pokes.L(:));
        first_poke_R = min(PEH(i).pokes.R(:));
        if ~isempty(first_poke_L) && isempty(first_poke_R)
            rewardside(i) = 0;
        elseif isempty(first_poke_L) && ~isempty(first_poke_R)
            rewardside(i) = 1;
        elseif ~isempty(first_poke_L) && ~isempty(first_poke_R)
            if first_poke_L < first_poke_R
                rewardside(i) = 0;
            else
                rewardside(i) = 1;
            end
        end
    end
    [t_left_reward, t_right_reward] = deal(nan(size(t_reward)));
    t_left_reward(rewardside==0) = t_reward(rewardside==0);
    t_right_reward(rewardside==1) = t_reward(rewardside==1);
end
t_feedback = min([t_left_reward, t_right_reward, t_error], [], 2);
