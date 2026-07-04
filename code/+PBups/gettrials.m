function Trials = gettrials(ratname, sessiondate)
% tabulate the trials from one day
%
% If multiple sessions occured on the same day, then the sessions are combined
%
% ARGUMENT
%
%   `ratname`: character row vector specifying the name of a rat
%   
%   `sessiondate`: a character row vector specifying the date of the session, in the format of
%   'yyyy-mm-dd', where 'yyyy' corresponds to the year, 'mm' the month, and 'dd' the day.
%   
% RETURN
%   
%   `T`: a table tabulating the trials in the session
validateattributes(ratname, {'char'},{'row'})
validateattributes(sessiondate, {'char'},{'row'})
sessiondate = datestr(sessiondate, 'yyyy_mm_dd');
try
    bdata('status');
catch
    bdata('connect');
end
command = sprintf('select sessid from sessions where ratname="%s" and sessiondate="%s"', ...
    ratname, sessiondate);
sessids = bdata(command);
if isempty(sessids)
    Trials = [];
    warning('No trial was performed by %s on %s', ratname, sessiondate)
    return
end
concatenatedIDs = arrayfun(@(x) sprintf('%i,',x),sessids,'UniformOutput',false);
concatenatedIDs = strcat(concatenatedIDs{:});
concatenatedIDs = concatenatedIDs(1:end-1);
[PD, PEH]=bdata(['select protocol_data, peh from sessions s, parsed_events p where s.sessid in (' ...
    concatenatedIDs ') and s.sessid=p.sessid order by p.sessid']);
nsessions = numel(PD);
Trials = cell(nsessions,1);
for i = 1:nsessions
    [PD{i}, PEH{i}] = PBups.align_PD_PEH(PD{i}, PEH{i});
    if ~isempty(PEH{i})
        Trials{i,1} = PBups.tabulatetrials(PD{i}, PEH{i}, ratname, sessids(i), sessiondate);
        Trials{i} = struct2table(Trials{i});
    end
end
Trials = vertcat(Trials{:});