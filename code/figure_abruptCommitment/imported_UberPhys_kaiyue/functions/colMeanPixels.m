function [pixel_idx, n_pixels, noiseFloor] = colMeanPixels(corrMat, diagLow, timeX, timeY, offsets)
% all inputs are before nTc
% determine which and how many pixels to include in the column mean

% input:
    % corrMat: the correlation matrix between clicks and DV/SV before nTc, (ntimes_DV, ntimes_click_before_nTc)
    % diagLow: diag_mean - 95% confidence interval, (n_diags, 1)
    % timeX: time of clicks before nTc, (1, ntimes_click_before_nTc)
    % timeY: time of DV/SV, (1, ntimes_DV)
    % offsets: diagonal index in unit of time difference, time_X - time_Y, (1, n_diags)
% output:
    % pixel_idx: the pixels included to compute column mean in unit of time difference, subset of offsets, defined as the longest consecutive diagonals above noise floor
    % n_pixels: how many pixels in pixel_idx
    % noiseFloor: average of the acausal correlation matrix before nTc pixels, scalar

% shape of corrMat
nCols = length(timeX);
nRows = length(timeY);

% reshape arrays
timeY = round(reshape(timeY, nRows, 1), 2);
timeX = round(reshape(timeX, 1, nCols), 2);
diagLow = reshape(diagLow, length(diagLow), 1);
offsets = round(reshape(offsets, length(offsets), 1), 2);

% noise floor is the aveage of all the upper triangle pixels
is_upper_triag = timeY < timeX;
noiseFloor = mean(mean(corrMat(is_upper_triag)));

% index of causal diagonal above noise in unit of 1
idx_above = find(diagLow > noiseFloor & offsets <= 0);
if isempty(idx_above)
    disp('No diagonal is significantly above noise.');
end

% first_idx = idx_above(find(diff(idx_above)~=1, 1, 'last') + 1);
% if isempty(first_idx)
%     first_idx = idx_above(1);
% end
% % index of diagonal chosen to compute column mean in unit of 1
% idx_chosen = first_idx:idx_above(end);

% id idx_above: (1,n), then d: (1, n-1) insert boards in between
d = diff(idx_above);
% is_break: (1, n+1) insert boards in between and at ends
is_break = [true; d ~= 1; true];
% index of the boards that separate segments, including the ends (1, n_seg+1)
break_idx = find(is_break);
% length of each segment (1, n_seg)
seq_lengths = diff(break_idx);
% choose the longest one
max_len = max(seq_lengths);
% if there are more longest segments, pick the last one
all_max_idx = find(seq_lengths == max_len);
max_id = all_max_idx(end);
% idx_above -> idx_chosen
start_pos = break_idx(max_id);
idx_chosen = idx_above(start_pos : start_pos + max_len - 1);

% diagonal chosen in unit of time diff
pixel_idx = offsets(idx_chosen);
n_pixels = length(pixel_idx);

end