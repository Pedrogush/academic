"""Port of dissertation/code/Algoritmos Capítulo 3/L2A_3M_Filtragem_O1.m

Second-level indirect adaptive model-reference control of dy/dt = -a_p*y + k_p*u
(a_p = 1.5, k_p = 3) with 3 identification models (filtered linear regression,
algebraic z_hat_i, gradient laws; initial estimates (0.5,1), (0.5,11), (7,1)) and
second-level weights alfa (alfa_3 = 1 - alfa_1 - alfa_2, dalfa/dt =
-E_f'E_f*alfa - E_f'*e_3_f).  The controller uses the combined estimate by
certainty equivalence: k_1 = (hat_a_p_n2 - a_m)/hat_k_p_n2, k_2 = k_m/hat_k_p_n2,
u = k_1*y + k_2*r, reference model a_m = k_m = 5, r = 1; hat_theta_n2(1) =
(0.5, 6).  Forward Euler, step h.

Porting notes:
- Outputs hat_a_p_n2, hat_k_p_n2, y, y_m (endk+1 samples), u (endk), tempo_1.
- ``main()`` (no MATLAB counterpart) runs t = 12, h = 1e-3 and prints final values.
"""
import numpy as np


def L2A_3M_Filtragem_O1(t, h):
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, a_m, k_m, lam = 1.5, 3, 5, 5, 4
    y = np.zeros(endk + 1); y[0] = 0.2
    y_m = np.zeros(endk + 1)
    phi_1 = np.zeros(endk + 1); phi_2 = np.zeros(endk + 1)
    ha = np.zeros((3, endk + 1)); hk = np.zeros((3, endk + 1))
    ha[:, 0] = [0.5, 0.5, 7]
    hk[:, 0] = [1, 11, 1]
    alfa = np.zeros((2, endk + 1)); alfa[:, 0] = [0.5, 0.5]
    alfa_3 = np.zeros(endk + 1)
    hat_a_p_n2 = np.zeros(endk + 1); hat_a_p_n2[0] = 0.5
    hat_k_p_n2 = np.zeros(endk + 1); hat_k_p_n2[0] = 6
    u = np.zeros(endk); r = np.zeros(endk); tempo = np.zeros(endk)
    tempo_1 = np.zeros(endk + 1)
    z = np.zeros(endk); zh = np.zeros((3, endk)); e = np.zeros((3, endk))
    for i in range(endk):
        k = i + 1
        r[i] = 1
        k_1 = (hat_a_p_n2[i] - a_m) / hat_k_p_n2[i]
        k_2 = k_m / hat_k_p_n2[i]
        u[i] = k_1 * y[i] + k_2 * r[i]
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        y_m[i + 1] = y_m[i] + h * (-a_m * y_m[i] + k_m * r[i])
        phi_1[i + 1] = phi_1[i] + h * (-lam * phi_1[i] + y[i])
        phi_2[i + 1] = phi_2[i] + h * (-lam * phi_2[i] + u[i])
        z[i] = y[i] - lam * phi_1[i]
        zh[:, i] = -phi_1[i] * ha[:, i] + phi_2[i] * hk[:, i]
        e[:, i] = zh[:, i] - z[i]
        ha[:, i + 1] = ha[:, i] + h * (e[:, i] * y[i])
        hk[:, i + 1] = hk[:, i] + h * (-e[:, i] * u[i])
        E = np.array([e[0, i] - e[2, i], e[1, i] - e[2, i]])
        dot_alfa = -np.outer(E, E) @ alfa[:, i] - E * e[2, i]
        alfa[:, i + 1] = alfa[:, i] + h * dot_alfa
        alfa_3[i + 1] = 1 - alfa[0, i + 1] - alfa[1, i + 1]
        w = np.array([alfa[0, i + 1], alfa[1, i + 1], alfa_3[i + 1]])
        hat_k_p_n2[i + 1] = w @ hk[:, i + 1]
        hat_a_p_n2[i + 1] = w @ ha[:, i + 1]
    return hat_a_p_n2, hat_k_p_n2, y, y_m, u, tempo_1


def main():
    an2, kn2, y, y_m, u, tempo_1 = L2A_3M_Filtragem_O1(12, 1e-3)
    print("hat_a_p_n2(end) =", an2[-1], " hat_k_p_n2(end) =", kn2[-1], " y(end) =", y[-1])


if __name__ == "__main__":
    main()
