"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_ModDes_SatAlfa_theAnimation.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

First animation version: same adaptive-identification-model simulation as
L2AA_Dif_Anim.m, but the saturation rule zeroes alpha_dot_j when
``sign(alpha_dot_{n+1}) ~= sign(alpha_dot_j)`` (as in L2AA_Dif_ModDes_SatAlfa.m), and a
frame is grabbed at EVERY step: current models triangle (animatedline, LineWidth 3),
plant point (cyan 'o'), initial models (red) and the trail of the plant estimate
theta_p_hat = THETA_BARRA*alpha_bar (blue). No per-model trails, no theta0 segment.

Porting notes:
- Numerical core imported from L2AA_Dif_Anim.py with ``sat_rule='ne'``; verified against
  Octave (max rel. err ~1e-15).
- MATLAB grabs one frame per step (18000 for the header example); the port subsamples
  with ``skip`` (default: endk/240 rounded, i.e. ~240 frames). Use skip=1 for every step.
- Returns the FuncAnimation (``movie``); simulation in ``movie.sim``.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt

from L2AA_Dif_Anim import simulate, frame_steps, animate_runs, _style


def animate(sim, save=None, skip=None, interval=50, ax=None):
    if skip is None:
        skip = max(1, int(round(sim['endk'] / 240)))
    run = dict(sim=sim, frames=frame_steps(sim['endk'], skip), style=_style(None, 2.0),
               trails=False, theta0=False)
    return animate_runs([run], save=save, interval=interval, ax=ax, hull_lw=3.0)


def L2AA_Dif_ModDes_SatAlfa_theAnimation(stoptime, h, modelos, planta, modelo_de_referencia,
                                         cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0,
                                         referencia, Q, gamma, P, save=None, skip=None, interval=50,
                                         ax=None):
    sim = simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                   cond_iniciais_i, alfa0, referencia, Q, gamma, P, sat_rule='ne')
    movie = None
    if sim['planta'].size == 2:
        movie = animate(sim, save=save, skip=skip, interval=interval, ax=ax)
        movie.sim = sim
    return movie


def main():
    ap = argparse.ArgumentParser(description='L2AA_Dif_ModDes_SatAlfa_theAnimation demo')
    ap.add_argument('--animate', action='store_true', help='(default; kept for CLI uniformity)')
    ap.add_argument('--save', default=None, help='save animation to .gif or .mp4')
    ap.add_argument('--skip', type=int, default=None)
    a = ap.parse_args()
    # header example: L2AA_Dif_ModDes_SatAlfa(18,1e-3,[-4 -3 8; -5 -2 -4], [2.3; -3.6], ...)
    movie = L2AA_Dif_ModDes_SatAlfa_theAnimation(18, 1e-3, [[-4, -3, 8], [-5, -2, -4]], [2.3, -3.6],
                                                 [-4, -4], [0, 0], [0.2, 0.3], np.zeros((2, 3)), [0, 1], 5,
                                                 np.eye(2) * 1e4, 20, np.eye(2), save=a.save, skip=a.skip)
    print('theta_p_estimativa(:,end) =', movie.sim['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
