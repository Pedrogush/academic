#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Run the KeYmaera X command-line prover over every .kyx file in this folder.
#
# Toolchain (installed rootlessly under $HOME, see README.md):
#   KeYmaera X 5.1.2          $KYX_JAR
#   Temurin JDK 21.0.12+8     $JAVA_HOME
#   Z3 5.0.0                  $Z3_REAL, invoked through the wrapper $Z3_PATH
#
# The Z3 WRAPPER is not optional.  KeYmaera X asks Z3 to prove real-exponent
# power laws (x^i*x^j = x^(i+j) with i,j real) that Z3 cannot decide, and
# without a hard limit it blocks forever.  The wrapper adds `-T:25`.
#
# Override KYX_TOOLS / JAVA_HOME / KYX_JAR / Z3_REAL / TIMEOUT in the
# environment if your layout differs.
# ---------------------------------------------------------------------------
set -uo pipefail

KYX_TOOLS="${KYX_TOOLS:-$HOME/kyx-tools}"
JAVA_HOME="${JAVA_HOME:-$KYX_TOOLS/jdk-21.0.12+8}"
KYX_JAR="${KYX_JAR:-$KYX_TOOLS/keymaerax.jar}"
Z3_REAL="${Z3_REAL:-$KYX_TOOLS/z3-5.0.0-x64-glibc-2.39/bin/z3}"
Z3_PATH="${Z3_PATH:-$KYX_TOOLS/z3wrap/z3}"
TIMEOUT="${TIMEOUT:-560}"       # wall-clock cap per file (seconds)
PROOF_BUDGET="${PROOF_BUDGET:-200}"  # KeYmaera X -timeout, per entry

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$PATH"

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for tool in "$JAVA_HOME/bin/java" "$KYX_JAR" "$Z3_REAL"; do
  if [ ! -e "$tool" ]; then
    echo "missing: $tool" >&2
    echo "see README.md for the rootless install instructions" >&2
    exit 2
  fi
done

# Create the Z3 wrapper if it is not there yet.
if [ ! -x "$Z3_PATH" ]; then
  mkdir -p "$(dirname "$Z3_PATH")"
  printf '#!/bin/sh\nexec %s -T:25 "$@"\n' "$Z3_REAL" > "$Z3_PATH"
  chmod +x "$Z3_PATH"
  echo "created Z3 wrapper at $Z3_PATH"
fi

# Files that are EXPECTED to return non-zero.  05 records that dI/ODE do not
# close on the dissertation's Lyapunov candidate (4.57).  NOTE: that is a
# failed proof attempt, NOT a refutation -- the machine-checked refutation of
# (4.58) is in 04_eq458_discrepancy.kyx.  See README.md section 5.
EXPECT_FAIL="05_eq458_dI_fails.kyx"

# KeYmaera X prints a ~20-line warning about 19 lemmas it cannot derive with
# Z3 on every run (see README.md section 1); fold it away for readability.
NOISE='^\s+at |^WARNING: Encountered|^timesDiv|^powNeg|^powerLemma|^timesPowers|^powerEven|^powerOdd|^divide|^normalizeCoeff|^powerDivide|^ratForm|^taylorModel'

run_one() {
  local f="$1"
  timeout "$TIMEOUT" nice -n 15 "$JAVA_HOME/bin/java" -Xmx2g -Xss20M \
      -jar "$KYX_JAR" -launch -prove "$HERE/$f" \
      -tool z3 -z3path "$Z3_PATH" -timeout "$PROOF_BUDGET" 2>&1 \
    | grep -vE "$NOISE" | sed "s#$HERE/##"
  return "${PIPESTATUS[0]}"
}

rc_all=0
for f in $(cd "$HERE" && ls *.kyx | sort); do
  echo "=============================================================="
  echo "== $f"
  echo "=============================================================="
  run_one "$f"
  rc=$?
  case " $EXPECT_FAIL " in
    *" $f "*)
      if [ "$rc" -eq 0 ]; then
        echo ">>> $f: UNEXPECTEDLY PROVED (exit 0) -- investigate"
        rc_all=1
      else
        echo ">>> $f: did not close, as expected (exit $rc)"
      fi ;;
    *)
      if [ "$rc" -eq 0 ]; then
        echo ">>> $f: PROVED"
      elif [ "$rc" -eq 124 ]; then
        echo ">>> $f: TIMED OUT after ${TIMEOUT}s"
        rc_all=1
      else
        echo ">>> $f: FAILED (exit $rc)"
        rc_all=1
      fi ;;
  esac
  echo
done

if [ "$rc_all" -eq 0 ]; then
  echo "ALL FILES BEHAVED AS EXPECTED"
else
  echo "SOME FILES DID NOT BEHAVE AS EXPECTED"
fi
exit "$rc_all"
