"""Port of dissertation/code/2016-second-level-adaptation-toolbox/gen_randconvhull.m

[convhull, alpha] = gen_randconvhull(n, theta): draws random simplices
(n x (n+1) matrices with N(0, (2*norm(theta))^2) entries) until theta lies
inside (isinconvhull), and returns the vertices and the barycentric
coordinates alpha of theta.

Porting notes:
- randn -> numpy Generator (np.random.default_rng(seed)); optional `seed`
  argument; the random stream differs from MATLAB's.
- Bug kept: alpha(1:length(alpha-1)) is the WHOLE vector (n+1 entries), not
  the first n entries.
- gen_randconvhull.asv (MATLAB autosave with a different signature) is not
  ported.
"""
import numpy as np

from _toolbox_l2 import minv
from isinconvhull import isinconvhull


def gen_randconvhull(n, theta, seed=None):
    rng = np.random.default_rng(seed)
    theta = np.asarray(theta, dtype=float).ravel()
    m = n + 1
    convhull = np.zeros((n, m))
    radius = 2 * np.linalg.norm(theta)

    while isinconvhull(convhull, theta) != 1:
        convhull = radius * rng.standard_normal((n, m))
    alpha = minv(np.vstack([convhull, np.ones((1, m))])) @ np.concatenate([theta, [1.0]])
    alpha = alpha[:len(alpha - 1)]  # (sic) o vetor inteiro, como no original
    return convhull, alpha
