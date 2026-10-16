"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_ModDes_SatAlfa_longA.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

"Long animation" variant: same simulation as L2AA_Dif_Anim.m (adaptive identification
models, saturated differential alpha law with the ``sign(..)==sign(..)`` rule, PE
reference never switched off since eta(k+1) = 1) with a frame every skip = 10/h steps
(one frame per 10 s of simulated time), fixed colors (model trails magenta, plant cyan
'o', initial models red, plant-estimate trail blue, current models triangle with
LineWidth 3) and the segment theta0 -> theta_p.

Porting notes:
- The numerical core is identical to L2AA_Dif_Anim.m and is imported from
  L2AA_Dif_Anim.py (``simulate``); verified against Octave (max rel. err ~1e-15).
- MATLAB returns the getframe ``movie``; here the FuncAnimation (``movie.sim`` holds the
  simulation). ``skip`` defaults to MATLAB's 10/h.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt

from L2AA_Dif_Anim import simulate, frame_steps, animate_runs, _style


def animate(sim, save=None, skip=None, interval=200, ax=None):
    if skip is None:
        skip = 10 / sim['h']
    run = dict(sim=sim, frames=frame_steps(sim['endk'], skip), style=_style(None, 2.0),
               trails=True, theta0=True)
    return animate_runs([run], save=save, interval=interval, ax=ax, hull_lw=3.0)


def L2AA_Dif_ModDes_SatAlfa_longA(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                                  cond_iniciais_m, cond_iniciais_i, alfa0, referencia, Q, gamma, P,
                                  save=None, skip=None, interval=200, ax=None):
    sim = simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                   cond_iniciais_i, alfa0, referencia, Q, gamma, P)
    movie = None
    if sim['planta'].size == 2:
        movie = animate(sim, save=save, skip=skip, interval=interval, ax=ax)
        movie.sim = sim
    return movie


def main():
    ap = argparse.ArgumentParser(description='L2AA_Dif_ModDes_SatAlfa_longA demo')
    ap.add_argument('--animate', action='store_true', help='(default; kept for CLI uniformity)')
    ap.add_argument('--save', default=None, help='save animation to .gif or .mp4')
    ap.add_argument('--stoptime', type=float, default=100)
    ap.add_argument('--h', type=float, default=1e-3)  # h=1e-2 makes this Euler loop diverge
    a = ap.parse_args()
    # header example of the family (with a longer horizon, which is the point of "longA")
    movie = L2AA_Dif_ModDes_SatAlfa_longA(a.stoptime, a.h, [[-4, -3, 8], [-5, -2, -4]], [2.3, -3.6],
                                          [-4, -4], [0, 0], [0.2, 0.3], np.zeros((2, 3)), [0, 1], 5,
                                          np.eye(2) * 1e4, 20, np.eye(2), save=a.save)
    print('theta_p_estimativa(:,end) =', movie.sim['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
