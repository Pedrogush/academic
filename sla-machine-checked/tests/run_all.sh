#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Every soundness check in this directory, cheapest first.
#
#   ./run_all.sh            static scan, Coq tests, numerics, annotated-tree
#                           comparison, axiom audit                 (~3 min)
#   ./run_all.sh --dl       ... and the KeYmaera X entries          (+~8 min)
#   ./run_all.sh --mutants  ... and the full mutation run           (+~1 h)
#
# See README.md for what each stage is defending against.
# ---------------------------------------------------------------------------
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
COQC="${COQC:-/usr/bin/coqc}"
rc=0
step() { printf '\n=== %s ===\n' "$1"; }

step "static anti-cheat scan"
bash "$HERE/static/scan.sh" || rc=1

step "Coq semantic tests (T01-T04, T06)"
( cd "$HERE/coq" && for f in T01_defs_discriminate.v T02_nonvacuity.v \
                             T03_witness_458.v T04_statement_fidelity.v \
                             T06_witness_simplex.v; do
    printf '  %-28s' "$f"
    if "$COQC" -Q "$ROOT/coq" SLA -Q . "" "$f" >/dev/null 2>&1; then echo ok; else echo FAIL; exit 1; fi
  done ) || rc=1

step "numerical cross-check of the T03 / T06 trajectories"
python3 "$HERE/numeric/simulate.py" A | tail -2 || rc=1
python3 "$HERE/numeric/simulate.py" B | tail -2 || rc=1

step "annotated tree states the same theorems as the checked tree"
bash "$HERE/static/annotated_equiv.sh" | tail -2 || rc=1

step "Coq axiom audit (Print Assumptions, as a test)"
bash "$HERE/static/coq_axioms.sh" >/dev/null 2>&1 \
  && echo "  ok    only the four axioms of Coq's Reals" || { echo "  FAIL"; rc=1; }

step "Lean audit file (statement fidelity + inhabited bundles)"
if [ -x "$HOME/.elan/bin/lake" ] && [ -e "$ROOT/lean/.lake" ]; then
  ( cd "$ROOT/lean" && nice -n 15 env PATH="$HOME/.elan/bin:$PATH" \
      lake env lean ../tests/lean/Check.lean >/dev/null 2>&1 ) \
    && echo "  ok    tests/lean/Check.lean type-checks" \
    || { echo "  FAIL  tests/lean/Check.lean"; rc=1; }
else
  echo "  skip  (no Lean toolchain / no lean/.lake here)"
fi

if [ "${1:-}" = "--dl" ] || [ "${1:-}" = "--mutants" ]; then
  step "KeYmaera X non-vacuity entries"
  bash "$HERE/keymaerax/run.sh" | tail -3 || rc=1
fi

if [ "${1:-}" = "--mutants" ]; then
  step "mutation run (slow)"
  python3 "$HERE/mutants/run_mutants.py" || rc=1
fi

echo
[ "$rc" -eq 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit "$rc"
