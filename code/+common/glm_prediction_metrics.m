function metrics = glm_prediction_metrics(Y,Y_hat,varargin)
    p=inputParser;
    p.addRequired('Y',@(x)validateattributes(x,{'numeric','logical'},{'ndims',2,'nonempty'}));
    p.addRequired('Y_hat',@(x)validateattributes(x,{'numeric','logical'},{'ndims',2,'nonempty'}));
    p.addParameter('Y_hat_null',[],@(x)validateattributes(x,{'numeric','logical'},{'ndims',2,'nonempty'}));     
    p.addParameter('group_idx',[],@(x)validateattributes(x,{'numeric'},{'vector'}));
    p.addParameter('bin_size_s',[],@(x)validateattributes(x,{'numeric'},{'positive','scalar'}));   % time duration of each sample, in case you want metrics per unit time
    p.addParameter('family','gaussian',@(x)validateattributes(x,{'char','string'},{'nonempty'}));    
    p.addParameter('fast',false);
    p.parse(Y,Y_hat,varargin{:});
    params = p.Results;
        
    [nobs,ncol] = size(Y); % ncol is number of response variables
    [nobs_hat,ncol_hat] = size(Y_hat);
    [nobs_grp,ncol_grp] = size(params.group_idx);
    if nobs_hat~=nobs || ncol~=ncol_hat
        error('Y and Y_hat must be of the same size.');
    end
    if ~ismember('Y_hat_null',p.UsingDefaults)
        has_null=true;
        if numel(params.Y_hat_null)==ncol
            params.Y_hat_null = repmat(params.Y_hat_null(:)',nobs,1);
        end
        [nobs_hat_null,ncol_hat_null] = size(params.Y_hat_null);                
        if nobs_hat_null~=nobs || ncol_hat_null~=ncol
            error('Y_hat_null must be of the same size as Y and Y_hat.');
        end        
    else
        has_null=false;
    end
    if nobs_grp
        if nobs_grp~=nobs
            error('group_idx must have same number of observations as Y.')
        end
    end
    if has_null
        nans = any(isnan(Y),2) | any(isnan(Y_hat),2) | any(isnan(params.Y_hat_null),2);
        Y_hat_null = params.Y_hat_null(~nans,:);        
    else
        nans = any(isnan(Y),2) | any(isnan(Y_hat),2) ;        
    end
    Y = Y(~nans,:);
    Y_hat = Y_hat(~nans,:);
    if nobs_grp
        grp_idx = params.group_idx(~nans);
        if any(isnan(grp_idx))
            error('group_idx cannot have NaNs where data does not.')
        end
    else
        grp_idx=[];
    end
    metrics.nobs = sum(~nans);
    
    
    nspks=sum(Y,'all');        
    
    switch params.family
        case 'poisson'
            logprobfun = @(y,yhat)poisslogpdf(y,yhat);
            ll_sat = sum(logprobfun(Y,Y),2);% summed across response variables            
        case {'gaussian','normal'}
            % note: this line needs further consideration (should be
            % changed so that sigma (or sigma^2) is a cross-validated
            % estimator like beta used to generate y_hat. supplied as a
            % vector of same length as yhat where all values are
            % out-o-fsample predictions.
            logprobfun = @(y,yhat)log(normpdf(y,yhat,sqrt(mean((y-yhat).^2)))); % use average squared error as estimate of sigma^2. but really i should be using a cross-validated estimate of sigma^2 (i.e. evaluating ll on test data using estimate of B and sigma from training data). requires knowingset of cross-validated sigmas.
            ll_sat = 0;%sum(log(normpdf(Y,Y,sqrt(mean((Y-Y_hat).^2)))),2);% summed across response variables            
        case 'binomial'
            logprobfun = @(y,yhat)log(binopdf(y,1,yhat));
            ll_sat = sum(logprobfun(Y,Y),2);% summed across response variables            
        otherwise
            error('LL function for this distribution has not been included yet.');
    end
            
    total_secs = metrics.nobs * params.bin_size_s;
    r2fun=@(se,st)1-sum(se,'all')/sum(st,'all'); % R^2 calculated in most standard way (1-SSE/SST)    
    
    ll = sum(logprobfun(Y,Y_hat),2); % summed across response variables
    se=(Y-Y_hat).^2;
    st=(Y-mean(Y)).^2;      
    metrics.ll_tot=sum(ll);    % summed across time and cells
    metrics.ll_sat_tot=sum(ll_sat);    % summed across time and cells  
    metrics.R2 = r2fun(se,st);    
    metrics.deviance = 2*(metrics.ll_sat_tot - metrics.ll_tot) / metrics.nobs;
    metrics.se.deviance =  std(2*(ll_sat-ll))./sqrt(metrics.nobs); % se of total deviance, per timepoint 

    if params.fast
        return
    end

    if numel(Y)>1
        [r,~,rl,ru] = corrcoef(Y,Y_hat,'Alpha',(1-normcdf(1))*2);
        metrics.r=r(2);
        metrics.se.r = [rl(2),ru(2)];
        for i=1e2:-1:1
            idx = randi(metrics.nobs,metrics.nobs,true);
            boot(i) = r2fun(se(idx,:),st(idx,:));
        end
        metrics.se.R2=std(boot);
    else
        metrics.r=NaN;
        metrics.se.r=[NaN NaN];
        metrics.se.R2=NaN;
    end

    
    %% 2-class classification scores
    if params.family=="binomial"
        [metrics.accuracy,metrics.balanced_accuracy,metrics.dprime,metrics.se.accuracy,metrics.se.balanced_accuracy,metrics.se.dprime] = calculate_class_accuracy(Y,Y_hat,grp_idx);
    end    

    %% if null model predictions have been provided
    if has_null
        ll_null = sum(logprobfun(Y,Y_hat_null),2); % summed across response variables        
        metrics.ll_null_tot=sum(ll_null);    % summed across time and cells
        metrics.null_deviance = 2*(metrics.ll_sat_tot - metrics.ll_null_tot) / metrics.nobs;
        metrics.se.null_deviance =  std(2*(ll_sat-ll_null))./sqrt(metrics.nobs);  
        metrics.se.ll_null_tot = std(ll_null)./sqrt(metrics.nobs);
        metrics.se.ll_tot = std(ll)./sqrt(metrics.nobs);
        metrics.se.ll_sat_tot = std(ll_sat)./sqrt(metrics.nobs);        
        metrics.pseudo_R2 = (metrics.ll_tot-metrics.ll_null_tot)./(metrics.ll_sat_tot-metrics.ll_null_tot); % LL based metric that scales linearly between LL_null (0) and LL_sat (1)        
        metrics.se.pseudo_R2 = std((ll-ll_null)./(ll_sat-ll_null))./sqrt(metrics.nobs);     
        % calculate extra nats per timepoint (i.e. proposed - null LL per timepoints) and derived quantities    
        metrics.nats_per_obs = (metrics.ll_tot - metrics.ll_null_tot) ./ metrics.nobs;
        metrics.bits_per_obs = metrics.nats_per_obs/log(2);   
        metrics.se.nats_per_obs = std(ll-ll_null)./sqrt(metrics.nobs); % this should be divided by sqrt(nobs), regardless of how many fids you do (i.e. repeated cv), since you don't want this number sensitive to number of cv iterations            
        metrics.se.bits_per_obs = metrics.se.nats_per_obs/log(2);
        if strcmp(params.family,'poisson')
            metrics.nats_per_spk = metrics.nobs .* metrics.nats_per_obs ./ nspks;        
            metrics.bits_per_spk = metrics.nobs .* metrics.bits_per_obs ./ nspks;        
            metrics.se.nats_per_spk = metrics.nobs .* metrics.se.nats_per_obs ./ nspks;
            metrics.se.bits_per_spk = metrics.nobs .* metrics.se.bits_per_obs ./ nspks;
        end
        if ~isempty(total_secs)
            metrics.nats_per_s = metrics.nobs .* metrics.nats_per_obs ./ total_secs;    
            metrics.bits_per_s = metrics.nobs .* metrics.bits_per_obs ./ total_secs;  
            metrics.se.nats_per_s = metrics.nobs .* metrics.se.nats_per_obs ./ total_secs;                
            metrics.se.bits_per_s = metrics.nobs .* metrics.se.bits_per_obs ./ total_secs;               
        end
    end      
end

function pci=statbinoci(x,n,alpha)
    %STATBINOCI Confidence interval for binomial p parameter.

    %   Copyright 2008 The MathWorks, Inc.


    % Lower limits
    nu1 = 2*x;
    nu2 = 2*(n-x+1);
    F   = finv(alpha/2,nu1,nu2);
    lb  = (nu1.*F)./(nu2 + nu1.*F);

    % Fix NaNs caused by x=0
    xeq0 = find(x == 0);
    if ~isempty(xeq0)
        lb(xeq0) = 0;
    end

    % Upper limits
    nu1 = 2*(x+1);
    nu2 = 2*(n-x);
    F   = finv(1-alpha/2,nu1,nu2);
    ub = (nu1.*F)./(nu2 + nu1.*F);

    % Fix NaNs caused by x=n
    xeqn = find(x == n);
    if ~isempty(xeqn)
        ub(xeqn) = 1;
    end

    pci = [lb(:) ub(:)];
end

function y = poisslogpdf(x,lambda)
    % based on matlab builtin poisspdf
    if nargin <  2,
        error(message('stats:poisspdf:TooFewInputs')); 
    end

    [errorcode, x, lambda] = distchck(2,x,lambda);

    if errorcode > 0
        error(message('stats:poisspdf:InputSizeMismatch'));
    end

    y = zeros(size(x),'like',internal.stats.dominantType(x,lambda)); % Single if x or lambda is

    if ~isfloat(x)
       x = double(x);
    end

    y(lambda < 0) = NaN;
    y(isnan(x) | isnan(lambda)) = NaN;
    y(x==0 & lambda==0) = 0;
    k = find(x >= 0 & x == round(x) & lambda > 0);
    if ~isempty(k)
        x = x(k);
        lambda = lambda(k);

        smallx = x<=lambda*realmin;
        y(k(smallx)) = -lambda(smallx);

        largex = lambda<x*realmin;
        y(k(largex)) = -lambda(largex) + x(largex).*log(lambda(largex)) ...
            - gammaln(x(largex)+1);

        other = ~smallx & ~largex;
        lnsr2pi = 0.9189385332046727; % log(sqrt(2*pi))
        y(k(other)) = -lnsr2pi -0.5*log(x(other)) - stirlerr(x(other)) ...
            - binodeviance(x(other),lambda(other));
    end
end

function delta = stirlerr(n)
%STIRLERR Error of Stirling-De Moivre approximation to n factorial.
%    DELTA=STIRLERR(N) computes
%        gammaln(n+1) - (0.5*log(2*pi*n)+n*log(n)-n)
%    This function is used in C. Loader, "Fast and Accurate Calculations of
%    Binomial Probabilities", July 9, 2000, to compute binomial and Poisson
%    probabilities.
%
%    DELTA is approximated as
%        delta(n) = 1/(12*n) - 1/(360*n^3) + 1/(1260*n^5) + O(1/n^7)
%    For small values of "n", the pre-calculated values for delta(n) are
%    used.

%   Copyright 2010 The MathWorks, Inc.


delta = zeros(size(n),'like',n);
nn = n.*n;

% Define S0=1/12 S1=1/360 S2=1/1260 S3=1/1680 S4=1/1188
S0 = 8.333333333333333e-02;
S1 = 2.777777777777778e-03;
S2 = 7.936507936507937e-04;
S3 = 5.952380952380952e-04;
S4 = 8.417508417508418e-04;

% Define delta(n) for n<0:0.5:15
sfe=[                    0;...
     1.534264097200273e-01;...
     8.106146679532726e-02;...
     5.481412105191765e-02;...
     4.134069595540929e-02;... 
     3.316287351993629e-02;...
     2.767792568499834e-02;...
     2.374616365629750e-02;...
     2.079067210376509e-02;...
     1.848845053267319e-02;...
     1.664469118982119e-02;...
     1.513497322191738e-02;...
     1.387612882307075e-02;...
     1.281046524292023e-02;...
     1.189670994589177e-02;...
     1.110455975820868e-02;...
     1.041126526197210e-02;...
     9.799416126158803e-03;...
     9.255462182712733e-03;...
     8.768700134139385e-03;...
     8.330563433362871e-03;...
     7.934114564314021e-03;...
     7.573675487951841e-03;...
     7.244554301320383e-03;...
     6.942840107209530e-03;...
     6.665247032707682e-03;...
     6.408994188004207e-03;...
     6.171712263039458e-03;...
     5.951370112758848e-03;...
     5.746216513010116e-03;...
     5.554733551962801e-03];

k = find(n<=15);
if any(k)
    n1 = n(k);
    n2 = 2*n1;
    if all(n2==round(n2))
        delta(k) = sfe(n2+1);
    else
        lnsr2pi = 0.9189385332046728;
        delta(k) = gammaln(n1+1)-(n1+0.5).*log(n1)+n1-lnsr2pi;
    end
end
k = find(n>15 & n<=35);
if any(k)
    delta(k) = (S0-(S1-(S2-(S3-S4./nn(k))./nn(k))./nn(k))./nn(k))./n(k);
end
k = find(n>35 & n<=80);
if any(k)
    delta(k) = (S0-(S1-(S2-S3./nn(k))./nn(k))./nn(k))./n(k);
end
k = find(n>80 & n<=500);
if any(k)
    delta(k) = (S0-(S1-S2./nn(k))./nn(k))./n(k);
end
k = find(n>500);
if any(k)
    delta(k) = (S0-S1./nn(k))./n(k);
end

end

function bd0 = binodeviance(x,np)
%BINODEVIANCE Deviance term for binomial and Poisson probability calculation.
%    BD0=BINODEVIANCE(X,NP) calculates the deviance as defined in equation
%    5.2 in C. Loader, "Fast and Accurate Calculations of Binomial
%    Probabilities", July 9, 2000. X and NP must be of the same size.
%
%    For "x/np" not close to 1:
%        bd0(x,np) = np*f(x/np) where f(e)=e*log(e)+1-e
%    For "x/np" close to 1: 
%         The function is calculated using the formula in Equation 5.2. 

%   Copyright 2010-2014 The MathWorks, Inc.


bd0=zeros(size(x),'like',internal.stats.dominantType(x,np));

% If "x/np" is close to 1:
k = abs(x-np)<0.1*(x+np);
if any(k(:))
    s = (x(k)-np(k)).*(x(k)-np(k))./(x(k)+np(k));
    v = (x(k)-np(k))./(x(k)+np(k));
    ej = 2.*x(k).*v;
    s1 = zeros(size(s),'like',s);
    ok = true(size(s));
    j = 0;
    while any(ok(:))
        ej(ok) = ej(ok).*v(ok).*v(ok);
        j = j+1;
        s1(ok) = s(ok) + ej(ok)./(2*j+1);
        ok = ok & s1~=s;
        s(ok) = s1(ok);
    end
    bd0(k) = s;
end

% If "x/np" is not close to 1:
k = ~k;
if any(k(:))
    bd0(k)= x(k).*log(x(k)./np(k))+np(k)-x(k);
end

end

