% plot_sigmoid_params  Plot the distribution of fitted cumulative-Gaussian
%                      mu (drop time) and sigma (drop sharpness) values
%                      across bootstrap resamples, per region.
%
% Assumes the workspace contains:
%   sigmoid_params : nRegions x N x 4 array of [mu, sigma, scale, offset]
%                    (produced by cum_gauss_fits.m or fit_col_mean_sigmoid.m)
%   regions        : 1 x nRegions string array of region names
%
% Produces ONE figure with an nRegions x 2 grid of histograms:
%   Column 1 - mu (drop time),       common x-range [-0.4, 0.3] s
%   Column 2 - sigma (drop sharpness), common x-range [ 0  , 0.35] s
% Each column uses the same bin edges across regions for direct
% visual comparison.
%
% Adrian Bondy, 2026-05-11

if ~exist('sigmoid_params', 'var')
    error(['sigmoid_params not found in workspace. ', ...
           'Run cum_gauss_fits.m (or fit_col_mean_sigmoid.m) first.']);
end
if ~exist('regions', 'var')
    error('regions not found in workspace.');
end

% ----- settings --------------------------------------------------------
mu_range    = [-0.4, 0.3];     % mu values outside this are clipped to the edges
mu_min      = mu_range(1);
mu_max      = mu_range(2);
sigma_max   = 0.1;            % sigma values >= this are clipped to this
sigma_range = [ 0, sigma_max];
nBins       = 25;             % same bin count in both columns
mu_edges    = linspace(mu_range(1),    mu_range(2),    nBins + 1);
sigma_edges = linspace(sigma_range(1), sigma_range(2), nBins + 1);

% ----- pull data -------------------------------------------------------
nRegions = size(sigmoid_params, 1);
mus      = squeeze(sigmoid_params(:, :, 1));   % nRegions x N
% Clip mu / sigma to display ranges, but preserve NaNs (anomalous-resample
% flags set by cum_gauss_fits). min/max ignore NaNs by default, which would
% otherwise turn each NaN into the clip bound.
mus      = max(min(mus, mu_max, 'includenan'), mu_min, 'includenan');
sigmas   = squeeze(sigmoid_params(:, :, 2));   % nRegions x N
sigmas   = min(sigmas, sigma_max, 'includenan');

% Per-region colors from the standard uberphys palette.
regColors = zeros(nRegions, 3);
for k = 1:nRegions
    c              = uberphys.get_brain_region_colors(char(regions(k)));
    regColors(k,:) = c(1:3);
end

% ----- figure ----------------------------------------------------------
f  = figure('Position', [80 40 402 651], ...
       'Name', 'Sigmoid fit parameter distributions');
% Nested layout so vertical (row) and horizontal (column) spacing can be
% tuned independently: outer 1 x 2 controls the gap between columns,
% inner layouts control the gap between rows. To get a small but non-zero
% vertical gap (between the discrete values of TileSpacing), each
% histogram spans ROWS_HIST rows and a single blank row sits between
% successive histograms (ROWS_GAP : ROWS_HIST controls the gap ratio).
ROWS_HIST = 4;
ROWS_GAP  = 1;
nTiles    = nRegions * ROWS_HIST + (nRegions - 1) * ROWS_GAP;

tl    = tiledlayout(f, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
tlL   = tiledlayout(tl, nTiles, 1, 'TileSpacing', 'none', 'Padding', 'none');
tlR   = tiledlayout(tl, nTiles, 1, 'TileSpacing', 'none', 'Padding', 'none');
tlL.Layout.Tile = 1;
tlR.Layout.Tile = 2;

% Font sizes (centralised so they're easy to tune).
FS_tick  = 12;
FS_ylbl  = 12;
FS_xlbl  = 14;
FS_title = 14;
FS_sup   = 16;

for reg = 1:nRegions
    barColor = regColors(reg, :);

    % Top tile of this region's block (rows for histogram followed by gap).
    tile_start = (reg - 1) * (ROWS_HIST + ROWS_GAP) + 1;

    % ----- column 1: mu --------------------------------------------
    nexttile(tlL, tile_start, [ROWS_HIST 1]);
    histogram(mus(reg, :), mu_edges, ...
        'FaceColor', barColor, 'EdgeColor', 'none', 'FaceAlpha', 1, ...
        'Normalization', 'probability');
    xlim(mu_range);
    xline(0, 'k--', 'LineWidth', 0.8);
    ylabel(char(regions(reg)), ...
           'FontSize', FS_ylbl, 'Color', barColor);
    if reg == nRegions
        % Pin ticks at the clipping edges and relabel them with <= / >=.
        mu_ticks = [mu_min, 0, mu_max];
        mu_lbls  = {sprintf('\\leq%g', mu_min), '0', sprintf('\\geq%g', mu_max)};
        set(gca, 'XTick', mu_ticks, 'XTickLabel', mu_lbls);
        xlabel('\mu  (drop time, s)', 'FontSize', FS_xlbl);
    else
        % Hide both the tick marks and their labels.
        set(gca, 'XTick', [], 'XTickLabel', []);
    end
    if reg == 1, title('\mu  (drop time)', 'FontSize', FS_title); end
    set(gca, 'FontSize', FS_tick);
    box off;
    % Keep just two y-ticks: 0 and the top of the auto-range, rounded up
    % to a "nice" number (1, 2, or 5 times a power of 10). Lock the ylim
    % so the top tick sits exactly at the top of the axes.
    ax_h       = gca;
    y_top      = niceCeil(ax_h.YLim(2));
    ax_h.YLim  = [0, y_top];
    ax_h.YTick = [0, y_top];

    % ----- column 2: sigma (clipped at sigma_max) ------------------
    nexttile(tlR, tile_start, [ROWS_HIST 1]);
    histogram(sigmas(reg, :), sigma_edges, ...
        'FaceColor', barColor, 'EdgeColor', 'none', 'FaceAlpha', 1, ...
        'Normalization', 'probability');
    xlim(sigma_range);
    if reg == nRegions
        % Pin ticks and relabel top tick as ">=sigma_max" to flag
        % clipped values (and avoid MATLAB cycling labels when its
        % auto-tick count exceeds the number of labels we supply).
        sig_ticks = [0, sigma_max/2, sigma_max];
        sig_lbls  = {'0', sprintf('%g', sigma_max/2), sprintf('\\geq%g', sigma_max)};
        set(gca, 'XTick', sig_ticks, 'XTickLabel', sig_lbls);
        xlabel('\sigma  (drop sharpness, s)', 'FontSize', FS_xlbl);
    else
        % Hide both the tick marks and their labels.
        set(gca, 'XTick', [], 'XTickLabel', []);
    end
    if reg == 1, title('\sigma  (drop sharpness)', 'FontSize', FS_title); end
    set(gca, 'FontSize', FS_tick);
    box off;
    % Keep just two y-ticks: 0 and the top of the auto-range, rounded up
    % to a "nice" number (1, 2, or 5 times a power of 10). Lock the ylim
    % so the top tick sits exactly at the top of the axes.
    ax_h       = gca;
    y_top      = niceCeil(ax_h.YLim(2));
    ax_h.YLim  = [0, y_top];
    ax_h.YTick = [0, y_top];
end

title(tl, 'Cumulative-Gaussian fit parameters across bootstrap resamples', ...
      'FontSize', FS_sup);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_sigmoid_params');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_sigmoid_params.{fig,pdf,png} to %s\n', thisDir);

% ----- local helpers ---------------------------------------------------
function v = niceCeil(x)
% NICECEIL  Round x up to the next 1, 2, or 5 times a power of 10.
%           Returns x unchanged for x <= 0 (caller decides what to do).
    if x <= 0, v = x; return; end
    p = 10^floor(log10(x));
    m = x / p;
    if     m <= 1, m = 1;
    elseif m <= 2, m = 2;
    elseif m <= 5, m = 5;
    else,          m = 10;
    end
    v = m * p;
end
