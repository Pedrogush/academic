#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Static anti-cheat scan over the four formalisations.
#
# Everything here is a *syntactic* check: it needs no prover and runs in a
# second.  It catches the cheap ways of making a development exit 0 without
# proving anything, and it catches configuration that would make the provers
# lenient (Isabelle's quick_and_dirty, Lean's native_decide, ...).
#
# It deliberately does NOT try to establish soundness: for that see
# ../coq/T0*.v (semantic pinning, non-vacuity, statement fidelity) and
# ../mutants/ (does the build notice when the text changes?).
#
# Exit status: 0 if every check passed, 1 otherwise.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
rc=0

pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; rc=1; }

# $1 description, $2 egrep pattern, rest: files
forbid() {
  local desc="$1" pat="$2"; shift 2
  local hits
  hits=$(grep -nE "$pat" "$@" 2>/dev/null | grep -v '^\s*$')
  if [ -z "$hits" ]; then pass "$desc"; else fail "$desc"; echo "$hits" | sed 's/^/          /'; fi
}

# $1 description, $2 egrep pattern, rest: files -- must be PRESENT
require() {
  local desc="$1" pat="$2"; shift 2
  if grep -qE "$pat" "$@" 2>/dev/null; then pass "$desc"; else fail "$desc"; fi
}

echo "== Coq =="
# Comments are stripped first: the sources discuss "Admitted" in prose.
COQ_TMP=$(mktemp -d); trap 'rm -rf "$COQ_TMP"' EXIT
for f in "$ROOT"/coq/*.v "$ROOT"/coq/annotated/*.v; do
  [ -e "$f" ] || continue
  # crude comment stripper: drop (* ... *) spanning lines
  perl -0pe 's/\(\*.*?\*\)//gs' "$f" > "$COQ_TMP/$(basename "$(dirname "$f")")_$(basename "$f")"
done
forbid "no Axiom/Parameter/Conjecture/Admitted/admit" \
       '(^|[^A-Za-z_])(Axiom|Axioms|Parameter|Parameters|Conjecture|Admitted|admit|Abort)([^A-Za-z_]|$)' \
       "$COQ_TMP"/*.v
forbid "no kernel-weakening flags" \
       '(type-in-type|Unset Guard Checking|Unset Positivity Checking|Unset Universe Checking)' \
       "$COQ_TMP"/*.v
require "Instance file exists (a model of the hypotheses)" 'Definition' "$ROOT/coq/SLA_Instance.v"

echo "== Lean =="
# strip /- ... -/ and -- ... comments first (the sources discuss axioms in prose)
LEAN_TMP="$COQ_TMP/lean"; mkdir -p "$LEAN_TMP"
for f in "$ROOT"/lean/SLA/*.lean "$ROOT"/lean/SLA.lean; do
  perl -0pe 's{/-.*?-/}{}gs; s{--[^\n]*}{}g' "$f" > "$LEAN_TMP/$(basename "$f")"
done
forbid "no sorry / native_decide / axiom / unsafe" \
       '(^|[^A-Za-z_])(sorry|native_decide|axiom|unsafe|implemented_by|extern)([^A-Za-z_]|$)' \
       "$LEAN_TMP"/*.lean
forbid "no @[simp] on a false-looking local axiom, no macro_rules override" \
       'macro_rules|elab_rules|attribute \[instance\] sorryAx' \
       "$ROOT"/lean/SLA/*.lean
require "toolchain is pinned" 'leanprover/lean4:v' "$ROOT/lean/lean-toolchain"
require "Mathlib revision is pinned" '"rev":' "$ROOT/lean/lake-manifest.json"

echo "== Isabelle =="
# strip (* ... *) comments and text \<open> ... \<close> prose blocks
ISA_TMP="$COQ_TMP/isa"; mkdir -p "$ISA_TMP"
for f in "$ROOT"/isabelle/*.thy; do
  perl -0pe 's{\(\*.*?\*\)}{}gs; s{(text|section|subsection|txt|chapter)\s*\\<open>.*?\\<close>}{}gs' \
    "$f" > "$ISA_TMP/$(basename "$f")"
done
forbid "no sorry / oops / axiomatization / nitpick-as-proof" \
       '(^|[^A-Za-z_])(sorry|oops|axiomatization|ax_specification)([^A-Za-z_]|$)' \
       "$ISA_TMP"/*.thy
# The single most important Isabelle configuration check: with
# quick_and_dirty = true, `sorry` is accepted silently and the session still
# builds.  The ROOT file must switch it off.
if grep -qE 'quick_and_dirty *= *false' "$ROOT/isabelle/ROOT"; then
  pass "ROOT sets quick_and_dirty = false"
else
  fail "ROOT does not set quick_and_dirty = false (sorry would be accepted)"
fi
require "session builds the audit theory SLA_Check" 'SLA_Check' "$ROOT/isabelle/ROOT"
require "session builds the model theory SLA_Instance" 'SLA_Instance' "$ROOT/isabelle/ROOT"

echo "== KeYmaera X =="
# Every entry must carry a Tactic; an entry without one is not proved by the
# batch prover, and an archive of such entries would still "run".
for f in "$ROOT"/keymaerax/*.kyx; do
  n_entry=$(grep -c '^ArchiveEntry' "$f")
  n_tac=$(grep -c '^Tactic' "$f")
  if [ "$n_entry" -eq "$n_tac" ]; then
    pass "$(basename "$f"): $n_entry entries, $n_tac tactics"
  else
    fail "$(basename "$f"): $n_entry entries but $n_tac tactics"
  fi
done
forbid "no 'Lemma' blocks assumed without proof" '^Lemma ' "$ROOT"/keymaerax/*.kyx
require "the expected-to-fail entry is declared as such in build.sh" \
        'EXPECT_FAIL' "$ROOT/keymaerax/build.sh"

echo "== cross-cutting =="
# The four ports must agree on the two findings; if one of them silently
# dropped a finding, the equation map would still look fine.
for pat in "4.58" "4.69"; do
  miss=""
  for d in coq lean isabelle keymaerax; do
    grep -rqF "$pat" "$ROOT/$d" || miss="$miss $d"
  done
  if [ -z "$miss" ]; then pass "finding ($pat) is discussed in all four ports";
  else fail "finding ($pat) missing from:$miss"; fi
done

# Each headline result must exist in all three general-purpose provers.  A port
# that silently dropped one would still build, and the equation map in its
# README would still look complete.
echo "== result inventory (coq / lean / isabelle) =="
check_triple() {
  local label="$1" cpat="$2" lpat="$3" ipat="$4" miss=""
  grep -qE "$cpat" "$ROOT"/coq/*.v            || miss="$miss coq"
  grep -qE "$lpat" "$ROOT"/lean/SLA/*.lean    || miss="$miss lean"
  grep -qE "$ipat" "$ROOT"/isabelle/*.thy     || miss="$miss isabelle"
  if [ -z "$miss" ]; then pass "$label"; else fail "$label -- missing in:$miss"; fi
}
check_triple "(4.23) first-level Lyapunov derivative" 'V1_dyn' 'V1_deriv' 'V1_dyn'
check_triple "(4.30) error dynamics"                  'e_dyn'  'e_deriv'  'e_dyn'
check_triple "(4.41) hull invariance"                 'hull_invariance' 'hull_invariance' 'hull_invariance'
check_triple "(4.45) e_alpha = 0"                     'ea_zero' 'ea_zero' 'ea_zero'
check_triple "(4.51) E_f alpha* = -eps_N"             'E_alpha_star' 'E_alpha_star' 'E_alpha_star'
check_triple "(4.57) exact derivative"                'Vb_dyn' 'Vb_deriv' 'Vb_dyn'
check_triple "(4.58) finding: can be positive"        'Vb_deriv_can_be_positive' 'Vb_deriv_can_be_positive' 'Vb_deriv_can_be_positive'
check_triple "(4.65) M_f positive semi-definite"      'Mf_psd' 'Mf_psd' 'Mf_psd'
check_triple "(4.69) residual vanishes"               'qres_zero' 'qres_zero' 'qres_zero'
check_triple "(4.68) SLAFF Lyapunov derivative"       'VrF_dyn' 'VrF_deriv' 'VrF_dyn'
check_triple "Appendix A uniqueness"                  'theorem2_uniqueness' 'theorem2_uniqueness' 'theorem2_uniqueness'
check_triple "amended design rule N = d+1"            'design_rule_exact' 'design_rule_exact' 'design_rule_exact'
check_triple "N > d+1 breaks uniqueness"              'more_vertices_not_unique' 'more_vertices_not_unique' 'more_vertices_not_unique'

echo
if [ "$rc" -eq 0 ]; then echo "STATIC SCAN: all checks passed"; else echo "STATIC SCAN: FAILURES ABOVE"; fi
exit "$rc"
