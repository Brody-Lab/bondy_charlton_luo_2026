function options = tabulateoptions(analysispath)
    % tabulate the settings of all models fitted in analysis
    %
    % ARGUMENT
    % -'analysispath': absolute path of the folder containing the code and output of the
    % analysis
    %
    % RETURN
    % -`option`: a table
    csvpath = fullfile(analysispath, 'options.csv');
    if ~isfile(csvpath)
        csvpath = fullfile(analysispath, 'models.csv');
    end
    assert(isfile(csvpath))
    options = readtable(csvpath, 'Delimiter', ',');
    if ~ismember("datapath", options.Properties.VariableNames)
        options.datapath = cellfun(@(recording_id, datafolder) string(fullfile(datafolder, recording_id)), ...
            options.recording_id, options.datafolder);
    else
        options.datapath = string(options.datapath);
    end
    if ~ismember("outputpath", options.Properties.VariableNames)
        options.outputpath = cellfun(@(fitname, outputfolder) string(fullfile(outputfolder, fitname)), ...
            options.fitname, options.outputfolder);
    else
        options.outputpath = string(options.outputpath);
    end
    options.datapath = UBT.cup2windows(options.datapath);
    options.outputpath = UBT.cup2windows(options.outputpath);
end