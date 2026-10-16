"""Port of dissertation/code/2016-second-level-adaptation-experiments/blub.m

Minimal MATLAB classdef experiment: class ``blub`` with a single property
``debugOn`` (default 0) set by the constructor ``blub(debugself_var)``.

Porting notes:
- classdef -> Python class; like MATLAB, calling the constructor without the
  argument is an error (TypeError here, "Not enough input arguments" in MATLAB).
"""


class blub:
    def __init__(self, debugself_var):
        self.debugOn = 0
        self.debugOn = debugself_var

    def __repr__(self):
        return f"blub(debugOn={self.debugOn!r})"
