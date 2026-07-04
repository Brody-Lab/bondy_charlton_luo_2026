function [Fit, varargout] = fit_logistic3(Y, X, varargin)
%{
Fit an extended logistic regression model with a parameter for lapse rates.

For each sample, the probability of the dependent variable `y` (0 or 1) given the independent
variable `x` is

    p(y==1 | x) = gamma + (1-gamma)*logistic(w*x + b)

ARGUMENT
`Y`: dependent variable, should be either 0 or 1
`X`: independent variable

RETURN

OPTIONAL ARGUMENT
`lower_bound`: a three-element array
`upper_bound`: a three-element array
%}

    X = X(:);
    Y = Y(:);
    P = inputParser;
    addParameter(P, 'lower_bound', [0,  0, min(X)], @isnumeric) % lapse [0,1], sensitivity [0 5], bias [min(X), max(X)]
    addParameter(P, 'upper_bound', [0.5, 5, max(X)], @isnumeric)
    addParameter(P, 'initial_values',[0.05, 0.5, 0], @(x) isnumeric(x))% a bit of lapse, mediocre sensitivity, no bias 
    parse(P, varargin{:});
    P = P.Results;
    X_unique = unique(X);
    n_X_unique = numel(X_unique);
    K = nan(n_X_unique,1);
    N = nan(n_X_unique,1);
    for c = 1:n_X_unique
        idx = X_unique(c) == X;
        K(c,1) = sum(Y(idx)); 
        N(c,1) = sum(idx);
    end
    warning('off', 'MATLAB:nchoosek:LargeCoefficient')
    % ***************** %
    %       Fmincon     %
    % ***************** %
    nLL0 = PBups.negLogLike_logistic3(P.initial_values, N, K, X_unique);
    if isinf(nLL0) || isnan(nLL0)
        error('Failure to evaluate initial values')
    end

    [x_fmin, f_fmin, exitflag, output, ~, grad, hessian] = ...
        fmincon(@(param) PBups.negLogLike_logistic3(param, N, K, X_unique), ...
                P.initial_values, ...
                [], [], [], [], ...
                P.lower_bound, P.upper_bound, ...
                @boundcon, ...
                optimset('DiffMinChange', 0.0001, ...
                         'MaxIter', 200, ...
                         'Algorithm', 'interior-point', ...
                         'Display', 'off')     );
    Fit = struct;
    Fit.gamma = x_fmin(1);
    Fit.sens   = x_fmin(2);
    Fit.bias   = x_fmin(3);

    est_var = diag(inv(hessian)); % estimated variance
    est_var(est_var < 0) = NaN; % hessian matrix not positive semidefinite
    est_std = est_var.^0.5;

    Fit.std.gamma = est_std(1);
    Fit.std.sens = est_std(2);
    Fit.std.bias = est_std(3);
    
    % 95% confidence interval
    tcv = tinv(0.975, numel(Y)-2); % T critical value
    Fit.error95.gamma = Fit.std.gamma * tcv;
    Fit.error95.sens = Fit.std.sens * tcv;
    Fit.error95.bias = Fit.std.bias * tcv;

    % *** vargout ***
    varargout{1} = f_fmin;
    varargout{2} = exitflag;
    varargout{3} = output;
    varargout{4} = grad;
    varargout{5} = hessian;
end

function [c,ceq] = boundcon(x)
    c(1) = x(1) + x(2) - 1; % gamm0 + gamm1  <= 1
    c(2) = -(x(1) + x(2));  % gamm0 + gamm1 >= 0
    ceq = [];
end