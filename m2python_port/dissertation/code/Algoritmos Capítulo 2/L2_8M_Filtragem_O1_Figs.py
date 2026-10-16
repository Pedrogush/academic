"""Port of dissertation/code/Algoritmos Capítulo 2/L2_8M_Filtragem_O1_Figs.m

Figure version of the 8-model second-level identification of
dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3, u = sin(t)), models on the border of
the uncertainty region (see L2_8M_Filtragem_O1).  Differences from
L2_8M_Filtragem_O1: the "measured" regression output is the noise-free
z = -a_p*phi_1 + k_p*phi_2, and the model outputs are computed one step ahead,
z_hat_i(k+1) = -phi_1(k+1)*hat_a_p_i(k+1) + phi_2(k+1)*hat_k_p_i(k+1) with
z_hat_i(1) = 0.  Then it draws, with an animatedline loop (no drawnow), the level-2
trajectory inside the uncertainty region (skip = 10000).

Porting notes:
- MATLAB returns nothing; the Python function returns (fig, ax).
- Default run: the final static figure, as MATLAB shows it; ``--animate`` /
  ``--save PATH`` play the animatedline loop as a FuncAnimation.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space, final_static_plot  # noqa: E402
from L2_3M_Filtragem_O1_Figs import _elements  # noqa: E402  (same figure layout)
from L2_8M_Filtragem_O1 import THETA0_8M  # noqa: E402


def _simulate(t, h):
    endk = int(np.floor(t / h + 1e-9))
    N = 8
    a_p, k_p, lam = 1.5, 3, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    ha = np.zeros((N, endk + 1)); hk = np.zeros((N, endk + 1))
    ha[:, 0], hk[:, 0] = THETA0_8M
    zh = np.zeros((N, endk + 1))  # z_hat(i,1) = 0
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
        z[i] = -a_p * phi_1[i] + k_p * phi_2[i]
        e[:, i] = zh[:, i] - z[i]
        ha[:, i + 1] = ha[:, i] + h * (e[:, i] * y[i])
        hk[:, i + 1] = hk[:, i] + h * (-e[:, i] * u[i])
        zh[:, i + 1] = -phi_1[i + 1] * ha[:, i + 1] + phi_2[i + 1] * hk[:, i + 1]
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


TITLE = "8 Modelos por Regressão Linear "


def L2_8M_Filtragem_O1_Figs(t, h, skip=10000):
    """Simulate and draw the final figure (MATLAB figure(1)). Returns (fig, ax)."""
    s = _simulate(t, h)
    return final_static_plot(s["tempo"], _elements(s), skip=skip,
                             axis0=[s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]],
                             title=TITLE, fontsize=20)


def animate(t=30, h=1e-3, save=None, skip=10000, interval=500, sim=None):
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(s["tempo"], _elements(s), skip=skip,
                               axis0=[s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]],
                               title=TITLE, fontsize=20, interval=interval, save=save)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=10000)
    p.add_argument("--interval", type=int, default=500)
    a = p.parse_args(argv)
    anim = None
    if a.animate or a.save:
        anim = animate(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval)
    else:
        L2_8M_Filtragem_O1_Figs(a.t, a.h, skip=a.skip)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
