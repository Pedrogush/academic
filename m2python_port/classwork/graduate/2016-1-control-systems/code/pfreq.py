"""Port of classwork/graduate/2016-1-control-systems/code/pfreq.m

Trabalho Referente a disciplina de Sistemas de Controle
Professor: Carlos Eduardo Trabuco Dorea
Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia

Simulação em malha fechada do oscilador de Van der Pol forçado com dois controladores
em cascata (projeto em frequência), tratando o problema da regulação em torno do ponto
de equilíbrio [u_barra; 0]. Malha interna: controlador estabilizador
Gc = 18*(s^3 + 2.1 s^2 + 1.47 s + 0.343) / (0.1 s^3 + s^2) = 18*(s+0.7)^3/(0.1 s^3 + s^2);
malha externa: compensador avanço Gcf = 1*(s+1)/(0.05 s+1). (Os comentários do original
ainda citam Gc = 18*(s+1)^3/... e Gcf = 0.18*(s+1)/(0.05s+1).) Oscilador, sensor s/((s+0.04)(s+9)) e controladores são
integrados por Euler explícito com passo h. Perturbação degrau +1 em t>15 s, retirada
em t>35 s, -1 em t>55 s.

Especificações: erro em regime nulo para perturbação degrau,
PO% <= 15% <-> MF >= 30 graus, MG >= 6 dB; Ts2% <= 8 s <-> banda passante >= 10 rad/s;
u_barra = 0.6, mi = 0.5.

FTs: Gp = tf([0 0 1], [1 -0.32 1]); Gs = tf([0 1 0], [1 9.04 0.36]);
Gma = feedback(Gc*Gp*Gs, 1); bode(Gma), margin(Gma); bode(Gcf); margin(Gcf*Gma)
(ver passo_a_passo_freq.py).

Comando original: pfreq(70,1e-2,0.6,0.5)

Porting notes:
- 1-based -> 0-based indexing; arrays preallocated with their final MATLAB sizes.
- tf2ss -> scipy.signal.tf2ss (same controller canonical form as MATLAB).
- The measurement noise term is commented out in the original (deterministic run);
  it is kept as an opt-in keyword `noise=False` (with `seed`) for convenience.
- Extra keyword `plot`; the function returns a dict of signals (MATLAB returns nothing).
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import tf2ss


def pfreq(stoptime, h, u_barra, mi, seed=None, noise=False, plot=True):
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

    # variáveis de estado do sensor de delta
    y_ponto = np.zeros((2, endk))
    y = np.zeros((2, endk + 1))
    y_medido = np.zeros(endk + 1)

    # Matrizes de espaço de estado do sensor
    A_sensor = np.array([[-9.04, -0.36], [1.0, 0.0]])
    b_sensor = np.array([1.0, 0.0])
    C_sensor = np.array([0.0, 1.0])

    # Matrizes do controlador para estabilização convertido para espaço de estados
    Ac, bc, Cc, Dc = tf2ss(18 * np.array([1, 2.1, 1.47, 0.343]), [0.1, 1, 0, 0])
    bc, Cc, Dc = bc[:, 0], Cc[0, :], Dc[0, 0]

    # Matriz do controlador por projeto em frequência: avanço
    Acf, bcf, Ccf, Dcf = tf2ss(1 * np.array([1, 1]), [0.05, 1])
    bcf, Ccf, Dcf = bcf[:, 0], Ccf[0, :], Dcf[0, 0]

    # variáveis de estado dos controladores
    # controlador iniciado de forma que seu sinal de controle seja u_barra
    xc = np.zeros((3, endk + 1))
    xc[:, 0] = [0, 0, 0.0097]
    xc_ponto = np.zeros((3, endk))
    xcf = np.zeros((1, endk + 1))
    xcf_ponto = np.zeros((1, endk))

    r = np.zeros(endk)
    e1 = np.zeros(endk)
    e = np.zeros(endk)
    uf = np.zeros(endk)
    u = np.zeros(endk)
    entrada_planta = np.zeros(endk)

    tempo = np.zeros(endk + 1)
    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k] = referencia
        e1[k] = r[k] - y_medido[k]

        # controlador por projeto em frequência
        xcf_ponto[:, k] = Acf @ xcf[:, k] + bcf * e1[k]
        xcf[:, k + 1] = xcf[:, k] + h * xcf_ponto[:, k]
        uf[k] = Ccf @ xcf[:, k] + Dcf * e1[k]

        # erro de feedback da saída
        e[k] = uf[k] - y_medido[k]

        # controlador estabilizador
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

        # Sensor de Velocidade
        y_ponto[:, k] = A_sensor @ y[:, k] + b_sensor * x_ponto[k]
        y[:, k + 1] = y[:, k] + h * y_ponto[:, k]

        # + 0.0001*(0.5-rand()) <- ruído comentado no original
        ruido = 0.0001 * (0.5 - rng.random()) if noise else 0.0
        y_medido[k + 1] = C_sensor @ y[:, k + 1] + ruido

    tempo_acesso = tempo[:endk]

    if plot:
        _plot_resultados(tempo, tempo_acesso, y_medido, u, x)

    return dict(tempo=tempo, x=x, x_ponto=x_ponto, y=y, y_medido=y_medido, u=u,
                uf=uf, xc=xc, xcf=xcf, entrada_planta=entrada_planta)


def _plot_resultados(tempo, tempo_acesso, y_medido, u, x):
    def _fmt(ax, titulo):
        ax.grid(True)
        ax.set_xlabel('Tempo (s)', fontsize=14)
        ax.set_ylabel('Amplitude', fontsize=14)
        ax.set_title(titulo, fontsize=14)
        ax.legend(fontsize=14)
        ax.tick_params(labelsize=14)

    fig, ax = plt.subplots(num=1)
    ax.plot(tempo, y_medido, color=(1, 0, 0), linewidth=2.0, linestyle=':',
            label='Medição Modelo real, $x_p$')
    _fmt(ax, 'Medição de delta')

    fig, ax = plt.subplots(num=2)
    ax.plot(tempo_acesso, u, color=(1, 0, 0), linewidth=2.0, linestyle=':',
            label='Sinal de Controle')
    _fmt(ax, 'Sinal de Controle')

    fig, ax = plt.subplots(num=3)
    ax.plot(tempo, x, color=(0, 1, 0), linewidth=2.0, linestyle=':',
            label='Saída do Oscilador')
    _fmt(ax, 'Saída do Oscilador')


def main():
    pfreq(70, 1e-2, 0.6, 0.5)
    plt.show()


if __name__ == "__main__":
    main()
