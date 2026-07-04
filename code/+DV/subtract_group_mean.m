function newDV = subtract_group_mean(DV,gidx,varargin)

    
    p=inputParser;
    p.addParameter('exclude_self',false,@(x)validateattributes(x,{'logical'},{'scalar'})); % for each trial t, subtract mean of matching trials excluding trial t?
    p.addParameter('foldid',[]);
    p.parse(varargin{:});
    params=p.Results;
    if ~ismatrix(DV)
        error('l');
    end
    [nt,ntp] = size(DV);
    newDV=NaN([nt ntp]);
    if numel(gidx)~=nt
        error('l');
    end
    if ~ismember('foldid',p.UsingDefaults)
        if numel(params.foldid)~=nt || ~isvector(params.foldid)
            error('foldid must be a vector of same length as gidx.');
        end
        params.foldid=params.foldid(:);
    end
    gidx=double(gidx);
    u=unique(gidx);
    for i=1:nt
        gidx(i,1) = find(u==gidx(i));
    end
    if params.exclude_self
        for i=1:nt
            if isempty(params.foldid)
                match = gidx == gidx(i);
                match(i)=false;
                if ~sum(match)
                    error('Some trials are unmatched.');
                end
                mn = nanmean(DV(match,:));            
                newDV(i,:) = DV(i,:) - mn;
            else
                for f=1:max(params.foldid)            
                    out_match = gidx == gidx(i) & params.foldid~=params.foldid(i);
                    if ~sum(match)
                        error('Some trials are unmatched.');
                    end
                    in_match = gidx == gidx(i) & params.foldid==params.foldid(i);
                    mn = nanmean(DV(in_match,:));            
                    newDV(i,:) = DV(i,:) - mn;
                end
            end
        end
    else  
        for i=1:max(gidx)
            if isempty(params.foldid)
                match = gidx==i;
                if any(match)
                    if sum(match)==1
                        error('Some trials are unmatched.');
                    end
                    mn = nanmean(DV(match,:));
                    newDV(match,:) = bsxfun(@plus,DV(match,:),-mn);
                end                
            else            
                for f=1:max(params.foldid)
                    out_match = gidx==i & params.foldid~=f;
                    if any(out_match)
                        if sum(out_match)==1
                            error('Some trials are unmatched.');
                        end
                        mn = nanmean(DV(out_match,:));
                        in_match = gidx==i & params.foldid==f;                    
                        newDV(in_match,:) = bsxfun(@plus,DV(in_match,:),-mn);
                    end
                end
            end
        end
    end
end