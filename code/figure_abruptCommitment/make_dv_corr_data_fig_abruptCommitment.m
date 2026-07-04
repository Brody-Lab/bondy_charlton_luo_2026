path = ["A324_2023_07_19a";
    "A324_2023_07_20";
    "A324_2023_07_21";
    "A324_2023_07_22";
    "A324_2023_07_23";
    "A324_2023_07_24";
    "A324_2023_07_25";
    "A327_2023_08_31";
    "A327_2023_09_01";
    "A327_2023_09_02";
    "A327_2023_09_03";
    "A327_2023_09_04";
    "A327_2023_09_08";
    "C211_2023_12_14";
    "C211_2023_12_17";
    "C211_2023_12_18";
    "C211_2023_12_19";
    "C211_2023_12_30";
    "C211_2023_12_31"];

clear data
for i=1:numel(path)
    data{i} = load("D:\DVs_latest\" + path(i) + "_DVs.mat");
end

regions = DV.get_brain_regions;
r=0;
for region = regions
r=r+1;
params.region_i = region;
params.subtract_aft = 0; % 0: subtract before; 1: subtract after;
% time relative to nTc
params.thre_clicks_bef = -0.4;
params.thre_clicks_aft = 0.3;
params.thre_DV_bef = -0.4;
params.thre_DV_aft = 0.6;
params.offset=0;
params.nboot=300;
params.thre_trial = 1200;
% trial threshold in column mean

[delta_clicks_aligned,DV_aligned,sess_idx] = process_data(data,path,params);

% time aligned
time_clicks = round(params.thre_clicks_bef:0.05:params.thre_clicks_aft,3)+params.offset;
time_DV = round(params.thre_DV_bef:0.05:params.thre_DV_aft,3)+params.offset;
%% The whole correlation matrix
% Compute the correlation matrix and trial numbers

corr_mat = NaN(size(DV_aligned,2), size(delta_clicks_aligned,2));
corr_num = zeros(size(DV_aligned,2), size(delta_clicks_aligned,2));

for j = 1:size(delta_clicks_aligned,2)
    for i = 1:size(DV_aligned,2)
        % trial index
        idx = ~isnan(DV_aligned(:,i)) & ~isnan(delta_clicks_aligned(:,j));
        if sum(idx) == 0 % no trial for this pixel
            continue
        else
            % correlation matrix
            corr_mat(i,j) = corr(DV_aligned(idx,i), delta_clicks_aligned(idx,j));
            % number of trials in the pixel
            corr_num(i,j) = sum(idx);
        end
    end
end
% Pixels above threshold trial number

isAboveThre = corr_num >= params.thre_trial; % (ntimes_DV, ntimes_click)
pixBelowThre = findFirstZeroVec(isAboveThre); % (1, ntimes_click)
yAboveThre = [pixBelowThre(1), pixBelowThre, pixBelowThre(end)]; % (1, ntimes_click+2)
%% Plot the whole matrix


col_before_idx = find(time_clicks < 0);
% delta_clicks_aligned before nTc
delta_clicks_diag = delta_clicks_aligned(:, col_before_idx);
% time_clicks before nTc
time_clicks_diag = time_clicks(col_before_idx);
% get diagonal mean before nTc
[diag_mean, diag_idx, diag_lower, diag_upper] = diagonalMean(delta_clicks_diag, DV_aligned, time_clicks_diag, time_DV);
% pixels in column mean
[pixel_idx, n_pixels, noiseFloor] = colMeanPixels(corr_mat(:, col_before_idx), diag_lower, time_clicks_diag, time_DV, diag_idx);
%pixel_idx = pixel_idx(pixel_idx>-0.3);

%% Stimulus response curve

idx_bef = find(time_clicks < 0);
idx_aft = find(time_clicks >= 0);



pixBelowThre = ones(size(pixBelowThre))*max(pixBelowThre);
% maximum length of all the curves
maxLength = max(pixBelowThre - (1:length(time_clicks)));
% plot each curve
src_times = 0:0.05:0.05*maxLength;
src = NaN(numel(src_times),length(time_clicks));
for j = 1:length(time_clicks)
    endPixel = pixBelowThre(j)-1;
    src(1:(endPixel-j+1),j) = corr_mat(j:endPixel,j);
end
output(r).src=src;
output(r).src_times=src_times;
output(r).dv_times = time_DV;
output(r).click_times = time_clicks;

% Column mean at each click time
col_mean = zeros(params.nboot,size(delta_clicks_aligned,2));
% Errorbar
err_lower = zeros(size(delta_clicks_aligned,2), 1);
err_upper = zeros(size(delta_clicks_aligned,2), 1);
n=size(delta_clicks_aligned,1);
rng(1);
idx = hierarchical_bootstrp_samples(params.nboot,sess_idx);
for j = 1:size(delta_clicks_aligned,2)
    % condition: on the included diagonal && trial number exceeds threshold
    idx_i = find(time_DV >= round(time_clicks(j)-max(pixel_idx), 3) & time_DV <= round(time_clicks(j)-min(pixel_idx), 3) );
    idx_j = linspace(j, j, length(idx_i));
    % column mean
    if isempty(idx_i)
        col_mean(:,j) = NaN;
        err_lower(j) = NaN;
        err_upper(j) = NaN;
    else
        for i=1:params.nboot
            col_mean(i,j) =  mean_corr(delta_clicks_aligned(idx(:,i),:), DV_aligned(idx(:,i),:), idx_j, idx_i);
        end
    end
    % disp(time_clicks(j));
    % disp(time_DV(idx_i(1)) + "," + time_DV(idx_i(end)));
end
output(r).col_mean = col_mean;
output(r).col_mean_lower = mean(output(r).col_mean) - std(output(r).col_mean);
output(r).col_mean_upper = mean(output(r).col_mean) + std(output(r).col_mean);
output(r).corr_mat = corr_mat;
output(r).corr_num = corr_num;
output(r).noiseFloor = noiseFloor;
output(r).sig_diags = pixel_idx;



% sig_diags=ismember(round((  output(r).click_times - output(r).dv_times'),4),round(output(r).sig_diags,4));
% before_ntc = repmat(output(r).click_times<0,[numel(output(r).dv_times),1]);
% good_pixel = outputri).corr_num>params.thre_trial;



end


%%
function row_idx = findFirstZeroVec(isInclude)
    [m, n] = size(isInclude);
    
    [rows, cols] = meshgrid(1:m, 1:n);
    mask = (rows' >= cols') & (isInclude == 0);
    
    row_idx = linspace(m, m, n);
    for j = 1:n
        first = find(mask(:,j), 1, 'first');
        if ~isempty(first)
            row_idx(j) = first;
        end
    end
end


function [delta_clicks_aligned,DV_aligned,sess_idx] = process_data(data,path,params)

session = repmat(struct(),length(path),1);
for i = 1:length(path)

    r = data{i};
    % DV: (ntrials, ntimes)
    region_idx = find([r.res{1,1}.region]==params.region_i);
    if isempty(region_idx)
        continue
    end
    DV = r.res{1,1}(region_idx).log_odds_same_lambda; % M1
    % time points of DV
    time_DV = r.res{1,1}(region_idx).bin_params.time_s;
    % gamma: (ntrials,1)
    gamma = r.res{1,1}(1).Trials.gamma;
    % first click: (ntrials, 1)
    first_click = r.res{1,1}(1).Trials.stateTimes.first_click;
    % clicks off: (ntrials,1)
    clicks_off = r.res{1,1}(1).Trials.stateTimes.clicks_off;
    % nTc: (ntrials, 1)
    n = load("C:\github\UberPhys\kaiyue\nTc_Loo_0314\" + path(i) + ".mat");
    region_idx = find([n.nTc_Loo.region]==params.region_i);
    if isempty(region_idx)
        disp(['region does not match in session ', num2str(i)]);
    end
    nTc = n.nTc_Loo(region_idx).nTc+params.offset;
    % choice: (ntrials, 1)
    choice = r.res{1,1}(1).Trials.pokedR;

    % delta_clicks: (ntrials, ntimes); bin_centers: (1, ntimes)
    [delta_clicks, time_DC] = get_binned_delta_clicks(r.res{1,1}(1).Trials, 'interval', [0, 1]);

    % subtract mean
    switch params.subtract_aft
        case 0
            DV_centered = subtractMean(DV, gamma);
            delta_clicks_centered = subtractMean(delta_clicks, gamma);
       

            % choose trials with valid nTc
            trial_idx = find(~isnan(nTc));
        
            gamma = gamma(trial_idx,:);
            nTc = nTc(trial_idx);
            first_click = first_click(trial_idx);
            choice = choice(trial_idx,:);
            DV = DV(trial_idx,:);
            delta_clicks = delta_clicks(trial_idx,:);
            DV_centered = DV_centered(trial_idx,:);
            delta_clicks_centered = delta_clicks_centered(trial_idx,:);
        case 1
            % choose trials with valid nTc
            trial_idx = find(~isnan(nTc));
        
            gamma = gamma(trial_idx,:);
            nTc = nTc(trial_idx);
            first_click = first_click(trial_idx);
            choice = choice(trial_idx,:);
            DV = DV(trial_idx,:);
            delta_clicks = delta_clicks(trial_idx,:);
    
            DV_centered = subtractMean(DV, gamma);
            delta_clicks_centered = subtractMean(delta_clicks, gamma);

        case 2
            % choose trials with valid nTc
            trial_idx = find(~isnan(nTc));
        
            gamma = gamma(trial_idx,:);
            nTc = nTc(trial_idx);
            first_click = first_click(trial_idx);
            choice = choice(trial_idx,:);
            DV = DV(trial_idx,:);
            delta_clicks = delta_clicks(trial_idx,:);
    
            unique_gamma = unique(gamma);
            DV_centered = zeros(size(DV));
            delta_clicks_centered = zeros(size(delta_clicks));
            
            for j = 1:length(unique_gamma)
                idx = (gamma == unique_gamma(j));
                dc = 2 * (exp(unique_gamma(j)) - 1) / (1 + exp(unique_gamma(j)));
                DV_centered(idx, :) = DV(idx, :) - mean(DV(idx, :), 1, 'omitnan');
                delta_clicks_centered(idx, :) = delta_clicks(idx, :) - dc;
            end
        otherwise
            disp('Wrong input');
    end

    % realign data
    % the whole aligned matrix
    nTc_fc = nTc - first_click;
    [DV_all_aligned, time_to_nTc] = realign_data_mom(DV_centered, time_DV, nTc_fc);
    delta_clicks_all_aligned = realign_data_mom(delta_clicks_centered, time_DC, nTc_fc);
    time_to_nTc = round(time_to_nTc,3);
    % Column for delta_clicks
    clicks_idx = find(time_to_nTc >= params.thre_clicks_bef & time_to_nTc <= params.thre_clicks_aft);
    session(i).delta_clicks_aligned = delta_clicks_all_aligned(:, clicks_idx);
    % Column for DV
    DV_idx = find(time_to_nTc >= params.thre_DV_bef & time_to_nTc <= params.thre_DV_aft);
    session(i).DV_aligned = DV_all_aligned(:, DV_idx);
   % session(i).DV_aligned = session(i).DV_aligned ./ nanstd(session(i).DV_aligned);
   % session(i).DV_aligned = session(i).DV_aligned - nanmean(session(i).DV_aligned);
   % session(i).delta_clicks_aligned = session(i).delta_clicks_aligned ./ nanstd(session(i).delta_clicks_aligned);
   % session(i).delta_clicks_aligned = session(i).delta_clicks_aligned - nanmean(session(i).delta_clicks_aligned);
end
%%
DV_aligned = [];
delta_clicks_aligned = [];
sess_idx=[];
for i = 1:length(path)
    DV_aligned = [DV_aligned; session(i).DV_aligned];
    delta_clicks_aligned = [delta_clicks_aligned; session(i).delta_clicks_aligned];
    n_trials(i) = size(session(i).DV_aligned,1);
    sess_idx = [sess_idx;ones(n_trials(i),1)*i];
end
%%

end