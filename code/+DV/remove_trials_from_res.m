function res = remove_trials_from_res(res,remove)  
    if ~any(remove)
        return
    end
    if isscalar(res)
        fields=fieldnames(res);
        for f=1:numel(fields)
            if size(res.(fields{f}),1)==numel(remove)
                res.(fields{f}) = res.(fields{f})(~remove,:);
            end
        end
        if isfield(res,'Trials')
            res.Trials = common.remove_trials(res.Trials,remove);
        end
    else
        for i=1:numel(res)
            res(i) = DV.remove_trials_from_res(res(i),remove); 
        end
    end
end