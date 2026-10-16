"""Port of dissertation/code/Algoritmos Capítulo 5/L2A_5M_SISOF_O2.m

Second-level indirect adaptive model-reference control of the unstable plant of
L1A_SISOF_O2 (theta_p = [-3 -4 2 1]) with 5 identification models (filtered linear
regression, Lambda(s) = (s+3)(s+4), normalized gradient, Gamma = 10*I; model 1
starts at theta_p_m, models 2..5 have one component moved to
theta_p_m(j) + 5*(theta_p_M(j) - theta_p_m(j))) and
second-level weights alfa (alfa_5 = 1 - sum(alfa_1..4)),
dalfa/dt = 3*(-E_f'E_f*alfa - E_f'*eps_5_f).  The combined estimate
theta_n2 (clipped to [theta_p_m, theta_p_M]) gives the controller by certainty
equivalence, u = theta_c(theta_n2)'*w.  Reference r = 1 + sin(3t) + sin(1.7t) +
sin(t).  Forward Euler, step h.

Porting notes:
- ``_simulate(t, h, fe=True)`` is the core of L2A_5M_SISOF_O2_FE (Gamma = 100*I,
  memory terms M, v with forgetting -6, gain 10).
- MATLAB auto-filled zeros reproduced (r(1), y_m(1), phi(:,1), eps_i_f(1),
  alfa_N(1)); y_p(1) = 0.8.  theta_c1 (controller from model 1) is computed but
  unused, as in MATLAB.
- Outputs theta_n2 (4, endk+1), y_p, y_m (endk+1), u (endk), tempo_1.
- ``main()`` runs t = 20, h = 1e-3.
"""
import os
import sys
import time

import numpy as np
from scipy.signal import tf2ss

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from L1A_SISOF_O2 import theta_c_of, THETA_P_m, THETA_P_M  # noqa: E402


def _simulate(t, h, fe=False):
    endk = int(np.floor(t / h + 1e-9))
    A_p = np.array([[3.0, 4.0], [1.0, 0.0]])
    b_p = np.array([1.0, 0.0])
    h_p_T = np.array([2.0, 1.0])
    A_m, b_m, htm, _ = tf2ss([1, 4], [1, 4, 4])
    b_m = b_m[:, 0]; htm = htm[0]
    NM = 5
    theta = np.zeros((NM, 4, endk + 1))
    for j in range(NM):
        theta[j, :, 0] = THETA_P_m
    for j in range(1, NM):
        theta[j, j - 1, 0] = THETA_P_m[j - 1] + 5 * (THETA_P_M[j - 1] - THETA_P_m[j - 1])
    theta_c = np.zeros((4, endk + 1)); theta_c[:, 0] = theta_c_of(theta[0, :, 0])
    theta_c1 = theta_c.copy()
    Lambda_d_s = [1, 7, 12] if fe else np.convolve([1, 3], [1, 4])
    Lambda_c, l, _, _ = tf2ss([1], Lambda_d_s)
    l = l[:, 0]
    Gamma = (100.0 if fe else 10.0) * np.eye(4)
    phi_1 = np.zeros((2, endk + 1)); phi_2 = np.zeros((2, endk + 1))
    phi = np.zeros((4, endk + 1))
    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.4]
    x_m = np.zeros((2, endk + 1))
    y_p = np.zeros(endk + 1); y_p[0] = 0.8
    y_m = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    alfa = np.zeros((4, endk + 1)); alfa[0, 0] = 1
    alfa_N = np.zeros(endk + 1)
    theta_n2 = np.zeros((4, endk + 1)); theta_n2[:, 0] = theta[0, :, 0]
    M = np.zeros((4, 4, endk + 1)); v = np.zeros((4, endk + 1))
    z_p = np.zeros(endk + 1); z_p[0] = h_p_T @ x_p[:, 0]
    z = np.zeros((NM, endk + 1))
    e = np.zeros((NM, endk + 1)); e[0, 0] = z[0, 0] - z_p[0]
    eps = np.zeros((NM, endk + 1))
    w = np.zeros((4, endk + 1)); w_1 = np.zeros(endk + 1); w_2 = np.zeros(endk + 1)
    for i in range(endk):
        k = i + 1
        tempo[i] = h * k
        tempo_1[i + 1] = h * k + h
        r[i + 1] = 1 + np.sin(3 * h * k) + np.sin(1.7 * h * k) + np.sin(h * k)
        u[i] = theta_c[:, i] @ w[:, i]
        x_p[:, i + 1] = x_p[:, i] + h * (A_p @ x_p[:, i] + b_p * u[i])
        y_p[i + 1] = h_p_T @ x_p[:, i + 1]
        x_m[:, i + 1] = x_m[:, i] + h * (A_m @ x_m[:, i] + b_m * r[i])
        y_m[i + 1] = htm @ x_m[:, i + 1]
        phi_1[:, i + 1] = phi_1[:, i] + h * (Lambda_c @ phi_1[:, i] + l * y_p[i])
        phi_2[:, i + 1] = phi_2[:, i] + h * (Lambda_c @ phi_2[:, i] + l * u[i])
        phi[:, i + 1] = np.r_[-phi_1[:, i + 1], phi_2[:, i + 1]]
        w_1[i + 1] = w_1[i] + h * (-4 * w_1[i] + u[i])
        w_2[i + 1] = w_2[i] + h * (-4 * w_2[i] + y_p[i])
        w[:, i + 1] = [w_1[i + 1], w_2[i + 1], y_p[i + 1], r[i + 1]]
        z_p[i + 1] = -np.array([7.0, 12.0]) @ phi_1[:, i + 1] + y_p[i + 1]
        m_2 = 1 + phi[:, i] @ phi[:, i]
        for j in range(NM):
            z[j, i + 1] = theta[j, :, i] @ phi[:, i]
            e[j, i + 1] = z[j, i + 1] - z_p[i + 1]
            eps[j, i + 1] = e[j, i + 1] / m_2
            theta[j, :, i + 1] = theta[j, :, i] + h * ((-Gamma * eps[j, i + 1]) @ phi[:, i])
        E = eps[:4, i] - eps[4, i]
        EE = np.outer(E, E)
        if fe:
            M[:, :, i + 1] = M[:, :, i] + h * (-6 * M[:, :, i] + EE)
            v[:, i + 1] = v[:, i] + h * (-6 * v[:, i] + E * eps[4, i])
            dot_alfa = 10 * (-(EE + M[:, :, i]) @ alfa[:, i] - E * eps[4, i] - v[:, i])
        else:
            dot_alfa = 3 * (-EE @ alfa[:, i] - E * eps[4, i])
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_N[i + 1] = 1 - np.sum(alfa[:, i + 1])
        th = (alfa[0, i + 1] * theta[0, :, i + 1] + alfa[1, i + 1] * theta[1, :, i + 1]
              + alfa[2, i + 1] * theta[2, :, i + 1] + alfa[3, i + 1] * theta[3, :, i + 1]
              + alfa_N[i + 1] * theta[4, :, i + 1])
        theta_n2[:, i + 1] = np.clip(th, THETA_P_m, THETA_P_M)
        theta_c[:, i + 1] = theta_c_of(theta_n2[:, i + 1])
        theta_c1[:, i + 1] = theta_c_of(theta[0, :, i + 1])
    return dict(endk=endk, theta=theta, theta_n2=theta_n2, theta_c=theta_c, alfa=alfa,
                alfa_N=alfa_N, y_p=y_p, y_m=y_m, u=u, r=r, tempo=tempo, tempo_1=tempo_1,
                eps=eps, M=M, v=v)


def L2A_5M_SISOF_O2(t, h):
    """[theta_n2, y_p, y_m, u, tempo_1] = L2A_5M_SISOF_O2(t,h)"""
    t0 = time.time()
    with np.errstate(divide="ignore", invalid="ignore"):
        s = _simulate(t, h, fe=False)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["theta_n2"], s["y_p"], s["y_m"], s["u"], s["tempo_1"]


def main():
    theta_n2, y_p, y_m, u, tempo_1 = L2A_5M_SISOF_O2(20, 1e-3)
    print("theta_n2(end) =", theta_n2[:, -1], " y_p(end)-y_m(end) =", y_p[-1] - y_m[-1])


if __name__ == "__main__":
    main()
