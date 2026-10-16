"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/AC_Metodos.rar/AC_Metodos/APPC.m

Controle adaptativo de uma planta de grau qualquer usando o método do
posicionamento de polos (APPC) combinado com identificação dos parâmetros da
planta (Aluno: Pedro Gushiken; Orientador: Aldayr Dantas de Araújo). Archived
(earlier, actually adaptive) version.

The plant Zs_estrela/Rs_estrela (tf2ss, forward Euler, step h) is identified by
continuous least squares with forgetting factor on filtered regressors: the
filter is given directly as the companion matrix Aw (regressor states driven
through l = [1 0..0]', output filter through bw = [0..0 1]',
z1 = Aw(ordem,:) z_est + y), P' = Beta P - P phi phi' P/m^2, theta' = P eo phi.
The ESTIMATED polynomials Zs_chapeu = theta(1:n), Rs_chapeu = [1; theta(n+1:2n)]
are used in the Diophantine equation Qm*R*L + Z*P = A_estrela (Sylvester matrix
M_sylv, solved when |det(M)| >= 0.1), and the controller
u = (P/Lambda) e + ((Lambda - Qm L)/Lambda) u is implemented with tf2ss filters,
e = r - y, r = refA*cos(t*refF).

The argument is a struct (dict) with fields, in order: t_inicial, t_final, h, Aw,
~, ~, ordem, P0, Plinha, cond_inicial_p, cond_inicial_est_p, teta_inicial, Beta,
~, ~, refF, refA, Qms, Zs_estrela, Rs_estrela, A_estrela, Lambda. Returns
make_struct_out(teta, tempo, z1, z1e, e, x_p_out, m, u); plot with
plot_adap_figures_APPC.

Porting notes:
- convert_struct and M_sylv are taken from the main "Estrategias Controle
  Adaptativo" ports, and make_struct_out from the "Identificação" port (the local
  archived make_struct_out is the MRAC one, with another signature; with it the
  APPC output could not be plotted), all with importlib.
- BUG KEPT: ``coefs`` is only assigned when |det(M)| >= 0.1; if that fails on the
  first step MATLAB stops with "Undefined variable coefs" (NameError here).
- x_fil1/x_fil2 are preallocated with ``ordem`` rows as in the original (requires
  n+q-1 = ordem). x_fil1_out(k+1) uses the previous output x_fil1_out(k) as the
  feed-through input (kept).
- MATLAB's ``Lambda - conv(Qms,Ls)`` mixes orientations (implicit expansion would
  give a matrix in R2016b+); vectors are 1-D here, i.e. the intended polynomial
  difference.
- ``(M^-1)*A_estrela`` is computed as inv(M) @ A_estrela as in MATLAB.
"""
import importlib.util
import os
import sys
import warnings

import numpy as np
from scipy import signal


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


_EST = "../../../Estrategias Controle Adaptativo/"
convert_struct = _import_from(_EST + "convert_struct.py", "convert_struct")
M_sylv = _import_from(_EST + "M_sylv.py", "M_sylv")
make_struct_out = _import_from("../../../Identificação/make_struct_out.py", "make_struct_out")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _tf2ss(num, den):
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", signal.BadCoefficients)
        A, B, C, D = signal.tf2ss(np.ravel(np.asarray(num, float)), np.ravel(np.asarray(den, float)))
    return A, B[:, 0], C[0, :], float(D[0, 0]) if D.size else 0.0


def _ref(refA, refF, t):
    return float(np.dot(np.ravel(refA), np.cos(t * np.ravel(np.asarray(refF, float)))))


def APPC(estrutura_de_entrada):
    (t_inicial, t_final, h, Aw, _, _, ordem, P0, Plinha, cond_inicial_p,
     cond_inicial_est_p, teta_inicial, Beta, _, _, refF, refA, Qms, Zs_estrela,
     Rs_estrela, A_estrela, Lambda) = convert_struct(estrutura_de_entrada, 22)
    Qms = np.ravel(np.asarray(Qms, float))
    Zs_estrela = np.ravel(np.asarray(Zs_estrela, float))
    Rs_estrela = np.ravel(np.asarray(Rs_estrela, float))
    A_estrela = np.ravel(np.asarray(A_estrela, float))
    Lambda = np.ravel(np.asarray(Lambda, float))
    Aw = np.atleast_2d(np.asarray(Aw, float))
    P0 = np.atleast_2d(np.asarray(P0, float)); Plinha = np.atleast_2d(np.asarray(Plinha, float))
    ordem = int(ordem)

    Ap, bp, Cp, Dp = _tf2ss(Zs_estrela, Rs_estrela)
    q = len(Qms) - 1
    n = len(Rs_estrela) - 1
    endk = (t_final - t_inicial) / h
    K = _ncount(endk)
    L = max(K, 1)
    npar = 2 * ordem

    P = np.zeros((npar, npar, K + 1)); P[:, :, 0] = P0
    teta = np.zeros((npar, K + 1)); teta[:, 0] = np.ravel(teta_inicial)
    tempo = np.zeros(K + 1); tempo[0] = t_inicial
    r = np.zeros(K + 1)
    z_est = np.zeros((ordem, K + 1)); z_est[:, 0] = np.ravel(cond_inicial_est_p)
    fi1 = np.zeros((ordem, K + 1)); fi2 = np.zeros((ordem, K + 1))
    u = np.zeros(K + 1); u[0] = 1
    x_p = np.zeros((n, K + 1)); x_p[:, 0] = np.ravel(cond_inicial_p)
    x_fil1 = np.zeros((ordem, K + 1)); x_fil2 = np.zeros((ordem, K + 1))
    fi = np.concatenate([fi1[:, 0], fi2[:, 0]])
    ns2 = np.zeros(L); m = np.zeros(L)
    ns2[0] = fi @ Plinha @ fi
    m[0] = np.sqrt(1 + ns2[0])
    z1e = np.zeros(L); z1e[0] = teta[:, 0] @ fi
    h_transposto = np.zeros(ordem); h_transposto[ordem - 1] = 1
    x_p_out = np.zeros(K + 1); x_p_out[0] = h_transposto @ x_p[:, 0]
    z1 = np.zeros(L); z1[0] = Aw[ordem - 1, :] @ z_est[:, 0] + x_p_out[0]
    eo = np.zeros(L); eo[0] = (z1[0] - z1e[0]) / m[0] ** 2
    l = np.zeros(ordem); l[0] = 1
    bw = np.zeros(ordem); bw[ordem - 1] = 1
    e = np.zeros(K + 1)
    x_fil1_out = np.zeros(K + 1)
    x_fil2_out = np.zeros(K + 1)
    coefs = None

    for k in range(K):
        tempo[k + 1] = tempo[k] + h
        r[k + 1] = _ref(refA, refF, tempo[k])
        # algoritmo de estimação: filtragem de y(t)
        z_est_ponto = Aw @ z_est[:, k] + bw * x_p_out[k]
        z_est[:, k + 1] = z_est[:, k] + h * z_est_ponto
        z1[k] = Aw[ordem - 1, :] @ z_est[:, k] + x_p_out[k]
        # Geração do vetor fi
        fi1_p = Aw @ fi1[:, k] + l * u[k]
        fi1[:, k + 1] = fi1[:, k] + h * fi1_p
        fi2_p = Aw @ fi2[:, k] + l * x_p_out[k]
        fi2[:, k + 1] = fi2[:, k] + h * fi2_p
        fi = np.concatenate([fi1[:, k], -fi2[:, k]])
        # sinal de normalização
        ns2[k] = fi @ Plinha @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # Cálculo da matriz de ganhos adaptativos P
        Pk = P[:, :, k]
        P_ponto = Beta * Pk - np.outer(Pk @ fi, fi) @ Pk / m[k] ** 2
        P[:, :, k + 1] = Pk + h * P_ponto
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        teta_p = (Pk * eo[k]) @ fi
        teta[:, k + 1] = teta[:, k] + h * teta_p

        Zs_chapeu = teta[:n, k + 1]
        Rs_chapeu = np.concatenate([[1.0], teta[n:2 * n, k + 1]])
        # fim do algoritmo de estimação
        # APPC
        QmRs = np.convolve(Qms, Rs_chapeu)
        M = M_sylv(n, q, QmRs, Zs_chapeu)
        if abs(np.linalg.det(M)) >= 0.1:
            coefs = np.linalg.inv(M) @ A_estrela
        if coefs is None:
            raise NameError("Undefined function or variable 'coefs' (|det(M)| < 0.1 at the first step)")
        Ls = coefs[:n]
        Ps = coefs[n:2 * n + q]

        Afil1, bfil1, Cfil1, Dfil1 = _tf2ss(Ps, Lambda)
        Afil2, bfil2, Cfil2, Dfil2 = _tf2ss(Lambda - np.convolve(Qms, Ls), Lambda)

        x_fil1_ponto = Afil1 @ x_fil1[:, k] + bfil1 * e[k]
        x_fil1[:, k + 1] = x_fil1[:, k] + h * x_fil1_ponto
        x_fil1_out[k + 1] = Cfil1 @ x_fil1[:, k + 1] + Dfil1 * x_fil1_out[k]

        x_fil2_ponto = Afil2 @ x_fil2[:, k] + bfil2 * u[k]
        x_fil2[:, k + 1] = x_fil2[:, k] + h * x_fil2_ponto
        x_fil2_out[k + 1] = Cfil2 @ x_fil2[:, k + 1] + Dfil2 * u[k]

        u[k + 1] = x_fil2_out[k + 1] + x_fil1_out[k + 1]

        x_p_ponto = Ap @ x_p[:, k] + bp * u[k]
        x_p[:, k + 1] = x_p[:, k] + h * x_p_ponto
        x_p_out[k + 1] = Cp @ x_p[:, k + 1] + Dp * u[k]

        e[k + 1] = r[k + 1] - x_p_out[k + 1]

    estrutura_de_saida = make_struct_out(teta[:, None, :], tempo, z1, z1e, e, x_p_out, m, u)
    return estrutura_de_saida
