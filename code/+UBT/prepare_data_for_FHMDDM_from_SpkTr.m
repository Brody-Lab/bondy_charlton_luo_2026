function success = prepare_data_for_FHMDDM_from_SpkTr(filepath, recording_id, SpkTr_settings, varargin)
%{
Prepare a dataset for the `FHMDDM` module from a dataset prepared by the `SpkTr` package

The `FHMDDM` module is located at https://github.com/Brody-Lab/FHMDDM. and The `SpkTr` package is
located at https://github.com/Brody-Lab/UberPhys/tree/main/thomas/src/%2BSpkTr

ARGUMENT

    filepath
        Absolute path where the dataset interpretable by the FHMDDM module to be saved. A character
        row vector.
    
    recording_id
        a character row vector identifying a recording sessions
    
    SpkTr_settings
        a character row vector identifying the settings under which the SpkTr dataset was made

RETURN

    success
        a scalar logical value indicating whether a file was successfully saved

OPTIONAL ARGUMENT

    maxtrials
        Maximum number of trials selected. If the dataset has more than the specified maximum, then 
        the first `maxtrials` are selected. This feature is useful for testing.

    neuronindices
        A numeric array of positive integers indicating which neurons are selected. By default, this
        is empty, indicating that all neurons will be selected. If this is just the scalar `0`, no
        neuron will be selected (useful for fitting a drift-diffusion model to behavior).

    probeserial_indexinprobe
        Specify neurons to include using a vector of strings. Each element of the vector should have
        the format "<probeserial>_<indexinprobe>" such as "19108310372_002"

EXAMPLE
    
    analysisname = 'test';
    folder_data_for_FHMDDM = fullfile(UBT.analysisoutput_path, analysisname, 'data_for_FHMDDM');
    if ~isfolder(folder_data_for_FHMDDM)
        mkdir(folder_data_for_FHMDDM)
    end
    recording_id = 'A324_2023_07_25';
    filepath = fullfile(folder_data_for_FHMDDM, [recording_id '.mat']);
    SpkTr_settings = 'settings_2023_10_21';
    UBT.prepare_data_for_FHMDDM_from_SpkTr(filepath, recording_id, SpkTr_settings);

%}
success = false;
validateattributes('FHMDDM_datapath', {'char'}, {'row'})
validateattributes('recording_id', {'char'}, {'row'})
validateattributes('SpkTr_settings', {'char'}, {'row'})
P=inputParser;
P.addParameter('maxtrials', [], @(x) validateattributes(x,{'numeric',}, {'integer', 'positive', 'scalar'}));
P.addParameter('neuronindices', [], @(x) validateattributes(x,{'numeric',}, {'integer', 'nonnegative'}));
P.addParameter('probeserial_indexinprobe', [], @(x) validateattributes(x,{'string',}, {}));

P.parse(varargin{:});
P=P.Results;
settings = SpkTr.settings(SpkTr_settings);
SpkTr_filepath = fullfile(settings.folderpath, recording_id, 'allneurons.mat');
assert(isfile(SpkTr_filepath))
load(SpkTr_filepath, 'neurons', 'trials')
if ~isempty(P.neuronindices)
    neuronindices = false(size(neurons));
    if P.neuronindices ~= 0
        neuronindices(P.neuronindices) = true;
    end
elseif ~isempty(P.probeserial_indexinprobe)
    x = arrayfun(@str2double, split(P.probeserial_indexinprobe, "_"));
    if numel(P.probeserial_indexinprobe)>1
        selected_probeserial = x(:,1);
        selected_index_in_probe = x(:,2);
    else
        selected_probeserial = x(1);
        selected_index_in_probe = x(2);
    end
    probeserial = [neurons.probeserial]';
    index_in_probe = double([neurons.index_in_probe]');
    neuronindices = false(size(neurons));
    for i = 1:numel(selected_probeserial)
        selected = probeserial==selected_probeserial(i) & ...
                   index_in_probe==selected_index_in_probe(i);
        assert(sum(selected)==1)
        neuronindices(selected) = true;
    end
else
    neuronindices = true(size(neurons));
end
trials = arrayfun(@(x) x, trials, 'uni', 0);
if ~isempty(P.maxtrials) && numel(trials) > P.maxtrials
    trials = trials(1:P.maxtrials);
end
for m = 1:numel(trials)
    trials{m}.spiketrains = num2cell(trials{m}.spiketrains(neuronindices,:),2);
    trials{m}.photostimulus_incline_on_s = NaN;
    trials{m}.photostimulus_decline_on_s = NaN;
    trials{m}.previousanswer = 0;
end
neurons = neurons(neuronindices);
neurons0 = neurons;
neurons = cell(numel(neurons0),1);
for i = 1:numel(neurons0)
    neurons{i} = struct;
    neurons{i}.brainarea = char(UBT.standardize_region_names(neurons0(i).brainarea));
    neurons{i}.index_in_probe = neurons0(i).index_in_probe;
    neurons{i}.probeserial = neurons0(i).probeserial;
    neurons{i}.righthemisphere = neurons0(i).righthemisphere;
    neurons{i}.mm_from_probe_tip = neurons0(i).mm_from_probe_tip;
    neurons{i}.quality_metrics = neurons0(i).quality_metrics;
end
save(filepath, 'neurons', 'trials')
success = isfile(filepath);