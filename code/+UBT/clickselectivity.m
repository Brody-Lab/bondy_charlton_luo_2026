function [x, times_s] = clickselectivity(spiketimes_s, Trials, varargin)
% Estimate the time course of a neuron's selectivity to an auditory click
%
% ARGUMENT
%   
%   spiketime_s
%       a numeric vector containing the spike times of a neuron
%
%   Trials
%       A structure containing information on the sensory stimuli and behavioral responses
%
% RETURN
%
%   x
%       a numeric column vector representing the selectivity at each time step, in the unit of spikes
%       per second
%
%   times_s
%       a numeric column vector, with the same size as `x`, representing the right edge of each bin
%       used to count spikes
%
% OPTIONAL ARGUMENT
%
%   nresamples
%       number of times the trials are resampled
%
%   binedges_s
%       a numeric column vector, with the same size as `x`, representing the edges of each bin
%       used to count spikes
validateattributes(spiketimes_s, {'numeric'}, {'vector'})
validateattributes(Trials, {'struct'}, {'scalar'})
P=inputParser;
P.addParameter('nresamples', 10, @(x) validateattributes(x,{'numeric',}, {'positive', 'integer'}));
P.addParameter('binedges_s', 0:0.01:0.1, @(x) validateattributes(x,{'numeric',}, {'vector'}));
P.parse(varargin{:});
P=P.Results;
binduration_s = mean(diff(P.binedges_s));
iscomplete = ~Trials.violated & ~isnan(Trials.stateTimes.clicks_on);
gammas = unique(Trials.gamma);
X = nan(P.nresamples, numel(P.binedges_s)-1);
for s = 1:P.nresamples
    trialindices = cell(numel(gammas),1);
    for i = 1:numel(gammas)
        pokedR = find(iscomplete & ...
                      Trials.gamma==gammas(i) & ...
                      Trials.pokedR==1);
        pokedL = find(iscomplete & ...
                      Trials.gamma==gammas(i) & ...
                      Trials.pokedR==0);
        nR = numel(pokedR);
        nL = numel(pokedL);
        if nR > nL
            indicesR = pokedR(randperm(nR,nL));
            indicesL = pokedL;
        elseif nL > nR
            indicesR = pokedR;
            indicesL = pokedL(randperm(nL,nR));
        else
            indicesR = pokedR;
            indicesL = pokedL;
        end
        trialindices{i} = [indicesL; indicesR];
    end
    trialindices = cell2mat(trialindices);
    t_clicks_on = num2cell(Trials.stateTimes.clicks_on(trialindices));
    clicktimes = struct;
    clicktimes.L = cell2mat(cellfun(@(x,y) x(2:end)'+y, Trials.leftBups(trialindices), t_clicks_on, 'uni', 0));
    clicktimes.R = cell2mat(cellfun(@(x,y) x(2:end)'+y, Trials.rightBups(trialindices), t_clicks_on, 'uni', 0));
    spikerate = struct;
    for side = ["L", "R"]
        clicktimes.(side) = sort(clicktimes.(side));
        spikecounts = nan(numel(clicktimes.(side)), numel(P.binedges_s)-1);
        for i = 1:numel(clicktimes.(side))
            spikecounts(i,:) = histcounts(spiketimes_s, clicktimes.(side)(i) + P.binedges_s);
        end
        spikerate.(side) = mean(spikecounts)/binduration_s;
    end
    X(s,:) = spikerate.R - spikerate.L;
end
x = mean(X);
times_s = P.binedges_s(2:end);