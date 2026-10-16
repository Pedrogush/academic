"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/MATLAB_Files_Old.rar/test_mtruct.m

Prototype of the "name-to-field" trick: builds a struct whose field names are the
caller's variable names of the arguments (MATLAB inputname(i)), each field
holding the argument wrapped in a 1x1 cell (``varargin(i)``, not ``varargin{i}``).

Porting notes:
- Struct = dict; a 1x1 cell is represented by a one-element list.
- Python has no inputname: names are found by identity (``is``) among the
  caller's local variables; a ValueError is raised when an argument is not a
  variable (MATLAB fails on ``estr.('')``).
"""
import inspect


def test_mtruct(*varargin):
    frame = inspect.currentframe().f_back
    try:
        estr = {}
        for v in varargin:
            name = ""
            for k, val in frame.f_locals.items():
                if val is v:
                    name = k
                    break
            if not name:
                raise ValueError("test_mtruct: argument is not a variable (inputname is empty)")
            estr[name] = [v]
    finally:
        del frame
    return estr
