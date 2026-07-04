function metrics = combine_metrics(res,R,H)
    p=inputParser;
    % takes a cell array of res structs (where each elements of the cell
    % array is a session) and recalculates prediction metrics across all
    % combined trials
    if iscell(res)
        res=cat(2,res{:});
    end
    % if numel(unique([res.family]))>1
    %     error('Input appears to contain a mix of model distributions.')
    % else
    %     family=res(1).family;
    % end
    family='binomial';
    if nargin>1
        region = cat(1,res.region);
        if nargin>2
            hemisphere = cat(1,res.hemisphere);
            idx= ismember(region,R(:)) & ismember(hemisphere,H(:));
        else
            idx= ismember(region,R(:));
        end
    else
        idx = true(size(res));
    end
    n = arrayfun(@(x)size(x.Y,1),res(idx));
    for i=numel(n):-1:1
        group_idx(1:sum(n(1:i)),1)=i;
    end
    Y = cat(1,res(idx).Y);
    logistic= @(x) (1./(1+exp(-x)));
    %Y_hat = logistic(cat(1,res(idx).eta_same_lambda)); %% using samelambda here fyi, to match dvs
    Y_hat = cat(1,res(idx).Y_hat);
    Y_hat_null = cat(1,res(idx).Y_hat_null);
    if ~isfield(res,'family')
        res(1).family='binomial';
    end
    for i = 1:size(Y_hat,2)
        if size(Y,2)>1
            metrics(i) = glm_prediction_metrics(Y(:,i),Y_hat(:,i),'Y_hat_null',Y_hat_null(:,i),'family',res(1).family,'group_idx',group_idx);            
        else
            metrics(i) = glm_prediction_metrics(Y,Y_hat(:,i),'Y_hat_null',Y_hat_null(:,i),'family',res(1).family,'group_idx',group_idx);
        end
    end
end