% GET_RESPONSE_TIME extract the time in second the animal took to respond
%
%=INPUT
%
%   PEH
%       parsed event history of a session. A structure
%
%=OUTPUT
%
%   response_time_s
%       A vector with the same number of elements as PEH
function response_time_s = get_response_time(PEH)
validateattributes(PEH, {'struct'},{})

t_cpoke = arrayfun(@(x) x.states.cpoke1, PEH, 'uni', 0);
t_cpoke(cellfun(@isempty,t_cpoke)) = {nan(1,2)};
t_cpoke_req_end = cellfun(@(x) max(x(:)), t_cpoke);

T = struct;
for state = {'hit_state', 'error_state'}; state = state{:};
    t_state = arrayfun(@(x) x.states.(state), PEH, 'uni', 0);
    t_state(cellfun(@isempty,t_state)) = {nan(1,2)};
    t_state = cell2mat(t_state);
    T.(state) = t_state(:,1);
end

response_time_s = nan(size(t_cpoke_req_end));
rt_hit = T.hit_state - t_cpoke_req_end;
rt_err = T.error_state - t_cpoke_req_end;
response_time_s(~isnan(T.hit_state)) = rt_hit(~isnan(T.hit_state));
response_time_s(~isnan(T.error_state)) = rt_err(~isnan(T.error_state));