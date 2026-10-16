"""Port of dissertation/code/2016-second-level-adaptation-experiments/testswitch.m

Test of a MATLAB ``switch`` on a concatenated char array: [a,b,c] = 'bmb' is
compared with 'bma', which does not match, so the ``otherwise`` branch displays
``b = 1``.

Porting notes:
- switch/case on strings -> if/else on str equality; display -> print.
"""


def main():
    a = "b"
    b = "m"
    c = "b"
    if a + b + c == "b" + "m" + "a":
        b = 2
    else:
        b = 1
    print("b =", b)
    return b


if __name__ == "__main__":
    main()
