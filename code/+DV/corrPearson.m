function [coef,zalpha,pval] = corrPearson(x,y,alpha)
%CORRPEARSON Computation of Pearson correlation matrix
%
%   [COEF,RLO, RHI,PVAL] = CORRPEARSON(X,Y,ALPHA) calculates the Pearson
%   cross-correlation matrix COEF. ROWS are treated in a pairwise fashion,
%   with NaN removal. TAIL is automatically 'both'.

%  This is a modified version of internal.stats.corrsPearson that removes
%  some features we do not need and adds computation of confidence
%  intervals.
%
%  AGB 2024

if nargin<3
    alpha=0.3173; % 1 s.e.
end
[n,p1] = size(x);
p2 = size(y,2);

% Do column-pairwise NaN removal only if there are missing values.
isnanX = isnan(x);
isnanY = isnan(y);

% Computation of linear correlation with column-pairwise NaN removal
% Preallocate the outputs.
coef = zeros(p1,p2);
nij = zeros(p1,p2);
for i = 1:p1
    xi = x(:,i);
    isnanXi = isnanX(:,i);

    % Loop over all columns of y for corr(x,y), or over the lower triangle
    % without the diagonal for corr(x).
    for j = 1:p2
        yj = y(:,j);
        ok = ~(isnanXi | isnanY(:,j));
        nij(i,j) = sum(ok);
        if nij(i,j) < n
            x0 = xi(ok); x0 = x0 - sum(x0)/nij(i,j);
            y0 = yj(ok); y0 = y0 - sum(y0)/nij(i,j);
        else
            x0 = xi - sum(xi)/n;
            y0 = yj - sum(yj)/n;
        end
        coef(i,j) = (x0'*y0) ./ (norm(x0) .* norm(y0));
    end
end
    

n = nij;
% Limit off-diag elements to [-1,1], and put exact ones on the diagonal for
% autocorrelation.
t = find(abs(coef) > 1); coef(t) = coef(t)./abs(coef(t)); % preserves NaNs

if nargout > 1
    zalpha = ciPearson(n,alpha);    
    if nargout>3
        pval = pvalPearson(coef, n);        
    end
end
end

%--------------------------------------------------------------------------

function p = pvalPearson(rho, n)
%PVALPEARSON Tail probability for Pearson's linear correlation.
t = rho.*sqrt((n-2)./(1-rho.^2)); % +/- Inf where rho == 1
p = 2*tcdf(-abs(t),n-2);
end

function zalpha = ciPearson(n, alpha)
%CIs for Pearson's linear correlation.
zalpha = NaN(size(n));
zalpha(n>3) = (-erfinv(alpha - 1)) .* sqrt(2) ./ sqrt(n(n>3)-3);
end