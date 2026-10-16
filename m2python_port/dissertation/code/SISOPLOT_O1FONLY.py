"""Port of dissertation/code/SISOPLOT_O1FONLY.m

Chapter 2 comparison plots, filtered-regression schemes only ("FONLY"): the a_p
estimate (figure 1) and the k_p estimate (figure 2) of level 1 and of level 2 with
N = 3, 4 and 8 models, against the true value and the bounds of the uncertainty
region.  In figure 1 the curves get sparse markers placed with VectorReduction
(semi-transparent scatter) and a legend built from dummy line+marker handles.

Porting notes:
- The parallel / series-parallel inputs (a_pal, a_spal, a_2sp3, k_pal, k_spal,
  k_2sp3) are only used for the length endk = length(a_2sp3) and are never plotted;
  their generating functions are not in the repository, so the port accepts None
  for them (endk is then length(a_2f3)).
- MATLAB ``alpha(p,0.2)`` on the scatter objects -> ``alpha=0.2``; the dummy legend
  lines plotted at (30,50) -> matplotlib Line2D legend handles.
- ``main()`` (no MATLAB counterpart) runs the available Chapter 2 ports with
  t = 30, h = 1e-3 (as Lista_de_Comandos_Ch2) and plots them.
"""
import importlib.util
import os
import sys

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.lines import Line2D

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from VectorReduction import VectorReduction  # noqa: E402


def _load(folder, name):
    path = os.path.join(HERE, folder, name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def SISOPLOT_O1FONLY(a_pal, a_spal, a_f, a_2f3, a_2sp3, a_2f4, a_2f8,
                     k_pal, k_spal, k_f, k_2f3, k_2sp3, k_2f4, k_2f8, tempo_1):
    endk = len(a_2sp3) if a_2sp3 is not None else len(a_2f3)
    tempo_1 = np.asarray(tempo_1)[:endk]
    a_f = np.asarray(a_f)[:endk]
    k_f = np.asarray(k_f)[:endk]
    a_2f3, a_2f4, a_2f8 = (np.asarray(v)[:endk] for v in (a_2f3, a_2f4, a_2f8))
    k_2f3, k_2f4, k_2f8 = (np.asarray(v)[:endk] for v in (k_2f3, k_2f4, k_2f8))

    a_p, a_p_M, a_p_m = 1.5, 4, 0.5
    k_p_M, k_p_m, k_p = 6, 1, 3
    f = 100
    msize = 100
    fs = 20

    fig = plt.figure(1)
    ax = fig.gca()
    handles = []
    for v, ls, mk, lw in [(a_f, "--", "o", 2.0), (a_2f3, "-.", "s", 2.0),
                          (a_2f4, "-", "*", 2.0), (a_2f8, ":", "x", 2.0)]:
        (pl,) = ax.plot(tempo_1, v, linewidth=lw, linestyle=ls)
        c = pl.get_color()
        v1s, v2s = VectorReduction(tempo_1, v, 1.6, 0, 20, a_p_m, a_p_M)
        if mk in ("x", "*"):
            ax.scatter(v1s, v2s, s=msize, marker=mk, linewidths=2, color=c, alpha=0.2)
        else:
            ax.scatter(v1s, v2s, s=msize, marker=mk, linewidths=2, facecolors="none",
                       edgecolors=c, alpha=0.2)
        handles.append(Line2D([], [], linewidth=2.0, linestyle=ls, marker=mk, markersize=8,
                              color=c, markerfacecolor="none"))
    (p5,) = ax.plot(tempo_1[0:endk:f], a_p * np.ones(endk)[0:endk:f], linewidth=1.0,
                    linestyle="-.", color=(0, 0, 0))
    ax.legend(handles + [p5], ["Nível 1 Reg. Linear", "Nível 2 Reg. Lin. N=3",
                               "Nível 2 Reg. Lin. N=4", "Nível 2 Reg. Lin. N=8",
                               "Valor Correto"])
    ax.grid(True)
    ax.set_title(r"a estimativa - a$_p$", fontsize=fs)
    ax.plot(tempo_1, a_p_m * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
    ax.plot(tempo_1, a_p_M * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
    ax.axis([0, 20, a_p_m, a_p_M])
    ax.tick_params(labelsize=fs)

    fig = plt.figure(2)
    ax = fig.gca()
    ax.plot(tempo_1, k_f, linewidth=2.0, linestyle="-.")
    ax.plot(tempo_1, k_2f3, linewidth=3.0, linestyle="-.")
    ax.plot(tempo_1, k_2f4, linewidth=2.0, linestyle="-.")
    ax.plot(tempo_1, k_2f8, linewidth=2.0, linestyle="-.")
    ax.plot(tempo_1, k_p * np.ones(endk), linewidth=1.0, linestyle="-.", color=(0, 0, 0))
    ax.legend(["Nível 1 Reg. Linear", "Nível 2 Reg. Lin. N=3", "Nível 2 Reg. Lin. N=4",
               "Nível 2 Reg. Lin. N=8", "Valor Correto"])
    ax.grid(True)
    ax.set_title(r"k estimativa-k$_p$", fontsize=fs)
    ax.plot(tempo_1, k_p_m * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
    ax.plot(tempo_1, k_p_M * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
    ax.axis([0, 20, k_p_m, k_p_M])
    ax.tick_params(labelsize=fs)


def main():
    folder = "Algoritmos Capítulo 2"
    t, h = 30, 1e-3
    a_f, k_f, _ = _load(folder, "L1_Filtragem_O1").L1_Filtragem_O1(t, h)
    a_2f3, k_2f3, _ = _load(folder, "L2_3M_Filtragem_O1").L2_3M_Filtragem_O1(t, h)
    a_2f4, k_2f4, _ = _load(folder, "L2_4M_Filtragem_O1").L2_4M_Filtragem_O1(t, h)
    a_2f8, k_2f8, tempo = _load(folder, "L2_8M_Filtragem_O1").L2_8M_Filtragem_O1(t, h)
    SISOPLOT_O1FONLY(None, None, a_f, a_2f3, None, a_2f4, a_2f8,
                     None, None, k_f, k_2f3, None, k_2f4, k_2f8, tempo)
    plt.show()


if __name__ == "__main__":
    main()
