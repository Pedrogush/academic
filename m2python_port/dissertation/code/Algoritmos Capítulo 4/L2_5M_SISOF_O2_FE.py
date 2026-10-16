"""Port of dissertation/code/Algoritmos Capítulo 4/L2_5M_SISOF_O2_FE.m

Same 5-model second-level identification as L2_5M_SISOF_O2, with forgetting-
factor ("FE") memory terms in the second level:
dM/dt = -0.2*M + E_f'E_f, dv/dt = -0.2*v + E_f'*eps_5_f,
dalfa/dt = 10*(-(E_f'E_f + M)*alfa - E_f'*eps_5_f - v).
Forward Euler, step h.

Porting notes:
- Core shared with L2_5M_SISOF_O2._simulate(fe=True) (the MATLAB files differ
  only in these terms).  Outputs theta_n2 (4, endk+1), z_1, z_p, tempo_1.
- ``main()`` runs t = 20, h = 1e-3.
"""
import os
import sys
import time

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from L2_5M_SISOF_O2 import _simulate  # noqa: E402


def L2_5M_SISOF_O2_FE(t, h):
    """[theta_n2, z_1, z_p, tempo_1] = L2_5M_SISOF_O2_FE(t,h)"""
    t0 = time.time()
    s = _simulate(t, h, fe=True)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["theta_n2"], s["z_1"], s["z_p"], s["tempo_1"]


def main():
    theta_n2, z_1, z_p, tempo_1 = L2_5M_SISOF_O2_FE(20, 1e-3)
    print("theta_n2(end) =", theta_n2[:, -1])


if __name__ == "__main__":
    main()
