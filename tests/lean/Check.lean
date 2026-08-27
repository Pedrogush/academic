/-
  tests/lean/Check.lean — statement fidelity and non-vacuity for the Lean port.

  THREAT (G6, G3 of ../README.md).  A green `lake build` says the proofs
  type-check against the statements as written; it does not say the statements
  are the intended ones, nor that anything satisfies their hypotheses.

  Isabelle has `SLA_Check.thy` for the first half and interpretations for the
  second; Coq now has `tests/coq/T02` and `T04`.  This file is the Lean
  counterpart:

  * PART 1 restates each headline result in the form the dissertation writes it
    and closes it with the library theorem, so statement drift breaks the file;
  * PART 2 shows the hypothesis bundles are inhabited and applies the
    second-level and forgetting-factor theorems to the concrete instance —
    the check that Coq's `SLA_Instance.v` was missing (mutant C24).

  It is NOT part of the SLA library: run it with

      cd lean && lake env lean ../tests/lean/Check.lean

  which type-checks it against the built package without adding a module.
-/
import SLA

namespace SLACheck

open SLA

/-! ## Part 1 — the statements say what the equations say -/

section Statements

variable {d M : ℕ} (S : Model d M) (H : Hull S) (L : SecondLevel H) (F : Forgetting H)

/-- (4.15)/(4.28): `e_{i,f} = θ̃ᵀφ` -/
theorem chk_4_15 (i : Fin (M + 1)) (t : ℝ) : S.e i t = S.tht i t ⬝ᵥ S.φ t :=
  S.e_eq_dot_tht i t

/-- (4.13)/(4.27): `ε = e/m²` -/
theorem chk_4_13 (i : Fin (M + 1)) (t : ℝ) : S.e i t = S.eps i t * S.msq t :=
  S.e_eq_eps_mul_msq i t

/-- (4.23): `V̇ = −ε² m²` -/
theorem chk_4_23 (i : Fin (M + 1)) :
    Deriv (S.V1 i) (fun t => -(S.eps i t * S.eps i t * S.msq t)) :=
  S.V1_deriv i

/-- (4.41): `θ*ᵖ` stays in the hull, with the same coefficients -/
theorem chk_4_41 (t : ℝ) (ht : 0 ≤ t) (j : Fin d) :
    ∑ i, S.θ i t j * H.α i = S.θstar j :=
  H.theta_star_in_hull t ht j

/-- (4.45): `e_{α,f} = 0` -/
theorem chk_4_45 (t : ℝ) (ht : 0 ≤ t) : H.ea t = 0 :=
  H.ea_zero t ht

/-- (4.51): `E_f α*_f = −ε_{N,f}` -/
theorem chk_4_51 (t : ℝ) (ht : 0 ≤ t) :
    ∑ i : Fin M, S.Ev t i * H.α i.castSucc = -S.eps (Fin.last M) t :=
  H.E_alpha_star_exact t ht

/-- the exact derivative of (4.57) — the statement the (4.58) finding rests on -/
theorem chk_4_57 :
    Deriv L.Vb (fun t => -((L.Ealpt t + L.Sb t * S.SE t)
                            * (L.Ealpt t + H.ea t / S.msq t))) :=
  L.Vb_deriv

/-- (4.65): `M_f ⪰ 0` -/
theorem chk_Mf_psd (x : Fin M → ℝ) (t : ℝ) (ht : 0 ≤ t) : 0 ≤ F.MQ x t :=
  F.Mf_psd x t ht

/-- (4.69): the residual `M_f α*_f + v_f` vanishes — including the `v_f` the
    dissertation omits -/
theorem chk_qres (hea : ∀ t, H.ea t = 0) (t : ℝ) (ht : 0 ≤ t) (i : Fin M) :
    F.qres t i = 0 :=
  F.qres_zero hea t ht i

/-- and that residual really is `M_f α*_f + v_f` -/
theorem chk_qres_shape (t : ℝ) (i : Fin M) :
    F.qres t i = (∑ j, F.Mf t i j * H.α j.castSucc) + F.vf t i :=
  rfl

end Statements

/-! ## Part 2 — the hypothesis bundles are inhabited, and the theorems apply

The Lean port bundles the hypotheses of each level into a structure, so
producing a term of that type discharges every one of them.  All four exist. -/

noncomputable example : Model 1 1 := Instance.M0
noncomputable example : Hull Instance.M0 := Instance.H0
noncomputable example : SecondLevel Instance.H0 := Instance.L0
noncomputable example : Forgetting Instance.H0 := Instance.F0

/-- the second-level theorems, applied to the instance (Coq's `SLA_Instance.v`
    never did this for the SLA/SLAFF levels; see mutant C24) -/
theorem inst_Vb_deriv :
    Deriv Instance.L0.Vb
      (fun t => -((Instance.L0.Ealpt t + Instance.L0.Sb t * Instance.M0.SE t)
                   * (Instance.L0.Ealpt t + Instance.H0.ea t / Instance.M0.msq t))) :=
  Instance.L0.Vb_deriv

theorem inst_Vr_deriv :
    Deriv Instance.L0.Vr
      (fun t => -Instance.L0.γ₂ * (Instance.L0.Ealpt t * Instance.L0.Ealpt t)
                 - Instance.L0.γ₂ * (Instance.L0.Ealpt t
                     * (Instance.H0.ea t / Instance.M0.msq t))) :=
  Instance.L0.Vr_deriv

theorem inst_Mf_psd (x : Fin 1 → ℝ) (t : ℝ) (ht : 0 ≤ t) : 0 ≤ Instance.F0.MQ x t :=
  Instance.F0.Mf_psd x t ht

theorem inst_qres_zero (t : ℝ) (ht : 0 ≤ t) (i : Fin 1) : Instance.F0.qres t i = 0 :=
  Instance.F0.qres_zero Instance.H0_ea t ht i

/-! ## Part 3 — non-degeneracy of the instance

An inhabited bundle is worthless if the inhabitant is trivial. -/

example (t : ℝ) : Instance.M0.Ev t 0 ≠ 0 := Instance.E_nonzero t
example (t : ℝ) : Instance.M0.θ 0 t 0 ≠ Instance.M0.θstar 0 := Instance.models_are_distinct t
example (t : ℝ) : Instance.M0.eps (Fin.last 1) t ≠ 0 := Instance.eps_last_ne_zero t

end SLACheck
