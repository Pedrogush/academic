"""Port of dissertation/code/Algoritmos Capítulo 3/L1A_EST_O1.m

Model-reference control of the first-order plant dy/dt = -a_p*y + k_p*u
(a_p = 1.5, k_p = 3) with *known* parameters ("EST" = estático/ideal controller):
u = k_1*y + k_2*r with k_1 = (a_p - a_m)/k_p, k_2 = k_m/k_p, so that y follows the
reference model dy_m/dt = -a_m*y_m + k_m*r (a_m = k_m = 5), r = 1.
Forward Euler, step h.

Porting notes:
- Outputs y, y_m, u, tempo_1 keep MATLAB lengths (endk+1, endk+1, endk, endk+1;
  tempo_1[0] = 0).
- ``main()`` (no MATLAB counterpart) runs t = 12, h = 1e-3 and prints final values.
"""
import numpy as np


def L1A_EST_O1(t, h):
    endk = int(np.floor(t / h + 1e-9))
    a_p, k_p, a_m, k_m = 1.5, 3, 5, 5
    k_1_est = (a_p - a_m) / k_p
    k_2_est = k_m / k_p
    y = np.zeros(endk + 1); y[0] = 0.2
    y_m = np.zeros(endk + 1)
    u = np.zeros(endk); r = np.zeros(endk); tempo = np.zeros(endk)
    tempo_1 = np.zeros(endk + 1); e_o = np.zeros(endk)
    for i in range(endk):
        k = i + 1
        r[i] = 1
        tempo[i] = h * k
        tempo_1[i + 1] = h + h * k
        u[i] = k_1_est * y[i] + k_2_est * r[i]
        y[i + 1] = y[i] + h * (-a_p * y[i] + k_p * u[i])
        y_m[i + 1] = y_m[i] + h * (-a_m * y_m[i] + k_m * r[i])
        e_o[i] = y[i] - y_m[i]
    return y, y_m, u, tempo_1


def main():
    y, y_m, u, tempo_1 = L1A_EST_O1(12, 1e-3)
    print("y(end) =", y[-1], " y_m(end) =", y_m[-1], " u(end) =", u[-1])


if __name__ == "__main__":
    main()
