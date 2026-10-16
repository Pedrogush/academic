"""Port of dissertation/code/Algoritmos Capítulo 2/L2_3M_Filtragem_O1_DEFESA.m

Version of L2_3M_Filtragem_O1 prepared for the thesis defense ("DEFESA"): same
3-model second-level identification of dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3,
u = sin(t)), but the model outputs are algebraic,
z_hat_i = -phi_1*hat_a_p_i + phi_2*hat_k_p_i (filtered linear regression), and the
function's purpose is the (active) animation: the triangle (convex hull, "Fecho
Convexo") whose vertices are the three model estimates, shrinking and moving towards
the true parameters, drawn every skip = 250 steps and written to 'anim_fecho.gif'.

Porting notes:
- MATLAB returns nothing; the Python function returns the FuncAnimation object.
  The animation is active in MATLAB, so ``main()`` animates by default.
- ``gif('anim_fecho.gif',...)`` (File Exchange) -> ``save=`` / ``--save PATH``; the
  Python port only writes a file when a path is given.
- Full-screen figure -> figsize (16, 9); 'Marker','X','LineWidth',8 -> marker 'x'
  with edge width 8.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space, region  # noqa: E402


def _simulate(t, h):
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, lam = 1.5, 3, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    zh = np.zeros((3, endk + 1))
    ha = np.zeros((3, endk + 1)); hk = np.zeros((3, endk + 1))
    ha[:, 0] = [0.5, 0.5, 7]
    hk[:, 0] = [1, 11, 1]
    alfa = np.zeros((2, endk + 1)); alfa[:, 0] = [0.5, 0.5]
    alfa_3 = np.zeros(endk + 1); alfa_3[0] = 0
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); e = np.zeros((3, endk))
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
        E = np.array([e[0, i] - e[2, i], e[1, i] - e[2, i]])
        dot_alfa = -np.outer(E, E) @ alfa[:, i] - E * e[2, i]
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_3[i + 1] = 1 - alfa[0, i + 1] - alfa[1, i + 1]
        w = np.array([alfa[0, i], alfa[1, i], alfa_3[i]])
        hat_k_p_n2[i] = w @ hk[:, i]
        hat_a_p_n2[i] = w @ ha[:, i]
    return dict(endk=endk, y=y, u=u, tempo=tempo, tempo_1=tempo_1, z=z, z_hat=zh,
                e_f=e, hat_a_p=ha, hat_k_p=hk, alfa=alfa, alfa_3=alfa_3,
                hat_a_p_n2=hat_a_p_n2, hat_k_p_n2=hat_k_p_n2, a_p=a_p, k_p=k_p,
                a_p_M=4, a_p_m=0.5, k_p_M=6, k_p_m=1)


def animate(t=30, h=1e-3, save=None, skip=250, interval=50, sim=None):
    """The defense animation: convex hull of the 3 model estimates + their markers."""
    s = sim if sim is not None else _simulate(t, h)
    n = len(s["tempo"])
    ha, hk = s["hat_a_p"][:, :n], s["hat_k_p"][:, :n]
    cols = [(0, 0.3, 0.7), (0, 0.7, 0.3), (0.7, 0.3, 0)]
    el = [{"kind": "static", "x": [s["a_p"]], "y": [s["k_p"]], "label": "Parametros Verdadeiros",
           "kw": dict(marker="x", markersize=12, markeredgewidth=8.0, color=(0, 0, 0),
                      linestyle="none")},
          region(s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]),
          {"kind": "hull", "xs": ha, "ys": hk, "label": "Fecho Convexo",
           "kw": dict(linewidth=1.5, color=(0.1, 0, 0.5))}]
    for j in range(3):
        el.append({"kind": "marker", "x": ha[j], "y": hk[j], "label": f"Modelo {j + 1}",
                   "kw": dict(marker="*", markersize=12, markeredgewidth=1.0, color=cols[j])})
    return animate_param_space(
        s["tempo"], el, skip=skip, axis0=[s["a_p_m"] - 1, 8, s["k_p_m"] - 1, 12],
        interval=interval, title="3 Modelos por Regressão Linear ",
        xlabel="Parametro a", ylabel="Parametro k", fontsize=20, figsize=(16, 9),
        save=save)


def L2_3M_Filtragem_O1_DEFESA(t, h, save=None, skip=250, interval=50):
    """L2_3M_Filtragem_O1_DEFESA(t,h): simulate and build the convex-hull animation."""
    return animate(t, h, save=save, skip=skip, interval=interval)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true",
                   help="(always on: the MATLAB animation is active)")
    p.add_argument("--save", default=None, help="e.g. anim_fecho.gif")
    p.add_argument("--skip", type=int, default=250)
    p.add_argument("--interval", type=int, default=50)
    a = p.parse_args(argv)
    anim = L2_3M_Filtragem_O1_DEFESA(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
