function T = tabulate_click_response(spiketimes_s, Trials, varargin)
% Tabulate the response of a neuron to each auditory click
%
% ARGUMENT
%   
%   'spiketime_s': a numeric vector containing the spike times of a neuron
%
%   'Trials': A structure containing information on the sensory stimuli and behavioral responses
%
% RETURN
%
%   'T': a table whose each row is a click. The variables of the table are
%
%       'trialindex': the linear index of the trial in the argument 'Trials'
%
%       'source': A UINT8 scalar. A value of '0' indicates the click is from the left speaker, '1'
%       from the right speaker, and '2' from both the left and right speaker
%
%       'precedingclicks': number of clicks preceding this click on this trial
%
%       'time_s': 
%
%       'time_from_1st_click_s': time, in seconds, from the first click
%
%       'choice': behavioral choice on this trial. 'true' indicates a right choice, and 'false' a
%       left choice
%
%       'gamma': a parameter indicating the generative statistics of the clicks in this trial. 
%
%       'spikecounts': A row vector indicating the spike counts aligned to the onset time of the
%       auditory click. Typically, the bin edges, in seconds, are '0:0.001:0.1' 
%
% OPTIONAL ARGUMENT
%
%   binedges_s
%       a numeric column vector representing the edges of each time bin used to count spikes
validateattributes(spiketimes_s, {'numeric'}, {'vector'})
validateattributes(Trials, {'struct'}, {'scalar'})
P=inputParser;
P.addParameter('binedges_s', 0:0.001:0.1, @(x) validateattributes(x,{'numeric',}, {'vector'}));
P.parse(varargin{:});
P=P.Results;
trialindices = find(~Trials.violated & ...
                      ~isnan(Trials.stateTimes.clicks_on));
nclicks = sum(cellfun(@(L,R) numel(L)+numel(R)-1, Trials.leftBups(trialindices), ...
                                                  Trials.rightBups(trialindices)));
T = struct;
[T.trialindex, ...
 T.source, ...
 T.time_s, ...
 T.precedingclicks, ...
 T.time_from_1st_click_s, ...
 T.choice, ...
 T.gamma] = deal(nan(nclicks,1));
nbins = numel(P.binedges_s)-1;
T.spikecounts = nan(numel(trialindices),nbins);
k = 0;
for i = 1:numel(trialindices)
    trialindex = trialindices(i);
    stereoclick_click_time_s = Trials.leftBups{trialindex}(1);
    left_click_time_s = Trials.leftBups{trialindex}(2:end);
    right_click_time_s = Trials.rightBups{trialindex}(2:end);
    clicktimes_s = [stereoclick_click_time_s, left_click_time_s, right_click_time_s];
    clicksources = [2, zeros(1, numel(left_click_time_s)), ones(1, numel(right_click_time_s))];
    [clicktimes_s, sortindices] = sort(clicktimes_s);
    clicksources = clicksources(sortindices);
    clicktimes_s = clicktimes_s + Trials.stateTimes.clicks_on(trialindex);
    spiketimes_this_trial = spiketimes_s(spiketimes_s>=clicktimes_s(1) & ...
                                        spiketimes_s< clicktimes_s(end)+P.binedges_s(end));
    spiketimes_this_trial = spiketimes_this_trial - clicktimes_s(1);
    relative_clicktimes_s = clicktimes_s - clicktimes_s(1);
    for j = 1:numel(clicktimes_s)
        k = k + 1;
        T.trialindex(k) = trialindex;
        T.source(k) = clicksources(j);
        T.gamma(k) = Trials.gamma(trialindex);
        T.choice(k) = Trials.pokedR(trialindex);
        T.time_s(k) = clicktimes_s(j);
        T.time_from_1st_click_s(k) = relative_clicktimes_s(j);
        T.precedingclicks(k) = j-1;
        T.spikecounts(k,:) = histcounts(spiketimes_this_trial, P.binedges_s+relative_clicktimes_s(j));
    end
end
for variablename = ["trialindex", "choice", "source", "precedingclicks"]
    assert(~any(isnan(T.(variablename))));
end
T.choice = logical(T.choice);
T.trialindex = uint16(T.trialindex);
T.source = uint8(T.source);
T.precedingclicks = uint8(T.precedingclicks);
T.spikecounts = uint8(T.spikecounts);
T = struct2table(T);