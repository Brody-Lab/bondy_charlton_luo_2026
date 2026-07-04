function log = get_brain_region_color_log()
% RETURN a table indicating the RGB values all figures should use to associate
% with a given brain region
    path=which('brain_region_colors.csv');
    if ~isfile(path)
        error('cannot find the table of brain regions')
    end
    log=readtable(path,'TextType','string','Delimiter',",");
    for i=height(log):-1:1
        color(i,:) = str2num(log.color(i));
    end
    log.color=color;
end