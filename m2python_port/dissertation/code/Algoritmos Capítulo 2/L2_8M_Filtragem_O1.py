"""Port of dissertation/code/Algoritmos Capítulo 2/L2_8M_Filtragem_O1.m

Same as L2_4M_Filtragem_O1 but with N = 8 identification models placed on the
border of the uncertainty region [0.5, 4] x [1, 6] (corners and mid-points):
(0.5,1) (2,1) (4,1) (4,3) (4,6) (2.5,6) (0.5,4) (0.5,6).  Plant
dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3, u = sin(t)); algebraic filtered-
regression model outputs, gradient first level, second-level weights with
alfa_8 = 1 - sum(alfa_1..7).  Returns the combined estimate.  Forward Euler.

The commented-out MATLAB animation (``animate``) shows the level-2 trajectory, the
8-vertex polygon (vertices in model order, closed) and the markers, skip = 200,
axis [0 5 0 7]; it wrote 'L2_8M_Filtragem_O1.gif'.

Porting notes:
- Outputs hat_a_p_n2, hat_k_p_n2, tempo with endk samples.
- Animation commented out in MATLAB -> ``--animate`` / ``--save PATH``.
- Same animation bugs as the 4-model file (markers frozen at the initial estimates,
  legend strings shifted); fixed in the port, ``faithful_markers=True`` restores the
  frozen markers.  See L2_4M_Filtragem_O1.n_model_elements.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space  # noqa: E402
from L2_4M_Filtragem_O1 import n_model_elements  # noqa: E402

THETA0_8M = ([0.5, 2, 4, 4, 4, 2.5, 0.5, 0.5], [1, 1, 1, 3, 6, 6, 4, 6])


def _simulate(t, h):
    endk = int(np.floor(t / h + 1e-9))
    N = 8
    a_p, k_p, lam = 1.5, 3, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    ha = np.zeros((N, endk + 1)); hk = np.zeros((N, endk + 1))
    ha[:, 0], hk[:, 0] = THETA0_8M
    zh = np.zeros((N, endk + 1))
    alfa = np.zeros((N - 1, endk + 1))
    alfa_N = np.zeros(endk + 1); alfa_N[0] = 1
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); e = np.zeros((N, endk))
    hat_a_p_n2 = np.zeros(endk); hat_k_p_n2 = np.zeros(endk)
    for i in range(endk):
        k = i + 1
        u[i] = np.sin(h * k)
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        phi_1[i + 1] = phi_1[i] + h * (-lam * phi_1[i] + y[i])
        phi_2[i + 1] = phi_2[i] + h * (-lam * phi_2[i] + u[i])
        z[i] = y[i] - lam * phi_1[i]
        zh[:, i] = -phi_1[i] * ha[:, i] + phi_2[i] * hk[:, i]
        e[:, i] = zh[:, i] - z[i]
        ha[:, i + 1] = ha[:, i] + h * (e[:, i] * y[i])
        hk[:, i + 1] = hk[:, i] + h * (-e[:, i] * u[i])
        E = e[:N - 1, i] - e[N - 1, i]
        dot_alfa = -np.outer(E, E) @ alfa[:, i] - E * e[N - 1, i]
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_N[i + 1] = 1 - np.sum(alfa[:, i + 1])
        w = np.r_[alfa[:, i], alfa_N[i]]
        hat_a_p_n2[i] = w @ ha[:, i]
        hat_k_p_n2[i] = w @ hk[:, i]
    return dict(endk=endk, N=N, y=y, u=u, tempo=tempo, tempo_1=tempo_1, z=z, z_hat=zh,
                e_f=e, hat_a_p=ha, hat_k_p=hk, alfa=alfa, alfa_N=alfa_N,
                hat_a_p_n2=hat_a_p_n2, hat_k_p_n2=hat_k_p_n2, a_p=a_p, k_p=k_p,
                a_p_M=4, a_p_m=0.5, k_p_M=6, k_p_m=1)


def L2_8M_Filtragem_O1(t, h):
    """[hat_a_p_n2, hat_k_p_n2, tempo] = L2_8M_Filtragem_O1(t,h)"""
    s = _simulate(t, h)
    return s["hat_a_p_n2"], s["hat_k_p_n2"], s["tempo"]


def animate(t=30, h=1e-3, save=None, skip=200, interval=50, sim=None,
            faithful_markers=False):
    """Port of the commented-out animation (skip = 200)."""
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(s["tempo"], n_model_elements(s, faithful_markers),
                               skip=skip, axis0=[0, 5, 0, 7], interval=interval,
                               figsize=(16, 9), save=save)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=200)
    p.add_argument("--interval", type=int, default=50)
    p.add_argument("--faithful-markers", action="store_true")
    a = p.parse_args(argv)
    an2, kn2, tempo = L2_8M_Filtragem_O1(a.t, a.h)
    print("hat_a_p_n2(end) =", an2[-1], " hat_k_p_n2(end) =", kn2[-1])
    anim = None
    if a.animate or a.save:
        anim = animate(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval,
                       faithful_markers=a.faithful_markers)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
