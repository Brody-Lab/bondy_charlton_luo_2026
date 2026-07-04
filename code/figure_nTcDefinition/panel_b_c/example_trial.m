clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%% load posterior probability distributions
regions = ["M1"];
recording_id = 'A324_2023_07_21';
for region = regions
    S = load(fullfile(TZL.analysis_data_path, 'analysis_2024_08_08a_MMDDM_uberphys', ...
        [recording_id '_ALL'], 'results', 'individual_brain_areas', region, ...
        'paccumulator_spikes.mat'));
    P.(region) = S.paccumulator_spikes{1};
end
S = load(fullfile(TZL.analysis_data_path, 'analysis_2024_08_08a_MMDDM_uberphys', ...
    [recording_id '_ALL'], 'results', 'paccumulator_choice.mat'));
P.choice = S.paccumulator_choice{1};
D = load(fullfile(TZL.analysis_data_path, 'analysis_2024_08_08a_MMDDM_uberphys', ...
        [recording_id '_ALL'], 'trialsets.mat'));
trials = PBups.gettrials('A324', '2023_07_21');
%% get nTc's
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
T = T(strcmp(T.recording_id, recording_id), :);
gammas = cellfun(@(trial) trial.gamma, D.trialsets{1}.trials);
%% parameters
i = 63; % trial
timesteps = [1 30];
thresh = 1e-3;
f = @(x) log10(max(thresh,x));
colors = UBT.colors;
colors.choice = 0.5*[1,1,1];
colors.M1 = [1 0 0];
colors.default = colororder;
nrows = 3;
ncols = 2;
xi = (2*(1:53) - 53 -1 )/(53-1);
ntimesteps = double(D.trialsets{1}.trials{i}.ntimesteps);
Delta_t = 0.01;
time_s = (1:ntimesteps)'*Delta_t;
cu = 0.5;
conditioned_on = ["M1", "choice"];
x0 = [1 0.5];
axx0 = 0.135;
axx = 0.3;
axy = 0.2;
xlim1 = [0 1] + [-1 0]*1/20;
ylim1 = [-1 1] + [-1 1]*1/10;
clims = [f(thresh), 0];
colorindices = clims(1):(diff(clims)/255):clims(2)
%% get click times
k = find(trials.stereoclick_s == T.stereoclick_time_s(i));
leftclick_s = trials.leftclick_s{k} - T.stereoclick_time_s(i);
rightclick_s = trials.rightclick_s{k} - T.stereoclick_time_s(i);
%%
nTc_s = T.committime_s_M1(i) - T.stereoclick_time_s(i);
ax = nan(3,1);
close all
for cond = ["M1", "choice"]
    posterior_raw = cell2mat(P.(cond){i}');
    hfig = figure('pos', [100 100 800 1200]);
    set(hfig, 'Renderer', 'Painters', 'color', ones(1,3))
    subplot(nrows,ncols,1)
    UBT.stylizeaxes
    for j = leftclick_s
        plot(j*[1,1], [1.2 1.3], 'color', colors.left, 'linewidth', 1.5)
    end
    for j = rightclick_s
        plot(j*[1,1], [1.35 1.45], 'color', colors.right, 'linewidth', 1.5)
    end
    xlim(xlim1)
    ylim([1.2 2.5])
    pos = get(gca, 'Position');
    pos(1) = axx0;
    pos(3) = axx;
    pos(4) = axy;
    set(gca, 'Position', pos,  'visible', 'off')

    % --------------------------------
    % heatmap
    ax(1) = subplot(nrows,ncols,3);
    UBT.stylizeaxes
    posterior = f(posterior_raw);
    xlim(xlim1)
    ylim(ylim1)
    xticks([0 1.0])
    yticks([-1 0 1])
    yticklabels([sprintf('\\color[rgb]{%f, %f, %f}%s', colors.left, '-B'), ...
                    "0", ...
                    sprintf('\\color[rgb]{%f, %f, %f}%s', colors.right, '+B')])
    UBT.stylizeaxes
    imagesc([0, time_s(end)], [-1 1], posterior, clims)
    cmap = colormap;
    xlabel('time from first click (s)')
    % title(['p(z | clicks, ' char(cond) ')'],'color', colors.(cond))
    % clim([f(thresh) 0])
    cb = colorbar('limits', [-3 0], 'ticks', [-3 -2 -1 log10(cu)], 'location', 'westoutside');
    cb.TickLabels = {'0.001','0.01', '0.1' '0.5'};
    cb.TickDirection = 'out';
    cb.Location = 'south';
    cb.AxisLocationMode = "manual";
    cb.Position = [0.52 0.3 0.25 0.0178];
    cb.TickLength = 0.02;
    cb.Label.LineWidth = 1;
    cb.YAxisLocation = "top";
    ylabel('accumulator (z)')
    plot(nTc_s, min(ylim)-0.2, '^', 'markeredgecolor', colors.nTc, ...
            'markerfacecolor', colors.nTc, 'markersize', 10)
    plot(nTc_s*[1,1], ylim, '--', 'color', colors.nTc)
    text(nTc_s-0.16, min(ylim)-0.4, 'nTc-M1', 'color', colors.nTc, 'FontSize', get(gca, 'fontsize'))    
    pos = get(gca, 'Position');
    pos(1) = axx0;
    pos(3) = axx;
    pos(4) = axy;
    set(gca, 'Position', pos, 'clipping', 'off', 'XAxisLocation', 'top')

    % ----------------------------------------------------------------------------------------------
    % probability plot
    ax(2) = subplot(nrows,ncols,5);
    UBT.stylizeaxes
    xlim(xlim1)
    ylim([-0.1, 1])
    xlabel('time from first click (s)')
    xticks([0 1])
    if trials.pokedR(i) == 0
        ylabel_str = sprintf('p(z = {\\color[rgb]{%f, %f, %f}%s} | clicks,', colors.left, '-B');
    else
    end
    ylabel_str = sprintf('%s {\\color[rgb]{%f, %f, %f}%s}', ylabel_str, colors.(cond), cond)
    if cond == "choice"
        ylabel_str = [ylabel_str ')'];
    else
        ylabel_str = [ylabel_str ' spikes)'];
    end
    ylabel(ylabel_str)
    yticks([0 1])
    if trials.pokedR(i) == 0
        pbound = cellfun(@(x) x(1), P.(cond){i});
    else
        pbound = cellfun(@(x) x(end), P.(cond){i});
    end
    xhat = UBT.logistic_lsqcurvefit(x0, time_s, pbound)
    g = @(x, time_s) 1 ./ (1 + exp(-x(1)*(time_s - x(2))))
    pbound_mdl = g(xhat, time_s);
    plot(time_s, pbound_mdl, 'k-', 'linewidth', 1)
    for q = 1:numel(pbound)
        index = find(colorindices>=f(pbound(q)), 1);
        plot(time_s(q), pbound(q), 'o', 'linewidth', 0.25, 'markeredgecolor', ones(1,3), ...
            'markerfacecolor', cmap(index,:), 'markersize', 8)
    end
    plot(nTc_s, max(ylim)*1.3, 'v', 'markeredgecolor', colors.nTc, ...
            'markerfacecolor', colors.nTc, 'markersize', 10, 'linewidth', 0.25)
    plot(xlim, 0.95*[1,1], '--', 'color', colors.nTc) % nTc threshold
    pos = get(gca, 'Position');
    pos(1) = axx0;
    pos(2) = pos(2) + 0.16;
    pos(3) = axx;
    pos(4) = axy/3;
    set(gca, 'Position', pos, 'clipping', 'off')

    % ----------------------------------------------------------------------------------------------
    ax(3) = subplot(nrows,ncols,4);
    UBT.stylizeaxes
    index = find(time_s >= nTc_s,1);
    p_thistime = posterior_raw(:,index);
    plot(p_thistime, xi, 'k-')
    for q = 1:numel(xi)
        index = find(colorindices>=f(p_thistime(q)), 1);
        plot(p_thistime(q), xi(q), 'o', 'linewidth', 0.5, 'markeredgecolor', ones(1,3), ...
            'markerfacecolor', cmap(index,:), 'markersize', 8)
    end
    % if cond == "choice"
    %     xlim(xlim.*[0 1.1])
    % else
        xlim([0 1.1])
    % end
    ylim(ylim1)
    xticks([0 1])
    yticks([-1, 0, 1])
    yticklabels([sprintf('\\color[rgb]{%f, %f, %f}%s', colors.left, '-B'), ...
                        "0", ...
                        sprintf('\\color[rgb]{%f, %f, %f}%s', colors.right, '+B')])    
    ylabel_str = sprintf('p(z | clicks, {\\color[rgb]{%f, %f, %f}%s}', colors.(cond), cond);
    if cond == "choice"
        ylabel_str = [ylabel_str ')'];
    else
        ylabel_str = [ylabel_str ' spikes)'];
    end
    xlabel(ylabel_str)
    title(sprintf('time = {\\color[rgb]{%f, %f, %f}nTc-M1}', colors.nTc))

    pos = get(gca, 'Position');
    pos_ax1 = get(ax(1), 'Position');
    pos(1) = pos(1)-0.05;
    pos(2) = pos_ax1(2);
    pos(3) = axx/2;
    pos(4) = axy;
    set(gca, 'Position', pos, 'clipping', 'off', 'yaxislocation', 'right')
    print(gcf, fullfile(analysispath, [scriptname '_' char(cond) '.svg']), '-dsvg')
    saveas(gcf, fullfile(analysispath, [scriptname '_' char(cond)]))
end