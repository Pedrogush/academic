"""Port of classwork/graduate/2016-1-control-systems/code/sensorexp.m

Determinação da F.T. de um sensor a partir de dados experimentais: a partir de
pontos (ganho, fase, frequência) lidos de um diagrama de Bode de um sensor de posição,
ajusta-se uma F.T. B(s)/A(s) com numerador de grau 0 e denominador de grau 2 usando
invfreqs (mínimos quadrados de B(jw) - H(jw)A(jw), A mônico), e exibe tf(B, A).

Porting notes:
- invfreqs (Signal Processing Toolbox) is re-implemented below with MATLAB's default
  (non-iterative, unit weights) equation-error algorithm; tf display is a small
  printer. The fit's B and A are printed like the MATLAB echo.
"""
import numpy as np


def invfreqs(h, w, nb, na):
    """MATLAB invfreqs(h, w, nb, na) default algorithm: linear least squares of
    B(jw) - H(jw) A(jw) = 0 with A monic (real and imaginary parts stacked)."""
    h = np.asarray(h, dtype=complex).ravel()
    s = 1j * np.asarray(w, dtype=float).ravel()
    # unknowns: a_1..a_na (coefficients of s^(na-1)..s^0 of A) and b_0..b_nb
    Da = np.column_stack([h * s ** k for k in range(na - 1, -1, -1)])
    Db = -np.column_stack([s ** k for k in range(nb, -1, -1)])
    Dm = np.hstack([Da, Db])
    rhs = -h * s ** na
    M = np.vstack([Dm.real, Dm.imag])
    v = np.concatenate([rhs.real, rhs.imag])
    th = np.linalg.solve(M.T @ M, M.T @ v)
    a = np.concatenate([[1.0], th[:na]])
    b = th[na:]
    return b, a


def _poly_str(p):
    n = len(p) - 1
    out = []
    for i, c in enumerate(p):
        if c == 0:
            continue
        e = n - i
        mon = '' if e == 0 else ('s' if e == 1 else 's^%d' % e)
        cs = format(abs(c), '.4g')
        term = (cs + ' ' + mon).strip() if not (abs(c) == 1 and mon) else mon
        out.append(('-' if c < 0 else '+', term))
    s = ('-' if out[0][0] == '-' else '') + out[0][1]
    for sg, t in out[1:]:
        s += ' %s %s' % (sg, t)
    return s


def main():
    Gain = np.array([4.86, 2.356, 1.038, 0.382, 0.074, 0.016])
    Phase = np.array([-99.43, -106.53, -121.13, -139.85, -164.46, -171.89])
    w = np.array([1.57, 3.14, 6.28, 12.57, 31.42, 62.83])
    H = Gain * np.exp(1j * Phase * np.pi / 180)
    B, A = invfreqs(H, w, 0, 2)
    print('B =', B)
    print('A =', A)
    n, d = _poly_str(B), _poly_str(A)
    wd = max(len(n), len(d))
    print('\n  %s\n  %s\n  %s\n\nContinuous-time transfer function.'
          % (n.center(wd), '-' * wd, d.center(wd)))
    return B, A


if __name__ == "__main__":
    main()
