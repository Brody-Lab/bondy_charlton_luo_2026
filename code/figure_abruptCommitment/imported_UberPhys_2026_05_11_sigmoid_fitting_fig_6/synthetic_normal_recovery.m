% synthetic_normal_recovery  Recovery analysis for the CumulativeNormal
%                            class (a thin wrapper around MATLAB's
%                            built-in `fit` for scale*normcdf+offset).
%
%   Mirrors synthetic_sigma_recovery.m but uses CumulativeNormal.fit
%   instead of CumulativeGaussian.fit. Three-row figure: recovered sigma,
%   recovered mu, sample noisy realizations -- one column per sigma_true.

if ~exist('output', 'var')
    error('output not found in workspace.');
end

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
addpath(thisDir);

pool = gcp('nocreate');
if isempty(pool); pool = parpool; end
pctRunOnAll(['addpath(''' thisDir ''')']);

% ----- generative parameters (matched to real-data SNR) ---------------
t           = output(1).click_times;
mu_true     = 0;
scale_true  = -0.05;
offset_true = 0;
sigma_grid  = [0.025, 0.05, 0.10, 0.20];

% ----- noise level ----------------------------------------------------
ns = nan(numel(output), numel(t));
for r = 1:numel(output)
    ns(r,:) = std(output(r).col_mean, 0, 1);
end
sigma_noise = mean(ns(:), 'omitnan');
fprintf('Per-sample noise std: %.4f\n', sigma_noise);
fprintf('Synthetic |scale|/noise = %.2f\n\n', abs(scale_true)/sigma_noise);

% ----- generate + fit -------------------------------------------------
N  = 300;
nS = numel(sigma_grid);
results = struct('sigma_true', cell(1,nS), 'sigma_fit', cell(1,nS), ...
                 'mu_fit',     cell(1,nS), 'scale_fit', cell(1,nS));

rng(2026);
for is = 1:nS
    sigma_true = sigma_grid(is);
    y_true     = scale_true*normcdf(t, mu_true, sigma_true) + offset_true;

    mu_fit    = nan(N, 1);
    sigma_fit = nan(N, 1);
    scale_fit = nan(N, 1);

    fprintf('Fitting %d synthetic realizations with sigma_true = %.3f...\n', N, sigma_true);
    parfor i = 1:N
        y_i = y_true + sigma_noise * randn(size(t));
        cn  = CumulativeNormal.fit(t, y_i);
        v   = cn.asVector();
        mu_fit(i)    = v(1);
        sigma_fit(i) = v(2);
        scale_fit(i) = v(3);
    end

    results(is).sigma_true = sigma_true;
    results(is).sigma_fit  = sigma_fit;
    results(is).mu_fit     = mu_fit;
    results(is).scale_fit  = scale_fit;

    qs = prctile(sigma_fit, [5 25 50 75 95]);
    qm = prctile(mu_fit,    [5 25 50 75 95]);
    fprintf('  sigma  p05=%.4f p25=%.4f med=%.4f p75=%.4f p95=%.4f\n', qs(1), qs(2), qs(3), qs(4), qs(5));
    fprintf('  mu     p05=%.4f p25=%.4f med=%.4f p75=%.4f p95=%.4f\n\n', qm(1), qm(2), qm(3), qm(4), qm(5));
end

% ----- plot -----------------------------------------------------------
f  = figure('Position', [120 40 1100 900], 'Name', 'Synthetic recovery (CumulativeNormal)');
tl = tiledlayout(3, nS, 'TileSpacing', 'compact', 'Padding', 'compact');

% row 1: recovered sigma histograms
edges_sigma = linspace(0, 0.4, 41);
for is = 1:nS
    nexttile(is);
    s_fit = results(is).sigma_fit;
    histogram(min(s_fit, 0.4), edges_sigma, 'FaceColor', [0.4 0.5 0.8], 'EdgeColor', 'none');
    xline(results(is).sigma_true, 'r-',  'LineWidth', 1.5);
    xline(median(s_fit),          'k--', 'LineWidth', 1.2);
    xlabel('recovered \sigma');  ylabel('count');
    title(sprintf('\\sigma_{true} = %.3f', results(is).sigma_true));
    text(0.97, 0.92, sprintf('median = %.3f', median(s_fit)), ...
         'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 9);
    box off;
end

% row 2: recovered mu histograms
edges_mu = linspace(-0.4, 0.3, 41);
for is = 1:nS
    nexttile(nS + is);
    m_fit = results(is).mu_fit;
    histogram(m_fit, edges_mu, 'FaceColor', [0.8 0.5 0.4], 'EdgeColor', 'none');
    xline(mu_true,       'r-',  'LineWidth', 1.5);
    xline(median(m_fit), 'k--', 'LineWidth', 1.2);
    xlabel('recovered \mu');  ylabel('count');
    title(sprintf('\\sigma_{true} = %.3f', results(is).sigma_true));
    text(0.97, 0.92, sprintf('median = %.3f', median(m_fit)), ...
         'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 9);
    box off;
end

% row 3: 5 sample noisy realizations + truth
t_fine = linspace(min(t), max(t), 400);
rng(2026);
for is = 1:nS
    nexttile(2*nS + is); hold on;
    sigma_true_is = results(is).sigma_true;
    y_t = scale_true*normcdf(t_fine, mu_true, sigma_true_is) + offset_true;
    plot(t_fine, y_t, 'r-', 'LineWidth', 2);
    y_truth_t = scale_true*normcdf(t, mu_true, sigma_true_is) + offset_true;
    for k = 1:5
        y_i = y_truth_t + sigma_noise * randn(size(t));
        plot(t, y_i, '.-', 'Color', [0.4 0.5 0.8 0.5], 'MarkerSize', 8, 'LineWidth', 0.5);
    end
    xlabel('t');  ylabel('y');
    title(sprintf('truth + 5 noisy samples (\\sigma_{true} = %.3f)', sigma_true_is));
    box off;
end

title(tl, sprintf(['CumulativeNormal (built-in `fit`) calibration: ' ...
                   '|scale|=%.2g, noise std=%.3f, SNR=%.1f, N=%d' ...
                   '   (red = truth, dashed = recovered median)'], ...
                  abs(scale_true), sigma_noise, abs(scale_true)/sigma_noise, N), ...
      'FontSize', 11);

% ----- save -----------------------------------------------------------
stem = fullfile(thisDir, 'synthetic_normal_recovery');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.png'], 'Resolution', 200);
fprintf('Saved %s.{fig,png}\n', stem);
