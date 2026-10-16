"""Port of dissertation/code/Algoritmos Capítulo 3/L1A_VS_O1.m

Variable-structure ("VS", switched) model-reference control of the first-order
plant dy/dt = -a_p*y + k_p*u (a_p = 1.5, k_p = 3): the gains are switched
k_1 = -k_1_bar*sign(k_p*e_0*y), k_2 = -k_2_bar*sign(k_p*e_0*r) (k_1_bar = 4.5,
k_2_bar = 5), u = k_1*y + k_2*r, reference model a_m = k_m = 5, r = 1,
e_0 = y - y_m (e_0(1) = 0.2).  Forward Euler, step h.

Porting notes:
- np.sign(0) = 0 like MATLAB sign(0).
- Outputs y, y_m (endk+1), u (endk), tempo_1 (endk+1).
- ``main()`` (no MATLAB counterpart) runs t = 12, h = 1e-3 and prints final values.
"""
import numpy as np


def L1A_VS_O1(t, h):
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, a_m, k_m = 1.5, 3, 5, 5
    k_1_bar, k_2_bar = 4.5, 5
    y = np.zeros(endk + 1); y[0] = 0.2
    y_m = np.zeros(endk + 1)
    e_0 = np.zeros(endk + 1); e_0[0] = 0.2
    u = np.zeros(endk); r = np.zeros(endk); tempo = np.zeros(endk)
    tempo_1 = np.zeros(endk + 1)
    for i in range(endk):
        k = i + 1
        r[i] = 1
        k_1 = -k_1_bar * np.sign(k_p * e_0[i] * y[i])
        k_2 = -k_2_bar * np.sign(k_p * e_0[i] * r[i])
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        u[i] = k_1 * y[i] + k_2 * r[i]
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        y_m[i + 1] = y_m[i] + h * (-a_m * y_m[i] + k_m * r[i])
        e_0[i + 1] = y[i + 1] - y_m[i + 1]
    return y, y_m, u, tempo_1


def main():
    y, y_m, u, tempo_1 = L1A_VS_O1(12, 1e-3)
    print("y(end) =", y[-1], " y_m(end) =", y_m[-1])


if __name__ == "__main__":
    main()
