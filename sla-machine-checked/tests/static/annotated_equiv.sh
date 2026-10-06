#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# The annotated sources must prove the SAME statements as the checked ones.
#
# THREAT.  coq/annotated/ exists so a reader unfamiliar with Coq can follow the
# development.  If the two copies drifted, a reader would be reading one thing
# while the machine checks another -- the most comfortable way to be wrong.
# `Print Assumptions` and a green build cannot see this.
#
# METHOD.  Both trees declare the same module names (SLA.SLA_*), so each is
# compiled separately and the *type* of every declaration in coq/*.v is printed
# in both worlds with fully qualified names.  The two outputs must be
# identical.  Any change in a statement, in the order or number of section
# variables and hypotheses, or a missing declaration, shows up as a diff.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COQC="${COQC:-/usr/bin/coqc}"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# every declaration of the checked tree, in file order
gen_check_file() {
  python3 - "$ROOT" > "$TMP/check.v" <<'PY'
import re, sys, os
root = sys.argv[1]
mods = ["SLA_Prelim", "SLA_Chapter4", "SLA_AppendixA", "SLA_Instance"]
print("Require Import Reals.")
for m in mods:
    print("Require Import SLA.%s." % m)
print("Set Printing Width 200.")
pat = re.compile(r'^\s*(?:Theorem|Lemma|Corollary|Definition|Fixpoint)\s+([A-Za-z_][A-Za-z0-9_\']*)',
                 re.M)
for m in mods:
    src = open(os.path.join(root, "coq", m + ".v"), encoding="utf-8").read()
    src = re.sub(r'\(\*.*?\*\)', '', src, flags=re.S)
    for name in pat.findall(src):
        print("Check SLA.%s.%s." % (m, name))
PY
}

run_tree() {                       # $1 = source dir, $2 = output file
  cp "$1"/*.v "$TMP/tree/" 2>/dev/null
  ( cd "$TMP/tree" && for f in SLA_Prelim.v SLA_Chapter4.v SLA_AppendixA.v SLA_Instance.v; do
      "$COQC" -Q . SLA "$f" >/dev/null 2>&1 || { echo "BUILD FAILED: $1/$f"; exit 1; }
    done ) || return 1
  "$COQC" -Q "$TMP/tree" SLA "$TMP/check.v" > "$2" 2>&1
  rm -rf "$TMP/tree"; mkdir -p "$TMP/tree"
}

mkdir -p "$TMP/tree"
gen_check_file
n=$(grep -c '^Check' "$TMP/check.v")
echo "comparing $n declarations between coq/ and coq/annotated/"

run_tree "$ROOT/coq" "$TMP/plain.txt"           || { echo "FAIL: coq/ does not build"; exit 1; }
run_tree "$ROOT/coq/annotated" "$TMP/annot.txt" || { echo "FAIL: coq/annotated/ does not build"; exit 1; }

if diff -q "$TMP/plain.txt" "$TMP/annot.txt" >/dev/null; then
  echo "ok    all $n declarations have identical statements in both trees"
  exit 0
else
  echo "FAIL  the annotated tree states something different:"
  diff "$TMP/plain.txt" "$TMP/annot.txt" | head -40
  exit 1
fi
