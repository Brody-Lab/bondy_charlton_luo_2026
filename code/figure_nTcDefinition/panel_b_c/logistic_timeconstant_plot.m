clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = readtable(fullfile(analysispath, 'logistic_timeconstant.csv'), 'delimiter', ',');
%%
close all
colors = UBT.colors;
figure('pos', [1e3 1e3 350 275])
UBT.stylizeaxes
set(gca, 'DataAspectRatio', [1,1,1], 'clipping', 'on')
lims = [-3 0];
xlim(lims)
ylim(lims)
plot(lims, lims, 'k--')
has_nTc = ~isnan(T.committime_s_M1) | ~isnan(T.committime_s_choice);
has_nTc_well_fit = has_nTc & T.logistic_R2_M1 > 0 & T.logistic_R2_choice > 0;
has_nTc_poor_fit = has_nTc & (T.logistic_R2_M1 <= 0 | T.logistic_R2_choice <= 0);

% scatter(log10(T.logistic_tau_M1(has_nTc_poor_fit)), ...
%     log10(T.logistic_tau_choice(has_nTc_poor_fit)), 'b*','markerfacecolor', [0,0,1], ...
%     'markeredgealpha', 1, 'markerfacealpha', 1, 'sizedata', 10)

scatter(log10(T.logistic_tau_M1(has_nTc_well_fit)), ...
    log10(T.logistic_tau_choice(has_nTc_well_fit)), 'k','markerfacecolor', [0,0,0], ...
    'markeredgealpha', 0.1, 'markerfacealpha', 0.1, 'sizedata', 10)

xlabel(sprintf('{\\color[rgb]{%f, %f, %f} M1} t (s)', colors.M1))
ylabel(sprintf('{\\color[rgb]{%f, %f, %f} choice} t (s)', colors.choice))
ticks = [-2 0];
xticks(ticks)
xticklabels(arrayfun(@(x) num2str(10^x), xticks, 'uni', 0))
yticks(ticks)
yticklabels(arrayfun(@(x) num2str(10^x), yticks, 'uni', 0))
colors.default = colororder;
plot(median(log10(T.logistic_tau_M1))*[1,1], max(ylim)*[1,1], ...
    'v', 'color', colors.M1)
plot(max(xlim)*[1,1], median(log10(T.logistic_tau_choice))*[1,1], ...
    '<', 'color', colors.choice)
text(median(log10(T.logistic_tau_M1)), max(ylim), ...
    num2str(median(T.logistic_tau_M1), '%0.2f'), 'color', colors.M1, ...
    'fontsize', get(gca, 'fontsize'))
text(max(xlim), median(log10(T.logistic_tau_choice)), ...
    num2str(median(T.logistic_tau_choice), '%0.2f'), 'color', colors.choice, ...
    'fontsize', get(gca, 'fontsize'))
print(gcf, fullfile(analysispath, [scriptname '.svg']), '-dsvg')
saveas(gcf, fullfile(analysispath, [scriptname '_' char(cond)]))
fprintf('\n%0.2f percent of the trials were well fit by a logistic model', sum(has_nTc_well_fit)/sum(has_nTc)*100)