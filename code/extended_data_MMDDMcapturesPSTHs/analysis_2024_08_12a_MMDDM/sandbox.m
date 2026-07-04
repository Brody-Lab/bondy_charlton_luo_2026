clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~,analysisname] = fileparts(analysispath);
%%
psm = load('X:\tzluo\analysis_data\analysis_2024_08_12a_MMDDM\A324_2023_07_19a_singlemode\crossvalidation\paccumulator_spikes.mat');
pmm = load('X:\tzluo\analysis_data\analysis_2024_08_12a_MMDDM\A324_2023_07_19a_multimode\crossvalidation\paccumulator_spikes.mat');
P = struct;
P.singlemode = psm.paccumulator_spikes{1};
P.multimode = pmm.paccumulator_spikes{1};
%%
i = i+1;
clf
subplot(1,2,1)
TZL.stylizeaxes
for mode = ["singlemode", "multimode"]
    p = cellfun(@(x) x(1), P.(mode){i});
    t = (2:numel(p))*0.01;
    plot(t,diff(p))
end
ylim([0 1])
subplot(1,2,2)
TZL.stylizeaxes
for mode = ["singlemode", "multimode"]
    p = cellfun(@(x) x(end), P.(mode){i});
    t = (2:numel(p))*0.01;
    plot(t,diff(p))
end
ylim([0 1])
