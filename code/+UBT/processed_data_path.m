function p = processed_data_path()
    % Returns the absolute path to the processed_data directory

    % Get path to the folder containing this function
    baseDir = fileparts(fileparts(fileparts(mfilename('fullpath'))));

    % Construct the full path to the processed_data directory
    p = fullfile(baseDir, 'processed_data');
end