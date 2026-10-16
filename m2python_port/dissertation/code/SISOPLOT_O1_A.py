"""Port of dissertation/code/SISOPLOT_O1_A.m

Plots for Chapter 3 (adaptive control of the first-order plant): estimates of a_p
and k_p by level 1 and level 2 (N = 3) with true values and bounds (figures 1-2),
plant outputs of the level-1, level-2 and variable-structure schemes with the
reference model output (figure 3), control signals of the integral-law schemes
and of the known-parameter controller (figure 4) and the switched control signal
of the VS scheme (figure 5).

Porting notes:
- MATLAB extends the control vectors in place (un1o1(endk) = un1o1(endk-1), ...,
  uvso1(end+1) = uvso1(end)); the port does the same on copies.
- ``main()`` (no MATLAB counterpart) runs the Chapter 3 ports with t = 12,
  h = 1e-3 (the VS scheme with the same h) and plots them.
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


def _set_last(v, endk):
    """MATLAB v(endk) = v(endk-1) (grows the vector when needed)."""
    v = np.asarray(v, dtype=float).copy()
    if len(v) < endk:
        v = np.r_[v, np.zeros(endk - len(v))]
    v[endk - 1] = v[endk - 2]
    return v


def SISOPLOT_O1_A(a_f, a_2f3, k_f, k_2f3, yn1, yn2, ym, yvs, un1o1, un2o1, uvso1, uest,
                  tempo_1, tempo_vs):
    endk = len(a_f)
    a_p, a_p_M, a_p_m = 1.5, 4, 0.5
    k_p_M, k_p_m, k_p = 6, 1, 3

    for fig, (v1, v2, val, lo, hi, ttl) in enumerate([
            (a_f, a_2f3, a_p, a_p_m, a_p_M, r"a estimativa - a$_p$"),
            (k_f, k_2f3, k_p, k_p_m, k_p_M, r"k estimativa-k$_p$")], start=1):
        plt.figure(fig)
        plt.plot(tempo_1, v1, linewidth=2.0, linestyle="-.")
        plt.plot(tempo_1, v2, linewidth=3.0, linestyle="-.")
        plt.plot(tempo_1, val * np.ones(endk), linewidth=1.0, linestyle="-.", color=(0, 0, 0))
        plt.legend(["Nível 1 Reg. Linear", "Nível 2 Reg. Lin. N=3", "Valor Correto"])
        plt.grid(True)
        plt.title(ttl)
        plt.plot(tempo_1, lo * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.plot(tempo_1, hi * np.ones(endk), linewidth=1.0, color=(0, 0, 0))
        plt.axis([0, 12, lo, hi])
        plt.gca().tick_params(labelsize=20)

    plt.figure(3)
    plt.plot(tempo_1, ym, linewidth=2.0, linestyle="-.")
    plt.plot(tempo_1, yn1, linewidth=3.0, linestyle="-.")
    plt.plot(tempo_1, yn2, linewidth=3.0, linestyle="-.")
    plt.plot(tempo_vs, yvs, linewidth=1.0, linestyle="-.")
    plt.legend(["Modelo de Referencia", "Nível 1 Reg. Linear", "Nível 2 Reg. Lin. N=3",
                "Estrutura Variavel"])
    plt.grid(True)
    plt.title("saida da planta e do modelo")
    plt.axis([0, 12, 0, 1.25])
    plt.gca().tick_params(labelsize=20)

    un1o1 = _set_last(un1o1, endk)
    un2o1 = _set_last(un2o1, endk)
    uest = _set_last(uest, endk)
    uvso1 = np.r_[np.asarray(uvso1, dtype=float), uvso1[-1]]
    plt.figure(4)
    plt.plot(tempo_1, un1o1, linewidth=3.0, linestyle="-.")
    plt.plot(tempo_1, un2o1, linewidth=3.0, linestyle="-.")
    plt.plot(tempo_1, uest, linewidth=3.0, linestyle="-.")
    plt.legend(["Nível 1 Reg. Linear", "Nível 2 Reg. Lin. N=3", "Parametros Conhecidos"])
    plt.grid(True)
    plt.title("sinal de controle com leis integrais")
    plt.axis([0, 12, 0, 2])
    plt.gca().tick_params(labelsize=20)

    plt.figure(5)
    plt.plot(tempo_vs, uvso1, linewidth=2.0, linestyle="-.")
    plt.legend(["Estrutura Variavel"])
    plt.grid(True)
    plt.title("sinal de controle com leis chaveadas")
    plt.axis([0, 12, -10, 10])
    plt.gca().tick_params(labelsize=20)


def main():
    folder = "Algoritmos Capítulo 3"
    t, h = 12, 1e-3
    a_f, k_f, yn1, ym, un1o1, tempo_1 = _load(folder, "L1A_Filtragem_O1").L1A_Filtragem_O1(t, h)
    a_2f3, k_2f3, yn2, _, un2o1, _ = _load(folder, "L2A_3M_Filtragem_O1").L2A_3M_Filtragem_O1(t, h)
    yvs, _, uvso1, tempo_vs = _load(folder, "L1A_VS_O1").L1A_VS_O1(t, h)
    _, _, uest, _ = _load(folder, "L1A_EST_O1").L1A_EST_O1(t, h)
    SISOPLOT_O1_A(a_f, a_2f3, k_f, k_2f3, yn1, yn2, ym, yvs, un1o1, un2o1, uvso1, uest,
                  tempo_1, tempo_vs)
    plt.show()


if __name__ == "__main__":
    main()
