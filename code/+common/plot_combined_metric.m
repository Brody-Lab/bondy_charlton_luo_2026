function [h,nobs]=plot_combined_metric(res,metric,regions,hemispheres,color,time_lim_s)
    if iscell(res)
        for i=1:numel(res)
            if iscell(res{i}) && isscalar(res{i})
                res{i} = res{i}{1};
            end
        end
        res=[res{:}];
    end
    if nargin<6
        time_lim_s = [-Inf Inf];
        if nargin<5
            color=[0 0 0];
            if nargin<4 || isempty(hemispheres)
                hemispheres=["right" "left" ""];
                if nargin<3 || isempty(regions)
                    regions=common.get_brain_regions();
                end        
            end
        end
    end
    metrics=common.combine_metrics(res,regions,hemispheres);
    se=[metrics.se];
    switch metric
        case {'accuracy','balanced_accuracy','r'}
            err = abs(cat(1,se.(metric))'-[metrics.(metric)]);     
        otherwise
            err=[se.(metric)];      
    end
    idx = res(1).bin_params.time_s>=time_lim_s(1) & res(1).bin_params.time_s<=time_lim_s(2);
    data=[metrics.(metric)];
    h=common.shadedErrorBar(res(1).bin_params.time_s(idx),data(idx),err(:,idx),{'color',color,'LineWidth',2});         
end