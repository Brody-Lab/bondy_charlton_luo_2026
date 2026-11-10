% cum_normal_fits  Fit a 4-parameter cumulative-normal sigmoid to
%                  col_mean for every bootstrap resample of every region
%                  in `output`, plot the per-region across-resample-mean
%                  fit, and save as .fig / .pdf / .png.
%
% Identical workflow to cum_gauss_fits, except the fitter is the new
% CumulativeNormal class (a thin wrapper around MATLAB's built-in `fit`
% from Curve Fitting Toolbox) instead of CumulativeGaussian.
%
% Assumes the variables `output` and `regions` are in the workspace.
%   output  : 1 x nRegions struct; each entry has fields
%               .click_times  (1 x M time axis)
%               .col_mean     (N x M; N bootstrap resamples)
%   regions : 1 x nRegions string array of region names (used in titles)
%
% Strategy:
%   For each region, fit a CumulativeNormal to the across-resample mean
%   to obtain reliable parameters. Use those as the warm start
%   ('mu0','sigma0','scale0','offset0') for the fits to each bootstrap
%   resample. Inner loop is parallelised with parfor.
%
% Outputs to base workspace:
%   sigmoid_params : nRegions x N x 4 array of [mu sigma scale offset]
%   cn_all_fits    : nRegions x N x numel(t_fine) array of evaluated fits
%   cn_means       : 1 x nRegions array of CumulativeNormal fits to mean
%   is_anomalous   : nRegions x N logical
%
% Requires CumulativeNormal.m on the MATLAB path (same directory as
% this script).
%
% Adrian Bondy, 2026-05-19

% ----- parameters ------------------------------------------------------
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

cn_all_fits    = nan(nRegions, N, numel(t_fine));
cn_fits        = nan(nRegions, numel(t_fine));
sigmoid_params = nan(nRegions, N, 4);          % [mu sigma scale offset]
is_anomalous   = false(nRegions, N);
cn_means       = repmat(CumulativeNormal, 1, nRegions);

% Same anomaly criteria as cum_gauss_fits: positive-going sigmoid
% (scale > 0) or mu pinned within mu_bound_tol of the bounds enforced
% by CumulativeNormal.fit (min(t_fit) / max(t_fit)).
mu_bound_tol = 0.01;
mu_lb        = min(t_fit);
mu_ub        = max(t_fit);

% ----- fit every (region, resample) -----------------------------------
for reg = 1:nRegions
    data     = output(reg).col_mean;
    data_fit = data(:, fit_mask);
    cn_mean  = CumulativeNormal.fit(t_fit, mean(data_fit, 1));
    cn_means(reg) = cn_mean;
    mp       = cn_mean.asVector();   % [mu sigma scale offset]

    fits_r   = nan(N, numel(t_fine));
    params_r = nan(N, 4);
    parfor i = 1:N
        cn = CumulativeNormal.fit(t_fit, data_fit(i, :), ...
            'mu0',     mp(1), ...
            'sigma0',  mp(2), ...
            'scale0',  mp(3), ...
            'offset0', mp(4));
        params_r(i, :) = cn.asVector();
        fits_r  (i, :) = cn.evaluate(t_fine);
    end

    mu_r       = params_r(:, 1);
    scale_r    = params_r(:, 3);
    bad_r      = scale_r > 0 ...
               | abs(mu_r - mu_lb) < mu_bound_tol ...
               | abs(mu_r - mu_ub) < mu_bound_tol;
    params_r(bad_r, :) = NaN;
    fits_r  (bad_r, :) = NaN;

    cn_all_fits   (reg, :, :) = fits_r;
    sigmoid_params(reg, :, :) = params_r;
    is_anomalous  (reg, :)    = bad_r(:)';
    cn_fits       (reg, :)    = evaluate(cn_means(reg), t_fine);
end

% ----- anomaly summary -------------------------------------------------
n_bad_per_region = sum(is_anomalous, 2);
fprintf('Anomalous-resample counts (of %d) per region:\n', N);
for reg = 1:nRegions
    fprintf('  %-6s : %3d\n', char(regions(reg)), n_bad_per_region(reg));
end

% ----- plot ------------------------------------------------------------
y_offset_step = 0.1;
f = figure('Position', [100 100 700 1000]);
ax = axes(f); hold(ax, 'on');

for reg = 1:nRegions
    c = uberphys.get_brain_region_colors(char(regions(reg)));
    c = c(1:3);
    offset = (nRegions - reg) * y_offset_step;

    y_data = mean(output(reg).col_mean, 1) + offset;
    lo     = output(reg).col_mean_lower(:)' + offset;
    hi     = output(reg).col_mean_upper(:)' + offset;
    fill([t, fliplr(t)], [lo, fliplr(hi)], c, ...
         'EdgeColor', 'none', 'FaceAlpha', 0.3);
    plot(t, y_data, '-', 'Color', c, 'LineWidth', 1.5);

    plot(t_fine, cn_means(reg).evaluate(t_fine) + offset, ...
         'k--', 'LineWidth', 1.2);

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
title (ax, 'Cumulative-Normal (built-in fit) per-region mean fit');

% ----- save ------------------------------------------------------------
savefig       (f, fullfile(thisDir, 'cum_normal_fits.fig'));
exportgraphics(f, fullfile(thisDir, 'cum_normal_fits.pdf'), 'ContentType', 'vector');
exportgraphics(f, fullfile(thisDir, 'cum_normal_fits.png'), 'Resolution',  300);

fprintf('Saved cum_normal_fits.{fig,pdf,png} to %s\n', thisDir);
