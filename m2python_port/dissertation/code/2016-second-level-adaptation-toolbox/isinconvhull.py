"""Port of dissertation/code/2016-second-level-adaptation-toolbox/isinconvhull.m

isinconvhull(convhull, theta): returns 1 if the point theta (n-vector) lies
strictly inside the simplex whose m = n+1 vertices are the columns of
`convhull` (n x m), 0 otherwise. The barycentric coordinates are
alfa = [convhull; ones(1,m)]^-1 [theta; 1]; the test requires 0 < alfa < 1
and sum(alfa) == 1 (exact floating-point equality, as in the original).

Porting notes:
- m = length(convhull) (largest dimension), as in MATLAB.
- A singular vertex matrix (e.g. the all-zero initial hull used by
  gen_randconvhull) gives Inf in MATLAB (warning disabled) and therefore 0;
  the port reproduces this with _toolbox_l2.minv.
- The exact test sum(alfa) == 1 is kept; the sum is accumulated sequentially,
  so its round-off can differ from MATLAB's BLAS dot product in rare cases.
"""
import numpy as np

from _toolbox_l2 import minv, mlength


def isinconvhull(convhull, theta):
    convhull = np.atleast_2d(np.asarray(convhull, dtype=float))
    theta = np.asarray(theta, dtype=float).ravel()
    m = mlength(convhull)
    with np.errstate(invalid="ignore", over="ignore"):
        alfa_sup = minv(np.vstack([convhull, np.ones((1, m))])) @ np.concatenate([theta, [1.0]])
        up = alfa_sup[:m] < 1
        bottom = alfa_sup[:m] > 0
        soma = 0.0
        for a in alfa_sup:
            soma += a
    if np.sum(bottom[:m]) == m and np.sum(up[:m]) == m and soma == 1:
        return 1
    return 0
