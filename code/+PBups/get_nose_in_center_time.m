function t = get_nose_in_center_time(sessid)
% GET_NOSE_IN_CENTER_TIME return the time it is required for the animal to
% be fixating in each trial.
%
%=INPUT
%
%   sessid
%       session ID
%
%=OUTPUT
%
%   t
%       A vector of the required fixation time in each trial

S = PBups.load_saved_data_of_session(sessid);
t = cell2mat(S.saved_history.StimulusSection_nose_in_center);
t = t(2:end);