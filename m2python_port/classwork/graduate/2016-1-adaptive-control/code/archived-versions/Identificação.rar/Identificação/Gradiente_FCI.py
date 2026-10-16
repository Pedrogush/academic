"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/Identificação.rar/Identificação/Gradiente_FCI.m

Função referente à simulação de um sistema de identificação usando o método do gradiente
com função de custo integral (Alunos: Pedro Gushiken e Isaac Dantas; Orientador: Aldayr
Dantas de Araújo).

The plant x' = Ap x + bp u, y = [0 .. 0 1] x is excited by u and integrated with forward
Euler (step h). The filter is given directly as the companion matrix Aw: the regressor
states are driven through l = [1 0 .. 0]' (phi = [fi1; -fi2]) and the output filter
through bw = [0 .. 0 1]', with z1 = Aw(ordem,:) z_est + y. With m^2 = 1 + phi' P phi,
the normalised error is eo = (z1 - theta' phi)/m^2. Adaptive law (gradient with integral
cost): R' = -beta R + phi phi'/m^2, Q' = -beta Q - z1 phi/m^2, theta' = -gama (Q + R
theta). The argument is a struct (dict) whose fields are, in order: t_inicial, t_final,
h, Aw (filter companion matrix), Ap, bp, ordem, P, gama, cond_inicial_p,
cond_inicial_est_p, teta_inicial, beta, refA, refF (see make_struct_Grad); u =
refA*cos(t*refF). Returns the struct of make_struct_out (teta, tempo, z1, z1e, eo,
saida_planta, m, u); plot it with plot_adap_figures_Ident.

Porting notes:
- convert_struct comes from the original "Estrategias Controle Adaptativo" folder and is
  loaded from the sibling port with importlib.
- Arrays are preallocated (MATLAB grows them); teta has shape (2*ordem, N+1) and is
  returned as (2*ordem, 1, N+1) like MATLAB's 3-D array; u, z1, z1e, eo, saida_planta, m
  have N samples (sample 1 is overwritten in the first iteration, as in MATLAB).
- N = (t_final - t_inicial)/h is used like MATLAB's ``for k=1:n`` (floor, with a few-eps
  tolerance).
- gama may be a scalar or a matrix.
- R and Q are initialised with hard-coded 4x4 / 4x1 zeros in MATLAB, so only 2nd-order
  plants (4 parameters) work; kept (numpy raises otherwise).
- Archived version: differs from the main Identificação/Gradiente_FCI.m in that the
  filter is passed directly as the companion matrix Aw (no tf2ss), as described above.
- The archive has no convert_struct/make_struct_out: they are taken from the main ports
  ("Estrategias Controle Adaptativo/convert_struct.py" and
  "Identificação/make_struct_out.py") with importlib.
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

convert_struct = _import_from("../../../Estrategias Controle Adaptativo/convert_struct.py", "convert_struct")
make_struct_out = _import_from("../../../Identificação/make_struct_out.py", "make_struct_out")


def _ncount(n):
    """Number of iterations of MATLAB ``for k=1:n``."""
    return int(np.floor(n + 4 * np.finfo(float).eps * abs(n)))


def _ref(refA, refF, t):
    """MATLAB ``refA*cos(t*refF)`` (scalars, or row refA times column refF)."""
    return float(np.dot(np.ravel(refA), np.cos(t * np.ravel(np.asarray(refF, float)))))


def _gain_times(G, v):
    """MATLAB ``G*v`` for a scalar or matrix gain G and a column vector v."""
    G = np.asarray(G)
    return G * v if G.ndim == 0 else G @ v


def Gradiente_FCI(estrutura_de_entrada):
    # conversão da estrutura de dados para variáveis internas da função
    (t_inicial, t_final, h, Aw, Ap, bp,
     ordem, P, gama, cond_inicial_p, cond_inicial_est_p, teta_inicial,
     beta, refA, refF) = convert_struct(estrutura_de_entrada, 15)

    Aw = np.atleast_2d(np.asarray(Aw, float))
    Ap = np.atleast_2d(np.asarray(Ap, float)); bp = np.ravel(np.asarray(bp, float))
    P = np.atleast_2d(np.asarray(P, float))
    ordem = int(ordem)

    # inicialização
    n = (t_final - t_inicial) / h
    N = _ncount(n)
    L = max(N, 1)
    tempo = np.zeros(N + 1); tempo[0] = t_inicial
    z_est = np.zeros((ordem, N + 1)); z_est[:, 0] = np.ravel(cond_inicial_est_p)
    fi1 = np.zeros((ordem, N + 1))
    fi2 = np.zeros((ordem, N + 1))
    u = np.zeros(L); u[0] = 1
    xps = np.zeros((ordem, N + 1)); xps[:, 0] = np.ravel(cond_inicial_p)
    fi = np.concatenate([fi1[:, 0], fi2[:, 0]])
    ns2 = np.zeros(L); m = np.zeros(L)
    ns2[0] = fi @ P @ fi
    m[0] = np.sqrt(1 + ns2[0])
    teta = np.zeros((2 * ordem, N + 1)); teta[:, 0] = np.ravel(teta_inicial)
    z1e = np.zeros(L); z1e[0] = teta[:, 0] @ fi
    h_transposto = np.zeros(ordem); h_transposto[ordem - 1] = 1
    saida_planta = np.zeros(L); saida_planta[0] = h_transposto @ xps[:, 0]
    z1 = np.zeros(L); z1[0] = Aw[ordem - 1, :] @ z_est[:, 0] + saida_planta[0]
    eo = np.zeros(L); eo[0] = (z1[0] - z1e[0]) / m[0] ** 2
    l = np.zeros(ordem); l[0] = 1
    bw = np.zeros(ordem); bw[ordem - 1] = 1
    Q = np.zeros((4, N + 1))   # Q(:,1,1) = [0 0 0 0] (hard-coded for 4 parameters)
    R = np.zeros((4, 4, N + 1))
    B = beta
    # fim da inicialização

    for k in range(N):
        tempo[k + 1] = tempo[k] + h
        # geração do sinal de referência
        u[k] = _ref(refA, refF, tempo[k])
        # Medição de y(t); esp. estado
        xps_p = Ap @ xps[:, k] + bp * u[k]
        xps[:, k + 1] = xps[:, k] + h * xps_p
        saida_planta[k] = h_transposto @ xps[:, k]
        # Filtragem de y(t)
        z_est_ponto = Aw @ z_est[:, k] + bw * saida_planta[k]
        z_est[:, k + 1] = z_est[:, k] + h * z_est_ponto
        z1[k] = Aw[ordem - 1, :] @ z_est[:, k] + saida_planta[k]
        # Geração do vetor fi
        fi1_p = Aw @ fi1[:, k] + l * u[k]
        fi1[:, k + 1] = fi1[:, k] + h * fi1_p
        fi2_p = Aw @ fi2[:, k] + l * saida_planta[k]
        fi2[:, k + 1] = fi2[:, k] + h * fi2_p
        fi = np.concatenate([fi1[:, k], -fi2[:, k]])
        # sinal de normalização
        ns2[k] = fi @ P @ fi
        m[k] = np.sqrt(1 + ns2[k])
        # lei adaptativa
        z1e[k] = teta[:, k] @ fi
        eo[k] = (z1[k] - z1e[k]) / m[k] ** 2
        # matrizes relacionadas à solução homogênea das equações usando função de custo integral
        R_p = -B * R[:, :, k] + np.outer(fi, fi) / m[k] ** 2
        R[:, :, k + 1] = R[:, :, k] + h * R_p
        Q_p = -B * Q[:, k] - z1[k] * fi / m[k] ** 2
        Q[:, k + 1] = Q[:, k] + h * Q_p
        # geração da lei adaptativa
        teta_p = _gain_times(-np.asarray(gama, float), Q[:, k] + R[:, :, k] @ teta[:, k])
        teta[:, k + 1] = teta[:, k] + h * teta_p

    # conversão dos dados relevantes para a estrutura de saída
    estrutura_de_saida = make_struct_out(teta[:, None, :], tempo, z1, z1e, eo, saida_planta, m, u)
    return estrutura_de_saida
