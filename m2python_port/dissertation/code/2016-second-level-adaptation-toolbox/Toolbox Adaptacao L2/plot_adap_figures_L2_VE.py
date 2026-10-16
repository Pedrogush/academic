"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/plot_adap_figures_L2_VE.m

Função de Plotagem referente à adaptação de Segundo Nível (UFRN/PPgEEC, Pedro Yochinori
Gushiken, orientador Aldayr Dantas de Araújo). Produces, in one window (figure 1, 4x2
grid), the system output, the alphas, the control signal, the output-error norm, the
merit figure eta and, for second-order plants, the trajectory of the plant-parameter
estimate in the 2-D parameter plane (final and initial convex hulls, theta*, theta_0).

Uso: plot_adap_figures_L2_VE(func), func = Struct returned by L2AA (state accessible,
second-order plant without zeros).

Porting notes: MATLAB TeX -> mathtext; subplot(4,2,[1,3]) and subplot(4,2,[6,8]) are
spanning gridspec cells. The MATLAB code sets the alfa-legend font before creating it
(no effect) - ignored. Returns the figure.
"""
import numpy as np
import matplotlib.pyplot as plt


def _g(func, name):
    return func[name] if isinstance(func, dict) else getattr(func, name)


def plot_adap_figures_L2_VE(func):
    endk = int(_g(func, "endk"))
    tempo = np.asarray(_g(func, "tempo"))
    tempo_acesso = tempo[:endk]
    x_m = np.asarray(_g(func, "x_m"))
    x_p = np.asarray(_g(func, "x_p"))
    r = np.asarray(_g(func, "r"))
    mref = np.ravel(_g(func, "modelo_de_referencia"))
    planta = np.ravel(_g(func, "planta"))
    theta_BARRA = np.asarray(_g(func, "theta_BARRA"))
    modelos = np.asarray(_g(func, "modelos"))
    tpe = np.asarray(_g(func, "theta_p_estimativa"))

    fig = plt.figure(1)
    gs = fig.add_gridspec(4, 2)
    # figura 1, saídas
    ax = fig.add_subplot(gs[0:2, 0])
    ax.plot(tempo, x_m[0, :], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, x_p[0, :], color=[1, 0, 0], linewidth=2.0, linestyle=":")
    ax.plot(tempo, r / abs(mref[0]), color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(["Modelo, $x_m(1)$", "Planta, $x_p(1)$", "Referencia/Ganho Estático"], fontsize=10)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Saída do sistema", fontsize=14)
    ax.tick_params(labelsize=10)

    # figura 3, adaptação dos alfas no tempo
    ax = fig.add_subplot(gs[0, 1])
    ax.plot(tempo_acesso, np.asarray(_g(func, "alfa_barra")).T, linewidth=2.0)
    ax.grid(True)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Valores dos alfas", fontsize=14)
    ax.legend([r"$\alpha_1(t)$", r"$\alpha_2(t)$", r"$\alpha_3(t)$"], fontsize=10)
    ax.tick_params(labelsize=10)

    # figura 4, sinal de controle no tempo
    ax = fig.add_subplot(gs[1, 1])
    ax.plot(tempo_acesso, np.asarray(_g(func, "u")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True)
    ax.legend(["u(t)"], fontsize=10)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Sinal de Controle", fontsize=14)
    ax.tick_params(labelsize=10)

    # figura 5, norma 2 do erro de saída
    ax = fig.add_subplot(gs[2, 0])
    ax.plot(tempo_acesso, np.asarray(_g(func, "norm_2_e_o")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True)
    ax.legend([r"$||e_0||_2$"], fontsize=14)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.tick_params(labelsize=10)

    # figura 6 condicional: trajetória no espaço de parâmetros bi-dimensional
    if len(planta) == 2:
        ax = fig.add_subplot(gs[2:4, 1])
        # Tracejado do Fecho Convexo ao final da simulação (theta_BARRA(:,:,endk))
        tb = theta_BARRA[:, :, endk - 1]
        ax.plot(np.r_[tb[0, :], tb[0, 0]], np.r_[tb[1, :], tb[1, 0]],
                color=[1, 0, 1], linewidth=2.0, label="Fecho Final")
        # theta estrela, parâmetros verdadeiros da planta
        ax.plot(planta[0], planta[1], color=[0, 1, 1], linewidth=2.0, marker="o",
                linestyle="none", label=r"$\theta^*$")
        # Fecho Convexo inicial
        ax.plot(np.r_[modelos[0, :], modelos[0, 0]], np.r_[modelos[1, :], modelos[1, 0]],
                color=[1, 0, 0], linewidth=2.0, label="Fecho Inicial")
        # Trajetória da Adaptação de Segundo Nível
        ax.plot(tpe[0, :], tpe[1, :], color=[0, 0, 1], linewidth=2.0, label="Trajetória L2")
        # Estimativa inicial dos parâmetros da planta
        ax.plot([tpe[0, 0], tpe[0, 0]], [tpe[1, 0], tpe[1, 0]], color=[0, 0, 0],
                linewidth=2.0, marker="x", label=r"$\theta_0$")
        ax.grid(True)
        ax.legend(fontsize=10, loc="upper left")
        ax.set_ylabel(r"$\theta_2$", fontsize=14)
        ax.set_xlabel(r"$\theta_1$", fontsize=14)
        ax.set_title("Trajetória dos Parâmetros", fontsize=14)
        ax.tick_params(labelsize=10)

    # figura 7, evolução da figura de mérito eta no tempo
    ax = fig.add_subplot(gs[3, 0])
    ax.plot(tempo, np.asarray(_g(func, "eta")), color=[0, 0, 0], linewidth=2.0)
    ax.grid(True)
    ax.legend([r"$\eta$"], fontsize=14)
    ax.set_xlabel("Tempo (s)", fontsize=14)
    ax.set_ylabel("Amplitude", fontsize=14)
    ax.set_title("Fig. Mérito ETA", fontsize=14)
    ax.tick_params(labelsize=10)
    fig.tight_layout()
    return fig
