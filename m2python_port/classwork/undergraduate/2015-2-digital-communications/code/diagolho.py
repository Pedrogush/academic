"""Port of classwork/undergraduate/2015-2-digital-communications/code/diagolho.m

"Diagrama de olho" (na prática exibido com comm.ConstellationDiagram): 100000 bits
aleatórios são modulados em 2-PAM (comm.PAMModulator(2): 0 -> -1, 1 -> +1), formatados
com filtro cosseno levantado (rolloff 0.5, 64 amostras/símbolo, span 64 símbolos),
normalizados pelo pico do filtro e exibidos; em seguida, AWGN com SNR = 20 dB é
adicionado (o step do scope do sinal ruidoso está comentado no original).

Porting notes:
- Communications Toolbox System objects are re-implemented below with numpy/scipy:
  comm.RaisedCosineTransmitFilter (normal raised cosine from rcosdesign, unit energy,
  polyphase interpolation with upfirdn; the filter state carries over between step()
  calls, as in MATLAB), awgn(..., 'measured'), downsample and a matplotlib stand-in
  for comm.ConstellationDiagram (last 256 symbols, decimated by SamplesPerSymbol, with
  the default QPSK reference constellation).
- In the original, `Rup` is used in the filter constructor BEFORE `Rup = 64` is
  assigned, so the script only works if Rup already exists in the workspace; here Rup is
  defined first.
- rand/randi/awgn use np.random.default_rng(seed) (`--seed`); streams differ from MATLAB.
- The PAM signal is treated as real-valued (so awgn adds real noise).
"""
import argparse

import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import upfirdn


# ---------------------------------------------------------------------------
# Minimal replacements for the Communications Toolbox System objects used here.
# ---------------------------------------------------------------------------
def rcosdesign(beta, span, sps):
    """Normal (non-square-root) raised-cosine FIR, length span*sps+1, unit energy
    (MATLAB rcosdesign(beta, span, sps, 'normal'))."""
    t = np.arange(-span * sps / 2, span * sps / 2 + 1) / sps
    with np.errstate(divide='ignore', invalid='ignore'):
        h = np.sinc(t) * np.cos(np.pi * beta * t) / (1 - (2 * beta * t) ** 2)
    sing = np.isclose(np.abs(2 * beta * t), 1.0)
    h[sing] = (np.pi / 4) * np.sinc(1 / (2 * beta))
    return h / np.sqrt(np.sum(h ** 2))


class RaisedCosineTransmitFilter:
    """comm.RaisedCosineTransmitFilter('Shape','Normal', ...): stateful polyphase
    interpolator; each step() continues from the filter state of the previous call
    (as the MATLAB System object does), output length = len(x)*sps."""

    def __init__(self, RolloffFactor, FilterSpanInSymbols, OutputSamplesPerSymbol):
        self.sps = OutputSamplesPerSymbol
        self.span = FilterSpanInSymbols
        self.Numerator = rcosdesign(RolloffFactor, FilterSpanInSymbols,
                                    OutputSamplesPerSymbol)
        self._hist = None   # previous input symbols kept as filter state

    def step(self, x):
        x = np.asarray(x).ravel()
        nmem = int(np.ceil((len(self.Numerator) - 1) / self.sps))
        if self._hist is None:
            self._hist = np.zeros(nmem, dtype=x.dtype)
        xx = np.concatenate([self._hist, x])
        y = upfirdn(self.Numerator, xx, up=self.sps)
        y = y[nmem * self.sps: (nmem + len(x)) * self.sps]
        self._hist = xx[-nmem:]
        return y


def awgn(sig, snr_db, mode='measured', rng=None):
    """awgn(sig, snr, 'measured'): adds white Gaussian noise for the given SNR (dB)
    relative to the measured signal power (complex noise for complex signals)."""
    rng = np.random.default_rng() if rng is None else rng
    sig_power = np.sum(np.abs(sig) ** 2) / sig.size
    noise_power = sig_power / 10 ** (snr_db / 10)
    if np.iscomplexobj(sig):
        noise = np.sqrt(noise_power / 2) * (rng.standard_normal(sig.shape)
                                            + 1j * rng.standard_normal(sig.shape))
    else:
        noise = np.sqrt(noise_power) * rng.standard_normal(sig.shape)
    return sig + noise


def downsample(x, n):
    """MATLAB downsample(x, n): samples 1, 1+n, 1+2n, ... (1-based)."""
    return x[::n]


def constellation_diagram(sig, SamplesPerSymbol, symbols_to_display=256,
                          title='Constellation Diagram'):
    """comm.ConstellationDiagram step(): shows the last 256 symbols (decimated by
    SamplesPerSymbol, offset 0) plus the default QPSK reference constellation."""
    s = np.asarray(sig).ravel()[::SamplesPerSymbol][-symbols_to_display:]
    fig, ax = plt.subplots()
    ax.plot(np.real(s), np.imag(s) if np.iscomplexobj(s) else np.zeros_like(s),
            '.', color='y', markersize=6)
    ref = np.exp(1j * (np.pi / 4 + np.pi / 2 * np.arange(4)))
    ax.plot(ref.real, ref.imag, '+', color='r', markersize=10, mew=2)
    ax.set_xlabel('In-phase Amplitude')
    ax.set_ylabel('Quadrature Amplitude')
    ax.set_title(title)
    ax.set_facecolor('k')
    ax.grid(True, color='0.4')
    ax.set_aspect('equal', adjustable='datalim')
    return ax


def pam2_modulate(data):
    """comm.PAMModulator(2): symbol 0 -> -1, 1 -> +1."""
    return 2.0 * np.asarray(data, dtype=float).ravel() - 1.0


def main(seed=None):
    rng = np.random.default_rng(seed)
    Rup = 64  # upsampling rate (definido depois do uso no original)
    hRCTxFilter = RaisedCosineTransmitFilter(RolloffFactor=0.5, FilterSpanInSymbols=Rup,
                                             OutputSamplesPerSymbol=Rup)
    # número de bit = ndBit
    ndBit = 100000
    data = (np.ones(ndBit) + np.sign(rng.random(ndBit) - 0.5)) / 2
    modData = pam2_modulate(data)
    txSig = hRCTxFilter.step(modData)
    gain = 1 / np.max(hRCTxFilter.Numerator)
    txSig = gain * hRCTxFilter.step(modData)
    constellation_diagram(txSig, SamplesPerSymbol=Rup)
    rcv = awgn(txSig, 20, 'measured', rng)
    plt.show()
    return txSig, rcv


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument('--seed', type=int, default=None)
    main(ap.parse_args().seed)
