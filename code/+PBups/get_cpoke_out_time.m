% GET_CPOKE_OUT_TIME return time when the animal withdrew from the center
% poke
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%   PD
%       structure containing protocol data
%
%   t_spoke_or_sessid
%       Time when the side poke was made
%=OUTPUT
%
%   t
%       A numeric array of the times when the animal stopped fixating
function t = get_cpoke_out_time(PEH, PD, t_spoke_or_sessid)
    if numel(t_spoke_or_sessid) == numel(PD.hits)
        t_spoke = t_spoke_or_sessid;
    else
        sessid = t_spoke_or_sessid;
        nose_in_center_s = get_nose_in_center_time(sessid);
        t_cpoke_in = get_cpoke_in_time(PEH);
        cpoke_req_end = t_cpoke_in + unique(nose_in_center_s);
        t_spoke = get_spoke_time(PEH, PD, cpoke_req_end);
    end        
    t_break = PBups.get_violation_time(PEH);
    t = nan(size(PEH));
    for i = 1:numel(PEH)
        if ~isempty(PEH(i).pokes.C)
            t_cpoke = PEH(i).pokes.C(:,2);
            if ~isnan(t_spoke(i)) % made a side poke
                t_cpoke = max(t_cpoke(t_cpoke<t_spoke(i)));
                if numel(t_cpoke) == 1
                    t(i) = t_cpoke;
                else
                    % the animal kept its nose in the center port while
                    % reaching for the side poke with its paw.
                end
            elseif ~isnan(t_break(i)) % violation
                t(i) = t_break(i);
            else % no side poke, no violation
                t(i) = max(t_cpoke);
            end
            t_feedback = min([PEH(i).states.hit_state(:); PEH(i).states.error_state(:)]);
            if ~isempty(t_feedback)
                if t_feedback < t(i)
                    t(i) = NaN;
                end
            end
        end
    end