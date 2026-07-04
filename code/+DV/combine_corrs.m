function combined = combine_corrs(corrs,varargin)     
    p=inputParser;
    p.addParameter('min_units',1);
    p.addParameter('regions',common.get_brain_regions());
    p.addParameter('order_by_hemi',false);
    p.parse(varargin{:});
    params=p.Results;

    nsess=numel(corrs);
    params.regions = unique(params.regions,'stable');
    nregions=numel(params.regions);

    if all(cat(1,corrs.hemisphere)=="")
        params.regions = params.regions(:);
        params.hemisphere = repmat("",[1 nregions]);        
    else
        params.regions = repmat(params.regions(:),[2 1]);    
        params.regions = params.regions(:);
        params.hemisphere = repmat(["left" "right"],[nregions 1]);
    end
    params.hemisphere = params.hemisphere(:);
    
    n=max(cat(1,corrs.split));
    params.split = repmat(1:n,[numel(params.hemisphere) 1]);            
    params.split=params.split(:);
    params.regions = repmat(params.regions,[n 1]);
    params.hemisphere = repmat(params.hemisphere,[n 1]);

    if params.order_by_hemi
        [~,idx] = sort(params.hemisphere,'descend');
        params.regions = params.regions(idx);
        params.hemisphere = params.hemisphere(idx);
        params.split = params.split(idx);
    end
        
    corrs=equalize_times(corrs);
    
    param_fields={'time_s'};    
    combined.time_s= corrs(1).time_s;
    combined.lags = corrs(1).lags;
    
    for i=1:nsess
        for f=1:numel(param_fields)
            if ~isequal(combined.time_s,corrs(i).(param_fields{f}))
                error('Not all sessions had corrs calculated with the same value of param %s.',param_fields{f});
            end
        end
        good=corrs(i).n_units>=params.min_units;
        if any(~good)
            corrs(i) = reindex_corrs(corrs(i),good);    
            corrs(i).se = reindex_corrs(corrs(i).se,good);
        end
        [idx_combined,idx_orig] = ismember(strcat(params.regions,params.hemisphere,string(params.split)), strcat(corrs(i).regions(:),corrs(i).hemisphere(:),string(corrs(i).split)));
        corrs(i).is_missing = ~idx_combined;        
        idx_orig = idx_orig(~corrs(i).is_missing);
        corrs(i) = reindex_corrs(corrs(i),idx_orig,idx_combined);
        corrs(i).se = reindex_corrs(corrs(i).se,idx_orig,idx_combined);        
    end
    
    % ok so now all indices are the same and are in the desired order
    
    combined.regions = params.regions;
    combined.hemisphere = params.hemisphere;
    combined.split = params.split;
    combined.sess_date = [corrs.sess_date]';
    combined.sessid = [corrs.sessid]';
    combined.rat = [corrs.rat]';
    combined.n_units = cat(2,corrs.n_units);
    
    fields = fieldnames(corrs(1).se);
    se=[corrs.se];
    for f=1:numel(fields)
        d=ndims(corrs(1).(fields{f}))+1;
        [combined.(fields{f}),combined.se.(fields{f})] = DV.average_corrs(cat(d,corrs.(fields{f})),cat(d,se.(fields{f})),d);
    end
      
   
end

function corrs = equalize_times(corrs)
    times = corrs(1).time_s;
    for i=2:numel(corrs)
        times = intersect(times,corrs(i).time_s);
    end
    for i=1:numel(corrs)
        corrs(i) = DV.select_times_from_corrs(corrs(i),times);
    end
end

function out = reindex_corrs(corrs,idx_in,idx_out)
    % idx_in gives indices in original array to keep
    % idx_out gives indices in new array to assign them to
    % assumes that the regions dimensions are the leading one (if a vector)
    % or two (if matrix or ndarray)
    if nargin<3
        idx_out = true(numel(find(idx_in)),1);
    end
    if numel(find(idx_in))~=numel(find(idx_out))
        error('number of idx_in and idx_out indices must match.');
    end    
    out=corrs;
    fields = fieldnames(corrs);
    for f=1:numel(fields)
        val = corrs.(fields{f});       
        sz=size(val,1:4);
        if sz(1)==numel(idx_in)
            if isvector(val) || contains(fields{f},"std")
                if isstring(val)
                    out.(fields{f}) = repmat(string(missing),[numel(idx_out),sz(2)]);
                else
                    out.(fields{f}) = NaN(numel(idx_out),sz(2));
                end
                out.(fields{f})(idx_out,:) = val(idx_in,:);
            else
                out.(fields{f}) = NaN([numel(idx_out),numel(idx_out),sz(3),sz(4)]);                
                out.(fields{f})(idx_out,idx_out,:,:) = val(idx_in,idx_in,:,:);
            end
        end
    end
end
