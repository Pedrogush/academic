"""Port of classwork/graduate/2016-1-control-systems/code/sim_trabalho_sist_cont_controlador_rlocus.m

Trabalho Referente a disciplina de Sistemas de Controle
Professor: Carlos Eduardo Trabuco Dorea
Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia

Simulação em malha fechada do oscilador de Van der Pol forçado com controlador
PID+PID (projeto por lugar das raízes), tratando o problema da regulação em torno
do ponto de equilíbrio [u_barra; 0]. Tudo é integrado por Euler explícito com passo h:
oscilador não linear (2a ordem), sensor de velocidade com integrador saturado
s/((s+0.04)(s+9)) em espaço de estados, e controlador
Gc = 18*(s+1)^4 / (0.0025 s^4 + 0.1 s^3 + s^2) convertido com tf2ss.
Perturbação degrau +1 em t>15 s, retirada em t>35 s, -1 em t>55 s.

Especificações: erro em regime nulo para perturbação degrau, PO% <= 15%,
Ts2% <= 8 s, u_barra = 0.6, mi = 0.5.

FT de malha aberta do sistema sem controlador:
    Gp = tf([0 0 1], [1 -0.32 1]); Gs = tf([0 1 0], [1 9.04 0.36])
FT de malha fechada: Gmf = feedback(Gc*Gp*Gs, 1)
Outras FTs testadas (obs. do original):
    tf2ss(18*[1 16/25 2561/2500 7503/12500], [0.1 1 0 0])
    tf2ss(18*[1 9/5 52/25 102/125], [0.1 1 0 0])

Comando original: sim_trabalho_sist_cont_controlador_rlocus(70,1e-2,0.6,0.5)

Porting notes:
- 1-based -> 0-based: MATLAB step k (1..endk) is Python index k-1; arrays are
  preallocated with their final MATLAB sizes.
- tf2ss -> scipy.signal.tf2ss (same controller canonical form as MATLAB).
- Measurement noise 0.0001*(0.5-rand()) uses np.random.default_rng(seed); the
  stream differs from MATLAB. Extra keyword args: seed, noise (False disables the
  noise term, used for the Octave comparison), plot.
- The function returns a dict with the simulated signals (MATLAB returns nothing).
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import tf2ss


def sim_trabalho_sist_cont_controlador_rlocus(stoptime, h, u_barra, mi, seed=None,
                                              noise=True, plot=True):
    rng = np.random.default_rng(seed)

    # problema da regulação: o sistema é iniciado no ponto de equilíbrio
    referencia = 0
    # magnitude da perturbação introduzida
    perturbacao = 1

    # número de passos a serem dados na simulação
    endk = int(np.floor(stoptime / h))

    # variáveis de estado do oscilador
    x_2_ponto = np.zeros(endk)
    x_ponto = np.zeros(endk + 1)
    x = np.zeros(endk + 1)
    x[0] = u_barra

    # variáveis de estado do sensor de delta (variação do ponto de operação)
    y_ponto = np.zeros((2, endk))
    y = np.zeros((2, endk + 1))
    y_medido = np.zeros(endk + 1)

    # Matrizes de espaço de estado do sensor
    A_sensor = np.array([[-9.04, -0.36], [1.0, 0.0]])
    b_sensor = np.array([1.0, 0.0])
    C_sensor = np.array([0.0, 1.0])

    # Matrizes controlador convertido para espaço de estados
    Ac, bc, Cc, Dc = tf2ss(18 * np.array([1, 4, 6, 4, 1]), [0.0025, 0.1, 1, 0, 0])
    bc = bc[:, 0]
    Cc = Cc[0, :]
    Dc = Dc[0, 0]

    # variáveis de estado do controlador
    # controlador iniciado de forma que seu sinal de controle seja u_barra
    xc = np.zeros((4, endk + 1))
    xc[:, 0] = [0, 0, 0, 0.8333 * 10 ** -4]
    xc_ponto = np.zeros((4, endk))

    r = np.zeros(endk)
    e = np.zeros(endk)
    u = np.zeros(endk)
    entrada_planta = np.zeros(endk)

    tempo = np.zeros(endk + 1)
    for k in range(endk):
        # tempo de simulação
        tempo[k + 1] = tempo[k] + h
        # sinal de referência
        r[k] = referencia

        # controlador: erro de feedback da saída
        e[k] = r[k] - y_medido[k]
        xc_ponto[:, k] = Ac @ xc[:, k] + bc * e[k]
        xc[:, k + 1] = xc[:, k] + h * xc_ponto[:, k]

        # entrada introduzida na planta
        u[k] = Cc @ xc[:, k] + Dc * e[k]
        entrada_planta[k] = u[k]

        # perturbação positiva em 15 s, retirada em 35 s, negativa em 55 s
        if tempo[k] > 15:
            entrada_planta[k] = u[k] + perturbacao
        if tempo[k] > 35:
            entrada_planta[k] = u[k]
        if tempo[k] > 55:
            entrada_planta[k] = u[k] - perturbacao

        # Oscilador de Van Der Pol (Euler)
        x_2_ponto[k] = mi * (1 - x[k] ** 2) * x_ponto[k] - x[k] + entrada_planta[k]
        x_ponto[k + 1] = x_ponto[k] + h * x_2_ponto[k]
        x[k + 1] = x[k] + h * x_ponto[k]

        # Sensor de Velocidade, variáveis de estado
        y_ponto[:, k] = A_sensor @ y[:, k] + b_sensor * x_ponto[k]
        y[:, k + 1] = y[:, k] + h * y_ponto[:, k]

        # 0.0001*(0.5-rand()) <- Ruído (ver comentários no original)
        ruido = 0.0001 * (0.5 - rng.random()) if noise else 0.0
        y_medido[k + 1] = C_sensor @ y[:, k + 1] + ruido

    # artifício para produzir um vetor tempo com 1 valor a menos
    tempo_acesso = tempo[:endk]

    if plot:
        _plot_resultados(tempo, tempo_acesso, y_medido, u, x)

    return dict(tempo=tempo, x=x, x_ponto=x_ponto, y=y, y_medido=y_medido, u=u,
                xc=xc, entrada_planta=entrada_planta)


def _plot_resultados(tempo, tempo_acesso, y_medido, u, x):
    def _fmt(ax, titulo):
        ax.grid(True)
        ax.set_xlabel('Tempo (s)', fontsize=14)
        ax.set_ylabel('Amplitude', fontsize=14)
        ax.set_title(titulo, fontsize=14)
        ax.legend(fontsize=14)
        ax.tick_params(labelsize=14)

    # Figura 1, Medida de delta (desvio do ponto de operação)
    fig, ax = plt.subplots(num=1)
    ax.plot(tempo, y_medido, color=(1, 0, 0), linewidth=2.0, linestyle=':',
            label='Medição Modelo real, $x_p$')
    _fmt(ax, 'Medição de delta')

    # Figura 2, Sinal de Controle
    fig, ax = plt.subplots(num=2)
    ax.plot(tempo_acesso, u, color=(1, 0, 0), linewidth=2.0, linestyle=':',
            label='Sinal de Controle')
    _fmt(ax, 'Sinal de Controle')

    # Figura 3, Saída do oscilador
    fig, ax = plt.subplots(num=3)
    ax.plot(tempo, x, color=(0, 1, 0), linewidth=2.0, linestyle=':',
            label='Saída do Oscilador')
    _fmt(ax, 'Saída do Oscilador')


def main():
    sim_trabalho_sist_cont_controlador_rlocus(70, 1e-2, 0.6, 0.5)
    plt.show()


if __name__ == "__main__":
    main()
