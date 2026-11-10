classdef CumulativeNormal
% CumulativeNormal  4-parameter cumulative-normal sigmoid, fit via MATLAB's
%                   built-in `fit` function (Curve Fitting Toolbox).
%
%   f(x) = scale * normcdf(x, mu, sigma) + offset
%
%   Same model as CumulativeGaussian, but the fitting is delegated to
%   MATLAB's built-in `fit` (Curve Fitting Toolbox) with a custom
%   `fittype`. No custom objective function, no variable projection, no
%   multi-start -- just a single call to `fit` from a data-driven start.
%
%   The point of this class is to be a thin sanity-check baseline: how
%   does the off-the-shelf MATLAB nonlinear LS fit behave on this problem?
%
%   Parameters:
%     mu     - centre / inflection
%     sigma  - width (> 0)
%     scale  - amplitude  (sign unconstrained)
%     offset - lower-asymptote value (limit as x -> -inf)
%
%   Usage:
%     cn = CumulativeNormal.fit(x, y);
%     cn = CumulativeNormal.fit(x, y, 'mu0', 0, 'sigma0', 0.1, ...
%                                     'scale0', -0.1, 'offset0', 0.05);

    properties
        mu     (1,1) double = 0
        sigma  (1,1) double = 1
        scale  (1,1) double = 1
        offset (1,1) double = 0
    end

    % ------------------------------------------------------------------
    methods

        function obj = CumulativeNormal(mu, sigma, scale, offset)
        % Constructor.  All arguments optional; defaults: mu=0, sigma=1,
        % scale=1, offset=0.
            if nargin >= 1, obj.mu     = mu;     end
            if nargin >= 2, obj.sigma  = sigma;  end
            if nargin >= 3, obj.scale  = scale;  end
            if nargin >= 4, obj.offset = offset; end
        end

        % --------------------------------------------------------------
        function y = evaluate(obj, x)
        % EVALUATE  f(x) = scale * normcdf(x, mu, sigma) + offset
            y = obj.scale .* normcdf(x, obj.mu, obj.sigma) + obj.offset;
        end

        % --------------------------------------------------------------
        function params = asVector(obj)
        % ASVECTOR  Return [mu, sigma, scale, offset].
            params = [obj.mu, obj.sigma, obj.scale, obj.offset];
        end

        % --------------------------------------------------------------
        function disp(obj)
            fprintf('CumulativeNormal\n');
            fprintf('  mu     = %g\n', obj.mu);
            fprintf('  sigma  = %g\n', obj.sigma);
            fprintf('  scale  = %g\n', obj.scale);
            fprintf('  offset = %g\n', obj.offset);
        end

    end   % instance methods

    % ------------------------------------------------------------------
    methods (Static)

        function obj = fit(x, y, varargin)
        % FIT  Fit via MATLAB's built-in `fit` (Curve Fitting Toolbox).
        %
        %   cn = CumulativeNormal.fit(x, y)
        %   cn = CumulativeNormal.fit(x, y, 'mu0', m, 'sigma0', s, ...
        %                                   'scale0', c, 'offset0', o)
        %
        %   Builds a `fittype` for scale*normcdf(x,mu,sigma)+offset and
        %   calls `fit(x, y, ft, opts)`. The starting point is data-driven
        %   unless overridden via the name-value pairs above.
        %
        %   NaNs in x and y are removed before fitting.

            % --- strip NaNs --------------------------------------------
            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid); y = y(valid);

            % --- data-driven default start point -----------------------
            xr          = range(x);
            [~, idx]    = max(abs(diff(y)));
            mu0_data    = (x(idx) + x(idx+1)) / 2;
            sigma0_data = xr / 4;

            % Linear LS for (scale, offset) at the default (mu, sigma)
            % to give the nonlinear solver a sensible initial guess.
            F  = [normcdf(x, mu0_data, sigma0_data), ones(numel(x), 1)];
            ab = F \ y;

            % --- parse overrides ---------------------------------------
            p = inputParser;
            addParameter(p, 'mu0',     mu0_data,    @isnumeric);
            addParameter(p, 'sigma0',  sigma0_data, @isnumeric);
            addParameter(p, 'scale0',  ab(1),       @isnumeric);
            addParameter(p, 'offset0', ab(2),       @isnumeric);
            parse(p, varargin{:});

            % --- build a fittype and call MATLAB's built-in `fit` ------
            ft = fittype(@(mu, sigma, scale, offset, xx) ...
                            scale .* normcdf(xx, mu, sigma) + offset, ...
                         'independent',  'xx', ...
                         'coefficients', {'mu', 'sigma', 'scale', 'offset'});

            opts = fitoptions(ft);
            opts.StartPoint = [p.Results.mu0,    p.Results.sigma0, ...
                               p.Results.scale0, p.Results.offset0];
            opts.Lower      = [x(1),   1e-3, -Inf, -Inf];
            opts.Upper      = [x(end), 1,     0,  Inf];

            try
                cfo = fit(x, y, ft, opts);
                obj = CumulativeNormal(cfo.mu, cfo.sigma, cfo.scale, cfo.offset);
            catch ME
                % If `fit` fails outright, fall back to the start point so
                % downstream code still gets a CumulativeNormal back.
                warning('CumulativeNormal:fitFailed', ...
                    'fit() failed (%s); returning start point.', ME.message);
                obj = CumulativeNormal(p.Results.mu0,    p.Results.sigma0, ...
                                       p.Results.scale0, p.Results.offset0);
            end
        end

    end   % static methods

end
