% deriv_normal_fits  Fit a Gaussian PDF to the discrete time derivative
%                    of col_mean for every bootstrap resample of every
%                    region in `output`. No curve-overlay plot, because
%                    the fit doesn't model the data asymptotes.
%
% Workflow:
%   1. For each bootstrap resample of each region, take the forward
%      difference along time:
%            dy_i = (y_{i+1} - y_i) / (t_{i+1} - t_i)
%      assigned to the midpoint time
%            t_mid_i = (t_i + t_{i+1}) / 2
%      That yields N-1 = 14 samples on a grid shifted by dt/2.
%   2. Fit the new Normal class (scale*normpdf(x, mu, sigma) + offset,
%      scale <= 0) to the derivative. mu and sigma directly recover the
%      drop time and drop sharpness of the underlying sigmoid.
%
% Outputs to base workspace:
%   sigmoid_params : nRegions x N x 4 array of [mu sigma scale offset]
%   normal_means   : 1 x nRegions array of Normal fits to mean(derivative)
%   is_anomalous   : nRegions x N logical
%   t_mid          : 1 x (M-1) midpoint time axis used for fitting
%
% Requires Normal.m on the MATLAB path (same directory as this script).
%
% Adrian Bondy, 2026-05-19

% ----- parameters ------------------------------------------------------
if ~exist('fit_x_range', 'var') || isempty(fit_x_range)
    fit_x_range = [-Inf Inf];
end

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
t        = output(1).click_times(:)';        % 1 x M
N        = size(output(1).col_mean, 1);

% Forward-difference midpoint grid: one fewer point than t.
t_mid   = (t(1:end-1) + t(2:end)) / 2;        % 1 x (M-1)
dt_vec  = diff(t);                            % per-pair spacing

% Optional restriction of which midpoint samples are used for fitting.
fit_mask = t_mid >= fit_x_range(1) & t_mid <= fit_x_range(2);
if ~any(fit_mask)
    error('fit_x_range = [%g %g] excludes every midpoint sample in t_mid.', ...
        fit_x_range(1), fit_x_range(2));
end
t_mid_fit = t_mid(fit_mask);

sigmoid_params = nan(nRegions, N, 4);    % [mu sigma scale offset]
is_anomalous   = false(nRegions, N);
normal_means   = repmat(Normal, 1, nRegions);

% Anomaly criteria. scale is already constrained <= 0; flag fits where
% the constraint is active (scale ~= 0 means no real dip in the
% derivative) or where mu is pinned within mu_bound_tol seconds of the
% midpoint-grid boundaries.
mu_bound_tol = 0.01;
mu_lb        = min(t_mid_fit);
mu_ub        = max(t_mid_fit);
scale_tol    = 1e-8;

% ----- fit every (region, resample) -----------------------------------
for reg = 1:nRegions
    data    = output(reg).col_mean;                    % N x M

    % Per-resample derivative on the midpoint grid.
    d_data  = diff(data, 1, 2) ./ dt_vec;              % N x (M-1)
    d_fit   = d_data(:, fit_mask);

    % Fit to the across-resample mean derivative as a warm start for
    % each bootstrap fit.
    n_mean        = Normal.fit(t_mid_fit, mean(d_fit, 1));
    normal_means(reg) = n_mean;
    mp            = n_mean.asVector();

    params_r = nan(N, 4);
    parfor i = 1:N
        nm = Normal.fit(t_mid_fit, d_fit(i, :), ...
            'mu0',     mp(1), ...
            'sigma0',  mp(2), ...
            'scale0',  mp(3), ...
            'offset0', mp(4));
        params_r(i, :) = nm.asVector();
    end

    % Flag anomalous resamples and NaN-mask them.
    mu_r    = params_r(:, 1);
    scale_r = params_r(:, 3);
    bad_r   = scale_r > -scale_tol ...                  % no dip
            | abs(mu_r - mu_lb) < mu_bound_tol ...
            | abs(mu_r - mu_ub) < mu_bound_tol;
    params_r(bad_r, :) = NaN;

    sigmoid_params(reg, :, :) = params_r;
    is_anomalous  (reg, :)    = bad_r(:)';
end

% ----- anomaly summary -------------------------------------------------
n_bad_per_region = sum(is_anomalous, 2);
fprintf('Anomalous-resample counts (of %d) per region:\n', N);
for reg = 1:nRegions
    fprintf('  %-6s : %3d\n', char(regions(reg)), n_bad_per_region(reg));
end

fprintf('Done. sigmoid_params, normal_means, is_anomalous, t_mid written to base workspace.\n');
