classdef CumulativeGaussianL1
% CumulativeGaussianL1  4-parameter cumulative-Gaussian sigmoid, L1 fit
%
%   f(x) = scale * normcdf(x, mu, sigma) + offset
%
%   Same model as CumulativeGaussian, but fit by minimising the L1 loss
%
%       sum |y_i - f(x_i)|
%
%   instead of L2. All four parameters (mu, sigma, scale, offset) are
%   optimised jointly via lsqnonlin -- no variable-projection step.
%
%   lsqnonlin is intrinsically a least-squares solver (minimises sum F^2),
%   so L1 is obtained via the signed-square-root trick:
%
%       F_i = sign(r_i) * sqrt(|r_i| + eps_smooth),  r_i = y_i - f(x_i)
%   =>  sum F_i^2 = sum |r_i| + N * eps_smooth
%
%   eps_smooth is a tiny smoothing term that keeps F differentiable at
%   r = 0 (so finite-difference Jacobians inside lsqnonlin behave).
%
%   Parameters:
%     mu     - centre / inflection
%     sigma  - width (> 0)
%     scale  - amplitude  (sign unconstrained; > 0 rising, < 0 falling)
%     offset - lower-asymptote value
%
%   Usage:
%     cg = CumulativeGaussianL1.fit(x, y);
%     cg = CumulativeGaussianL1.fit(x, y, 'mu0', 0, 'sigma0', 0.1);
%     cg = CumulativeGaussianL1.fit(x, y, ...
%             'mu0', 0, 'sigma0', 0.1, 'scale0', -0.1, 'offset0', 0.05);

    properties
        mu     (1,1) double = 0
        sigma  (1,1) double = 1
        scale  (1,1) double = 1
        offset (1,1) double = 0
    end

    % ------------------------------------------------------------------
    methods

        function obj = CumulativeGaussianL1(mu, sigma, scale, offset)
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
            fprintf('CumulativeGaussianL1\n');
            fprintf('  mu     = %g\n', obj.mu);
            fprintf('  sigma  = %g\n', obj.sigma);
            fprintf('  scale  = %g\n', obj.scale);
            fprintf('  offset = %g\n', obj.offset);
        end

    end   % instance methods

    % ------------------------------------------------------------------
    methods (Static)

        function obj = fit(x, y, varargin)
        % FIT  Fit a CumulativeGaussianL1 to (x, y) under L1 loss.
        %
        %   cg = CumulativeGaussianL1.fit(x, y)
        %   cg = CumulativeGaussianL1.fit(x, y, 'mu0', m, 'sigma0', s, ...
        %                                       'scale0', c, 'offset0', o)
        %
        %   All four parameters are optimised jointly via lsqnonlin with
        %   the signed-square-root residual transform (see classdef
        %   header). The fit uses multiple starts and returns the lowest
        %   SAD (sum of absolute deviations) result.
        %
        %   Initial points are constructed by:
        %     1. Forming the same (mu, sigma) grid that CumulativeGaussian
        %        uses for its profiled fit.
        %     2. At each grid (mu, sigma), solving the linear LS problem
        %        for (scale, offset) as a warm start.  This gives 4-D
        %        starts that lie near the L2 optimum at that (mu, sigma).
        %     3. If 'mu0'/'sigma0' are supplied they form an extra start
        %        (tried first).  'scale0'/'offset0', if supplied,
        %        override the LS warm-start values on that first start.
        %
        %   NaNs in x and y are removed before fitting.

            % --- strip NaNs (force columns for the linear-LS warm-up) ---
            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid);
            y = y(valid);

            % --- parameter bounds: [mu, sigma, scale, offset] ----------
            xr = range(x);
            lb = [x(1),   1e-3, -Inf, -Inf];
            ub = [x(end), 1,     Inf,  Inf];

            % --- parse optional initial-parameter overrides ------------
            p = inputParser;
            addParameter(p, 'mu0',     [], @isnumeric);
            addParameter(p, 'sigma0',  [], @isnumeric);
            addParameter(p, 'scale0',  [], @isnumeric);
            addParameter(p, 'offset0', [], @isnumeric);
            parse(p, varargin{:});

            % --- (mu, sigma) start grid (same as CumulativeGaussian) ---
            [~, idx]    = max(abs(diff(y)));
            mu0_data    = (x(idx) + x(idx+1)) / 2;
            sigma0_data = xr / 4;

            mu_grid    = linspace(min(x), max(x), 5);
            sigma_grid = [xr/20, xr/8, xr/3];

            [MM, SS] = ndgrid(mu_grid, sigma_grid);
            ms_starts = [MM(:), SS(:); ...
                         mu0_data, sigma0_data];

            if ~isempty(p.Results.mu0)
                ms_user = [p.Results.mu0, ...
                           CumulativeGaussianL1.coalesce(p.Results.sigma0, sigma0_data)];
                ms_starts = [ms_user; ms_starts];
            end

            % Lift each (mu, sigma) start to 4-D via linear LS warm-up
            % for (scale, offset) at that (mu, sigma).
            one_col = ones(numel(x), 1);
            starts4 = zeros(size(ms_starts, 1), 4);
            for s = 1:size(ms_starts, 1)
                mu_s    = ms_starts(s, 1);
                sigma_s = max(ms_starts(s, 2), lb(2));
                F  = [normcdf(x, mu_s, sigma_s), one_col];
                ab = F \ y;                   % [scale_warm; offset_warm]
                starts4(s, :) = [mu_s, sigma_s, ab(1), ab(2)];
            end

            % If caller supplied scale0/offset0, override the warm start
            % values on the first row (the user-supplied start).
            if ~isempty(p.Results.scale0)
                starts4(1, 3) = p.Results.scale0;
            end
            if ~isempty(p.Results.offset0)
                starts4(1, 4) = p.Results.offset0;
            end

            % --- L1 residual (signed-square-root transform) ------------
            eps_smooth = 1e-10;
            l1Resid = @(th) CumulativeGaussianL1.l1ResidualVec( ...
                                th, x, y, eps_smooth);

            opts = optimoptions('lsqnonlin', ...
                'Display',               'off', ...
                'FunctionTolerance',     1e-9, ...
                'StepTolerance',         1e-9, ...
                'OptimalityTolerance',   1e-9, ...
                'MaxFunctionEvaluations', 5000);

            best_sad = Inf;
            best_th  = starts4(1, :);

            for s = 1:size(starts4, 1)
                th0 = min(max(starts4(s, :), lb), ub);
                try
                    th_fit = lsqnonlin(l1Resid, th0, lb, ub, opts);
                    yhat   = th_fit(3) .* normcdf(x, th_fit(1), th_fit(2)) + th_fit(4);
                    sad    = sum(abs(y - yhat));
                    if sad < best_sad
                        best_sad = sad;
                        best_th  = th_fit;
                    end
                catch
                    % skip failed starts
                end
            end

            obj = CumulativeGaussianL1(best_th(1), best_th(2), ...
                                       best_th(3), best_th(4));
        end

        % --------------------------------------------------------------
        function F = l1ResidualVec(th, x, y, eps_smooth)
        % Signed-square-root residual so lsqnonlin's sum(F^2) is the
        % (smoothed) sum of absolute deviations.
            yhat = th(3) .* normcdf(x, th(1), th(2)) + th(4);
            r    = y - yhat;
            F    = sign(r) .* sqrt(abs(r) + eps_smooth);
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
