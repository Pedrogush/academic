"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/plot_adap_figures_L1.m

Plots (figure 1, 3x1 subplots) the output struct of L1A (or L2AA): first state of the
reference model and of the plant with the reference divided by the static gain, the
control signal, and the 2-norm of the output error.

Porting notes: ``func`` is the Struct returned by L1A/L2AA (attribute or key access).
MATLAB TeX labels -> mathtext. Figure is created/reused with plt.figure(1); plt.show()
is left to the caller.
"""
import numpy as np
import matplotlib.pyplot as plt


def _g(func, name):
    return func[name] if isinstance(func, dict) else getattr(func, name)


def plot_adap_figures_L1(func):
    endk = int(_g(func, "endk"))
    tempo = np.asarray(_g(func, "tempo"))
    tempo_acesso = tempo[:endk]
    x_m = np.asarray(_g(func, "x_m"))
    x_p = np.asarray(_g(func, "x_p"))
    r = np.asarray(_g(func, "r"))
    mref = np.ravel(_g(func, "modelo_de_referencia"))

    fig = plt.figure(1)
    # figura 1, saídas referentes à primeira variável de estado
    ax = fig.add_subplot(3, 1, 1)
    ax.plot(tempo, x_m[0, :], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, x_p[0, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
    ax.plot(tempo, r / abs(mref[0]), color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Modelo, $x_m(1)$", "Planta, $x_p(1)$", "Referencia/Ganho Estático"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Saída do sistema (Método Diferencial)", fontsize=14)

    # figura 2, sinal de controle no tempo
    ax = fig.add_subplot(3, 1, 2)
    ax.plot(tempo_acesso, np.asarray(_g(func, "u")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Sinal de Controle"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Sinal de Controle", fontsize=14)

    # figura 3, norma 2 do erro de saída da planta no tempo
    ax = fig.add_subplot(3, 1, 3)
    ax.plot(tempo_acesso, np.asarray(_g(func, "norm_2_e_o")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Norma 2 do Erro de Saída"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Norma 2 do erro de Saída entre o modelo de referência e a planta", fontsize=14)
    fig.tight_layout()
    return fig
