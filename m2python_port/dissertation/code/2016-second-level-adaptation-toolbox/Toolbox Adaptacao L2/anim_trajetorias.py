"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/anim_trajetorias.m

Animation of the parameter-estimate convergence of second-level adaptation in the 2-D
parameter plane (second-order plants). ``anim_trajetorias(func, args)`` runs the
simulation ``estrutura = func(args)`` (func = L2AA, L2AA_CL, L1A, ... from this toolbox)
and animates, every ``skip`` integration steps:
- the CURRENT convex hull of the n+1 identification models (thick line, colour
  [0.35 0.5 0]; MATLAB animatedline with MaximumNumPoints=4, i.e. only the current closed
  triangle is visible);
- the trails of each identification model theta_i(t) (thin lines, [1-cor cor 1-cor]);
- the trajectory of the plant-parameter estimate theta_p_hat = THETA_BARRA*alfa_barra
  ([cor cor 1-cor]) plus a marker on its current value (marker added in the port);
- static elements: theta* (plant, marker 'o', [cor 1-cor 1-cor]), the straight segment
  theta_0 -> theta*, and the initial hull ``args.modelos`` ([1-cor cor cor]).
The legend title shows the simulation time "N Segundos" (added in the port); the axes
autoscale as data are added, like MATLAB's line() calls.

Python API:
- ``anim_trajetorias(func, args, save=None, skip=None, interval=100)`` -> FuncAnimation
- ``animate(estrutura, args, save=None, skip=None, interval=100)`` -> FuncAnimation, to
  animate an already-computed output struct (any of L1A/L2AA/L2AA_CL/L2A_sem_zeros_IO).
``save``: path ending in .gif (PillowWriter) or .mp4/.avi (FFMpegWriter).

Porting notes:
- Frame selection reproduces MATLAB: skip = stoptime/(nframes*h) and a frame is drawn at
  every step k with floor(k/skip)==ceil(k/skip). An explicit integer ``skip`` overrides it.
- MATLAB reads args.stoptime, args.nframes and args.cor, which only exist in the OLD
  15/17-field structs (see exemplos.m); the current L2AA args (t_0, t_final, ...) have no
  stoptime/nframes/cor, so in MATLAB ``anim_trajetorias(@L2AA, Parameters)`` errors. The
  port falls back to stoptime = t_final - t_0 (or tempo(end)), nframes = 40, cor = 0.2 so
  that L2AA / L2AA_CL / L1A outputs can drive it. (L2A.m is an unfinished draft that
  cannot run, see L2A.py.)
- The MATLAB code opened VideoWriter('testavi.avi') and called ``addframe`` on it (an
  avifile API, invalid for VideoWriter) and never closed it; here video output is only
  written when ``save`` is given.
- Nothing is drawn when the plant is not second order (as in MATLAB); returns None then.

CLI: python anim_trajetorias.py [--params MAT --var NAME] [--func L2AA|L2AA_CL]
     [--save out.gif] [--skip N] [--interval MS]
(default parameters: papers/2016-cba-second-level-adaptation-pe-switch-off/code/CBA1.mat,
struct ``Parameters``).
"""
import argparse
import os
import sys

import numpy as np
import matplotlib.pyplot as plt
from matplotlib import animation

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def _get(s, name, default=None):
    if isinstance(s, dict):
        return s.get(name, default)
    return getattr(s, name, default)


def _frames_matlab(endk, stoptime, nframes, h):
    skip = stoptime / (nframes * h)
    return [k for k in range(1, endk + 1) if np.floor(k / skip) == np.ceil(k / skip)]


def animate(estrutura, args, save=None, skip=None, interval=100):
    """Animate the parameter trajectories stored in ``estrutura`` (see module doc)."""
    theta_BARRA = np.asarray(_get(estrutura, "theta_BARRA"), dtype=float)
    alfa_barra = np.asarray(_get(estrutura, "alfa_barra"), dtype=float)
    tpe = np.asarray(_get(estrutura, "theta_p_estimativa"), dtype=float)
    tempo = np.asarray(_get(estrutura, "tempo"), dtype=float)
    endk = int(_get(estrutura, "endk"))

    planta = _get(args, "planta", None)
    planta = np.ravel(np.asarray(planta if planta is not None else _get(estrutura, "planta"), dtype=float))
    modelos = _get(args, "modelos", None)
    modelos = np.atleast_2d(np.asarray(modelos if modelos is not None else _get(estrutura, "modelos"), dtype=float))
    h = float(_get(args, "h", tempo[1] - tempo[0]))
    stoptime = _get(args, "stoptime", None)
    if stoptime is None:
        if _get(args, "t_final", None) is not None and _get(args, "t_0", None) is not None:
            stoptime = float(_get(args, "t_final")) - float(_get(args, "t_0"))
        else:
            stoptime = float(tempo[-1])
    nframes = float(_get(args, "nframes", 40))
    cor = float(_get(args, "cor", 0.2))

    if len(planta) != 2:
        print("anim_trajetorias: planta não é de segunda ordem, nada a animar.")
        return None

    if skip is None:
        ks = _frames_matlab(endk, float(stoptime), nframes, h)
    else:
        ks = list(range(int(skip), endk + 1, int(skip)))
    if not ks:
        ks = [endk]

    theta0 = theta_BARRA[:, :, 0] @ alfa_barra[:, 0]
    L = theta_BARRA.shape[1]

    fig, ax = plt.subplots()
    ax.grid(True)
    ax.set_xlabel(r"$\theta_1$")
    ax.set_ylabel(r"$\theta_2$")
    ax.set_title("Trajetória dos Parâmetros")

    # elementos estáticos
    s, = ax.plot(planta[0], planta[1], color=[cor, 1 - cor, 1 - cor], linewidth=1.0,
                 marker="o", linestyle="none", label=r"$\theta^*$ (planta)")
    ax.plot([theta0[0], planta[0]], [theta0[1], planta[1]], linewidth=0.5,
            label=r"$\theta_0 \rightarrow \theta^*$")
    ax.plot(np.r_[modelos[0, :], modelos[0, 0]], np.r_[modelos[1, :], modelos[1, 0]],
            color=[1 - cor, cor, cor], linewidth=1.0, label="Fecho inicial")
    # elementos animados
    trails = []
    for j in range(L):
        ln, = ax.plot([], [], color=[1 - cor, cor, 1 - cor], linewidth=0.6,
                      label="Trajetórias dos modelos" if j == 0 else None)
        trails.append(ln)
    est_line, = ax.plot([], [], color=[cor, cor, 1 - cor], linewidth=1.0,
                        label=r"Estimativa $\hat{\theta}_p$")
    est_mark, = ax.plot([], [], color=[cor, cor, 1 - cor], marker="o", markersize=5,
                        linestyle="none")
    aniline, = ax.plot([], [], linewidth=3.0, color=[0.35, 0.5, 0],
                       label="Fecho convexo atual")
    leg = ax.legend(loc="best", fontsize=8, title=f"{tempo[0]:.2f} Segundos")

    def update(k):
        tb = theta_BARRA[:, :, k - 1]
        aniline.set_data(np.r_[tb[0, :], tb[0, 0]], np.r_[tb[1, :], tb[1, 0]])
        for j in range(L):
            trails[j].set_data(theta_BARRA[0, j, :k], theta_BARRA[1, j, :k])
        kk = min(k, tpe.shape[1])
        est_line.set_data(tpe[0, :kk], tpe[1, :kk])
        est_mark.set_data([tpe[0, kk - 1]], [tpe[1, kk - 1]])
        leg.set_title(f"{tempo[k - 1]:.2f} Segundos")
        ax.relim()
        ax.autoscale_view()
        return [aniline, est_line, est_mark, *trails]

    anim = animation.FuncAnimation(fig, update, frames=ks, interval=interval,
                                   blit=False, repeat=False)
    if save:
        if str(save).lower().endswith(".gif"):
            writer = animation.PillowWriter(fps=max(1, int(round(1000 / interval))))
        else:
            writer = animation.FFMpegWriter(fps=max(1, int(round(1000 / interval))))
        anim.save(save, writer=writer)
    return anim


def anim_trajetorias(func, args, save=None, skip=None, interval=100):
    """``video_trajetoria = anim_trajetorias(func, args)``: run ``func(args)`` and animate."""
    estrutura = func(args)
    return animate(estrutura, args, save=save, skip=skip, interval=interval)


def main(argv=None):
    here = os.path.dirname(os.path.abspath(__file__))
    root = here[:here.index(os.sep + "dissertation" + os.sep)]
    default_mat = os.path.join(root.replace(os.sep + "m2python_port", ""), "papers",
                               "2016-cba-second-level-adaptation-pe-switch-off", "code", "CBA1.mat")
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--params", default=default_mat)
    p.add_argument("--var", default="Parameters")
    p.add_argument("--func", default="L2AA", choices=["L2AA", "L2AA_CL"])
    p.add_argument("--save", default=None)
    p.add_argument("--skip", type=int, default=None)
    p.add_argument("--interval", type=int, default=100)
    a = p.parse_args(argv)
    from convert_struct import load_struct
    args = load_struct(a.params, a.var)
    if a.func == "L2AA":
        from L2AA import L2AA as func
    else:
        from L2AA_CL import L2AA_CL as func
    anim = anim_trajetorias(func, args, save=a.save, skip=a.skip, interval=a.interval)
    plt.show()
    return anim


if __name__ == "__main__":
    main()
