"""Port of dissertation/code/2016-second-level-adaptation-experiments/narendra_2015_sim1.m

Unfinished first attempt to reproduce a simulation of Narendra (2015) on
second-level adaptation for a 3rd-order plant: A_p with unknown entry a31
(alpha* = -20.48) and b_p with unknown b3 (beta* = 6); three identification
models x_i with dx_i/dt = A_m*x_i + b_m*u + [0; 0; alpha_i*x_3 + beta_i*u],
parameter "vertices" Theta_BARRA = [alpha_1..3; beta_1..3] =
[-10 -10 -70; 2 24 2].  Euler loop with h = 1e-3 for 25000 steps.

Porting notes:
- The MATLAB code cannot run: x_p, u and x_i are used before being defined
  (MATLAB stops with "Undefined function or variable 'x_p'" at the first loop
  line), and the model update has inconsistent indexing (x_i(i,k),
  x_i_chapeu_ponto(i,k), x_p(3,i,k), alpha1/beta1 for every model).  The port sets
  up the same data and raises the same kind of error at the same place
  (NameError); no algorithm is invented.
"""
import numpy as np


def narendra_2015_sim1():
    # a31 considerado desconhecido
    A_p = np.array([[-11.62, -15.73, 9.47],
                    [-15.38, -24.27, 14.52],
                    [-30.48, -47.92, 27.89]])
    # b3 considerado desconhecido
    b_p = np.array([3.0, 4.0, 8.0])
    # valores de referência constante
    a31_bar = -10
    b3_bar = 2
    # parâmetros a serem estimados
    alpha_estrela = -20.48
    beta_estrela = 6
    alpha1, alpha2, alpha3 = -10, -10, -70
    beta1, beta2, beta3 = 2, 24, 2
    b_m = np.array([3.0, 4.0, 2.0])
    A_m = np.array([[-11.62, -15.73, 9.47],
                    [-15.38, -24.27, 14.52],
                    [-10.0, -47.92, 27.89]])
    Theta_BARRA = np.array([[alpha1, alpha2, alpha3], [beta1, beta2, beta3]])
    h = 0.001
    _ = (A_p, b_p, a31_bar, b3_bar, alpha_estrela, beta_estrela, b_m, A_m, Theta_BARRA, h)
    # for k=1:25000
    #   x_p_ponto(:,k) = A_p*x_p(:,k) + b_p*u(k);   <- x_p, u undefined in MATLAB
    raise NameError("Undefined function or variable 'x_p' (as in the original MATLAB code: "
                    "x_p, u and x_i are never initialised)")


if __name__ == "__main__":
    try:
        narendra_2015_sim1()
    except NameError as err:
        print("error:", err)
