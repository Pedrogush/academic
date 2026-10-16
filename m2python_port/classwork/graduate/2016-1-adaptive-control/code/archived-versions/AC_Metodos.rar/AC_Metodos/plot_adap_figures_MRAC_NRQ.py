"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/AC_Metodos.rar/AC_Metodos/plot_adap_figures_MRAC_NRQ.m

Plots the MRAC_NRQ output struct in separate figures: model output, plant output
and reference (figure 1), the controller parameters (figure 3), the control
signal (figure 4) and the output error between reference model and plant
(figure 5). (Archived version; the main one uses one 2x2 figure.)

Porting notes:
- The struct is accessed by field name (func['tempo'], ...), like the original.
- MATLAB's TeX labels x_m(1)/x_p(1) -> mathtext. The stray ``set(leg1,...)`` of the
  parameters subplot (it re-styles the previous legend) is dropped.
- Returns the list of Figures (MATLAB returns nothing).
"""
import matplotlib.pyplot as plt
import numpy as np


def plot_adap_figures_MRAC_NRQ(func):
    endk = int(func['endk'])
    tempo = np.ravel(func['tempo'])
    tempo_acesso = tempo[:endk]
    figs = []
    # figura 1: saídas da planta e do modelo de referência, e a referência
    figs.append(plt.figure(1))
    plt.clf()
    ax = plt.gca()
    ax.plot(tempo, func['x_m_out'], color=[0, 0, 0], linewidth=2.0)
    ax.plot(tempo, func['x_p_out'], color=[1, 0, 0], linewidth=2.0, linestyle=':')
    ax.plot(tempo, func['r'], color=[0, 0, 1], linewidth=2.0)
    ax.grid(True)
    ax.legend(['Modelo, $x_m(1)$', 'Planta, $x_p(1)$', 'Referencia'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Saída do sistema', fontsize=14); ax.tick_params(labelsize=14)
    # figura 3: adaptação dos parâmetros no tempo
    figs.append(plt.figure(3))
    plt.clf()
    ax = plt.gca()
    ax.plot(tempo, np.atleast_2d(func['theta']).T, linewidth=2.0)
    ax.grid(True)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Valores dos parâmetros', fontsize=14); ax.tick_params(labelsize=14)
    # figura 4: sinal de controle no tempo
    figs.append(plt.figure(4))
    plt.clf()
    ax = plt.gca()
    ax.plot(tempo, func['u'], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(['Sinal de Controle'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Sinal de Controle', fontsize=14); ax.tick_params(labelsize=14)
    # figura 5: erro de saída
    figs.append(plt.figure(5))
    plt.clf()
    ax = plt.gca()
    ax.plot(tempo_acesso, func['e_o'], color=[0, 0, 0], linewidth=2.0)
    ax.grid(True); ax.legend(['Erro de Saída'], fontsize=14)
    ax.set_xlabel('Tempo (s)', fontsize=14); ax.set_ylabel('Amplitude', fontsize=14)
    ax.set_title('Erro de Saída entre o modelo de referência e a planta', fontsize=14)
    ax.tick_params(labelsize=14)
    return figs
