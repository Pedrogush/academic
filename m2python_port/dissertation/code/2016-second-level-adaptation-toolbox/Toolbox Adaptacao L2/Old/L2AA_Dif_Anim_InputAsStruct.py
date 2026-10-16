"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_Anim_InputAsStruct.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Same simulation and parameter-convergence animation as L2AA_Dif_Anim.m (adaptive
identification models + saturated differential alpha law, PE reference always on), but
all inputs are given as one struct ``args`` with fields stoptime, h, modelos, planta,
modelo_de_referencia, cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0, referencia,
Q, gamma, P, cor. Frames every skip = stoptime/(240 h) steps, colors from ``cor``.

Porting notes:
- ``args`` may be a dict or any object with those attributes (e.g. SimpleNamespace).
- The numerical core is byte-for-byte the same as L2AA_Dif_Anim.m (only A_p/A_m are built
  with the nested ``can`` instead of the explicit loop - identical result), so it is
  imported from L2AA_Dif_Anim.py (``simulate``, ``animate``); verified against Octave there.
- Unlike L2AA_Dif_Anim.m, this file indexes ``movie(k/skip)`` (integer), so the MATLAB
  movie works here. Returns the FuncAnimation (``movie``), simulation in ``movie.sim``.
"""
import argparse
from types import SimpleNamespace

import numpy as np
import matplotlib.pyplot as plt

from L2AA_Dif_Anim import simulate, animate


def L2AA_Dif_Anim_InputAsStruct(args, save=None, skip=None, interval=50, ax=None):
    if isinstance(args, dict):
        args = SimpleNamespace(**args)
    sim = simulate(args.stoptime, args.h, args.modelos, args.planta, args.modelo_de_referencia,
                   args.cond_iniciais_p, args.cond_iniciais_m, args.cond_iniciais_i, args.alfa0,
                   args.referencia, args.Q, args.gamma, args.P)
    movie = None
    if np.asarray(args.planta).size == 2:
        movie = animate(sim, cor=args.cor, save=save, skip=skip, interval=interval, ax=ax)
        movie.sim = sim
    return movie


def main():
    ap = argparse.ArgumentParser(description='L2AA_Dif_Anim_InputAsStruct demo')
    ap.add_argument('--animate', action='store_true', help='(default; kept for CLI uniformity)')
    ap.add_argument('--save', default=None, help='save animation to .gif or .mp4')
    ap.add_argument('--stoptime', type=float, default=900)
    a = ap.parse_args()
    # same parameters as genfigure.m (c = 1)
    args = dict(stoptime=a.stoptime, h=0.5e-1,
                modelos=[[1.5, 3.5, 2.5 + np.cos(np.pi / 180)], [-3, -3, -3 + np.sin(np.pi / 180)]],
                planta=[2.5, -3], modelo_de_referencia=[-4, -4], cond_iniciais_p=[0, 0],
                cond_iniciais_m=[0.2, 0.3], cond_iniciais_i=[[0, 0, 0], [0, 0, 0]], alfa0=[0, 0],
                referencia=5, Q=[[1e4, 0], [0, 1e4]], gamma=100, P=[[1, 0], [0, 1]],
                cor=abs(np.cos(0)))
    movie = L2AA_Dif_Anim_InputAsStruct(args, save=a.save)
    print('theta_p_estimativa(:,end) =', movie.sim['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
