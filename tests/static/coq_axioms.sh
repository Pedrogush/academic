#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Turn `Print Assumptions` into a pass/fail test.
#
# Print Assumptions only PRINTS; a development can depend on a private axiom
# and still build.  This script prints the assumptions of every headline
# theorem -- of the library AND of the test files, including the trajectory
# witness of T03 -- and fails if anything appears that is not one of the four
# axioms Coq's own Reals library is built on.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COQC="${COQC:-/usr/bin/coqc}"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

ALLOWED='Classical_Prop.classic|FunctionalExtensionality.functional_extensionality_dep|ClassicalDedekindReals.sig_forall_dec|ClassicalDedekindReals.sig_not_dec|Closed under global context'

cat > "$TMP/audit.v" <<'V'
Require Import Reals.
Require Import SLA.SLA_Prelim. Require Import SLA.SLA_Chapter4.
Require Import SLA.SLA_AppendixA. Require Import SLA.SLA_Instance.
Require Import T01_defs_discriminate. Require Import T02_nonvacuity.
Require Import T03_witness_458. Require Import T04_statement_fidelity.
Require Import T06_witness_simplex.
(* library *)
Print Assumptions hull_invariance.       Print Assumptions theta_star_in_hull.
Print Assumptions ea_zero.               Print Assumptions E_alpha_star.
Print Assumptions V1_dyn.                Print Assumptions e_dyn.
Print Assumptions Vr_dyn.                Print Assumptions Vb_dyn.
Print Assumptions Vb_deriv_can_be_positive.
Print Assumptions Mf_psd.                Print Assumptions qres_zero.
Print Assumptions VrF_dyn.               Print Assumptions VrF_nonpos.
Print Assumptions theorem1_uniqueness.   Print Assumptions theorem2_uniqueness.
Print Assumptions design_rule_exact.     Print Assumptions more_vertices_not_unique.
Print Assumptions inst_astar_unique.     Print Assumptions inst_hull_invariance.
(* tests *)
Print Assumptions deriv_discriminates.
Print Assumptions inst_Vb_dyn.           Print Assumptions inst_qres_zero.
Print Assumptions W_Vb_strictly_increases.
Print Assumptions W_458_is_wrong_here.
Print Assumptions W_conditional_corollary_is_not_vacuous.
Print Assumptions Q_Vb_strictly_increases.
Print Assumptions Q_458_wrong_sign.
Print Assumptions Q_alp0_is_a_simplex_vertex.
V

( cd "$ROOT/tests/coq" && for f in T01_defs_discriminate.v T02_nonvacuity.v T03_witness_458.v T04_statement_fidelity.v T06_witness_simplex.v; do
    "$COQC" -Q "$ROOT/coq" SLA -Q . "" "$f" >/dev/null || exit 1
  done ) || { echo "FAIL: the test files do not compile"; exit 1; }

out=$("$COQC" -Q "$ROOT/coq" SLA -Q "$ROOT/tests/coq" "" "$TMP/audit.v" 2>&1)
audit_rc=$?
echo "$out"
if [ "$audit_rc" -ne 0 ]; then
  echo; echo "FAIL: the audit file did not compile (a Print Assumptions target is missing?)"
  exit 1
fi
bad=$(echo "$out" | grep -vE "$ALLOWED" | grep -E '^[A-Za-z_].*:' | grep -v '^Axioms:')
if [ -n "$bad" ]; then
  echo; echo "FAIL: unexpected assumptions:"; echo "$bad"; exit 1
fi
echo; echo "AXIOM AUDIT: only the four axioms of Coq's Reals are used"
