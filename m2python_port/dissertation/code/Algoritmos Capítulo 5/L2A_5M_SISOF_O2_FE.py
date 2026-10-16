"""Port of dissertation/code/Algoritmos Capítulo 5/L2A_5M_SISOF_O2_FE.m

Variant of L2A_5M_SISOF_O2 with forgetting-factor memory in the second level
("FE") and a faster first level: Gamma = 100*I, dM/dt = -6*M + E_f'E_f, dv/dt = -6*v + E_f'*eps_5_f,
dalfa/dt = 10*(-(E_f'E_f + M)*alfa - E_f'*eps_5_f - v); controller from the
clipped combined estimate by certainty equivalence.  Forward Euler, step h.

Porting notes:
- Core shared with L2A_5M_SISOF_O2._simulate(fe=True).
- Outputs theta_n2 (4, endk+1), y_p, y_m (endk+1), u (endk), tempo_1.
- ``main()`` runs t = 20, h = 1e-3.
"""
import os
import sys
import time

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from L2A_5M_SISOF_O2 import _simulate  # noqa: E402


def L2A_5M_SISOF_O2_FE(t, h):
    """[theta_n2, y_p, y_m, u, tempo_1] = L2A_5M_SISOF_O2_FE(t,h)"""
    t0 = time.time()
    with np.errstate(divide="ignore", invalid="ignore"):
        s = _simulate(t, h, fe=True)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["theta_n2"], s["y_p"], s["y_m"], s["u"], s["tempo_1"]


def main():
    theta_n2, y_p, y_m, u, tempo_1 = L2A_5M_SISOF_O2_FE(20, 1e-3)
    print("theta_n2(end) =", theta_n2[:, -1], " y_p(end)-y_m(end) =", y_p[-1] - y_m[-1])


if __name__ == "__main__":
    main()
