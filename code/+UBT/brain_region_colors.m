function colors = brain_region_colors()
% Load a struct with of red-blue-green (RGB) triplet for each brain region
    repositorypath = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    T = readtable(fullfile(repositorypath, 'logs', 'brain_region_colors.csv'), 'delimiter', ',');
    colors = struct;
    for i = 1:height(T)
        colors.(T.region{i}) = cellfun(@str2double, split(T.color{i}, ' '))';
    end
    colors.choice = zeros(1,3);
    colors.all = zeros(1,3);
end
