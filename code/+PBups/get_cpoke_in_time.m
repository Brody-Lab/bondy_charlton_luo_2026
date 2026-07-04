% GET_CPOKE_IN_TIMES return time when the animal began fixating
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%=OUTPUT
%
%   t
%       A numeric array of the times when the animal began fixating
function t_cpoke_in = get_cpoke_in_time(PEH)
t_cpoke_in = arrayfun(@(x) x.states.cpoke1, PEH, 'uni', 0);
t_cpoke_in(cellfun(@isempty,t_cpoke_in)) = {nan};

t_c2s_pun2 = PBups.get_c2s_pun2_end_time(PEH);
for i = 1:numel(t_cpoke_in)
    b4_pun = t_cpoke_in{i} < t_c2s_pun2(i);
    t_cpoke_in{i}(b4_pun) = [];
end
t_cpoke_in = cellfun(@(x) x(1),t_cpoke_in);