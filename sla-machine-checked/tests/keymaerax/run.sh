#!/usr/bin/env bash
# Run the dL non-vacuity checks (T05_dl_vacuity.kyx) with the same toolchain
# as ../../keymaerax/build.sh.  All entries must PROVE.
set -uo pipefail
KYX_TOOLS="${KYX_TOOLS:-$HOME/kyx-tools}"
JAVA_HOME="${JAVA_HOME:-$KYX_TOOLS/jdk-21.0.12+8}"
KYX_JAR="${KYX_JAR:-$KYX_TOOLS/keymaerax.jar}"
Z3_PATH="${Z3_PATH:-$KYX_TOOLS/z3wrap/z3}"
export JAVA_HOME PATH="$JAVA_HOME/bin:$PATH"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOISE='^\s+at |^WARNING: Encountered|^timesDiv|^powNeg|^powerLemma|^timesPowers|^powerEven|^powerOdd|^divide|^normalizeCoeff|^powerDivide|^ratForm|^taylorModel'

timeout 900 nice -n 15 "$JAVA_HOME/bin/java" -Xmx2g -Xss20M -jar "$KYX_JAR" \
    -launch -prove "$HERE/T05_dl_vacuity.kyx" -tool z3 -z3path "$Z3_PATH" -timeout 200 2>&1 \
  | grep -vE "$NOISE" | sed "s#$HERE/##"
rc="${PIPESTATUS[0]}"
if [ "$rc" -eq 0 ]; then echo ">>> T05: all non-vacuity entries PROVED"; else echo ">>> T05: FAILED (exit $rc)"; fi

# ---------------------------------------------------------------------------
# The expected-to-fail entry, checked for the RIGHT KIND of failure.
#
# ../../keymaerax/build.sh treats a nonzero exit from 05_eq458_dI_fails.kyx as
# success.  That is correct -- the file records that dI does not close on the
# dissertation's candidate -- but it also means a typo, a parse error or a
# missing file would be counted as the expected outcome.  Here the output is
# required to contain UNFINISHED, i.e. a proof that ran and did not close.
# ---------------------------------------------------------------------------
echo
echo "== 05_eq458_dI_fails.kyx must fail as an UNFINISHED proof, not as an error =="
out=$(timeout 900 nice -n 15 "$JAVA_HOME/bin/java" -Xmx2g -Xss20M -jar "$KYX_JAR" \
        -launch -prove "$HERE/../../keymaerax/05_eq458_dI_fails.kyx" \
        -tool z3 -z3path "$Z3_PATH" -timeout 200 2>&1 | grep -vE "$NOISE")
if echo "$out" | grep -q 'UNFINISHED'; then
  echo ">>> ok: the entry is UNFINISHED (a proof attempt that did not close)"
  echo "$out" | grep -E 'UNFINISHED|PROVED' | sed 's/^/    /'
else
  echo ">>> FAIL: 05 did not report UNFINISHED -- it failed for some other reason:"
  echo "$out" | tail -5 | sed 's/^/    /'
  rc=1
fi
exit "$rc"
