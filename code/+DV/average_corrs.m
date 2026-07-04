function [rho,se] = average_corrs(rho,se,dim,options)

    arguments
       rho {mustBeNumeric,mustBeNonempty}
       se {mustBeNumeric,mustBeNonempty}
       dim (1,1) {mustBeNumeric}
       options.weighted (1,1) logical = false
       options.z_cutoff = 4
    end
    
    sz=size(rho);
    if any(sz~=size(se))
        error('rho and se must have the same dimensions.');
    end
    if sz(dim)<2
       warning('Inputs are scalar along selected dimension. No averaging needed.');
       return
    end
     
    if isfinite(options.z_cutoff)
        z = (se - mean(se,'all','omitnan')) ./ std(se,0,'all','omitnan');
        rho(z>options.z_cutoff)=NaN;
    end

    se(isnan(rho))=NaN;
    if options.weighted
        w = 1./(se.^2); % weights are inversely proportional to error variance        
    else
       
        w=ones(size(se));        
    end
    w =  w./nansum(w,dim);
    rho = wmean(rho,w,dim);        
    %rho=nanmedian(rho,dim);
    se = sqrt(nansum((se.*w).^2,dim));
end

function y = wmean(x,w,dim)
    % weighted mean
    % by default, operates along the first non-scalar dimension.
    % NaN weights are treated like zeros
    % no singleton expansion. should add that.
    sz=size(x);
    if any(size(w)~=sz)
        error('wMean:sizeMismatch','x and w must be the same size');
    end      
    if any(isinf(w))
        error('Weights cannot be Inf.');
    end
    w(isnan(x))=NaN;
    w(w==0)=NaN;
    if nargin<3
        if max(sz)==1
            dim=1;
        else
            ndims=length(sz);
            for j=1:ndims
                if sz(j)>1
                    dim=j;
                    break
                end
            end
        end
    end           
    xw = x.*w;
    wsum = nansum(xw,dim);
    y = wsum ./ nansum(w,dim);
end