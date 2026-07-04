function S = load_saved_data_of_session(sessid)
% LOAD_SAVED_DATA_OF_SESSION load the trial by trial task data
%
%=INPUT
%
%   sessid
%       session ID
%
%=OUTPUT
%
%   S
%       A structure containing the trial by trial data.

[data_path, data_file] = ...
    bdata('select data_path, data_file from sessions where sessid = "{S}"', sessid);
if sessid ==506165
    data_path = {'X:\RATTER\SoloData\Data\Chuck\K215\'};
    data_file = {'data_@PBups_Chuck_K215_170516a'};
else
    [data_path, data_file] = ...
    bdata('select data_path, data_file from sessions where sessid = "{S}"', sessid);
end
data_path = strrep(data_path, 'C:', 'X:');
data_path = strrep(data_path, 'ratter', 'RATTER');
data_path = [data_path{:} data_file{:} '.mat'];
if ~contains(data_path, 'X:')
    data_path = ['X:' data_path];
end
assert(isfile(data_path), sprintf('Data file does not exist: %s', data_path))
S = load(data_path);