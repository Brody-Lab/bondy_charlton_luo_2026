function t = get_wait_for_cpoke_time(PEH)
% GET_WAIT_FOR_CPOKE_TIME return the time in each trial when the state
% "wait_for_cpoke" begins
%
%=INPUT
%
%   PEH
%       parsed event history
%
%=OUTPUT
%
%   t
%       A vector of  the time in each trial when the state
%       "wait_for_cpoke" begins
t = nan(size(PEH));
for i = 1:numel(PEH)
    if ~isempty(PEH(i).states.wait_for_cpoke1)
        t(i) = PEH(i).states.wait_for_cpoke1(1);
    end
end
