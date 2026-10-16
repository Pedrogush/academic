"""Port of dissertation/code/SISOPLOT_F.m

Plots for Chapter 4 (identification of the 2nd-order SISO plant): for each of the
4 parameters, the level-1 estimate theta_1(i), the level-2 estimate theta_n2(i)
and the level-2 FE estimate theta_n2fe(i) against the true value theta_p(i) and
the bounds theta_p_m(i), theta_p_M(i) (figures 1-4), and the identification
error z_1 - z_p (figure 5).

Porting notes:
- theta_1 may be given as (4, N) (Python ports) or (4, 1, N) (MATLAB layout).
- ``main()`` (no MATLAB counterpart) runs the Chapter 4 ports L1_SISOF_O2,
  L2_5M_SISOF_O2, L2_5M_SISOF_O2_FE with t = 20, h = 1e-3 and plots them.
- MATLAB TeX title 'theta(1)-theta_p(1)' -> mathtext subscript.
"""
import importlib.util
import os

import numpy as np
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))


def _load(folder, name):
    path = os.path.join(HERE, folder, name + ".py")
    spec = importlib.util.spec_from_file_location(name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def SISOPLOT_F(theta_1, theta_n2, theta_n2fe, z1, zp, tempo_1):
    theta_p = [4, 3, 2, 0]
    theta_p_m = [3, 1, -1, -3]
    theta_p_M = [8, 6, 7, 3]
    theta_1 = np.asarray(theta_1).reshape(4, -1)
    theta_n2 = np.asarray(theta_n2).reshape(4, -1)
    theta_n2fe = np.asarray(theta_n2fe).reshape(4, -1)
    endk = theta_1.shape[1]
    for i in range(4):
        plt.figure(i + 1)
        plt.plot(tempo_1, theta_1[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_n2[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_n2fe[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_p[i] * np.ones(endk), linewidth=1.0, linestyle="-.",
                 color=(0, 0, 0))
        plt.legend(["Nível 1", "Nível 2", "Nível 2 FE", "Valor Correto"])
        plt.grid(True)
        plt.title(rf"theta({i + 1})-theta$_p$({i + 1})")
        plt.plot(tempo_1, theta_p_m[i] * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.plot(tempo_1, theta_p_M[i] * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.axis([0, 20, theta_p_m[i], theta_p_M[i]])

    plt.figure(5)
    plt.plot(tempo_1, np.asarray(z1) - np.asarray(zp), linewidth=2.0, linestyle="-.",
             label="Erro de identificacao e(1)")
    plt.legend()
    plt.plot(tempo_1, np.zeros(endk), linewidth=1.0, linestyle="-.", color=(0, 0, 0))
    plt.grid(True)
    plt.axis([0, 20, -0.5, 0.5])


def main():
    folder = "Algoritmos Capítulo 4"
    theta_1, z1, zp, tempo_1 = _load(folder, "L1_SISOF_O2").L1_SISOF_O2(20, 1e-3)
    theta_n2 = _load(folder, "L2_5M_SISOF_O2").L2_5M_SISOF_O2(20, 1e-3)[0]
    theta_n2fe = _load(folder, "L2_5M_SISOF_O2_FE").L2_5M_SISOF_O2_FE(20, 1e-3)[0]
    SISOPLOT_F(theta_1, theta_n2, theta_n2fe, z1, zp, tempo_1)
    plt.show()


if __name__ == "__main__":
    main()
