"""Port of dissertation/code/Algoritmos Capítulo 5/L1A_VS_SISOF_O2.m

Variable-structure (switched) model-reference control of the second-order plant
A_p = [3 4; 1 0], b_p = [1; 0], h_p' = [2 1], reference model
W_m(s) = (s+4)/(s^2+4s+4): u = theta_c'*w, w = [w_1; w_2; y_p; r], with
theta_c,i = -theta_bar_i*sign(e_0*w_i), theta_bar = [3.93 42.5 12 1],
e_0 = y_p - y_m (e_0(1) = y_p(1) = 0.01).  Reference
r = 1 + sin(3t) + sin(1.7t) + sin(t).  Forward Euler, step h.

Porting notes:
- r(1) = 0 and y_m(1) = 0 (MATLAB auto-fill) reproduced; np.sign(0) = 0 = MATLAB.
- After the loop MATLAB sets u(endk+1) = u(endk): u has endk+1 samples.
- Outputs u, y_p, y_m, tempo_1.  ``main()`` runs t = 20, h = 1e-3.
"""
import time

import numpy as np
from scipy.signal import tf2ss


def L1A_VS_SISOF_O2(t, h):
    """[u, y_p, y_m, tempo_1] = L1A_VS_SISOF_O2(t,h)"""
    t0 = time.time()
    endk = int(np.floor(t / h + 1e-9))
    A_p = np.array([[3.0, 4.0], [1.0, 0.0]])
    b_p = np.array([1.0, 0.0])
    h_p_T = np.array([2.0, 1.0])
    A_m, b_m, htm, _ = tf2ss([1, 4], [1, 4, 4])
    b_m = b_m[:, 0]; htm = htm[0]
    theta_bar = np.array([3.93, 42.5, 12.0, 1.0])
    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.4]
    x_m = np.zeros((2, endk + 1))
    y_p = np.zeros(endk + 1); y_p[0] = 0.01
    y_m = np.zeros(endk + 1)
    e_0 = np.zeros(endk + 1); e_0[0] = 0.01
    r = np.zeros(endk + 1)
    u = np.zeros(endk + 1); tempo = np.zeros(endk); tempo_1 = np.zeros(endk + 1)
    w = np.zeros((4, endk + 1)); w_1 = np.zeros(endk + 1); w_2 = np.zeros(endk + 1)
    for i in range(endk):
        k = i + 1
        tempo[i] = h * k
        tempo_1[i + 1] = h * k + h
        r[i + 1] = 1 + np.sin(3 * h * k) + np.sin(1.7 * h * k) + np.sin(h * k)
        theta_c = -theta_bar * np.sign(e_0[i] * np.array([w_1[i], w_2[i], y_p[i], r[i]]))
        u[i] = theta_c @ w[:, i]
        x_p[:, i + 1] = x_p[:, i] + h * (A_p @ x_p[:, i] + b_p * u[i])
        y_p[i + 1] = h_p_T @ x_p[:, i + 1]
        x_m[:, i + 1] = x_m[:, i] + h * (A_m @ x_m[:, i] + b_m * r[i])
        y_m[i + 1] = htm @ x_m[:, i + 1]
        e_0[i + 1] = y_p[i + 1] - y_m[i + 1]
        w_1[i + 1] = w_1[i] + h * (-4 * w_1[i] + u[i])
        w_2[i + 1] = w_2[i] + h * (-4 * w_2[i] + y_p[i])
        w[:, i + 1] = [w_1[i + 1], w_2[i + 1], y_p[i + 1], r[i + 1]]
    u[endk] = u[endk - 1]
    print(f"Elapsed time is {time.time() - t0:.6f} seconds.")
    return u, y_p, y_m, tempo_1


def main():
    u, y_p, y_m, tempo_1 = L1A_VS_SISOF_O2(20, 1e-3)
    print("y_p(end)-y_m(end) =", y_p[-1] - y_m[-1])


if __name__ == "__main__":
    main()
