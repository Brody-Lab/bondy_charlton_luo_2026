% synthetic_trilinear_recovery  Diagnose whether the Trilinear fit
%                               recovers the drop time (midpoint of seg 2)
%                               and drop sharpness (duration of seg 2)
%                               under realistic noise levels.
%
% Generative model: flat upper plateau (m1 = 0) -> linear drop (m2 < 0)
% -> flat lower plateau (m3 = 0), centred on x = 0, with the drop
% amplitude and noise level matched to the real data.
%
% Sweeps drop_dur in {0.025, 0.05, 0.10, 0.20} and reports recovered
% (drop_time, drop_dur) distributions across N noisy realizations.

if ~exist('output', 'var')
    error('output not found in workspace.');
end

thisDir = fileparts(mfilename('fullpath'));
if isempty(thisDir), thisDir = pwd; end
addpath(thisDir);

pool = gcp('nocreate');
if isempty(pool); pool = parpool; end
pctRunOnAll(['addpath(''' thisDir ''')']);

% ----- generative parameters ------------------------------------------
t            = output(1).click_times;
drop_center  = 0;
drop_amp     = 0.05;     % matches median |scale| of mid-amplitude regions
y0_upper     = drop_amp; % upper plateau value (so lower plateau = 0)
dur_grid     = [0.025, 0.05, 0.10, 0.20];   % truths to test

% ----- noise level: per-sample bootstrap std, averaged across regions -
ns = nan(numel(output), numel(t));
for r = 1:numel(output)
    ns(r,:) = std(output(r).col_mean, 0, 1);
end
sigma_noise = mean(ns(:), 'omitnan');
fprintf('Estimated per-sample noise std: %.4f\n', sigma_noise);
fprintf('Synthetic drop amplitude / noise: %.2f (matches real-data SNR)\n\n', ...
        drop_amp / sigma_noise);

% ----- generate + fit, swept across drop_dur --------------------------
N  = 300;
nS = numel(dur_grid);
results = struct('dur_true', cell(1,nS), 'mid_true', cell(1,nS), ...
                 'dur_fit',  cell(1,nS), 'mid_fit',  cell(1,nS), ...
                 'x1_fit',   cell(1,nS), 'x2_fit',   cell(1,nS));

rng(2026);
for is = 1:nS
    dur_true = dur_grid(is);
    mid_true = drop_center;
    x1_true  = mid_true - dur_true/2;
    x2_true  = mid_true + dur_true/2;
    m1_true  = 0;
    m3_true  = 0;
    m2_true  = -drop_amp / dur_true;        % slope of drop segment

    tl_true  = Trilinear(m1_true, m2_true, m3_true, x1_true, x2_true, y0_upper);
    y_true   = tl_true.evaluate(t);

    x1_fit = nan(N, 1);
    x2_fit = nan(N, 1);

    fprintf('Fitting %d synthetic realizations, drop_dur = %.3f (slope = %.2f)...\n', ...
        N, dur_true, m2_true);
    parfor i = 1:N
        y_i = y_true + sigma_noise * randn(size(t));
        tl  = Trilinear.fit(t, y_i);
        v   = tl.asVector();    % [m1 m2 m3 x1 x2 y0]
        x1_fit(i) = v(4);
        x2_fit(i) = v(5);
    end

    dur_fit_v = x2_fit - x1_fit;
    mid_fit_v = (x1_fit + x2_fit) / 2;

    results(is).dur_true = dur_true;
    results(is).mid_true = mid_true;
    results(is).dur_fit  = dur_fit_v;
    results(is).mid_fit  = mid_fit_v;
    results(is).x1_fit   = x1_fit;
    results(is).x2_fit   = x2_fit;

    qd = prctile(dur_fit_v, [5 25 50 75 95]);
    qm = prctile(mid_fit_v, [5 25 50 75 95]);
    fprintf('  dur (truth %.3f) p05=%.4f p25=%.4f med=%.4f p75=%.4f p95=%.4f\n', ...
            dur_true, qd(1), qd(2), qd(3), qd(4), qd(5));
    fprintf('  mid (truth %.3f) p05=%.4f p25=%.4f med=%.4f p75=%.4f p95=%.4f\n\n', ...
            mid_true, qm(1), qm(2), qm(3), qm(4), qm(5));
end

% ----- plot -----------------------------------------------------------
f  = figure('Position', [120 60 1100 800], 'Name', 'Synthetic trilinear recovery');
tl = tiledlayout(3, nS, 'TileSpacing', 'compact', 'Padding', 'compact');

% row 1: recovered drop_dur histograms
edges_dur = linspace(0, 0.6, 41);
for is = 1:nS
    nexttile(is);
    d = results(is).dur_fit;
    histogram(min(d, 0.6), edges_dur, 'FaceColor', [0.5 0.7 0.4], 'EdgeColor', 'none');
    xline(results(is).dur_true, 'r-',  'LineWidth', 1.5);
    xline(median(d),            'k--', 'LineWidth', 1.2);
    xlabel('recovered drop duration  ( x_2-x_1 )');
    ylabel('count');
    title(sprintf('dur_{true} = %.3f', results(is).dur_true));
    text(0.97, 0.92, sprintf('median = %.3f', median(d)), ...
         'Units', 'normalized', 'HorizontalAlignment', 'right', 'FontSize', 9);
    box off;
end

% row 2: recovered drop_time (midpoint) histograms
edges_mid = linspace(-0.4, 0.3, 41);
for is = 1:nS
    nexttile(nS + is);
    m = results(is).mid_fit;
    histogram(m, edges_mid, 'FaceColor', [0.5 0.7 0.4], 'EdgeColor', 'none');
    xline(results(is).mid_true, 'r-',  'LineWidth', 1.5);
    xline(median(m),            'k--', 'LineWidth', 1.2);
    xlabel('recovered drop time  ( (x_1+x_2)/2 )');
    ylabel('count');
    title(sprintf('dur_{true} = %.3f', results(is).dur_true));
    box off;
end

% row 3: truth (red) + 5 sample noisy realizations
t_fine = linspace(min(t), max(t), 400);
rng(2026);
for is = 1:nS
    nexttile(2*nS + is); hold on;
    dur_true = results(is).dur_true;
    x1_true  = drop_center - dur_true/2;
    x2_true  = drop_center + dur_true/2;
    m2_true  = -drop_amp / dur_true;
    tl_true  = Trilinear(0, m2_true, 0, x1_true, x2_true, y0_upper);

    plot(t_fine, tl_true.evaluate(t_fine), 'r-', 'LineWidth', 2);
    y_truth_t = tl_true.evaluate(t);
    for k = 1:5
        y_i = y_truth_t + sigma_noise * randn(size(t));
        plot(t, y_i, '.-', 'Color', [0.5 0.7 0.4 0.5], 'MarkerSize', 8, 'LineWidth', 0.5);
    end
    xlabel('t'); ylabel('y');
    title(sprintf('truth + 5 noisy samples (dur_{true} = %.3f)', dur_true));
    box off;
end

title(tl, sprintf(['Trilinear fit calibration: drop_{amp}=%.2g, noise std=%.3f, SNR=%.1f, N=%d' ...
                   '   (red = truth, dashed = recovered median)'], ...
                  drop_amp, sigma_noise, drop_amp/sigma_noise, N), ...
      'FontSize', 11);

% ----- save ----------------------------------------------------------
stem = fullfile(thisDir, 'synthetic_trilinear_recovery');
savefig       (f, [stem '.fig']);
exportgraphics(f, [stem '.png'], 'Resolution', 200);
fprintf('Saved %s.{fig,png}\n', stem);
