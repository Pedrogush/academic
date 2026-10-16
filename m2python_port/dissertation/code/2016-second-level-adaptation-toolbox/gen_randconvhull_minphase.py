"""Port of dissertation/code/2016-second-level-adaptation-toolbox/gen_randconvhull_minphase.m

[convhull, alpha] = gen_randconvhull_minphase(n, theta): like
gen_randconvhull, but the first n/2 rows (numerator coefficients) of each
random vertex are made non-negative (|.|), so that the identification models
are minimum phase; draws until theta is inside the simplex and returns the
vertices and the barycentric coordinates alpha.

Porting notes:
- randn -> numpy Generator (np.random.default_rng(seed)); optional `seed`
  argument; the random stream differs from MATLAB's. As in MATLAB, the b
  block is drawn before the a block in each attempt.
- n must be even (MATLAB would fail with a non-integer size otherwise).
- Bug kept: alpha(1:length(alpha-1)) is the WHOLE vector (n+1 entries).
"""
import numpy as np

from _toolbox_l2 import minv
from isinconvhull import isinconvhull


def gen_randconvhull_minphase(n, theta, seed=None):
    rng = np.random.default_rng(seed)
    theta = np.asarray(theta, dtype=float).ravel()
    m = n + 1
    convhull = np.zeros((n, m))
    radius = 2 * np.linalg.norm(theta)

    while isinconvhull(convhull, theta) != 1:
        convhull_b = radius * rng.standard_normal((n // 2, m))
        convhull_a = radius * rng.standard_normal((n // 2, m))
        for j in range(m):
            for i in range(n // 2):
                if np.sign(convhull_b[i, j]) < 0:
                    convhull_b[i, j] = -convhull_b[i, j]
        convhull = np.vstack([convhull_b, convhull_a])
    alpha = minv(np.vstack([convhull, np.ones((1, m))])) @ np.concatenate([theta, [1.0]])
    alpha = alpha[:len(alpha - 1)]  # (sic) o vetor inteiro, como no original
    return convhull, alpha
