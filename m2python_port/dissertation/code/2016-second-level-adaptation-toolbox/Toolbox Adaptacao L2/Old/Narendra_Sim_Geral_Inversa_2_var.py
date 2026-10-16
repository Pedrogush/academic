"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/Narendra_Sim_Geral_Inversa_2_var.m

Simulação 1 referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Intermediate step between Narendra_Sim_1_Inversa.m (hard-coded) and
Narendra_Sim_Geral_Inversa.m: the same 2-parameter / 3-model inverse-method simulation,
with models, plant, reference model, initial conditions, alfa0 and the constant reference
passed as arguments. Here ``modelos`` holds one model per ROW (theta_iT = modelos(i,1:2)).
Plots alpha_bar versus time.

Porting notes - BUGS of the original, kept:
- ``theta_BARRA = modelos`` (3x2, rows = models) is then used as THETA_BARRA*alpha_bar
  with a 3-vector, a dimension mismatch: the MATLAB function errors at the k_T
  initialisation for any input. The port reproduces this (numpy raises ValueError).
  Pass ``fix_theta_barra=True`` to use transpose(modelos) (as in Narendra_Sim_1_Inversa.m)
  and run the simulation.
- x_3 is initialised with cond_iniciais_i(1:2,1) (column 1, not 3), so x_1(1) = x_3(1),
  E(:,:,1) is singular and E^-1 = Inf: even with the THETA_BARRA fix the run is
  Inf/NaN from the first steps (Octave gives the same).
- ``r(k) = referencia`` has no semicolon in MATLAB (prints each step); not reproduced.
"""
import numpy as np
import matplotlib.pyplot as plt


def _matlab_inv(E):
    """E^-1 like MATLAB/Octave: a singular matrix gives an all-Inf inverse (plus a warning)."""
    try:
        return np.linalg.inv(E)
    except np.linalg.LinAlgError:
        print('warning: matrix singular to machine precision')
        return np.full(E.shape, np.inf)


def Narendra_Sim_Geral_Inversa_2_var(stoptime, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
                                     cond_iniciais_m, cond_iniciais_i, alfa0, referencia,
                                     fix_theta_barra=False):
    modelos = np.atleast_2d(np.asarray(modelos, dtype=float))
    cond_iniciais_i = np.atleast_2d(np.asarray(cond_iniciais_i, dtype=float))
    theta_1T = np.array([modelos[0, 0], modelos[0, 1]])
    theta_2T = np.array([modelos[1, 0], modelos[1, 1]])
    theta_3T = np.array([modelos[2, 0], modelos[2, 1]])
    theta_pT = np.asarray(planta, dtype=float).ravel()
    theta_mT = np.asarray(modelo_de_referencia, dtype=float).ravel()
    A_1 = np.array([[0, 1], theta_1T])
    A_2 = np.array([[0, 1], theta_2T])
    A_3 = np.array([[0, 1], theta_3T])
    A_p = np.array([[0, 1], theta_pT])
    A_m = np.array([[0, 1], theta_mT])
    theta_BARRA = modelos.T if fix_theta_barra else modelos
    b = np.array([0., 1.])
    endk = int(np.floor(stoptime / h))

    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = np.asarray(cond_iniciais_p, dtype=float).ravel()
    x_m = np.zeros((2, endk + 1)); x_m[:, 0] = np.asarray(cond_iniciais_m, dtype=float).ravel()
    x_1 = np.zeros((2, endk + 1)); x_1[:, 0] = cond_iniciais_i[0:2, 0]
    x_2 = np.zeros((2, endk + 1)); x_2[:, 0] = cond_iniciais_i[0:2, 1]
    x_3 = np.zeros((2, endk + 1)); x_3[:, 0] = cond_iniciais_i[0:2, 0]  # sic: column 1
    alfa = np.zeros((2, endk))
    alfa[:, 0] = np.asarray(alfa0, dtype=float).ravel()
    alfa_barra = np.zeros((3, endk + 1))
    alfa_barra[:, 0] = np.append(alfa[:, 0], 1 - alfa[:, 0].sum())
    k_T = np.zeros((2, endk))
    k_T[:, 0] = theta_mT - theta_BARRA @ alfa_barra[:, 0]   # MATLAB errors here (3x2 * 3x1)
    u = np.zeros(endk + 1)
    tempo = np.zeros(endk + 1)
    r = np.zeros(endk)

    for k in range(endk):
        tempo[k + 1] = tempo[k] + h
        r[k] = referencia
        e_1 = x_1[:, k] - x_p[:, k]
        e_2 = x_2[:, k] - x_p[:, k]
        e_3 = x_3[:, k] - x_p[:, k]
        E = np.column_stack((e_1 - e_3, e_2 - e_3))
        alfa[:, k] = -_matlab_inv(E) @ e_3
        alfa_barra[:, k + 1] = np.append(alfa[:, k], 1 - alfa[:, k].sum())
        k_T[:, k] = theta_mT - theta_BARRA @ alfa_barra[:, k]
        u[k + 1] = r[k] + k_T[:, k] @ x_p[:, k]
        x_1[:, k + 1] = x_1[:, k] + h * (A_m @ x_1[:, k] + (A_1 - A_m) @ x_p[:, k] + b * u[k])
        x_2[:, k + 1] = x_2[:, k] + h * (A_m @ x_2[:, k] + (A_2 - A_m) @ x_p[:, k] + b * u[k])
        x_3[:, k + 1] = x_3[:, k] + h * (A_m @ x_3[:, k] + (A_3 - A_m) @ x_p[:, k] + b * u[k])
        x_m[:, k + 1] = x_m[:, k] + h * (A_m @ x_m[:, k] + b * r[k])
        x_p[:, k + 1] = x_p[:, k] + h * (A_p @ x_p[:, k] + b * u[k])

    plt.figure()
    plt.plot(tempo, alfa_barra.T)
    return dict(tempo=tempo, r=r, alfa=alfa, alfa_barra=alfa_barra, k_T=k_T, u=u, x_p=x_p, x_m=x_m,
                x_1=x_1, x_2=x_2, x_3=x_3, endk=endk)


def main():
    # Narendra_Sim_1_Inversa.m data, one model per row; the faithful call fails like MATLAB.
    args = (16, 1e-3, [[-2, -4], [-6, -6], [3, -6]], [-2, -1], [-1, -3], [0.2, 0.1], [0, 0],
            [[2, 1, 0], [2, 0, 0]], [0, 0], 10)
    try:
        Narendra_Sim_Geral_Inversa_2_var(*args)
    except ValueError as exc:
        print('As in MATLAB, the original code fails (dimension mismatch):', exc)
    s = Narendra_Sim_Geral_Inversa_2_var(*args, fix_theta_barra=True)
    print('with fix_theta_barra=True: alfa_barra(:,end) =', s['alfa_barra'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
