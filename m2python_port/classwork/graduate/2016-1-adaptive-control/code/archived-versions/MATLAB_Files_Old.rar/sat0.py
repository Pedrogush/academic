"""Port of classwork/graduate/2016-1-adaptive-control/code/archived-versions/MATLAB_Files_Old.rar/sat0.m

Returns 0 for arg <= 0 and arg otherwise (a "saturation at zero"). Used by
calc_gamma_0 to switch a term on only for the 4th parameter (sat0(i-3)).

Porting notes:
- The else branch lacks a semicolon in MATLAB, so it echoes ``num = ...``; the
  port prints it too.
"""


def sat0(arg):
    if arg <= 0:
        num = 0
    else:
        num = arg
        print("num =", num)
    return num
