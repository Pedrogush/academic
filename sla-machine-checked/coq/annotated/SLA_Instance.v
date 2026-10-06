(** * SLA_Instance.v — ANNOTATED COPY

    Identical Coq code to ../SLA_Instance.v, with a block comment before every
    item explaining the syntax.

    ====================================================================
    WHY THIS FILE EXISTS
    ====================================================================

    SLA_Chapter4.v proves everything under a long list of hypotheses.  If
    those hypotheses were mutually contradictory, every theorem would be
    provable and none would mean anything.  (In Coq, from a contradiction
    anything follows, and nothing warns you.)

    This file rules that out by exhibiting CONCRETE signals for which every
    hypothesis holds, and then feeding them to the main theorem.

    THE INSTANCE.  The simplest non-degenerate one whose adaptive ODEs have
    closed-form solutions:

        d = 1,  N = 2 models (so M = 1),  phi(t) = 1,  theta*_p = 1,
        z(t) = 1,  Gamma = 2.

    Then m^2 = 1 + phi.phi = 2, and the gradient law (4.19) reads

        d/dt thetahat_i = -(2 * eps_i * 1) = -(thetahat_i - 1)

    whose solution is  thetahat_i(t) = 1 + (v_i - 1) e^{-t}  with initial
    values v = (0, 2).  The convex coefficients alpha* = (1/2, 1/2)
    reproduce theta*_p = 1 from those, since (1/2)*0 + (1/2)*2 = 1.

    ====================================================================
    AMENDMENT: WHY N IS 2 AND NOT 3
    ====================================================================

    An earlier version of this file used N = 3 models with v = (0, 2, 1) at
    d = 1.  That satisfied the dissertation's design rule as written
    (N >= 2n+1) but violates the AMENDED rule N = 2n+1 = d+1, and it was
    degenerate in a way that matters:

      * three points on a line admit a whole one-parameter family of convex
        coefficients — alpha* = (s, s, 1-2s) works for every s in [0, 1/2],
        so alpha* was not a well-defined identification target;
      * correspondingly the second-level regressor was
        E_f(t) = (e^{-t}/2)(-1, 1), which is RANK 1 in R^2 at every t.  Its
        null direction (1,1) is exactly the direction of the alpha* family:
        the non-uniqueness and the rank deficiency are the same fact.

    At N = d+1 = 2 the coefficients are unique — proved below as
    inst_astar_unique — and E_f is a nonzero SCALAR, so "nonzero" really is
    full rank.  See ../../NOTE_convex_uniqueness.md.

    One visible consequence of the change: the last model no longer sits
    exactly on theta*_p, so eps_M is no longer identically zero and v_f is
    no longer identically zero either.  Both now have genuine closed forms.

    For the second level we take alpha_f identically equal to alpha*, which
    satisfies both (4.52) and (4.67) precisely BECAUSE e_alpha vanishes —
    itself an instance of the convex-hull invariance theorem.  With sigma = 1
    the forgetting-factor equations (4.66) also solve in closed form:

        M_f(t) = c_ij (e^{-t} - e^{-2t}),   v_f(t) = c_i (e^{-t} - e^{-2t}).

    The instance is not degenerate: the two model estimates are distinct and
    time varying (inst_models_are_distinct), and E_f is nowhere zero
    (inst_E_nonzero).

    ====================================================================
    HOW A SECTION-BASED THEOREM IS INSTANTIATED
    ====================================================================

    Once Section Chapter4 is closed, hull_invariance has become

        forall d phi thstar z, (forall t, z t = dot d thstar (phi t)) ->
        forall N th gam, (forall j, j < d -> 0 < gam j) ->
        (forall i j, i < N -> j < d -> Deriv ...) ->
        forall astar, Sum N astar = 1 ->
        (forall j, j < d -> Sum N (fun i => th i 0 j * astar i) = thstar j) ->
        forall t, 0 <= t -> forall j, j < d -> tha thstar N th astar t j = 0

    so applying it is a matter of supplying, in order, the objects and then
    the PROOFS of the hypotheses — which is what the lemmas below are for.
    See inst_hull_invariance at the end.

    Coq abstracts a theorem only over the section variables it actually USED,
    so phid, H_phi, H_N_exact and the beta family do not appear in that list.

    ====================================================================
    NEW SYNTAX APPEARING IN THIS FILE
    ====================================================================

    match i with O => ... | _ => ... end
                          pattern match on a natural number: here the cases
                          are 0 and everything else.  '_' is a wildcard.
    reflexivity           closes a goal whose two sides COMPUTE to the same
                          thing; that is why 'v 1 = 2' is proved by
                          reflexivity alone.
    exfalso               replaces the current goal by False, useful when the
                          hypotheses are already contradictory.
    exp                   the real exponential from the standard library.
    exp_0 : exp 0 = 1
    exp_pos : 0 < exp x
    exp_plus : exp (x + y) = exp x * exp y
*)

Require Import Reals Lra Lia.
Require Import SLA.SLA_Prelim.
Require Import SLA.SLA_Chapter4.
Local Open Scope R_scope.

(** ** The instance *)

(* ---------------------------------------------------------------------
   The initial values of the two models, as a function of the index.
   'match ... end' is the case analysis; the branches are i = 0 and any
   larger i.  Indices at or above N are never looked at by the theorems, so
   the catch-all branch is free to return anything — here 2.
   --------------------------------------------------------------------- *)
Definition v (i : nat) : R := match i with O => 0 | _ => 2 end.

(* ---------------------------------------------------------------------
   The concrete objects.  Every one of them has exactly the type that the
   corresponding Variable of SLA_Chapter4.v had, which is what makes the
   instantiation at the end typecheck.

   Note 'fun _ _ => 1' for PHI: a function of two arguments that ignores
   both, i.e. the constant regressor phi(t) = 1 in dimension one.

   TH ignores its component index too (there is only one component):
       TH i t _ = 1 + (v i - 1) exp(-t).
   '-1 * t' rather than '- t' because the differentiation rule D_exp_lin is
   stated for exp (a * t), so the exponent must literally have that shape.

   ASTAR is now the CONSTANT 1/2 rather than a three-branch match, because
   with two models both weights are 1/2.

   MF's coefficient c_ij = (v_i - 2)(v_j - 2)/4 comes from
       E_f(t)_i = (v_i - 2) e^{-t} / 2   (see inst_Ev below),
   so that E_i E_j = c_ij e^{-2t}, and M_f(t) = c_ij (e^{-t} - e^{-2t})
   solves Mdot = -M + E_i E_j with M(0) = 0.  The '- 2' replaces the old
   '- 1' because the last model now starts at 2, not at theta*_p = 1.

   VF is no longer the zero function: with eps_M nonzero, v_f solves
   vdot = -v + E_i eps_M, giving c_i (e^{-t} - e^{-2t}) with c_i = (v_i-2)/4.
   --------------------------------------------------------------------- *)
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

(* ---------------------------------------------------------------------
   Two computation facts, each closed by 'reflexivity' alone.

   This works because v is defined by pattern matching on a CONSTRUCTOR,
   and 0 and 1 are literal constructors, so 'v 1' reduces to 2 by pure
   computation and the two sides of the equation are the same term.

   They are stated as named lemmas rather than left to 'simpl' inside larger
   proofs so that later rewrites are explicit and robust.  (ASTAR needs no
   such lemmas any more: being a constant function, 'unfold ASTAR' is
   enough.)
   --------------------------------------------------------------------- *)
Lemma v0 : v 0 = 0. Proof. reflexivity. Qed.
Lemma v1 : v 1 = 2. Proof. reflexivity. Qed.

(** ** Closed forms of the derived signals *)

(* m^2 = 1 + phi.phi = 1 + 1 = 2.
   'unfold' replaces the named definitions by their bodies; 'cbn [Sum]'
   evaluates the Sum recursion only (leaving everything else alone); 'ring'
   finishes the polynomial identity.                                       *)
Lemma inst_msq : forall t, msq 1 PHI t = 2.
Proof. intros t. unfold msq, dot, PHI. cbn [Sum]. ring. Qed.

(* The identification error (4.11): e_i = thetahat_i . phi - z
                                       = (1 + (v_i-1)e^{-t}) - 1.          *)
Lemma inst_e : forall i t, e 1 PHI Z TH i t = (v i - 1) * exp (-1 * t).
Proof. intros i t. unfold e, zh, dot, PHI, Z, TH. cbn [Sum]. ring. Qed.

(* The normalised error (4.13): eps_i = e_i / m^2 = e_i / 2.
   'rewrite A, B' rewrites with A and then with B.                         *)
Lemma inst_eps : forall i t, eps 1 PHI Z TH i t = (v i - 1) * exp (-1 * t) / 2.
Proof. intros i t. unfold eps. rewrite inst_e, inst_msq. reflexivity. Qed.

(* ---------------------------------------------------------------------
   The last model has index M = 1, and it starts at v_1 = 2, so its error
   does NOT vanish: eps_1(t) = e^{-t}/2.

   This is the substantive difference from the old N = 3 instance, where
   the last model was initialised exactly at theta*_p = 1 and so had
   eps_M identically 0.  That made several of the lemmas below collapse to
   'ring'; now they carry real content.

   'field' rather than 'ring' because of the division by 2.
   --------------------------------------------------------------------- *)
Lemma inst_eps1 : forall t, eps 1 PHI Z TH 1 t = exp (-1 * t) / 2.
Proof. intros t. rewrite inst_eps, v1. field. Qed.

(* The second-level regressor (4.50): E_i = eps_i - eps_M, here
       (v_i - 1)e^{-t}/2 - e^{-t}/2 = (v_i - 2)e^{-t}/2.                   *)
Lemma inst_Ev : forall i t, Ev 1 PHI Z TH 1 t i = (v i - 2) * exp (-1 * t) / 2.
Proof. intros i t. unfold Ev. rewrite (inst_eps i t), inst_eps1. field. Qed.

(* e^{-t} * e^{-t} = e^{-2t}.  Needed because the M_f and v_f proofs produce
   products of exponentials that must be recognised as the single
   exponential appearing in the closed form.
   'f_equal' reduces 'exp X = exp Y' to 'X = Y'.                           *)
Lemma exp_sq : forall t, exp (-1 * t) * exp (-1 * t) = exp (-2 * t).
Proof. intros t. rewrite <- exp_plus. f_equal. ring. Qed.

(** ** Every hypothesis of SLA_Chapter4 holds for this instance *)

(* phi is constant, so its derivative is the zero function.                *)
Lemma H_phi_ok : forall j, (j < 1)%nat -> Deriv (fun t => PHI t j) (fun t => PHID t j).
Proof. intros j Hj. unfold PHI, PHID. apply D_const. Qed.

(* (4.8): z = theta*_p . phi, here 1 = 1 * 1.                              *)
Lemma H_param_ok : forall t, Z t = dot 1 THSTAR (PHI t).           (* (4.8) *)
Proof. intros t. unfold Z, dot, THSTAR, PHI. cbn [Sum]. ring. Qed.

(* ---------------------------------------------------------------------
   The AMENDED design rule N = 2n+1 = d+1.  With d = 1 that is N = 2, and
   'S 1' is the successor of 1, i.e. 2, so the statement is 2 = 2 and
   'reflexivity' closes it by computation.

   The old file proved '(2 * 1 / 2 + 1 <= 3)%nat' instead — the inequality
   form, which N = 3 also satisfied.  See ../../NOTE_convex_uniqueness.md.
   --------------------------------------------------------------------- *)
Lemma H_N_exact_ok : (2 = S 1)%nat.
Proof. reflexivity. Qed.

(* (4.17): the adaptation gain is positive.                                *)
Lemma H_gam_ok : forall j, (j < 1)%nat -> 0 < GAM j.               (* (4.17) *)
Proof. intros j Hj. unfold GAM. lra. Qed.

(* ---------------------------------------------------------------------
   (4.19)/(4.29): each estimate obeys the normalised gradient law.

   This is the D_ext pattern.  D_ext f f' g g' takes
     (1) forall t, f t = g t          — the functions agree,
     (2) forall t, f' t = g' t        — the derivatives agree,
     (3) Deriv f f'                   — the EASY derivative,
   and returns Deriv g g'.  So we differentiate the convenient closed form
   and then argue that it equals the form the hypothesis demands.

   Bullet 1 is 'reflexivity' after unfolding TH.
   Bullet 2 is the real content: -(2 * eps_i * 1) = (v_i - 1)(-1 e^{-t}).
   Bullet 3 assembles the derivative from D_const, D_scal and D_exp_lin.
   --------------------------------------------------------------------- *)
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

(* (4.31): the beta weights of the "virtual model" are convex.  With two
   models each is 1/2.                                                     *)
Lemma H_beta_sum_ok : Sum 2 BETA = 1.                              (* (4.31) *)
Proof. unfold BETA. cbn [Sum]. lra. Qed.

Lemma H_beta_rng_ok : forall i, (i < 2)%nat -> 0 <= BETA i <= 1.   (* (4.31) *)
Proof. intros i Hi. unfold BETA. lra. Qed.

(* (4.41): alpha* sums to one and lies in [0,1].  Both are now immediate,
   ASTAR being the constant 1/2.                                           *)
Lemma H_astar_sum_ok : Sum 2 ASTAR = 1.                            (* (4.41) *)
Proof. unfold ASTAR. cbn [Sum]. lra. Qed.

Lemma H_astar_rng_ok : forall i, (i < 2)%nat -> 0 <= ASTAR i <= 1. (* (4.41) *)
Proof. intros i Hi. unfold ASTAR. lra. Qed.

(* ---------------------------------------------------------------------
   (4.41) at t = 0: theta*_p = 1 is the convex combination
   (1/2)*0 + (1/2)*2 of the initial estimates.

   'replace (-1 * 0) with 0 by ring' rewrites the exponent so that 'exp_0'
   applies; without it the term is 'exp (-1 * 0)', which is not literally
   'exp 0'.
   --------------------------------------------------------------------- *)
Lemma H_astar_init_ok : forall j, (j < 1)%nat ->
  Sum 2 (fun i => TH i 0 j * ASTAR i) = THSTAR j.
Proof.
  intros j Hj. unfold THSTAR. cbn [Sum]. unfold TH, ASTAR.
  replace (-1 * 0) with 0 by ring. rewrite exp_0.
  rewrite v0, v1. field.
Qed.

(* ---------------------------------------------------------------------
   UNIQUENESS OF alpha* — exactly what N = d+1 buys, and the reason this
   file was changed.

   Read the statement as: if ANY vector a sums to one and reproduces
   theta*_p from the same initial estimates, then a IS alpha*.

   With the old N = 3 instance this was FALSE: (1/2,1/2,0), (0,0,1) and
   (1/3,1/3,1/3) all worked.  See SLA_AppendixA.more_vertices_not_unique
   for that counterexample stated in Coq.

   Proof reading.  'pose proof (Hrep 0%nat H0) as H' instantiates the
   representation hypothesis at coordinate 0, giving a linear equation in
   a 0 and a 1; 'cbn [Sum] in Hsum, H' evaluates both sums; after rewriting
   the exponential at t = 0 away, 'lra' solves the resulting 2x2 linear
   system.  The third branch of the destruct is impossible because Hi says
   i < 2, so 'exfalso; lia' discharges it from the arithmetic hypotheses.
   --------------------------------------------------------------------- *)
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

(* N = S M with M = 1, i.e. 2 = 2.                                         *)
Lemma H_NM_ok : (2 = S 1)%nat.
Proof. reflexivity. Qed.

(* The second-level gain is positive.                                      *)
Lemma H_gn_ok : 0 < GN.
Proof. unfold GN. lra. Qed.

(** *** Second level: alpha_f == alpha* is a solution of (4.52) *)

(* ---------------------------------------------------------------------
   E_f . alpha_f, with alpha_f = alpha*.  Only the single index 0 survives
   (M = 1), so the sum is E_0 * (1/2) = -e^{-t}/2.

   In the old N = 3 instance this was 0, because eps_M was 0 there.  Now it
   is nonzero, and what makes the adaptive law still hold is the identity
       E_f . alpha* + eps_M = 0,
   which is the instance-level shadow of the general theorem E_alpha_star
   (4.49)/(4.51): E_f alpha*_f = -eps_N + e_alpha/m^2, with e_alpha = 0.
   --------------------------------------------------------------------- *)
Lemma inst_Ealp : forall t, Ealp 1 PHI Z TH 1 ALP t = - (exp (-1 * t) / 2).
Proof.
  intros t. unfold Ealp. cbn [Sum].
  rewrite (inst_Ev 0 t). unfold ALP, ASTAR. rewrite v0. field.
Qed.

(* ---------------------------------------------------------------------
   (4.52): the constant alpha_f = alpha* really does solve the second-level
   adaptive law.  Its derivative is 0, so the whole content is that the
   right-hand side vanishes — which it does because
       -GN * E_i * (Ealp) - GN * E_i * (eps_M)
     = -GN * E_i * (Ealp + eps_M) = -GN * E_i * 0 = 0.
   'ring' sees this once both rewrites have been performed; GN is left as an
   opaque atom, which is fine since it cancels symbolically.
   --------------------------------------------------------------------- *)
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

(* M_f(0) = c (e^0 - e^0) = 0.                                             *)
Lemma H_Mf0_ok : forall i j, MF 0 i j = 0.
Proof.
  intros i j. unfold MF.
  replace (-1 * 0) with 0 by ring. replace (-2 * 0) with 0 by ring.
  rewrite exp_0. field.
Qed.

(* v_f(0) = 0, for the same reason.  In the old instance VF was literally
   the zero function and this was 'reflexivity'; now it needs the same
   exponential computation as M_f.                                         *)
Lemma H_vf0_ok : forall i, VF 0 i = 0.
Proof.
  intros i. unfold VF.
  replace (-1 * 0) with 0 by ring. replace (-2 * 0) with 0 by ring.
  rewrite exp_0. field.
Qed.

(* ---------------------------------------------------------------------
   (4.66) for M_f: Mdot = -sigma M + E_i E_j.

   Same D_ext pattern as H_law_ok.  The step that makes bullet 2 work is
   'rewrite <- (exp_sq t)', which turns every e^{-2t} back into
   e^{-t} * e^{-t} so that a single 'field' call can verify the identity
   in one variable.
   --------------------------------------------------------------------- *)
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

(* ---------------------------------------------------------------------
   (4.66) for v_f: vdot = -sigma v + E_i eps_M.

   In the old instance this was trivial (both sides zero).  Here it is a
   genuine linear ODE with the closed form c_i (e^{-t} - e^{-2t}),
   c_i = (v_i - 2)/4, and the proof mirrors H_Mf_ok exactly.
   --------------------------------------------------------------------- *)
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

(* Same quantity as inst_Ealp but for the SLAFF estimate alpha_f, which in
   this instance is the same constant vector.                              *)
Lemma inst_EalpF : forall t, EalpF 1 PHI Z TH 1 ALP t = - (exp (-1 * t) / 2).
Proof.
  intros t. unfold EalpF. cbn [Sum].
  rewrite (inst_Ev 0 t). unfold ALP, ASTAR. rewrite v0. field.
Qed.

(* ---------------------------------------------------------------------
   The residual M_f alpha* + v_f vanishes identically.

   This is exactly the quantity that (4.69) of the dissertation omits the
   v_f half of — see the qres discussion in SLA_Chapter4.v.  Here the two
   halves cancel term by term: the sum equals -VF, so sum + VF = 0.

   Note this is now a real cancellation.  In the old N = 3 instance VF was
   identically zero and the sum was zero on its own, so the identity said
   nothing about how the two terms interact.
   --------------------------------------------------------------------- *)
Lemma inst_MFalp : forall i t, Sum 1 (fun j => MF t i j * ALP t j) = - VF t i.
Proof.
  intros i t. cbn [Sum]. unfold MF, ALP, ASTAR, VF. rewrite v0. field.
Qed.

(* ---------------------------------------------------------------------
   (4.67): alpha_f = alpha* also solves the SLAFF law.  Again the derivative
   is zero and the content is that the bracket vanishes:
       -(-VF_i) - E_i * EalpF - VF_i - E_i * eps_M
     = VF_i - VF_i - E_i * (EalpF + eps_M)  =  0.
   --------------------------------------------------------------------- *)
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

(* ---------------------------------------------------------------------
   Supplying the objects and the hypothesis proofs, in the order the
   generalised statement expects.  No 'intros' is needed: 'apply' unifies
   the conclusion directly with the goal.

   Compare the argument list with the generalised type quoted in the header
   of this file: 1 for d, PHI, THSTAR, Z, then the proof of (4.8), then 2
   for N, and so on.
   --------------------------------------------------------------------- *)
Corollary inst_hull_invariance : forall t, 0 <= t -> forall j, (j < 1)%nat ->
  tha THSTAR 2 TH ASTAR t j = 0.
Proof.
  apply (hull_invariance 1 PHI THSTAR Z H_param_ok 2 TH GAM H_gam_ok H_law_ok
                         ASTAR H_astar_sum_ok H_astar_init_ok).
Qed.

(** Independent check by direct computation: the same identity obtained
    without the theorem.  Agreement confirms the instance really is a model of
    the hypotheses rather than an artefact of the encoding. *)

(* (1 - e^{-t})/2 + (1 + e^{-t})/2 = 1, for every t.                       *)
Lemma inst_hull_direct : forall t, Sum 2 (fun i => TH i t 0 * ASTAR i) = 1.
Proof.
  intros t. cbn [Sum]. unfold TH, ASTAR. rewrite v0, v1. field.
Qed.

(** The estimates are genuinely distinct: model 0 never equals theta*_p. *)

(* TH 0 t 0 = 1 - e^{-t}, and e^{-t} > 0 for every real t, so it is never 1.
   'pose proof (exp_pos (-1 * t))' adds that positivity fact to the context
   so that 'lra' can use it.                                               *)
Lemma inst_models_are_distinct : forall t, TH 0 t 0 <> THSTAR 0.
Proof.
  intros t. unfold TH, THSTAR. rewrite v0.
  pose proof (exp_pos (-1 * t)). lra.
Qed.

(* ---------------------------------------------------------------------
   ... and the second-level regressor E_f is nowhere zero: E_0(t) = -e^{-t}.

   At N = d+1 = 2 the regressor is a SCALAR, so "nonzero" here really does
   mean full rank.  That was not true of the old N = 3 instance, where E_f
   was a nonzero but rank-deficient vector in R^2 — nonzero at every t, yet
   confined to the line spanned by (-1,1), leaving the second-level
   regression under-determined.  The lemma name meant less there than its
   wording suggested.

   Caveat worth keeping in view: full rank pointwise is still weaker than
   PERSISTENCY OF EXCITATION, which is what convergence of alpha_f would
   need.  Here E_f(t) = -e^{-t} decays, so its square has a finite integral
   and it is not PE.  Nothing in this development claims otherwise; see the
   "not formalised" section of ../README.md.
   --------------------------------------------------------------------- *)
Lemma inst_E_nonzero : forall t, Ev 1 PHI Z TH 1 t 0 <> 0.
Proof.
  intros t. rewrite inst_Ev, v0.
  pose proof (exp_pos (-1 * t)). lra.
Qed.
