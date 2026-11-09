% TODO, easy parameter for one fit across timepoints, same lambda  across
% timepoints
%some timepoints are crashing. don't know why
% when i predict residuals from residuals I get basically no prediction.
% not clear why that is. shuffle prediction does worse, so this seems at
% odd.

% 
 sessions=uberphys.load_bcl_sessions_table();
 ref_event = 'first_click';
 opt = glmnetSet(struct('alpha',0.95,'relaxed',false,'balance_classes',false,'quiet',true));
 %res = DV.load_DVs('fit_average',false,'reward_reversal',false,'alpha',0.95,'frozen',true,'ref_event',ref_event,'by_hemisphere',false,'causal',false,'by_region',true);
 %res=res(sessions.frozen==true);
 %res=res([1:3,5:end]); % 2023-09-08 doesn't have syncable video right now
 control_fields = {'seed','pokedR'};
% time_lim_s = [-0.5 0.5];
path = fileparts(which(mfilename));
ext={'png','fig','pdf'};
clear DVs
 offsets=[-0.3 -0.25 -0.2 -0.15 -0.1 -0.05 0 0.05 0.1 0.15 0.2 0.25 0.3];
for i=1:numel(res)
    if iscell(res{i})
        res{i} = res{i}{1};
    end
        for k=numel(res{i}):-1:1
            res{i}(k).DV = res{i}(k).log_odds;
        end    

        %% remove all uncommitted or unmatched trials
        remove_trial = isnan(res{i}(1).Trials.stateTimes.(ref_event));
        res{i} = DV.remove_trials_from_res(res{i},remove_trial);
        if ~isempty(control_fields)
            [~,gidx,missing_trials] = DV.find_matched_trials(res{i}(1).Trials,control_fields); 
            res{i} = DV.remove_trials_from_res(res{i},missing_trials);        
        end

        time_s = res{i}(1).bin_params.time_s;
        clear DVs      
        for k=numel(res{i}):-1:1
            DVs{i}{k} = res{i}(k).DV;
        end      

        if ~isempty(control_fields)    
            for k=numel(res{i}):-1:1
                DVs{i}{k} = DV.subtract_group_mean(DVs{i}{k},gidx,'exclude_self',false);
                res{i}(k).DV = DVs{i}{k};
            end    
        end

        for o=1:numel(offsets)
            latents{i} = uberphys.get_aligned_motor_latents(char(res{i}(1).Trials.rat(1)),datestr(res{i}(1).Trials.sess_date(1),'YYYY-mm-DD'),...
                ref_event,time_s+offsets(o),["cpoke_in" "cpoke_out"],res{i}(1).Trials);

            if ~isempty(control_fields)    
                for g=1:size(latents{i},3)
                    latents{i}(:,:,g) = DV.subtract_group_mean(squeeze(latents{i}(:,:,g)),gidx,'exclude_self',false);                    
                end              
            end

            nans = isnan(DVs{i}{1});

            for k=numel(res{i}):-1:1
                for t=numel(time_s):-1:1
                    X=squeeze(latents{i}(:,t,:));
                    Y=DVs{i}{k}(:,t);
                    if numel(unique(Y(~isnan(Y))))>1 && sum(~isnan((X(:,1))))>10
                        res{i}(k).fit(o,t) = neuro_glmnet(X,Y,'family','gaussian','options',opt,'foldseed',1);   
                        if offsets(o)==0
                            Y_not_nan = Y(~isnan(Y));
                            Y_not_nan = Y_not_nan(randder(numel(Y_not_nan)));
                            Y(~isnan(Y)) = Y_not_nan;
                            res{i}(k).shuffle_fit(t) = neuro_glmnet(X,Y,'family','gaussian','options',opt,'foldseed',1);                           
                        end
                    else
                        res{i}(k).fit(o,t)=res{i}(end).fit(end);
                        res{i}(k).fit(o,t).Y = DVs{i}{k}(:,t);
                        res{i}(k).fit(o,t).Y_hat = NaN(size(DVs{i}{k}(:,t)));      
                        if offsets(o)==0
                            res{i}(k).shuffle_fit(t) = res{i}(k).fit(o,t);
                        end
                    end           
                end             
            end
        end
end
path = fileparts(which(mfilename));
ext={'png','fig','pdf'};
% 

f={'cvfit','neuro_glmnet_params','Y_hat_null','proj','eta','proj_same_lambda','eta_same_lambda','Y_hat_same_lambda'};
for s=1:numel(res)
    for r=1:numel(res{s})
        res{s}(r).fit = myrmfield(res{s}(r).fit,f);
        res{s}(r).shuffle_fit = myrmfield(res{s}(r).shuffle_fit,f);
    end
    res{s} = myrmfield(res{s},f);    
end

save(fullfile(path,'dv_residual_predictions_offsets_2025.mat'),'res','offsets','-v7.3');


function struct = myrmfield(struct,fields)
    for i=1:numel(fields)
        if isfield(struct,fields{i})
            struct=rmfield(struct,fields{i});
        end
    end
end