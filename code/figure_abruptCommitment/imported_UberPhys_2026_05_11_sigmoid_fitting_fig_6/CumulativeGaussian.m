classdef CumulativeGaussian
% CumulativeGaussian  4-parameter cumulative Gaussian sigmoid
%
%   f(x) = scale * normcdf(x, mu, sigma) + offset
%
%   Parameters:
%     mu     - mean: center / inflection point of the sigmoid
%     sigma  - sd: width (must be > 0)
%     scale  - amplitude; positive = increasing, negative = decreasing
%     offset - vertical offset (asymptote as x -> -inf)
%
%   Usage:
%     % Construct with known parameters
%     cg = CumulativeGaussian(0, 0.1, 1, 0);
%     y  = cg.evaluate(x);
%
%     % Fit to data (auto-initialised)
%     cg = CumulativeGaussian.fit(x, y);
%
%     % Fit to data with explicit initial parameters
%     cg = CumulativeGaussian.fit(x, y, 'mu0', 0, 'sigma0', 0.1, ...
%                                        'scale0', -1, 'offset0', 0.1);

    properties
        mu     (1,1) double = 0       % inflection point
        sigma  (1,1) double = 1       % width (kept > 0 by fit bounds)
        scale  (1,1) double = 1       % amplitude (+ve = increasing)
        offset (1,1) double = 0       % baseline (lower asymptote)
    end

    % ------------------------------------------------------------------
    methods

        function obj = CumulativeGaussian(mu, sigma, scale, offset)
        % Constructor.  All arguments optional; defaults: mu=0, sigma=1,
        % scale=1, offset=0.
            if nargin >= 1, obj.mu     = mu;     end
            if nargin >= 2, obj.sigma  = sigma;  end
            if nargin >= 3, obj.scale  = scale;  end
            if nargin >= 4, obj.offset = offset; end
        end

        % --------------------------------------------------------------
        function y = evaluate(obj, x)
        % EVALUATE  Compute f(x) = scale * normcdf(x, mu, sigma) + offset
            y = obj.scale .* normcdf(x, obj.mu, obj.sigma) + obj.offset;
        end

        % --------------------------------------------------------------
        function params = asVector(obj)
        % ASVECTOR  Return [mu, sigma, scale, offset] as a row vector.
            params = [obj.mu, obj.sigma, obj.scale, obj.offset];
        end

        % --------------------------------------------------------------
        function disp(obj)
            fprintf('CumulativeGaussian\n');
            fprintf('  mu     = %g\n', obj.mu);
            fprintf('  sigma  = %g\n', obj.sigma);
            fprintf('  scale  = %g\n', obj.scale);
            fprintf('  offset = %g\n', obj.offset);
        end

    end   % instance methods

    % ------------------------------------------------------------------
    methods (Static)

        function obj = fit(x, y, varargin)
        % FIT  Fit a CumulativeGaussian to data via variable projection.
        %
        %   cg = CumulativeGaussian.fit(x, y)
        %   cg = CumulativeGaussian.fit(x, y, 'mu0', mu0, 'sigma0', sigma0)
        %
        %   The model y = scale * normcdf(x; mu, sigma) + offset is
        %   linear in (scale, offset) at fixed (mu, sigma). This routine
        %   only runs the nonlinear solver on the 2-D (mu, sigma)
        %   problem; at every iterate the optimal (scale, offset) is
        %   recovered in closed form via CumulativeGaussian.fitLinear.
        %   This is faster and dramatically reduces start-point
        %   sensitivity vs a naive 4-D fit.
        %
        %   'mu0' / 'sigma0' supply an extra start point (e.g. from a
        %   fit to the mean across bootstrap resamples) tried first.
        %   'scale0' and 'offset0' are accepted for backward
        %   compatibility but ignored -- scale and offset are always
        %   solved linearly.
        %
        %   NaNs in x and y are removed before fitting. The best result
        %   across multiple starts is returned.

            % --- strip NaNs (force columns for downstream linear LS) ---
            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid);
            y = y(valid);

            % --- 2-D bounds on (mu, sigma) -----------------------------
            xr = range(x);
            lb = [x(1), 1e-3];
            ub = [x(end), 1];

            % --- parse optional initial-parameter overrides ------------
            p = inputParser;
            addParameter(p, 'mu0',     [], @isnumeric);
            addParameter(p, 'sigma0',  [], @isnumeric);
            addParameter(p, 'scale0',  [], @isnumeric);   % ignored
            addParameter(p, 'offset0', [], @isnumeric);   % ignored
            parse(p, varargin{:});

            % --- build set of (mu, sigma) starts -----------------------
            [~, idx]    = max(abs(diff(y)));
            mu0_data    = (x(idx) + x(idx+1)) / 2;
            sigma0_data = xr / 4;

            mu_grid    = linspace(min(x), max(x), 5);
            sigma_grid = [xr/20, xr/8, xr/3];           % narrow, mid, wide

            [MM, SS] = ndgrid(mu_grid, sigma_grid);
            starts   = [MM(:), SS(:); ...
                        mu0_data, sigma0_data];

            if ~isempty(p.Results.mu0)
                override = [p.Results.mu0, ...
                            CumulativeGaussian.coalesce(p.Results.sigma0, sigma0_data)];
                starts = [override; starts];
            end

            % --- profiled residual: closed-form (scale, offset) at each
            %     (mu, sigma) eval, return y - yhat. Anonymous form so
            %     lsqnonlin handles it cleanly inside classdef.
            one_col   = ones(numel(x), 1);
            profResid = @(ms) y - ...
                [normcdf(x, ms(1), ms(2)), one_col] * ...
                ([normcdf(x, ms(1), ms(2)), one_col] \ y);

            opts = optimoptions('lsqnonlin', ...
                'Display',               'off', ...
                'FunctionTolerance',     1e-7, ...
                'StepTolerance',         1e-7, ...
                'OptimalityTolerance',   1e-7, ...
                'MaxFunctionEvaluations', 5000);

            best_sse = Inf;
            best_ms  = starts(1,:);

            for s = 1:size(starts, 1)
                ms0 = min(max(starts(s,:), lb), ub);
                try
                    ms_fit = lsqnonlin(profResid, ms0, lb, ub, opts);
                    rr     = profResid(ms_fit);
                    sse    = rr.' * rr;
                    if sse < best_sse 
                        best_sse = sse;
                        best_ms  = ms_fit;
                    end
                                    ff(s,:)=ms_fit;
                catch
                    % skip failed starts
                end
            end

            % Recover (scale, offset) at the winning (mu, sigma).
            obj = CumulativeGaussian.fitLinear(x, y, best_ms(1), best_ms(2));
        end

        % --------------------------------------------------------------
        function [obj, sse, yhat] = fitLinear(x, y, mu, sigma)
        % FITLINEAR  Best (scale, offset) for fixed (mu, sigma) via linear LS.
        %
        %   cg                  = CumulativeGaussian.fitLinear(x, y, mu, sigma)
        %   [cg, sse]           = CumulativeGaussian.fitLinear(x, y, mu, sigma)
        %   [cg, sse, yhat]     = CumulativeGaussian.fitLinear(x, y, mu, sigma)
        %
        %   At fixed (mu, sigma) the model
        %       y = scale * normcdf(x; mu, sigma) + offset
        %   is linear in (scale, offset), so the optimum is closed-form:
        %       [scale; offset] = F \ y,   F = [normcdf(x; mu, sigma), 1].
        %
        %   Returns a CumulativeGaussian object with the supplied
        %   (mu, sigma) and the linearly-optimal (scale, offset). The
        %   second output is the SSE; the third is the fitted y values.
        %
        %   NaNs in x or y are stripped before fitting.

            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid); y = y(valid);

            F  = [normcdf(x, mu, sigma), ones(numel(x), 1)];
            ab = F \ y;                       % [scale; offset]

            obj = CumulativeGaussian(mu, sigma, ab(1), ab(2));

            if nargout >= 2
                yhat = F * ab;
                sse  = sum((y - yhat).^2);
            end
            if nargout >= 3
                yhat = F * ab;
            end
        end

        % --------------------------------------------------------------
        function val = coalesce(override, default)
        % Return override if non-empty, otherwise default.
            if isempty(override)
                val = default;
            else
                val = override;
            end
        end

    end   % static methods

end
