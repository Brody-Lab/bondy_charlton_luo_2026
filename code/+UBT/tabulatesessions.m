function T = tabulatesessions()
% Create a table with information on the sessions that Thomas wishes to analyze
folderpath = fileparts(mfilename('fullpath'));
csvpath = fullfile(folderpath, 'sessions.csv');
T = readtable(csvpath, 'delimiter', ',');
for variablename = ["recording_id", "date", "rat"]
    T.(variablename) = string(T.(variablename));
end