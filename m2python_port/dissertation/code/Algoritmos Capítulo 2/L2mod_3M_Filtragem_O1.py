"""Port of dissertation/code/Algoritmos Capítulo 2/L2mod_3M_Filtragem_O1.m

Modified second-level adaptation ("L2mod") with 3 identification models for the
plant dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3) under a step input u = 1.
Filtered linear regression with z = -a_p*phi_1 + k_p*phi_2 and algebraic model
outputs z_hat_i = -phi_1*hat_a_p_i + phi_2*hat_k_p_i; first-level gradient laws.
The second level uses integral (memory) terms: M = int(E_f'E_f), v = int(E_f'e_3_f),
dalfa/dt = -(E_f'E_f + M)*alfa - E_f'*e_3_f - v, alfa_3 = 1 - alfa_1 - alfa_2, with
initial weights alfa = (0, 0, 1).  Forward Euler, step h.  After the loop MATLAB
prints phi_1(endk), phi_2(endk) and runs the (active) animation of the three
first-level trajectories, the level-2 trajectory and the triangle (convex hull)
of the model estimates, skip = 200, axis zoom at t = 6 s and 10 s, written to
'L2mod_3M_Filtragem_O1.gif'.

Porting notes:
- The animation is active in MATLAB, so ``main()`` animates by default;
  ``gif(...)`` (File Exchange) -> ``--save PATH`` (no file is written otherwise).
- MATLAB also opens an empty figure(1) before the full-screen animation figure;
  not reproduced.
- The function returns the FuncAnimation (MATLAB returns nothing); the simulation
  results are available with ``_simulate``.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space  # noqa: E402
from L2_3M_Filtragem_O1 import three_model_elements  # noqa: E402


def _simulate(t, h, alfa0=(0.0, 0.0)):
    """Euler loop; alfa0 = (alfa_1(1), alfa_2(1)) (L2mod: (0,0); _Figs: (0.5,0.5))."""
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, lam = 1.5, 3, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    zh = np.zeros((3, endk + 1))
    ha = np.zeros((3, endk + 1)); hk = np.zeros((3, endk + 1))
    ha[:, 0] = [0.5, 0.5, 7]
    hk[:, 0] = [1, 11, 1]
    alfa = np.zeros((2, endk + 1)); alfa[:, 0] = alfa0
    alfa_3 = np.zeros(endk + 1); alfa_3[0] = 1 - alfa0[0] - alfa0[1]
    M = np.zeros((2, 2, endk + 1)); v = np.zeros((2, endk + 1))
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); e = np.zeros((3, endk))
    hat_a_p_n2 = np.zeros(endk); hat_k_p_n2 = np.zeros(endk)
    for i in range(endk):
        k = i + 1
        u[i] = 1
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        phi_1[i + 1] = phi_1[i] + h * (-lam * phi_1[i] + y[i])
        phi_2[i + 1] = phi_2[i] + h * (-lam * phi_2[i] + u[i])
        z[i] = -a_p * phi_1[i] + k_p * phi_2[i]
        zh[:, i] = -phi_1[i] * ha[:, i] + phi_2[i] * hk[:, i]
        e[:, i] = zh[:, i] - z[i]
        ha[:, i + 1] = ha[:, i] + h * (e[:, i] * y[i])
        hk[:, i + 1] = hk[:, i] + h * (-e[:, i] * u[i])
        E = np.array([e[0, i] - e[2, i], e[1, i] - e[2, i]])
        EE = np.outer(E, E)
        M[:, :, i + 1] = M[:, :, i] + h * EE
        v[:, i + 1] = v[:, i] + h * (E * e[2, i])
        dot_alfa = -(EE + M[:, :, i]) @ alfa[:, i] - E * e[2, i] - v[:, i]
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_3[i + 1] = 1 - alfa[0, i + 1] - alfa[1, i + 1]
        w = np.array([alfa[0, i], alfa[1, i], alfa_3[i]])
        hat_k_p_n2[i] = w @ hk[:, i]
        hat_a_p_n2[i] = w @ ha[:, i]
    return dict(endk=endk, y=y, u=u, tempo=tempo, tempo_1=tempo_1, z=z, z_hat=zh,
                e_f=e, hat_a_p=ha, hat_k_p=hk, alfa=alfa, alfa_3=alfa_3, M=M, v=v,
                phi_1=phi_1, phi_2=phi_2,
                hat_a_p_n2=hat_a_p_n2, hat_k_p_n2=hat_k_p_n2, a_p=a_p, k_p=k_p,
                a_p_M=4, a_p_m=0.5, k_p_M=6, k_p_m=1)


def animate(t=30, h=1e-3, save=None, skip=200, interval=50, sim=None):
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(
        s["tempo"], three_model_elements(s, "f"), skip=skip, axis0=[0, 9, 0, 12],
        axis_schedule=[(6, [0, 5.5, 0, 6]), (10, [1, 2.5, 1, 5])],
        interval=interval, figsize=(16, 9), save=save)


def L2mod_3M_Filtragem_O1(t, h, save=None, skip=200, interval=50):
    """L2mod_3M_Filtragem_O1(t,h): simulate, print phi_1(endk), phi_2(endk), animate."""
    s = _simulate(t, h)
    endk = s["endk"]
    print("ans =", s["phi_1"][endk - 1])
    print("ans =", s["phi_2"][endk - 1])
    return animate(t, h, save=save, skip=skip, interval=interval, sim=s)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true",
                   help="(always on: the MATLAB animation is active)")
    p.add_argument("--save", default=None, help="e.g. L2mod_3M_Filtragem_O1.gif")
    p.add_argument("--skip", type=int, default=200)
    p.add_argument("--interval", type=int, default=50)
    a = p.parse_args(argv)
    anim = L2mod_3M_Filtragem_O1(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
