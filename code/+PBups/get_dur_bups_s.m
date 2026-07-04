% GET_DUR_BUPS_S return the duation of the bups in each trial of a session
%
%=INPUT
%
%   PEH
%       Structure containing the parsed event history the same session
%
%=OUTPUT
%
%   dur_bups_s
%       A numeric vector 

function dur_bups_s = get_dur_bups_s(PEH)
n_stim = arrayfun(@(x) numel(x.waves.sound_on)/2, PEH);
if ~all(n_stim==0|n_stim==1)
    warning('The bups stimulus was played more than once')
end
sound_on = arrayfun(@(x) x.waves.sound_on, PEH, 'uni', 0);
sound_on(cellfun(@isempty, sound_on)) = {nan(1,2)};
sound_on = cellfun(@(x) x(end,:), sound_on, 'uni', 0);
dur_bups_s = diff(cell2mat(sound_on),[],2);