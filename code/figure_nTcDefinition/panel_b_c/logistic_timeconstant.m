clc
clear
[analysispath, scriptname] = fileparts(matlab.desktop.editor.getActiveFilename);
[~, analysisname] = fileparts(analysispath);
%% get nTc's
T = readtable(fullfile(TZL.analyses_path, 'analysis_2024_08_13c_nTc', 'nTc.csv'), 'delimiter', ',');
T.index_in_MMDDMdata = nan(size(T,1),1);
recording_ids = string(unique(T.recording_id));
for i = 1:numel(recording_ids)
    indices = T.recording_id == recording_ids(i);
    T.index_in_MMDDMdata(indices) = 1:sum(indices);
end
indices = ~isnan(T.committime_s_M1) | ~isnan(T.committime_s_choice);
T = T(indices,:);
recording_ids = string(unique(T.recording_id))
%%
taus = struct;
R2 = struct;
[taus.M1, taus.choice, R2.M1, R2.choice] = deal(nan(size(T,1),1));
x0 = [1 0.5];
g = @(x, time_s) 1 ./ (1 + exp(-x(1)*(time_s - x(2))))
recording_ids = string(unique(T.recording_id));
k = 0;
for i = 1:numel(recording_ids)
    for region = ["M1"]
        S = load(fullfile(TZL.analysis_data_path, 'analysis_2024_08_08a_MMDDM_uberphys', ...
            [recording_ids{i} '_ALL'], 'results', 'individual_brain_areas', region, ...
            'paccumulator_spikes.mat'));
        P.(region) = S.paccumulator_spikes{1};
    end
    S = load(fullfile(TZL.analysis_data_path, 'analysis_2024_08_08a_MMDDM_uberphys', ...
        [recording_ids{i} '_ALL'], 'results', 'paccumulator_choice.mat'));
    P.choice = S.paccumulator_choice{1};
    trials = PBups.gettrials(recording_ids{1}(1:4), recording_ids{1}(6:15));
    Tsub = T(T.recording_id == recording_ids(i),:);
    for j = 1:size(Tsub,1)
        ntimesteps = numel(P.choice{Tsub.index_in_MMDDMdata(j)});
        time_s = (1:ntimesteps)'*0.01;
        trainindices = 1:2:ntimesteps;
        testindices = 2:2:ntimesteps;
        time_s_train = time_s(trainindices);
        time_s_test = time_s(testindices);
        k = k + 1;
        fprintf('\n%i %i', i, j)
        for cond = ["M1", "choice"]
            pboundL = cellfun(@(x) x(1), P.(cond){Tsub.index_in_MMDDMdata(j)});
            pboundR = cellfun(@(x) x(end), P.(cond){Tsub.index_in_MMDDMdata(j)});
            if pboundL(end) > pboundR(end)
                pbound = pboundL;
            else
                pbound = pboundR;
            end            
            pbound_train = pbound(trainindices);
            pbound_test = pbound(testindices);
            xhat = UBT.logistic_lsqcurvefit(x0, time_s_train, pbound_train);
            taus.(cond)(k) = 1/xhat(1);
            pbound_test_fit = g(xhat,time_s_test);
            SSTot = sum((pbound_test-mean(pbound_test)).^2);
            SSRes = sum((pbound_test-pbound_test_fit).^2);
            R2.(cond)(k) = 1-SSRes/SSTot;
        end
    end
end
T.logistic_tau_M1 = taus.M1;
T.logistic_tau_choice = taus.choice;
T.logistic_R2_M1 = R2.M1;
T.logistic_R2_choice = R2.choice;
writetable(T, fullfile(analysispath, [scriptname '.csv']), 'Delimiter',',')