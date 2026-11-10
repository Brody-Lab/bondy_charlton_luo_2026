classdef Normal
% Normal  4-parameter Gaussian PDF curve (not cumulative), fit via MATLAB's
%         built-in `fit` function (Curve Fitting Toolbox).
%
%   f(x) = scale * normpdf(x, mu, sigma) + offset
%
%   This is the PDF analog of CumulativeNormal -- a bell curve with an
%   additive offset, not a sigmoid. Intended for fitting the derivative
%   of a CumulativeNormal: d/dx [scale_cdf * Phi((x-mu)/sigma) + offset_cdf]
%   = scale_cdf * normpdf(x, mu, sigma), so the (mu, sigma) of this
%   class directly recover the (mu, sigma) of the underlying sigmoid.
%
%   The fitter delegates to MATLAB's built-in `fit` with a custom
%   `fittype` -- no custom objective. The scale parameter is constrained
%   to scale <= 0 so the fit corresponds to a "dip" in the derivative
%   (i.e. the original signal is decreasing through the transition).
%
%   Parameters:
%     mu     - centre (peak / dip location)
%     sigma  - width  (> 0)
%     scale  - amplitude (<= 0; the integral of the Gaussian component)
%     offset - additive baseline
%
%   Usage:
%     nm = Normal.fit(x, dy);
%     nm = Normal.fit(x, dy, 'mu0', 0, 'sigma0', 0.05, ...
%                            'scale0', -0.05, 'offset0', 0);

    properties
        mu     (1,1) double =  0
        sigma  (1,1) double =  1
        scale  (1,1) double = -1
        offset (1,1) double =  0
    end

    % ------------------------------------------------------------------
    methods

        function obj = Normal(mu, sigma, scale, offset)
        % Constructor.  All arguments optional; defaults: mu=0, sigma=1,
        % scale=-1, offset=0.
            if nargin >= 1, obj.mu     = mu;     end
            if nargin >= 2, obj.sigma  = sigma;  end
            if nargin >= 3, obj.scale  = scale;  end
            if nargin >= 4, obj.offset = offset; end
        end

        % --------------------------------------------------------------
        function y = evaluate(obj, x)
        % EVALUATE  f(x) = scale * normpdf(x, mu, sigma) + offset
            y = obj.scale .* normpdf(x, obj.mu, obj.sigma) + obj.offset;
        end

        % --------------------------------------------------------------
        function params = asVector(obj)
        % ASVECTOR  Return [mu, sigma, scale, offset].
            params = [obj.mu, obj.sigma, obj.scale, obj.offset];
        end

        % --------------------------------------------------------------
        function disp(obj)
            fprintf('Normal\n');
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
        %   nm = Normal.fit(x, y)
        %   nm = Normal.fit(x, y, 'mu0', m, 'sigma0', s, ...
        %                         'scale0', c, 'offset0', o)
        %
        %   Builds a `fittype` for scale*normpdf(x,mu,sigma)+offset and
        %   calls `fit(x, y, ft, opts)`. scale is constrained <= 0 so
        %   the recovered Gaussian is a "dip" (matching the derivative
        %   of a decreasing cumulative-normal sigmoid).
        %
        %   NaNs in x and y are removed before fitting.

            % --- strip NaNs --------------------------------------------
            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid); y = y(valid);

            % --- data-driven default start point -----------------------
            % mu: location of biggest deviation from the median (i.e.
            % the peak/dip). sigma: a moderate width.
            xr               = range(x);
            base             = median(y);
            [~, idx_extreme] = max(abs(y - base));
            mu0_data         = x(idx_extreme);
            sigma0_data      = xr / 6;

            % Linear LS for (scale, offset) at the default (mu, sigma)
            % to give the nonlinear solver a sensible starting amplitude.
            F  = [normpdf(x, mu0_data, sigma0_data), ones(numel(x), 1)];
            ab = F \ y;
            % If the unconstrained scale comes out positive, clamp it
            % at 0 so we start inside the feasible region.
            if ab(1) > 0
                ab(1) = 0;
                ab(2) = mean(y);
            end

            % --- parse overrides ---------------------------------------
            p = inputParser;
            addParameter(p, 'mu0',     mu0_data,    @isnumeric);
            addParameter(p, 'sigma0',  sigma0_data, @isnumeric);
            addParameter(p, 'scale0',  ab(1),       @isnumeric);
            addParameter(p, 'offset0', ab(2),       @isnumeric);
            parse(p, varargin{:});

            % --- build a fittype and call MATLAB's built-in `fit` ------
            ft = fittype(@(mu, sigma, scale, offset, xx) ...
                            scale .* normpdf(xx, mu, sigma) + offset, ...
                         'independent',  'xx', ...
                         'coefficients', {'mu', 'sigma', 'scale', 'offset'});

            opts = fitoptions(ft);
            opts.StartPoint = [p.Results.mu0,    p.Results.sigma0, ...
                               p.Results.scale0, p.Results.offset0];
            opts.Lower      = [x(1),   1e-3, -Inf, -Inf];
            opts.Upper      = [x(end), 1,     0,   Inf];   % scale <= 0

            try
                cfo = fit(x, y, ft, opts);
                obj = Normal(cfo.mu, cfo.sigma, cfo.scale, cfo.offset);
            catch ME
                warning('Normal:fitFailed', ...
                    'fit() failed (%s); returning start point.', ME.message);
                obj = Normal(p.Results.mu0,    p.Results.sigma0, ...
                             p.Results.scale0, p.Results.offset0);
            end
        end

    end   % static methods

end
