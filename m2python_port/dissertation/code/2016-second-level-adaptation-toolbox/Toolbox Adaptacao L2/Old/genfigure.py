"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/genfigure.m

Script that calls L2AA_Dif_Anim twice (c = 1 and c = 91, step 90 up to 180) on the same
axes: the third identification model is placed on a circle of radius r around (2.5, -3)
at angle c degrees, and the color parameter ``cor = |cos(floor(c/60))|`` distinguishes
the runs. Each run animates the convergence of the three adaptive identification models
and of the plant estimate towards the plant theta_p = (2.5, -3) over 900 s (h = 0.05).

Porting notes:
- The two runs are simulated with L2AA_Dif_Anim.simulate and played one after the other
  in a single FuncAnimation on the same axes (earlier run stays drawn, as with MATLAB's
  persistent lines). Frames every stoptime/(240 h) = 75 steps, as in L2AA_Dif_Anim.m.
- In MATLAB, genfigure.m would actually stop at the first frame because
  L2AA_Dif_Anim.m indexes ``movie(0.5*k/skip)`` = movie(0.5) (see L2AA_Dif_Anim.py).
- The animation is not commented out in MATLAB, so it is built by default; ``--save PATH``
  writes a .gif/.mp4, ``--stoptime`` shortens the runs for quick tests.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt

from L2AA_Dif_Anim import simulate, frame_steps, animate_runs, _style


def main():
    ap = argparse.ArgumentParser(description='genfigure: two L2AA_Dif_Anim runs on one axes')
    ap.add_argument('--animate', action='store_true', help='(default; kept for CLI uniformity)')
    ap.add_argument('--save', default=None, help='save animation to .gif or .mp4')
    ap.add_argument('--stoptime', type=float, default=900)
    ap.add_argument('--interval', type=int, default=50)
    a = ap.parse_args()
    stoptime, h = a.stoptime, 0.5e-1
    runs = []
    for c in range(1, 181, 90):
        angulo = c * np.pi / 180
        r = (20 - np.floor(c / 360)) / 20
        cor = abs(np.cos(np.floor(c / 60)))
        sim = simulate(stoptime, h, [[1.5, 3.5, 2.5 + r * np.cos(angulo)], [-3, -3, -3 + r * np.sin(angulo)]],
                       [2.5, -3], [-4, -4], [0, 0], [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 0], 5,
                       [[1e4, 0], [0, 1e4]], 100, [[1, 0], [0, 1]])
        print(f'c = {c}: theta_p_estimativa(:,end) = {sim["theta_p_estimativa"][:, -1]}')
        skip = stoptime / (240 * h)
        runs.append(dict(sim=sim, frames=frame_steps(sim['endk'], skip), style=_style(cor, 1.0),
                         trails=True, theta0=True))
    anim = animate_runs(runs, save=a.save, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
