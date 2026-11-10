% plot_sigmoid_params_box  Box-plot summary of the cumulative-Gaussian fit
%                          parameters (mu = drop time, sigma = drop sharpness)
%                          across bootstrap resamples, one box per region.
%
% Same inputs as plot_sigmoid_params.m:
%   sigmoid_params : nRegions x N x 4 array of [mu, sigma, scale, offset]
%   regions        : 1 x nRegions string array of region names
%
% Layout: ONE figure with two horizontal-orientation box-chart axes side
% by side (mu on the left, sigma on the right). Regions are stacked
% vertically with region 1 at the top. Each box is filled with its
% region's standard colour, and the y-tick labels are colour-coded to
% match.
%
% Adrian Bondy, 2026-05-13

if ~exist('sigmoid_params', 'var')
    error(['sigmoid_params not found in workspace. ', ...
           'Run cum_gauss_fits.m first.']);
end
if ~exist('regions', 'var')
    error('regions not found in workspace.');
end

% ----- settings --------------------------------------------------------
mu_range    = [-0.4, 0.3];
mu_min      = mu_range(1);
mu_max      = mu_range(2);
sigma_max   = Inf;
sigma_range = [0, sigma_max];

% ----- pull data -------------------------------------------------------
nRegions = size(sigmoid_params, 1);
N        = size(sigmoid_params, 2);
mus      = squeeze(sigmoid_params(:, :, 1));
mus      = max(min(mus, mu_max), mu_min);    % clip to display range
sigmas   = squeeze(sigmoid_params(:, :, 2));
sigmas   = min(sigmas, sigma_max);

% Per-region colours from the standard uberphys palette.
regColors = zeros(nRegions, 3);
for k = 1:nRegions
    c              = uberphys.get_brain_region_colors(char(regions(k)));
    regColors(k,:) = c(1:3);
end

% Colour-coded region labels (used by the YTickLabel call below). Use tex
% interpreter to embed an \color directive per label.
regLabels = arrayfun(@(reg) sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s', ...
    regColors(reg, 1), regColors(reg, 2), regColors(reg, 3), regions(reg)), ...
    (1:nRegions)', 'UniformOutput', false);

% ----- font sizes (centralised) ----------------------------------------
FS_tick  = 12;
FS_xlbl  = 14;
FS_title = 14;
FS_sup   = 16;

% ----- figure ----------------------------------------------------------
f  = figure('Position', [80 40 600 651], ...
       'Name', 'Sigmoid fit parameter distributions (box)');
tl = tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- mu column ---------------------------------------------------------
nexttile;
hold on;
for reg = 1:nRegions
    drawHorizBox(reg, mus(reg, :), regColors(reg, :), 0.5);
end
xlim(mu_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse');            % region 1 at top
yticks(1:nRegions);
set(gca, 'TickLabelInterpreter', 'tex', 'YTickLabel', regLabels);
% Pin x-ticks at the clipping edges with <= / >= labels.
mu_ticks = [mu_min, 0, mu_max];
mu_lbls  = {sprintf('\\leq%g', mu_min), '0', sprintf('\\geq%g', mu_max)};
set(gca, 'XTick', mu_ticks, 'XTickLabel', mu_lbls);
xline(0, 'k--', 'LineWidth', 0.8);
xlabel('\mu  (drop time, s)', 'FontSize', FS_xlbl);
title ('\mu  (drop time)',    'FontSize', FS_title);
set(gca, 'FontSize', FS_tick);
box off; grid on;

% --- sigma column ------------------------------------------------------
nexttile;
hold on;
for reg = 1:nRegions
    drawHorizBox(reg, sigmas(reg, :), regColors(reg, :), 0.5);
end
xlim(sigma_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse');
yticks(1:nRegions);
% No region labels in the right axes -- they're already on the left axes.
set(gca, 'YTickLabel', []);
% Pin x-ticks: 0, sigma_max/2, sigma_max with >= on the clipped top.
sig_ticks = [0, sigma_max/2, sigma_max];
sig_lbls  = {'0', sprintf('%g', sigma_max/2), sprintf('\\geq%g', sigma_max)};
set(gca, 'TickLabelInterpreter', 'tex', ...
         'XTick', sig_ticks, 'XTickLabel', sig_lbls);
xlabel('\sigma  (drop sharpness, s)', 'FontSize', FS_xlbl);
title ('\sigma  (drop sharpness)',    'FontSize', FS_title);
set(gca, 'FontSize', FS_tick);
box off; grid on;

title(tl, 'Cumulative-Gaussian fit parameters across bootstrap resamples', ...
      'FontSize', FS_sup);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_sigmoid_params_box');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_sigmoid_params_box.{fig,pdf,png} to %s\n', thisDir);

% ----- local helpers ---------------------------------------------------
function drawHorizBox(y, data, color, alpha)
% DRAWHORIZBOX  Manual horizontal box plot at vertical position y:
%   - patch from Q1 to Q3 in the supplied color with FaceAlpha = alpha
%   - black median line, drawn last so the alpha-blended box doesn't dim it
%   - whiskers extending to the most extreme datum within 1.5 * IQR of
%     the box, drawn as plain lines (no caps)
%   - no outlier markers
    data = data(:);
    data = data(~isnan(data));
    if isempty(data), return; end

    q   = quantile(data, [0.25 0.5 0.75]);
    iqr = q(3) - q(1);
    lo  = max(min(data),  q(1) - 1.5 * iqr);
    hi  = min(max(data),  q(3) + 1.5 * iqr);

    halfH = 0.35;     % half-height of the box in y-axis units
    % Box (filled, semi-transparent).
    patch([q(1) q(3) q(3) q(1)], ...
          [y-halfH y-halfH y+halfH y+halfH], ...
          color, 'EdgeColor', color, 'FaceAlpha', alpha, 'LineWidth', 1.2);
    % Whiskers (no caps).
    line([lo q(1)], [y y], 'Color', color, 'LineWidth', 1.2);
    line([q(3) hi], [y y], 'Color', color, 'LineWidth', 1.2);
    % Median line (black, drawn last so it sits on top of the box).
    line([q(2) q(2)], [y-halfH y+halfH], 'Color', 'k', 'LineWidth', 1.5);
end
