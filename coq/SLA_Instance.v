(** * SLA_Instance.v — a concrete model of every hypothesis of SLA_Chapter4

    A formalisation whose theorems live under a long list of hypotheses is
    worthless if those hypotheses are contradictory: everything would then be
    provable vacuously.  This file rules that out by exhibiting concrete
    signals for which *every* hypothesis of [SLA_Chapter4] holds, and then
    instantiating the main theorem on them.

    The instance is the simplest non-degenerate one whose adaptive ODEs have
    closed-form solutions:

      d = 1,  N = 2 models (M = 1),  phi(t) = 1,  theta*_p = 1,  z(t) = 1,
      Gamma = 2, so the gradient law (4.19) is  d/dt thetahat_i = -(thetahat_i - 1)
      and hence            thetahat_i(t) = 1 + (v_i - 1) e^{-t}
      with initial values  v = (0, 2).

    AMENDMENT (see NOTE_convex_uniqueness.md).  An earlier version of this file
    used N = 3 models at d = 1.  That satisfied the dissertation's rule as
    written (N >= 2n+1) but violated the amended rule N = 2n+1 = d+1, and it
    was degenerate in a way that matters: with three points on a line the
    convex coefficients are not unique — alpha* = (s, s, 1-2s) works for every
    s in [0, 1/2] — and correspondingly the second-level regressor E_f(t) was
    rank 1 in R^2 for every t, so the second-level problem was structurally
    under-determined.  With N = d+1 = 2 the coefficients are unique, which is
    now proved here as [inst_astar_unique], and E_f is a nonzero scalar.

    The two model estimates are genuinely distinct and time-varying, the
    identification errors e_i(t) = (v_i - 1) e^{-t} are nonzero, and the
    second-level regressor E_f(t) = -e^{-t} is nowhere zero.  The convex
    coefficients alpha* = (1/2, 1/2) reproduce theta*_p = 1 from v = (0, 2),
    and they are the only ones that do.

    For the second level we take alpha_f == alpha*, which satisfies both the
    SLA law (4.52) and the SLAFF law (4.67) precisely because e_alpha == 0 —
    itself an instance of the convex-hull invariance theorem.  With sigma = 1
    the forgetting-factor equations (4.66) also solve in closed form:
      M_f(t) = c_ij (e^{-t} - e^{-2t}),   v_f(t) = c_i (e^{-t} - e^{-2t}).
    Unlike the old N = 3 instance, v_f is no longer identically zero, because
    the last model no longer sits exactly on theta*_p. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Local Open Scope R_scope.

(** ** The instance *)

Definition v (i : nat) : R := match i with O => 0 | _ => 2 end.

Definition PHI   : R -> nat -> R := fun _ _ => 1.
Definition PHID  : R -> nat -> R := fun _ _ => 0.
Definition THSTAR: nat -> R      := fun _ => 1.
Definition Z     : R -> R        := fun _ => 1.
Definition TH    : nat -> R -> nat -> R := fun i t _ => 1 + (v i - 1) * exp (-1 * t).
Definition GAM   : nat -> R      := fun _ => 2.
Definition BETA  : nat -> R      := fun _ => 1 / 2.
Definition ASTAR : nat -> R      := fun _ => 1 / 2.
Definition GN    : R := 1.
Definition SIG   : R := 1.
Definition ALP   : R -> nat -> R := fun _ i => ASTAR i.
Definition MF    : R -> nat -> nat -> R :=
  fun t i j => (v i - 2) * (v j - 2) / 4 * (exp (-1 * t) - exp (-2 * t)).
Definition VF    : R -> nat -> R :=
  fun t i => (v i - 2) / 4 * (exp (-1 * t) - exp (-2 * t)).

Lemma v0 : v 0 = 0. Proof. reflexivity. Qed.
Lemma v1 : v 1 = 2. Proof. reflexivity. Qed.

(** ** Closed forms of the derived signals *)

Lemma inst_msq : forall t, msq 1 PHI t = 2.
Proof. intros t. unfold msq, dot, PHI. cbn [Sum]. ring. Qed.

Lemma inst_e : forall i t, e 1 PHI Z TH i t = (v i - 1) * exp (-1 * t).
Proof. intros i t. unfold e, zh, dot, PHI, Z, TH. cbn [Sum]. ring. Qed.

Lemma inst_eps : forall i t, eps 1 PHI Z TH i t = (v i - 1) * exp (-1 * t) / 2.
Proof. intros i t. unfold eps. rewrite inst_e, inst_msq. reflexivity. Qed.

(** the last model (index M = 1) starts at 2, so its error does NOT vanish *)
Lemma inst_eps1 : forall t, eps 1 PHI Z TH 1 t = exp (-1 * t) / 2.
Proof. intros t. rewrite inst_eps, v1. field. Qed.

Lemma inst_Ev : forall i t, Ev 1 PHI Z TH 1 t i = (v i - 2) * exp (-1 * t) / 2.
Proof. intros i t. unfold Ev. rewrite (inst_eps i t), inst_eps1. field. Qed.

Lemma exp_sq : forall t, exp (-1 * t) * exp (-1 * t) = exp (-2 * t).
Proof. intros t. rewrite <- exp_plus. f_equal. ring. Qed.

(** ** Every hypothesis of SLA_Chapter4 holds for this instance *)

Lemma H_phi_ok : forall j, (j < 1)%nat -> Deriv (fun t => PHI t j) (fun t => PHID t j).
Proof. intros j Hj. unfold PHI, PHID. apply D_const. Qed.

Lemma H_param_ok : forall t, Z t = dot 1 THSTAR (PHI t).           (* (4.8) *)
Proof. intros t. unfold Z, dot, THSTAR, PHI. cbn [Sum]. ring. Qed.

(** the amended design rule N = 2n+1 = d+1, here 2 = 1+1 *)
Lemma H_N_exact_ok : (2 = S 1)%nat.
Proof. reflexivity. Qed.

Lemma H_gam_ok : forall j, (j < 1)%nat -> 0 < GAM j.               (* (4.17) *)
Proof. intros j Hj. unfold GAM. lra. Qed.

Lemma H_law_ok : forall i j, (i < 2)%nat -> (j < 1)%nat ->         (* (4.19)/(4.29) *)
  Deriv (fun t => TH i t j) (fun t => - (GAM j * eps 1 PHI Z TH i t * PHI t j)).
Proof.
  intros i j Hi Hj.
  apply (D_ext (fun t => 1 + (v i - 1) * exp (-1 * t))
               (fun t => 0 + (v i - 1) * (-1 * exp (-1 * t)))).
  - intros t. unfold TH. reflexivity.
  - intros t. rewrite inst_eps. unfold GAM, PHI. field.
  - apply D_plus; [apply D_const | apply D_scal; apply D_exp_lin].
Qed.

Lemma H_beta_sum_ok : Sum 2 BETA = 1.                              (* (4.31) *)
Proof. unfold BETA. cbn [Sum]. lra. Qed.

Lemma H_beta_rng_ok : forall i, (i < 2)%nat -> 0 <= BETA i <= 1.   (* (4.31) *)
Proof. intros i Hi. unfold BETA. lra. Qed.

Lemma H_astar_sum_ok : Sum 2 ASTAR = 1.                            (* (4.41) *)
Proof. unfold ASTAR. cbn [Sum]. lra. Qed.

Lemma H_astar_rng_ok : forall i, (i < 2)%nat -> 0 <= ASTAR i <= 1. (* (4.41) *)
Proof. intros i Hi. unfold ASTAR. lra. Qed.

(** (4.41) at t = 0: theta*_p = 1 is the convex combination
    (1/2)*0 + (1/2)*2 of the initial estimates. *)
Lemma H_astar_init_ok : forall j, (j < 1)%nat ->
  Sum 2 (fun i => TH i 0 j * ASTAR i) = THSTAR j.
Proof.
  intros j Hj. unfold THSTAR. cbn [Sum]. unfold TH, ASTAR.
  replace (-1 * 0) with 0 by ring. rewrite exp_0.
  rewrite v0, v1. field.
Qed.

(** *** Uniqueness of alpha*, which is exactly what N = d+1 buys

    With two affinely independent points on the line, the convex
    representation of theta*_p = 1 is the only one.  The earlier N = 3
    instance admitted a whole one-parameter family; see
    NOTE_convex_uniqueness.md and SLA_AppendixA.more_vertices_not_unique. *)
Lemma inst_astar_unique : forall a,
  Sum 2 a = 1 ->
  (forall j, (j < 1)%nat -> Sum 2 (fun i => TH i 0 j * a i) = THSTAR j) ->
  forall i, (i < 2)%nat -> a i = ASTAR i.
Proof.
  intros a Hsum Hrep i Hi.
  assert (H0 : (0 < 1)%nat) by lia.
  pose proof (Hrep 0%nat H0) as H.
  cbn [Sum] in Hsum, H. unfold TH, THSTAR in H.
  replace (-1 * 0) with 0 in H by ring. rewrite exp_0 in H.
  rewrite v0, v1 in H.
  unfold ASTAR. destruct i as [|[|i]]; [lra | lra | exfalso; lia].
Qed.

Lemma H_NM_ok : (2 = S 1)%nat.
Proof. reflexivity. Qed.

Lemma H_gn_ok : 0 < GN.
Proof. unfold GN. lra. Qed.

(** *** Second level: alpha_f == alpha* is a solution of (4.52) *)

Lemma inst_Ealp : forall t, Ealp 1 PHI Z TH 1 ALP t = - (exp (-1 * t) / 2).
Proof.
  intros t. unfold Ealp. cbn [Sum].
  rewrite (inst_Ev 0 t). unfold ALP, ASTAR. rewrite v0. field.
Qed.

Lemma H_sla_ok : forall i, (i < 1)%nat ->                          (* (4.52) *)
  Deriv (fun t => ALP t i)
        (fun t => - GN * (Ev 1 PHI Z TH 1 t i * Ealp 1 PHI Z TH 1 ALP t)
                  - GN * (Ev 1 PHI Z TH 1 t i * eps 1 PHI Z TH 1 t)).
Proof.
  intros i Hi.
  apply (D_ext (fun t => ASTAR i) (fun t => 0)).
  - intros t. unfold ALP. reflexivity.
  - intros t. rewrite inst_Ealp, inst_eps1. ring.
  - apply D_const.
Qed.

(** *** Forgetting factor: closed-form solutions of (4.66) with sigma = 1 *)

Lemma H_sig_ok : 0 < SIG.
Proof. unfold SIG. lra. Qed.

Lemma H_Mf0_ok : forall i j, MF 0 i j = 0.
Proof.
  intros i j. unfold MF.
  replace (-1 * 0) with 0 by ring. replace (-2 * 0) with 0 by ring.
  rewrite exp_0. field.
Qed.

Lemma H_vf0_ok : forall i, VF 0 i = 0.
Proof.
  intros i. unfold VF.
  replace (-1 * 0) with 0 by ring. replace (-2 * 0) with 0 by ring.
  rewrite exp_0. field.
Qed.

Lemma H_Mf_ok : forall i j, (i < 1)%nat -> (j < 1)%nat ->          (* (4.66) *)
  Deriv (fun t => MF t i j)
        (fun t => - SIG * MF t i j + Ev 1 PHI Z TH 1 t i * Ev 1 PHI Z TH 1 t j).
Proof.
  intros i j Hi Hj.
  apply (D_ext
           (fun t => (v i - 2) * (v j - 2) / 4 * (exp (-1 * t) - exp (-2 * t)))
           (fun t => (v i - 2) * (v j - 2) / 4
                     * (-1 * exp (-1 * t) - -2 * exp (-2 * t)))).
  - intros t. unfold MF. reflexivity.
  - intros t. rewrite (inst_Ev i t), (inst_Ev j t). unfold SIG, MF.
    rewrite <- (exp_sq t). field.
  - apply D_scal. apply D_minus; apply D_exp_lin.
Qed.

Lemma H_vf_ok : forall i, (i < 1)%nat ->                           (* (4.66) *)
  Deriv (fun t => VF t i)
        (fun t => - SIG * VF t i + Ev 1 PHI Z TH 1 t i * eps 1 PHI Z TH 1 t).
Proof.
  intros i Hi.
  apply (D_ext
           (fun t => (v i - 2) / 4 * (exp (-1 * t) - exp (-2 * t)))
           (fun t => (v i - 2) / 4 * (-1 * exp (-1 * t) - -2 * exp (-2 * t)))).
  - intros t. unfold VF. reflexivity.
  - intros t. rewrite (inst_Ev i t), inst_eps1. unfold SIG, VF.
    rewrite <- (exp_sq t). field.
  - apply D_scal. apply D_minus; apply D_exp_lin.
Qed.

Lemma inst_EalpF : forall t, EalpF 1 PHI Z TH 1 ALP t = - (exp (-1 * t) / 2).
Proof.
  intros t. unfold EalpF. cbn [Sum].
  rewrite (inst_Ev 0 t). unfold ALP, ASTAR. rewrite v0. field.
Qed.

(** the residual M_f alpha* + v_f vanishes identically — this is (4.69) with
    the v_f term that the dissertation omits, and it cancels exactly *)
Lemma inst_MFalp : forall i t, Sum 1 (fun j => MF t i j * ALP t j) = - VF t i.
Proof.
  intros i t. cbn [Sum]. unfold MF, ALP, ASTAR, VF. rewrite v0. field.
Qed.

Lemma H_slaff_ok : forall i, (i < 1)%nat ->                        (* (4.67) *)
  Deriv (fun t => ALP t i)
        (fun t => GN * (- Sum 1 (fun j => MF t i j * ALP t j)
                        - Ev 1 PHI Z TH 1 t i * EalpF 1 PHI Z TH 1 ALP t
                        - VF t i
                        - Ev 1 PHI Z TH 1 t i * eps 1 PHI Z TH 1 t)).
Proof.
  intros i Hi.
  apply (D_ext (fun t => ASTAR i) (fun t => 0)).
  - intros t. unfold ALP. reflexivity.
  - intros t. rewrite (inst_MFalp i t), inst_EalpF, inst_eps1. ring.
  - apply D_const.
Qed.

(** ** The main theorem, instantiated

    Convex-hull invariance holds for this instance, and it is not vacuous:
    the individual estimates [TH i t 0] both differ from theta*_p = 1 at every
    finite t, yet their fixed convex combination is exactly 1. *)

Corollary inst_hull_invariance : forall t, 0 <= t -> forall j, (j < 1)%nat ->
  tha THSTAR 2 TH ASTAR t j = 0.
Proof.
  apply (hull_invariance 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok
                         ASTAR H_astar_sum_ok H_astar_init_ok).
Qed.

(** Independent check by direct computation: the same identity obtained
    without the theorem.  Agreement confirms the instance really is a model of
    the hypotheses rather than an artefact of the encoding. *)
Lemma inst_hull_direct : forall t, Sum 2 (fun i => TH i t 0 * ASTAR i) = 1.
Proof.
  intros t. cbn [Sum]. unfold TH, ASTAR. rewrite v0, v1. field.
Qed.

(** The estimates are genuinely distinct: model 0 never equals theta*_p. *)
Lemma inst_models_are_distinct : forall t, TH 0 t 0 <> THSTAR 0.
Proof.
  intros t. unfold TH, THSTAR. rewrite v0.
  pose proof (exp_pos (-1 * t)). lra.
Qed.

(** ... and the second-level regressor E_f is nowhere zero.  At N = d+1 = 2
    the regressor is a scalar, so "nonzero" here really is full rank — unlike
    the old N = 3 instance, where E_f was a nonzero but rank-deficient vector
    in R^2 and the second-level problem was under-determined. *)
Lemma inst_E_nonzero : forall t, Ev 1 PHI Z TH 1 t 0 <> 0.
Proof.
  intros t. rewrite inst_Ev, v0.
  pose proof (exp_pos (-1 * t)). lra.
Qed.
