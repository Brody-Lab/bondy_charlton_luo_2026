function h=plot_corr_timecourse(corrs,varargin)

    p=inputParser;
    p.KeepUnmatched=true;
    p.addParameter('field','corrected_timecourse',@(x)validateattributes(x,{'string','char'},{'nonempty'}));
    p.addParameter('regions',common.get_brain_regions(),@(x)validateattributes(x,{'string','char'},{'nonempty'})); 
    p.addParameter('new_fig',true,@(x)validateattributes(x,{'logical'},{'scalar'}));       
    p.addParameter('hemispheres',["left","right",""]);
    p.addParameter('color',[0 0 0],@(x)validateattributes(x,{'numeric'},{'numel',3,'<=',1,'>=',0}));
    p.parse(varargin{:});
    params = p.Results;

    if ~isfield(corrs,params.field)
        error('%s is not a field of corrs structure.',params.field);
    end
    
    ntimepoints = numel(corrs.time_s);
    
    idx = ismember(corrs.regions,params.regions) & ismember(corrs.hemisphere,params.hemispheres);
    for t=1:ntimepoints
        tmp = common.SetDiag(corrs.(params.field)(idx,idx,t),NaN);
        tmp_se = common.SetDiag(corrs.se.(params.field)(idx,idx,t),NaN);
        data(:,t)=tmp(:);
        data_se(:,t)=tmp_se(:);
    end
        
    [data,data_se] = DV.average_corrs(data,data_se,1,"weighted",true);
    if params.new_fig
        figure('units','pixels','position',[869   715   589   400]);
    else
        hold on;
    end
    h=common.shadedErrorBar(corrs(1).time_s,data,data_se,{'color',params.color});
    xlabel('Time (s)');
    ylabel('DV corr.');
    set(gca,'tickdir','out');box off; 
end   