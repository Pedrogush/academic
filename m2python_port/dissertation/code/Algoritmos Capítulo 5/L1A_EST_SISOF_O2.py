"""Port of dissertation/code/Algoritmos Capítulo 5/L1A_EST_SISOF_O2.m

Model-reference control of the second-order plant of L1A_SISOF_O2 with the
controller computed from the *true* plant parameters ("EST"): u = theta_c_est'*w,
theta_c_est = f(theta_p).  The identifier of L1A_SISOF_O2 still runs in parallel
(its estimate does not affect u).  Reference r = 1 + sin(3t) + sin(1.7t) + sin(t).
Forward Euler, step h.

Porting notes:
- Core shared with L1A_SISOF_O2._simulate(known=True, y_p0=0): here y_p(1) is not
  set in MATLAB and is auto-filled with 0.
- Outputs u (endk samples), tempo_1 (endk+1).  ``main()`` runs t = 20, h = 1e-3.
"""
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from L1A_SISOF_O2 import _simulate  # noqa: E402


def L1A_EST_SISOF_O2(t, h):
    """[u, tempo_1] = L1A_EST_SISOF_O2(t,h)"""
    t0 = time.time()
    with np.errstate(divide="ignore", invalid="ignore"):
        s = _simulate(t, h, y_p0=0.0, known=True)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["u"], s["tempo_1"]


def main():
    u, tempo_1 = L1A_EST_SISOF_O2(20, 1e-3)
    print("u(end) =", u[-1])


if __name__ == "__main__":
    main()
