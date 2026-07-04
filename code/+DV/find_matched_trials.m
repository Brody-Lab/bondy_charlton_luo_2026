function [match_idx,gidx,missing_trials] = find_matched_trials(Trials,fields,varargin)
    % first two outputs have had missing trials removed. third output gives
    % indices in original data that were removed.
    validateattributes(fields,{'cell'},{},'find_matched_trials','fields',2);
    if ~isstruct(Trials)
        error('First input must be a Trials struct.');
    end
    trial_data=[];
    for f=1:numel(fields)
        if isfield(Trials,fields{f})
            if any(isnan(Trials.(fields{f})))
                warning('%d trials with NaN values for %s. These trials will be removed.',sum(isnan(Trials.(fields{f}))),fields{f});
            end
            trial_data = cat(2,trial_data,Trials.(fields{f})); 
        else
            error('"%s" is not a field of the Trials struct.');
        end
    end
    if isempty(trial_data)
        trial_data=ones(size(Trials.pokedR));
        warning('control_fields is isempty. Treating all trials as belonging to one group.');
    end
    ntrials = size(trial_data,1);
    p=inputParser;
    p.KeepUnmatched=true;
    p.addParameter('trial_idx',true(ntrials,1),@(x)validateattributes(x,{'logical'},{'nonempty','vector'}));
    p.addParameter('seed',randi(1e8),@(x)validateattributes(x,{'logical'},{'scalar'}));    
    p.addParameter('n_resamples',1,@(x)validateattributes(x,{'numeric'},{'scalar','positive','integer'}));        
    p.addParameter('min_trials',2,@(x)validateattributes(x,{'numeric'},{'integer','>',1,'finite'}));
    p.addParameter('min_choices',1,@(x)validateattributes(x,{'numeric'},{'integer','>=',1,'<=',2,'finite'}));
    p.addParameter('max_choice_ratio',Inf,@(x)validateattributes(x,{'numeric'},{'>=',1})); %ratio of most freq choice to least freq choice
    
    p.parse(varargin{:});
    params=p.Results;
    rng(params.seed);
    params.trial_idx = find(params.trial_idx);
    trial_data = trial_data(params.trial_idx,:);
    trial_data_has_nans = any(isnan(trial_data),2);    
    choice = Trials.pokedR(params.trial_idx);
    ntrials = size(trial_data,1);
    [~,~,gidx] = unique(trial_data,'rows');
    missing=false(max(gidx),1);  % groups with only one element  
    if ~isinf(params.max_choice_ratio) && params.min_choices~=2
        error('l');
    end
    for i=1:max(gidx)
       this_match_idx = find(gidx==i);
       n_matches=numel(this_match_idx);
       if n_matches<params.min_trials
            missing(i)=true;
       end
       if params.min_choices>1
           if numel(unique(choice(gidx==i)))<params.min_choices
               missing(i)=true;
           end
       end
       if ~isinf(params.max_choice_ratio)
           nleft=sum(choice(gidx==i)==0);
           nright = sum(choice(gidx==i)==1);
           if nright>nleft
               if nright/nleft>params.max_choice_ratio
                   missing(i)=true;
               end
           else
               if nleft/nright>params.max_choice_ratio
                   missing(i)=true;
               end
           end
       end
    end
    missing_trials = ismember(gidx,find(missing)) | trial_data_has_nans; % trials with no match or invalid trial data
    if any(missing_trials)
        warning('%d trials with no matches or invalid values for match fields.',sum(missing_trials));
    end
    
    gidx=gidx(~missing_trials);
    match_idx=NaN(sum(~missing_trials),params.n_resamples);
    
    
    for i=1:max(gidx)
       this_match_idx = find(gidx==i);
       n_matches=numel(this_match_idx);
       if n_matches<params.min_trials
            match_idx(this_match_idx,1:params.n_resamples)=NaN;
            continue
       end
       for n=1:params.n_resamples
           repeated=true;
           while repeated
                roll = randperm(n_matches);
                repeated = any(roll==(1:n_matches));
           end
           match_idx(this_match_idx,n) = this_match_idx(roll);
       end
    end    
    if ~all(match_idx(:)>0)
        error('Some match indices are invalid. Something has gone wrong.');
    end
end