function plotpsychometric(Trials, varargin)
% Plot a psychometric function
%
% Only audition-guided trials in which the animal completed its fixation requirement and made a
% response are included
%
% ARGUMENT
%
%   `Trials`: a table whose each row is a trial
%
% OPTIONAL ARGUMENT
%
%   'axes': the axes object in which the psychometric function is plotted
%
%   `color`: color of the line and the confidence interval. A 3-element numeric row vector
%
%   `confidenceinterval`: A `logical` scalar specifying whether to plot the 95% binomial confidence
%   intervals as shading
%
%   `nbins': number of bins used for grouping click difference
%
validateattributes(Trials, {'table'}, {})
P = inputParser;
addParameter(P, 'axes', gca, @(x) ishandle(x))
addParameter(P, 'confidenceinterval', true, @(x) islogical(x) && isscalar(x))
addParameter(P, 'linespec', {'ko-', 'linewidth', 1.5}, @(x) iscell(x))
addParameter(P, 'nbins', 8, ...
    @(x) validateattributes(x, {'numeric'},{'scalar', 'positive', 'integer'}))
parse(P, varargin{:});
P = P.Results;
Trials = Trials(~Trials.violated & ...
    ~isnan(Trials.clicks_on_s) & ...
    (Trials.trial_type=='a' | ...
    Trials.trial_type=='r'), :);
edges = quantile(Trials.clickdifference, 0:1/P.nbins:1);
groupindices = findgroups(discretize(Trials.clickdifference, edges));
x = splitapply(@mean, Trials.clickdifference, groupindices);
[pointestimate, ci] = splitapply(@(x) binofit(sum(x), numel(x)), Trials.pokedR, groupindices);
PBups.stylizeaxes(P.axes)
if P.confidenceinterval
    PBups.shadeplot(x, ci(:,1), ci(:,2))
end
plot(x, pointestimate, P.linespec{:})
absxlim = ceil(max(abs(x))/10)*10;
xlim([-absxlim, absxlim])
xticks([-absxlim, 0, absxlim])
ylim([0,1])
yticks([0 1])
ylabel('fraction chose right')
xlabel('#right - #left clicks')