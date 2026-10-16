"""Port of classwork/graduate/2015-2-nonlinear-systems/code/mfase.m

Campo vetorial (quiver) pretendido para o oscilador de Van der Pol x1' = x2,
x2' = -mi*(1 - x1^2)*x2 - x1 (mi = 1) na grade [-2, 2] x [-2, 2] com passo 0.5.

Porting notes:
- BUG in the original, kept by default: `x2d = -mi(1-x1^2)*x2-x1;` uses the matrix
  power x1^2 (= x1*x1, which is the zero matrix here because every row of the meshgrid
  x1 is -2:0.5:2, whose sum is 0), then indexes the scalar mi with the all-ones matrix
  1-x1^2 (giving a 9x9 matrix of mi), then matrix-multiplies by x2 (column sums of x2
  are 0). The net result in MATLAB/Octave is x2d = -x1, i.e. the field of the harmonic
  oscillator, not Van der Pol. The port reproduces this literally (verified in Octave).
- `--intended` (or main(intended=True)) uses the evidently intended elementwise
  expression -mi*(1-x1.^2).*x2 - x1 instead.
- Unused variable c = 1 dropped.
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt


def main(intended=False):
    x1, x2 = np.meshgrid(np.arange(-2, 2.0001, 0.5), np.arange(-2, 2.0001, 0.5))
    mi = 1
    x1d = x2
    if intended:
        x2d = -mi * (1 - x1 ** 2) * x2 - x1
    else:
        # literal MATLAB semantics of -mi(1-x1^2)*x2-x1
        idx = 1 - x1 @ x1                      # matrix power x1^2
        assert np.all(idx == 1), 'MATLAB would raise an indexing error here'
        mi_mat = np.full(idx.shape, mi, dtype=float)   # mi(ones(9)) -> 9x9 of mi
        x2d = -(mi_mat @ x2) - x1              # matrix product, as in MATLAB

    fig, ax = plt.subplots()
    ax.quiver(x1, x2, x1d, x2d)
    plt.show()
    return x1d, x2d


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument('--intended', action='store_true',
                    help='usa a expressão elemento-a-elemento pretendida (Van der Pol)')
    main(ap.parse_args().intended)
