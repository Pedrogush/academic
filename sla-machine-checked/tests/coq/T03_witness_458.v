(** * T03 — the (4.58) counterexample is realised by an actual trajectory

    THREAT.  [Vb_deriv_can_be_positive] and [Vb_deriv_differs_from_4_58] are
    stated conditionally:

      ea t = 0 -> Ealpt t = 1 -> Sb t = -2 -> SE t = 1 -> 0 < Vdot.

    A conditional statement whose hypotheses cannot be met is vacuous.  The
    three assumptions constrain *derived* quantities of the model, so a
    sceptic is entitled to ask whether any system satisfying (4.19), (4.41)
    and (4.52) ever reaches such a state.  If not, the "refutation" of (4.58)
    refutes nothing.  Neither the Coq, the Lean nor the Isabelle development
    answers that: the closest is a purely arithmetic witness
    (E_f = (2,-1), alphatilde_f = (-1/3,-5/3)) which shows the three scalar
    values are *mutually* consistent, not that they are *reachable*.

    This file closes the gap by exhibiting a complete model of Chapter 4 at

      d = 2,  N = 3 = d + 1 (the amended design rule),  M = 2,

    with closed-form solutions of BOTH adaptive laws, in which the
    counterexample state occurs at t = 0.  Every hypothesis of the chapter is
    discharged, and then [Vb_dyn] is applied to conclude that the
    dissertation's own Lyapunov function (4.57) has derivative +1 at t = 0 --
    so it strictly INCREASES along a genuine trajectory of the system, while
    (4.58) predicts -3.

    The system.  phi = (1,0) constant, theta*_p = 0, Gamma = 2I, so the
    gradient law (4.19) gives thetahat_i(t) = (s_i e^{-t}, c_i) with

      s = (10/3, -8/3, -2/3),   c = (1, -1, 0),   alpha* = (1/3, 1/3, 1/3).

    Then E_f(t) = e^{-t} (2, -1) and e_alpha == 0.  For the second level,
    (4.52) with e_alpha = 0 reduces to alphatildedot = -E^T E alphatilde,
    which for a rank-one E^T E integrates in closed form:

      alphatilde(t) = alphatilde(0) + u(t) E_f(0)^T,
      u(t) = (w(t) - 1)/5,   w(t) = exp(-5/2 + (5/2) e^{-2t}),

    with alphatilde(0) = (-1/3, -5/3) and w(0) = 1. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Local Open Scope R_scope.

(** ** Two pieces of derivative plumbing not in SLA_Prelim *)

Lemma D_comp_exp : forall g g',
  Deriv g g' -> Deriv (fun t => exp (g t)) (fun t => g' t * exp (g t)).
Proof.
  intros g g' Hg t.
  assert (H : derivable_pt_lim (fun x => exp (g x)) t (exp (g t) * g' t)).
  { apply (derivable_pt_lim_comp g exp t (g' t) (exp (g t))).
    - apply Hg.
    - apply derivable_pt_lim_exp. }
  replace (g' t * exp (g t)) with (exp (g t) * g' t) by ring. exact H.
Qed.

(** A function whose derivative at 0 is positive is strictly larger somewhere
    to the right of 0.  This is what makes "Vdot(0) > 0" a statement about
    the trajectory rather than about a formula. *)
Lemma increases_if_deriv_pos : forall f f',
  Deriv f f' -> 0 < f' 0 -> exists h, 0 < h /\ f 0 < f h.
Proof.
  intros f f' Hd Hpos.
  assert (Heps : 0 < f' 0 / 2) by lra.
  destruct (Hd 0 (f' 0 / 2) Heps) as [delta Hdelta].
  set (h := pos delta / 2).
  assert (Hh : 0 < h) by (unfold h; pose proof (cond_pos delta); lra).
  exists h. split; [assumption|].
  assert (Hne : h <> 0) by lra.
  assert (Hlt : Rabs h < delta).
  { rewrite Rabs_right by lra. unfold h. pose proof (cond_pos delta). lra. }
  pose proof (Hdelta h Hne Hlt) as Hb. simpl in Hb.
  apply Rabs_def2 in Hb. destruct Hb as [_ Hb2].
  replace (0 + h) with h in Hb2 by ring.
  assert (Hq : 0 < (f h - f 0) / h) by lra.
  assert (Heq : f h - f 0 = ((f h - f 0) / h) * h) by (field; lra).
  nra.
Qed.

(** ** The model *)

Definition s (i : nat) : R := match i with O => 10/3 | S O => -8/3 | _ => -2/3 end.
Definition c (i : nat) : R := match i with O => 1 | S O => -1 | _ => 0 end.

Definition WPHI   : R -> nat -> R := fun _ j => match j with O => 1 | _ => 0 end.
Definition WPHID  : R -> nat -> R := fun _ _ => 0.
Definition WTHSTAR: nat -> R      := fun _ => 0.
Definition WZ     : R -> R        := fun _ => 0.
Definition WTH    : nat -> R -> nat -> R :=
  fun i t j => match j with O => s i * exp (-1 * t) | _ => c i end.
Definition WGAM   : nat -> R      := fun _ => 2.
Definition WBETA  : nat -> R      := fun _ => 1/3.
Definition WASTAR : nat -> R      := fun _ => 1/3.
Definition WGN    : R             := 1.

(** the closed-form solution of the second-level law *)
Definition w (t : R) : R := exp (-5/2 + 5/2 * exp (-2 * t)).
Definition u (t : R) : R := (w t - 1) / 5.
Definition WALP (t : R) (i : nat) : R :=
  match i with O => 2 * u t | S O => -4/3 - u t | _ => 0 end.

Lemma exp_sq2 : forall t, exp (-1 * t) * exp (-1 * t) = exp (-2 * t).
Proof. intros t. rewrite <- exp_plus. f_equal. ring. Qed.

Lemma w0 : w 0 = 1.
Proof.
  unfold w. replace (-2 * 0) with 0 by ring. rewrite exp_0.
  replace (-5/2 + 5/2 * 1) with 0 by field. apply exp_0.
Qed.

Lemma u0 : u 0 = 0.
Proof. unfold u. rewrite w0. field. Qed.

Lemma w_pos : forall t, 0 < w t.
Proof. intros t. unfold w. apply exp_pos. Qed.

Lemma w_dyn : Deriv w (fun t => -5 * exp (-2 * t) * w t).
Proof.
  unfold w.
  apply (D_ext (fun t => exp (-5/2 + 5/2 * exp (-2 * t)))
               (fun t => (0 + 5/2 * (-2 * exp (-2 * t)))
                         * exp (-5/2 + 5/2 * exp (-2 * t)))).
  - intros; reflexivity.
  - intros t. field.
  - apply D_comp_exp. apply D_plus; [apply D_const|].
    apply D_scal. apply D_exp_lin.
Qed.

Lemma u_dyn : Deriv u (fun t => - exp (-2 * t) * w t).
Proof.
  unfold u.
  apply (D_ext (fun t => / 5 * (w t - 1)) (fun t => / 5 * (-5 * exp (-2 * t) * w t - 0))).
  - intros; unfold Rdiv; ring.
  - intros; field.
  - apply D_scal. apply D_minus; [apply w_dyn | apply D_const].
Qed.

(** ** Closed forms of the derived signals *)

Lemma W_msq : forall t, msq 2 WPHI t = 2.
Proof. intros t. unfold msq, dot, WPHI. cbn [Sum]. ring. Qed.

Lemma W_e : forall i t, e 2 WPHI WZ WTH i t = s i * exp (-1 * t).
Proof.
  intros i t. unfold e, zh, dot, WPHI, WZ, WTH. cbn [Sum]. ring.
Qed.

Lemma W_eps : forall i t, eps 2 WPHI WZ WTH i t = s i * exp (-1 * t) / 2.
Proof. intros i t. unfold eps. rewrite W_e, W_msq. reflexivity. Qed.

Lemma W_Ev : forall i t, Ev 2 WPHI WZ WTH 2 t i = (s i - s 2) * exp (-1 * t) / 2.
Proof. intros i t. unfold Ev. rewrite !W_eps. field. Qed.

Lemma W_Ev0 : forall t, Ev 2 WPHI WZ WTH 2 t 0 = 2 * exp (-1 * t).
Proof. intros t. rewrite W_Ev. unfold s. field. Qed.

Lemma W_Ev1 : forall t, Ev 2 WPHI WZ WTH 2 t 1 = - exp (-1 * t).
Proof. intros t. rewrite W_Ev. unfold s. field. Qed.

Lemma W_ea : forall t, ea 2 WPHI WZ 3 WTH WASTAR t = 0.
Proof.
  intros t. unfold ea. cbn [Sum]. rewrite !W_e. unfold s, WASTAR. field.
Qed.

(** ** Every hypothesis of Chapter 4 holds for this model *)

Lemma W_H_phi : forall j, (j < 2)%nat -> Deriv (fun t => WPHI t j) (fun t => WPHID t j).
Proof.
  intros j Hj. unfold WPHI, WPHID. destruct j; apply D_const.
Qed.

Lemma W_H_param : forall t, WZ t = dot 2 WTHSTAR (WPHI t).          (* (4.8) *)
Proof. intros t. unfold WZ, dot, WTHSTAR, WPHI. cbn [Sum]. ring. Qed.

Lemma W_H_N_exact : (3 = S 2)%nat.                          (* N = 2n+1 = d+1 *)
Proof. reflexivity. Qed.

Lemma W_H_gam : forall j, (j < 2)%nat -> 0 < WGAM j.                (* (4.17) *)
Proof. intros j Hj. unfold WGAM. lra. Qed.

Lemma W_H_law : forall i j, (i < 3)%nat -> (j < 2)%nat ->      (* (4.19)/(4.29) *)
  Deriv (fun t => WTH i t j)
        (fun t => - (WGAM j * eps 2 WPHI WZ WTH i t * WPHI t j)).
Proof.
  intros i j Hi Hj. destruct j as [|j].
  - apply (D_ext (fun t => s i * exp (-1 * t))
                 (fun t => s i * (-1 * exp (-1 * t)))).
    + intros; reflexivity.
    + intros t. rewrite W_eps. unfold WGAM, WPHI. field.
    + apply D_scal. apply D_exp_lin.
  - apply (D_ext (fun _ => c i) (fun _ => 0)).
    + intros; reflexivity.
    + intros t. unfold WGAM, WPHI. ring.
    + apply D_const.
Qed.

Lemma W_H_beta_sum : Sum 3 WBETA = 1.                               (* (4.31) *)
Proof. unfold WBETA. cbn [Sum]. field. Qed.

Lemma W_H_beta_rng : forall i, (i < 3)%nat -> 0 <= WBETA i <= 1.
Proof. intros i Hi. unfold WBETA. lra. Qed.

Lemma W_H_astar_sum : Sum 3 WASTAR = 1.                             (* (4.41) *)
Proof. unfold WASTAR. cbn [Sum]. field. Qed.

Lemma W_H_astar_rng : forall i, (i < 3)%nat -> 0 <= WASTAR i <= 1.
Proof. intros i Hi. unfold WASTAR. lra. Qed.

Lemma W_H_astar_init : forall j, (j < 2)%nat ->                 (* (4.41) at 0 *)
  Sum 3 (fun i => WTH i 0 j * WASTAR i) = WTHSTAR j.
Proof.
  intros j Hj. unfold WTHSTAR, WASTAR, WTH. cbn [Sum].
  replace (-1 * 0) with 0 by ring. rewrite exp_0.
  destruct j as [|j]; [ unfold s; field | unfold c; field ].
Qed.

Lemma W_H_NM : (3 = S 2)%nat.
Proof. reflexivity. Qed.

Lemma W_H_gn : 0 < WGN.
Proof. unfold WGN. lra. Qed.

(** the second-level law (4.52) -- the interesting one *)

Lemma W_Ealp : forall t, Ealp 2 WPHI WZ WTH 2 WALP t = exp (-1 * t) * (5 * u t + 4/3).
Proof.
  intros t. unfold Ealp. cbn [Sum].
  rewrite W_Ev0, W_Ev1. unfold WALP. field.
Qed.

Lemma W_eps_last : forall t, eps 2 WPHI WZ WTH 2 t = - exp (-1 * t) / 3.
Proof. intros t. rewrite W_eps. unfold s. field. Qed.

Lemma W_H_sla : forall i, (i < 2)%nat ->                            (* (4.52) *)
  Deriv (fun t => WALP t i)
        (fun t => - WGN * (Ev 2 WPHI WZ WTH 2 t i * Ealp 2 WPHI WZ WTH 2 WALP t)
                  - WGN * (Ev 2 WPHI WZ WTH 2 t i * eps 2 WPHI WZ WTH 2 t)).
Proof.
  intros i Hi. destruct i as [|[|i]].
  - apply (D_ext (fun t => 2 * u t) (fun t => 2 * (- exp (-2 * t) * w t))).
    + intros; reflexivity.
    + intros t. rewrite W_Ealp, W_eps_last, W_Ev0. unfold WGN, u.
      rewrite <- (exp_sq2 t). field.
    + apply D_scal. apply u_dyn.
  - apply (D_ext (fun t => -4/3 - u t) (fun t => 0 - (- exp (-2 * t) * w t))).
    + intros; reflexivity.
    + intros t. rewrite W_Ealp, W_eps_last, W_Ev1. unfold WGN, u.
      rewrite <- (exp_sq2 t). field.
    + apply D_minus; [apply D_const | apply u_dyn].
  - exfalso. lia.
Qed.

(** ** The counterexample state occurs at t = 0 *)

Lemma W_Ealpt0 : Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0 = 1.
Proof.
  unfold Ealpt, alpt. cbn [Sum].
  rewrite W_Ev0, W_Ev1. replace (-1 * 0) with 0 by ring. rewrite exp_0.
  unfold WALP, WASTAR. rewrite u0. field.
Qed.

Lemma W_Sb0 : Sb WASTAR 2 WALP 0 = -2.
Proof.
  unfold Sb, alpt. cbn [Sum]. unfold WALP, WASTAR. rewrite u0. field.
Qed.

Lemma W_SE0 : SE 2 WPHI WZ WTH 2 0 = 1.
Proof.
  unfold SE. cbn [Sum]. rewrite W_Ev0, W_Ev1.
  replace (-1 * 0) with 0 by ring. rewrite exp_0. field.
Qed.

(** ** Consequences, obtained from the chapter's own theorems *)

(** (4.57)'s derivative, from [Vb_dyn], on this model *)
Theorem W_Vb_dyn :
  Deriv (Vb WASTAR 2 WGN WALP)
        (fun t => - ((Ealpt 2 WPHI WZ WTH WASTAR 2 WALP t
                      + Sb WASTAR 2 WALP t * SE 2 WPHI WZ WTH 2 t)
                     * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP t
                        + ea 2 WPHI WZ 3 WTH WASTAR t / msq 2 WPHI t))).
Proof.
  apply (Vb_dyn 2 WPHI WZ 3 WTH WASTAR W_H_astar_sum 2 W_H_NM WGN W_H_gn
                WALP W_H_sla).
Qed.

(** the value of that derivative at t = 0 is +1 *)
Theorem W_Vb_rate_at_0 :
  - ((Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
      + Sb WASTAR 2 WALP 0 * SE 2 WPHI WZ WTH 2 0)
     * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
        + ea 2 WPHI WZ 3 WTH WASTAR 0 / msq 2 WPHI 0)) = 1.
Proof.
  rewrite W_Ealpt0, W_Sb0, W_SE0, W_ea, W_msq. field.
Qed.

(** what (4.58) predicts at the same instant: -N (E alphatilde)^2 = -3 *)
Theorem W_rate_458_at_0 :
  - (INR 3 * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
              * Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0)) = -3.
Proof.
  rewrite W_Ealpt0. replace (INR 3) with 3 by (simpl; ring). field.
Qed.

(** hence, on a genuine trajectory, (4.58) is off by 4 *)
Theorem W_458_is_wrong_here :
  - ((Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
      + Sb WASTAR 2 WALP 0 * SE 2 WPHI WZ WTH 2 0)
     * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
        + ea 2 WPHI WZ 3 WTH WASTAR 0 / msq 2 WPHI 0))
  <> - (INR 3 * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
                 * Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0)).
Proof.
  rewrite W_Vb_rate_at_0, W_rate_458_at_0. lra.
Qed.

(** and the conditional corollary of the chapter applies to this state:
    its three hypotheses are met by an actual solution of (4.19)+(4.52) *)
Theorem W_conditional_corollary_is_not_vacuous :
  0 < - ((Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
          + Sb WASTAR 2 WALP 0 * SE 2 WPHI WZ WTH 2 0)
         * (Ealpt 2 WPHI WZ WTH WASTAR 2 WALP 0
            + ea 2 WPHI WZ 3 WTH WASTAR 0 / msq 2 WPHI 0)).
Proof.
  apply (Vb_deriv_can_be_positive 2 WPHI WZ 3 WTH WASTAR 2 WALP 0
                                  (W_ea 0) W_Ealpt0 W_Sb0 W_SE0).
Qed.

(** *** The punchline

    The dissertation's Lyapunov function (4.57) is strictly LARGER at some
    positive time than at t = 0, along a trajectory that satisfies every
    hypothesis of Chapter 4.  A function claimed to be nonincreasing by
    (4.58) therefore is not. *)
Theorem W_Vb_strictly_increases :
  exists h, 0 < h /\ Vb WASTAR 2 WGN WALP 0 < Vb WASTAR 2 WGN WALP h.
Proof.
  apply (increases_if_deriv_pos _ _ W_Vb_dyn).
  rewrite W_Vb_rate_at_0. lra.
Qed.

(** ** The same model also witnesses the first level and the hull

    so the trajectory above is not an artefact of ignoring (4.19) or (4.41). *)

Corollary W_hull_invariance : forall t, 0 <= t -> forall j, (j < 2)%nat ->
  tha WTHSTAR 3 WTH WASTAR t j = 0.
Proof.
  apply (hull_invariance 2 WPHI WTHSTAR WZ W_H_param 3 WTH WGAM W_H_gam W_H_law
                         WASTAR W_H_astar_sum W_H_astar_init).
Qed.

Corollary W_V1_dyn : forall i, (i < 3)%nat ->
  Deriv (V1 2 WTHSTAR WTH WGAM i)
        (fun t => - (eps 2 WPHI WZ WTH i t * eps 2 WPHI WZ WTH i t * msq 2 WPHI t)).
Proof.
  apply (V1_dyn 2 WPHI WTHSTAR WZ W_H_param 3 WTH WGAM W_H_gam W_H_law).
Qed.

(** and it is non-degenerate: three affinely independent estimates in R^2,
    a nowhere-zero second-level regressor, and alpha* in the open simplex *)

Lemma W_models_affinely_independent :
  (WTH 0 0 0 - WTH 2 0 0) * (WTH 1 0 1 - WTH 2 0 1)
  - (WTH 1 0 0 - WTH 2 0 0) * (WTH 0 0 1 - WTH 2 0 1) <> 0.
Proof.
  unfold WTH, s, c. replace (-1 * 0) with 0 by ring. rewrite exp_0. lra.
Qed.

Lemma W_E_nowhere_zero : forall t, Ev 2 WPHI WZ WTH 2 t 0 <> 0 /\ Ev 2 WPHI WZ WTH 2 t 1 <> 0.
Proof.
  intros t. rewrite W_Ev0, W_Ev1. pose proof (exp_pos (-1 * t)). lra.
Qed.
