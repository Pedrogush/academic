"""Port of classwork/undergraduate/2015-1-electrical-installations/code/dimensionamento_cond.m

Stub of a conductor-sizing function (dimensionamento de condutores) that was never
implemented: it only sets and displays `output = 0`.

Porting notes:
- The MATLAB stub never assigns its declared output `output_args` (it assigns
  `output`), so calling it with an output in MATLAB raises "Output argument
  output_args not assigned". The port prints `output = 0` (the MATLAB echo) and
  returns None.
"""


def dimensionamento_cond(corrente_args):
    output = 0
    print('output =', output)
    output_args = None
    return output_args


if __name__ == "__main__":
    dimensionamento_cond(0)
