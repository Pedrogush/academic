"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/L2AA_Dif_Anim.m

Simulação referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Parameter-convergence animation of second-level adaptation with adaptive identification
models (L2AA, differential alpha law with alpha saturation). The n+1 = 3 identification
models theta_i (columns of ``modelos``) move under theta_i_dot = -e_i' P b x_p, and alpha
follows alpha_dot = gamma*(-E'E alpha - E' e_{n+1}) saturated to [0,1]. The PE reference
r = ref(1 + 0.2 sin t + 0.2 sin 2t) is kept on for the whole run (eta(k+1) = 1, so the
switch-off branch only acts at k = 1). In the 2-parameter case the MATLAB function draws,
every ``skip = stoptime/(240 h)`` steps: the current triangle of models (animatedline with 4
points), the trajectory (trail) of each model's parameters, the plant point, the segment
theta0 -> theta_p, the initial triangle and the trail of the plant estimate
theta_p_hat = THETA_BARRA*alpha_bar; it collects those frames with getframe and returns
the movie. Colors depend on the extra argument ``cor`` (genfigure.m overlays two runs).

This module also provides the shared animation machinery (``animate_runs``) used by
L2AA_Dif_Anim_InputAsStruct.py, L2AA_Dif_ModDes_SatAlfa_longA.py,
L2AA_Dif_ModDes_SatAlfa_theAnimation.py and genfigure.py.

Porting notes:
- ``can`` (../can.m) is inlined.
- The MATLAB function returns ``movie`` (getframe frames). Here it returns the
  matplotlib FuncAnimation (``movie``) built from the same frame steps; the simulation
  arrays are attached as ``movie.sim``.
- BUG kept/documented: MATLAB stores ``movie(0.5*k/skip) = getframe`` -> with skip = 75
  (genfigure.m) the first frame index is 0.5 and MATLAB stops with an indexing error.
  The Python port simply renders every frame step (k multiple of skip).
- The frame test ``floor(k/skip)==ceil(k/skip)`` is reproduced with the same floating
  point skip value.
- MATLAB axes autoscale as lines are added; the animation re-autoscales each frame.
  A legend title shows the current time "N Segundos" (not in the MATLAB code).
- The internal ``sat_rule`` keyword ('eq' = this file, ``sign(..)==sign(..)``;
  'ne' = theAnimation variant) is a porting convenience.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter, FFMpegWriter


def can(vect):
    """Companion matrix: ones on the super-diagonal, last row = vect (copy of ../can.m)."""
    vect = np.asarray(vect, dtype=float).ravel()
    n = vect.size
    A = np.zeros((n, n))
    for linha in range(n - 1):
        A[linha, linha + 1] = 1.0
    A[n - 1, :] = vect
    return A


def simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
             cond_iniciais_i, alfa0, referencia, Q, gamma, P, sat_rule='eq'):
    """Euler simulation loop of L2AA_Dif_Anim.m (eta(k+1)=1; r switch-off test eta(k)<=0)."""
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    planta = np.asarray(planta, dtype=float).ravel()
    modelo_de_referencia = np.asarray(modelo_de_referencia, dtype=float).ravel()
    P = np.atleast_2d(np.asarray(P, dtype=float))
    n = modelos.shape[0]
    N = max(modelos.shape)  # length(modelos)
    na = N - 1
    A_p = can(planta)
    A_m = can(modelo_de_referencia)
    b = np.zeros(n)
    b[n - 1] = 1.0
    endk = int(np.floor(stoptime / h))

    theta_BARRA = np.zeros((n, N, endk + 1))
    theta_BARRA[:, :, 0] = modelos
    x_p = np.zeros((n, endk + 1))
    x_m = np.zeros((n, endk + 1))
    x_i = np.zeros((n, N, endk + 1))
    x_p[:, 0] = np.asarray(cond_iniciais_p, dtype=float).ravel()
    x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_i[:, :, 0] = np.asarray(cond_iniciais_i, dtype=float).reshape(n, N)
    e_i = np.zeros((n, N, endk))
    alfa = np.zeros((na, endk + 1))
    alfa[:, 0] = np.asarray(alfa0, dtype=float).ravel()
    alfa_ponto = np.zeros((na, endk))
    alfa_barra = np.zeros((N, endk))
    alfa_barra[:, 0] = np.append(alfa[:, 0], 1 - alfa[:, 0].sum())
    theta0 = modelos @ alfa_barra[:, 0]
    k_T = np.zeros((n, endk))
    k_T[:, 0] = modelo_de_referencia - modelos @ alfa_barra[:, 0]
    u = np.zeros(endk)
    u[0] = referencia
    tempo = np.zeros(endk + 1)
    eta = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    r_ponto = np.zeros(endk)
    e_o = np.zeros((n, endk))
    norm_2_e_o = np.zeros(endk)
    theta_p_estimativa = np.zeros((n, endk))

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = referencia + 0.2 * referencia * np.sin(tempo[k]) + 0.2 * referencia * np.sin(2 * tempo[k])
        if eta[k] <= 0:
            r_ponto[k] = 10 * (-r[k] + referencia)
            r[k + 1] = r[k] + h * r_ponto[k]
        e_i[:, :, k] = x_i[:, :, k] - x_p[:, [k]]
        E = x_i[:, :na, k] - x_i[:, [N - 1], k]
        ap = gamma * (-E.T @ E @ alfa[:, k] - E.T @ e_i[:, N - 1, k])
        alfa_n1 = 1 - alfa[:, k].sum()
        alfa_ponto_n1 = -ap.sum()
        for i in range(na):
            if (alfa[i, k] >= 1 and ap[i] > 0) or (alfa[i, k] <= 0 and ap[i] < 0):
                ap[i] = 0.0
            if (alfa_n1 >= 1 and alfa_ponto_n1 > 0) or (alfa_n1 <= 0 and alfa_ponto_n1 < 0):
                for j in range(na):
                    same = np.sign(alfa_ponto_n1) == np.sign(ap[j])
                    if (same if sat_rule == 'eq' else not same):
                        ap[j] = 0.0
        alfa_ponto[:, k] = ap
        alfa[:, k + 1] = alfa[:, k] + h * ap
        eta[k + 1] = 1
        alfa_barra[:, k] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = modelo_de_referencia - theta_BARRA[:, :, k] @ alfa_barra[:, k]
        u[k] = r[k] + k_T[:, k] @ x_p[:, k]
        for j in range(N):
            theta_i_ponto = -(e_i[:, j, k] @ P @ b) * x_p[:, k]
            theta_BARRA[:, j, k + 1] = theta_BARRA[:, j, k] + h * theta_i_ponto
        for j in range(N):
            A_i = can(theta_BARRA[:, j, k])
            x_i_ponto = A_m @ x_i[:, j, k] + (A_i - A_m) @ x_p[:, k] + b * u[k]
            x_i[:, j, k + 1] = x_i[:, j, k] + h * x_i_ponto
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])
        e_o[:, k] = x_m[:, k] - x_p[:, k]
        norm_2_e_o[k] = np.sqrt(e_o[:, k] @ e_o[:, k])
        theta_p_estimativa[:, k] = theta_BARRA[:, :, k] @ alfa_barra[:, k]

    return dict(tempo=tempo, r=r, eta=eta, alfa=alfa, alfa_ponto=alfa_ponto, alfa_barra=alfa_barra,
                k_T=k_T, u=u, x_p=x_p, x_m=x_m, x_i=x_i, e_i=e_i, theta_BARRA=theta_BARRA,
                e_o=e_o, norm_2_e_o=norm_2_e_o, theta_p_estimativa=theta_p_estimativa,
                theta0=theta0, planta=planta, modelos=modelos, endk=endk, h=h, stoptime=stoptime)


def frame_steps(endk, skip):
    """1-based steps k with floor(k/skip)==ceil(k/skip) (MATLAB frame test)."""
    ks = np.arange(1, endk + 1)
    return ks[np.floor(ks / skip) == np.ceil(ks / skip)]


def _style(cor=None, lw=1.0):
    """Colors of the MATLAB code: cor-dependent (L2AA_Dif_Anim) or fixed (cor=None)."""
    blue = (0, 0.447, 0.741)  # MATLAB default color (animatedline / theta0 line)
    if cor is None:
        return dict(trail=(1, 0, 1), plant=(0, 1, 1), modelos=(1, 0, 0), est=(0, 0, 1),
                    hull=blue, theta0=blue, lw=lw)
    return dict(trail=(1 - cor, cor, 1 - cor), plant=(cor, 1 - cor, 1 - cor),
                modelos=(1 - cor, cor, cor), est=(cor, cor, 1 - cor), hull=blue, theta0=blue, lw=lw)


def animate_runs(runs, save=None, interval=50, ax=None, hull_lw=None):
    """FuncAnimation over one or more simulations drawn on the same axes (hold on).

    ``runs`` is a list of dicts: {'sim': simulate(...) result, 'frames': 1-based steps k,
    'style': _style(...), 'trails': bool (model trails a1j/a2j), 'theta0': bool
    (segment theta0 -> planta)}. Runs are played one after another; earlier runs stay
    drawn, like successive calls in genfigure.m.
    """
    if ax is None:
        fig, ax = plt.subplots(figsize=(7, 6))
    else:
        fig = ax.figure
    ax.grid(True)
    ax.set_xlabel(r'$\theta_1$')
    ax.set_ylabel(r'$\theta_2$')
    schedule = []
    artists = []
    for ri, run in enumerate(runs):
        s, st = run['sim'], run['style']
        lw = st['lw']
        N = s['theta_BARRA'].shape[1]
        a = dict(
            hull=ax.plot([], [], color=st['hull'], lw=hull_lw if hull_lw else lw,
                         label='modelos atuais' if ri == 0 else None)[0],
            trails=[ax.plot([], [], color=st['trail'], lw=lw,
                            label=r'trajetórias $\theta_i$' if (ri == 0 and j == 0) else None)[0]
                    for j in range(N)] if run.get('trails', True) else [],
            plant=ax.plot([], [], color=st['plant'], lw=lw, marker='o', ls='none',
                          label=r'planta $\theta_p$' if ri == 0 else None)[0],
            theta0=ax.plot([], [], color=st['theta0'], lw=lw,
                           label=r'$\theta_0 \to \theta_p$' if ri == 0 else None)[0]
            if run.get('theta0', True) else None,
            modelos=ax.plot([], [], color=st['modelos'], lw=lw,
                            label='modelos iniciais' if ri == 0 else None)[0],
            est=ax.plot([], [], color=st['est'], lw=lw,
                        label=r'estimativa $\hat\theta_p$' if ri == 0 else None)[0],
        )
        artists.append(a)
        for k in run['frames']:
            schedule.append((ri, int(k)))
    leg = ax.legend(loc='best', fontsize=8, title='0 Segundos')

    def update(fi):
        ri, k = schedule[fi]
        s, a = runs[ri]['sim'], artists[ri]
        kk = k - 1  # 0-based
        tb = s['theta_BARRA'][:, :, kk]
        a['hull'].set_data(np.append(tb[0], tb[0, 0]), np.append(tb[1], tb[1, 0]))
        for j, ln in enumerate(a['trails']):
            ln.set_data(s['theta_BARRA'][0, j, :k], s['theta_BARRA'][1, j, :k])
        pl, mo = s['planta'], s['modelos']
        a['plant'].set_data([pl[0]], [pl[1]])
        if a['theta0'] is not None:
            a['theta0'].set_data([s['theta0'][0], pl[0]], [s['theta0'][1], pl[1]])
        a['modelos'].set_data(np.append(mo[0], mo[0, 0]), np.append(mo[1], mo[1, 0]))
        a['est'].set_data(s['theta_p_estimativa'][0, :k], s['theta_p_estimativa'][1, :k])
        leg.set_title(f"{s['tempo'][kk]:.4g} Segundos")
        ax.relim()
        ax.autoscale_view()
        return []

    anim = FuncAnimation(fig, update, frames=len(schedule), interval=interval, blit=False, repeat=False)
    if save:
        fps = max(1, int(round(1000 / interval)))
        if str(save).lower().endswith('.gif'):
            anim.save(save, writer=PillowWriter(fps=fps))
        elif str(save).lower().endswith('.mp4'):
            anim.save(save, writer=FFMpegWriter(fps=fps))
        else:
            raise ValueError('save must end in .gif or .mp4')
    return anim


def animate(sim, cor=0, save=None, skip=None, interval=50, ax=None):
    """Animation of one L2AA_Dif_Anim run. ``skip`` defaults to MATLAB's stoptime/(240*h)."""
    if skip is None:
        skip = sim['stoptime'] / (240 * sim['h'])
    run = dict(sim=sim, frames=frame_steps(sim['endk'], skip), style=_style(cor, 1.0),
               trails=True, theta0=True)
    return animate_runs([run], save=save, interval=interval, ax=ax)


def L2AA_Dif_Anim(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                  cond_iniciais_i, alfa0, referencia, Q, gamma, P, cor, save=None, skip=None, interval=50,
                  ax=None):
    """Simulate and return the animation (``movie``); simulation dict in ``movie.sim``."""
    sim = simulate(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p, cond_iniciais_m,
                   cond_iniciais_i, alfa0, referencia, Q, gamma, P)
    movie = None
    if sim['planta'].size == 2:
        movie = animate(sim, cor=cor, save=save, skip=skip, interval=interval, ax=ax)
        movie.sim = sim
    return movie


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument('--animate', action='store_true', help='(default; kept for CLI uniformity)')
    ap.add_argument('--save', default=None, help='save animation to .gif or .mp4')
    ap.add_argument('--stoptime', type=float, default=900)
    args = ap.parse_args()
    # call used in genfigure.m (first iteration, c = 1)
    c = 1
    angulo = c * np.pi / 180
    rr = (20 - np.floor(c / 360)) / 20
    cor = abs(np.cos(np.floor(c / 60)))
    movie = L2AA_Dif_Anim(args.stoptime, 0.5e-1,
                          [[1.5, 3.5, 2.5 + rr * np.cos(angulo)], [-3, -3, -3 + rr * np.sin(angulo)]],
                          [2.5, -3], [-4, -4], [0, 0], [0.2, 0.3], [[0, 0, 0], [0, 0, 0]], [0, 0], 5,
                          [[1e4, 0], [0, 1e4]], 100, [[1, 0], [0, 1]], cor, save=args.save)
    print('theta_p_estimativa(:,end) =', movie.sim['theta_p_estimativa'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
