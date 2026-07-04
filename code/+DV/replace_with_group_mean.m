function newDV = replace_with_group_mean(DV,gidx,varargin)
    % res should be scalar
    % passes varargs, like "seed" and "nresamples" and "min_trials" to find_matched_trials
    % output does not include missing trials (trials that could not be
    % matched). but second output gives indices into original data that
    % were excluded.
    
    p=inputParser;
    p.addParameter('exclude_self',false,@(x)validateattributes(x,{'logical'},{'scalar'})); % for each trial t, subtract mean of matching trials excluding trial t?
    p.parse(varargin{:});
    params=p.Results;
    [nt,ntp] = size(DV);
    newDV=NaN([nt ntp]);
    if params.exclude_self
        for i=1:nt
            match = gidx == gidx(i);
            match(i)=false;
            if ~sum(match)
                error('Some trials are unmatched.');
            end
            mn = nanmean(DV(match,:));            
            newDV(i,:) = mn;
        end
    else  
        for i=1:max(gidx)
            match = gidx==i;
            if any(match)
                if sum(match)==1
                    error('Some trials are unmatched.');
                end
                mn = nanmean(DV(match,:));
                newDV(match,:) = bsxfun(@plus,zeros(size(DV(match,:))),mn);
            end
        end
    end
end