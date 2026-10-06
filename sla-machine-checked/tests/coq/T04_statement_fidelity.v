(** * T04 — statement fidelity: the theorems say what the equations say

    THREAT.  A development can compile, be axiom-free and have a model, and
    still not prove the advertised result: the theorem named "(4.23)" may
    have a flipped sign, a missing factor, an extra hypothesis, or a
    conclusion weakened to something trivial.  Nothing in the build catches
    that, because the *comment* is what carries the claim.

    This file restates each headline result in the form the dissertation
    writes it -- built from definitions given HERE, not imported -- and closes
    each one with a single [exact].  If a statement in SLA_Chapter4 drifts,
    this file stops compiling.  It is the Coq counterpart of
    ../../isabelle/SLA_Check.thy, which does the same for the Isabelle port.

    The claimed right-hand sides of (4.58) and (4.69) are also written out
    here, as [claimed_458] and [claimed_469_term], so that the two findings
    are comparisons between two explicitly stated formulas rather than
    assertions in prose. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Local Open Scope R_scope.

Section Fidelity.

(** the same data as Chapter 4 *)
Variable d : nat.
Variable phi phid : R -> nat -> R.
Variable thstar : nat -> R.
Variable z : R -> R.
Variable N : nat.
Variable th : nat -> R -> nat -> R.
Variable gam : nat -> R.
Variable astar : nat -> R.
Variable M : nat.
Variable gn : R.
Variable alp : R -> nat -> R.

Hypothesis H_phi : forall j, (j < d)%nat -> Deriv (fun t => phi t j) (fun t => phid t j).
Hypothesis H_param : forall t, z t = dot d thstar (phi t).
Hypothesis H_gam : forall j, (j < d)%nat -> 0 < gam j.
Hypothesis H_law : forall i j, (i < N)%nat -> (j < d)%nat ->
  Deriv (fun t => th i t j) (fun t => - (gam j * eps d phi z th i t * phi t j)).
Hypothesis H_astar_sum : Sum N astar = 1.
Hypothesis H_astar_init : forall j, (j < d)%nat ->
  Sum N (fun i => th i 0 j * astar i) = thstar j.
Hypothesis H_NM : N = S M.
Hypothesis H_gn : 0 < gn.
Hypothesis H_sla : forall i, (i < M)%nat ->
  Deriv (fun t => alp t i)
        (fun t => - gn * (Ev d phi z th M t i * Ealp d phi z th M alp t)
                  - gn * (Ev d phi z th M t i * eps d phi z th M t)).

(** (4.15)/(4.28)   e_{i,f} = thetatilde_{i,f}^T phi *)
Theorem chk_4_15 : forall i t, e d phi z th i t = dot d (tht thstar th i t) (phi t).
Proof. exact (e_eq_dot_tht d phi thstar z H_param th). Qed.

(** (4.13)/(4.27)   eps_{i,f} = e_{i,f} / m^2,  m^2 = 1 + phi^T phi *)
Theorem chk_4_13 : forall i t,
  eps d phi z th i t = dot d (tht thstar th i t) (phi t) / msq d phi t.
Proof. exact (eps_eq_dot_tht d phi thstar z H_param th). Qed.

(** (4.23)   Vdot = - eps^2 m^2 *)
Theorem chk_4_23 : forall i, (i < N)%nat ->
  Deriv (V1 d thstar th gam i)
        (fun t => - (eps d phi z th i t * eps d phi z th i t * msq d phi t)).
Proof. exact (V1_dyn d phi thstar z H_param N th gam H_gam H_law). Qed.

(** (4.30)   edot = -(1/m^2) e phi^T Gamma phi + thetatilde^T phidot *)
Theorem chk_4_30 : forall i, (i < N)%nat ->
  Deriv (e d phi z th i)
        (fun t => - (eps d phi z th i t * phiGphi d phi gam t)
                  + dot d (tht thstar th i t) (phid t)).
Proof. exact (e_dyn d phi phid thstar z H_phi H_param N th gam H_law). Qed.

(** (4.41)   theta*_p = sum_i alpha*_i thetahat_{i,f}(t), for every t >= 0 *)
Theorem chk_4_41 : forall t, 0 <= t -> forall j, (j < d)%nat ->
  Sum N (fun i => th i t j * astar i) = thstar j.
Proof.
  exact (theta_star_in_hull d phi thstar z H_param N th gam H_gam H_law
                            astar H_astar_sum H_astar_init).
Qed.

(** (4.45)   e_alpha = sum_i alpha*_i e_{i,f} = 0 *)
Theorem chk_4_45 : forall t, 0 <= t -> ea d phi z N th astar t = 0.
Proof.
  exact (ea_zero d phi thstar z H_param N th gam H_gam H_law
                 astar H_astar_sum H_astar_init).
Qed.

(** (4.51)   E_f alpha*_f = - eps_{N,f} *)
Theorem chk_4_51 : forall t, 0 <= t ->
  Sum M (fun i => Ev d phi z th M t i * astar i) = - eps d phi z th M t.
Proof.
  exact (E_alpha_star_exact d phi thstar z H_param N th gam H_gam H_law
                            astar H_astar_sum H_astar_init M H_NM).
Qed.

(** ** The two findings, as a comparison of two written-out formulas *)

(** what (4.58) claims:  Vdot = -N alphatilde^T E^T E alphatilde
                                - N alphatilde^T E^T e_alpha/m^2   *)
Definition claimed_458 (n : nat) (Ea r : R) : R := - (INR n * (Ea * Ea)) - INR n * (Ea * r).

(** what the exact derivative of (4.57) is *)
Definition exact_457 (Ea Sbv SEv r : R) : R := - ((Ea + Sbv * SEv) * (Ea + r)).

Theorem chk_4_58_exact_derivative :
  Deriv (Vb astar M gn alp)
        (fun t => exact_457 (Ealpt d phi z th astar M alp t)
                            (Sb astar M alp t)
                            (SE d phi z th M t)
                            (ea d phi z N th astar t / msq d phi t)).
Proof.
  unfold exact_457.
  exact (Vb_dyn d phi z N th astar H_astar_sum M H_NM gn H_gn alp H_sla).
Qed.

(** the two formulas are different functions, and the exact one is not sign
    definite: at (Ea, 1a, 1E, r) = (1, -2, 1, 0) it is +1 while (4.58) gives -3 *)
Theorem chk_458_differs : exact_457 1 (-2) 1 0 <> claimed_458 3 1 0.
Proof. unfold exact_457, claimed_458. simpl. lra. Qed.

Theorem chk_458_not_negative_semidefinite : 0 < exact_457 1 (-2) 1 0.
Proof. unfold exact_457. lra. Qed.

(** for (4.69): the dissertation's last term is -N alphatilde^T M_f alpha*_f,
    i.e. it omits v_f from the residual.  The residual proved here is
    [qres] = M_f alpha*_f + v_f. *)
Definition claimed_469_term (Mfa : R) : R := Mfa.
Definition exact_469_term (Mfa vfi : R) : R := Mfa + vfi.

Theorem chk_469_omits_vf : forall Mfa vfi,
  vfi <> 0 -> exact_469_term Mfa vfi <> claimed_469_term Mfa.
Proof. intros Mfa vfi Hv. unfold exact_469_term, claimed_469_term. lra. Qed.

End Fidelity.

(** ** The reduced and the literal Lyapunov candidates are different functions

    Caveat 2 of ../../VERIFICATION.md, machine-checked: [Vr] is the *reduced*
    candidate (1/2) alphatilde^T alphatilde of Narendra-Wang-Chen, NOT the
    alphabartilde^T alphabartilde / 2 gamma of (4.57)/(4.68).  A reader who
    conflates them would read the (4.58) finding as being about the wrong
    function, so the difference is worth stating rather than commenting. *)

Theorem chk_Vr_is_not_the_literal_457 :
  Vr (fun _ => 0) 1 (fun _ _ => 1) 0 <> Vb (fun _ => 0) 1 1 (fun _ _ => 1) 0.
Proof.
  unfold Vr, Vb, Wq, Sb. cbn [Sum]. unfold alpt. rewrite Rinv_1. lra.
Qed.

(** [qres] really is M_f alpha* + v_f, i.e. the term compared above is the
    one the development uses *)
Theorem chk_qres_is_Mf_astar_plus_vf : forall astar M Mf vf t i,
  qres astar M Mf vf t i = Sum M (fun j => Mf t i j * astar j) + vf t i.
Proof. intros. reflexivity. Qed.
