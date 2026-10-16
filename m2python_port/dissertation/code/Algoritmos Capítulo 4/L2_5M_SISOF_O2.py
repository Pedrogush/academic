"""Port of dissertation/code/Algoritmos Capítulo 4/L2_5M_SISOF_O2.m

Second-level identification with 5 models of the second-order SISO plant of
L1_SISOF_O2 (A_p = [-1 -2; 0 -3], b_p = [2; 3], h_p' = [1 0]) by filtered linear
regression (Lambda(s) = s^2+6s+9, z_p = [6 9]*phi_1 + y_p).  Model 1 starts at
theta_p_m, models 2..5 start at theta_p_m with one component moved to
theta_p_m(j) + 5*(theta_p_M(j) - theta_p_m(j)).  Each model follows the normalized
gradient law (Gamma = 100*I, no projection); the second level estimates
alfa (alfa_5 = 1 - sum(alfa_1..4)) with dalfa/dt = 10*(-E_f'E_f*alfa -
E_f'*eps_5_f), E_f = [eps_i_f - eps_5_f] (previous-step errors), and the combined
estimate theta_n2 = sum alfa_i*theta_i is clipped to [theta_p_m, theta_p_M].
Input u = 1 + sin(3t) + sin(1.7t) + sin(t).  Forward Euler, step h.

Porting notes:
- Outputs theta_n2 (4, endk+1), z_1, z_p, tempo_1 (endk+1).
- MATLAB auto-filled zeros reproduced: y_p(1) = 0, phi(:,1) = 0, eps_i_f(1) = 0,
  alfa_N(1) = 0 (so E_f at k = 1 is zero).
- ``_simulate(t, h, fe=True)`` is the core of L2_5M_SISOF_O2_FE (adds the
  forgetting-factor memory terms M, v); the two MATLAB files are otherwise equal.
- ``tic``/``toc`` -> elapsed time printed.  ``main()`` runs t = 20, h = 1e-3.
"""
import time

import numpy as np
from scipy.signal import tf2ss


def _simulate(t, h, fe=False):
    endk = int(np.floor(t / h + 1e-9))
    A_p = np.array([[-1.0, -2.0], [0.0, -3.0]])
    b_p = np.array([2.0, 3.0])
    h_p_T = np.array([1.0, 0.0])
    theta_p_m = np.array([3.0, 1.0, -1.0, -3.0])
    theta_p_M = np.array([8.0, 6.0, 7.0, 3.0])
    NM = 5
    theta = np.zeros((NM, 4, endk + 1))
    for j in range(NM):
        theta[j, :, 0] = theta_p_m
    for j in range(1, NM):
        theta[j, j - 1, 0] = theta_p_m[j - 1] + 5 * (theta_p_M[j - 1] - theta_p_m[j - 1])
    Lambda_c, l, _, _ = tf2ss([1], [1, 6, 9])
    l = l[:, 0]
    Gamma = 100.0 * np.eye(4)
    phi_1 = np.zeros((2, endk + 1)); phi_2 = np.zeros((2, endk + 1))
    phi = np.zeros((4, endk + 1))
    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.4]
    y_p = np.zeros(endk + 1)
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    alfa = np.zeros((4, endk + 1)); alfa[0, 0] = 1
    alfa_N = np.zeros(endk + 1)
    theta_n2 = np.zeros((4, endk + 1)); theta_n2[:, 0] = theta[0, :, 0]
    M = np.zeros((4, 4, endk + 1)); v = np.zeros((4, endk + 1))
    z_p = np.zeros(endk + 1); z_p[0] = h_p_T @ x_p[:, 0]
    z = np.zeros((NM, endk + 1))
    e = np.zeros((NM, endk + 1)); e[0, 0] = z[0, 0] - z_p[0]
    eps = np.zeros((NM, endk + 1))
    for i in range(endk):
        k = i + 1
        tempo[i] = h * k
        tempo_1[i + 1] = h * k + h
        u[i] = 1 + np.sin(3 * h * k) + np.sin(1.7 * h * k) + np.sin(h * k)
        x_p[:, i + 1] = x_p[:, i] + h * (A_p @ x_p[:, i] + b_p * u[i])
        y_p[i + 1] = h_p_T @ x_p[:, i + 1]
        phi_1[:, i + 1] = phi_1[:, i] + h * (Lambda_c @ phi_1[:, i] - l * y_p[i])
        phi_2[:, i + 1] = phi_2[:, i] + h * (Lambda_c @ phi_2[:, i] + l * u[i])
        phi[:, i + 1] = np.r_[phi_1[:, i + 1], phi_2[:, i + 1]]
        z_p[i + 1] = np.array([6.0, 9.0]) @ phi_1[:, i + 1] + y_p[i + 1]
        m_2 = 1 + phi[:, i] @ phi[:, i]
        for j in range(NM):
            z[j, i + 1] = theta[j, :, i] @ phi[:, i]
            e[j, i + 1] = z[j, i + 1] - z_p[i + 1]
            eps[j, i + 1] = e[j, i + 1] / m_2
            dot_theta = (-Gamma * eps[j, i + 1]) @ phi[:, i]
            theta[j, :, i + 1] = theta[j, :, i] + h * dot_theta
        E = eps[:4, i] - eps[4, i]
        EE = np.outer(E, E)
        if fe:
            M[:, :, i + 1] = M[:, :, i] + h * (-0.2 * M[:, :, i] + EE)
            v[:, i + 1] = v[:, i] + h * (-0.2 * v[:, i] + E * eps[4, i])
            dot_alfa = 10 * (-(EE + M[:, :, i]) @ alfa[:, i] - E * eps[4, i] - v[:, i])
        else:
            dot_alfa = 10 * (-EE @ alfa[:, i] - E * eps[4, i])
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_N[i + 1] = 1 - np.sum(alfa[:, i + 1])
        th = (alfa[0, i + 1] * theta[0, :, i + 1] + alfa[1, i + 1] * theta[1, :, i + 1]
              + alfa[2, i + 1] * theta[2, :, i + 1] + alfa[3, i + 1] * theta[3, :, i + 1]
              + alfa_N[i + 1] * theta[4, :, i + 1])
        theta_n2[:, i + 1] = np.clip(th, theta_p_m, theta_p_M)
    return dict(endk=endk, theta=theta, theta_n2=theta_n2, alfa=alfa, alfa_N=alfa_N,
                z=z, z_1=z[0], z_p=z_p, y_p=y_p, u=u, tempo=tempo, tempo_1=tempo_1,
                eps=eps, M=M, v=v)


def L2_5M_SISOF_O2(t, h):
    """[theta_n2, z_1, z_p, tempo_1] = L2_5M_SISOF_O2(t,h)"""
    t0 = time.time()
    s = _simulate(t, h, fe=False)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["theta_n2"], s["z_1"], s["z_p"], s["tempo_1"]


def main():
    theta_n2, z_1, z_p, tempo_1 = L2_5M_SISOF_O2(20, 1e-3)
    print("theta_n2(end) =", theta_n2[:, -1])


if __name__ == "__main__":
    main()
