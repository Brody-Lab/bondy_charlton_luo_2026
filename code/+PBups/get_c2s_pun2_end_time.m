function t = get_c2s_pun2_end_time(PEH)
% GET_C2S_PUN2_END_TIME return the time when the state "c2s_pun2" ends
%
% The c2s_pun2 state is triggered when the animal makes a side poke too
% soon after leaving the center port. After the punishment, the trial is
% restarted.
t = arrayfun(@(x) x.states.c2s_pun2, PEH, 'uni', 0);
t(cellfun(@isempty,t)) = {nan};
t = cellfun(@(x) max(x), t);