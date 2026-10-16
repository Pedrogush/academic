"""Port of dissertation/code/Algoritmos Capítulo 5/L1A_SISOF_O2.m

First-level indirect adaptive model-reference control ("L1A") of the unstable
second-order SISO plant A_p = [3 4; 1 0], b_p = [1; 0], h_p' = [2 1]
(G_p(s) = (2s+1)/(s^2-3s-4), theta_p = [-3 -4 2 1]) with reference model
W_m(s) = (s+4)/(s^2+4s+4).  Identification by filtered linear regression with
Lambda(s) = (s+3)(s+4): phi = [-phi_1; phi_2], z_p = -[7 12]*phi_1 + y_p,
normalized gradient law (Gamma = 10*I, no projection), theta_1(0) = theta_p_m.
Controller u = theta_c'*w, w = [w_1; w_2; y_p; r] with dw_1/dt = -4w_1 + u,
dw_2/dt = -4w_2 + y_p, and theta_c computed from the estimate by certainty
equivalence: theta_c = [4 - th4/th3; (-4 th1 + th2 + 12)/th3; (th1 - 4)/th3; 1/th3].
Reference r = 1 + sin(3t) + sin(1.7t) + sin(t).  Forward Euler, step h.

Porting notes:
- Outputs theta_1 as (4, endk+1) (MATLAB 4x1x(endk+1)), y_p, y_m (endk+1),
  u (endk), tempo_1 (endk+1).
- MATLAB auto-filled zeros reproduced: r(1) = 0, y_m(1) = 0, phi(:,1) = 0,
  eps_1_f(1) = 0.  y_p(1) = 0.8 is set explicitly (x_p(:,1) = [0.2; 0.4]).
- Unused MATLAB variables (theta_c_est, F, g, Nm_s, alfa, theta_n2, ...) dropped.
- ``_simulate(t, h, y_p0, known)`` is shared with L1A_EST_SISOF_O2 (known=True:
  controller with the true parameters theta_c_est, y_p(1) = 0).
- ``main()`` runs t = 20, h = 1e-3.
"""
import time

import numpy as np
from scipy.signal import tf2ss

THETA_P = np.array([-3.0, -4.0, 2.0, 1.0])
THETA_P_m = np.array([-8.0, -6.0, 1.0, 0.5])
THETA_P_M = np.array([-0.5, -1.5, 7.0, 1.5])


def theta_c_of(th):
    """Certainty-equivalence controller parameters from plant parameters."""
    return np.array([4 - (th[3] / th[2]),
                     (-4 * th[0] + th[1] + 12) / th[2],
                     (th[0] - 4) / th[2],
                     1 / th[2]])


def _simulate(t, h, y_p0=0.8, known=False):
    endk = int(np.floor(t / h + 1e-9))
    A_p = np.array([[3.0, 4.0], [1.0, 0.0]])
    b_p = np.array([1.0, 0.0])
    h_p_T = np.array([2.0, 1.0])
    A_m, b_m, htm, _ = tf2ss([1, 4], [1, 4, 4])
    b_m = b_m[:, 0]; htm = htm[0]
    theta_c_est = theta_c_of(THETA_P)
    Lambda_c, l, _, _ = tf2ss([1], np.convolve([1, 3], [1, 4]))
    l = l[:, 0]
    Gamma = 10.0 * np.eye(4)
    theta_1 = np.zeros((4, endk + 1)); theta_1[:, 0] = THETA_P_m
    theta_c1 = np.zeros((4, endk + 1)); theta_c1[:, 0] = theta_c_of(theta_1[:, 0])
    phi_1 = np.zeros((2, endk + 1)); phi_2 = np.zeros((2, endk + 1))
    phi = np.zeros((4, endk + 1))
    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.4]
    x_m = np.zeros((2, endk + 1))
    y_p = np.zeros(endk + 1); y_p[0] = y_p0
    y_m = np.zeros(endk + 1)
    r = np.zeros(endk + 1)
    u = np.zeros(endk); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    z_p = np.zeros(endk + 1); z_p[0] = h_p_T @ x_p[:, 0]
    z_1 = np.zeros(endk + 1)
    e_1_f = np.zeros(endk + 1); e_1_f[0] = z_1[0] - z_p[0]
    eps_1_f = np.zeros(endk + 1)
    w = np.zeros((4, endk + 1)); w_1 = np.zeros(endk + 1); w_2 = np.zeros(endk + 1)
    for i in range(endk):
        k = i + 1
        tempo[i] = h * k
        tempo_1[i + 1] = h * k + h
        r[i + 1] = 1 + np.sin(3 * h * k) + np.sin(1.7 * h * k) + np.sin(h * k)
        u[i] = (theta_c_est if known else theta_c1[:, i]) @ w[:, i]
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
        z_1[i + 1] = theta_1[:, i] @ phi[:, i]
        e_1_f[i + 1] = z_1[i + 1] - z_p[i + 1]
        m_2 = 1 + phi[:, i] @ phi[:, i]
        eps_1_f[i + 1] = e_1_f[i + 1] / m_2
        theta_1[:, i + 1] = theta_1[:, i] + h * ((-Gamma * eps_1_f[i + 1]) @ phi[:, i])
        theta_c1[:, i + 1] = theta_c_of(theta_1[:, i + 1])
    return dict(endk=endk, theta_1=theta_1, theta_c1=theta_c1, y_p=y_p, y_m=y_m, u=u,
                r=r, w=w, tempo=tempo, tempo_1=tempo_1, z_1=z_1, z_p=z_p, eps_1_f=eps_1_f)


def L1A_SISOF_O2(t, h):
    """[theta_1, y_p, y_m, u, tempo_1] = L1A_SISOF_O2(t,h)"""
    t0 = time.time()
    with np.errstate(divide="ignore", invalid="ignore"):
        s = _simulate(t, h, y_p0=0.8, known=False)
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return s["theta_1"], s["y_p"], s["y_m"], s["u"], s["tempo_1"]


def main():
    theta_1, y_p, y_m, u, tempo_1 = L1A_SISOF_O2(20, 1e-3)
    print("theta_1(end) =", theta_1[:, -1], " y_p(end)-y_m(end) =", y_p[-1] - y_m[-1])


if __name__ == "__main__":
    main()
