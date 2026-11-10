% plot_sigmoid_summary  Summarize fitted cumulative-Gaussian mu and sigma
%                       distributions per region as median +/- MAD across
%                       bootstrap resamples (instead of histograms).
%
% Assumes the workspace contains:
%   sigmoid_params : nRegions x N x 4 array of [mu, sigma, scale, offset]
%   regions        : 1 x nRegions string array of region names
%
% Produces ONE figure with two panels:
%   Left   - mu    (drop time)       per region, median +/- MAD, x in [-0.4, 0.3]
%   Right  - sigma (drop sharpness)  per region, median +/- MAD, x in [ 0  , 0.1 ]
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
sigma_range = [ 0  , 0.3];

% ----- pull data + summarise ------------------------------------------
nRegions = size(sigmoid_params, 1);
mus      = squeeze(sigmoid_params(:, :, 1));     % nRegions x N
sigmas   = squeeze(sigmoid_params(:, :, 2));     % nRegions x N

% Anomalous resamples are NaN-masked by cum_gauss_fits; omit them.
% MAD = median absolute deviation from the median.
mu_med   = median(mus,    2, 'omitnan');
mu_mad   = median(abs(mus    - mu_med ), 2, 'omitnan');
sig_med  = median(sigmas, 2, 'omitnan');
sig_mad  = median(abs(sigmas - sig_med), 2, 'omitnan');

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
f  = figure('Position', [80 60 800 600], ...
            'Name', 'Sigmoid fit parameter summary');
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---- mu panel
nexttile; hold on;
for k = 1:nRegions
    line([mu_med(k) - mu_mad(k), mu_med(k) + mu_mad(k)], ...
         [yvals(k),               yvals(k)], ...
         'Color', regColors(k,:), 'LineWidth', 1.2);
    plot(mu_med(k), yvals(k), 'o', ...
         'MarkerFaceColor', regColors(k,:), ...
         'MarkerEdgeColor', regColors(k,:), ...
         'MarkerSize',      5);
end
xline(0, 'k--', 'LineWidth', 0.8);
xlim(mu_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', regLabels, ...
         'TickLabelInterpreter', 'tex', ...
         'FontSize', 8);
xlabel('\mu  (drop time, s)', 'FontSize', 9);
title('\mu', 'FontSize', 11);
box off;

% ---- sigma panel
nexttile; hold on;
for k = 1:nRegions
    line([sig_med(k) - sig_mad(k), sig_med(k) + sig_mad(k)], ...
         [yvals(k),                 yvals(k)], ...
         'Color', regColors(k,:), 'LineWidth', 1.2);
    plot(sig_med(k), yvals(k), 'o', ...
         'MarkerFaceColor', regColors(k,:), ...
         'MarkerEdgeColor', regColors(k,:), ...
         'MarkerSize',      5);
end
xlim(sigma_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', [], ...      % shared y-labels with the mu panel
         'FontSize', 8);
xlabel('\sigma  (drop sharpness, s)', 'FontSize', 9);
title('\sigma', 'FontSize', 11);
box off;

title(tl, 'Cumulative-Gaussian fit parameters: median \pm MAD across resamples', ...
      'FontSize', 11);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_sigmoid_summary_simple');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_sigmoid_summary_simple.{fig,pdf,png} to %s\n', thisDir);