% commitment_schematic.m
% Schematic contrasting two hypotheses for covert decision commitment:
%   left column  = DISCRETE   (drift-diffusion model, absorbing bound)
%   right column = CONTINUOUS (two-basin attractor, cf. Wong & Wang 2006)
%
% Rows:
%   1) the model as an energy landscape, with one simulated single-trial
%      particle. DDM: a flat accumulation plateau bounded by fully-absorbing
%      cliffs (energy drops instantaneously off-screen). Attractor: a smooth
%      double well, visible (low but finite) basins.
%   2) the single-trial decision variable -- the value of the same particle
%      over time. DDM: a biased random walk, frozen at the bound after
%      commitment. Attractor: a slow noisy descent that settles late and
%      keeps jittering.
%   3) idealized influence of an evidence pulse vs. time in the trial.
%      DDM: a step that drops at commitment. Attractor: a gradual decay.
%
% All lower panels share one "time in trial" axis (single trial, so the
% alignment is unambiguous). Commitment is centered for the DDM.
%
% Output (.fig/.pdf/.png) is written to the mirrored plots/ folder via
% common.savefig. Self-contained: does not depend on setup.m or TZL utils.

clc; clear; close all

%% ------------------------------------------------------------- paths ----
scriptfull = mfilename('fullpath');
scriptdir  = fileparts(scriptfull);
coderoot   = fileparts(fileparts(scriptdir));   % .../code  (for +common)
addpath(coderoot);
plotdir = strrep(scriptdir, 'code', 'plots');
if ~exist(plotdir, 'dir'); mkdir(plotdir); end

%% ---------------------------------------------------------- parameters --
rng(12)                                 % seed chosen for a clean single trial

right_color = [141  4 175]/255;         % "right" choice / right basin
left_color  = [  0 174 239]/255;        % "left"  choice / left  basin
traj_color  = [0.15 0.15 0.15];         % idealized bottom-row traces
guide_color = [0.6 0.6 0.6];            % faint guide lines
early_color = [0.8 0.8 0.8];            % start of an elapsed-time gradient
fs          = 11;                       % axis font size

B  = 1;                                 % bound height / basin DV value
E0 = 1;                                 % pre-commitment pulse impact
dt_trial = 0.02;                        % timestep (bin size) per trial

%% -------------------------------------------------------------- figure --
figure('Position', [100 100 540 640], 'Color', 'w')
tiledlayout(3, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

% ========================================================================
% ROW 1 -- model as an energy landscape (+ one single-trial particle)
% ========================================================================

% ---- (1,1) DDM: flat accumulation plateau, fully-absorbing bounds -------
ax = nexttile(1); hold(ax, 'on')

% landscape: flat plateau on [-1,1]; the bounds are fully absorbing, so the
% cliffs drop instantaneously to zero energy, far below the visible frame
yfloor = -1;                                % off-screen (below ylim)
plot(ax, [-1 -1 1 1], [yfloor 1 1 yfloor], '-', 'Color', [0 0 0], 'LineWidth', 2.5)

% one particle: a coarse biased random walk on the flat plateau (zero
% gradient = evidence accumulation) until it reaches the bound
xp = 0; drift = 1.5; D = 0.07; xwalk = xp;
for k = 1:2000
    xp = xp + drift*dt_trial + sqrt(2*D*dt_trial)*randn;
    if xp >= 1, xwalk(end+1) = 1; break; end %#ok<SAGROW>
    xwalk(end+1) = xp; %#ok<SAGROW>
end
n_commit = numel(xwalk) - 1;                % steps to commitment
T   = 2 * n_commit * dt_trial;             % commitment at the trial midpoint
N_T = 2 * n_commit;                        % steps in the whole trial

% the walk lives on the plateau (E=1); absorption at the bound is
% instantaneous, so no markers descend the cliff
for j = 1:numel(xwalk)
    frac = (j-1)/(numel(xwalk)-1);
    c = (1-frac)*early_color + frac*right_color;
    plot(ax, xwalk(j), 1, 'o', 'MarkerSize', 6, ...
        'MarkerFaceColor', c, 'MarkerEdgeColor', 'none')
end

text(ax, -1.3, -0.12, 'left',  'Color', left_color,  'FontSize', fs-1, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
text(ax,  1.3, -0.12, 'right', 'Color', right_color, 'FontSize', fs-1, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')

xlim(ax, [-1.7 1.7]); ylim(ax, [-0.35, 1.25])
ylabel(ax, 'energy')
xlabel(ax, 'decision variable')
title(ax, 'Discrete (drift-diffusion)', 'FontWeight', 'bold')
style_axis(ax, fs); set(ax, 'XTick', [], 'YTick', [])

% ---- (1,2) Attractor: double-well landscape + slow descending particle --
ax = nexttile(2); hold(ax, 'on')

xx = linspace(-1.65, 1.65, 400);
plot(ax, xx, well_E(xx), '-', 'Color', [0 0 0], 'LineWidth', 2.5)

% one particle, simulated for the whole trial: a slow, noisy descent from
% the central hump that reaches the right well only late and keeps jittering
xp = 0.12; relax = 0.9; D = 0.028;
xs = xp;
for k = 1:N_T
    xp = xp - relax*well_dE(xp)*dt_trial + sqrt(2*D*dt_trial)*randn;
    xs(end+1) = xp; %#ok<SAGROW>
end
idx = round(linspace(1, numel(xs), 14));       % subsample the trail
for j = 1:numel(idx)
    frac = (j-1)/(numel(idx)-1);
    c = (1-frac)*early_color + frac*right_color;
    plot(ax, xs(idx(j)), well_E(xs(idx(j))), 'o', 'MarkerSize', 6, ...
        'MarkerFaceColor', c, 'MarkerEdgeColor', 'none')
end

text(ax, -1, well_E(-1)-0.12, 'left', 'Color', left_color, 'FontSize', fs-1, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')
text(ax,  1, well_E(1)-0.12, 'right', 'Color', right_color, 'FontSize', fs-1, ...
    'HorizontalAlignment', 'center', 'VerticalAlignment', 'top')

xlim(ax, [-1.7 1.7]); ylim(ax, [-0.35, 1.25])
ylabel(ax, 'energy')
xlabel(ax, 'decision variable')
title(ax, 'Continuous (two-basin attractor)', 'FontWeight', 'bold')
style_axis(ax, fs); set(ax, 'XTick', [], 'YTick', [])

% ------ shared single-trial time base (same axis for all lower panels) --
t_ddm    = (0:numel(xwalk)-1) * dt_trial;   % DDM particle time -> commitment
t_att    = (0:numel(xs)-1)    * dt_trial;   % attractor particle time (0..T)
t_commit = n_commit * dt_trial;             % = T/2
settle_idx = find(abs(xs-1) < 0.1, 1);      % first arrival in the right well
if isempty(settle_idx)
    t_settle = 0.85*T;
else
    t_settle = (settle_idx-1) * dt_trial;
end

% ========================================================================
% ROW 2 -- single-trial decision variable (the particle simulated above)
% ========================================================================

% ---- (2,1) DDM: random walk, frozen at the absorbing bound after commit -
ax = nexttile(3); hold(ax, 'on')
plot(ax, [0 T], [B B], ':', 'Color', guide_color, 'LineWidth', 0.75)
gradient_line(ax, [t_ddm T], [xwalk B], early_color, right_color, 1.8)
xlim(ax, [0 T]); ylim(ax, [-0.05*B, 1.30*B])
commit_vline(ax, t_commit)
ylabel(ax, 'decision variable')
xlabel(ax, 'time in trial')
set(ax, 'XTick', [], 'YTick', [0 B], 'YTickLabel', {'0','B'})
style_axis(ax, fs)

% ---- (2,2) Attractor: noisy descent, still jittering at the end ---------
ax = nexttile(4); hold(ax, 'on')
gradient_line(ax, t_att, xs, early_color, right_color, 1.8)
xlim(ax, [0 T]); ylim(ax, [-0.05*B, 1.30*B])
xlabel(ax, 'time in trial')
set(ax, 'XTick', [], 'YTick', 0, 'YTickLabel', {'0'})
style_axis(ax, fs)

% ========================================================================
% ROW 3 -- idealized influence of an evidence pulse vs. time in trial
% ========================================================================

% ---- (3,1) DDM: step -- full influence until commitment, then zero -----
ax = nexttile(5); hold(ax, 'on')
plot(ax, [0 t_commit],  [E0 E0], '-', 'Color', traj_color, 'LineWidth', 1.8)
plot(ax, [t_commit t_commit], [E0 0], '-', 'Color', traj_color, 'LineWidth', 1.8)
plot(ax, [t_commit T],  [0 0],  '-', 'Color', traj_color, 'LineWidth', 1.8)
xlim(ax, [0 T]); ylim(ax, [-0.05*E0, 1.30*E0])
commit_vline(ax, t_commit)
ylabel(ax, 'influence of evidence on DV')
xlabel(ax, 'time in trial')
set(ax, 'XTick', [], 'YTick', [0 E0], 'YTickLabel', {'0','max'})
style_axis(ax, fs)

% ---- (3,2) Attractor: gradual decay that asymptotes toward zero --------
% a descending logistic -- the mirror of the DV's sigmoidal rise: full
% influence early, dropping as the particle commits, asymptoting (never
% snapping) to zero as it sinks into the basin
ax = nexttile(6); hold(ax, 'on')
t = linspace(0, T, 400);
t_mid = 0.5*T;                               % influence half-max at mid-trial
a     = 7/T;                                 % near max at start, near zero by trial end
k_att = E0 ./ (1 + exp(a*(t - t_mid)));
plot(ax, t, k_att, '-', 'Color', traj_color, 'LineWidth', 1.8)
xlim(ax, [0 T]); ylim(ax, [-0.05*E0, 1.30*E0])
xlabel(ax, 'time in trial')
set(ax, 'XTick', [], 'YTick', [0 E0], 'YTickLabel', {'0','max'})
style_axis(ax, fs)

%% ---------------------------------------------------------------- save --
common.savefig(gcf, scriptfull)

% ======================================================================
% local helpers
% ======================================================================
function E = well_E(x)
    E = (x.^2 - 1).^2;
end

function dE = well_dE(x)
    dE = 4*x.*(x.^2 - 1);
end

function style_axis(ax, fs)
    set(ax, 'FontSize', fs, 'TickDir', 'out', 'Box', 'off', ...
        'LineWidth', 1, 'XColor', 'k', 'YColor', 'k', 'Color', 'w')
end

function commit_vline(ax, x0)
    yl = get(ax, 'YLim');
    plot(ax, [x0 x0], yl, '--', 'Color', [0.93 0.49 0.13], 'LineWidth', 1.1)
end

function gradient_line(ax, x, y, c0, c1, lw)
    % draw a polyline whose color ramps from c0 (start) to c1 (end)
    n = numel(x);
    for i = 1:n-1
        frac = (i-1) / max(1, n-2);
        c = (1-frac)*c0 + frac*c1;
        plot(ax, x(i:i+1), y(i:i+1), '-', 'Color', c, 'LineWidth', lw)
    end
end
