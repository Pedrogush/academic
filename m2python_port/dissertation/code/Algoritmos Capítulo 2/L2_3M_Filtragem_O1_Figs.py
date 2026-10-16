"""Port of dissertation/code/Algoritmos Capítulo 2/L2_3M_Filtragem_O1_Figs.m

Figure version of the 3-model second-level identification (filtered linear
regression with algebraic model outputs z_hat_i = -phi_1*hat_a_p_i +
phi_2*hat_k_p_i) of dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3, u = sin(t)).
After the Euler simulation it draws, with an animatedline loop, the trajectory of
the second-level estimate (hat_a_p_n2, hat_k_p_n2) inside the uncertainty region,
with the current-estimate marker updated every skip = 10000 steps and the legend
title showing the time.

Porting notes:
- In MATLAB the loop has no drawnow, so what is seen is the final figure; the
  default run reproduces that static figure (``L2_3M_Filtragem_O1_Figs``) and
  ``--animate`` / ``--save`` play the same loop as a FuncAnimation (``animate``).
- The 'Estimativas Iniciais' marker is plotted at (0.5, 6) as in MATLAB (it is not
  the actual initial level-2 estimate).
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _param_anim import (animate_param_space, final_static_plot, true_point,  # noqa: E402
                         region)
from L2_3M_Filtragem_O1_DEFESA import _simulate  # noqa: E402  (identical core loop)


def _elements(s):
    return [
        {"kind": "static", "x": [0.5], "y": [6], "label": "Estimativas Iniciais",
         "kw": dict(marker="*", markeredgewidth=3.0, color=(0.5, 0, 0.5), linestyle="none")},
        true_point(s["a_p"], s["k_p"], ms=6),
        region(s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]),
        {"kind": "trail", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"], "label": "Trajetória",
         "kw": dict(linewidth=3.0, color=(0.35, 0.5, 0))},
        {"kind": "marker", "x": s["hat_a_p_n2"], "y": s["hat_k_p_n2"],
         "label": r"$a_p,k_p$ Estimados",
         "kw": dict(marker="*", markersize=12, markeredgewidth=1.0, color=(0.2, 0.3, 0.4))},
    ]


def L2_3M_Filtragem_O1_Figs(t, h, skip=10000):
    """Simulate and draw the final figure (MATLAB figure(1)). Returns (fig, ax)."""
    s = _simulate(t, h)
    return final_static_plot(s["tempo"], _elements(s), skip=skip,
                             axis0=[s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]],
                             title="3 Modelos por Regressão Linear ", fontsize=20)


def animate(t=30, h=1e-3, save=None, skip=10000, interval=500, sim=None):
    s = sim if sim is not None else _simulate(t, h)
    return animate_param_space(s["tempo"], _elements(s), skip=skip,
                               axis0=[s["a_p_m"], s["a_p_M"], s["k_p_m"], s["k_p_M"]],
                               title="3 Modelos por Regressão Linear ", fontsize=20,
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
        L2_3M_Filtragem_O1_Figs(a.t, a.h, skip=a.skip)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
