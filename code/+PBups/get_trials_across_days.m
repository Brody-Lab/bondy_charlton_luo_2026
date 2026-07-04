function Trials = get_trials_across_days(ratname, sessiondates)
% Collect trials performed by a rat across multiple days
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
%   `Trials`: a table whose each row is a trial
%
validateattributes(ratname, {'char'}, {'row'})
validateattributes(sessiondates, {'char','string', 'cell'}, {})
sessiondates = string(sessiondates);
ndates = numel(sessiondates);
Trials = cell(ndates,1);
for i = 1:ndates
    Trials{i} = PBups.gettrials(ratname, sessiondates{i});
end
Trials = vertcat(Trials{:});