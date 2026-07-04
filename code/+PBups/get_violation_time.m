% get_violation_time return time when the animal broke_fixation
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%=OUTPUT
%
%   t
%       A numeric array of the times when the animal broke fixation

function t = get_violation_time(PEH)

    t = arrayfun(@(x) x.states.violation_state, PEH, 'uni', 0);
    t(cellfun(@isempty, t)) = {nan};
    t = cellfun(@(x) min(x), t);