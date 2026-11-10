% plot_sigmoid_summary  Summarize fitted cumulative-Gaussian mu and sigma
%                       distributions per region as median, IQR
%                       (25th-75th percentiles) and Tukey whiskers
%                       across bootstrap resamples (instead of histograms).
%
% Assumes the workspace contains:
%   sigmoid_params : nRegions x N x 4 array of [mu, sigma, scale, offset]
%   regions        : 1 x nRegions string array of region names
%
% Produces ONE figure with two panels:
%   Left   - mu    (drop time)       per region, median + IQR + whiskers
%   Right  - sigma (drop sharpness)  per region, median + IQR + whiskers
%           (sigma values >= 0.1 are clipped to 0.1 before summarising,
%            matching plot_sigmoid_params.m.)
%
% Saves figure as plot_sigmoid_summary.{fig,pdf,png} alongside this script.

if ~exist('sigmoid_params', 'var')
    error(['sigmoid_params not found in workspace. ', ...
           'Run cum_gauss_fits.m (or fit_col_mean_sigmoid.m) first.']);
end
if ~exist('regions', 'var')
    error('regions not found in workspace.');
end

% ----- settings --------------------------------------------------------
mu_range    = [-0.4, 0.3];
sigma_range = [ 0  , 0.1];

% ----- pull data + summarise ------------------------------------------
nRegions = size(sigmoid_params, 1);
mus      = squeeze(sigmoid_params(:, :, 1));     % nRegions x N
sigmas   = squeeze(sigmoid_params(:, :, 2));     % nRegions x N

% IQR (25th-75th percentiles) for the box; prctile ignores NaNs by default.
mu_med   = median (mus,    2, 'omitnan');
mu_lo    = prctile(mus, 25, 2);
mu_hi    = prctile(mus, 75, 2);
sig_med  = median (sigmas, 2, 'omitnan');
sig_lo   = prctile(sigmas, 25, 2);
sig_hi   = prctile(sigmas, 75, 2);

yvals     = 1:nRegions;

% Per-region colors from the standard uberphys palette, and tex-colored
% y-tick labels so each region label matches its data color.
regColors = zeros(nRegions, 3);
regLabels = cell(1, nRegions);
for k = 1:nRegions
    c              = uberphys.get_brain_region_colors(char(regions(k)));
    regColors(k,:) = c(1:3);
    regLabels{k}   = sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s', ...
                             c(1), c(2), c(3), regions(k));
end

% ----- figure ----------------------------------------------------------
f  = figure('Position', [231   225   325   321], ...
            'Name', 'Sigmoid fit parameter summary');
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---- mu panel
nexttile; hold on;
for k = 1:nRegions
    draw_box_row(mus(k,:), yvals(k), mu_lo(k), mu_med(k), mu_hi(k), ...
                 regColors(k,:));
end
xline(0, 'k--', 'LineWidth', 0.8);
xlim(mu_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', regLabels, ...
         'TickLabelInterpreter', 'tex', ...
         'FontSize', 11);
xlabel('\mu  (drop time, s)', 'FontSize', 9);
title('\mu', 'FontSize', 11);
box off;

% ---- sigma panel
nexttile; hold on;
for k = 1:nRegions
    draw_box_row(sigmas(k,:), yvals(k), sig_lo(k), sig_med(k), sig_hi(k), ...
                 regColors(k,:));
end
xlim(sigma_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', [], ...      % shared y-labels with the mu panel
         'FontSize', 11);
xlabel('\sigma  (drop sharpness, s)', 'FontSize', 9);
title('\sigma', 'FontSize', 11);
box off;

title(tl, 'Cumulative-Gaussian fit parameters: median, IQR and Tukey whiskers across resamples', ...
      'FontSize', 11);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_sigmoid_summary');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_sigmoid_summary.{fig,pdf,png} to %s\n', thisDir);


% ----- helper ----------------------------------------------------------
function draw_box_row(x, y, q1, med, q3, col)
% Horizontal box-and-whisker glyph at row y:
%   IQR box (thick line) from q1 to q3, filled median dot, and Tukey
%   whiskers (thinner line, no end caps) extending to the most extreme
%   sample within [q1 - 1.5*IQR, q3 + 1.5*IQR].
    x   = x(:);
    x   = x(~isnan(x));
    iqr = q3 - q1;
    lof = q1 - 1.5 * iqr;
    hif = q3 + 1.5 * iqr;
    inWhisker = x(x >= lof & x <= hif);
    if isempty(inWhisker)
        wlo = q1; whi = q3;
    else
        wlo = min(inWhisker);
        whi = max(inWhisker);
    end

    % whiskers: thin line, no caps
    line([wlo, q1], [y, y], 'Color', col, 'LineWidth', 0.8);
    line([q3, whi], [y, y], 'Color', col, 'LineWidth', 0.8);

    % IQR box: thick line
    line([q1, q3], [y, y], 'Color', col, 'LineWidth', 2.5);

    % median marker
    plot(med, y, 'o', ...
         'MarkerFaceColor', col, 'MarkerEdgeColor', col, ...
         'MarkerSize', 5);
end
