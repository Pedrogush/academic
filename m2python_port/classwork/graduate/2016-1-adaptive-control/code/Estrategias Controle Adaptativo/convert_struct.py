"""Port of classwork/graduate/2016-1-adaptive-control/code/Estrategias Controle Adaptativo/convert_struct.m

Converts a "struct" into a list of outputs, in field order (MATLAB:
``varargout = struct2cell(struct)``). It is the unpacking helper used by every
simulation function of this course (identification and adaptive control), which
receive their parameters as a struct and unpack them positionally.

Porting notes:
- MATLAB structs are represented by Python dicts (insertion-ordered), so the
  field order is the order in which keys were inserted.
- MATLAB lets the caller request fewer outputs than there are fields (the rest
  are dropped). Python tuple unpacking needs the exact count, so an optional
  ``nargout`` argument is provided: ``convert_struct(s, 15)`` returns the first
  15 values and raises ValueError (MATLAB: "Too many output arguments") if the
  struct has fewer fields.
"""


def convert_struct(struct, nargout=None):
    l = list(struct.values())
    if nargout is None:
        return tuple(l)
    if nargout > len(l):
        raise ValueError(
            "convert_struct: too many output arguments (%d requested, struct has %d fields)"
            % (nargout, len(l)))
    return tuple(l[:nargout])
