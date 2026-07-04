function Trials = remove_trials(Trials,remove_trial)
    %remove_trials is logical
    if ~any(remove_trial)
        return
    end
    fields = string(fieldnames(Trials));
    nt=length(remove_trial);
    for f = fields(:)'
        if numel(Trials.(f))==nt
            if istable(Trials.(f))
                Trials.(f) = Trials.(f)(~remove_trial,:);                
            else
                Trials.(f) = Trials.(f)(~remove_trial);
            end
        elseif any(strcmp({'pharma','laser','stateTimes'},f))
            Trials.(f) = common.remove_trials(Trials.(f),remove_trial);
        end
    end
    if ismember('left_clicks',fields)
        inc_trials = find(~remove_trial);
        count=0;
        for i=1:length(inc_trials)
            count=count+1;
            idx(inc_trials(i)) = count;
        end
        left_click_idx = ismember(Trials.left_click_trial,inc_trials);
        right_click_idx = ismember(Trials.right_click_trial,inc_trials);
        Trials.left_clicks = Trials.left_clicks(left_click_idx);
        Trials.left_click_times = Trials.left_click_times(left_click_idx);
        if isfield(Trials,'shuffled_left_clicks')
            Trials.shuffled_left_clicks = Trials.shuffled_left_clicks(left_click_idx);
            Trials.shuffled_left_click_times = Trials.shuffled_left_click_times(left_click_idx);
        Trials.shuffled_right_clicks = Trials.shuffled_right_clicks(right_click_idx);
        Trials.shuffled_right_click_times = Trials.shuffled_right_click_times(right_click_idx);            
        end
        Trials.left_click_trial = idx(Trials.left_click_trial(left_click_idx));
        Trials.right_clicks = Trials.right_clicks(right_click_idx);
        Trials.right_click_times = Trials.right_click_times(right_click_idx);
        Trials.right_click_trial = idx(Trials.right_click_trial(right_click_idx));        
    end
end
