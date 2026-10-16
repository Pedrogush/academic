"""Port of classwork/graduate/2016-1-adaptive-control/code/calc_gamma_0.m

Heuristic order-of-magnitude starting point for each adaptive gain of the MRAC
"aprendizado" experiments:
gamma_0(i) = 10^floor(log10 K - log10 tau_dom - 2 log(ref) + log10 theta*_i
                      - sat0(i-3) log10 tau_men).

Porting notes:
- ``sat0`` exists only in archived-versions/MATLAB_Files_Old.rar; it is loaded from
  its port with importlib (it echoes ``num = ...`` for i >= 4, as in MATLAB).
- Kept as in the original: ``log(ref)`` is the NATURAL log, mixed with log10
  (probably a slip).
- MATLAB's log10 of a negative/zero theta* gives a complex number/-Inf; the port
  uses the same complex principal value (floor applied to real and imaginary parts,
  like MATLAB). The result is returned real when no entry is complex.
"""
import importlib.util
import os
import sys

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


sat0 = _import_from("archived-versions/MATLAB_Files_Old.rar/sat0.py", "sat0")


def _log10(x):
    x = complex(x)
    if x == 0:
        return -np.inf
    v = np.log10(x)
    return v.real if v.imag == 0 else v


def _floor(z):
    if isinstance(z, complex):
        return complex(np.floor(z.real), np.floor(z.imag))
    return np.floor(z)


def calc_gamma_0(K, ref, tau_dom, tau_men, theta_estrela):
    theta_estrela = np.ravel(np.asarray(theta_estrela, float))
    gamma_0 = []
    for i in range(1, len(theta_estrela) + 1):
        number = (_log10(K) - _log10(tau_dom) - 2 * np.log(ref) + _log10(theta_estrela[i - 1])
                  - sat0(i - 3) * _log10(tau_men))
        gamma_0.append(10 ** _floor(number))
    gamma_0 = np.array(gamma_0)
    if np.iscomplexobj(gamma_0) and np.all(gamma_0.imag == 0):
        gamma_0 = gamma_0.real
    return gamma_0
