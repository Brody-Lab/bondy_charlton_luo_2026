%{
Fit a logistic function using a least-square solver

The logistic function has 2 parameters: `k` captures the steepness of the curve and `x0` is the
function's midpoint.

$$
y = \frac{1}{1+\exp(-k(x-x_0))
$$


ARGUMENT
* `theta0`: initial parameters
* `x`: input data
* `y`: output data

RETURN
* `theta`: the first element represents the steepness of the curve and the second the function's
midpoint

%}
function theta = logistic_lsqcurvefit(theta0,x,y)
    f = @(theta, x) 1 ./ (1 + exp(-theta(1)*(x - theta(2))));
    theta = lsqcurvefit(f, theta0, x, y, [0 -1], [1e3, 1]);
end