"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/Old/Narendra_Sim_1_Inversa.m

Simulação 1 referente ao artigo sobre adaptação de segundo nível (Narendra, Wang, Chen,
ACC 2014). Aluno: Pedro Gushiken.

Hard-coded 2-parameter example of second-level adaptation with the inverse method:
three fixed identification models theta_1 = [-2 -4], theta_2 = [-6 -6], theta_3 = [3 -6],
plant theta_p = [-2 -1], reference model theta_m = [-1 -3]. At each step
alpha = -E^{-1} e_3 with E = [e_1 - e_3, e_2 - e_3]; alpha_bar = [alpha; 1 - sum(alpha)],
controller k = theta_m - THETA_BARRA*alpha_bar (one-step shifts as in the MATLAB code:
alfa_barra(:,k+1) from alfa(:,k), u(k+1) from k_T(:,k), the plant uses u(k), u(1) = 0).
Reference r(k) = 10 sin(k h) + 10. Plots alpha_bar versus time.

Porting notes:
- The MATLAB file is named Narendra_Sim_1_Inversa.m but declares
  ``function narendra_sim_inversa(stoptime, h)``; MATLAB calls it by the file name. Both
  names are provided here.
- k_T(:,k) is overwritten inside the loop with alfa_barra(:,k) (the k=1 value uses the
  initial alfa); kept.
- Commented alternative plots (x_p/x_m, u) available from the returned dict.
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


def narendra_sim_inversa(stoptime, h):
    theta_1T = np.array([-2., -4.])
    theta_2T = np.array([-6., -6.])
    theta_3T = np.array([3., -6.])
    theta_pT = np.array([-2., -1.])
    theta_mT = np.array([-1., -3.])
    A_1 = np.array([[0, 1], theta_1T])
    A_2 = np.array([[0, 1], theta_2T])
    A_3 = np.array([[0, 1], theta_3T])
    A_p = np.array([[0, 1], theta_pT])
    A_m = np.array([[0, 1], theta_mT])
    theta_BARRA = np.array([theta_1T, theta_2T, theta_3T]).T
    b = np.array([0., 1.])
    endk = int(np.floor(stoptime / h))

    x_p = np.zeros((2, endk + 1)); x_p[:, 0] = [0.2, 0.1]
    x_m = np.zeros((2, endk + 1)); x_m[:, 0] = [0, 0]
    x_1 = np.zeros((2, endk + 1)); x_1[:, 0] = [2, 2]
    x_2 = np.zeros((2, endk + 1)); x_2[:, 0] = [1, 0]
    x_3 = np.zeros((2, endk + 1)); x_3[:, 0] = [0, 0]
    alfa = np.zeros((2, endk))
    alfa_barra = np.zeros((3, endk + 1))
    alfa_barra[:, 0] = np.append(alfa[:, 0], 1 - alfa[:, 0].sum())
    k_T = np.zeros((2, endk))
    k_T[:, 0] = theta_mT - theta_BARRA @ alfa_barra[:, 0]
    u = np.zeros(endk + 1)
    tempo = np.zeros(endk + 1)
    r = np.zeros(endk)

    for k in range(endk):
        k1 = k + 1
        tempo[k + 1] = tempo[k] + h
        r[k] = 10 * np.sin(k1 * h) + 10
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
    # plt.plot(tempo, x_p.T, 'k', tempo, x_m.T)
    plt.plot(tempo, alfa_barra.T)
    # plt.plot(tempo, u)
    return dict(tempo=tempo, r=r, alfa=alfa, alfa_barra=alfa_barra, k_T=k_T, u=u, x_p=x_p, x_m=x_m,
                x_1=x_1, x_2=x_2, x_3=x_3, endk=endk)


Narendra_Sim_1_Inversa = narendra_sim_inversa


def main():
    s = narendra_sim_inversa(16, 1e-3)
    print('alfa_barra(:,end) =', s['alfa_barra'][:, -1])
    plt.show()


if __name__ == "__main__":
    main()
