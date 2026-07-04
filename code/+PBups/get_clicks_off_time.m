% GET_CLICKS_OFF_TIMES return time when the sound turns off
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%=OUTPUT
%
%   t
%       A numeric array of the times when the sound turned off
function t = get_clicks_off_time(PEH)
    sound_on = arrayfun(@(x) x.waves.sound_on, PEH, 'uni', 0);    
    t_c2s_pun2 = PBups.get_c2s_pun2_end_time(PEH);
    t = nan(numel(PEH),1);
    for i = 1:numel(sound_on)
        b4_pun = sound_on{i} < t_c2s_pun2(i);
        sound_on{i}(b4_pun) = [];
        if ~isempty(sound_on{i})
            t(i) = max(sound_on{i}(:));
        end
    end