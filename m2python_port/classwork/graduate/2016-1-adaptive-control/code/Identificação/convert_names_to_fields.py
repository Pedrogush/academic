"""Port of classwork/graduate/2016-1-adaptive-control/code/Identificação/convert_names_to_fields.m

Builds a struct whose field names are the caller's variable names of the
arguments (MATLAB ``inputname(i)``) and whose values are the arguments.

Porting notes:
- Python has no ``inputname``. The port accepts an explicit ``names=`` keyword
  (used by make_struct_Grad / make_struct_MQ / make_struct_out). Without it the
  names are looked up in the caller's local variables by object identity, which
  mimics inputname; if an argument is not a plain variable (an expression or a
  literal that no local refers to) a ValueError is raised, as MATLAB fails on
  ``estr.('')``.
- MATLAB's ``cell2mat(varargin(i))`` just returns the value; values are stored
  as given.
"""
import inspect


def _inputnames(values, frame):
    names = []
    for v in values:
        found = ""
        for k, val in frame.f_locals.items():
            if val is v:
                found = k
                break
        if not found:
            raise ValueError("convert_names_to_fields: argument is not a variable (inputname is empty)")
        names.append(found)
    return names


def convert_names_to_fields(*args, names=None):
    if names is None:
        frame = inspect.currentframe().f_back
        try:
            names = _inputnames(args, frame)
        finally:
            del frame
    estr = {}
    for nm, val in zip(names, args):
        estr[nm] = val
    return estr
