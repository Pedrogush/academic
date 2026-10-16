"""Port of dissertation/code/PLOT_VS_O2.m

Plots the results of the variable-structure (switched) controller of Chapter 5
(L1A_VS_SISOF_O2): figure 1 the switched control signal, figure 2 the output
error y_p - y_m with the zero line.

Porting notes:
- ``main()`` (no MATLAB counterpart) runs the Chapter 5 port
  L1A_VS_SISOF_O2(20, 1e-3) (imported from its sibling folder) and plots it.
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


def PLOT_VS_O2(uvs, ypvs, ymvs, tempo_1):
    tempo_1 = np.asarray(tempo_1)
    plt.figure(1)
    plt.grid(True)
    plt.plot(tempo_1, uvs, linewidth=2, linestyle="-")
    plt.legend(["Sinal de Controle Chaveado"])

    plt.figure(2)
    plt.grid(True)
    plt.plot(tempo_1, np.asarray(ypvs) - np.asarray(ymvs), linewidth=2, linestyle="-",
             label="Erro de Saída")
    plt.legend()
    plt.plot(tempo_1, np.zeros(len(tempo_1)), linewidth=2, linestyle="-.", color=(0, 0, 0))


def main():
    vs = _load("Algoritmos Capítulo 5", "L1A_VS_SISOF_O2")
    u, y_p, y_m, tempo_1 = vs.L1A_VS_SISOF_O2(20, 1e-3)
    PLOT_VS_O2(u, y_p, y_m, tempo_1)
    plt.show()


if __name__ == "__main__":
    main()
