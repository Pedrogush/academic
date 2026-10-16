"""Port of papers/2016-cba-second-level-adaptation-pe-switch-off/code/plot_adap_figures.m

Plots the output struct of the toolbox simulations (L1A / L2AA, see
dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/) in seven
separate figures: (1) first state of reference model and plant with the reference divided
by the static gain, (2) second state, (3) alphas, (4) control signal, (5) 2-norm of the
output error, (6) for second-order plants the parameter plane with the final hull
theta_BARRA(:,:,endk), theta*, the initial hull and the trajectory of theta_p_hat, and (7)
the merit figure eta.

Porting notes: ``func`` is the Struct/dict returned by L1A/L2AA. Figures are reused with
plt.figure(1..7) (MATLAB's hold on: repeated calls overlay). MATLAB TeX -> mathtext. The
``set(leg1,...)`` before figure 3 (acting on figure 2's legend) is ignored.
"""
import numpy as np
import matplotlib.pyplot as plt


def _g(func, name):
    return func[name] if isinstance(func, dict) else getattr(func, name)


def plot_adap_figures(func):
    endk = int(_g(func, "endk"))
    tempo = np.asarray(_g(func, "tempo"))
    tempo_acesso = tempo[:endk]
    x_m = np.asarray(_g(func, "x_m")); x_p = np.asarray(_g(func, "x_p"))
    r = np.asarray(_g(func, "r"))
    mref = np.ravel(_g(func, "modelo_de_referencia"))
    planta = np.ravel(_g(func, "planta"))

    ax = plt.figure(1).gca()
    ax.plot(tempo, x_m[0, :], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, x_p[0, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
    ax.plot(tempo, r / abs(mref[0]), color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Modelo, $x_m(1)$", "Planta, $x_p(1)$", "Referencia/Ganho Estático"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Saída do sistema (Método Diferencial)", fontsize=14)

    ax = plt.figure(2).gca()
    ax.plot(tempo, x_m[1, :], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, x_p[1, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
    ax.grid(True)
    ax.legend(["Modelo, $x_m(2)$", "Planta, $x_p(2)$"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Saída do sistema (Método Diferencial)", fontsize=14)

    ax = plt.figure(3).gca()
    ax.plot(tempo_acesso, np.asarray(_g(func, "alfa_barra")).T, linewidth=2.0)
    ax.grid(True)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Valores dos alfas", fontsize=14)

    ax = plt.figure(4).gca()
    ax.plot(tempo_acesso, np.asarray(_g(func, "u")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Sinal de Controle"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Sinal de Controle", fontsize=14)

    ax = plt.figure(5).gca()
    ax.plot(tempo_acesso, np.asarray(_g(func, "norm_2_e_o")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Norma 2 do Erro de Saída"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Norma 2 do erro de Saída entre o modelo de referência e a planta", fontsize=14)

    if len(planta) == 2:
        ax = plt.figure(6).gca()
        tb = np.asarray(_g(func, "theta_BARRA"))[:, :, endk - 1]
        ax.plot(np.r_[tb[0, :], tb[0, 0]], np.r_[tb[1, :], tb[1, 0]], color=[1, 0, 1], linewidth=2.0)
        ax.grid(True)
        ax.plot(planta[0], planta[1], color=[0, 1, 1], linewidth=2.0, marker="o", linestyle="none")
        modelos = np.asarray(_g(func, "modelos"))
        ax.plot(np.r_[modelos[0, :], modelos[0, 0]], np.r_[modelos[1, :], modelos[1, 0]],
                color=[1, 0, 0], linewidth=2.0)
        tpe = np.asarray(_g(func, "theta_p_estimativa"))
        ax.plot(tpe[0, :], tpe[1, :], color=[0, 0, 1], linewidth=2.0)

    ax = plt.figure(7).gca()
    ax.plot(tempo, np.asarray(_g(func, "eta")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(["Fig. Mérito ETA"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14); ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Fig. Mérito ETA", fontsize=14)
