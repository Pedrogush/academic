"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/plot_adap_figures_APPC.m

Plots the APPC output struct (unpacked by field order: teta, x = time, z1, z1e,
eo = tracking error e, plant output, m, u) in a 3x2 figure: z1 vs z1e, the
parameter estimates, the error e0, the plant output y, the normalisation m and
the control u.

Porting notes:
- ``x_acesso = x(1:endk-1)`` with endk = length(u) = number of steps + 1, as in MATLAB.
- teta is (npar, 1, K); each row is plotted against time.
- Returns the Figure (MATLAB returns nothing).
"""
import matplotlib.pyplot as plt
import numpy as np

from convert_struct import convert_struct


def plot_adap_figures_APPC(func):
    teta, x, z1, z1e, eo, saida_planta, m, u = convert_struct(func, 8)
    u = np.ravel(u); x = np.ravel(x)
    endk = len(u)
    teta_acesso = np.asarray(teta)[:, 0, :]
    x_acesso = x[:endk - 1]
    fig1 = plt.figure(figsize=(10.24, 7.68))
    ax = fig1.add_subplot(3, 2, 1)
    ax.plot(x_acesso, z1, '-r', linewidth=2)
    ax.plot(x_acesso, z1e, '-b', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['z1(t)', 'z1e(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 2)
    ax.plot(x, teta_acesso.T, linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude')
    ax.legend(['Theta %d(t)' % (c + 1) for c in range(teta_acesso.shape[0])]); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 3)
    ax.plot(x, eo, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['e0(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 4)
    ax.plot(x, saida_planta, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['y(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 5)
    ax.plot(x_acesso, m, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['m(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 6)
    ax.plot(x, u, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['u(t)']); ax.grid(True)
    fig1.tight_layout()
    return fig1
