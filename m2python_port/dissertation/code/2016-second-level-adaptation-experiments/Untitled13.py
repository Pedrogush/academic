"""Port of dissertation/code/2016-second-level-adaptation-experiments/Untitled13.m

Scratch test of try/catch: ``a = 8`` is displayed, then ``a = blub()`` fails
(the blub constructor needs one argument), so the catch branch displays
``a = 7``, sets ``exit = 1`` and returns (``a = 9`` is never reached).

Porting notes:
- MATLAB displays assignments without ';' -> print.  ``return`` in a script ->
  return from main().  The variable named ``exit`` (shadows the MATLAB builtin)
  is kept as a local.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from blub import blub  # noqa: E402


def main():
    try:
        a = 8
        print("a =", a)
        a = blub()
        print("a =", a)
    except TypeError:
        a = 7
        print("a =", a)
        exit = 1  # noqa: F841  (as in MATLAB)
        return a
        a = 9  # noqa: F841  (unreachable, as in MATLAB)
    return a


if __name__ == "__main__":
    main()
