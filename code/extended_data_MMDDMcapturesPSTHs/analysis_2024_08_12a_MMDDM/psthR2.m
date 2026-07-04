clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%%
T = UBT.tabulateoptions(analysispath)
T.recording_id=string(T.recording_id);
recording_ids = unique(T.recording_id);
nrecordings = numel(recording_ids);
psthR2 = struct;
psthR2.multimode = cell(nrecordings,1);
psthR2.singlemode = cell(nrecordings,1);
brainarea = cell(height(T),1);
for i = 1:nrecordings
    for model = ["multimode", "singlemode"]
        index = T.recording_id == recording_ids(i) & contains(T.outputpath, model);
        assert(sum(index==1))
        S = load(fullfile(T.outputpath{index}, 'crossvalidation', 'pethsets_stereoclick.mat'));
        D = load(T.datapath{index});
        brainarea{i} = cellfun(@(neuron) string(neuron.brainarea), D.neurons);
        nneurons = size(S.pethsets{1},1);
        indices = 1:numel(S.time_s);
        psthR2.(model){i} = nan(nneurons,1);
        for n = 1:nneurons
            psthR2.(model){i}(n) = FHMDDM.coefficient_of_determination(["leftchoice", "rightchoice"], ...
                                                        indices, S.pethsets{1}{n});
        end
    end
    i    
end
save(fullfile(analysispath, [scriptname '.mat']), 'psthR2', 'brainarea')