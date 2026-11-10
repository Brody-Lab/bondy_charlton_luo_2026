% logistic_fits  Fit a 4-parameter decreasing-Logistic sigmoid to
%                 col_mean for every bootstrap resample of every region
%                 in `output`, plot the per-region across-resample-mean
%                 fit, and save as .fig / .pdf / .png.
%
% Assumes the variables `output` and `regions` are in the workspace.
%   output  : 1 x nRegions struct; each entry has fields
%               .click_times  (1 x M time axis)
%               .col_mean     (N x M; N bootstrap resamples)
%   regions : 1 x nRegions string array of region names (used in titles)
%
% Strategy:
%   For each region, fit a Logistic to the across-resample mean to obtain
%   reliable parameters. Use those as the warm start ('x00','k0','scale0',
%   'offset0') for the fits to each bootstrap resample. Inner loop is
%   parallelised with parfor.
%
%   Logistic.fit enforces scale <= 0, so all fits are constrained to be
%   monotonically decreasing (positive -> negative).
%
% Requires Logistic.m on the MATLAB path (same directory as this script).
%
% Adrian Bondy, 2026-05-19

% ----- parameters ------------------------------------------------------
% fit_x_range : 1x2 vector [xmin xmax] restricting which time samples are
% used to learn the model parameters. Fits are still evaluated over the
% full t range. Use [-Inf Inf] (or leave unset) to fit on all samples.
if ~exist('fit_x_range', 'var') || isempty(fit_x_range)
    fit_x_range = [-Inf Inf];
end

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

fit_mask = t >= fit_x_range(1) & t <= fit_x_range(2);
if ~any(fit_mask)
    error('fit_x_range = [%g %g] excludes every time sample in t.', ...
        fit_x_range(1), fit_x_range(2));
end
t_fit = t(fit_mask);

lg_all_fits     = nan(nRegions, N, numel(t_fine));
lg_fits         = nan(nRegions, numel(t_fine));
logistic_params = nan(nRegions, N, 4);          % [x0 k scale offset]
is_anomalous    = false(nRegions, N);           % true => exclude
lg_means        = repmat(Logistic, 1, nRegions);

% Anomaly criteria: scale is already constrained <= 0 by Logistic.fit, so
% flag fits where the inequality is active (scale ~ 0; the fitter gave up
% on a sigmoid and returned a flat line) or where x0 is pinned within
% `x0_bound_tol` seconds of the bounds Logistic.fit enforces
% (min(t_fit) / max(t_fit)).
x0_bound_tol = 0.01;
scale_tol    = 1e-8;
x0_lb        = min(t_fit);
x0_ub        = max(t_fit);

% ----- fit every (region, resample) -----------------------------------
for reg = 1:nRegions
    data     = output(reg).col_mean;
    data_fit = data(:, fit_mask);
    lg_mean  = Logistic.fit(t_fit, mean(data_fit, 1));
    lg_means(reg) = lg_mean;
    mp       = lg_mean.asVector();   % [x0 k scale offset]

    fits_r   = nan(N, numel(t_fine));
    params_r = nan(N, 4);
    parfor i = 1:N
        lg = Logistic.fit(t_fit, data_fit(i, :), ...
            'x00',     mp(1), ...
            'k0',      mp(2), ...
            'scale0',  mp(3), ...
            'offset0', mp(4));
        params_r(i, :) = lg.asVector();
        fits_r  (i, :) = lg.evaluate(t_fine);
    end

    % Flag anomalous resamples and NaN-mask them out of the saved arrays
    % so downstream summaries can ignore them with 'omitnan'.
    x0_r    = params_r(:, 1);
    scale_r = params_r(:, 3);
    bad_r   = scale_r > -scale_tol ...           % constraint active / ~flat
            | abs(x0_r - x0_lb) < x0_bound_tol ...
            | abs(x0_r - x0_ub) < x0_bound_tol;
    params_r(bad_r, :) = NaN;
    fits_r  (bad_r, :) = NaN;

    lg_all_fits    (reg, :, :) = fits_r;
    logistic_params(reg, :, :) = params_r;
    is_anomalous   (reg, :)    = bad_r(:)';
    lg_fits        (reg, :)    = evaluate(lg_means(reg), t_fine);
end

% ----- anomaly summary -------------------------------------------------
n_bad_per_region = sum(is_anomalous, 2);
fprintf('Anomalous-resample counts (of %d) per region:\n', N);
for reg = 1:nRegions
    fprintf('  %-6s : %3d\n', char(regions(reg)), n_bad_per_region(reg));
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

    % Logistic fit to the across-resample mean, shifted.
    plot(t_fine, lg_means(reg).evaluate(t_fine) + offset, ...
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
title (ax, 'Logistic fit to the across-resample mean, per region');

% ----- save ------------------------------------------------------------
savefig       (f, fullfile(thisDir, 'logistic_fits.fig'));
exportgraphics(f, fullfile(thisDir, 'logistic_fits.pdf'), 'ContentType', 'vector');
exportgraphics(f, fullfile(thisDir, 'logistic_fits.png'), 'Resolution',  300);

fprintf('Saved logistic_fits.{fig,pdf,png} to %s\n', thisDir);
