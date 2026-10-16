"""Port of classwork/undergraduate/2015-2-tcc-parameter-estimation-pe-switch-off/code/Parametros de Simulacao/params.m

Parameter script for the TCC simulations (MRAC direto com regra MIT): reference,
plant poles/zeros, ideal controller parameters theta_c*, reference-model parameters,
adaptation gains and the initial controller estimate (85 % of theta_c*). In MATLAB the
script just populates the workspace (for the Simulink models) and echoes each value.

Notes from the original:
  u = theta_1*r + theta_2*y + theta_3*y_ponto
  y2ponto = theta_1p*u - theta_2p*y - theta_3p*y_ponto
  ym2ponto = theta_1m*r + theta_2m*y + theta_3m*y_ponto
  y2ponto = t1p*t1*r + (t1p*t2-t2p)*y + (t1p*t3-t3p)*y_ponto
  t1p*t1 = t1m = 1.5625*t1p;  t1* = 1.5625
  t1p*t2-t2p = t2m = -1.5625*t2p;  t2* = -0.5625*t2p/t1p = -0.5114
  t1p*t3-t3p = t3m = -1.25*t3p = -0.25
Alternative gains (commented out in the original):
  gamma (mit, traj. con 1e4 s) = 1e-3*[0 0.5 0.452 0.07]
  gamma (grad)                 = 1e-3*[0 5 4.52 0.7]

Porting notes:
- Script -> params() returning a dict with the same variable names (instead of
  workspace variables); main() echoes them like MATLAB. MATLAB 1-based it(1), it(2),
  b_MRAC_MIT(2) -> it[0], it[1], b_MRAC_MIT[1].
"""
import numpy as np


def params():
    ref = 1
    it_MRAC_MIT = np.array([10, 1])
    it = it_MRAC_MIT
    b_MRAC_MIT = np.array([0, 11])
    b = b_MRAC_MIT
    a1 = b_MRAC_MIT[1]
    a2 = it[0] * it[1]
    a3 = it[0] + it[1]
    theta_c_estrela_MRAC_DIRETO_MIT = np.array([0, 1.5625, -0.5114, -0.25])
    md_ref_MRAC_DIRETO_MIT = np.array([0, 1.5625, -1.25 * a2, -1.5625 * a3])
    gamma = np.array([0, 1, 1, 1])  # mit
    theta_c_ini = 0.85 * theta_c_estrela_MRAC_DIRETO_MIT
    return dict(ref=ref, it_MRAC_MIT=it_MRAC_MIT, it=it, b_MRAC_MIT=b_MRAC_MIT, b=b,
                a1=a1, a2=a2, a3=a3,
                theta_c_estrela_MRAC_DIRETO_MIT=theta_c_estrela_MRAC_DIRETO_MIT,
                md_ref_MRAC_DIRETO_MIT=md_ref_MRAC_DIRETO_MIT, gamma=gamma,
                theta_c_ini=theta_c_ini)


def main():
    for k, v in params().items():
        print('%-32s = %s' % (k, v))


if __name__ == "__main__":
    main()
