function [res,X] = predict_from_cells(Cells,varargin)

    % perform choice decoding analysis on a Cells file.
    % uses relaxed lasso regularization. 
    % requires Brody Lab repo neuro_glmnet be in your matlab path
    % times after stimulus off are not included (filled wih NaNs)

    %% parse and validate input args
    p=inputParser;
    p.KeepUnmatched=true;
    p.addParameter('regions',{},@(x)validateattributes(x,{'char','string','cell'},{'nonempty'}));
    p.addParameter('seed',1,@(x)validateattributes(x,{'numeric'},{'scalar','positive','integer'}));        % used when resampling neurons
    p.addParameter('trial_idx',true(numel(Cells.Trials.pokedR),1),@(x)validateattributes(x,{'logical'},{'vector'})); 
    p.addParameter('hemisphere',["left" "right"]);
    p.addParameter('unit_include_idx',[],@(x)validateattributes(x,{'numeric'},{'integer','positive'})); 
    params = DV.parse_args(p,varargin{:});  
    
    if params.use_simulated_spikes
        if params.variable~="choice"
            error('Currently we only support predicting choice from simulated spikes. Previous choice and reward aren''t dealt with yet -- remember these are previous simulated choices and reward, not what the animal did.');
        end
        if ~isfield(Cells,'sim_spike_trains')
            error('Cells struct has no field "sim_spike_trains. Cannot predict using simulated spikes.');
        end
    end

    %% apply trial exclusion criteria   
    nan_ref_event = isnan(Cells.Trials.stateTimes.(params.ref_event));
    if any(nan_ref_event)
        params.trial_idx = params.trial_idx & ~nan_ref_event;
        fprintf('%d trials where ref_event %s is NaN. Removing them.\n',sum(nan_ref_event),params.ref_event);
    end    
    if ~all(params.trial_idx)
        Cells.Trials = remove_trials(Cells.Trials,~params.trial_idx);
    end
    nTrials = numel(Cells.Trials.pokedR);            
    if params.use_simulated_spikes
        Cells.sim_spike_trains.first_click = Cells.sim_spike_trains.first_click(params.trial_idx);
    end        

    %% apply unit inclusion criteria
    if ~isempty(params.unit_include_idx)
        if any(params.unit_include_idx>sum(Cells.ncells))
            error('members of unit_include_idx cannot exceed number of cells in Cells file.');
        end
        if numel(unique(params.unit_include_idx))<numel(params.unit_include_idx)
            error('Members of unit_include_idx must be unique');
        end
        unit_include_idx = params.unit_include_idx;
        warning('region, hemisphere arguments, random sampling args and inclusion criteria will be ignored because user specified units to include manually.');
    else
        if ~isempty(params.regions)
            if isfield(Cells,'region')
                in_region_idx = ismember(Cells.region,params.regions) & ismember(Cells.hemisphere,params.hemisphere) ;
            else
                in_region_idx = ismember ( uberphys.lookup_brainregion (Cells.electrode,Cells.probe_serial) , params.regions ) & ismember(Cells.hemisphere,params.hemisphere);
            end
        else
            in_region_idx = ismember(Cells.hemisphere,params.hemisphere);
        end
        if params.use_simulated_spikes
            unit_include_idx = find(in_region_idx);         
        else
            unit_include_idx = find(uberphys.apply_inclusion_criteria(Cells,'quiet',true,'min_value_field','min_value_dv','max_value_field','max_value_dv') & in_region_idx); 
        end
    end
    n_units = numel(unit_include_idx);
    
    % apply unit resampling
    if n_units>params.max_units && isempty(params.unit_include_idx)
        fprintf('Randomly sampling %d of %d units.\n',params.max_units,n_units);
        rng(params.seed);
        unit_include_idx  = randsample(unit_include_idx,params.max_units);
        n_units = params.max_units;
    end

    %% perform population splits
    if params.nsplits>1
        if params.nsplits>n_units
            error('fewer units than nsplits.');
        end
        rng(params.seed);        
        partition = cvpartition(numel(unit_include_idx),"KFold",params.nsplits);
        fprintf('Splitting units into %d groups.\n',params.nsplits);
        for n=params.nsplits:-1:1
            fprintf('Using split %d:\n\n',n);
            res(n) = DV.predict_from_cells(Cells,params.variable,varargin{:},'nsplits',1,'unit_include_idx',unit_include_idx(partition.test(n)));
        end
        return        
    end

    %% determine fitting time ranges depending on reference event 
    params = get_interval(Cells.Trials.stim_dur_s,params);

    %% get binned spike trains
    fprintf('Making design matrix ... ');tmp=tic;
    [binned_spikes,bin_params] = uberphys.make_binned_spike_trains(Cells,params,'units',unit_include_idx);
    fprintf('took %s.\n',timestr(toc(tmp)));
    nbins = numel(bin_params.time_s);         
    
    %% mask times after stim off
    if params.ref_event=="clicks_on" || params.ref_event=="first_click"
        if params.variable=="evidence"
            stim_dur_s=Cells.Trials.stateTimes.cpoke_req_end - Cells.Trials.stateTimes.(params.ref_event) ;            
        else
            stim_dur_s=Cells.Trials.stateTimes.cpoke_out - Cells.Trials.stateTimes.(params.ref_event) ;
        end
        for i=1:nTrials
           binned_spikes(i,bin_params.time_s>stim_dur_s(i),:) = NaN; 
        end 
    elseif contains(params.ref_event,"commit") % mask times before first click and after cpoke_out
        stim_dur_s= Cells.Trials.stateTimes.first_click - Cells.Trials.stateTimes.(params.ref_event)  ;
        if contains(params.variable,"evidence")
            stim_dur_s=stim_dur_s+0.1;
        end
        for i=1:nTrials
           binned_spikes(i,bin_params.time_s<stim_dur_s(i),:) = NaN; 
        end
        if contains(params.variable,"evidence")
            stim_dur_s= Cells.Trials.stateTimes.cpoke_req_end - Cells.Trials.stateTimes.(params.ref_event)  ;            
        else
            stim_dur_s= Cells.Trials.stateTimes.cpoke_out - Cells.Trials.stateTimes.(params.ref_event)  ;
        end
        for i=1:nTrials
           binned_spikes(i,bin_params.time_s>stim_dur_s(i),:) = NaN; 
        end   
    elseif params.ref_event=="cpoke_out" % mask times before first click
        stim_dur_s= Cells.Trials.stateTimes.first_click - Cells.Trials.stateTimes.(params.ref_event)  ;
        for i=1:nTrials
           binned_spikes(i,bin_params.time_s<stim_dur_s(i),:) = NaN; 
        end      
    end

    %% create variable being predicted ("y")
    family='binomial';       
    switch params.variable
        case 'choice'
            if params.use_simulated_spikes
                y_rat=Cells.Trials.pokedR;                
                y = Cells.Trials.sim_pokedR;
                if mean(y==y_rat)<0.7
                    error('mmddm disagrees with rat''s choices more than 30% of the time. Something may be wrong here.');
                end
            else
                y=Cells.Trials.pokedR;                
            end
        case 'previous_choice'
            y=Cells.Trials.previous_pokedR;
        case 'previous_reward'
            y=Cells.Trials.previous_is_hit;
        case 'previous_rewardxchoice' % interaction of previous reward and choice
            y=Cells.Trials.previous_rewardxchoice;
        case 'evidence'
            y = uberphys.get_binned_delta_clicks(Cells,'resolution_s',params.resolution_s,'interval',params.interval-params.delay_s,'ref_event',params.ref_event);
            family='gaussian';       
        case 'accumulated_evidence'
            y = uberphys.get_binned_delta_clicks(Cells,'resolution_s',params.resolution_s,'interval',params.interval-params.delay_s,'ref_event',params.ref_event);
            y = cumsum(y,2);
            family='gaussian';
    end

    %% standardize binned spikes (separately for each time point) and apply PCA if requested
    for i=1:size(binned_spikes,2)
        binned_spikes(:,i,:) = bsxfun(@minus,squeeze(binned_spikes(:,i,:)) , nanmean(squeeze(binned_spikes(:,i,:))));
    end
    if params.npcs>=nbins && ~ismember('npcs',p.UsingDefaults)
        params.npcs=n_units;
        warning('You specified more PCs than neurons. PCA will not be performed.');
    end     
    loadings=[];     
    if params.npcs<nbins
        fprintf('Using %d PCs.\n',params.npcs);
        [binned_spikes,loadings] = DV.get_signal_pcs(binned_spikes,y,params);
    end
    % for i=1:size(binned_spikes,3)
    %     for k=1:size(binned_spikes,2)
    %         scale=(squeeze(binned_spikes(:,k,i)));
    %         scale = scale(:);
    %         scale=scale(~isnan(scale));
    %         sc(i)=range(scale(:))+5;
    %         sc(sc==0)=1;
    %         sc(isnan(sc))=1;
    %         binned_spikes(:,k,i) = binned_spikes(:,k,i)./sc(i);
    %     end
    % end       

    %% create design matrix X and add trial history regressor if requested 
    if params.trial_history_regressor
        if params.use_simulated_spikes
           error('trial_history_regressor not implemented with use_simulated_spikes. not clear what you want to do here, since model makes different choices from animal and doesn''t care about trial history.'); 
        end
        prev_choices = Cells.Trials.previous_pokedR-0.5;
        prev_rewards = Cells.Trials.previous_is_hit-0.5;
        prev_choices(isnan(prev_choices))=0;
        prev_rewards(isnan(prev_rewards))=0;
        z=median(std(binned_spikes(:,1,:)));
        X_hist = [prev_choices prev_rewards prev_choices.*prev_rewards];
        X_hist = zscore(X_hist)*z;
        X_hist = permute(X_hist,[1 3 2]);
        X=cat(3,binned_spikes,repmat(X_hist,[1 size(binned_spikes,2) 1]));
    else
        X=binned_spikes;
    end

    %% set up arguments for glmnet
    if params.fit_average
        is_in_fit_interval = bin_params.time_s>=params.fit_interval(1) & bin_params.time_s<=params.fit_interval(2);
        xargs={'X_fit',squeeze(nanmean(X(:,is_in_fit_interval,:),2))};
    else
        xargs={};
    end
    % make opt struct (could be sep function)
    opt=glmnetSet(struct('alpha',params.alpha,'relaxed',params.relaxed)); 
    opt.control=glmnetControl(struct('factory',true)); % reset to defaults
    opt.control=glmnetControl(mysetfield(opt.control,'fdev',0,'devmax',1,'mnlam',opt.nlambda)); 
    opt.quiet=true;
    if opt.alpha==0
        opt.relaxed=false;
    end    
    if opt.relaxed
        opt.nlambda=50;
        opt.lambda_min=5e-7;       
    else
        opt.nlambda=50;
        %opt.lambda_min = 1e-5;
    end
    
    %% call glmnet
    if contains(params.variable,"evidence")
        for i=1:size(y,2)
            tmp = neuro_glmnet(squeeze(X(:,i,:)),y(:,i),varargin{:},'family',family,'options',opt,...
                'kfold',params.kfold,'timepoint_pcs',params.timepoint_pcs,xargs{:});
            fields={'Y','Y_hat','Y_hat_null','proj','eta','proj_same_lambda','eta_same_lambda','Y_hat_same_lambda'};            
            for f=1:numel(fields)
                if isfield(tmp,fields{f})
                    res.(fields{f})(:,i) = tmp.(fields{f});
                end
            end
            res.cvfit(i) = tmp.cvfit;
            res.beta(:,i) = tmp.beta;
            res.beta_same_lambda(:,i)=tmp.beta_same_lambda;
            if isfield(tmp,'covb')
                res.covb(:,:,i) = tmp.covb;
            end
            res.metrics(i) = tmp.metrics; 
        end
    else
        res = neuro_glmnet(X,y,varargin{:},'family',family,'options',opt,'kfold',params.kfold,xargs{:},'force_3d',true,'timepoint_pcs',params.timepoint_pcs);
    end

    if ~isempty(params.timepoint_pcs)
        Xhat=X(:,:,1:params.timepoint_pcs);        
        for k=1:size(X,2)
            Xhat(:,k,:) = squeeze(X(:,k,:))*res.pca_loadings;
        end    
        X=Xhat;
    end

    %% format output structure
    res.bin_params=bin_params;
    res.family=family;    
    for i=1:size(X,2)
        if params.fit_average
            B = res.beta(2:end);
            a0=res.beta(1);
        else
            B = res.beta(2:end,i);
            a0=res.beta(1,i);   
            B_same_lambda = res.beta_same_lambda(2:end,i);
            a0_same_lambda=res.beta_same_lambda(1,i); 
            res.log_odds_same_lambda(:,i) = squeeze(X(:,i,:)) * B_same_lambda + a0_same_lambda;
            res.DV_same_lambda(:,i) = squeeze(X(:,i,:)) * B_same_lambda./norm(B_same_lambda) ;            
            if ~any(B_same_lambda)
                res.DV_same_lambda(:,i)=0;
            end
        end
        res.log_odds(:,i) = squeeze(X(:,i,:)) * B + a0; % same as eta but not cross-validated
        res.DV(:,i) = squeeze(X(:,i,:)) * B./norm(B) ; % same as proj but not cross-validated                    
        if ~any(B)
            res.DV(:,i)=0;
        end
    end   
    
    if ~params.use_simulated_spikes
        res.mean_AP = mean(Cells.AP(unit_include_idx));
        res.mean_DV = mean(Cells.DV(unit_include_idx));
        res.mean_ML = mean(Cells.ML(unit_include_idx));   
    end
    if ~isfield(res,'pca_loadings')
        res.pca_loadings=loadings;
    end
    res.Trials=Cells.Trials;
end


function s = mysetfield(s,varargin)
    j=1;
    while j<=length(varargin)
        s.(varargin{j}) = varargin{j+1};    
        j=j+2;
    end
end

function params = get_interval(stim_dur,params)
    switch params.ref_event
        case {'clicks_on','first_click'}
            params.interval = [-params.resolution_s/2 1.2] ;
            if params.variable=="previous_reward"
                params.interval = [-params.resolution_s/2 1] ;
            end                    
            if isempty(params.fit_interval)
                params.fit_interval = [0.2 1.2] ;
            end     
            if contains(params.variable,"evidence")
                params.interval = [0.1-params.resolution_s/2 1];
                params.fit_interval=[0.1-params.resolution_s/2 1];
            end         
            if params.use_simulated_spikes
                params.interval = [ 0 1];
                params.fit_interval = [0.2 1];
                fprintf('For MMDDM-simulated spikes, a time interval of [0,1] relative to first click will be enforced.\n');
            end
        case {'cpoke_req_end','clicks_off'}
            params.interval = [-0.9 0] * roundToNearestMultiple(max(stim_dur),params.resolution_s);  
            if isempty(params.fit_interval)
                params.fit_interval = [-0.7 0] * roundToNearestMultiple(max(stim_dur),params.resolution_s);
            end          
            if ~contains(params.variable,"evidence")
                params.interval(2)=params.resolution_s/2;
                params.fit_interval(2)=params.resolution_s/2;                
            end
        case 'cpoke_out'
            if params.use_simulated_spikes
                endpt = [0 0 0];
            else
                endpt = [0.5 0.3 0.5];
            end
            params.interval = [-1 endpt(1)] * roundToNearestMultiple(max(stim_dur),params.resolution_s);
            if isempty(params.fit_interval)
                params.fit_interval = [-0.8 endpt(2)] * roundToNearestMultiple(max(stim_dur),params.resolution_s);
            end  
            if params.variable=="previous_reward"
                params.interval = [-1 endpt(3)] * roundToNearestMultiple(max(stim_dur),params.resolution_s);
            end                                     
        otherwise
            if contains(params.ref_event,"commit")
                params.interval = [-0.625 0.625];
                if isempty(params.fit_interval)    
                    params.fit_interval = [-0.5 0.5];
                end
                if params.variable=="previous_reward"
                    params.interval = [-0.6 0.6];
                end      
            else
                error('new reference event. make sure interval and fit_interval make sense.')
            end
    end
end