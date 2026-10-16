"""Port of dissertation/code/2016-second-level-adaptation-experiments/test_svd.m

Experiment on accumulating Gram matrices: starting from Em = 0 (m x m), k random
n x m matrices A are drawn and A'A is added to Em only when it increases the
smallest singular value of Em.  The singular values of Em are displayed before
and after.

Porting notes:
- randn -> np.random.default_rng(seed).standard_normal (stream differs from
  MATLAB).  Displays -> print.  ``main()`` uses k = 10, n = 5, m = 3.
"""
import numpy as np


def test_svd(k, n, m, seed=None):
    rng = np.random.default_rng(seed)
    E = np.zeros((n, m))
    Em = E.T @ E
    print("ans =", np.linalg.svd(Em, compute_uv=False))
    for i in range(k):
        A = rng.standard_normal((n, m))
        Am = A.T @ A
        if np.min(np.linalg.svd(Am + Em, compute_uv=False)) > np.min(np.linalg.svd(Em, compute_uv=False)):
            Em = Em + Am
    print("ans =", np.linalg.svd(Em, compute_uv=False))


if __name__ == "__main__":
    test_svd(10, 5, 3, seed=0)
