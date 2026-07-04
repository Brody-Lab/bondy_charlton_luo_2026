function [PD, PEH] = align_PD_PEH(PD, PEH)
% Align the trial sequence between the protocol data and the parsed event history
%
% All trials in which a suppressed crash had occurred are removed.
%
% ARGUMENT
%
%   `PD`: a structure containing the protocol data
%
%   `PEH`: a cell array containing the parsed event history
%
% RETURN
%
%   `PD`: each field of the structure now has the same number of trials. The field 'leftwatertime`
%   and 'rightwatertime` are removed
%
%   `PEH`: a cell array containing the parsed event history
if isfield(PD, 'leftwatertime') && isrow(PD.leftwatertime)
    PD = rmfield(PD, 'leftwatertime');
end
if  isfield(PD, 'rightwatertime') &&  isrow(PD.rightwatertime)
    PD = rmfield(PD, 'rightwatertime');
end
minimum = min(structfun(@numel, PD));
minimum = min(minimum, numel(PEH));
PD = structfun(@(x) x(1:minimum), PD, 'UniformOutput', false);
PEH = PEH(1:minimum);
peh_hit = arrayfun(@(x) ~isempty(x.states.hit_state), PEH);
pd_hit = PD.hits == 1;
pd_hit = pd_hit(1:numel(peh_hit));
if any(peh_hit ~= pd_hit)
    has_rw = arrayfun(@(x) isfield(x.waves, 'rewarded_wave'), PEH);
    PEH(~has_rw).waves.rewarded_wave = [];
    peh_hit = arrayfun(@(x) ~isempty(x.waves.rewarded_wave) || ...
                            ~isempty(x.waves.hitstatetimer), PEH);
    if any(peh_hit ~= pd_hit)
        error('Protocol data and parsed event history don''t align')
    end
end
if isfield(PD, 'crash')
    crashindices = PD.crash==1;
    if sum(crashindices) > 0
        warning('Crashes have occurred and been suppressed')
        PD = structfun(@(x) x(~crashindices), PD, 'UniformOutput', false);
        PEH = PEH(~crashindices);
    end
end
if isfield(PD, 'stimdata')
    pd_stim = cellfun(@(x) x.ison, PD.stimdata) > 0;
    peh_stim = arrayfun(@(x) ~isempty(x.waves.laser_stim_on), PEH);
    pd_stim = round(double(pd_stim));
    peh_stim = round(double(peh_stim));
    violated = logical(PD.violations);
    no_cpoke = cellfun(@isempty, arrayfun(@(x) x.pokes.C, PEH, 'uni', false)); % the animal didn't cpoke, and the trial terminated
    incomplete = violated | no_cpoke;
    pd_stim_compl = pd_stim(~incomplete);
    peh_stim_compl = peh_stim(~incomplete);
    if ~all(pd_stim_compl == peh_stim_compl)
        new_pd_stim = pd_stim(2:end);
        new_peh_stim = peh_stim(1:end-1);
        is_matching = new_pd_stim == new_peh_stim;
        is_matching = is_matching(~incomplete(1:end-1));
        if all(is_matching)
            PD.stimdata(1:end-1) = PD.stimdata(2:end);
            PD = structfun(@(x) x(1:end-1), PD, 'uni', 0);
            PEH = PEH(1:end-1);
        else
            warning('Unknown misalignment problem between *pd* and *peh.*')
        end
    end
end