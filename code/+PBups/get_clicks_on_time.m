% GET_CLICKS_ON_TIME 
%
%=INPUT
%
%   PEH
%       The parsed event history structure for one session
%
%=OUTPUT
%
%   clicks_on
%       A vector of clicks on times in seconds
%
function t = get_clicks_on_time(PEH)
    sound_on = arrayfun(@(x) x.waves.sound_on, PEH, 'uni', 0);    
    t_c2s_pun2 = PBups.get_c2s_pun2_end_time(PEH);
    t = nan(numel(PEH),1);
    for i = 1:numel(sound_on)
        b4_pun = sound_on{i} < t_c2s_pun2(i);
        sound_on{i}(b4_pun) = [];
        if ~isempty(sound_on{i})
            t(i) = min(sound_on{i}(:));
        end
    end