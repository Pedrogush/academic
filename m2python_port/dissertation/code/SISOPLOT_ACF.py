"""Port of dissertation/code/SISOPLOT_ACF.m

Plots for Chapter 5 (adaptive control of the 2nd-order SISO plant, "ACF"): for
each of the 4 plant parameters the level-1, level-2 and level-2 FE estimates
against the true value and bounds (figures 1-4), the control signals of the three
schemes and of the known-parameter controller (figure 5), and the output errors
y - y_m (figure 6).

Porting notes:
- theta_1 may be (4, N) (Python ports) or (4, 1, N) (MATLAB layout).
- As in MATLAB, the control signals are plotted against tempo = tempo_1(1:end-1).
- ``main()`` (no MATLAB counterpart) runs the Chapter 5 ports with t = 20,
  h = 1e-3 and plots them.
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


def SISOPLOT_ACF(theta_1, theta_n2, theta_n2fe, ym, y1, yn2, yn2fe, u1, un2, un2fe,
                 u_est, tempo_1):
    theta_p = [-3, -4, 2, 1]
    theta_p_m = [-8, -6, 1, 0.5]
    theta_p_M = [-0.5, -1.5, 7, 1.5]
    theta_1 = np.asarray(theta_1).reshape(4, -1)
    theta_n2 = np.asarray(theta_n2).reshape(4, -1)
    theta_n2fe = np.asarray(theta_n2fe).reshape(4, -1)
    tempo_1 = np.asarray(tempo_1)
    endk = theta_1.shape[1]
    tempo = tempo_1[:endk - 1]
    for i in range(4):
        plt.figure(i + 1)
        plt.plot(tempo_1, theta_1[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_n2[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_n2fe[i], linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, theta_p[i] * np.ones(endk), linewidth=1.0, linestyle="-.",
                 color=(0, 0, 0))
        plt.legend(["Nível 1", "Nível 2", "Nível 2 FE", "Valor Correto"])
        plt.grid(True)
        plt.title(rf"Estimativa de $\theta_p({i + 1})$")
        plt.plot(tempo_1, theta_p_m[i] * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.plot(tempo_1, theta_p_M[i] * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.axis([0, 20, theta_p_m[i], theta_p_M[i]])

    n = len(tempo)
    plt.figure(5)
    plt.plot(tempo, np.asarray(u1)[:n], linewidth=2.0, linestyle="-.")
    plt.plot(tempo, np.asarray(un2)[:n], linewidth=2.0, linestyle="-.")
    plt.plot(tempo, np.asarray(un2fe)[:n], linewidth=2.0, linestyle="-.")
    plt.plot(tempo, np.asarray(u_est)[:n], linewidth=1.0, linestyle="-.", color=(0, 0, 0))
    plt.legend(["Nível 1", "Nível 2", "Nível 2 FE", "Valor Correto"])
    plt.grid(True)
    plt.title("Sinal de Controle")

    ym = np.asarray(ym)
    plt.figure(6)
    plt.plot(tempo_1, np.asarray(y1) - ym, linewidth=2.0, linestyle="-.")
    plt.plot(tempo_1, np.asarray(yn2) - ym, linewidth=2.0, linestyle="-.")
    plt.plot(tempo_1, np.asarray(yn2fe) - ym, linewidth=2.0, linestyle="-.")
    plt.legend(["Nível 1", "Nível 2", "Nível 2 FE"])
    plt.grid(True)
    plt.title("Erro de Saída")
    plt.plot(tempo_1, np.zeros(endk), linewidth=1.0, linestyle="-.", color=(0, 0, 0))


def main():
    folder = "Algoritmos Capítulo 5"
    t, h = 20, 1e-3
    theta_1, y1, ym, u1, tempo_1 = _load(folder, "L1A_SISOF_O2").L1A_SISOF_O2(t, h)
    theta_n2, yn2, _, un2, _ = _load(folder, "L2A_5M_SISOF_O2").L2A_5M_SISOF_O2(t, h)
    theta_n2fe, yn2fe, _, un2fe, _ = _load(folder, "L2A_5M_SISOF_O2_FE").L2A_5M_SISOF_O2_FE(t, h)
    u_est, _ = _load(folder, "L1A_EST_SISOF_O2").L1A_EST_SISOF_O2(t, h)
    SISOPLOT_ACF(theta_1, theta_n2, theta_n2fe, ym, y1, yn2, yn2fe, u1, un2, un2fe, u_est,
                 tempo_1)
    plt.show()


if __name__ == "__main__":
    main()
