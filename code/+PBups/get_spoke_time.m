function t = get_spoke_time(PEH, PD, cpoke_req_end_s)
% GET_SPOKE_TIME return time when the animal entered the side poke
%
% Because animals typically have a center_2_side_gap_2 state between
% cpoke_out and reward/punishment, their first lick after the end of the
% center2_side_gap2 state is considered to be its choice. The side poke is
% the first time when a lick has occurred at the ultimately chosen port,
% and no lick to the opposite port intervenes between this port and the
% chosen port.
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%   PD
%       Structure containing the protocol data informaton
%
%   cpoke_req_end_s
%       A vector of times for each trial when the required duration for
%       cpoke in has ended
%
%=OUTPUT
%
%   t
%       A numeric array of the times when the animal side-poked
    t_clicks_off = PBups.get_clicks_off_time(PEH);
    t_feedback = PBups.get_feedback_time(PEH);
    pokedR = (PD.sides=='r') == PD.hits;
    t = nan(numel(PEH),1);
    for i = 1:numel(PEH)
        if isnan(t_feedback(i))
            continue
        end
        r_pokes = PEH(i).pokes.R;
        l_pokes = PEH(i).pokes.L;
        idx = isnan(r_pokes(:,2));
        r_pokes(idx,2) = r_pokes(idx,1);
        idx = isnan(l_pokes(:,2));
        l_pokes(idx,2) = l_pokes(idx,1);
        % determine the earliest time after which side pokes are accepted
        if isfield(PEH(i).states, 'center_2_side_gap_2') && ~isempty(PEH(i).states.center_2_side_gap_2)
            earliest_valid_spoke_time = max(PEH(i).states.center_2_side_gap_2);
            earliest_valid_spoke_time = max(cpoke_req_end_s(i), earliest_valid_spoke_time);
        else
            earliest_valid_spoke_time = cpoke_req_end_s(i);
        end
        % find the pokes that occur after the end of clicks off and before
        % feedback        
        idx = r_pokes(:,2) > earliest_valid_spoke_time & r_pokes(:,1) <= t_feedback(i);
        r_pokes = r_pokes(idx,:);
        idx = l_pokes(:,2) > earliest_valid_spoke_time & l_pokes(:,1) <= t_feedback(i);
        l_pokes = l_pokes(idx,:);
        if pokedR(i)
            if ~isempty(l_pokes)
                r_pokes(r_pokes(:,2)<max(l_pokes(:,2)),:) = [];
            end
            if isempty(r_pokes)
                t(i) = t_feedback(i);
            else
                t(i) = min(r_pokes(:,1));
            end
        else
            if ~isempty(r_pokes)
                l_pokes(l_pokes(:,2)<max(r_pokes(:,2)),:) = [];
            end
            if isempty(l_pokes)
                t(i) = t_feedback(i);
            else
                t(i) = min(l_pokes(:,1));
            end      
        end
    end
    