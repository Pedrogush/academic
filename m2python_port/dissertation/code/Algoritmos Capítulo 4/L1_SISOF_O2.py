"""Port of dissertation/code/Algoritmos Capítulo 4/L1_SISOF_O2.m

First-level identification of a second-order SISO plant (state space
A_p = [-1 -2; 0 -3], b_p = [2; 3], h_p' = [1 0], i.e. transfer function
(2s+3)/(s^2+4s+3)) by filtered linear regression ("SISOF", order 2): the
regressor phi = [phi_1; phi_2] is produced by the filters
dphi_1/dt = Lambda_c*phi_1 - l*y_p, dphi_2/dt = Lambda_c*phi_2 + l*u with
Lambda(s) = s^2 + 6s + 9 ((Lambda_c, l) = tf2ss(1, Lambda)), the "measured"
output is z_p = [6 9]*phi_1 + y_p and the model output z_1 = theta_1'*phi.  The
normalized gradient law dtheta_1/dt = -Gamma*eps_1_f*phi (eps = e/(1+phi'phi),
Gamma = 100*I) is followed by a projection (clipping) onto the box
[theta_p_m, theta_p_M] = [3 1 -1 -3] .. [8 6 7 3].  Input
u = 1 + sin(3t) + sin(1.7t) + sin(t).  Forward Euler, step h.

Porting notes:
- theta_1 is returned as a (4, endk+1) array (MATLAB: 4x1x(endk+1)); z_1, z_p,
  tempo_1 have endk+1 samples.
- MATLAB auto-fills y_p(1) = 0 and phi(:,1) = 0 (they are first assigned at index
  2); this is reproduced (y_p[0] = 0 even though x_p(:,1) = [0.2; 0.4]).
- tf2ss -> scipy.signal.tf2ss (same controller canonical form as MATLAB).
- ``tic``/``toc`` -> elapsed time printed.  ``main()`` runs t = 20, h = 1e-3.
"""
import time

import numpy as np
from scipy.signal import tf2ss


def L1_SISOF_O2(t, h):
    t0 = time.time()
    endk = int(np.floor(t / h + 1e-9))
    A_p = np.array([[-1.0, -2.0], [0.0, -3.0]])
    b_p = np.array([2.0, 3.0])
    h_p_T = np.array([1.0, 0.0])
    theta_p_m = np.array([3.0, 1.0, -1.0, -3.0])
    theta_p_M = np.array([8.0, 6.0, 7.0, 3.0])
    Lambda_c, l, _, _ = tf2ss([1], [1, 6, 9])
    l = l[:, 0]
    Gamma = 100.0 * np.eye(4)
    theta_1 = np.zeros((4, endk + 1)); theta_1[:, 0] = theta_p_m
    phi_1 = np.zeros((2, endk + 1)); phi_2 = np.zeros((2, endk + 1))
    phi = np.zeros((4, endk + 1))
    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.4]
    y_p = np.zeros(endk + 1)
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z_p = np.zeros(endk + 1); z_p[0] = h_p_T @ x_p[:, 0]
    z_1 = np.zeros(endk + 1)
    e_1_f = np.zeros(endk + 1); e_1_f[0] = z_1[0] - z_p[0]
    eps_1_f = np.zeros(endk + 1)
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
        z_1[i + 1] = theta_1[:, i] @ phi[:, i]
        e_1_f[i + 1] = z_1[i + 1] - z_p[i + 1]
        m_2 = 1 + phi[:, i] @ phi[:, i]
        eps_1_f[i + 1] = e_1_f[i + 1] / m_2
        dot_theta_1 = (-Gamma * eps_1_f[i + 1]) @ phi[:, i]
        theta_1[:, i + 1] = np.clip(theta_1[:, i] + h * dot_theta_1, theta_p_m, theta_p_M)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return theta_1, z_1, z_p, tempo_1


def main():
    theta_1, z_1, z_p, tempo_1 = L1_SISOF_O2(20, 1e-3)
    print("theta_1(end) =", theta_1[:, -1])


if __name__ == "__main__":
    main()
