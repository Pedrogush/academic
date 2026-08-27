(** * T02 — the hypothesis bundle has a model, and the theorems say something on it

    THREAT 1 (vacuity).  Every theorem of [SLA_Chapter4] is stated inside a
    section with ~15 hypotheses.  If those hypotheses were jointly
    unsatisfiable, every theorem would hold vacuously and the whole
    development would be worthless — while still compiling with exit 0 and
    with a clean [Print Assumptions].

    THREAT 2 (degeneracy).  A model may exist but be trivial: all signals
    zero, [d = 0], [M = 0], [E_f = 0].  Then the theorems are true but empty.

    THREAT 3 (statement drift).  A theorem may be *about* something else than
    its comment claims.  Instantiating it on a system whose closed-form
    solution is known and comparing with a hand computation catches that.

    [SLA_Instance] answers threat 1 for the first level.  This file goes
    further: it instantiates *every headline theorem* of the chapter on that
    model — including the SLA and SLAFF ones, which [SLA_Instance] never
    applies — checks non-degeneracy, and cross-checks two derivative claims
    against derivatives computed by hand from the closed forms.

    It also discharges caveat 1 of ../../VERIFICATION.md: the corollaries that
    assume [e_alpha = 0] on all of R (not just [t >= 0]) are satisfiable, and
    here is a model that satisfies them. *)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Require Import SLA.SLA_Instance.
Local Open Scope R_scope.

(** ** The global form of e_alpha = 0

    [ea_zero] only gives [t >= 0].  The instance satisfies the stronger
    hypothesis used by [Vr_nonincreasing], [qres_zero] and [VrF_nonpos]. *)

Lemma inst_ea_all : forall t, ea 1 PHI Z 2 TH ASTAR t = 0.
Proof.
  intros t. unfold ea. cbn [Sum].
  rewrite (inst_e 0 t), (inst_e 1 t), v0, v1. unfold ASTAR. field.
Qed.

(** ** Non-degeneracy of the model

    d = 1 > 0, M = 1 > 0, and the signals that the theorems talk about are
    not identically zero. *)

Lemma nondeg_dim : (0 < 1)%nat /\ (0 < 1)%nat.  (* d and M *)
Proof. lia. Qed.

Lemma nondeg_msq : msq 1 PHI 0 = 2.
Proof. apply inst_msq. Qed.

Lemma nondeg_eps : eps 1 PHI Z TH 0 0 <> 0.
Proof.
  rewrite inst_eps, v0. replace (-1 * 0) with 0 by ring. rewrite exp_0. lra.
Qed.

Lemma nondeg_Ev : forall t, Ev 1 PHI Z TH 1 t 0 <> 0.
Proof. exact inst_E_nonzero. Qed.

(** the first-level Lyapunov function is not constant: it strictly decreases,
    so [V1_nonincreasing] is not the trivial statement [c <= c] *)
Lemma inst_V1_closed : forall i t, V1 1 THSTAR TH GAM i t = (v i - 1) * (v i - 1) * exp (-2 * t) / 4.
Proof.
  intros i t. unfold V1, Wq, tht, TH, THSTAR, GAM. cbn [Sum].
  rewrite <- (exp_sq t). field.
Qed.

Lemma nondeg_V1_strictly_decreases : V1 1 THSTAR TH GAM 0 1 < V1 1 THSTAR TH GAM 0 0.
Proof.
  rewrite !inst_V1_closed, v0.
  replace (-2 * 0) with 0 by ring. rewrite exp_0.
  assert (exp (-2 * 1) < 1).
  { replace 1 with (exp 0) at 2 by apply exp_0. apply exp_increasing. lra. }
  lra.
Qed.

(** ** Threat 3: the derivative claims agree with a hand computation

    [V1_dyn] says Vdot = -(eps^2 m^2).  Below, the closed form of V1 is
    differentiated directly, and the two answers are compared. *)

Lemma inst_V1_dyn_thm : forall i, (i < 2)%nat ->
  Deriv (V1 1 THSTAR TH GAM i)
        (fun t => - (eps 1 PHI Z TH i t * eps 1 PHI Z TH i t * msq 1 PHI t)).
Proof.
  apply (V1_dyn 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok).
Qed.

(** the same derivative obtained from the closed form, with no reference to
    the chapter at all *)
Lemma inst_V1_dyn_direct : forall i,
  Deriv (V1 1 THSTAR TH GAM i) (fun t => - ((v i - 1) * (v i - 1) * exp (-2 * t) / 2)).
Proof.
  intros i.
  apply (D_ext (fun t => (v i - 1) * (v i - 1) / 4 * exp (-2 * t))
               (fun t => (v i - 1) * (v i - 1) / 4 * (-2 * exp (-2 * t)))).
  - intros t. rewrite inst_V1_closed. field.
  - intros t. field.
  - apply D_scal. apply D_exp_lin.
Qed.

(** and they agree pointwise -- if [V1_dyn] had drifted (wrong sign, missing
    m^2, wrong Gamma) this equation would be false *)
Theorem inst_V1_dyn_agree : forall i t,
  - (eps 1 PHI Z TH i t * eps 1 PHI Z TH i t * msq 1 PHI t)
  = - ((v i - 1) * (v i - 1) * exp (-2 * t) / 2).
Proof.
  intros i t. rewrite inst_eps, inst_msq, <- (exp_sq t). field.
Qed.

(** ** Every headline theorem, instantiated on the model

    Each [Corollary] below discharges the *whole* hypothesis list of the
    theorem it names.  Together they show the bundle is consistent. *)

Corollary inst_e_dyn : forall i, (i < 2)%nat ->
  Deriv (e 1 PHI Z TH i)
        (fun t => - (eps 1 PHI Z TH i t * phiGphi 1 PHI GAM t)
                  + dot 1 (tht THSTAR TH i t) (PHID t)).
Proof.
  apply (e_dyn 1 PHI PHID THSTAR Z H_phi_ok H_param_ok 2 TH GAM H_law_ok).
Qed.

Corollary inst_ev_convex : forall t,
  ev 1 PHI Z 2 TH BETA t = Sum 2 (fun i => e 1 PHI Z TH i t * BETA i).
Proof. apply (ev_convex 1 PHI Z 2 TH BETA H_beta_sum_ok). Qed.

Corollary inst_theta_star_in_hull : forall t, 0 <= t -> forall j, (j < 1)%nat ->
  Sum 2 (fun i => TH i t j * ASTAR i) = THSTAR j.
Proof.
  apply (theta_star_in_hull 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok
                            ASTAR H_astar_sum_ok H_astar_init_ok).
Qed.

Corollary inst_ea_zero : forall t, 0 <= t -> ea 1 PHI Z 2 TH ASTAR t = 0.
Proof.
  apply (ea_zero 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok
                 ASTAR H_astar_sum_ok H_astar_init_ok).
Qed.

Corollary inst_E_alpha_star_exact : forall t, 0 <= t ->
  Sum 1 (fun i => Ev 1 PHI Z TH 1 t i * ASTAR i) = - eps 1 PHI Z TH 1 t.
Proof.
  apply (E_alpha_star_exact 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok
                            ASTAR H_astar_sum_ok H_astar_init_ok 1 H_NM_ok).
Qed.

(** *** the second level (SLA) -- never instantiated in SLA_Instance *)

Corollary inst_alpt_dyn : forall i, (i < 1)%nat ->
  Deriv (fun t => alpt ASTAR ALP t i)
        (fun t => - GN * (Ev 1 PHI Z TH 1 t i * Ealpt 1 PHI Z TH ASTAR 1 ALP t)
                  - GN * (Ev 1 PHI Z TH 1 t i *
                          (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t))).
Proof.
  apply (alpt_dyn 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN ALP H_sla_ok).
Qed.

Corollary inst_Vr_dyn :
  Deriv (Vr ASTAR 1 ALP)
        (fun t => - GN * (Ealpt 1 PHI Z TH ASTAR 1 ALP t * Ealpt 1 PHI Z TH ASTAR 1 ALP t)
                  - GN * (Ealpt 1 PHI Z TH ASTAR 1 ALP t *
                          (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t))).
Proof.
  apply (Vr_dyn 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN ALP H_sla_ok).
Qed.

Corollary inst_Vr_nonincreasing : forall a b, a <= b -> Vr ASTAR 1 ALP b <= Vr ASTAR 1 ALP a.
Proof.
  apply (Vr_nonincreasing 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN H_gn_ok
                          ALP H_sla_ok inst_ea_all).
Qed.

Corollary inst_Vb_dyn :
  Deriv (Vb ASTAR 1 GN ALP)
        (fun t => - ((Ealpt 1 PHI Z TH ASTAR 1 ALP t
                      + Sb ASTAR 1 ALP t * SE 1 PHI Z TH 1 t)
                     * (Ealpt 1 PHI Z TH ASTAR 1 ALP t
                        + ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t))).
Proof.
  apply (Vb_dyn 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN H_gn_ok ALP H_sla_ok).
Qed.

(** *** the forgetting-factor level (SLAFF) -- also never instantiated *)

Corollary inst_Mf_psd : forall x t, 0 <= t -> 0 <= MQ 1 MF x t.
Proof.
  apply (Mf_psd 1 PHI Z TH 1 SIG MF H_Mf0_ok H_Mf_ok).
Qed.

Corollary inst_qres_zero : forall t, 0 <= t -> forall i, (i < 1)%nat ->
  qres ASTAR 1 MF VF t i = 0.
Proof.
  apply (qres_zero 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok SIG H_sig_ok
                   MF VF H_Mf0_ok H_vf0_ok H_Mf_ok H_vf_ok inst_ea_all).
Qed.

Corollary inst_VrF_dyn :
  Deriv (VrF ASTAR 1 ALP)
        (fun t => GN * (- Sum 1 (fun i => alpFt ASTAR ALP t i
                                          * Sum 1 (fun j => MF t i j * alpFt ASTAR ALP t j))
                        - EalpFt 1 PHI Z TH ASTAR 1 ALP t * EalpFt 1 PHI Z TH ASTAR 1 ALP t
                        - EalpFt 1 PHI Z TH ASTAR 1 ALP t
                          * (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t)
                        - Sum 1 (fun i => alpFt ASTAR ALP t i * qres ASTAR 1 MF VF t i))).
Proof.
  apply (VrF_dyn 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN MF VF ALP H_slaff_ok).
Qed.

Corollary inst_Mf_integrating_factor : forall i j, (i < 1)%nat -> (j < 1)%nat ->
  Deriv (fun t => exp (SIG * t) * MF t i j)
        (fun t => exp (SIG * t) * (Ev 1 PHI Z TH 1 t i * Ev 1 PHI Z TH 1 t j)).
Proof.
  apply (Mf_integrating_factor 1 PHI Z TH 1 SIG MF H_Mf_ok).
Qed.


(** *** The remaining headline results, so that the list really is complete *)

Lemma inst_tha_all : forall t j, (j < 1)%nat -> tha THSTAR 2 TH ASTAR t j = 0.
Proof.
  intros t j Hj. unfold tha, tht. cbn [Sum].
  unfold TH, THSTAR, ASTAR. rewrite v0, v1. field.
Qed.

Corollary inst_V1_nonincreasing : forall i, (i < 2)%nat ->
  forall a b, a <= b -> V1 1 THSTAR TH GAM i b <= V1 1 THSTAR TH GAM i a.
Proof.
  apply (V1_nonincreasing 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok).
Qed.

Corollary inst_thtv_convex : forall t j,
  thtv THSTAR 2 TH BETA t j = Sum 2 (fun i => tht THSTAR TH i t j * BETA i).
Proof. apply (thtv_convex THSTAR 2 TH BETA H_beta_sum_ok). Qed.

Corollary inst_ev_dyn :
  Deriv (ev 1 PHI Z 2 TH BETA)
        (fun t => - (epsv 1 PHI Z 2 TH BETA t * phiGphi 1 PHI GAM t)
                  + dot 1 (thtv THSTAR 2 TH BETA t) (PHID t)).
Proof.
  apply (ev_dyn 1 PHI PHID THSTAR Z H_phi_ok H_param_ok 2 TH GAM H_law_ok
                BETA H_beta_sum_ok).
Qed.

Corollary inst_ea_dyn :
  Deriv (ea 1 PHI Z 2 TH ASTAR)
        (fun t => - (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t * phiGphi 1 PHI GAM t)).
Proof.
  apply (ea_dyn 1 PHI PHID THSTAR Z H_phi_ok H_param_ok 2 TH GAM H_law_ok
                ASTAR inst_tha_all).
Qed.

Corollary inst_E_alpha_star : forall t,
  Sum 1 (fun i => Ev 1 PHI Z TH 1 t i * ASTAR i)
  = - eps 1 PHI Z TH 1 t + ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t.
Proof.
  apply (E_alpha_star 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok).
Qed.

Corollary inst_vf_integrating_factor : forall i, (i < 1)%nat ->
  Deriv (fun t => exp (SIG * t) * VF t i)
        (fun t => exp (SIG * t) * (Ev 1 PHI Z TH 1 t i * eps 1 PHI Z TH 1 t)).
Proof. apply (vf_integrating_factor 1 PHI Z TH 1 SIG VF H_vf_ok). Qed.

Corollary inst_alpFt_dyn : forall i, (i < 1)%nat ->
  Deriv (fun t => alpFt ASTAR ALP t i)
        (fun t => GN * (- Sum 1 (fun j => MF t i j * alpFt ASTAR ALP t j)
                        - Ev 1 PHI Z TH 1 t i * EalpFt 1 PHI Z TH ASTAR 1 ALP t
                        - Ev 1 PHI Z TH 1 t i * (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t)
                        - qres ASTAR 1 MF VF t i)).
Proof.
  apply (alpFt_dyn 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN MF VF ALP H_slaff_ok).
Qed.

(** Note, visible in the argument list: [VrF_nonpos] does not consume the
    SLAFF law (4.67).  It says the *expression* is nonpositive; that this
    expression is VrF's derivative is the separate content of [VrF_dyn],
    which does consume (4.67).  Both are instantiated here, so the pair is
    meaningful on this model. *)
Corollary inst_VrF_nonpos : forall t, 0 <= t ->
  GN * (- Sum 1 (fun i => alpFt ASTAR ALP t i
                          * Sum 1 (fun j => MF t i j * alpFt ASTAR ALP t j))
        - EalpFt 1 PHI Z TH ASTAR 1 ALP t * EalpFt 1 PHI Z TH ASTAR 1 ALP t
        - EalpFt 1 PHI Z TH ASTAR 1 ALP t * (ea 1 PHI Z 2 TH ASTAR t / msq 1 PHI t)
        - Sum 1 (fun i => alpFt ASTAR ALP t i * qres ASTAR 1 MF VF t i)) <= 0.
Proof.
  apply (VrF_nonpos 1 PHI Z 2 TH ASTAR H_astar_sum_ok 1 H_NM_ok GN H_gn_ok
                    SIG H_sig_ok MF VF H_Mf0_ok H_vf0_ok H_Mf_ok H_vf_ok
                    ALP inst_ea_all).
Qed.

(** ** Cross-check of the SLAFF residual against a direct computation

    [qres_zero] concludes that M_f alpha* + v_f vanishes.  Here is the same
    fact obtained by unfolding the closed forms -- and, unlike the theorem,
    for every t, not only t >= 0. *)

Lemma inst_qres_direct : forall t i, (i < 1)%nat -> qres ASTAR 1 MF VF t i = 0.
Proof.
  intros t i Hi. unfold qres. cbn [Sum].
  unfold MF, VF, ASTAR. destruct i as [|i]; [ rewrite v0; field | lia ].
Qed.

(** ** The (4.69) finding is witnessed too, not merely stated

    (4.69) writes the last term of Vdot as  -N alphatilde^T M_f alpha*_f,
    where the correct residual is  M_f alpha*_f + v_f  ([qres]).  Saying "it
    omits v_f" only bites if v_f is not identically zero and if the omitted
    term actually changes the value.  Both are false in the OLD N = 3
    instance, where v_f vanished identically -- which is exactly why the
    amendment rebuilt it at N = d+1 = 2.  Here is the check, on the current
    instance, at t = 1. *)

Lemma exp_m2_lt_exp_m1 : exp (-2 * 1) < exp (-1 * 1).
Proof. apply exp_increasing. lra. Qed.

(** v_f is not identically zero ... *)
Theorem inst_vf_nonzero : VF 1 0 <> 0.
Proof.
  unfold VF. rewrite v0. pose proof exp_m2_lt_exp_m1. lra.
Qed.

(** ... and neither is the term (4.69) keeps, M_f alpha*_f ... *)
Lemma inst_MFastar : Sum 1 (fun j => MF 1 0 j * ASTAR j) = - VF 1 0.
Proof.
  replace (Sum 1 (fun j => MF 1 0 j * ASTAR j))
     with (Sum 1 (fun j => MF 1 0 j * ALP 1 j))
     by (apply Sum_ext; intros; unfold ALP; reflexivity).
  apply (inst_MFalp 0 1).
Qed.

Theorem inst_Mf_astar_nonzero : Sum 1 (fun j => MF 1 0 j * ASTAR j) <> 0.
Proof.
  rewrite inst_MFastar. pose proof inst_vf_nonzero. lra.
Qed.

(** ... yet their sum, the residual the development uses, is exactly zero.
    So the two terms cancel: dropping v_f does not drop a negligible
    quantity, it drops the half of a cancelling pair. *)
Theorem inst_residual_cancels :
  Sum 1 (fun j => MF 1 0 j * ASTAR j) <> 0
  /\ VF 1 0 <> 0
  /\ Sum 1 (fun j => MF 1 0 j * ASTAR j) + VF 1 0 = 0.
Proof.
  repeat split; [ exact inst_Mf_astar_nonzero | exact inst_vf_nonzero | ].
  rewrite inst_MFastar. ring.
Qed.
