%% load posterior probability distributions
regions = ["M1"];
recording_id = 'A327_2023_09_01';
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
%%
index = 230;
pbound = cellfun(@(x) x(end), P.M1{230});
time_s = (1:numel(pbound))'*0.01;
trainindices = 1:2:numel(pbound);
testindices = 2:2:numel(pbound);
p_train = pbound(trainindices);
p_test = pbound(testindices);
time_s_train = time_s(trainindices);
time_s_test = time_s(testindices);
x0 = [1 0.5];
xhat = UBT.logistic_lsqcurvefit(x0, time_s_train, p_train);
g = @(x, time_s) 1 ./ (1 + exp(-x(1)*(time_s - x(2))))
p_test_fit = g(xhat,time_s_test);
SSTot = sum((p_test-mean(p_test)).^2)
SSRes = sum((p_test-p_test_fit).^2)
%%
figure
UBT.stylizeaxes
plot(time_s, pbound,'ko')
plot(time_s, g(xhat,time_s), 'k-')

%%

