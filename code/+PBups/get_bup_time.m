% GET_BUP_TIMES return the bup times of each trial of a session
%
%=INPUT
%
%   PD
%       Structure containing the protocol data of one session
%
%   PEH
%       Structure containing the parsed event history the same session
%
%=OUTPUT
%
%   L
%       A cell array whose each element contains the times of the left clicks on one trial
%
%   R
%       right clicks times
%
%   clicks_on_s
%       the onset of the click train on each trial
%
%   clicks_off_s
%       the offset of the click train
function [L,R,clicks_on_s,clicks_off_s] = get_bup_time(PD,PEH)
L = cellfun(@(x) x.left, PD.bupsdata, 'uni', 0);
R = cellfun(@(x) x.right, PD.bupsdata, 'uni', 0);
% give empty cells an NaN for sake of indexing
idx_empty = cellfun(@isempty, L);
[L{idx_empty}] = deal(NaN); 
idx_empty = cellfun(@isempty, R);
[R{idx_empty}] = deal(NaN); 
t_diff_firstbup = cellfun(@(x,y) x(1) - y(1), L, R);
if any(t_diff_firstbup > 1e-3) % millisecond precision        
    warning('The timing of the first left and first right bup differs by more than one millisecond!')
end
dur_bups_s = num2cell(PBups.get_dur_bups_s(PEH));
clicks_on_s = PBups.get_clicks_on_time(PEH);
clicks_off_s = PBups.get_clicks_off_time(PEH);
dur_bups_s = num2cell(clicks_off_s - clicks_on_s);
L = cellfun(@(bups, t) bups(bups <= t), L, dur_bups_s, 'uni', 0);
R = cellfun(@(bups, t) bups(bups <= t), R, dur_bups_s, 'uni', 0);
for i = 1:size(L)
    L{i} = L{i} + clicks_on_s(i);
    R{i} = R{i} + clicks_on_s(i);
end