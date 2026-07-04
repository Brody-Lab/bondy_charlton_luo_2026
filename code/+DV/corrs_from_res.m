function [combined,corrs] = corrs_from_res(res,varargin)

    % generates corrs structures for DVs in res, and one that combines
    % across sessions

    %% parse and validate inputs
    p=inputParser;
    p.addParameter('field','log_odds_same_lambda',@(x)validateattributes(x,{'string','char'},{'nonempty','vector'}));
    p.addParameter('nresamples',50,@(x)validateattributes(x,{'numeric'},{'scalar','positive','integer'}));
    p.addParameter('resample_idx',1,@(x)validateattributes(x,{'numeric'},{'scalar','positive','integer'}));    
    p.addParameter('control_for',{},@(x)validateattributes(x,{'cell'},{}));
    p.addParameter('correction_type','mean_subtract',@(x)validateattributes(x,{'string','char'},{'nonempty','vector'}));
    p.addParameter('ref_event','',@(x)validateattributes(x,{'string','char'},{}));
    p.addParameter('time_lim_s',[-Inf Inf],@(x)validateattributes(x,{'numeric'},{'numel',2,'increasing'}));
    p.addParameter('invert_combine',false); % set to true if there is an arbitrary sign convention in the variable being correlated that you want to abstract over, like FR or PC1
    p.parse(varargin{:});
    params=p.Results;
    if isempty(params.ref_event)
        params.realign=false;
    else
        params.realign=true;
    end
    if isempty(params.control_for)
        params.apply_correction=false;
    else
        params.apply_correction=true;
    end
    validatestring(params.correction_type,{'mean_subtract','shuffle','mean_replace'},mfilename,'correction_type');
    
    % loop over sessions
    n_sess = numel(res);
    for i=n_sess:-1:1

        %% reformat res
        if numel(res{i})>params.resample_idx
            error('res structure has fewer elements than requested resample index.');
        end
        res{i} = res{i}{params.resample_idx};
        n_regions = numel(res{i});
        Trials = res{i}(1).Trials;
        res{i} = rmfield(res{i},'Trials');
        time_s = res{i}(1).bin_params.time_s;

                % remove_trial = isnan(Trials.stateTimes.committime_s_M1);
                % res{i} = DV.remove_trials_from_res(res{i},remove_trial);
                % Trials = common.remove_trials(Trials,remove_trial);
        %% remove NaN reference event trials and unmatched trials
        if params.realign
            if params.ref_event == "custom_committime"
                Trials = add_custom_committime(Trials);
            end
            if isfield(Trials.stateTimes,params.ref_event)
                if res{i}(1).params.ref_event==string(params.ref_event)
                    params.realign=false;
                end        
                remove_trial = isnan(Trials.stateTimes.(params.ref_event));
                res{i} = DV.remove_trials_from_res(res{i},remove_trial);
                Trials = common.remove_trials(Trials,remove_trial);
            else
                error('%s is not a field of stateTimes.',params.ref_event);
            end
        end
        if params.apply_correction
            [match_idx,gidx,missing_trials] = DV.find_matched_trials(Trials,params.control_for,'n_resamples',params.nresamples); 
            res{i} = DV.remove_trials_from_res(res{i},missing_trials);  
            Trials = common.remove_trials(Trials,missing_trials);            
        end        

        %% get DVs
        if ~isfield(res{i},params.field)
            error('res structure does not contain requested field: %s.',params.field);
        end    
        clear DVs DVs_shuffled   
        for k=n_regions:-1:1
            DVs{k} = res{i}(k).(params.field);
        end      
        DVs_shuffled=cell(1,n_regions);      

              %% apply correction 
        if params.apply_correction 
            [DVs,DVs_shuffled] = do_correction(DVs,params.correction_type,gidx,match_idx);
        end  

        % for k=1:numel(DVs)
        %     DVs{k}(:,1:4)=NaN;
        % end

        %% realign to new reference event if necessary
        if params.realign
            t0=Trials.stateTimes.(params.ref_event)- Trials.stateTimes.(res{i}(1).params.ref_event);      
            for k=n_regions:-1:1
                [DVs{k},time_s] = DV.realign_DVs(DVs{k},res{i}(k).bin_params.time_s,t0);
                if ~isempty(DVs_shuffled{1})
                    for n=1:params.nresamples
                        DVs_shuffled{k}{n} = DV.realign_DVs(DVs_shuffled{k}{n},res{i}(k).bin_params.time_s,t0);       
                    end
                end
            end
        end    



        %% calculate correlations   
        c = DV.DV_correlation(DVs,time_s,'time_lim_s',params.time_lim_s,'DVs_shuffled',DVs_shuffled);
        corrs(i) = add_identifiers_to_corrs(c,res{i},Trials);

    end
    combined = DV.combine_corrs(corrs);
end

function corrs = add_identifiers_to_corrs(corrs,res,Trials)
    corrs.rat=unique(Trials.rat);        
    corrs.sess_date = unique(Trials.sess_date);
    corrs.sessid = unique(Trials.sessid);    
    corrs.regions = [res.region]';
    corrs.hemisphere = [res.hemisphere]';
    if ~isfield(res,'split')
        corrs.split = ones(size(corrs.regions));
    else
        corrs.split = [res.split]';
    end
    corrs.n_units = [res.n_units]';  
end

function [DVs,DVs_shuffled] = do_correction(DVs,correction_type,gidx,match_idx)
    switch correction_type
        case "mean_subtract"
            for k=numel(DVs):-1:1
                DVs{k} = DV.subtract_group_mean(DVs{k},gidx);
                DVs_shuffled{k}=[];                
            end
        case "mean_replace"
            for k=numel(DVs):-1:1
                DVs{k} = DV.replace_with_group_mean(DVs{k},gidx);
                DVs_shuffled{k}=[];                
            end            
        case "shuffle"
            clear DVs_shuffled
            for k=numel(DVs):-1:1
                DVs_shuffled{k} = DV.get_shuffled_DVs(DVs{k},match_idx);
            end
    end
end