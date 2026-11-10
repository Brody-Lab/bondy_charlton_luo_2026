% trilinear_fits  Fit a 6-parameter trilinear function to col_mean for
%                 every bootstrap resample of every region in `output`,
%                 plot the mean fit +/- 1 std for each region in a 5x2
%                 grid, and save the figure as .fig / .pdf / .png.
%
% Assumes the variables `output` and `regions` are in the workspace.
%   output  : 1 x nRegions struct; each entry has fields
%               .click_times  (1 x M time axis)
%               .col_mean     (N x M; N bootstrap resamples)
%   regions : 1 x nRegions string array of region names (used in titles)
%
% Strategy:
%   For each region, fit a Trilinear to the across-resample mean to get
%   reliable parameters.  Use those as the warm start ('m10'/'m20'/'m30',
%   'x10'/'x20', 'y00') for the fits to each bootstrap resample.  Inner
%   loop is parallelised with parfor.
%
% Requires Trilinear.m on the MATLAB path (same directory as this script).
%
% Adrian Bondy, 2026-05-11

% ----- preconditions ---------------------------------------------------
if ~exist('output',  'var'), error('Variable ''output'' not found.');  end
if ~exist('regions', 'var'), error('Variable ''regions'' not found.'); end

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
addpath(thisDir);

pool = gcp('nocreate');
if isempty(pool)
    pool = parpool;
end
pctRunOnAll(['addpath(''' thisDir ''')']);

% ----- setup -----------------------------------------------------------
nRegions = numel(output);
t        = output(1).click_times;
N        = size(output(1).col_mean, 1);
t_fine   = linspace(min(t), max(t), 400);

% ----- fit every (region, resample) -----------------------------------
tl_all_fits      = nan(nRegions, N, numel(t_fine));
trilinear_params = nan(nRegions, N, 6);       % [m1 m2 m3 x1 x2 y0]
tl_means = repmat(Trilinear, 1, nRegions);    % one trilinear fit per region,
                                              % fit to the across-resample mean
for reg = 1:nRegions
    data    = output(reg).col_mean;
    tl_mean = Trilinear.fit(t, mean(data, 1));
    tl_means(reg) = tl_mean;
    mp      = tl_mean.asVector();             % [m1 m2 m3 x1 x2 y0]

    fits_r   = nan(N, numel(t_fine));
    params_r = nan(N, 6);
    parfor i = 1:N
        tl = Trilinear.fit(t, data(i, :), ...
            'm10', mp(1), 'm20', mp(2), 'm30', mp(3), ...
            'x10', mp(4), 'x20', mp(5), 'y00', mp(6));
        params_r(i, :) = tl.asVector();
        fits_r  (i, :) = tl.evaluate(t_fine);
    end
    tl_all_fits     (reg, :, :) = fits_r;
    trilinear_params(reg, :, :) = params_r;
end

% ----- plot ------------------------------------------------------------
% Small-multiples style: all regions on a single set of shared axes,
% stacked vertically with a y-offset of 0.1 corr units per region.
% Region 1 is at the top.
y_offset_step = 0.1;
f = figure('Position', [100 100 700 1000]);
ax = axes(f); hold(ax, 'on');

for reg = 1:nRegions
    % Region color from the standard uberphys palette.
    c = uberphys.get_brain_region_colors(char(regions(reg)));
    c = c(1:3);

    % Region 1 at the top: largest offset for smallest region index.
    offset = (nRegions - reg) * y_offset_step;

    % Data: shaded CI band + mean line, both in the region color, shifted.
    y_data = mean(output(reg).col_mean, 1) + offset;
    lo     = output(reg).col_mean_lower(:)' + offset;
    hi     = output(reg).col_mean_upper(:)' + offset;
    fill([t, fliplr(t)], [lo, fliplr(hi)], c, ...
         'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(t, y_data, '-', 'Color', c, 'LineWidth', 1.5);

    % Trilinear fit to the across-resample mean, shifted.
    plot(t_fine, tl_means(reg).evaluate(t_fine) + offset, ...
         'k--', 'LineWidth', 1.2);

    % Region name at the right edge of the axes, on this region's baseline.
    text(max(t) + 0.01, offset, char(regions(reg)), ...
        'Color', c, 'FontSize', 10, 'FontWeight', 'bold', ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left');
end

xline(0, 'k--');
ax.YTick     = 0:y_offset_step:(nRegions * y_offset_step);
ax.YGrid     = 'on';
ax.XGrid     = 'on';
ax.GridAlpha = 0.3;
box(ax, 'on');
xlabel(ax, 'Time after nTc (s)');
ylabel(ax, 'Col mean corr (regions offset by 0.1 each)');

% ----- save ------------------------------------------------------------
savefig       (f, fullfile(thisDir, 'trilinear_fits.fig'));
exportgraphics(f, fullfile(thisDir, 'trilinear_fits.pdf'), 'ContentType', 'vector');
exportgraphics(f, fullfile(thisDir, 'trilinear_fits.png'), 'Resolution',  300);

fprintf('Saved trilinear_fits.{fig,pdf,png} to %s\n', thisDir);
