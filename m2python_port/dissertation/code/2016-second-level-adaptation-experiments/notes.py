"""Port of dissertation/code/2016-second-level-adaptation-experiments/notes.m

Comment-only MATLAB file (no executable code): notes on the real Schur form
(RSF, computed by successive QR decompositions), on eig returning normalized
eigenvectors (V'*V orthogonal when M = M'), and on bounding the Rayleigh-like
quotient x'Ax / x'A^2x < Ts*gamma by expanding x = V*K in the eigenvector basis:
sum(lambda_i*k_i^2) / sum(lambda_i^2*k_i^2), i.e. K'*L*K / K'*L^2*K, suggesting
max(polyeig(V*L*V', V*L^2*V'*Ts*gamma)); alternative approach: differentiate with
respect to x and set the gradient to zero.

Porting notes:
- Nothing to execute; ``main()`` just prints this note.
"""


def main():
    print(__doc__)


if __name__ == "__main__":
    main()
