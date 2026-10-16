"""Port of classwork/graduate/2016-1-control-systems/code/anotacoes_trabalho.m

Notes file (comments only in the original): performance obtained with different
controller transfer functions, i.e. alternative controllers that were tried in the
closed-loop simulations (see sim_trabalho_sist_cont_controlador_rlocus.py):

    [Ac,bc,Cc,Dc] = tf2ss(18*[1 16/25 2561/2500 7503/12500], [0.1 1 0 0]);
    [Ac,bc,Cc,Dc] = tf2ss(18*[1 9/5 52/25 102/125], [0.1 1 0 0]);

Porting notes:
- The original contains no executable code. The two alternatives are kept as data in
  CONTROLADORES_ALTERNATIVOS (num, den); main() just prints them.
"""
import numpy as np

CONTROLADORES_ALTERNATIVOS = [
    (18 * np.array([1, 16 / 25, 2561 / 2500, 7503 / 12500]), np.array([0.1, 1, 0, 0])),
    (18 * np.array([1, 9 / 5, 52 / 25, 102 / 125]), np.array([0.1, 1, 0, 0])),
]


def main():
    for num, den in CONTROLADORES_ALTERNATIVOS:
        print('num =', num, ' den =', den)


if __name__ == "__main__":
    main()
