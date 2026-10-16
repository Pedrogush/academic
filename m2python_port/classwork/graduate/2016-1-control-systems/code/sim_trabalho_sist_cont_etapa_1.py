"""Port of classwork/graduate/2016-1-control-systems/code/sim_trabalho_sist_cont_etapa_1.m

Trabalho Referente a disciplina de Sistemas de Controle
Professor: Carlos Eduardo Trabuco Dorea
Alunos: Pedro Gushiken, Isaac Dantas, Luan Garcia

Etapa 1: simulação (Euler explícito, passo h) do oscilador de Van der Pol forçado,
não linear, em malha fechada com o controlador 18*(s+1)^4/(0.0025 s^4 + 0.1 s^3 + s^2)
realimentando a medição do sensor de velocidade com integrador saturado
s/((s+0.04)(s+9)); simulação paralela do modelo linearizado (4 estados) com a mesma
entrada. Uma perturbação de +1 é aplicada à entrada para t > 10 s e retirada para
t > 30 s. Plota a medição e a posição real (deslocadas de u_barra) e o sinal de controle.

Na linha vermelha, a medição da posição do oscilador (o sensor é de velocidade com
integrador saturado, logo tem zero na origem: s/((s+0.04)(s+9)); no projeto o zero na
origem e o polo próximo dela são desconsiderados - dinâmica não modelada). Na linha
verde, a posição real do oscilador.

Exemplo do original: sim_trabalho_sist_cont_etapa_1(40,1e-1,1.5,0.5)

Porting notes:
- 1-based -> 0-based indexing; arrays preallocated with their final MATLAB sizes.
- The original calls tf2ss inside the loop on every step (constant result); here it
  is computed once before the loop (identical numerics).
- The linearized-model plots are commented out in the original; the linearized
  signals are still computed and returned in the dict (MATLAB returns nothing).
- Extra keyword `plot`.
- With the documented example (h = 0.1) the explicit Euler loop is numerically unstable
  (controller poles at s = -20, h*20 = 2): the states overflow to inf/NaN after ~12 s,
  exactly as in MATLAB/Octave (verified: same NaN onset at step 124). The example is
  kept as main(); overflow warnings are silenced. With h = 1e-2 the loop is stable.
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import tf2ss


def sim_trabalho_sist_cont_etapa_1(stoptime, h, u_barra, mi, plot=True):
    referencia = u_barra
    perturbacao = 1
    A_linearizado = np.array([[-9.04, -0.36, 0, 1],
                              [1, 0, 0, 0],
                              [0, 0, 0, 1],
                              [0, 0, -1, mi * (1 - u_barra ** 2)]])
    b_linearizado = np.array([0.0, 0.0, 0.0, 1.0])
    C_linearizado = np.array([0.0, 1.0, 0.0, 0.0])
    D_linearizado = 0.0

    C_e = np.array([0.0, 0.0, 1.0, 0.0])

    endk = int(np.floor(stoptime / h))

    # inicialização das variáveis em seus respectivos pontos de equilíbrio
    x_2_ponto = np.zeros(endk)
    x_ponto = np.zeros(endk + 1)
    x = np.zeros(endk + 1)
    y_ponto = np.zeros((2, endk))
    y = np.zeros((2, endk + 1))
    y_medido = np.zeros(endk + 1)
    xc = np.zeros((4, endk + 1))
    xc_ponto = np.zeros((4, endk))
    x_lin_ponto = np.zeros((4, endk))
    x_lin = np.zeros((4, endk + 1))
    y_lin_medido = np.zeros(endk + 1)
    y_lin_saida_osc = np.zeros(endk)
    r = np.zeros(endk)
    e = np.zeros(endk)
    u = np.zeros(endk)

    A_sensor = np.array([[-9.04, -0.36], [1.0, 0.0]])
    b_sensor = np.array([1.0, 0.0])

    # controlador (no original, recalculado a cada passo dentro do laço)
    Ac, bc, Cc, Dc = tf2ss(18 * np.array([1, 4, 6, 4, 1]), [0.0025, 0.1, 1, 0, 0])
    bc, Cc, Dc = bc[:, 0], Cc[0, :], Dc[0, 0]

    tempo = np.zeros(endk + 1)
    _err = np.seterr(over='ignore', invalid='ignore')
    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k] = referencia
        # controlador
        e[k] = -y_medido[k]
        xc_ponto[:, k] = Ac @ xc[:, k] + bc * e[k]
        xc[:, k + 1] = xc[:, k] + h * xc_ponto[:, k]
        u[k] = Cc @ xc[:, k] + Dc * e[k]
        if tempo[k] > 10:
            u[k] = u[k] + perturbacao  # + 0.1*sin(tempo(k))
        if tempo[k] > 30:
            u[k] = u[k] - perturbacao

        # Oscilador de Van Der Pol (Euler)
        x_2_ponto[k] = mi * (1 - x[k] ** 2) * x_ponto[k] - x[k] + u[k]
        x_ponto[k + 1] = x_ponto[k] + h * x_2_ponto[k]
        x[k + 1] = x[k] + h * x_ponto[k]
        # Sensor de Velocidade com integrador saturado: s/(s+0.04)(s+9)
        y_ponto[:, k] = A_sensor @ y[:, k] + b_sensor * x_ponto[k]
        y[:, k + 1] = y[:, k] + h * y_ponto[:, k]
        y_medido[k + 1] = np.array([0.0, 1.0]) @ y[:, k + 1]

        # Sistema Linearizado
        x_lin_ponto[:, k] = A_linearizado @ x_lin[:, k] + b_linearizado * u[k]
        x_lin[:, k + 1] = x_lin[:, k] + h * x_lin_ponto[:, k]
        y_lin_medido[k + 1] = C_linearizado @ x_lin[:, k + 1] + D_linearizado * u[k]
        y_lin_saida_osc[k] = C_e @ x_lin[:, k] + D_linearizado * u[k]

    np.seterr(**_err)
    tempo_acesso = tempo[:endk]

    if plot:
        fig, ax = plt.subplots(num=1)
        ax.plot(tempo, y_medido + u_barra, color=(1, 0, 0), linewidth=2.0,
                linestyle=':', label='Medição Modelo real, $x_p$')
        ax.plot(tempo, x + u_barra, color=(0, 1, 0), linewidth=2.0, linestyle=':',
                label='Modelo Real, posição real')
        ax.grid(True)
        ax.legend(fontsize=14)
        ax.set_xlabel('Tempo (s)', fontsize=14)
        ax.set_ylabel('Amplitude', fontsize=14)
        ax.set_title('Saída do sistema linearizado e sistema real', fontsize=14)
        ax.tick_params(labelsize=14)

        fig, ax = plt.subplots(num=2)
        ax.plot(tempo_acesso, u, color=(1, 0, 0), linewidth=2.0, linestyle=':')
        ax.grid(True)

    return dict(tempo=tempo, x=x, x_ponto=x_ponto, y=y, y_medido=y_medido, u=u,
                xc=xc, x_lin=x_lin, y_lin_medido=y_lin_medido,
                y_lin_saida_osc=y_lin_saida_osc)


def main():
    sim_trabalho_sist_cont_etapa_1(40, 1e-1, 1.5, 0.5)
    plt.show()


if __name__ == "__main__":
    main()
