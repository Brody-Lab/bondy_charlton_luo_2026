clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = UBT.tabulateoptions(analysispath)
T.recording_id=string(T.recording_id);
recording_ids = unique(T.recording_id);
nrecordings = numel(recording_ids);
DeltaLL_trial_neuron = nan(nrecordings,1);
for i = 1:nrecordings
    indexMM = T.recording_id == recording_ids(i) & ...
                contains(T.outputpath, "multimode");
    indexSM = T.recording_id == recording_ids(i) & ...
                contains(T.outputpath, "singlemode");
    assert((sum(indexMM)==1) && (sum(indexSM)==1))
    D = load(T.datapath{indexMM});
    nneurons = numel(D.neurons);
    S_MM = load(fullfile(T.outputpath{indexMM}, 'crossvalidation', 'LL.mat'));
    S_SM = load(fullfile(T.outputpath{indexSM}, 'crossvalidation', 'LL.mat'));
    LL_MM = S_MM.LL{1};
    LL_SM = S_SM.LL{1};
    DeltaLL_trial_neuron(i) = mean(LL_MM-LL_SM)/nneurons;
    i
end
%%
figure('position', [100 100 300 275])
TZL.stylizeaxes
histogram(DeltaLL_trial_neuron, 0:0.01:0.1, 'facecolor', 'k', ...
    'facealpha', 0.2, 'linewidth', 1)
ylabel('sessions')
xlabel('Deltabits/(neurons*trials)')
title('multi - single mode')
xlim([0 0.1])
xticks(xlim)
yticks(ylim)
pval = signtest(DeltaLL_trial_neuron);
text(0.05, 6, sprintf('p=%0.0e', pval), 'FontSize',get(gca, 'Fontsize'))
saveas(gcf, fullfile(analysispath, [scriptname '.svg']))