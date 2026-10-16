"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/plot_adap_figures_Ident.m

Unpacks an identifier output struct by field order (teta, x = time, z1, z1e,
eo, plant output, m, u) and plots, in a 3x2 figure: z1 vs its estimate z1e,
the parameter estimates theta_i(t), the normalised error e0, the plant output
y, the normalisation signal m and the input u.

Porting notes:
- ``convert_struct`` lives in the "Estrategias Controle Adaptativo" folder of the
  original; it is loaded from the sibling port with importlib.
- teta is (npar, 1, K) as in MATLAB; ``plot(x, teta_acesso)`` plots each row.
- Returns the matplotlib Figure (MATLAB returns nothing); call plt.show() to see it.
"""
import importlib.util
import os
import sys

import matplotlib.pyplot as plt
import numpy as np


def _import_from(relpath, name):
    path = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), relpath))
    d = os.path.dirname(path)
    sys.path.insert(0, d)
    try:
        spec = importlib.util.spec_from_file_location("_m2p_%x" % (hash(path) & 0xFFFFFFFF), path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
    finally:
        sys.path.remove(d)
    return getattr(mod, name)


convert_struct = _import_from("../Estrategias Controle Adaptativo/convert_struct.py", "convert_struct")


def plot_adap_figures_Ident(func):
    teta, x, z1, z1e, eo, saida_planta, m, u = convert_struct(func, 8)
    u = np.ravel(u)
    endk = len(u)
    teta_acesso = np.asarray(teta)[:, 0, :]
    x = np.ravel(x)
    x_acesso = x[:endk]
    fig1 = plt.figure(figsize=(10.24, 7.68))
    ax = fig1.add_subplot(3, 2, 1)
    ax.plot(x_acesso, z1, '-r', linewidth=2)
    ax.plot(x_acesso, z1e, '-b', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude')
    ax.legend(['z1(t)', 'z1e(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 2)
    ax.plot(x, np.real(teta_acesso).T, linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude')
    ax.legend(['Theta %d(t)' % (c + 1) for c in range(teta_acesso.shape[0])])
    ax.grid(True)

    ax = fig1.add_subplot(3, 2, 3)
    ax.plot(x_acesso, np.real(eo), '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['e0(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 4)
    ax.plot(x_acesso, saida_planta, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['y(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 5)
    ax.plot(x_acesso, m, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['m(t)']); ax.grid(True)

    ax = fig1.add_subplot(3, 2, 6)
    ax.plot(x_acesso, u, '-r', linewidth=2)
    ax.set_xlabel('Tempo'); ax.set_ylabel('Amplitude'); ax.legend(['u(t)']); ax.grid(True)
    fig1.tight_layout()
    return fig1
