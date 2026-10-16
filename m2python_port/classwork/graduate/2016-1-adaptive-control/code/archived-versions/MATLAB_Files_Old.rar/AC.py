"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/MATLAB_Files_Old.rar/AC.m

First draft of an indirect MRAC with a parallel identification model. It
simulates (forward Euler, step h, stoptime/h steps) a plant x_p' = Ap x_p + bp u,
a reference model x_m' = Am x_m + bm r and an identification model
x_i' = Ai x_i + bi u in companion form (Ai = can(theta(1:2)), bi = first half of
theta). The control is u = r + k_T' v with k_T = [bm; Am(end,:)'] -
[bi; Ai(end,:)'] and v = [u*ones; x_p]; the parameters are adapted by the scalar
law theta' = -e1' P v with e1 = [bp u - bi u; x_i - x_p]. The reference is
r = referencia*sin(t). Plots x_p, x_i and x_m against time in one figure.

Porting notes:
- ``can`` lives in the "Estrategias Controle Adaptativo" folder; loaded from its
  port with importlib.
- BUGS KEPT: theta' is a SCALAR (1x2N * 2Nx2N * 2Nx1) added to every component of
  theta; Ai always uses theta(1:2) (only works for N = 2) and both Ai and bi are
  built from the first half of theta.
- u(1) = 0 (MATLAB auto-fill: u(k+1) is assigned before u(k) is used).
- MATLAB returns nothing; the port returns a dict with the signals and the figure
  (extension). Run as a script for a demo with illustrative parameters (the
  original has no caller).
"""
import importlib.util
import os
import sys

import matplotlib.pyplot as plt
import numpy as np


def _import_from(relpath, name):
    path = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), relpath))
    d = os.path.dirname(path)
    sys.path.insert(0, d)
    try:
        spec = importlib.util.spec_from_file_location("_m2p_%x" % (hash(path) & 0xFFFFFFFF), path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        sys.path.remove(d)
    return getattr(mod, name)


can = _import_from("../../Estrategias Controle Adaptativo/can.py", "can")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def AC(h, stoptime, bpi0, api0, Ap, bp, Am, bm, cond_iniciais_p, cond_iniciais_m,
       cond_iniciais_i, referencia, P):
    Ap = np.atleast_2d(np.asarray(Ap, float)); bp = np.ravel(np.asarray(bp, float))
    Am = np.atleast_2d(np.asarray(Am, float)); bm = np.ravel(np.asarray(bm, float))
    P = np.atleast_2d(np.asarray(P, float))
    bpi0 = np.ravel(np.asarray(bpi0, float)); api0 = np.ravel(np.asarray(api0, float))
    N = len(np.ravel(cond_iniciais_p))
    endk = stoptime / h
    K = _ncount(endk)

    x_p = np.zeros((N, K + 1)); x_p[:, 0] = np.ravel(cond_iniciais_p)
    x_m = np.zeros((N, K + 1)); x_m[:, 0] = np.ravel(cond_iniciais_m)
    x_i = np.zeros((N, K + 1)); x_i[:, 0] = np.ravel(cond_iniciais_i)
    tempo = np.zeros(K + 1)
    Ai = np.zeros((len(api0), len(api0), K + 1)); Ai[:, :, 0] = can(api0)
    bi = np.zeros((len(bpi0), K + 1)); bi[:, 0] = bpi0
    theta = np.zeros((len(bpi0) + len(api0), K + 1)); theta[:, 0] = np.concatenate([bpi0, api0])
    v = np.zeros((2 * N, K + 1)); v[:, 0] = np.concatenate([0 * np.ones(N), x_p[:, 0]])
    r = np.zeros(K)
    u = np.zeros(K + 1)
    k_T = np.zeros((len(bm) + Am.shape[1], K))
    theta_ponto = np.zeros(K)
    nAm = max(Am.shape)
    for k in range(K):
        tempo[k + 1] = tempo[k] + h
        r[k] = referencia * np.sin(tempo[k])
        k_T[:, k] = (np.concatenate([bm, Am[nAm - 1, :]])
                     - np.concatenate([bi[:, k], Ai[N - 1, :, k]]))
        u[k + 1] = r[k] + k_T[:, k] @ v[:, k]
        x_p_ponto = Ap @ x_p[:, k] + bp * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        x_m_ponto = Am @ x_m[:, k] + bm * r[k]
        x_m[:, k + 1] = x_m[:, k] + h * x_m_ponto
        x_i_ponto = Ai[:, :, k] @ x_i[:, k] + bi[:, k] * u[k]
        x_i[:, k + 1] = x_i[:, k] + h * x_i_ponto
        v[:, k + 1] = np.concatenate([u[k + 1] * np.ones(N), x_p[:, k + 1]])
        e1 = np.concatenate([bp * u[k] - bi[:, k] * u[k], x_i[:, k] - x_p[:, k]])
        theta_ponto[k] = (-e1 @ P) @ v[:, k]
        theta[:, k + 1] = theta[:, k] + h * theta_ponto[k]
        Ai[:, :, k + 1] = can(theta[0:2, k + 1])
        bi[:, k + 1] = theta[:theta.shape[0] // 2, k + 1]

    fig = plt.figure()
    plt.plot(tempo, x_p.T)
    plt.plot(tempo, x_i.T)
    plt.plot(tempo, x_m.T)
    plt.grid(True)
    return dict(tempo=tempo, x_p=x_p, x_m=x_m, x_i=x_i, theta=theta, u=u, r=r, fig=fig)


def main():
    # illustrative parameters (the original has no caller)
    Ap = np.array([[0, 1], [-2, -3.]]); bp = np.array([0, 1.])
    Am = np.array([[0, 1], [-4, -4.]]); bm = np.array([0, 1.])
    AC(1e-3, 10, [0, 1], [-1, -2], Ap, bp, Am, bm, [0, 0], [0, 0], [0, 0], 1, 1e-3 * np.eye(4))
    plt.show()


if __name__ == "__main__":
    main()
