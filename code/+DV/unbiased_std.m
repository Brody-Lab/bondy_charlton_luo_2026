function [std,std_se] = unbiased_std(X,dim)
    % unbiased estimator of the standard deviation, assuming normality.
    % the sample standard deviation is really biased for small sample
    % sizes!

    % see
    % https://en.wikipedia.org/wiki/Unbiased_estimation_of_standard_deviation
    % for discussion of calculation applied here.
    
    if nargin<2
        dim=1;
    end
    n = sum(~isnan(X),dim);
    c = std_correction_factor(n);
    sample_std = nanstd(X,0,dim);
    std = sample_std./c;
    std_se = sample_std .* sqrt(c.^-2 - 1);
end

function c = std_correction_factor(n)
    if ~all(n>=0) || any(isinf(n))
        error('n must be finite and nonnegative.');
    end
    zeros=n==0;
    c=NaN(size(n));
    c(~zeros) = sqrt(2./(n(~zeros)-1)) .* exp(gammaln(n(~zeros)./2) - gammaln((n(~zeros)-1)/2));
end