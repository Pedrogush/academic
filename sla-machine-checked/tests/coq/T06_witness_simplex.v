(** * T06 — the same refutation, from an initial state inside the simplex

    OBJECTION TO T03.  The trajectory of T03 has
    alpha_f(0) = (0, -4/3): the second-level parameter starts outside the
    simplex.  Someone defending (4.58) could answer that such a state is not
    one the algorithm is meant to visit, and that the counterexample therefore
    does not bear on the intended operating regime.

    The objection cannot be met at that witness: the state used there has
    1.alphatilde = -2, and since sum(alpha*_f) <= 1 always, 1.alphatilde = -2
    forces sum(alpha_f) <= -1 < 0.  Every state with those scalar values lies
    outside the simplex.  So a different witness is needed.

    THIS FILE.  A second complete model of Chapter 4, again at d = 2,
    N = 3 = d+1, M = 2, in which

        alpha_f(0) = (1, 0)   -- a VERTEX of the simplex,
        alpha*     = (1/3, 1/3, 1/3),
        E_f(0)     = (1, 3),

    every hypothesis of the chapter holds, e_alpha == 0, and at t = 0

        exact derivative of (4.57)  =  +1/3   (V INCREASES)
        value claimed by (4.58)     =  -1/3

    -- the two do not even agree in sign.  The first level is as in T03 with
    s = (-2/3, 10/3, -8/3), c = (1,-1,0); the second level integrates to
    alphatilde(t) = alphatilde(0) - ((w-1)/30) E_f(0)^T with
    w(t) = exp(-5 + 5 e^{-2t}).

    Conclusion: a legitimate initial condition for the second level -- the
    convex combination that puts all weight on the first model -- already
    makes the dissertation's Lyapunov function increase. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Require Import T03_witness_458.       (* for D_comp_exp, increases_if_deriv_pos *)
Local Open Scope R_scope.

(** ** The model *)

Definition s' (i : nat) : R := match i with O => -2/3 | S O => 10/3 | _ => -8/3 end.
Definition c' (i : nat) : R := match i with O => 1 | S O => -1 | _ => 0 end.

Definition QPHI   : R -> nat -> R := fun _ j => match j with O => 1 | _ => 0 end.
Definition QPHID  : R -> nat -> R := fun _ _ => 0.
Definition QTHSTAR: nat -> R      := fun _ => 0.
Definition QZ     : R -> R        := fun _ => 0.
Definition QTH    : nat -> R -> nat -> R :=
  fun i t j => match j with O => s' i * exp (-1 * t) | _ => c' i end.
Definition QGAM   : nat -> R      := fun _ => 2.
Definition QBETA  : nat -> R      := fun _ => 1/3.
Definition QASTAR : nat -> R      := fun _ => 1/3.
Definition QGN    : R             := 1.

Definition wq (t : R) : R := exp (-5 + 5 * exp (-2 * t)).
Definition fq (t : R) : R := - (wq t - 1) / 30.

(** alpha_f = alpha*_f + alphatilde,  alphatilde = alphatilde(0) + f E_f(0) *)
Definition QALP (t : R) (i : nat) : R :=
  match i with
  | O   => 1 + fq t * 1
  | S O => 0 + fq t * 3
  | _   => 0
  end.

Lemma wq0 : wq 0 = 1.
Proof.
  unfold wq. replace (-2 * 0) with 0 by ring. rewrite exp_0.
  replace (-5 + 5 * 1) with 0 by field. apply exp_0.
Qed.

Lemma fq0 : fq 0 = 0.
Proof. unfold fq. rewrite wq0. field. Qed.

Lemma wq_dyn : Deriv wq (fun t => -10 * exp (-2 * t) * wq t).
Proof.
  unfold wq.
  apply (D_ext (fun t => exp (-5 + 5 * exp (-2 * t)))
               (fun t => (0 + 5 * (-2 * exp (-2 * t)))
                         * exp (-5 + 5 * exp (-2 * t)))).
  - intros; reflexivity.
  - intros t. field.
  - apply D_comp_exp. apply D_plus; [apply D_const|].
    apply D_scal. apply D_exp_lin.
Qed.

Lemma fq_dyn : Deriv fq (fun t => exp (-2 * t) * wq t / 3).
Proof.
  unfold fq.
  apply (D_ext (fun t => (- / 30) * (wq t - 1))
               (fun t => (- / 30) * (-10 * exp (-2 * t) * wq t - 0))).
  - intros t. unfold Rdiv. ring.
  - intros t. field.
  - apply D_scal. apply D_minus; [apply wq_dyn | apply D_const].
Qed.

(** ** Closed forms *)

Lemma Q_msq : forall t, msq 2 QPHI t = 2.
Proof. intros t. unfold msq, dot, QPHI. cbn [Sum]. ring. Qed.

Lemma Q_e : forall i t, e 2 QPHI QZ QTH i t = s' i * exp (-1 * t).
Proof. intros i t. unfold e, zh, dot, QPHI, QZ, QTH. cbn [Sum]. ring. Qed.

Lemma Q_eps : forall i t, eps 2 QPHI QZ QTH i t = s' i * exp (-1 * t) / 2.
Proof. intros i t. unfold eps. rewrite Q_e, Q_msq. reflexivity. Qed.

Lemma Q_eps_last : forall t, eps 2 QPHI QZ QTH 2 t = -4/3 * exp (-1 * t).
Proof. intros t. rewrite Q_eps. unfold s'. field. Qed.

Lemma Q_Ev0 : forall t, Ev 2 QPHI QZ QTH 2 t 0 = exp (-1 * t).
Proof. intros t. unfold Ev. rewrite !Q_eps. unfold s'. field. Qed.

Lemma Q_Ev1 : forall t, Ev 2 QPHI QZ QTH 2 t 1 = 3 * exp (-1 * t).
Proof. intros t. unfold Ev. rewrite !Q_eps. unfold s'. field. Qed.

Lemma Q_ea : forall t, ea 2 QPHI QZ 3 QTH QASTAR t = 0.
Proof. intros t. unfold ea. cbn [Sum]. rewrite !Q_e. unfold s', QASTAR. field. Qed.

(** ** Every hypothesis of Chapter 4 *)

Lemma Q_H_phi : forall j, (j < 2)%nat -> Deriv (fun t => QPHI t j) (fun t => QPHID t j).
Proof. intros j Hj. unfold QPHI, QPHID. destruct j; apply D_const. Qed.

Lemma Q_H_param : forall t, QZ t = dot 2 QTHSTAR (QPHI t).
Proof. intros t. unfold QZ, dot, QTHSTAR, QPHI. cbn [Sum]. ring. Qed.

Lemma Q_H_N_exact : (3 = S 2)%nat.       Proof. reflexivity. Qed.
Lemma Q_H_NM      : (3 = S 2)%nat.       Proof. reflexivity. Qed.
Lemma Q_H_gn      : 0 < QGN.             Proof. unfold QGN. lra. Qed.

Lemma Q_H_gam : forall j, (j < 2)%nat -> 0 < QGAM j.
Proof. intros j Hj. unfold QGAM. lra. Qed.

Lemma Q_H_law : forall i j, (i < 3)%nat -> (j < 2)%nat ->
  Deriv (fun t => QTH i t j)
        (fun t => - (QGAM j * eps 2 QPHI QZ QTH i t * QPHI t j)).
Proof.
  intros i j Hi Hj. destruct j as [|j].
  - apply (D_ext (fun t => s' i * exp (-1 * t)) (fun t => s' i * (-1 * exp (-1 * t)))).
    + intros; reflexivity.
    + intros t. rewrite Q_eps. unfold QGAM, QPHI. field.
    + apply D_scal. apply D_exp_lin.
  - apply (D_ext (fun _ => c' i) (fun _ => 0)).
    + intros; reflexivity.
    + intros t. unfold QGAM, QPHI. ring.
    + apply D_const.
Qed.

Lemma Q_H_beta_sum : Sum 3 QBETA = 1.
Proof. unfold QBETA. cbn [Sum]. field. Qed.
Lemma Q_H_beta_rng : forall i, (i < 3)%nat -> 0 <= QBETA i <= 1.
Proof. intros i Hi. unfold QBETA. lra. Qed.
Lemma Q_H_astar_sum : Sum 3 QASTAR = 1.
Proof. unfold QASTAR. cbn [Sum]. field. Qed.
Lemma Q_H_astar_rng : forall i, (i < 3)%nat -> 0 <= QASTAR i <= 1.
Proof. intros i Hi. unfold QASTAR. lra. Qed.

Lemma Q_H_astar_init : forall j, (j < 2)%nat ->
  Sum 3 (fun i => QTH i 0 j * QASTAR i) = QTHSTAR j.
Proof.
  intros j Hj. unfold QTHSTAR, QASTAR, QTH. cbn [Sum].
  replace (-1 * 0) with 0 by ring. rewrite exp_0.
  destruct j as [|j]; [ unfold s'; field | unfold c'; field ].
Qed.

Lemma Q_Ealp : forall t, Ealp 2 QPHI QZ QTH 2 QALP t
                         = exp (-1 * t) * (1 + 10 * fq t).
Proof.
  intros t. unfold Ealp. cbn [Sum]. rewrite Q_Ev0, Q_Ev1. unfold QALP. field.
Qed.

Lemma Q_H_sla : forall i, (i < 2)%nat ->
  Deriv (fun t => QALP t i)
        (fun t => - QGN * (Ev 2 QPHI QZ QTH 2 t i * Ealp 2 QPHI QZ QTH 2 QALP t)
                  - QGN * (Ev 2 QPHI QZ QTH 2 t i * eps 2 QPHI QZ QTH 2 t)).
Proof.
  intros i Hi. destruct i as [|[|i]].
  - apply (D_ext (fun t => 1 + fq t * 1)
                 (fun t => 0 + exp (-2 * t) * wq t / 3 * 1)).
    + intros; reflexivity.
    + intros t. rewrite Q_Ealp, Q_eps_last, Q_Ev0. unfold QGN, fq.
      rewrite <- (exp_sq2 t). field.
    + apply D_plus; [apply D_const|].
      apply (D_ext (fun t => fq t * 1) (fun t => exp (-2 * t) * wq t / 3 * 1 + fq t * 0)).
      * intros; reflexivity.
      * intros; ring.
      * apply D_mult; [apply fq_dyn | apply D_const].
  - apply (D_ext (fun t => 0 + fq t * 3)
                 (fun t => 0 + exp (-2 * t) * wq t / 3 * 3)).
    + intros; reflexivity.
    + intros t. rewrite Q_Ealp, Q_eps_last, Q_Ev1. unfold QGN, fq.
      rewrite <- (exp_sq2 t). field.
    + apply D_plus; [apply D_const|].
      apply (D_ext (fun t => fq t * 3) (fun t => exp (-2 * t) * wq t / 3 * 3 + fq t * 0)).
      * intros; reflexivity.
      * intros; ring.
      * apply D_mult; [apply fq_dyn | apply D_const].
  - exfalso. lia.
Qed.

(** ** alpha_f(0) is a vertex of the simplex *)

Theorem Q_alp0_is_a_simplex_vertex :
  QALP 0 0 = 1 /\ QALP 0 1 = 0
  /\ 0 <= QALP 0 0 <= 1 /\ 0 <= QALP 0 1 <= 1
  /\ QALP 0 0 + QALP 0 1 = 1.
Proof. unfold QALP. rewrite fq0. repeat split; lra. Qed.

(** ** The state at t = 0 *)

Lemma Q_Ealpt0 : Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0 = -1/3.
Proof.
  unfold Ealpt, alpt. cbn [Sum]. rewrite Q_Ev0, Q_Ev1.
  replace (-1 * 0) with 0 by ring. rewrite exp_0.
  unfold QALP, QASTAR. rewrite fq0. field.
Qed.

Lemma Q_Sb0 : Sb QASTAR 2 QALP 0 = 1/3.
Proof. unfold Sb, alpt. cbn [Sum]. unfold QALP, QASTAR. rewrite fq0. field. Qed.

Lemma Q_SE0 : SE 2 QPHI QZ QTH 2 0 = 4.
Proof.
  unfold SE. cbn [Sum]. rewrite Q_Ev0, Q_Ev1.
  replace (-1 * 0) with 0 by ring. rewrite exp_0. field.
Qed.

(** ** Consequences *)

Theorem Q_Vb_dyn :
  Deriv (Vb QASTAR 2 QGN QALP)
        (fun t => - ((Ealpt 2 QPHI QZ QTH QASTAR 2 QALP t
                      + Sb QASTAR 2 QALP t * SE 2 QPHI QZ QTH 2 t)
                     * (Ealpt 2 QPHI QZ QTH QASTAR 2 QALP t
                        + ea 2 QPHI QZ 3 QTH QASTAR t / msq 2 QPHI t))).
Proof.
  apply (Vb_dyn 2 QPHI QZ 3 QTH QASTAR Q_H_astar_sum 2 Q_H_NM QGN Q_H_gn
                QALP Q_H_sla).
Qed.

Theorem Q_Vb_rate_at_0 :
  - ((Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
      + Sb QASTAR 2 QALP 0 * SE 2 QPHI QZ QTH 2 0)
     * (Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
        + ea 2 QPHI QZ 3 QTH QASTAR 0 / msq 2 QPHI 0)) = 1/3.
Proof.
  rewrite Q_Ealpt0, Q_Sb0, Q_SE0, Q_ea, Q_msq. field.
Qed.

Theorem Q_rate_458_at_0 :
  - (INR 3 * (Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
              * Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0)) = -1/3.
Proof.
  rewrite Q_Ealpt0. replace (INR 3) with 3 by (simpl; ring). field.
Qed.

(** the exact derivative and (4.58) differ in SIGN here *)
Theorem Q_458_wrong_sign :
  0 < - ((Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
          + Sb QASTAR 2 QALP 0 * SE 2 QPHI QZ QTH 2 0)
         * (Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
            + ea 2 QPHI QZ 3 QTH QASTAR 0 / msq 2 QPHI 0))
  /\ - (INR 3 * (Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0
                 * Ealpt 2 QPHI QZ QTH QASTAR 2 QALP 0)) < 0.
Proof. rewrite Q_Vb_rate_at_0, Q_rate_458_at_0. lra. Qed.

(** and (4.57) strictly increases from this simplex vertex *)
Theorem Q_Vb_strictly_increases :
  exists h, 0 < h /\ Vb QASTAR 2 QGN QALP 0 < Vb QASTAR 2 QGN QALP h.
Proof.
  apply (increases_if_deriv_pos _ _ Q_Vb_dyn).
  rewrite Q_Vb_rate_at_0. lra.
Qed.

(** the first level and the hull hold for this model too *)
Corollary Q_hull_invariance : forall t, 0 <= t -> forall j, (j < 2)%nat ->
  tha QTHSTAR 3 QTH QASTAR t j = 0.
Proof.
  apply (hull_invariance 2 QPHI QTHSTAR QZ Q_H_param 3 QTH QGAM Q_H_gam Q_H_law
                         QASTAR Q_H_astar_sum Q_H_astar_init).
Qed.

Lemma Q_models_affinely_independent :
  (QTH 0 0 0 - QTH 2 0 0) * (QTH 1 0 1 - QTH 2 0 1)
  - (QTH 1 0 0 - QTH 2 0 0) * (QTH 0 0 1 - QTH 2 0 1) <> 0.
Proof.
  unfold QTH, s', c'. replace (-1 * 0) with 0 by ring. rewrite exp_0. lra.
Qed.
