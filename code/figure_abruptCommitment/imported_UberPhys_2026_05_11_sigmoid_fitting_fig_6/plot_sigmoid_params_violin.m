% plot_sigmoid_params_violin  Half-violin summary of the cumulative-Gaussian
%                             fit parameters across bootstrap resamples,
%                             one violin per region.
%
% Inputs (same as plot_sigmoid_params_box.m):
%   sigmoid_params : nRegions x N x 4 array of [mu, sigma, scale, offset]
%   regions        : 1 x nRegions string array of region names
%
% Layout: ONE figure with two axes side by side (mu on the left, sigma
% on the right). Regions are stacked vertically with region 1 at the
% top. For each (region, parameter):
%   - A half-violin (KDE of the in-range samples) extends downward from
%     the region's baseline, filled in the region colour.
%   - A black vertical tick at the median (clipped to the display range).
%   - A short coloured edge tick at each clipping boundary whose length
%     encodes the fraction of bootstrap samples that fell outside the
%     display range on that side. This preserves the "stuck at the
%     bound" information that a naive KDE would smooth away.
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
halfH       = 0.4;             % max violin height (in y-axis units)
violinAlpha = 0.5;             % fill transparency

% ----- pull data (raw; clipping happens inside drawHalfViolin) ---------
nRegions = size(sigmoid_params, 1);
N        = size(sigmoid_params, 2);
mus_raw    = squeeze(sigmoid_params(:, :, 1));
sigmas_raw = squeeze(sigmoid_params(:, :, 2));

% Per-region colours from the standard uberphys palette.
regColors = zeros(nRegions, 3);
for k = 1:nRegions
    c              = uberphys.get_brain_region_colors(char(regions(k)));
    regColors(k,:) = c(1:3);
end

regLabels = arrayfun(@(reg) sprintf('\\color[rgb]{%.3f,%.3f,%.3f}%s', ...
    regColors(reg, 1), regColors(reg, 2), regColors(reg, 3), regions(reg)), ...
    (1:nRegions)', 'UniformOutput', false);

% ----- font sizes ------------------------------------------------------
FS_tick  = 12;
FS_xlbl  = 14;
FS_title = 14;
FS_sup   = 16;

% ----- figure ----------------------------------------------------------
f  = figure('Position', [80 40 600 651], ...
       'Name', 'Sigmoid fit parameter distributions (violin)');
tl = tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% --- mu column ---------------------------------------------------------
nexttile;
hold on;
for reg = 1:nRegions
    drawHalfViolin(reg, mus_raw(reg, :), regColors(reg, :), ...
                   violinAlpha, mu_range, halfH);
end
xlim(mu_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse');            % region 1 at top
yticks(1:nRegions);
set(gca, 'TickLabelInterpreter', 'tex', 'YTickLabel', regLabels);
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
    drawHalfViolin(reg, sigmas_raw(reg, :), regColors(reg, :), ...
                   violinAlpha, sigma_range, halfH);
end
xlim(sigma_range);
ylim([0.5, nRegions + 0.5]);
set(gca, 'YDir', 'reverse');
yticks(1:nRegions);
set(gca, 'YTickLabel', []);
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
stem    = fullfile(thisDir, 'plot_sigmoid_params_violin');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_sigmoid_params_violin.{fig,pdf,png} to %s\n', thisDir);

% ----- local helpers ---------------------------------------------------
function drawHalfViolin(y, data, color, alpha, xrange, halfH)
% DRAWHALFVIOLIN  Half-violin (KDE of the in-range data) at vertical
% position y. With YDir='reverse' the bump grows downward visually
% (toward larger y), so each region's density sits below its baseline
% and above the next region's baseline.
%
% Samples falling at or outside xrange are NOT smoothed into the KDE;
% instead the fraction of clipped samples on each side is encoded as a
% short coloured tick at the corresponding boundary, with length
% halfH * (clipped_fraction). The in-range KDE is scaled so its peak is
% at halfH * (in_range_fraction), so the violin peak and the edge ticks
% are commensurate.
    data = data(:);
    data = data(~isnan(data));
    if isempty(data), return; end
    Ntot = numel(data);

    at_lo = data <= xrange(1);
    at_hi = data >= xrange(2);
    in    = data(~at_lo & ~at_hi);

    n_lo = sum(at_lo);
    n_hi = sum(at_hi);
    n_in = numel(in);

    % KDE on in-range samples.
    if n_in >= 2
        xi = linspace(xrange(1), xrange(2), 200);
        fi = ksdensity(in, xi);
        mx = max(fi);
        if mx > 0
            scaled = fi / mx * halfH * (n_in / Ntot);
            patch_x = [xi(1), xi, xi(end)];
            patch_y = [y, y + scaled, y];
            patch(patch_x, patch_y, color, ...
                'EdgeColor', color, 'FaceAlpha', alpha, 'LineWidth', 1.0);
        end
    end

    % Median tick (black, drawn after the patch so it sits on top).
    med = median(data);
    med = max(min(med, xrange(2)), xrange(1));    % pin to display range
    line([med med], [y, y + halfH], 'Color', 'k', 'LineWidth', 1.5);

    % Edge ticks for clipped fractions.
    if n_lo > 0
        line([xrange(1) xrange(1)], ...
             [y, y + halfH * (n_lo / Ntot)], ...
             'Color', color, 'LineWidth', 4);
    end
    if n_hi > 0
        line([xrange(2) xrange(2)], ...
             [y, y + halfH * (n_hi / Ntot)], ...
             'Color', color, 'LineWidth', 4);
    end
end
