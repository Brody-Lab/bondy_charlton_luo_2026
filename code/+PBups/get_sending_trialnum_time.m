function t = get_sending_trialnum_time(PEH)
% GET_SENDING_TRIALNUM_TIME return the time of the state when information
% about the trial number is sent
%
%=INPUT
%
%   PEH
%       parsed event history
%
%=OUTPUT
%
%   t
%       A vector of the time in each trial when the trial number
%       information is outputed
if isfield(PEH(1).states, 'state_0')
    t = arrayfun(@(x) x.states.state_0(1), PEH);
elseif isfield(PEH(1).states, 'sending_trialnum')
    t = arrayfun(@(x) x.states.sending_trialnum(1), PEH);
else
    t = arrayfun(@(x) x.states.sending_trialnum(1), PEH);
end