"""Port of classwork/graduate/2016-1-control-systems/code/passo_a_passo_freq.m

Projeto em frequência, passo a passo. Parte do passo 3 do projeto por lugar das
raízes: Gcc3 = (s+0.7)^3/(s^2 (0.1 s+1)) estabiliza a malha interna com kp = 18
(Gcc3 = 18*(s^3 + 2.1 s^2 + 1.47 s + 0.343)/(0.1 s^3 + s^2)); a malha interna fechada
Gma = feedback(Gcc3*Gp*Gs, 1) é analisada com margin (margens de ganho e fase), e um
compensador avanço Gcf = 0.3*(s+1)/(0.05 s+1) desloca a frequência de cruzamento para
a direita e melhora a margem de fase (bode(Gcf), margin(Gcf*Gma)).
Gp = 1/(s^2 - 0.32 s + 1) (planta linearizada), Gs = s/(s^2 + 9.04 s + 0.36) (sensor).

Porting notes:
- No python-control: tf, multiplication, feedback, rlocus, bode and margin are
  implemented below with numpy/scipy (margin evaluated on a dense log frequency grid
  with linear interpolation of the crossings; with several crossings the smallest
  margins are reported). Margin values are also printed.
- MATLAB echoes the TFs (no semicolon); they are printed in a similar format.
- `pause` -> pausa(): waits for Enter only when stdin is a terminal.
- MATLAB reuses one figure/axes; here each plot gets its own figure, and the axis
  limits are applied to the root-locus figure as in the original.
- The original prints 'PROJETO POR ROOT LOCUS' at the start (copied from the root
  locus script); kept.
"""
import sys

import numpy as np
import matplotlib.pyplot as plt


# ---------------------------------------------------------------------------
# Minimal replacements for Control System Toolbox functions (tf, *, feedback,
# rlocus, bode, margin) built on numpy / scipy.signal.
# ---------------------------------------------------------------------------
def _poly_clean(p):
    p = np.atleast_1d(np.asarray(p, dtype=complex))
    p = np.real_if_close(p, tol=1000)
    nz = np.flatnonzero(p != 0)
    return p[nz[0]:] if nz.size else np.zeros(1, dtype=p.dtype)


def _poly_str(p, var='s'):
    terms = []
    n = len(p) - 1
    for i, c in enumerate(p):
        if c == 0:
            continue
        e = n - i
        if np.iscomplexobj(c) and np.imag(c) != 0:
            cs = '(%s)' % format(complex(c), '.4g')
            sign = '+'
        else:
            c = float(np.real(c))
            sign = '-' if c < 0 else '+'
            c = abs(c)
            cs = '' if (c == 1 and e > 0) else format(c, '.4g')
        mon = '' if e == 0 else (var if e == 1 else '%s^%d' % (var, e))
        term = (cs + (' ' if cs and mon else '') + mon) or '1'
        terms.append((sign, term))
    if not terms:
        return '0'
    s = ('-' if terms[0][0] == '-' else '') + terms[0][1]
    for sign, term in terms[1:]:
        s += ' %s %s' % (sign, term)
    return s


class TF:
    """Continuous-time SISO transfer function num(s)/den(s) (MATLAB `tf`)."""

    def __init__(self, num, den):
        self.num = _poly_clean(num)
        self.den = _poly_clean(den)

    def __mul__(self, other):
        if isinstance(other, TF):
            return TF(np.polymul(self.num, other.num), np.polymul(self.den, other.den))
        return TF(other * self.num, self.den)

    __rmul__ = __mul__

    def poles(self):
        return np.roots(self.den)

    def zeros(self):
        return np.roots(self.num)

    def freqresp(self, w):
        s = 1j * np.asarray(w, dtype=float)
        return np.polyval(self.num, s) / np.polyval(self.den, s)

    def __str__(self):
        n = _poly_str(self.num)
        d = _poly_str(self.den)
        width = max(len(n), len(d))
        return ('\n  %s\n  %s\n  %s\n\nContinuous-time transfer function.\n'
                % (n.center(width), '-' * width, d.center(width)))


def tf(num, den):
    return TF(num, den)


def feedback(G, H=1, sign=-1):
    """MATLAB feedback(G,H): G/(1 - sign*G*H), without pole-zero cancellation."""
    if not isinstance(H, TF):
        H = TF([H], [1])
    num = np.polymul(G.num, H.den)
    den = np.polyadd(np.polymul(G.den, H.den), -sign * np.polymul(G.num, H.num))
    return TF(num, den)


def show(name, G):
    print('%s =\n%s' % (name, G))


def pausa():
    print('(pausa)')
    if sys.stdin is not None and sys.stdin.isatty():
        try:
            input()
        except EOFError:
            pass


def rlocus(G, ax=None, gains=None):
    """Root locus of 1 + k*G(s) = 0: closed-loop roots over a gain grid (np.roots),
    branches tracked by nearest-root assignment."""
    from scipy.optimize import linear_sum_assignment
    if ax is None:
        fig, ax = plt.subplots()
    if gains is None:
        gains = np.concatenate([[0], np.logspace(-4, 5, 4000)])
    n = len(G.den) - 1
    num = np.concatenate([np.zeros(len(G.den) - len(G.num)), G.num])
    R = np.zeros((len(gains), n), dtype=complex)
    prev = None
    for i, k in enumerate(gains):
        r = np.roots(G.den + k * num)
        r = np.concatenate([r, np.full(n - len(r), np.inf + 0j)])
        if prev is not None:
            cost = np.abs(prev[:, None] - r[None, :])
            cost[~np.isfinite(cost)] = 1e300
            _, col = linear_sum_assignment(cost)
            r = r[col]
        R[i] = r
        prev = r
    for j in range(n):
        ax.plot(R[:, j].real, R[:, j].imag, linewidth=1.2)
    p, z = G.poles(), G.zeros()
    ax.plot(p.real, p.imag, 'x', markersize=9, mew=1.5, color='k')
    if z.size:
        ax.plot(z.real, z.imag, 'o', markersize=8, mfc='none', color='k')
    ax.axhline(0, color='0.6', linestyle=':', linewidth=0.8)
    ax.axvline(0, color='0.6', linestyle=':', linewidth=0.8)
    ax.set_title('Root Locus')
    ax.set_xlabel('Real Axis (seconds$^{-1}$)')
    ax.set_ylabel('Imaginary Axis (seconds$^{-1}$)')
    ax.grid(True)
    return R, gains


def _wgrid(G, npts=20000):
    pz = np.concatenate([G.poles(), G.zeros()])
    mags = np.abs(pz[np.abs(pz) > 1e-9])
    lo = np.floor(np.log10(mags.min())) - 1 if mags.size else -2
    hi = np.ceil(np.log10(mags.max())) + 1 if mags.size else 2
    return np.logspace(lo, hi, npts)


def bode(G, w=None, axes=None):
    """Bode diagram (magnitude in dB, unwrapped phase in degrees)."""
    if w is None:
        w = _wgrid(G)
    H = G.freqresp(w)
    mag = 20 * np.log10(np.abs(H))
    ph = np.degrees(np.unwrap(np.angle(H)))
    if axes is None:
        fig, axes = plt.subplots(2, 1, sharex=True)
    axes[0].semilogx(w, mag)
    axes[0].set_ylabel('Magnitude (dB)')
    axes[0].set_title('Bode Diagram')
    axes[1].semilogx(w, ph)
    axes[1].set_ylabel('Phase (deg)')
    axes[1].set_xlabel('Frequency (rad/s)')
    for a in axes:
        a.grid(True, which='both')
    return mag, ph, w, axes


def _crossings(w, f, level):
    """Frequencies where f(w) crosses `level` (linear interpolation in log w)."""
    d = f - level
    idx = np.flatnonzero(np.sign(d[:-1]) * np.sign(d[1:]) < 0)
    lw = np.log10(w)
    out = [10 ** (lw[i] - d[i] * (lw[i + 1] - lw[i]) / (d[i + 1] - d[i])) for i in idx]
    return np.array(out)


def margin(G, w=None, plot=True):
    """Gain/phase margins (MATLAB margin): returns Gm (abs), Pm (deg), Wcg, Wcp.
    When several crossings exist, the smallest margins are reported."""
    if w is None:
        w = _wgrid(G, 200000)
    H = G.freqresp(w)
    mag = 20 * np.log10(np.abs(H))
    ph = np.degrees(np.unwrap(np.angle(H)))
    # gain crossover(s) -> phase margin
    Pm, Wcp = np.inf, np.nan
    for wc in _crossings(w, mag, 0.0):
        phc = np.degrees(np.angle(G.freqresp([wc])[0]))
        pm = (phc + 180.0) % 360.0
        pm = pm - 360.0 if pm > 180.0 else pm
        if abs(pm) < abs(Pm):
            Pm, Wcp = pm, wc
    # phase crossover(s) -> gain margin
    Gm, Wcg = np.inf, np.nan
    kmin = int(np.floor((ph.min() + 180) / 360)) - 1
    kmax = int(np.ceil((ph.max() + 180) / 360)) + 1
    for kk in range(kmin, kmax + 1):
        for wc in _crossings(w, ph, -180.0 + 360.0 * kk):
            gm = 1.0 / np.abs(G.freqresp([wc])[0])
            if abs(np.log10(gm)) < abs(np.log10(Gm)) or not np.isfinite(Gm):
                Gm, Wcg = gm, wc
    if plot:
        _, _, _, axes = bode(G, w[::20])
        axes[0].set_title('Bode Diagram\nGm = %.3g dB (at %.3g rad/s) ,  Pm = %.3g deg (at %.3g rad/s)'
                          % (20 * np.log10(Gm), Wcg, Pm, Wcp))
        if np.isfinite(Wcp):
            axes[0].axhline(0, color='k', linestyle=':', linewidth=0.8)
            axes[1].axvline(Wcp, color='k', linestyle=':', linewidth=0.8)
        if np.isfinite(Wcg):
            axes[0].axvline(Wcg, color='k', linestyle=':', linewidth=0.8)
    return Gm, Pm, Wcg, Wcp


def main():
    Gp = tf([0, 0, 1], [1, -0.32, 1])
    show('Gp', Gp)
    Gs = tf([0, 1, 0], [1, 9.04, 0.36])
    show('Gs', Gs)
    print('PROJETO POR ROOT LOCUS')
    print('Gp é a FT da planta linearizada, usada apenas para o projeto')
    print('Gs é a FT do sensor.')
    print('aperte uma tecla para continuar')
    pausa()

    Gcc3 = tf([1, 0.7], [1, 0]) * tf([1, 0.7], [1, 0]) * tf([1, 0.7], [0.1, 1])
    show('Gcc3', Gcc3)
    print('Partimos do passo 3 para o projeto em frequência, pois sabemos que')
    print('necessitamos de um sistema estável para este tipo de projeto')
    print('aperte uma tecla para continuar')
    pausa()

    print('ROOT LOCUS')
    fig, ax = plt.subplots()
    rlocus(Gcc3 * Gp * Gs, ax)
    ax.set_xlim(-2, 2)
    ax.set_ylim(-5, 5)
    print('fazemos apenas o suficiente para atrair os polos da malha interna')
    print('para dentro do semi plano esquerdo, escolhendo kp=18')
    print('aperte uma tecla para continuar')
    pausa()

    Gcc3 = tf(18 * np.array([1, 2.1, 1.47, 0.343]), [0.1, 1, 0, 0])
    Gma = feedback(Gcc3 * Gp * Gs, 1)
    show('Gma', Gma)
    print('função de transferência do sistema estabilizado')
    print('aperte uma tecla para continuar')
    pausa()

    print('DIAGRAMA DE BODE')
    Gm, Pm, Wcg, Wcp = margin(Gma)
    print('margin(Gma): Gm = %.4g dB (at %.4g rad/s), Pm = %.4g deg (at %.4g rad/s)'
          % (20 * np.log10(Gm), Wcg, Pm, Wcp))
    print('vemos que a margem de fase e largura de banda estão abaixo das especificações')
    print('projetamos um controlador avanço para compensar')
    print('aperte uma tecla para continuar')
    pausa()

    Gcf = tf(0.3 * np.array([1, 1]), [0.05, 1])
    show('Gcf', Gcf)
    print('com isso, deslocamos a frequência de cruzamento para a direita')
    print('e melhoramos a margem de fase')
    print('aperte uma tecla para continuar')
    pausa()

    print('DIAGRAMA DE BODE DO CONTROLADOR')
    bode(Gcf)
    print('aperte uma tecla para continuar')
    pausa()

    print('DIAGRAMA DE BODE DO CONTROLADOR + PLANTA')
    Gm, Pm, Wcg, Wcp = margin(Gcf * Gma)
    print('margin(Gcf*Gma): Gm = %.4g dB (at %.4g rad/s), Pm = %.4g deg (at %.4g rad/s)'
          % (20 * np.log10(Gm), Wcg, Pm, Wcp))
    print('aperte uma tecla para continuar')
    pausa()
    plt.show()


if __name__ == "__main__":
    main()
