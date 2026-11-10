function [diagMeans, offsets, err_lower, err_upper] = diagonalMean(mat_X, mat_Y, timeX, timeY)
% compute the diagonal mean of the correlation matrix before nTc

% input:
    % mat_X: e.g., delta_clicks (ntrials, ntimes_clicks) or delta_clicks_diag (ntrials, ntimes_clicks_before_nTc)
    % mat_Y: e.g., DV_aligned (ntrials, ntimes_DV)
    % timeX: e.g., time_clicks (1, ntimes_clicks) or time_clicks_diag (1, ntimes_clicks_before_nTc)
    % timeY: e.g., time_DV (1, ntimes)

% output:
    % diagMeans: the diagonal mean of the correlation matrix (nDiag, 1)
    % offsets: the diagonal index in unit of time, which is time on x minus time on y (nDiag,1)
    % err_lower: diag_mean - 0.95 confidence interval (nDiag, 1)
    % err_upper: diag_mean + 0.95 confidence interval (nDiag, 1)
    
    dt = 0.05;
    nCols = length(timeX);
    nRows = length(timeY);
    
    minOffset = min(timeX) - max(timeY);
    maxOffset = max(timeX) - min(timeY);
    
    offsets = minOffset:dt:maxOffset; % in seconds
    offsets = round(offsets,3);
    timeX = round(timeX,3);
    timeY = round(timeY,3);

    nDiags = length(offsets);
    diagMeans = zeros(nDiags,1);
    err_lower = zeros(nDiags,1);
    err_upper = zeros(nDiags,1);
    
    for i = 1:nDiags
        k = offsets(i); % timeX - timeY == k

        indY = find(timeY >= min(timeX) - k & timeY <= max(timeX) - k); % index for Y on this diagonal
        if isempty(indY)
            disp(['No pixel on diagonal time = ', num2str(k)]);
        end

        indX = zeros(length(indY),1);
        for j = 1:length(indY)
            indX(j) = find(timeX == round(timeY(indY(j)) + k, 3));
        end
        
        [diagMeans(i), ~, err_lower(i), err_upper(i)] = mean_corr(mat_X, mat_Y, indX, indY);
    end
end