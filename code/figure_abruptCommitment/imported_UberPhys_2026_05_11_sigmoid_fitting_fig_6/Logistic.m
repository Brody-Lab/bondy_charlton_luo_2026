classdef Logistic
% Logistic  4-parameter logistic sigmoid, constrained to be monotonically
%           decreasing (positive -> negative).
%
%   f(x) = scale * 1./(1 + exp(-(x - x0)/k)) + offset
%
%   Parameters:
%     x0     - inflection point (location)
%     k      - width (> 0); larger k = gentler slope
%     scale  - amplitude (<= 0, so the curve decreases)
%     offset - upper asymptote (value as x -> -inf)
%
%   The function decreases from offset (at x -> -inf) to offset + scale
%   (at x -> +inf). Sign convention mirrors a "drop" sigmoid.
%
%   Usage:
%     % Construct with known parameters
%     lg = Logistic(0, 0.05, -0.1, 0.05);
%     y  = lg.evaluate(x);
%
%     % Fit to data (auto-initialised, scale <= 0 enforced)
%     lg = Logistic.fit(x, y);
%
%     % Fit with warm starts for the nonlinear parameters
%     lg = Logistic.fit(x, y, 'x00', 0, 'k0', 0.05);

    properties
        x0     (1,1) double =  0     % inflection point
        k      (1,1) double =  1     % width  (> 0; enforced by fit bounds)
        scale  (1,1) double = -1     % amplitude (<= 0; enforced by fit)
        offset (1,1) double =  0     % upper asymptote
    end

    % ------------------------------------------------------------------
    methods

        function obj = Logistic(x0, k, scale, offset)
        % Constructor.  All arguments optional; defaults: x0=0, k=1,
        % scale=-1, offset=0.
            if nargin >= 1, obj.x0     = x0;     end
            if nargin >= 2, obj.k      = k;      end
            if nargin >= 3, obj.scale  = scale;  end
            if nargin >= 4, obj.offset = offset; end
        end

        % --------------------------------------------------------------
        function y = evaluate(obj, x)
        % EVALUATE  Compute f(x) = scale * sigmoid((x - x0)/k) + offset.
            y = obj.scale .* Logistic.sigmoid((x - obj.x0) ./ obj.k) + obj.offset;
        end

        % --------------------------------------------------------------
        function params = asVector(obj)
        % ASVECTOR  Return [x0, k, scale, offset] as a row vector.
            params = [obj.x0, obj.k, obj.scale, obj.offset];
        end

        % --------------------------------------------------------------
        function disp(obj)
            fprintf('Logistic\n');
            fprintf('  x0     = %g\n', obj.x0);
            fprintf('  k      = %g\n', obj.k);
            fprintf('  scale  = %g\n', obj.scale);
            fprintf('  offset = %g\n', obj.offset);
        end

    end   % instance methods

    % ------------------------------------------------------------------
    methods (Static)

        function s = sigmoid(z)
        % Numerically stable logistic: 1 / (1 + exp(-z))
            s = 1 ./ (1 + exp(-z));
        end

        % --------------------------------------------------------------
        function obj = fit(x, y, varargin)
        % FIT  Fit a decreasing Logistic to data via variable projection.
        %
        %   lg = Logistic.fit(x, y)
        %   lg = Logistic.fit(x, y, 'x00', x00, 'k0', k0)
        %
        %   The model y = scale * sigmoid((x - x0)/k) + offset is linear
        %   in (scale, offset) at fixed (x0, k). The nonlinear solver
        %   runs only on the 2-D (x0, k) problem; the optimal
        %   (scale, offset) is recovered in closed form via
        %   Logistic.fitLinear, which enforces scale <= 0 (so the
        %   sigmoid goes positive -> negative).
        %
        %   'x00' / 'k0' supply an extra start point (e.g. from a fit
        %   to the mean across bootstrap resamples) tried first.
        %   'scale0' and 'offset0' are accepted for backward compatibility
        %   with the CumulativeGaussian API but ignored -- scale and
        %   offset are always solved linearly.
        %
        %   NaNs in x and y are removed before fitting. The best result
        %   across multiple starts is returned.

            % --- strip NaNs (force columns for downstream linear LS) ---
            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid);
            y = y(valid);

            % --- 2-D bounds on (x0, k) ---------------------------------
            xr = range(x);
            lb = [x(1),    1e-3];
            ub = [x(end), 1   ];

            % --- parse optional initial-parameter overrides ------------
            p = inputParser;
            addParameter(p, 'x00',     [], @isnumeric);
            addParameter(p, 'k0',      [], @isnumeric);
            addParameter(p, 'scale0',  [], @isnumeric);   % ignored
            addParameter(p, 'offset0', [], @isnumeric);   % ignored
            parse(p, varargin{:});

            % --- build set of (x0, k) starts ---------------------------
            [~, idx]  = max(abs(diff(y)));
            x00_data  = (x(idx) + x(idx+1)) / 2;
            k0_data   = xr / 8;                          % moderate

            x0_grid = linspace(min(x), max(x), 5);
            k_grid  = [xr/40, xr/12, xr/4];              % narrow, mid, wide

            [XX, KK] = ndgrid(x0_grid, k_grid);
            starts   = [XX(:), KK(:); ...
                        x00_data, k0_data];

            if ~isempty(p.Results.x00)
                override = [p.Results.x00, ...
                            Logistic.coalesce(p.Results.k0, k0_data)];
                starts = [override; starts];
            end

            % --- profiled residual at fixed (x0, k):
            %     solve constrained linear LS for (scale, offset) and
            %     return y - yhat. Anonymous form so lsqnonlin handles
            %     it cleanly inside classdef.
            profResid = @(xk) Logistic.profiledResidual(xk(1), xk(2), x, y);

            opts = optimoptions('lsqnonlin', ...
                'Display',               'off', ...
                'FunctionTolerance',     1e-7, ...
                'StepTolerance',         1e-7, ...
                'OptimalityTolerance',   1e-7, ...
                'MaxFunctionEvaluations', 5000);

            best_sse = Inf;
            best_xk  = starts(1,:);

            for s = 1:size(starts, 1)
                xk0 = min(max(starts(s,:), lb), ub);
                try
                    xk_fit = lsqnonlin(profResid, xk0, lb, ub, opts);
                    rr     = profResid(xk_fit);
                    sse    = rr.' * rr;
                    if sse < best_sse
                        best_sse = sse;
                        best_xk  = xk_fit;
                    end
                catch
                    % skip failed starts
                end
            end

            % Recover (scale, offset) at the winning (x0, k).
            obj = Logistic.fitLinear(x, y, best_xk(1), best_xk(2));
        end

        % --------------------------------------------------------------
        function r = profiledResidual(x0, k, x, y)
        % Profiled residual used inside lsqnonlin on (x0, k).
        % Solves constrained (scale <= 0) linear LS for (scale, offset)
        % at fixed (x0, k) and returns y - yhat.
            F = [Logistic.sigmoid((x - x0) ./ k), ones(numel(x), 1)];

            % unconstrained linear LS
            ab = F \ y;

            if ab(1) > 0
                % constraint scale <= 0 is active: clamp scale = 0,
                % then offset is the LS estimate of a constant column.
                scale_c  = 0;
                offset_c = mean(y);
                yhat     = scale_c * F(:,1) + offset_c;
            else
                yhat = F * ab;
            end
            r = y - yhat;
        end

        % --------------------------------------------------------------
        function [obj, sse, yhat] = fitLinear(x, y, x0, k)
        % FITLINEAR  Best (scale, offset) for fixed (x0, k) via
        %            constrained linear LS (scale <= 0).
        %
        %   lg              = Logistic.fitLinear(x, y, x0, k)
        %   [lg, sse]       = Logistic.fitLinear(x, y, x0, k)
        %   [lg, sse, yhat] = Logistic.fitLinear(x, y, x0, k)
        %
        %   At fixed (x0, k) the model
        %       y = scale * sigmoid((x - x0)/k) + offset
        %   is linear in (scale, offset). The unconstrained LS solution
        %   is [scale*; offset*] = F \ y with F = [sigmoid, 1]. If
        %   scale* > 0 the constrained optimum has scale = 0 and
        %   offset = mean(y).
        %
        %   NaNs in x or y are stripped before fitting.

            x = x(:); y = y(:);
            valid = ~isnan(x) & ~isnan(y);
            x = x(valid); y = y(valid);

            F  = [Logistic.sigmoid((x - x0) ./ k), ones(numel(x), 1)];
            ab = F \ y;

            if ab(1) > 0
                scale_c  = 0;
                offset_c = mean(y);
            else
                scale_c  = ab(1);
                offset_c = ab(2);
            end

            obj = Logistic(x0, k, scale_c, offset_c);

            if nargout >= 2
                yhat = scale_c * F(:,1) + offset_c;
                sse  = sum((y - yhat).^2);
            end
            if nargout >= 3
                yhat = scale_c * F(:,1) + offset_c;
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
