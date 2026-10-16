"""Port of dissertation/code/Algoritmos Capítulo 2/L1_Filtragem_O1.m

First-level (single model) identification of a first-order plant
dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3, u = sin(t)) by the filtered linear
regression ("Filtragem") model z = y - lambda*phi_1 = -a_p*phi_1 + k_p*phi_2, with
phi_1, phi_2 the outputs of 1/(s+lambda) driven by y and u.  The estimates are
updated by the gradient law  d(hat_a_p)/dt = e_1_f*y,  d(hat_k_p)/dt = -e_1_f*u.
Everything is integrated with forward Euler, step h.  Lyapunov-like functions are
also computed (not returned, kept in the simulation dict).

The MATLAB file contains two commented-out animatedline animations of the estimate
(hat_a_p, hat_k_p) moving inside the uncertainty region; both are ported in
``animate`` (``variant=1``: figure with the initial estimate and axis equal to the
uncertainty region, ``variant=2``: the gif version 'L1_Filtragem_O1_Anim_cmp.gif'
with axis [0 5 0 7]).

Porting notes:
- Outputs keep MATLAB lengths: hat_a_p, hat_k_p and tempo_1 have endk+1 samples
  (tempo_1[0] = 0 because MATLAB never assigns tempo_1(1)).
- The animation was commented out in MATLAB: the default run does not animate;
  use ``--animate`` (and ``--save file.gif|mp4``).  ``gif(...)`` (File Exchange) ->
  ``--save``.
- The commented-out error/time plots are not ported.
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
    a_p = 1.5
    k_p = 3
    lam = 2.2261
    y = np.zeros(endk + 1); y[0] = 0.2
    phi_1 = np.zeros(endk + 1); phi_1[0] = 0.2
    phi_2 = np.zeros(endk + 1)
    hat_a_p = np.zeros(endk + 1); hat_a_p[0] = 0.5
    hat_k_p = np.zeros(endk + 1); hat_k_p[0] = 6
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); z_hat = np.zeros(endk); e_1_f = np.zeros(endk)
    lyap1 = np.zeros(endk)
    lyap1v = np.zeros(endk + 1); lyap2v = np.zeros(endk + 1)
    # initial values (before the loop)
    tilde_kp1 = hat_k_p[0] - k_p
    tilde_ap1 = hat_a_p[0] - a_p
    z0 = y[0] - lam * phi_1[0]
    zh0 = -hat_a_p[0] * phi_1[0] + hat_k_p[0] * phi_2[0]
    e0 = z0 - zh0
    lyap1v[0] = (e0 ** 2 + tilde_kp1 ** 2 + tilde_ap1 ** 2) * 0.5
    lyap2v[0] = lyap1v[0]
    for i in range(endk):  # i = k-1
        k = i + 1
        u[i] = np.sin(h * k)
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        dot_y = -a_p * y[i] + k_p * u[i]
        y[i + 1] = y[i] + h * dot_y
        phi_1[i + 1] = phi_1[i] + h * (-lam * phi_1[i] + y[i])
        phi_2[i + 1] = phi_2[i] + h * (-lam * phi_2[i] + u[i])
        z[i] = y[i] - lam * phi_1[i]
        z_hat[i] = -hat_a_p[i] * phi_1[i] + hat_k_p[i] * phi_2[i]
        e_1_f[i] = z_hat[i] - z[i]
        hat_a_p[i + 1] = hat_a_p[i] + h * (e_1_f[i] * y[i])
        hat_k_p[i + 1] = hat_k_p[i] + h * (-e_1_f[i] * u[i])
        vy = y[i] * phi_1[i]
        vu = u[i] * phi_2[i]
        tilde_kp1 = hat_k_p[i] - k_p
        tilde_ap1 = hat_a_p[i] - a_p
        lyap1[i] = (e_1_f[i] ** 2 + tilde_kp1 ** 2 + tilde_ap1 ** 2) * 0.5
        lyap1v[i + 1] = lyap1v[i] + h * (-(lam + vy + vu) * e_1_f[i] ** 2)
        lyap2v[i + 1] = lyap2v[i] + h * (-lam * e_1_f[i] ** 2)
    return dict(endk=endk, y=y, u=u, tempo=tempo, tempo_1=tempo_1, phi_1=phi_1,
                phi_2=phi_2, z=z, z_hat=z_hat, e_1_f=e_1_f, hat_a_p=hat_a_p,
                hat_k_p=hat_k_p, lyap1=lyap1, lyap1v=lyap1v, lyap2v=lyap2v,
                a_p=a_p, k_p=k_p, a_p_M=4, a_p_m=0.5, k_p_M=6, k_p_m=1)


def L1_Filtragem_O1(t, h):
    """[hat_a_p, hat_k_p, tempo_1] = L1_Filtragem_O1(t,h)"""
    s = _simulate(t, h)
    return s["hat_a_p"], s["hat_k_p"], s["tempo_1"]


def animate(t=30, h=1e-3, save=None, skip=10000, interval=500, variant=2, sim=None):
    """Port of the commented-out animatedline animations (see module docstring)."""
    s = sim if sim is not None else _simulate(t, h)
    trail = {"kind": "trail", "x": s["hat_a_p"], "y": s["hat_k_p"], "label": "Trajetória",
             "kw": dict(linewidth=3.0, color=(0.35, 0.5, 0), linestyle="-")}
    mark = {"kind": "marker", "x": s["hat_a_p"], "y": s["hat_k_p"],
            "label": r"$a_p,k_p$ Estimados",
            "kw": dict(marker="*", markersize=12, markeredgewidth=1.0, color=(0.2, 0.3, 0.4))}
    reg = region(s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"])
    tp = true_point(s["a_p"], s["k_p"], ms=6)
    if variant == 1:
        init = {"kind": "static", "x": [0.5], "y": [6], "label": "Estimativas Iniciais",
                "kw": dict(marker="*", markeredgewidth=3.0, color=(0.5, 0, 0.5),
                           linestyle="none")}
        elements = [init, tp, reg, trail, mark]
        axis0 = [s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]]
        title, fs = "Modelo por Regressão Linear", 20
    else:
        elements = [tp, reg, trail, mark]
        axis0 = [0, 5, 0, 7]
        title, fs = None, None
    return animate_param_space(s["tempo"], elements, skip=skip, axis0=axis0,
                               interval=interval, title=title, fontsize=fs, save=save)


def main(argv=None):
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--t", type=float, default=30.0)
    p.add_argument("--h", type=float, default=1e-3)
    p.add_argument("--animate", action="store_true")
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=10000)
    p.add_argument("--interval", type=int, default=500)
    p.add_argument("--variant", type=int, default=2, choices=[1, 2])
    a = p.parse_args(argv)
    hat_a_p, hat_k_p, tempo_1 = L1_Filtragem_O1(a.t, a.h)
    print("hat_a_p(end) =", hat_a_p[-1], " hat_k_p(end) =", hat_k_p[-1])
    anim = None
    if a.animate or a.save:
        anim = animate(a.t, a.h, save=a.save, skip=a.skip, interval=a.interval,
                       variant=a.variant)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
