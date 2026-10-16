"""Shared helpers for the ports of dissertation/code/2016-second-level-adaptation-toolbox/*.m

This module has no MATLAB counterpart. It gathers the small pieces that the
top-level toolbox functions (L2AA_Ident, L2A_IO_*, ...) take from the sibling
folder "Toolbox Adaptacao L2" (can, convert_struct, make_struct), plus a few
MATLAB-semantics helpers (inverse of a singular matrix, min of a complex
vector, tic/toc).

The functions from "Toolbox Adaptacao L2" are imported via importlib from the
sibling port path
    m2python_port/dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/<module>.py
When a module is not available (or fails), a minimal inline copy is used.

Porting notes:
- make_struct.m calls convert_names_to_fields, which is not in the toolbox
  folder (it lives in classwork/.../Identificação/ and uses inputname). The
  intended behaviour (see tabbedGUI.m,
  Current_Simulation_Output) is a struct whose field names are the names of the
  input variables; the inline fallback returns such a dict.
"""
import importlib.util
import os
import sys
import time

import numpy as np
import scipy.linalg

_HERE = os.path.dirname(os.path.abspath(__file__))
TOOLBOX_DIR = os.path.join(_HERE, "Toolbox Adaptacao L2")

_cache = {}


def load_toolbox(modname):
    """Load <modname>.py from the 'Toolbox Adaptacao L2' port folder (or None)."""
    if modname in _cache:
        return _cache[modname]
    path = os.path.join(TOOLBOX_DIR, modname + ".py")
    mod = None
    if TOOLBOX_DIR not in sys.path:
        # the toolbox modules import each other by plain name (e.g. make_struct
        # imports convert_struct); appended so it never shadows this folder
        sys.path.append(TOOLBOX_DIR)
    if os.path.isfile(path):
        try:
            spec = importlib.util.spec_from_file_location("toolbox_l2_" + modname, path)
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
        except Exception:  # pragma: no cover - concurrent/unfinished port
            mod = None
    _cache[modname] = mod
    return mod


# ---------------------------------------------------------------- can.m
def _can_inline(vect):
    vect = np.asarray(vect, dtype=float).ravel()
    n = len(vect)
    A = np.zeros((n, n))
    for linha in range(n - 1):
        A[linha, linha + 1] = 1.0
    A[n - 1, :] = vect
    return A


def can(vect):
    """Companion (canonical) matrix of vect (can.m)."""
    mod = load_toolbox("can")
    if mod is not None and hasattr(mod, "can"):
        try:
            return np.asarray(mod.can(np.asarray(vect, dtype=float).ravel()), dtype=float).reshape(
                len(np.ravel(vect)), len(np.ravel(vect)))
        except Exception:
            pass
    return _can_inline(vect)


# ------------------------------------------------------- convert_struct.m
def convert_struct(args):
    """Return the field values of a struct (dict / object / loadmat struct) in order."""
    if isinstance(args, dict):
        return list(args.values())
    if hasattr(args, "_fieldnames"):  # scipy.io.matlab mat_struct
        return [getattr(args, f) for f in args._fieldnames]
    if hasattr(args, "dtype") and getattr(args.dtype, "names", None):
        return [args[f] for f in args.dtype.names]
    return list(vars(args).values())


# ---------------------------------------------------------- make_struct.m
MAKE_STRUCT_FIELDS = ("x_p", "x_m", "eta", "theta_p_estimativa", "norm_2_e_o", "e_o", "u",
                      "alfa_barra", "r", "modelo_de_referencia", "planta", "theta_BARRA",
                      "modelos", "tempo", "endk")


def make_struct(*values):
    """Output structure of the simulations (make_struct.m)."""
    mod = load_toolbox("make_struct")
    if mod is not None and hasattr(mod, "make_struct"):
        try:
            return mod.make_struct(*values)
        except Exception:
            pass
    return dict(zip(MAKE_STRUCT_FIELDS, values))


# ------------------------------------------------------ input conversion
def parse_args(args):
    """convert_struct + numpy conversion of the 18 simulation parameters.

    Field order (as in tabbedGUI.m, Sim_Par):
    t_0, t_final, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
    cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, (unused), ref_amp,
    ref_freq, tol_eta, tau_ref
    """
    (t_0, t_final, h, modelos, planta, modelo_de_referencia, cond_iniciais_p,
     cond_iniciais_m, cond_iniciais_i, alfa0, Q, gamma, P, _unused, ref_amp,
     ref_freq, tol_eta, tau_ref) = convert_struct(args)[:18]
    f = lambda v: float(np.asarray(v, dtype=float).ravel()[0])
    vec = lambda v: np.asarray(v, dtype=float).ravel()
    mat = lambda v: np.atleast_2d(np.asarray(v, dtype=float))
    gamma = np.asarray(gamma, dtype=float)
    gamma = float(gamma.ravel()[0]) if gamma.size == 1 else np.atleast_2d(gamma)
    return dict(t_0=f(t_0), t_final=f(t_final), h=f(h), modelos=mat(modelos),
                planta=vec(planta), modelo_de_referencia=vec(modelo_de_referencia),
                cond_iniciais_p=vec(cond_iniciais_p), cond_iniciais_m=vec(cond_iniciais_m),
                cond_iniciais_i=np.asarray(cond_iniciais_i, dtype=float),
                alfa0=vec(alfa0), Q=mat(Q), gamma=gamma, P=mat(P), ref_amp=vec(ref_amp),
                ref_freq=vec(ref_freq), tol_eta=f(tol_eta), tau_ref=f(tau_ref))


def mlength(A):
    """MATLAB length(): largest dimension."""
    A = np.asarray(A)
    return max(A.shape) if A.ndim else 1


# ------------------------------------------------- MATLAB-like numerics
def minv(A):
    """MATLAB inv()/A^-1: an exactly singular matrix gives Inf (with a warning)."""
    A = np.atleast_2d(np.asarray(A, dtype=float))
    try:
        return np.linalg.inv(A)
    except np.linalg.LinAlgError:
        return np.full(A.shape, np.inf)


def svdvals(A):
    """Singular values (LAPACK gesvd, as MATLAB/Octave svd)."""
    A = np.atleast_2d(np.asarray(A, dtype=float))
    if not np.all(np.isfinite(A)):
        return np.full(min(A.shape), np.nan)
    return scipy.linalg.svd(A, compute_uv=False, lapack_driver="gesvd")


def norm2(A):
    """MATLAB norm(A) (2-norm: vector norm or largest singular value)."""
    A = np.asarray(A, dtype=float)
    if A.ndim <= 1 or min(A.shape) == 1:
        return float(np.sqrt(np.sum(A.ravel() ** 2)))
    s = svdvals(A)
    return float(np.max(s))


def mmin(v):
    """MATLAB min() of a vector: for complex data the element of smallest abs."""
    v = np.asarray(v).ravel()
    if np.iscomplexobj(v) and np.any(v.imag != 0):
        return v[np.argmin(np.abs(v))]
    return np.min(v.real)


class TicToc:
    """tic/toc"""

    def __init__(self):
        self.t0 = time.perf_counter()

    def toc(self):
        print("Elapsed time is %.6f seconds." % (time.perf_counter() - self.t0))


def example_args(kind="IO", t_final=10.0, h=1e-3):
    """Example parameter struct (values from 'Toolbox Adaptacao L2/exemplos.m', SIM1).

    kind="IO": state dimension n = 2, modelos 2 x 3 (L2AA_Ident, L2A_IO_*); the plant
               is replaced by a stable one inside the hull, [-2.4, -3.7].
    kind="CL": npar = 2 parameters (n = 1, plant b0/(s - a)), modelos 2 x 3
               (L2AA_CL_Ident, L2A_IO_CL_Ident_Esc/_Otimo/_V0_Completo).
    """
    modelos = np.array([[-4.0, -3.0, 8.0], [-5.0, -2.0, -4.0]])
    if kind == "IO":
        # stable plant inside the hull: 0.5*m1 + 0.4*m2 + 0.1*m3
        planta = np.array([-2.4, -3.7])
        cp, cm, ci = [0.0, 0.0], [0.2, 0.3], np.zeros((2, 3))
    else:
        planta = np.array([2.3, -3.6])
        cp, cm, ci = [0.0], [0.2], np.zeros((1, 3))
    return dict(t_0=0.0, t_final=t_final, h=h, modelos=modelos,
                planta=planta, modelo_ref=np.array([-4.0, -4.0]),
                cond_iniciais_p=np.array(cp), cond_iniciais_m=np.array(cm),
                cond_iniciais_i=ci, alfa_0=np.array([0.0, 1.0]),
                Q=1e4 * np.eye(2), gamma=10.0, P=100 * np.eye(2), not_used=5.0,
                ref_amp=np.array([5.0, 1.0, 1.0]), ref_freq=np.array([0.0, 1.0, 3.0]),
                tol_eta=1e-4, tau_ref=1.0)


def meig(A):
    """MATLAB eig(A) (eigenvalues only): symmetric solver (syev, ascending) when A
    is exactly symmetric, general solver (geev) otherwise."""
    A = np.atleast_2d(np.asarray(A, dtype=float))
    if not np.all(np.isfinite(A)):
        return np.full(A.shape[0], np.nan)
    if np.array_equal(A, A.T):
        return scipy.linalg.eigh(A, eigvals_only=True, driver="ev")
    w = scipy.linalg.eigvals(A)
    return w.real if np.all(w.imag == 0) else w


def meig_vec(A):
    """MATLAB [V, D] = eig(A) for a symmetric A (syev)."""
    A = np.atleast_2d(np.asarray(A, dtype=float))
    return scipy.linalg.eigh(A, driver="ev")


def gmul(gamma, v):
    """MATLAB gamma*v for a scalar or matrix gain gamma."""
    return gamma @ v if np.ndim(gamma) == 2 else gamma * v


def mdiv(a, b):
    """Floating division with IEEE semantics (x/0 = Inf, 0/0 = NaN) as in MATLAB."""
    with np.errstate(divide="ignore", invalid="ignore"):
        return np.float64(a) / np.float64(b)
