"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/exemplos.m

Example script of the toolbox: "simulação 1, referente ao artigo enviado para o CBA"
(second-order plant theta* = [2.3; -3.6], identification models [-4 -3 8; -5 -2 -4],
reference model [-4 -4], 18 s, h = 1e-3). It animates the parameter-estimate trajectories
(anim_trajetorias with L2AA), then plots the variables of interest with conventional
(L1A) and with second-level (L2AA) adaptation using plot_adap_figures. A second parameter
set SIM2 (90 s, h = 5e-2, gamma 100, P = 4I) is defined but not used.

Porting notes:
- SIM1/SIM2 were written for an OLDER toolbox interface (15 fields: stoptime, h, modelos,
  planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m, cond_iniciais_i, alfa0,
  referencia, Q, gamma, P, cor, nframes, read by name). The current L2AA/L1A unpack their
  argument POSITIONALLY with 18/17 fields (t_0, t_final, ... / stoptime, ..., ref_amp,
  ref_freq, tol_eta, tau_ref), so in MATLAB this script errors at the first call. To make
  the example runnable, the port converts SIM1 to those layouts (``_args_L2AA``,
  ``_args_L1A``) keeping all of SIM1's values and taking the reference/PE switch-off
  settings missing from SIM1 from the CBA parameter file param_sim_CBA.mat
  (ref_amp = [1 .4 .3], ref_freq = [0 .5 2], tol_eta = 1e-2, tau_ref = 10). cor and
  nframes are kept for anim_trajetorias.
- plot_adap_figures.m is not in this folder; it is imported from the port of
  papers/2016-cba-second-level-adaptation-pe-switch-off/code/plot_adap_figures.py (it was on
  the MATLAB path). Both calls draw into the same figures 1-7, as in MATLAB.
- ``pause`` (wait for a key) is skipped.
- The animation is active in the original, so it runs by default; ``--save PATH`` writes it
  (.gif/.mp4), ``--no-animate`` skips it, ``--skip N`` overrides the frame step.
"""
import argparse
import importlib.util
import os
import sys

import numpy as np
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from anim_trajetorias import anim_trajetorias  # noqa: E402
from convert_struct import Struct  # noqa: E402
from L1A import L1A  # noqa: E402
from L2AA import L2AA  # noqa: E402


def _import_plot_adap_figures():
    root = HERE[:HERE.index(os.sep + "dissertation" + os.sep)]
    path = os.path.join(root, "papers", "2016-cba-second-level-adaptation-pe-switch-off",
                        "code", "plot_adap_figures.py")
    spec = importlib.util.spec_from_file_location("plot_adap_figures_cba", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.plot_adap_figures


# settings missing from the old SIM structs (from papers/.../param_sim_CBA.mat)
_REF = dict(ref_amp=np.array([1.0, 0.4, 0.3]), ref_freq=np.array([0.0, 0.5, 2.0]),
            tol_eta=1e-2, tau_ref=10.0)


def _args_L2AA(S):
    return Struct(t_0=0.0, t_final=S.stoptime, h=S.h, modelos=S.modelos, planta=S.planta,
                  modelo_ref=S.modelo_de_referencia, cond_iniciais_p=S.cond_iniciais_p,
                  cond_iniciais_m=S.cond_iniciais_m, cond_iniciais_i=S.cond_iniciais_i,
                  alfa_0=S.alfa0, Q=S.Q, gamma=S.gamma, P=S.P, not_used=np.nan, **_REF,
                  stoptime=S.stoptime, cor=S.cor, nframes=S.nframes)


def _args_L1A(S):
    return Struct(stoptime=S.stoptime, h=S.h, modelos=S.modelos, planta=S.planta,
                  modelo_de_referencia=S.modelo_de_referencia,
                  cond_iniciais_p=S.cond_iniciais_p, cond_iniciais_m=S.cond_iniciais_m,
                  cond_iniciais_i=S.cond_iniciais_i, alfa0=S.alfa0, Q=S.Q, gamma=S.gamma,
                  P=S.P, cor=S.cor, **_REF)


def main(argv=None):
    p = argparse.ArgumentParser(description="Toolbox L2 examples (exemplos.m)")
    p.add_argument("--no-animate", action="store_true")
    p.add_argument("--animate", action="store_true", help="(default) run the animation")
    p.add_argument("--save", default=None, help="save the animation (.gif/.mp4)")
    p.add_argument("--skip", type=int, default=None)
    a = p.parse_args(argv)
    plot_adap_figures = _import_plot_adap_figures()

    # simulação 1, referente ao artigo
    print("simulação 1, referente ao artigo enviado para o CBA")
    SIM1 = Struct(stoptime=18, h=1e-3, modelos=np.array([[-4, -3, 8], [-5, -2, -4]], float),
                  planta=np.array([2.3, -3.6]), modelo_de_referencia=np.array([-4.0, -4.0]),
                  cond_iniciais_p=np.array([0.0, 0.0]), cond_iniciais_m=np.array([0.2, 0.3]),
                  cond_iniciais_i=np.zeros((2, 3)), alfa0=np.array([0.0, 1.0]), referencia=5,
                  Q=np.diag([1e4, 1e4]), gamma=10, P=np.diag([100.0, 100.0]), cor=0.2,
                  nframes=40)
    anim = None
    if not a.no_animate:
        print("trajetórias das estimativas dos parâmetros")
        anim = anim_trajetorias(L2AA, _args_L2AA(SIM1), save=a.save, skip=a.skip)

    print("variáveis de interesse usando adaptação convencional")
    plot_adap_figures(L1A(_args_L1A(SIM1)))
    print("variáveis de interesse usando adaptação de segundo nível")
    plot_adap_figures(L2AA(_args_L2AA(SIM1)))

    # simulação 2, referente ao artigo (definida mas não usada no original)
    SIM2 = Struct(stoptime=90, h=5e-2, modelos=np.array([[-4, -3, 8], [-5, -2, -4]], float),  # noqa: F841
                  planta=np.array([2.3, -3.6]), modelo_de_referencia=np.array([-4.0, -4.0]),
                  cond_iniciais_p=np.array([0.0, 0.0]), cond_iniciais_m=np.array([0.2, 0.3]),
                  cond_iniciais_i=np.zeros((2, 3)), alfa0=np.array([0.0, 1.0]), referencia=5,
                  Q=np.diag([1e4, 1e4]), gamma=100, P=np.diag([4.0, 4.0]), cor=0.2, nframes=40)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
