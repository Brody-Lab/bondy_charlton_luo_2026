function color_tick_labels()
    ax=gca;
    xlabels = ax.XTickLabels;
    ylabels = ax.YTickLabels;    
    if ~isempty(xlabels)
        xcolors = common.get_brain_region_colors(xlabels);
        for i=1:numel(xlabels)
            if all(~isnan(xcolors(i,:)))
                ax.XTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s', xcolors(i,:), xlabels{i});
            end
        end
    end
    if ~isempty(ylabels)
        ycolors = common.get_brain_region_colors(ylabels);    
        for i=1:numel(ylabels)
            if all(~isnan(ycolors(i,:)))            
                ax.YTickLabel{i} = sprintf('\\color[rgb]{%f,%f,%f}%s', ycolors(i,:), ylabels{i});
            end
        end 
    end
end