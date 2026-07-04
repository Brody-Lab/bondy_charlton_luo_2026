% FIGURE 2C
% Illustration of example single-trial DVs (goes with Fig. 2B)

%% load data
data=load(fullfile(repo_path,'/data/figure_DVsAndCorrelations/figure_DVsAndCorrelations_example_choice_prediction_in_pc_space.mat'));
X=data.binned_spikes;

%% subselect trials, PCs and timpoints (same as Fig. 2b)
rng(12); % make trial subselection deterministic
timebin=[3 7 17]; % indices for timepoints 0.1, 0.3 and 0.8 relative to first click
pcs=[1 2]; % first two choice pcs
n=150; % 150 example trials
this_X = squeeze(-X(:,timebin(end),pcs));  
good = find(~any(isnan(this_X),2) & data.res.Trials.is_hit);
samps=[randsample(good,n)];
samps = [randsample(samps(data.res.Trials.pokedR(samps)==1),1);samps];

%% make plot
figure('position',[1000 888 372 350]);hold on;
idx=intersect(find(data.res.Y==1),samps);
plot(data.res.bin_params.time_s,data.res.log_odds(idx,:),'color',right_color,'LineWidth',1);hold on;
idx=intersect(find(data.res.Y==0),samps);
plot(data.res.bin_params.time_s,data.res.log_odds(idx,:),'color',left_color,'LineWidth',1);hold on;
plot(data.res.bin_params.time_s,data.res.log_odds(samps(1),:),'color','r','LineWidth',2);hold on;
plot(data.res.bin_params.time_s(timebin),data.res.log_odds(samps(1),timebin),'color','r','LineStyle','none','Marker','o','MarkerFaceColor','r');hold on;
xlim([0 0.95]);
xlabel('Time since first click (s)');
ylabel('dmFC DV');
set(gca,'xtick',data.res.bin_params.time_s(timebin),'xgrid','on','ylim',[-10 10]);

%% save output
common.savefig(gcf,mfilename);