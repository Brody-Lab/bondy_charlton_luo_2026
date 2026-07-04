function Trials = tabulatetrials(PD, PEH, ratname, sessid, sessiondate)
% Create a table whose each row is a trial
%
% ARGUMENT
%
%   `PD`: a structure scalar containing the protocol data (PD) of one session
%
%   `PEH`: a structure array containing the parsed event history (PEH) of one session 
%
% RETURN
%
%   `Trials`: a table with the following variables (i.e., columns):
%       'ratname': a categorical representing an alpha-numeric ID beginning with a capital letter
%       followed by three numbers 
%
%       'sessid': an integer unique to each behavioral session.
%
%       'sessiondate': a categorical indicating the date in the format of 'yyyy_mm_dd' 
%
%       'violated': whether the animal left the center too early
%
%       'is_probe_trial': whether a trial has a stimulus period equal to 1 second
%
%       'is_hit': whether the trial is correct
%
%       'gamma': logarithm of the ratio of the right click rate to the left click rate
%
%       `leftclick_s`: a cell array indicating the times of each left click, in seconds, on the
%       timescale as all the events.
%
%       `rightclick_s': time of each right click on each time.
%
%       'stereoclick_s': time of each right click on each time.
%
%       `clicks_on_s': time when the click train began on each trial
%
%       `clicks_off_s`: time when the click train ended on each trial
%
%       `clickdifference`: #right-#left clicks
%
%       `trial_type`: "a" indicate an audition-guided trial, "s" a trial guided by an LED on either
%       the left or right, and "f" a free choice trial
%
%       `seed`: random number generator seed for creating the click trains
%
%       `reward_loc`: location of the reward: "l" indicates on the left and "r" on the right
%
%       `pokedR`: whether the animal chose right
%
%       `sending_trialnum_s`: time when the trial number, in bits, are sent from the behavioral
%       system to another recording system
%
%       `wait_for_cpoke_s`: time when the animal can insert its nose into the central port
%
%       'cpoke_in_s`: time when the animal inserted its nose into the central port
%
%       `cpoke_req_end_s`: time when the animal no longer had to keep its nose in the central port.
%       Assumed to be 1.5 second from `wait_for_cpoke_s`
%       
%       `violation_s`: time when the animal broke fixation
%a 
%       `feedback_s`: time when either a reward or an error sound is delivered
%
%       `error_s`: time of the error sound
%
%       `left_reward_s`: time when the left reward is delivered
%
%       `right_reward_s`: time of the right reward
%
%       `cleaned_up_s`: time when the behavioral system completed the `clean_up` state
%       
%       `responded`: whether the animal made a response, defined as a trial on which the animal's
%       side poke is within 10 seconds of when it can withdraw from the center port and also that
%       the animal's withdrawal from the center port occurs only after the time when it is allowed
%       to do so. This definition removes some trials on which the animal failed to realize a
%       stimulus was just played and that it could respond. This definition also removes trials when
%       the animal breaks the infrared beam of a beam with a paw while simultaneousy continuing to
%       keep its nose in the center port.
validateattributes(PD, {'struct'}, {'scalar'})
validateattributes(PEH, {'struct'}, {'vector'})
validateattributes(ratname, {'char'}, {'row'})
validateattributes(sessid, {'numeric'}, {'integer', 'scalar'})
validateattributes(sessiondate, {'char'}, {'row'})
Trials = struct;
ntrials = numel(PEH);
if ntrials < 1
    return
end
Trials.ratname = repmat(categorical(string(ratname)), ntrials,1);
Trials.sessid = repmat(sessid, ntrials,1);
Trials.sessiondate = repmat(categorical(string(sessiondate)), ntrials,1);
Trials.violated = PD.violations == 1;
if all(cellfun(@(x) isfield(x, 'is_probe_trial'), PD.bupsdata))
    Trials.is_probe_trial = logical(cellfun(@(x) x.is_probe_trial, PD.bupsdata));
else
    Trials.is_probe_trial= PD.samples >= 0.995;
end
PD.hits(isnan(PD.hits)) = 0; % NaN for violation trials
Trials.is_hit = logical(PD.hits);
gammas = cellfun(@(x) x.gamma, PD.bupsdata);
gammas = round(gammas*1000)/1000;
Trials.gamma = gammas;
[Trials.leftclick_s, Trials.rightclick_s, Trials.clicks_on_s,Trials.clicks_off_s] = ...
    PBups.get_bup_time(PD, PEH);
Trials.clickdifference = cellfun(@(L, R) numel(R) - numel(L), ...
    Trials.leftclick_s, Trials.rightclick_s);
Trials.trial_type = repmat('a', ntrials, 1); % by default, all trials are accumulation trials
Trials.trial_type(abs(gammas) == 99 & PD.sides ~= 'f') = 's';  % side LED trials
Trials.trial_type(abs(gammas) == 99 & PD.sides == 'f') = 'f';  % free choice trials
Trials.trial_type = categorical(string(Trials.trial_type));
Trials.RR_left_reward_prob = nan(ntrials,1);
Trials.RR_right_reward_prob = nan(ntrials,1);
if isfield(PD, 'reward_type')
    Trials.reward_type = categorical(string(PD.reward_type));
    Trials.trial_type(Trials.reward_type == 'reward_reversal') = 'r';     
    if all(ismember(string(PD.reward_type), ["delta clicks", "gamma", "free_choice"]))
        Trials.pokedR = false(size(Trials.is_hit));
        infer_pokedR = true;
    else
        Trials.pokedR = PD.pokedR;
        infer_pokedR = false;
    end
    for field = ["RR_left_reward_prob", "RR_right_reward_prob"]
        if isfield(PD, field)
            Trials.(field) = cell2mat(PD.(field));
        else
            Trials.(field) = nan(size(Trials.is_hit));
        end
    end
else
    Trials.reward_type = categorical(repmat("delta clicks", numel(PD.hits),1));
    infer_pokedR = true;
end
Trials.reward_loc = strings(ntrials,1);
Trials.photostim = cellfun(@(x) x.ison, PD.stimdata);
Trials.photostim = cellfun(@(x) x.ison, PD.stimdata);

for t = 1:ntrials
    left_reward = PEH(t).states.left_reward;
    right_reward = PEH(t).states.right_reward;
    if numel(left_reward) > 0
        Trials.reward_loc{t,1} = 'l';
    elseif numel(right_reward) > 0
        Trials.reward_loc{t,1} = 'r';
    elseif (numel(left_reward) > 0) && (numel(right_reward) > 0)
        error('multiple rewards')
    end
    if Trials.reward_type(t) == 'reward_reversal'
        if ~isempty(PEH(t).states.left_reward) && isempty(PEH(t).states.right_reward)
            Trials.pokedR(t,1) = false;
        elseif isempty(PEH(t).states.left_reward) && ~isempty(PEH(t).states.right_reward)
            Trials.pokedR(t,1) = true;
        elseif ~isempty(PEH(t).states.left_reward) && ~isempty(PEH(t).states.right_reward)
            error('reward at both sides?')
        elseif isempty(PEH(t).states.left_reward) && isempty(PEH(t).states.right_reward) && ...
                ~isempty(PEH(t).states.error_state1)
            leftpokes = PEH(t).pokes.L;
            rightpokes = PEH(t).pokes.R;
            time1 = PEH(t).states.cpoke1(end);
            time2 = PEH(t).states.error_state1(1);
            leftpokes = leftpokes(leftpokes > time1 & leftpokes < time2);
            rightpokes = rightpokes(rightpokes > time1 & rightpokes < time2);
            if ~isempty(leftpokes) && isempty(rightpokes)
                Trials.pokedR(t,1) = false;
            elseif isempty(leftpokes) && ~isempty(rightpokes)
                Trials.pokedR(t,1) = true;
            else
                error('need to debug')
            end
        end
    else
        if Trials.trial_type(t) == 'f'
            Trials.pokedR(t,1) = Trials.reward_loc(t) == 'r';
        else
            Trials.pokedR(t,1) = (PD.sides(t) =='r' & PD.hits(t) == 1 ) | ...
                                  (PD.sides(t) =='l' & PD.hits(t) == 0);
        end
    end
end
assert(sum(isnan(Trials.pokedR) & ~Trials.violated & ~isnan(Trials.clicks_on_s))==0)
Trials.reward_loc = categorical(Trials.reward_loc);
if isfield(PD.bupsdata{1}, "seed")
    Trials.seed = cellfun(@(x) x.seed, PD.bupsdata);
else
    Trials.seed = nan(size(PD.bupsdata));
end
Trials.sending_trialnum_s = PBups.get_sending_trialnum_time(PEH);
Trials.wait_for_cpoke_s = PBups.get_wait_for_cpoke_time(PEH);
Trials.cpoke_in_s = PBups.get_cpoke_in_time(PEH);
Trials.stereoclick_s = PBups.get_stereo_click_time(PD, PEH);
Trials.cpoke_req_end_s = Trials.cpoke_in_s + 1.5;
% Trials.sync_flash_s = arrayfun(@(peh) peh.states.sync_flash(1), PEH);
Trials.violation_s =  PBups.get_violation_time(PEH);
[Trials.feedback_s, ...
 Trials.error_s, ...
 Trials.left_reward_s, ...
 Trials.right_reward_s] = PBups.get_feedback_time(PEH);
Trials.spoke_s = PBups.get_spoke_time(PEH, PD, Trials.cpoke_req_end_s);
Trials.cpoke_out_s = PBups.get_cpoke_out_time(PEH, PD, Trials.spoke_s);
Trials.cleaned_up_s = nan(ntrials,1);
for i = 1:ntrials
    if ~isempty(PEH(i).states.clean_up_state)
        Trials.cleaned_up_s(i) = PEH(i).states.clean_up_state(1);
    end
end
                  