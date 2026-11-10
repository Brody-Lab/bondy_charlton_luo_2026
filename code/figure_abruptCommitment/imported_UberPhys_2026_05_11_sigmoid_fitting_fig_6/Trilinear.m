classdef Trilinear
% Trilinear  6-parameter continuous piecewise-linear function (3 segments)
%
%   f(x) = y0 + m1*(x - x1)                              for x <= x1
%   f(x) = y0 + m2*(x - x1)                              for x1 < x <= x2
%   f(x) = y0 + m2*(x2 - x1) + m3*(x - x2)               for x > x2
%
%   Continuous by construction (each segment is defined relative to its
%   left endpoint's value).  Allows arbitrary slope signs in each segment
%   so it can represent steps, ramps, or non-monotonic shapes.
%
%   Parameters:
%     m1, m2, m3 - slopes of the three segments
%     x1, x2     - breakpoints (x1 < x2)
%     y0         - y-value at x = x1 (vertical offset)
%
%   Usage:
%     tl = Trilinear(0, -1, 0, -0.05, 0.05, 0.1);
%     y  = tl.evaluate(x);
%
%     tl = Trilinear.fit(x, y);                  % auto-initialised
%     tl = Trilinear.fit(x, y, 'x10', -0.1, 'x20', 0.05);

    properties
        m1 (1,1) double = 0
        m2 (1,1) double = 0
        m3 (1,1) double = 0
        x1 (1,1) double = -1
        x2 (1,1) double =  1
        y0 (1,1) double = 0
    end

    % ------------------------------------------------------------------
    methods

        function obj = Trilinear(m1, m2, m3, x1, x2, y0)
            if nargin >= 1, obj.m1 = m1; end
            if nargin >= 2, obj.m2 = m2; end
            if nargin >= 3, obj.m3 = m3; end
            if nargin >= 4, obj.x1 = x1; end
            if nargin >= 5, obj.x2 = x2; end
            if nargin >= 6, obj.y0 = y0; end
        end

        % --------------------------------------------------------------
        function y = evaluate(obj, x)
        % EVALUATE  Compute trilinear f(x); x can be any size, y matches.
            y = zeros(size(x));
            seg1 = x <= obj.x1;
            seg2 = (x > obj.x1) & (x <= obj.x2);
            seg3 = x > obj.x2;
            y(seg1) = obj.y0 + obj.m1 .* (x(seg1) - obj.x1);
            y(seg2) = obj.y0 + obj.m2 .* (x(seg2) - obj.x1);
            y(seg3) = obj.y0 + obj.m2 .* (obj.x2 - obj.x1) ...
                            + obj.m3 .* (x(seg3) - obj.x2);
        end

        % --------------------------------------------------------------
        function params = asVector(obj)
        % ASVECTOR  Return [m1, m2, m3, x1, x2, y0].
            params = [obj.m1, obj.m2, obj.m3, obj.x1, obj.x2, obj.y0];
        end

        % --------------------------------------------------------------
        function disp(obj)
            fprintf('Trilinear\n');
            fprintf('  m1 = %g\n  m2 = %g\n  m3 = %g\n', obj.m1, obj.m2, obj.m3);
            fprintf('  x1 = %g\n  x2 = %g\n  y0 = %g\n', obj.x1, obj.x2, obj.y0);
        end

    end   % instance methods

    % ------------------------------------------------------------------
    methods (Static)

        function obj = fit(x, y, varargin)
        % FIT  Fit a Trilinear to data using lsqcurvefit.
        %
        %   tl = Trilinear.fit(x, y)
        %   tl = Trilinear.fit(x, y, 'm10', m10, 'm20', m20, 'm30', m30, ...
        %                            'x10', x10, 'x20', x20, 'y00', y00)
        %
        %   Internally parameterises as [m1, m2, m3, x1, dx, y0] with
        %   dx = x2 - x1 >= dx_min, so the breakpoint ordering x1 < x2
        %   is guaranteed.  Multi-start strategy: 3 initial guesses are
        %   tried and the lowest-SSE result is returned.
        %
        %   NaNs in x or y are dropped before fitting.

            % --- strip NaNs ----------------------------------------
            valid = ~isnan(x(:)) & ~isnan(y(:));
            x = x(valid);
            y = y(valid);

            % --- parse optional initial-parameter overrides ----------
            p = inputParser;
            addParameter(p, 'm10', [], @isnumeric);
            addParameter(p, 'm20', [], @isnumeric);
            addParameter(p, 'm30', [], @isnumeric);
            addParameter(p, 'x10', [], @isnumeric);
            addParameter(p, 'x20', [], @isnumeric);
            addParameter(p, 'y00', [], @isnumeric);
            parse(p, varargin{:});

            xr     = range(x);
            dx_min = xr / 20;        % minimum gap between breakpoints

            % --- bounds (parameter vector is [m1,m2,m3,x1,dx,y0]) ----
            % x1 constrained to the first half of the data range.
            lb = [-Inf, -Inf, -Inf, min(x),            dx_min, -Inf];
            ub = [ Inf,  0,  Inf, min(x) + xr/2,     xr,     Inf];

            % --- auto initial guesses ------------------------------
            % Start A: thirds split
            x1_A = min(x) + xr/3;
            x2_A = min(x) + 2*xr/3;
            sA   = Trilinear.segSlopes(x, y, x1_A, x2_A);
            y0_A = interp1(x, y, x1_A, 'linear', 'extrap');
            startA = [sA(1), sA(2), sA(3), x1_A, x2_A - x1_A, y0_A];

            % Start B: middle segment narrow & centred on x=0 (or median x)
            x_centre = 0;
            if x_centre < min(x) || x_centre > max(x)
                x_centre = median(x);
            end
            half_w = max(xr/10, dx_min);
            x1_B   = max(min(x), x_centre - half_w);
            x2_B   = min(max(x), x_centre + half_w);
            sB     = Trilinear.segSlopes(x, y, x1_B, x2_B);
            y0_B   = interp1(x, y, x1_B, 'linear', 'extrap');
            startB = [sB(1), sB(2), sB(3), x1_B, x2_B - x1_B, y0_B];

            % Start C: middle slope = overall slope, outer slopes ~ 0
            overall_slope = (y(end) - y(1)) / xr;
            startC = [0, overall_slope, 0, x1_A, x2_A - x1_A, y0_A];

            starts = [startA; startB; startC];

            % If caller supplied overrides, prepend them
            if any(~cellfun(@isempty, struct2cell(p.Results)))
                user = [ ...
                    Trilinear.coalesce(p.Results.m10, sA(1)), ...
                    Trilinear.coalesce(p.Results.m20, sA(2)), ...
                    Trilinear.coalesce(p.Results.m30, sA(3)), ...
                    Trilinear.coalesce(p.Results.x10, x1_A), ...
                    max(Trilinear.coalesce(p.Results.x20, x2_A) - ...
                        Trilinear.coalesce(p.Results.x10, x1_A), dx_min), ...
                    Trilinear.coalesce(p.Results.y00, y0_A) ];
                starts = [user; starts];
            end

            % --- fit from each start, keep best ----------------------
            model = @(pp, xdata) Trilinear.modelFcn(pp, xdata);

            opts = optimoptions('lsqcurvefit', ...
                'Display',               'off', ...
                'FunctionTolerance',     1e-10, ...
                'StepTolerance',         1e-10, ...
                'OptimalityTolerance',   1e-10, ...
                'MaxFunctionEvaluations', 5000);

            best_sse = Inf;
            best_p   = starts(1, :);

            for s = 1:size(starts, 1)
                p0 = starts(s, :);
                p0 = max(p0, lb);
                p0 = min(p0, ub);
                try
                    p_fit = lsqcurvefit(model, p0, x(:), y(:), lb, ub, opts);
                    sse   = sum((y(:) - model(p_fit, x(:))).^2);
                    if sse < best_sse
                        best_sse = sse;
                        best_p   = p_fit;
                    end
                catch
                    % skip failed starts
                end
            end

            % Convert internal (x1, dx) back to (x1, x2)
            obj = Trilinear(best_p(1), best_p(2), best_p(3), ...
                            best_p(4), best_p(4) + best_p(5), best_p(6));
        end

        % --------------------------------------------------------------
        function y = modelFcn(p, x)
        % Internal model used by lsqcurvefit.  Vector p is
        %   [m1, m2, m3, x1, dx, y0]   with x2 = x1 + dx.
            x1 = p(4);
            x2 = p(4) + p(5);
            y  = zeros(size(x));
            seg1 = x <= x1;
            seg2 = (x > x1) & (x <= x2);
            seg3 = x > x2;
            y(seg1) = p(6) + p(1) .* (x(seg1) - x1);
            y(seg2) = p(6) + p(2) .* (x(seg2) - x1);
            y(seg3) = p(6) + p(2) .* (x2 - x1) + p(3) .* (x(seg3) - x2);
        end

        % --------------------------------------------------------------
        function s = segSlopes(x, y, x1, x2)
        % Estimate slopes in the three segments via linear regression.
        % Returns [m1, m2, m3].  Falls back to 0 if a segment has <2 pts.
            s = zeros(1, 3);
            masks = {x <= x1, (x > x1) & (x <= x2), x > x2};
            for k = 1:3
                xs = x(masks{k});
                ys = y(masks{k});
                if numel(xs) >= 2 && range(xs) > 0
                    pp   = polyfit(xs(:), ys(:), 1);
                    s(k) = pp(1);
                end
            end
        end

        % --------------------------------------------------------------
        function val = coalesce(override, default)
            if isempty(override), val = default; else, val = override; end
        end

    end   % static methods

end
