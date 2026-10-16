"""Port of dissertation/code/Algoritmos Capítulo 2/L2_4M_Filtragem_O1.m

Second-level adaptation with N = 4 identification models placed at the corners of
the uncertainty region [0.5, 4] x [1, 6] for the plant dy/dt = -a_p*y + k_p*u
(a_p = 1.5, k_p = 3, u = sin(t)).  Filtered linear regression with algebraic model
outputs z_hat_i = -phi_1*hat_a_p_i + phi_2*hat_k_p_i, first-level gradient laws,
and second-level weights alfa (3 free weights, alfa_4 = 1 - alfa_1 - alfa_2 -
alfa_3) driven by dalfa/dt = -E_f'E_f*alfa - E_f'*e_4_f.  The combined estimate
theta_n2 = sum_i alfa_i*theta_i is returned.  Forward Euler, step h.

The commented-out MATLAB animation (ported in ``animate``) shows the level-2
trajectory, the polygon formed by the 4 model estimates (convex hull, yellow) and
markers, skip = 2000, axis [0 5 0 7].

Porting notes:
- Outputs hat_a_p_n2, hat_k_p_n2, tempo with endk samples.
- Animation commented out in MATLAB: default run does not animate; ``--animate`` /
  ``--save PATH``.
- Bugs in the MATLAB animation: the per-model markers were re-added at the
  *initial* estimates (hat_a_p(i,1)) every frame, so they never moved, and the
  legend had 11 strings for 9 objects (labels shifted, '_sp' subscripts copied from
  the series-parallel version).  The port moves the markers with the estimates
  (pass ``faithful_markers=True`` for the frozen MATLAB behaviour) and labels the
  objects correctly.  The hull line got [theta_1 theta_1..theta_4 theta_1] with
  MaximumNumPoints = 5, i.e. the closed polygon 1-2-3-4-1, which is what is drawn.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import animate_param_space, true_point, region  # noqa: E402

THETA0_4M = ([0.5, 4, 4, 0.5], [1, 1, 6, 6])


def _simulate(t, h):
    endk = int(np.floor(t / h + 1e-9))
    N = 4
    a_p, k_p, lam = 1.5, 3, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    ha = np.zeros((N, endk + 1)); hk = np.zeros((N, endk + 1))
    ha[:, 0], hk[:, 0] = THETA0_4M
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
        alfa_N[i + 1] = 1 - alfa[0, i + 1] - alfa[1, i + 1] - alfa[2, i + 1]
        w = np.r_[alfa[:, i], alfa_N[i]]
        hat_a_p_n2[i] = w @ ha[:, i]
        hat_k_p_n2[i] = w @ hk[:, i]
    return dict(endk=endk, N=N, y=y, u=u, tempo=tempo, tempo_1=tempo_1, z=z, z_hat=zh,
                e_f=e, hat_a_p=ha, hat_k_p=hk, alfa=alfa, alfa_N=alfa_N,
                hat_a_p_n2=hat_a_p_n2, hat_k_p_n2=hat_k_p_n2, a_p=a_p, k_p=k_p,
                a_p_M=4, a_p_m=0.5, k_p_M=6, k_p_m=1)


def L2_4M_Filtragem_O1(t, h):
    """[hat_a_p_n2, hat_k_p_n2, tempo] = L2_4M_Filtragem_O1(t,h)"""
    s = _simulate(t, h)
    return s["hat_a_p_n2"], s["hat_k_p_n2"], s["tempo"]


def n_model_elements(s, faithful_markers=False):
    """Elements of the N-model animation (shared with L2_8M_Filtragem_O1)."""
    n = len(s["tempo"])
    ha, hk = s["hat_a_p"][:, :n], s["hat_k_p"][:, :n]
    el = [true_point(s["a_p"], s["k_p"], ms=18),
          region(s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"])]
    for i in range(s["N"]):
        kw = dict(marker="*", markersize=6, markeredgewidth=1, color=(0.7, 0, 0))
        lab = r"$a_{i,f},k_{i,f}$" if i == 0 else None
        if faithful_markers:
            el.append({"kind": "static", "x": [ha[i, 0]], "y": [hk[i, 0]], "label": lab,
                       "kw": dict(kw, linestyle="none")})
        else:
            el.append({"kind": "marker", "x": ha[i], "y": hk[i], "label": lab, "kw": kw})
    el.append({"kind": "trail", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
               "label": "Trajetória Nível 2", "kw": dict(linewidth=3.0, color=(0.7, 0, 0.3))})
    el.append({"kind": "hull", "xs": ha, "ys": hk, "label": "Fecho Convexo",
               "kw": dict(linewidth=3.0, color="yellow")})
    el.append({"kind": "marker", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
               "label": r"$a_{n2,f},k_{n2,f}$",
               "kw": dict(marker="*", markersize=22, markeredgewidth=2, color=(0.5, 0.1, 0.1))})
    return el


def animate(t=30, h=1e-3, save=None, skip=2000, interval=200, sim=None,
            faithful_markers=False):
    """Port of the commented-out animation (loop from k = 2, skip = 2000)."""
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(s["tempo"], n_model_elements(s, faithful_markers),
                               skip=skip, axis0=[0, 5, 0, 7], interval=interval,
                               figsize=(16, 9), k_start=2, save=save)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=2000)
    p.add_argument("--interval", type=int, default=200)
    p.add_argument("--faithful-markers", action="store_true")
    a = p.parse_args(argv)
    an2, kn2, tempo = L2_4M_Filtragem_O1(a.t, a.h)
    print("hat_a_p_n2(end) =", an2[-1], " hat_k_p_n2(end) =", kn2[-1])
    anim = None
    if a.animate or a.save:
        anim = animate(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval,
                       faithful_markers=a.faithful_markers)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
