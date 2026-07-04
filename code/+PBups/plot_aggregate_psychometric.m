function [] = plot_aggregate_psychometric(ratname, sessiondates, varargin)
% Plot the psychometric function of one rat across one or more days
%
% ARGUMENT
%
%   `ratname`: character row vector specifying the name of a rat
%   
%   `sessiondate`: a character row vector, a string array, or a cell array of strings specifying the
%   one or more dates, in the format of 'yyyy-mm-dd', where 'yyyy' corresponds to the year, 'mm'
%   the month, and 'dd' the day.
%   
% RETURN
%
%   nothing
%
% OPTIONAL ARGUMENT
%
%   the same as those in `PBups.plotpsychometric`
%
% EXAMPLE
%
%   1) Plot performance from a single day
%   >> PBups.plot_aggregate_psychometric('T176', '2018_05_03')
%   
%   2) Plot performance across multiple days
%   >> PBups.plot_aggregate_psychometric('T176', {'2018_05_03', '2018_05_04'})
validateattributes(ratname, {'char'}, {'row'})
validateattributes(sessiondates, {'char','string', 'cell'}, {})
sessiondates = string(sessiondates);
ndates = numel(sessiondates);
Trials = cell(ndates,1);
for i = 1:ndates
    Trials{i} = PBups.gettrials(ratname, sessiondates{i});
end
Trials = vertcat(Trials{:});
if ~isempty(Trials)
    PBups.plotpsychometric(Trials, varargin{:});
else
    warning('no trials')
end