function colors = get_brain_region_colors(regions)
    % RETURN the colors associated with the list of brain regions in
    % "regions" (can be string vector or cell array of chars)
    validateattributes(regions,{'cell','string','char'},{'nonempty'},mfilename,'regions',1);
    regions=string(regions);
    log = common.get_brain_region_color_log();
    for i = 1:numel(regions)      
        for k=1:numel(log.region)
            idx(k) = startsWith(regions(i),log.region(k));
        end
        idx=find(idx);
        if numel(idx)==1
            colors(i,:) = log.color(idx,:);
        elseif numel(idx)>1
            error('Region %s matches multiple regions in log.',regions(i));
        else
            colors(i,:)=[NaN NaN NaN];
            warning('Region %s has no matches in log.',regions(i));
        end
    end
end