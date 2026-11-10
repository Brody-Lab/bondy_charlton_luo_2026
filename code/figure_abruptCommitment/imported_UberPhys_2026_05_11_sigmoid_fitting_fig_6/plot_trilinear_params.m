% plot_trilinear_params  Plot the distribution of trilinear-fit drop time
%                        (midpoint of segment 2) and drop sharpness
%                        (duration of segment 2) across bootstrap
%                        resamples, per region.
%
% Assumes the workspace contains:
%   trilinear_params : nRegions x N x 6 array of [m1, m2, m3, x1, x2, y0]
%                      (produced by trilinear_fits.m)
%   regions          : 1 x nRegions string array of region names
%
% Drop time      = (x1 + x2) / 2   (midpoint of segment 2)
% Drop sharpness = (x2 - x1)       (duration of segment 2)
%
% Produces ONE figure with an nRegions x 2 grid of histograms.
% Each column uses the same bin edges across regions for direct
% visual comparison.

if ~exist('trilinear_params', 'var')
    error(['trilinear_params not found in workspace. ', ...
           'Run trilinear_fits.m first.']);
end
if ~exist('regions', 'var')
    error('regions not found in workspace.');
end

% ----- settings --------------------------------------------------------
drop_range  = [-0.4, 0.3];   % drop time clip range
drop_min    = drop_range(1);
drop_max    = drop_range(2);
dur_max     = 1;             % drop duration cap (segment 2 width)
dur_range   = [0, dur_max];
nBins       = 25;
drop_edges  = linspace(drop_range(1), drop_range(2), nBins + 1);
dur_edges   = linspace(dur_range(1),  dur_range(2),  nBins + 1);

% ----- pull data -------------------------------------------------------
nRegions = size(trilinear_params, 1);
x1       = squeeze(trilinear_params(:, :, 4));    % nRegions x N
x2       = squeeze(trilinear_params(:, :, 5));    % nRegions x N
drop_t   = (x1 + x2) / 2;                          % midpoint of segment 2
dur      = x2 - x1;                                % duration of segment 2

% Clip to display ranges while preserving NaNs.
drop_t   = max(min(drop_t, drop_max, 'includenan'), drop_min, 'includenan');
dur      = min(dur, dur_max, 'includenan');

% Per-region colors from the standard uberphys palette.
regColors = zeros(nRegions, 3);
for k = 1:nRegions
    c              = uberphys.get_brain_region_colors(char(regions(k)));
    regColors(k,:) = c(1:3);
end

% ----- figure ----------------------------------------------------------
f  = figure('Position', [80 40 402 651], ...
       'Name', 'Trilinear fit parameter distributions');
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

    % ----- column 1: drop time (midpoint of segment 2) -------------
    nexttile(tlL, tile_start, [ROWS_HIST 1]);
    histogram(drop_t(reg, :), drop_edges, ...
        'FaceColor', barColor, 'EdgeColor', 'none', 'FaceAlpha', 1, ...
        'Normalization', 'probability');
    xlim(drop_range);
    xline(0, 'k--', 'LineWidth', 0.8);
    ylabel(char(regions(reg)), ...
           'FontSize', FS_ylbl, 'Color', barColor);
    if reg == nRegions
        % Pin ticks at the clipping edges and relabel them with <= / >=.
        d_ticks = [drop_min, 0, drop_max];
        d_lbls  = {sprintf('\\leq%g', drop_min), '0', sprintf('\\geq%g', drop_max)};
        set(gca, 'XTick', d_ticks, 'XTickLabel', d_lbls);
        xlabel('drop time  ( (x_1+x_2)/2, s )', 'FontSize', FS_xlbl);
    else
        set(gca, 'XTick', [], 'XTickLabel', []);
    end
    if reg == 1, title('drop time', 'FontSize', FS_title); end
    set(gca, 'FontSize', FS_tick);
    box off;
    ax_h       = gca;
    y_top      = niceCeil(ax_h.YLim(2));
    ax_h.YLim  = [0, y_top];
    ax_h.YTick = [0, y_top];

    % ----- column 2: drop duration (segment 2 width) -------------
    nexttile(tlR, tile_start, [ROWS_HIST 1]);
    histogram(dur(reg, :), dur_edges, ...
        'FaceColor', barColor, 'EdgeColor', 'none', 'FaceAlpha', 1, ...
        'Normalization', 'probability');
    xlim(dur_range);
    if reg == nRegions
        u_ticks = [0, dur_max/2, dur_max];
        u_lbls  = {'0', sprintf('%g', dur_max/2), sprintf('\\geq%g', dur_max)};
        set(gca, 'XTick', u_ticks, 'XTickLabel', u_lbls);
        xlabel('drop duration  ( x_2-x_1, s )', 'FontSize', FS_xlbl);
    else
        set(gca, 'XTick', [], 'XTickLabel', []);
    end
    if reg == 1, title('drop sharpness', 'FontSize', FS_title); end
    set(gca, 'FontSize', FS_tick);
    box off;
    ax_h       = gca;
    y_top      = niceCeil(ax_h.YLim(2));
    ax_h.YLim  = [0, y_top];
    ax_h.YTick = [0, y_top];
end

title(tl, 'Trilinear fit parameters across bootstrap resamples', ...
      'FontSize', FS_sup);

% ----- save ------------------------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
stem    = fullfile(thisDir, 'plot_trilinear_params');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.pdf'], 'ContentType', 'vector');
exportgraphics(f, [stem '.png'], 'Resolution',  300);
fprintf('Saved plot_trilinear_params.{fig,pdf,png} to %s\n', thisDir);

% ----- local helpers ---------------------------------------------------
function v = niceCeil(x)
% NICECEIL  Round x up to the next 1, 2, or 5 times a power of 10.
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
