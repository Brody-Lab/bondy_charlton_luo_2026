% TODO, easy parameter for one fit across timepoints, same lambda  across
% timepoints
%some timepoints are crashing. don't know why
% when i predict residuals from residuals I get basically no prediction.
% not clear why that is. shuffle prediction does worse, so this seems at
% odd.


sessions=uberphys.load_bcl_sessions_table();
sessions = sessions(sessions.recording_id~="A327_2023_09_08",:);
sessions = sessions(sessions.recording_id~="C211_2023_12_14",:);
ref_event = 'first_click';
opt = glmnetSet(struct('alpha',0.95,'relaxed',false,'balance_classes',false,'quiet',true));
% for i=1:height(sessions);
%     Trials(i) = uberphys.load_trials(string(sessions.recording_id(i)));
%             remove_trial = validate_trials(Trials(i));
%         Trials(i) = remove_trials(Trials(i),remove_trial);
%         Trials(i) = uberphys.add_Tc_to_Trials(Trials(i));  
%         bad = isnan(Trials(i).stateTimes.(ref_event));
%         Trials(i) = remove_trials(Trials(i),bad);
% end
path = fileparts(which(mfilename));
ext={'png','fig','pdf'};
time_s =  [0.025:0.05:1];
clear fit accuracy
for i=1:numel(Trials)



        


            latents{i} = uberphys.get_aligned_motor_latents(char(Trials(i).rat(1)),datestr(Trials(i).sess_date(1),'YYYY-mm-DD'),...
                ref_event,time_s,["cpoke_in","cpoke_out"],Trials(i));
            

            
            


                for t=1:numel(time_s)   
                    if i==1 && k==1 && t==1
                        %tmp=res{i}(k).fit(o,t);                    
                    end
                    X=squeeze(latents{i}(:,t,:));
                    Y=Trials(i).pokedR;
                    fit{i}(t) = neuro_glmnet(X,Y,'family','binomial','options',opt,'foldseed',1);           
                    accuracy(i,t) = fit{i}(t).metrics.balanced_accuracy;
                end
                %DV_pred{i}{k}=[glm_res{i}{k}.Y_hat];           
                %DV_resid{i}{k}=[glm_res{i}{k}.Y] - [glm_res{i}{k}.Y_hat];              
end
path = fileparts(which(mfilename));
boots=bootstrp(1000,@nanmean,accuracy);
figure;
plot(time_s,accuracy','color',[1 1 1]/2);
hold on;

shadedErrorBar(time_s,boots,{@nanmean,@nanstd});

xlabel('Time (s) after first click');
ylabel('Choice Prediction Accuracy');
box off;
set(gca,'ylim',[0.5 1]);
ext={'png','fig','pdf'};
res = DV.load_DVs('fit_average',false,'reward_reversal',false,'alpha',0.95,'frozen',false,'ref_event',ref_event,'by_hemisphere',false,'causal',false,'by_region',false);
hold on;DV.plot_combined_metric(res,'balanced_accuracy',"","",[ 0 0 0],[0 1]);hold on;
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['mean_choice_prediction_accuracy.',ext{i}]));
end

figure;
clear h
for t=1:3
    colors=parula(16);subplot(3,1,t);
    for i=1:16
        h(i)=plot(time_s,squeeze(latents{1}(t,:,i)),'color',colors(i,:));hold on;
        xlabel('Time (s) after first click');
    end;
    title(sprintf('Trial %d',t));
    box off;
    if t==1
        legend(h,strcat("latent ",string(1:16)),'NumColumns',4);
    end
end
matchylim(gcf);
matchxlim(gcf);
%save(fullfile(path,'dv_residual_predictions_offsets.mat'),'res','offsets','-v7.3');
% 
for i=1:numel(ext)
    saveas(gcf,fullfile(path,['example_trials.',ext{i}]));
end