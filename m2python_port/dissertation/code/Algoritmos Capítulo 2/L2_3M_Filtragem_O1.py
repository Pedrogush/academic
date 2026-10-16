"""Port of dissertation/code/Algoritmos Capítulo 2/L2_3M_Filtragem_O1.m

Second-level adaptation with 3 identification models (filtered linear regression)
for the first-order plant dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3, u = sin(t)).
Each model i keeps its own estimate (hat_a_p_i, hat_k_p_i) updated by the
first-level gradient law; here the model outputs z_hat_i are produced by the
filters dz_hat_i/dt = -lambda*z_hat_i - hat_a_p_i*y + hat_k_p_i*u.  The second
level estimates the convex-combination weights alfa (alfa_3 = 1 - alfa_1 - alfa_2)
from the identification errors, dalfa/dt = -E_f'E_f*alfa - E_f'*e_3_f, and returns
the combined estimate hat_theta_n2 = sum_i alfa_i*hat_theta_i.  Forward Euler, step h.

The (commented-out) MATLAB animation shows the three first-level trajectories, the
second-level trajectory and the triangle (convex hull) formed by the three model
estimates converging to (a_p, k_p), with axis zooms at t = 6 s and t = 10 s.  It is
ported in ``animate``.

Porting notes:
- Outputs: hat_a_p_n2, hat_k_p_n2, tempo, each with endk samples (as in MATLAB).
- Animation commented out in MATLAB -> default run does not animate; ``--animate``
  / ``--save PATH`` (the MATLAB gif call 'L2_3M_Filtragem_O1.gif' was also
  commented out).  MATLAB full-screen figure -> figsize (16, 9).
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space, true_point, region  # noqa: E402


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
        for j in range(3):
            dot_zh = -lam * zh[j, i] - ha[j, i] * y[i] + hk[j, i] * u[i]
            zh[j, i + 1] = zh[j, i] + h * dot_zh
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


def L2_3M_Filtragem_O1(t, h):
    """[hat_a_p_n2, hat_k_p_n2, tempo] = L2_3M_Filtragem_O1(t,h)"""
    s = _simulate(t, h)
    return s["hat_a_p_n2"], s["hat_k_p_n2"], s["tempo"]


def three_model_elements(s, sub="f"):
    """Element list of the 3-model animation (shared by L2_3M_* / L2mod_3M_*)."""
    ha, hk = s["hat_a_p"], s["hat_k_p"]
    n = len(s["tempo"])
    tcols = [(0.7, 0.2, 0.2), (0.2, 0.2, 0.7), (0.2, 0.7, 0.2)]
    mcols = [(0.7, 0, 0), (0, 0, 0.7), (0, 0.7, 0)]
    el = [true_point(s["a_p"], s["k_p"], ms=18), region(s["a_p_m"], s["a_p_M"],
                                                       s["k_p_m"], s["k_p_M"])]
    for j in range(3):
        el.append({"kind": "trail", "x": ha[j, :n], "y": hk[j, :n],
                   "label": f"Trajetória {j + 1}",
                   "kw": dict(linewidth=3.0, color=tcols[j])})
    el.append({"kind": "trail", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
               "label": "Trajetória Nível 2", "kw": dict(linewidth=3.0, color=(0.7, 0, 0.3))})
    el.append({"kind": "hull", "xs": ha[:, :n], "ys": hk[:, :n], "label": "Fecho Convexo",
               "kw": dict(linewidth=3.0, color=(0.6, 0.6, 0))})
    for j in range(3):
        el.append({"kind": "marker", "x": ha[j, :n], "y": hk[j, :n],
                   "label": rf"$a_{{{j + 1},{sub}}},k_{{{j + 1},{sub}}}$",
                   "kw": dict(marker="*", markersize=18, markeredgewidth=1, color=mcols[j])})
    el.append({"kind": "marker", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
               "label": rf"$a_{{n2,{sub}}},k_{{n2,{sub}}}$",
               "kw": dict(marker="*", markersize=22, markeredgewidth=2, color=(0.5, 0.1, 0.1))})
    return el


def animate(t=30, h=1e-3, save=None, skip=200, interval=50, sim=None):
    """Port of the commented-out animation (axis zoom at 6 s and 10 s)."""
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(
        s["tempo"], three_model_elements(s, "f"), skip=skip, axis0=[0, 9, 0, 12],
        axis_schedule=[(6, [0, 5.5, 0, 6]), (10, [1, 2.5, 1, 5])],
        interval=interval, figsize=(16, 9), save=save)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=200)
    p.add_argument("--interval", type=int, default=50)
    a = p.parse_args(argv)
    an2, kn2, tempo = L2_3M_Filtragem_O1(a.t, a.h)
    print("hat_a_p_n2(end) =", an2[-1], " hat_k_p_n2(end) =", kn2[-1])
    anim = None
    if a.animate or a.save:
        anim = animate(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
