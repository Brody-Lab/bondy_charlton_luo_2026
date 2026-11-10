% plot_trilinear_summary  Summarize trilinear-fit drop time and drop
%                         duration distributions per region as median,
%                         IQR (25th-75th percentiles) and Tukey whiskers
%                         across bootstrap resamples (instead of
%                         histograms).
%
% Assumes the workspace contains:
%   trilinear_params : nRegions x N x 6 array of [m1, m2, m3, x1, x2, y0]
%                      (produced by trilinear_fits.m)
%   regions          : 1 x nRegions string array of region names
%
% Drop time      = (x1 + x2) / 2   (midpoint of segment 2)
% Drop sharpness = (x2 - x1)       (duration of segment 2)
%
% Produces ONE figure with two panels:
%   Left   - drop time       per region, median + IQR + whiskers
%   Right  - drop sharpness  per region, median + IQR + whiskers
%
% Saves figure as plot_trilinear_summary.{fig,pdf,png} alongside this script.

if ~exist('trilinear_params', 'var')
    error(['trilinear_params not found in workspace. ', ...
           'Run trilinear_fits.m first.']);
end
if ~exist('regions', 'var')
    error('regions not found in workspace.');
end

% ----- settings --------------------------------------------------------
drop_range = [-0.4, 0.3];
dur_range  = [0.01, 1];     % log scale -> needs a positive lower bound

% ----- pull data + summarise ------------------------------------------
nRegions = size(trilinear_params, 1);
x1       = squeeze(trilinear_params(:, :, 4));    % nRegions x N
x2       = squeeze(trilinear_params(:, :, 5));    % nRegions x N
drop_t   = (x1 + x2) / 2;                          % midpoint of segment 2
dur      =  x2 - x1;                               % duration of segment 2

% IQR (25th-75th percentiles) for the box; prctile ignores NaNs by default.
drop_med = median (drop_t, 2, 'omitnan');
drop_lo  = prctile(drop_t, 25, 2);
drop_hi  = prctile(drop_t, 75, 2);
dur_med  = median (dur,    2, 'omitnan');
dur_lo   = prctile(dur,    25, 2);
dur_hi   = prctile(dur,    75, 2);

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
f  = figure('Position', [348   304   324   321], ...
            'Name', 'Trilinear fit parameter summary');
tl = tiledlayout(1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% ---- drop time panel
nexttile; hold on;
for k = 1:nRegions
    draw_box_row(drop_t(k,:), yvals(k), drop_lo(k), drop_med(k), drop_hi(k), ...
                 regColors(k,:));
end
xline(0, 'k--', 'LineWidth', 0.8);
xlim(drop_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', regLabels, ...
         'TickLabelInterpreter', 'tex', ...
         'FontSize', 11);
xlabel('drop time  ( (x_1+x_2)/2, s )', 'FontSize', 9);
title('drop time', 'FontSize', 11);
box off;

% ---- drop sharpness panel
nexttile; hold on;
for k = 1:nRegions
    draw_box_row(dur(k,:), yvals(k), dur_lo(k), dur_med(k), dur_hi(k), ...
                 regColors(k,:));
end
xlim(dur_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse', ...
         'YTick', yvals, ...
         'YTickLabel', [], ...      % shared y-labels with the drop-time panel
         'FontSize', 11, ...
         'XScale', 'log');
xlabel('drop duration  ( x_2-x_1, s )', 'FontSize', 9);
title('drop sharpness', 'FontSize', 11);
box off;

title(tl, 'Trilinear fit parameters: median, IQR and Tukey whiskers across resamples', ...
      'FontSize', 11);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_trilinear_summary');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_trilinear_summary.{fig,pdf,png} to %s\n', thisDir);


% ----- helper ----------------------------------------------------------
function draw_box_row(x, y, q1, med, q3, col)
% Horizontal box-and-whisker glyph at row y:
%   IQR box (thick line) from q1 to q3, vertical line at the median,
%   and Tukey whiskers (thinner line, no end caps) extending to the
%   most extreme sample within [q1 - 1.5*IQR, q3 + 1.5*IQR].
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

    % median: vertical tick line
    halfH = 0.35;
    line([med, med], [y - halfH, y + halfH], ...
         'Color', col, 'LineWidth', 2);
end
