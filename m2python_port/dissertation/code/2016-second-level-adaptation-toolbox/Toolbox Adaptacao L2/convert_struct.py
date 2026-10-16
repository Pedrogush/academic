"""Port of dissertation/code/2016-second-level-adaptation-toolbox/Toolbox Adaptacao L2/convert_struct.m

``convert_struct(struct)`` returns the values of all fields of a MATLAB struct, in field
order, so that the toolbox functions can unpack the simulation-parameter struct
positionally (``[a, b, c, ...] = convert_struct(args)``).

Porting notes:
- In Python the "struct" may be a ``dict`` (insertion order = field order), a
  ``Struct`` (defined here, a dict with attribute access), a numpy structured scalar as
  returned by ``scipy.io.loadmat`` or any object with ``__dict__``.  The function returns a
  tuple with ALL the field values; callers slice it (``vals[:17]``) because MATLAB silently
  ignores surplus ``varargout`` entries when fewer outputs are requested.
- Helpers added for the Python port (no MATLAB counterpart): ``Struct`` (used for the
  output structs produced by ``make_struct``) and ``load_struct`` (loads a struct saved in a
  .mat file, e.g. the ``Parameters`` structs saved by tabbedGUI, as a ``Struct`` of float
  arrays; ``mat_dtype=True`` is used so integer-valued doubles come back as doubles).
"""
import numpy as np


class Struct(dict):
    """dict with attribute access, mimicking a MATLAB struct (field order preserved)."""

    def __getattr__(self, name):
        try:
            return self[name]
        except KeyError as exc:
            raise AttributeError(name) from exc

    def __setattr__(self, name, value):
        self[name] = value

    def __delattr__(self, name):
        del self[name]


def _fields(struct):
    if isinstance(struct, dict):
        return list(struct.keys()), list(struct.values())
    if isinstance(struct, np.ndarray) and struct.dtype.names is not None:
        s = struct.item() if struct.shape == () else struct
        names = struct.dtype.names
        if isinstance(s, tuple):
            return list(names), list(s)
        return list(names), [struct[n] for n in names]
    if hasattr(struct, "_fieldnames"):  # scipy mat_struct
        return list(struct._fieldnames), [getattr(struct, n) for n in struct._fieldnames]
    d = vars(struct)
    return list(d.keys()), list(d.values())


def convert_struct(struct):
    """Return all field values of ``struct`` in field order (MATLAB ``varargout``)."""
    _, values = _fields(struct)
    return tuple(values)


def to_struct(struct):
    """Convert any supported struct representation into a ``Struct`` (helper)."""
    names, values = _fields(struct)
    out = Struct()
    for n, v in zip(names, values):
        if isinstance(v, np.ndarray) and v.dtype.kind in "biuf":
            v = v.astype(float)
            if v.ndim == 0:
                v = float(v)
        elif isinstance(v, (np.integer, np.floating)):
            v = float(v)
        out[n] = v
    return out


def load_struct(path, varname):
    """Load struct ``varname`` from the .mat file ``path`` as a ``Struct`` (helper)."""
    from scipy.io import loadmat
    d = loadmat(path, squeeze_me=True, mat_dtype=True)
    return to_struct(d[varname])


def as_vector(x):
    """Helper: MATLAB vector (row/column/scalar) -> 1-D float array."""
    return np.ravel(np.asarray(x, dtype=float))


def as_matrix(x, n_rows=None):
    """Helper: MATLAB matrix -> 2-D float array (reshaped to ``n_rows`` rows if given,
    which undoes scipy's squeeze of 1 x m / n x 1 matrices)."""
    a = np.asarray(x, dtype=float)
    if n_rows is not None:
        return a.reshape(n_rows, -1)
    return np.atleast_2d(a)
