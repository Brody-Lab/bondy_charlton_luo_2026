function [accuracy,bal_accuracy,dp,accuracy_se,balanced_accuracy_se,dp_se] = calculate_class_accuracy(Y,Y_hat,grp_idx)
    Y=round(Y);
    logit = @(p)log(p./(1-p));
    logp = logit(Y_hat);    
    Y_hat=round(Y_hat);
    if isempty(grp_idx)
        nans = isnan(Y_hat) | isnan(Y);
    else
        nans = isnan(Y_hat) | isnan(Y) | isnan(grp_idx);
        grp_idx = grp_idx(~nans);        
    end
    Y=Y(~nans);
    Y_hat=Y_hat(~nans);
    logp=logp(~nans);
    accuracy_fun=@(x,y)fastmean(x(:)==y(:));
    accuracy = accuracy_fun(Y,Y_hat);
    alphas = normcdf([-1 1])*100;
    bal_accuracy = balanced_accuracy(Y,Y_hat,grp_idx);

    dp = dprime(logp(Y==0),logp(Y==1));
    if numel(Y)>1 && nargout>2
        nobs=numel(Y);
        nboot=1e2;

        for i=nboot:-1:1
            idx = randi(nobs,nobs,true);
            boot(i) = accuracy_fun(Y(idx,:),Y_hat(idx,:));
        end
        accuracy_se = prctile(boot,alphas);

        for i=nboot:-1:1
            idx = randi(nobs,nobs,true);
            boot(i) = dprime(logp(intersect(find(Y==0),idx)),logp( intersect(find(Y==1),idx)));
        end
        dp_se = std(boot);        

        if isempty(grp_idx)


            for i=nboot:-1:1
                idx = randi(nobs,nobs,true);
                boot(i) = balanced_accuracy(Y(idx,:),Y_hat(idx,:));
            end
            balanced_accuracy_se = prctile(boot,alphas);
        else
            for i=nboot:-1:1
                idx = randi(nobs,nobs,true);
                boot(i) = balanced_accuracy(Y(idx,:),Y_hat(idx,:),grp_idx(idx,:));
            end
            balanced_accuracy_se = prctile(boot,alphas);
        end
    else
        accuracy_se=[NaN NaN];
        balanced_accuracy_se=[NaN NaN];
    end
end

function acc = balanced_accuracy(x,y,grp_idx)
    up = x==1;
    nup=sum(up);
    ndown=sum(~up);
    if nargin<3 || isempty(grp_idx)
        acc = (sum(y(up))./nup  +  1-sum(y(~up))./ndown )./2;
    else
        for i=max(grp_idx):-1:1
            idx = grp_idx==i;
            acc(i) = ( fastmean(y(up&idx)) + 1-fastmean(y(~up&idx)) ) ./ 2;
        end
        acc=sum(acc)./numel(acc);
    end     
end

function mn= fastmean(x)
    mn = sum(x)./numel(x);
end

function d = dprime(a,b)
    % allows nans and performs singleton expansion. treats rows as
    % observations in the two distributions, and columns as separate comparisons (e.g. timepoints). size of d is number of columns of
    % a and b
    % positive d-prime if mean(b)>mean(a)
    
    d = ( fastmean(b) - fastmean(a) ) ./ ( sqrt ( var(b) + var(a) ) / 2 ) ;
end