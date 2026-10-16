"""Port of dissertation/code/Algoritmos Capítulo 2/L2mod_3M_Filtragem_O1_Figs.m

Figure version of L2mod_3M_Filtragem_O1 (3-model second level with integral
memory terms M, v; step input u = 1; z = -a_p*phi_1 + k_p*phi_2), started from the
weights alfa = (0.5, 0.5, 0).  Plots: (1) z_hat_1..3 and z; (2) hat_a_p_1..3,
hat_a_p_n2 and a_p; (3) the same for k_p; (4) the level-2 trajectory in the
parameter plane drawn with an animatedline loop (no drawnow, skip = 10000);
(5) the identification errors e_1_f..e_3_f.

Porting notes:
- The simulation core is L2mod_3M_Filtragem_O1._simulate with alfa0 = (0.5, 0.5)
  (the two MATLAB loops are otherwise identical).
- Default run draws the 5 static figures; ``--animate`` / ``--save PATH`` play the
  figure-4 animatedline loop as a FuncAnimation.
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import (animate_param_space, final_static_plot, true_point,  # noqa: E402
                         region)
from L2mod_3M_Filtragem_O1 import _simulate as _simulate_mod  # noqa: E402


def _simulate(t, h):
    return _simulate_mod(t, h, alfa0=(0.5, 0.5))


def _elements(s):
    return [
        true_point(s["a_p"], s["k_p"], ms=6),
        region(s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]),
        {"kind": "trail", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"], "label": "Trajetória",
         "kw": dict(linewidth=3.0, color=(0.35, 0.5, 0))},
        {"kind": "marker", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
         "label": r"$a_p,k_p$ Estimados",
         "kw": dict(marker="*", markersize=12, markeredgewidth=1.0, color=(0.2, 0.3, 0.4))},
    ]


def L2mod_3M_Filtragem_O1_Figs(t, h, skip=10000):
    s = _simulate(t, h)
    endk, tempo, tempo_1 = s["endk"], s["tempo"], s["tempo_1"]
    zh, ha, hk = s["z_hat"], s["hat_a_p"], s["hat_k_p"]

    plt.figure(1)
    for j, ls in enumerate(["-.", "--", ":"]):
        plt.plot(tempo, zh[j, :endk], linestyle=ls, linewidth=3.0)
    plt.plot(tempo, s["z"], linewidth=2.0)
    plt.legend(["z estimado 1", "z estimado 2", "z estimado 3", "z"])
    plt.grid(True)

    plt.figure(2)
    for j in range(3):
        plt.plot(tempo_1, ha[j], linewidth=2.0)
    plt.plot(tempo, s["hat_a_p_n2"], linewidth=2.0)
    plt.plot(tempo_1, s["a_p"] * np.ones(endk + 1), linestyle="--", linewidth=2.0)
    plt.legend([r"$a_p$ estimado 1", r"$a_p$ estimado 2", r"$a_p$ estimado 3",
                r"$a_p$ estimado nivel 2", r"$a_p$"])
    plt.grid(True)
    plt.axis([0, 36, 0, 7])

    plt.figure(3)
    for j in range(3):
        plt.plot(tempo_1, hk[j], linewidth=2.0)
    plt.plot(tempo, s["hat_k_p_n2"], linewidth=2.0)
    plt.plot(tempo_1, s["k_p"] * np.ones(endk + 1), linestyle="--", linewidth=2.0)
    plt.legend([r"$k_p$ estimado 1", r"$k_p$ estimado 2", r"$k_p$ estimado 3",
                r"$k_p$ estimado nivel 2", r"$k_p$"])
    plt.axis([0, 36, 0, 7])
    plt.grid(True)

    final_static_plot(tempo, _elements(s), skip=skip, axis0=[0, 5, 0, 7])

    plt.figure(5)
    plt.grid(True)
    for j in range(3):
        plt.plot(tempo, s["e_f"][j], linewidth=2.0, label=rf"$e_{{{j + 1},f}}$")
    plt.plot(tempo, np.zeros(endk), linestyle="--", linewidth=2.0)
    plt.legend()
    return s


def animate(t=30, h=1e-3, save=None, skip=10000, interval=500, sim=None):
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(s["tempo"], _elements(s), skip=skip, axis0=[0, 5, 0, 7],
                               interval=interval, save=save)


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
        L2mod_3M_Filtragem_O1_Figs(a.t, a.h, skip=a.skip)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
