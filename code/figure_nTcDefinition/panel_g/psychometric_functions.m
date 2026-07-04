clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%
load(fullfile(analysispath, 'observed_and_simulated.mat'))
close all
colors = UBT.colors;
xs = -30:30;
figure('position', [100 100 1600 300])
k = 0;
for simulated = 0:1
    subplot(1,4,simulated+1)
    UBT.stylizeaxes
    nbins = 8;
    binedges = quantile(T.R_minus_L, 0:1/nbins:1);
    if simulated
        T.has_nTc = T.simulated_commitment_timestep > 0;
    else
        T.has_nTc = T.commitment_timestep > 0;
    end
    h = [];
    for has_nTc = 0:1
        trialindices = T.has_nTc == has_nTc;
        R_minus_L = T.R_minus_L(trialindices);
        if simulated
            choice = T.simulated_choice(trialindices);
        else
            choice = T.choice(trialindices);
        end
        groupindices = discretize(R_minus_L, binedges);
        [phat, pci] = splitapply(@(x) binofit(sum(x), numel(x)), choice, groupindices);
        avg_R_minus_L = splitapply(@mean, R_minus_L, groupindices);
        if has_nTc
            color = colors.nTc;
        else
            color = zeros(1,3);
        end
        % UBT.shadeplot(avg_R_minus_L, pci(:,1), pci(:,2), 'facecolor', color)
        h(has_nTc+1) = plot(avg_R_minus_L, phat, 'o', 'linewidth', 2, 'MarkerFaceColor',color, ...
            'MarkerEdgeColor',ones(1,3), 'markersize', 10);
        Fit = PBups.fit_logistic3(choice, R_minus_L);
        k = k + 1;
        sens(k) = Fit.sens;
        sens95(k) = Fit.error95.sens;
        lapse(k) = Fit.gamma;
        lapse95(k) = Fit.error95.gamma;

        p = Fit.gamma + (1-2*Fit.gamma)./(1+exp(-Fit.sens*(xs-Fit.bias)));
        plot(xs, p, 'linewidth', 1.5, 'color', color)
    end
    xlabel('#R - #L clicks')
    yticks([0 1])
    xticks([min(xs) 0 max(xs)])
    xlim([min(xs) max(xs)])
    ylabel('fraction chose R')
    plot(xlim, 0.5*[1,1], 'k--')
    plot([0,0], ylim, 'k--')
    if simulated
        title('simulated')
    else
        title('data')
    end
    text(5, 0.4, 'has nTc', 'FontSize', get(gca, 'fontsize'), 'color', colors.nTc)
    text(5, 0.25, 'no nTc', 'FontSize', get(gca, 'fontsize'), 'color', 'k')
end
subplot(1,4,3)
UBT.stylizeaxes
h = plot(1*[1,1], sens(1)+sens95(1)*[-1,1], 'k-', 'linewidth', 2)
plot(2*[1,1], sens(2)+sens95(2)*[-1,1], '-', 'color', colors.nTc, 'linewidth', 2)
plot(3*[1,1], sens(3)+sens95(3)*[-1,1], 'k-', 'linewidth', 2)
plot(4*[1,1], sens(4)+sens95(4)*[-1,1], '-', 'color', colors.nTc, 'linewidth', 2)

plot(1:2, sens(1:2), 'k-', 'linewidth', 1.5)
plot(3:4, sens(3:4), 'k-', 'linewidth', 1.5)
plot([1 3], sens([1 3]), 'o', 'linewidth', 1.5, 'MarkerFaceColor','k', ...
            'MarkerEdgeColor',ones(1,3), 'markersize', 8);
plot([2 4], sens([2 4]), 'o', 'linewidth', 1.5, 'MarkerFaceColor', colors.nTc, ...
            'MarkerEdgeColor',ones(1,3), 'markersize', 8);
ylabel('sensitivity')
xlim([0.4 4.5])
xticks([1.5, 3.5])
xticklabels(["data", "sim."])

legend(h, '95%CI', 'location', 'southeast')

subplot(1,4,4)
UBT.stylizeaxes
plot(1*[1,1], max(0, lapse(1)+lapse95(1)*[-1,1]), 'k-', 'linewidth', 2)
plot(2*[1,1], max(0, lapse(2)+lapse95(2)*[-1,1]), '-', 'color', colors.nTc, 'linewidth', 2)
plot(3*[1,1], max(0, lapse(3)+lapse95(3)*[-1,1]), 'k-', 'linewidth', 2)
plot(4*[1,1], max(0, lapse(4)+lapse95(4)*[-1,1]), '-', 'color', colors.nTc, 'linewidth', 2)

plot(1:2, lapse(1:2), 'k-', 'linewidth', 1.5)
plot(3:4, lapse(3:4), 'k-', 'linewidth', 1.5)
plot([1 3], lapse([1 3]), 'o', 'linewidth', 1.5, 'MarkerFaceColor','k', ...
            'MarkerEdgeColor',ones(1,3), 'markersize', 8);
plot([2 4], lapse([2 4]), 'o', 'linewidth', 1.5, 'MarkerFaceColor', colors.nTc, ...
            'MarkerEdgeColor',ones(1,3), 'markersize', 8);
ylabel('lapse rate')
xlim([0.4 4.5])
xticks([1.5, 3.5])
xticklabels(["data", "sim."])

exportgraphics(gcf, fullfile(analysispath, [scriptname '.pdf']),...
    "ContentType", "Vector", "BackgroundColor","none")
exportgraphics(gcf, fullfile(analysispath, [scriptname '.png']),...
    "BackgroundColor","none")