% FIGURE 2B
% Illustration of choice decoding procedure
% For illustration purposes only, this code first projects population
% activity down onto the first two choice-predictive axes and only shows correct trials.

%% load data
load(fullfile(repo_path,'/data/figure_DVsAndCorrelations/figure_DVsAndCorrelations_example_choice_prediction_in_pc_space.mat'));
X=binned_spikes;

%% subselect trials, PCs and timpoints
rng(12); % make trial subselection deterministic
timebin=[3 7 17]; % indices for timepoints 0.1, 0.3 and 0.8 relative to first click
pcs=[1 2]; % first two choice pcs
n=150; % 150 example trials
this_X = squeeze(-X(:,timebin(end),pcs));  
good = find(~any(isnan(this_X),2) & res.Trials.is_hit);
samps=[randsample(good,n)];
samps = [randsample(samps(res.Trials.pokedR(samps)==1),1);samps];

%% setup figure
figure('position',[173 608 762 239]); hold on;
props={'Marker','o','SizeData',50,'MarkerFaceAlpha',0.5,'MarkerEdgeColor','none','MarkerFaceColor',right_color};

%% make plots
for i=1:3
    subplot(1,3,i);
    this_X = squeeze(-X(:,timebin(i),pcs));  
    this_X=this_X(samps,:);
    idx = res.Y(samps)==1;
    scatter(this_X(idx,1),this_X(idx,2),props{:});
    hold on;
    scatter(this_X(~idx,1),this_X(~idx,2),props{:},'MarkerFaceColor',left_color);
    scatter(this_X(1,1),this_X(1,2),props{:},'MarkerFaceColor','r','MarkerFaceAlpha',1);
    set(gca,'xlim',[-120 120],'ylim',[-120 120]);
    set(gca,'xtick',[],'ytick',[]);
    if i==1
        xlabel('PC1');ylabel('PC2');
    end
    quiver(0,0,-res.beta(1+pcs(1),timebin(i))*1500, -res.beta(1+pcs(2),timebin(i))*1500,'AutoScale','off','MaxHeadSize',70,'ShowArrowHead',true,'color','k','LineWidth',2);        
    title(sprintf('t = %g s',res.bin_params.time_s(timebin(i))));
end

%% save output
common.savefig(gcf,mfilename);