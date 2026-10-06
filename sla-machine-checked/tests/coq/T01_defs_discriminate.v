(** * T01 — the definitions themselves are not vacuous

    THREAT.  Every theorem in [SLA_Chapter4] is stated in terms of a handful of
    defined notions: [Deriv], [Sum], [dot], [Wq], [msq].  If any of those were
    degenerate — [Deriv f f'] always true, [Sum] always 0, [dot] ignoring one
    argument — then every theorem above it would still compile and would still
    say nothing.  A "Print Assumptions" audit does not see this: no axiom is
    involved, the development is simply talking about the wrong thing.

    This file pins the definitions from below.  Each lemma fails if the
    corresponding notion is replaced by a vacuous or constant one, which is
    exactly what mutants D1, D2 and D5 of ../mutants/catalogue.tsv do. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Local Open Scope R_scope.

(** ** [Deriv] really is differentiation

    If [Deriv] were [fun _ _ => True] (mutant D1) the whole development would
    still compile.  It is not: it refutes a wrong derivative. *)

Lemma deriv_discriminates : ~ Deriv (fun t => t) (fun _ => 0).
Proof.
  intros H.
  (* the derivative of the identity is 1, and derivatives are unique *)
  pose proof (D_id) as Hid.
  assert (Huniq : (1 = 0)%R).
  { apply (uniqueness_limite (fun t => t) 0 1 0); [apply Hid | apply H]. }
  lra.
Qed.

(** and it is not the empty relation either: it holds where it should *)
Lemma deriv_inhabited : Deriv (fun t => 3 * t) (fun _ => 3).
Proof. apply D_lin. Qed.

(** A quantitative consequence, independent of [Deriv]'s internals: a function
    with a strictly negative derivative really does decrease. *)
Lemma deriv_has_teeth : forall f f',
  Deriv f f' -> (forall t, f' t <= 0) -> f 1 <= f 0.
Proof.
  intros f f' Hd Hs. apply (nonincr_of_nonpos_deriv f f' Hd Hs). lra.
Qed.

(** ** [Sum] really adds up *)

Lemma Sum_computes : Sum 3 (fun i => INR i + 1) = 6.
Proof. cbn [Sum]. replace (INR 0) with 0 by reflexivity.
  replace (INR 1) with 1 by reflexivity.
  replace (INR 2) with 2 by (simpl; ring). ring.
Qed.

Lemma Sum_sees_every_index : Sum 3 (fun i => if Nat.eqb i 2 then 5 else 0) = 5.
Proof. cbn. ring. Qed.

(** ** [dot] really is a bilinear pairing, not a projection *)

Definition u2 : nat -> R := fun j => match j with O => 2 | _ => 3 end.
Definition w2 : nat -> R := fun j => match j with O => 5 | _ => 7 end.

Lemma dot_computes : dot 2 u2 w2 = 31.
Proof. unfold dot, u2, w2. cbn [Sum]. ring. Qed.

Lemma dot_uses_both_arguments : dot 2 u2 w2 <> dot 2 u2 u2.
Proof. unfold dot, u2, w2. cbn [Sum]. lra. Qed.

(** ** [Wq] really is the quadratic form, positive off zero *)

Lemma Wq_computes : Wq 2 (fun _ => 1) (fun _ => u2) 0 = 13 / 2.
Proof. unfold Wq, u2. cbn [Sum]. rewrite Rinv_1. field. Qed.

Lemma Wq_positive_off_zero : 0 < Wq 2 (fun _ => 1) (fun _ => u2) 0.
Proof. rewrite Wq_computes. lra. Qed.

(** ** [msq] really is 1 + |phi|^2, hence > 1 for a nonzero regressor *)

Lemma msq_gt_one : 1 < msq 2 (fun _ => u2) 0.
Proof. unfold msq, dot, u2. cbn [Sum]. lra. Qed.

(** ** The Lyapunov machinery is not vacuously applicable

    [quad_zero] is the engine behind [hull_invariance] and [qres_zero].  Its
    conclusion is strong, so a reader should check that its hypotheses can be
    met at all — otherwise every use of it is vacuous. *)

Lemma quad_zero_is_inhabited :
  forall t, 0 <= t -> forall j, (j < 2)%nat -> (fun (_ : R) (_ : nat) => 0) t j = 0.
Proof.
  apply (quad_zero 2 (fun _ => 1) (fun _ _ => 0) (fun _ => 0)).
  - intros; lra.
  - apply (D_ext (fun _ => 0) (fun _ => 0)).
    + intros t. unfold Wq. cbn [Sum]. rewrite Rinv_1. ring.
    + intros; reflexivity.
    + apply D_const.
  - intros; lra.
  - intros; reflexivity.
Qed.
