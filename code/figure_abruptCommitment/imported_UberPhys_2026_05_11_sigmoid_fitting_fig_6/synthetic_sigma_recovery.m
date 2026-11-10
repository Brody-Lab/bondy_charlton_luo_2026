% synthetic_sigma_recovery  Diagnose whether the cumulative-Gaussian fit
%                           recovers wide-sigma transitions, or is biased
%                           toward sharp ones.
%
% Strategy:
%   - Use the same time grid t as the real data (output(1).click_times).
%   - Generate a "true" cumulative-Gaussian with sigma_true = 0.2 (wide).
%   - Estimate noise from the real bootstrap data so synthetic noise is
%     comparable in magnitude.
%   - Generate N noisy realizations, fit each with CumulativeGaussian.fit,
%     and look at the recovered sigma distribution.
%
% If recovered sigmas cluster near 0.2  -> fit is well-calibrated for wide
%                                          transitions; the real-data
%                                          sharpness is genuine.
% If recovered sigmas cluster near 0    -> fit is biased toward sharp
%                                          transitions even when truth is
%                                          wide; the real-data sharpness
%                                          is an artifact.

if ~exist('output', 'var')
    error('output not found in workspace.');
end

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
addpath(thisDir);

% ----- generative parameters (realistic amplitude / SNR) --------------
t           = output(1).click_times;
mu_true     = 0;
scale_true  = -0.05;       % matches median |scale| of mid-amplitude regions
offset_true = 0;
sigma_grid  = [0.025, 0.05, 0.10, 0.20];   % truths to test

% ----- noise level: average per-sample bootstrap std across regions ---
ns = nan(numel(output), numel(t));
for r = 1:numel(output)
    ns(r,:) = std(output(r).col_mean, 0, 1);
end
sigma_noise = mean(ns(:), 'omitnan');
fprintf('Estimated per-sample noise std (bootstrap, avg across regions/time): %.4f\n', sigma_noise);
fprintf('Synthetic |scale|/noise ratio: %.2f (matches real-data SNR)\n\n', abs(scale_true)/sigma_noise);

% ----- generate + fit, swept across sigma_true ------------------------
N = 300;
nS = numel(sigma_grid);
results = struct('sigma_true', cell(1,nS), 'sigma_fit', cell(1,nS), ...
                 'mu_fit', cell(1,nS), 'scale_fit', cell(1,nS));

rng(2026);
for is = 1:nS
    sigma_true = sigma_grid(is);
    y_true     = scale_true * normcdf(t, mu_true, sigma_true) + offset_true;

    mu_fit    = nan(N, 1);
    sigma_fit = nan(N, 1);
    scale_fit = nan(N, 1);

    fprintf('Fitting %d synthetic realizations with sigma_true = %.3f...\n', N, sigma_true);
    parfor i = 1:N
        y_i = y_true + sigma_noise * randn(size(t));
        cg  = CumulativeGaussian.fit(t, y_i);
        v   = cg.asVector();
        mu_fit(i)    = v(1);
        sigma_fit(i) = v(2);
        scale_fit(i) = v(3);
    end

    results(is).sigma_true = sigma_true;
    results(is).sigma_fit  = sigma_fit;
    results(is).mu_fit     = mu_fit;
    results(is).scale_fit  = scale_fit;

    qs = prctile(sigma_fit, [5 25 50 75 95]);
    fprintf('  recovered sigma  min=%.4f p05=%.4f p25=%.4f med=%.4f p75=%.4f p95=%.4f max=%.4f\n', ...
        min(sigma_fit), qs(1), qs(2), qs(3), qs(4), qs(5), max(sigma_fit));
    fprintf('  frac sigma < 0.05: %.2f   frac sigma > 0.10: %.2f   frac sigma >= 0.99 (ub): %.2f\n\n', ...
        mean(sigma_fit < 0.05), mean(sigma_fit > 0.10), mean(sigma_fit >= 0.99));
end

% pull out the sigma_true = 0.2 case for plotting compatibility
i02 = find(sigma_grid == 0.2, 1);
sigma_fit  = results(i02).sigma_fit;
mu_fit     = results(i02).mu_fit;
scale_fit  = results(i02).scale_fit;
sigma_true = 0.2;
y_true     = scale_true * normcdf(t, mu_true, sigma_true) + offset_true;

% ----- plot ----------------------------------------------------------
f = figure('Position', [120 40 1100 900], 'Name', 'Synthetic sigma+mu recovery');
tl = tiledlayout(3, nS, 'TileSpacing', 'compact', 'Padding', 'compact');

% row 1: recovered-sigma histograms, one per sigma_true
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

% row 2: recovered-mu histograms, one per sigma_true
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

% row 3: 5 sample noisy realizations + truth, per sigma_true
t_fine = linspace(min(t), max(t), 400);
rng(2026);
for is = 1:nS
    nexttile(2*nS + is);  hold on;
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

title(tl, sprintf(['CumulativeGaussian fit calibration: |scale|=%.2g, noise std=%.3f, SNR=%.1f, N=%d' ...
                   '   (red = truth, dashed = recovered median)'], ...
                  abs(scale_true), sigma_noise, abs(scale_true)/sigma_noise, N), ...
      'FontSize', 11);

% ----- save ----------------------------------------------------------
stem = fullfile(thisDir, 'synthetic_sigma_recovery');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.png'], 'Resolution', 200);
fprintf('\nSaved %s.{fig,png}\n', stem);
