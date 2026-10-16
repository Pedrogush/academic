"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/varname.m

Returns the name of the variable passed as argument (MATLAB ``inputname(1)``),
the small experiment that led to convert_names_to_fields.

Porting notes:
- Python has no ``inputname``: the caller's local (then global) variables are
  searched for an object identical (``is``) to ``var``; the first match is
  returned, '' if none (MATLAB also returns '' for non-variable arguments).
  Small ints/strings are interned in Python, so two variables holding the same
  small int may be confused.
"""
import inspect


def varname(var):
    frame = inspect.currentframe().f_back
    try:
        for scope in (frame.f_locals, frame.f_globals):
            for k, val in scope.items():
                if val is var:
                    return k
    finally:
        del frame
    return ""
