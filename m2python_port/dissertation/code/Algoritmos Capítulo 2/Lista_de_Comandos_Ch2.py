"""Port of dissertation/code/Algoritmos Capítulo 2/Lista_de_Comandos_Ch2.m

"Lista de Comandos, Capitulo 2 da Dissertacao": the command list that produces the
Chapter 2 comparison figures.  It runs every identification scheme for t = 30 s,
h = 1e-3 and calls SISOPLOT_O1FONLY (dissertation/code/SISOPLOT_O1FONLY).

Porting notes:
- L1_Paralelo_O1, L1_Serie_Paralelo_O1 and L2_3M_Serie_Paralelo_O1 are called by
  the MATLAB script but are not in the repository (the MATLAB script would stop
  at its first line).  The port skips them with a warning and passes None; their
  results are not plotted by SISOPLOT_O1FONLY anyway (only used for a length).
"""
import importlib.util
import os
import sys
import warnings

import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from L1_Filtragem_O1 import L1_Filtragem_O1  # noqa: E402
from L2_3M_Filtragem_O1 import L2_3M_Filtragem_O1  # noqa: E402
from L2_4M_Filtragem_O1 import L2_4M_Filtragem_O1  # noqa: E402
from L2_8M_Filtragem_O1 import L2_8M_Filtragem_O1  # noqa: E402


def _load_sisoplot():
    path = os.path.join(os.path.dirname(HERE), "SISOPLOT_O1FONLY.py")
    spec = importlib.util.spec_from_file_location("SISOPLOT_O1FONLY", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod.SISOPLOT_O1FONLY


def _missing(name):
    warnings.warn(f"{name}.m is not in the repository; skipped (None)")
    return None, None, None


def main():
    a_pal, k_pal, tempo = _missing("L1_Paralelo_O1")
    a_spal, k_spal, tempo = _missing("L1_Serie_Paralelo_O1")
    a_f, k_f, tempo = L1_Filtragem_O1(30, 1e-3)
    a_2f3, k_2f3, tempo = L2_3M_Filtragem_O1(30, 1e-3)
    a_2f4, k_2f4, tempo = L2_4M_Filtragem_O1(30, 1e-3)
    a_2f8, k_2f8, tempo = L2_8M_Filtragem_O1(30, 1e-3)
    a_2sp3, k_2sp3, _ = _missing("L2_3M_Serie_Paralelo_O1")
    SISOPLOT_O1FONLY = _load_sisoplot()
    SISOPLOT_O1FONLY(a_pal, a_spal, a_f, a_2f3, a_2sp3, a_2f4, a_2f8,
                     k_pal, k_spal, k_f, k_2f3, k_2sp3, k_2f4, k_2f8, tempo)
    plt.show()


if __name__ == "__main__":
    main()
