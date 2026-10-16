"""Port of dissertation/code/Algoritmos Capítulo 3/L1A_Filtragem_O1.m

First-level (single model) indirect adaptive model-reference control of
dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3): the plant parameters are identified
by filtered linear regression (z = y - lambda*phi_1, z_hat = -hat_a_p*phi_1 +
hat_k_p*phi_2, lambda = 4, gradient laws) and the controller gains are computed
by certainty equivalence, k_1 = (hat_a_p - a_m)/hat_k_p, k_2 = k_m/hat_k_p,
u = k_1*y + k_2*r, reference model a_m = k_m = 5, r = 1.  Forward Euler, step h.

Porting notes:
- Outputs hat_a_p, hat_k_p, y, y_m (endk+1 samples), u (endk), tempo_1 (endk+1).
- ``main()`` (no MATLAB counterpart) runs t = 12, h = 1e-3 and prints final values.
"""
import numpy as np


def L1A_Filtragem_O1(t, h):
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, a_m, k_m, lam = 1.5, 3, 5, 5, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    y_m = np.zeros(endk + 1)
    hat_a_p = np.zeros(endk + 1); hat_a_p[0] = 0.5
    hat_k_p = np.zeros(endk + 1); hat_k_p[0] = 6
    phi_1 = np.zeros(endk + 1); phi_1[0] = 0.2
    phi_2 = np.zeros(endk + 1)
    u = np.zeros(endk); r = np.zeros(endk); tempo = np.zeros(endk)
    tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); z_hat = np.zeros(endk); e_1_f = np.zeros(endk); e_o = np.zeros(endk)
    for i in range(endk):
        k = i + 1
        r[i] = 1
        k_1 = (hat_a_p[i] - a_m) / hat_k_p[i]
        k_2 = k_m / hat_k_p[i]
        u[i] = k_1 * y[i] + k_2 * r[i]
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        y_m[i + 1] = y_m[i] + h * (-a_m * y_m[i] + k_m * r[i])
        e_o[i] = y[i] - y_m[i]
        phi_1[i + 1] = phi_1[i] + h * (-lam * phi_1[i] + y[i])
        phi_2[i + 1] = phi_2[i] + h * (-lam * phi_2[i] + u[i])
        z[i] = y[i] - lam * phi_1[i]
        z_hat[i] = -hat_a_p[i] * phi_1[i] + hat_k_p[i] * phi_2[i]
        e_1_f[i] = z_hat[i] - z[i]
        hat_a_p[i + 1] = hat_a_p[i] + h * (e_1_f[i] * y[i])
        hat_k_p[i + 1] = hat_k_p[i] + h * (-e_1_f[i] * u[i])
    return hat_a_p, hat_k_p, y, y_m, u, tempo_1


def main():
    hat_a_p, hat_k_p, y, y_m, u, tempo_1 = L1A_Filtragem_O1(12, 1e-3)
    print("hat_a_p(end) =", hat_a_p[-1], " hat_k_p(end) =", hat_k_p[-1], " y(end) =", y[-1])


if __name__ == "__main__":
    main()
