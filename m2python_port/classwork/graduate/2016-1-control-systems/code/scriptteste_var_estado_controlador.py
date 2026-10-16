"""Port of classwork/graduate/2016-1-control-systems/code/scriptteste_var_estado_controlador.m

Quick test script: converts the controller 18*(s+1)^4/(0.0025 s^4 + 0.1 s^3 + s^2) to
state space (tf2ss) and integrates it by explicit Euler for 10000 steps, starting
from the state [0;0;0;0.6/7200] (chosen so that the controller output starts at
u = 0.6) and feeding back e(k) = 0.6 - u(k). Displays the controller state at
MATLAB step 50.

Porting notes:
- The original never defines the step `h` (the script errors in a clean workspace;
  it relied on a value left in the workspace by the simulation functions, which use
  h = 1e-2). Here `h` is a parameter of main() with default 1e-2 (CLI: --h).
- xc(:,1,50) (MATLAB, 1-based) -> xc[:, 49]. Arrays preallocated.
- The initial state is an equilibrium of this loop (u stays 0.6, e = 0), so
  xc(:,1,50) = [0 0 0 8.3333e-05], identical in Octave.
"""
import argparse

import numpy as np
from scipy.signal import tf2ss


def main(h=1e-2):
    Ac, bc, Cc, Dc = tf2ss(18 * np.array([1, 4, 6, 4, 1]), [0.0025, 0.1, 1, 0, 0])
    bc, Cc, Dc = bc[:, 0], Cc[0, :], Dc[0, 0]
    n = 10000
    u = np.zeros(n + 1)
    e = np.zeros(n)
    xc = np.zeros((4, n + 1))
    xc_ponto = np.zeros((4, n))
    u[0] = 0.6
    xc[:, 0] = [0, 0, 0, 0.6 / 7200]
    for k in range(n):
        e[k] = 0.6 - u[k]
        xc_ponto[:, k] = Ac @ xc[:, k] + bc * e[k]
        xc[:, k + 1] = xc[:, k] + h * xc_ponto[:, k]
        u[k + 1] = Cc @ xc[:, k + 1] + Dc * e[k]
    print('xc(:,1,50) =', xc[:, 49])
    return xc, u


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument('--h', type=float, default=1e-2, help='passo de Euler (indefinido no original)')
    main(ap.parse_args().h)
