"""Port of classwork/graduate/2016-1-control-systems/code/traject_test.m

Teste de trajetória para a equação do oscilador de Van der Pol para determinar o
ciclo limite: for theta in 0:0.05:2*pi and x1 in -1:0.05:1 evaluates
x2 = mu*(sin(theta)^2/cos(2*theta))*(1-x1^2)/x1 (x2 = 0 when x1 == 0) and plots it.

Porting notes:
- As in the original, `plot(x1, x2)` is called after the loops, when x1 is the scalar
  last loop value (1). MATLAB then draws each x2 value as a separate one-point line
  (with no marker, i.e. practically nothing visible). The port plots the same points
  (x = 1, y = x2) with '.' markers so they can be seen; this bug is otherwise kept.
- MATLAB ranges built as start + k*step (matches MATLAB's colon here, x1 == 0 exactly
  at k = 20).
- main() uses mu = 1 (the original has no example call).
"""
import numpy as np
import matplotlib.pyplot as plt


def traject_test(mu):
    thetas = 0 + 0.05 * np.arange(int(np.floor(2 * np.pi / 0.05)) + 1)
    x1s = -1 + 0.05 * np.arange(41)
    x2 = np.zeros(len(thetas) * len(x1s))
    k = 0
    with np.errstate(divide='ignore', invalid='ignore'):
        for theta in thetas:
            for x1 in x1s:
                if x1 != 0:
                    x2[k] = mu * (np.sin(theta) ** 2 / np.cos(2 * theta)) * (1 - x1 ** 2) / x1
                else:
                    x2[k] = 0
                k += 1
    fig, ax = plt.subplots()
    ax.plot(np.full_like(x2, x1), x2, linestyle='none', marker='.')
    return x2


def main():
    traject_test(1)
    plt.show()


if __name__ == "__main__":
    main()
