(** * SLA_Chapter4.v — ANNOTATED COPY

    Identical Coq code to ../SLA_Chapter4.v, with a block comment before every
    item explaining the syntax.  Read ./SLA_Prelim.v first: it introduces
    Sum, dot, Deriv and above all D_ext, which is the idiom used by every
    derivative proof below.

    ====================================================================
    THE THREE THINGS YOU NEED BEFORE STARTING
    ====================================================================

    (1) SECTIONS AND HYPOTHESES.  This whole file is one

            Section Chapter4.  ...  End Chapter4.

        Inside a Section you may write

            Variable   x : T.        -- an unknown object
            Hypothesis H : P.        -- an unknown proof of P

        Everything proved inside may use them freely.  When End is reached,
        Coq automatically closes every theorem over the variables and
        hypotheses IT ACTUALLY USED.  So

            Theorem hull_invariance : forall t, 0 <= t -> ... .

        becomes, outside the section,

            hull_invariance : forall d phi thstar z,
                                (forall t, z t = dot d thstar (phi t)) ->
                                forall N th gam, ... -> ...

        This is exactly the modelling contract: the theorem holds for ANY
        plant, regressor and adaptive law satisfying the listed hypotheses.
        (Because Coq only abstracts over what was used, the argument order is
        determined by declaration order in the file.  SLA_Instance.v shows how
        to feed such a theorem concrete arguments.)

    (2) VECTORS ARE FUNCTIONS.  There is no vector type.  A vector in R^d is
        a function nat -> R and the dimension d travels separately.  Because
        application is left-associative juxtaposition,

            th : nat -> R -> nat -> R        (* model index, time, component *)
            th i        : R -> nat -> R      (* the i-th model as a trajectory *)
            th i t      : nat -> R           (* the VECTOR theta-hat_i(t)      *)
            th i t j    : R                  (* its j-th component             *)

        You will see  dot d (th i t) (phi t)  everywhere: that is the inner
        product of the two vectors theta-hat_i(t) and phi(t).

    (3) EVERY DERIVATIVE PROOF HAS THE SAME SHAPE.  Because Deriv f f'
        mentions f' as a syntactic object, and the differentiation rules
        deliver derivatives in a fixed shape, we always go through D_ext:

            apply (D_ext <convenient f> <convenient f'>).
            - ...   (* subgoal 1: forall t, f t = g t     — usually reflexivity *)
            - ...   (* subgoal 2: forall t, f' t = g' t   — THE ALGEBRA         *)
            - ...   (* subgoal 3: Deriv f f'              — the calculus        *)

        Subgoal 2 is where the mathematics of the dissertation lives.  When
        reading a proof below, look at the second bullet first.

    ====================================================================
    THE DISSERTATION
    ====================================================================

    Pedro Yochinori Gushiken, Adaptacao de Segundo Nivel como Tecnica de
    Estimacao de Parametros e sua Aplicacao ao Controle Adaptativo por Modelo
    de Referencia, MSc dissertation, UFRN, 2018 — Chapter 4.

    Equations 4.1-4.7 and 4.9 only fix NOTATION for the filters generating the
    regressor phi.  Their whole content downstream is that phi is
    differentiable and z = theta*^T phi, which is hypothesis H_param (4.8).

    Two discrepancies are PROVED, not assumed: see Vb_dyn and its two
    corollaries near the end of the SLA_conventional section, and the comment
    above VrF_dyn. *)

Require Import Reals Lra Lia.

(* 'SLA.SLA_Prelim' is the logical name of the prelim file; the mapping from
   logical names to directories is set by the -Q flag (see _CoqProject).     *)
Require Import SLA.SLA_Prelim.
Local Open Scope R_scope.

Section Chapter4.

(** ** 4.1–4.9  Plant and linear parametrization *)

(* ---------------------------------------------------------------------
   THE UNKNOWNS OF THE PROBLEM.

   d      : the dimension 2n of theta*_p = [a_1..a_n b_1..b_n]^T.
   phi    : the regressor.  phi t is the VECTOR phi(t); phi t j its j-th
            component.  Note the argument order (time first, index second) —
            it is what makes 'phi t' a usable vector.
   phid   : the time derivative of phi, supplied as a separate object because
            Coq has no derivative operator that computes.
   thstar : theta*_p.  A plain nat -> R with no time argument: that IS the
            statement that the plant is time invariant, and it is why
            D_const closes half of the goals below.
   z      : the filtered output z(t) of equation 4.9.
   --------------------------------------------------------------------- *)
Variable d : nat.
Variable phi : R -> nat -> R.          (* the regressor phi(t) in R^d *)
Variable phid : R -> nat -> R.         (* its time derivative           *)
Variable thstar : nat -> R.            (* theta*_p, the true parameters *)
Variable z : R -> R.                   (* the filtered output z(t)      *)

(* phi is differentiable componentwise, with derivative phid.  '(j < d)%nat'
   restricts the claim to the d components that actually exist.            *)
Hypothesis H_phi : forall j, (j < d)%nat -> Deriv (fun t => phi t j) (fun t => phid t j).

(* ---------------------------------------------------------------------
   (4.8): the plant parametrization z(s) = theta*_p^T phi.

   This single hypothesis carries all of 4.1-4.7 and 4.9.  Everything those
   equations do — factor by Lambda(s), collect the filtered signals, define
   phi_1 and phi_2 — exists only to make this identity true.
   --------------------------------------------------------------------- *)
Hypothesis H_param : forall t, z t = dot d thstar (phi t).

(* ---------------------------------------------------------------------
   (4.12): m^2 = 1 + n_s^2 with n_s^2 = phi^T phi.

   'msq' is written as one word because Coq identifiers cannot contain
   superscripts; read it as m squared.  We never need m itself, only m^2,
   which is why there is no square root anywhere.
   --------------------------------------------------------------------- *)
Definition msq (t : R) : R := 1 + dot d (phi t) (phi t).

(* m^2 > 0 always.  This is what licenses every division by msq below.

   PROOF.  unfold msq turns the goal into 0 < 1 + dot d (phi t) (phi t);
   'pose proof (dot_nonneg d (phi t))' adds the fact 0 <= dot d (phi t)(phi t)
   to the context; 'lra' concludes.                                        *)
Lemma msq_pos : forall t, 0 < msq t.
Proof. intros t. unfold msq. pose proof (dot_nonneg d (phi t)). lra. Qed.

(* The same fact in the form the 'field' tactic wants: a nonzero denominator.
   '<>' is 'not equal'.                                                    *)
Lemma msq_neq0 : forall t, msq t <> 0.
Proof. intros t. pose proof (msq_pos t). lra. Qed.

(** ** 4.10–4.15 and 4.24–4.28  The N first-level regression models *)

(* ---------------------------------------------------------------------
   N is the number of models.  Indices run 0..N-1 here, so what the text
   calls model N is index N-1 (later given the name M).

   H_N_exact records the design rule.  'S d' is the successor of d, i.e.
   d + 1; with d = 2n this says N = 2n + 1.  The hypothesis is stated for the
   record and is DELIBERATELY NEVER USED: none of the identities of Chapter 4
   depend on it.  Its actual role — guaranteeing that alpha* exists at all,
   and is unique — is the subject of Appendix A (see SLA_AppendixA.v).

   AMENDED.  This used to read '(2 * d / 2 + 1 <= N)%nat', i.e. N >= d+1,
   matching the dissertation's N >= 2n+1 (pp. 23, 28, 60, 64, 72, 83).  That
   inequality gives EXISTENCE of the convex representation but not
   UNIQUENESS: N unknowns against d+1 equations leaves a solution family of
   dimension N-(d+1).  Because the second level identifies alpha*_f, that
   target has to be a single point, so the rule is tightened to equality.
   See ../../NOTE_convex_uniqueness.md and SLA_AppendixA.design_rule_exact.
   --------------------------------------------------------------------- *)
Variable N : nat.
Hypothesis H_N_exact : N = S d.                  (* N = 2n+1 with d = 2n *)

(* th i t j = the j-th component of theta-hat_{i,f}(t). *)
Variable th : nat -> R -> nat -> R.    (* thetahat_{i,f}(t) *)

(* ---------------------------------------------------------------------
   The four basic signals.  These are Definitions, i.e. pure abbreviations:
   anywhere you see 'eps i t' you may mentally substitute its body, and the
   tactic 'unfold eps' does exactly that.
   --------------------------------------------------------------------- *)
Definition zh  (i : nat) (t : R) : R := dot d (th i t) (phi t).      (* (4.10)/(4.24) *)
Definition e   (i : nat) (t : R) : R := zh i t - z t.                (* (4.11)/(4.25) *)
Definition tht (i : nat) (t : R) (j : nat) : R := th i t j - thstar j. (* (4.14)/(4.26) *)
Definition eps (i : nat) (t : R) : R := e i t / msq t.               (* (4.13)/(4.27) *)

(* ---------------------------------------------------------------------
   (4.15)/(4.28): e_{i,f} = theta-tilde_{i,f}^T phi.

   Note 'tht i t' on the right is the partial application, i.e. the vector
   theta-tilde_i(t).

   PROOF, step by step.
     intros i t             fix i and t.
     unfold e, zh, tht      goal becomes
                              dot d (th i t) (phi t) - z t
                            = dot d (fun j => th i t j - thstar j) (phi t)
     rewrite H_param        replaces z t by dot d thstar (phi t).  Rewriting
                            goes LEFT TO RIGHT along the equation, and
                            H_param's left-hand side is z t.
     rewrite dot_minus_l    the prelim lemma
                              dot d (fun j => u j - v j) w = dot d u w - dot d v w
                            fires on the right-hand side, splitting it.
     reflexivity            both sides are now the same term.
   --------------------------------------------------------------------- *)
Theorem e_eq_dot_tht : forall i t, e i t = dot d (tht i t) (phi t).
Proof.
  intros i t. unfold e, zh, tht. rewrite H_param. rewrite dot_minus_l. reflexivity.
Qed.

(* The normalised version of the same identity: divide through by m^2.
   Since eps is DEFINED as e / msq, unfolding it and rewriting with the
   previous theorem is all there is to do.                                 *)
Theorem eps_eq_dot_tht : forall i t, eps i t = dot d (tht i t) (phi t) / msq t.
Proof. intros i t. unfold eps. rewrite e_eq_dot_tht. reflexivity. Qed.

(* ---------------------------------------------------------------------
   The reverse reading, e = eps * m^2, needed whenever a proof arrives at
   -eps * e and wants -eps^2 m^2 (that is equation 4.23).

   'field' is 'ring' extended with division.  It normalises both sides as
   rational functions and then requires you to prove that each denominator it
   used is nonzero — hence the trailing 'apply msq_neq0'.

   Using 'ring' here would fail with 'not a valid ring equation', because
   ring has no notion of division.  That distinction causes most of the
   tactic choices in this file.
   --------------------------------------------------------------------- *)
Lemma e_eq_eps_msq : forall i t, e i t = eps i t * msq t.
Proof. intros i t. unfold eps. field. apply msq_neq0. Qed.

(** ** 4.16–4.21  The normalized gradient law *)

(* ---------------------------------------------------------------------
   Gamma is symmetric positive definite and diagonal, so it is fully
   described by its diagonal entries: gam j = Gamma_jj > 0.  Representing it
   as a vector rather than a matrix is what keeps the Lyapunov computations
   short, since Gamma^{-1} is then just j |-> / gam j.
   --------------------------------------------------------------------- *)
Variable gam : nat -> R.
Hypothesis H_gam : forall j, (j < d)%nat -> 0 < gam j.

(* Nonzero-ness in the shape 'field' wants. *)
Lemma gam_neq0 : forall j, (j < d)%nat -> gam j <> 0.
Proof. intros j Hj. pose proof (H_gam j Hj). lra. Qed.

(* ---------------------------------------------------------------------
   (4.19)/(4.29): the adaptive law, one component at a time.

   theta-hat-dot_{i,f} = -Gamma eps_{i,f} phi   becomes, componentwise,
   d/dt (th i t j) = -(gam j * eps i t * phi t j).

   Equations 4.16 (the cost J), 4.17 (theta-dot = -Gamma grad J) and 4.18
   (grad J = eps phi) are the DERIVATION of this law.  They are folded into
   the hypothesis because they define the algorithm rather than assert
   anything about it; nothing downstream refers to J.
   --------------------------------------------------------------------- *)
Hypothesis H_law : forall i j, (i < N)%nat -> (j < d)%nat ->
  Deriv (fun t => th i t j) (fun t => - (gam j * eps i t * phi t j)).

(* =====================================================================
   (4.20)/(4.21): theta*_p is constant, so the parametric error moves
   exactly like the estimate.

   THIS IS THE FIRST D_ext PROOF; the pattern repeats a dozen times below,
   so it is worth reading in full.

   The GOAL is
       Deriv (fun t => tht i t j) (fun t => - (gam j * eps i t * phi t j))
   and after 'unfold tht' the function becomes  fun t => th i t j - thstar j.

   The difference rule D_minus will hand us the derivative in the shape
       (- (gam j * eps i t * phi t j)) - 0
   because the derivative of the constant thstar j is 0.  That dangling
   '- 0' is not literally the expression in the statement, so we go through
   D_ext with exactly that shape supplied as f'.

   THE THREE SUBGOALS PRODUCED (they always come in this order):
     1.  forall t, th i t j - thstar j = th i t j - thstar j
           closed by 'intros; reflexivity'.
     2.  forall t, (- (gam j * eps i t * phi t j)) - 0
                 = - (gam j * eps i t * phi t j)
           closed by 'intros; ring'.  This is the algebra slot; here it is
           trivial, elsewhere it is the whole content of the theorem.
     3.  Deriv (fun t => th i t j - thstar j)
               (fun t => - (gam j * eps i t * phi t j) - 0)
           closed by the difference rule.  The bracket notation
           [tac1 | tac2] feeds the two subgoals of D_minus positionally:
           the first is discharged by the hypothesis H_law, the second by
           D_const.

   'assumption' means: this goal is literally one of the hypotheses in
   context (here (i < N)%nat and (j < d)%nat, which we introduced as Hi Hj).
   ===================================================================== *)
Theorem tht_law : forall i j, (i < N)%nat -> (j < d)%nat ->
  Deriv (fun t => tht i t j) (fun t => - (gam j * eps i t * phi t j)).
Proof.
  intros i j Hi Hj. unfold tht.
  apply (D_ext (fun t => th i t j - thstar j)
               (fun t => - (gam j * eps i t * phi t j) - 0)).
  - intros; reflexivity.
  - intros; ring.
  - apply D_minus; [apply H_law; assumption | apply D_const].
Qed.

(** ** Generic machinery: quadratic Lyapunov forms *)

(* ---------------------------------------------------------------------
   Every Lyapunov function in Chapter 4 has the same shape

       Wq n c T t  =  (1/2) sum_{j<n} T_j(t)^2 / c_j

   so it is worth defining once.  Instantiations:
       (4.22)         Wq d gam (tht i)          c_j = Gamma_jj
       (4.57)/(4.68)  Wq M (fun _ => 1) alpt    c_j = 1
       hull proof     Wq d gam tha

   '/ 2' is the real number 1/2: in Coq, '/ x' is the multiplicative inverse
   of x, so '/ 2 * X' means X/2.  Likewise '/ c j' is 1/c_j.

   T has type R -> nat -> R: a time-varying vector, same convention as phi.
   --------------------------------------------------------------------- *)
Definition Wq (n : nat) (c : nat -> R) (T : R -> nat -> R) (t : R) : R :=
  / 2 * Sum n (fun j => / c j * (T t j * T t j)).

(* ---------------------------------------------------------------------
   Differentiating Wq: if T_j has derivative T'_j for each j, then

       d/dt Wq = sum_j (1/c_j) T_j T'_j

   (the 1/2 and the factor 2 from the product rule cancel).

   PROOF.  Another D_ext.  The convenient f' is what the product rule
   literally produces, namely (1/c_j)(T'_j T_j + T_j T'_j); the wanted g' is
   sum_j (1/c_j) T_j T'_j.

   Second bullet in detail:
     Sum_ext rewrites the summand into  2 * ((1/c_j) (T_j T'_j))
       — the 'by (intros; ring)' clause proves that rewriting is legitimate.
     Sum_scal_l pulls the constant 2 out of the sum.
     'field' finishes:  (1/2) * (2 * S) = S.  ('ring' would fail: /2.)

   Third bullet: unfold Wq, then peel the expression from the outside in —
     D_scal   handles the leading / 2 *
     D_Sum    differentiates the sum termwise
     D_scal   handles the / c j *
     D_mult   is the product rule on T t j * T t j, and both of its subgoals
              are the same hypothesis HT, so a single 'apply HT' after the
              semicolon serves both.
   --------------------------------------------------------------------- *)
Lemma Wq_deriv : forall n (c : nat -> R) (T T' : R -> nat -> R),
  (forall j, (j < n)%nat -> Deriv (fun t => T t j) (fun t => T' t j)) ->
  Deriv (Wq n c T) (fun t => Sum n (fun j => / c j * (T t j * T' t j))).
Proof.
  intros n c T T' HT.
  apply (D_ext
           (fun t => / 2 * Sum n (fun j => / c j * (T t j * T t j)))
           (fun t => / 2 * Sum n (fun j =>
              / c j * (T' t j * T t j + T t j * T' t j)))).
  - intros; reflexivity.
  - intros t.
    rewrite (Sum_ext n
               (fun j => / c j * (T' t j * T t j + T t j * T' t j))
               (fun j => 2 * (/ c j * (T t j * T' t j))))
      by (intros; ring).
    rewrite Sum_scal_l. field.
  - unfold Wq. apply D_scal. apply D_Sum. intros j Hj.
    apply D_scal. apply D_mult; apply HT; assumption.
Qed.

(* ---------------------------------------------------------------------
   Wq is nonnegative when all c_j are positive.

   PROOF.
     assert (...) . { ... }   -- braces focus the side proof, like bullets.
     Rmult_le_pos             -- 0 <= a and 0 <= b imply 0 <= a * b.
     'left'                   -- the goal 0 <= x unfolds to (0 < x \/ 0 = x);
                                 'left' picks the strict disjunct.
     Rinv_0_lt_compat         -- 0 < x implies 0 < / x.
     Rle_0_sqr                -- 0 <= r * r.
   --------------------------------------------------------------------- *)
Lemma Wq_nonneg : forall n c T t,
  (forall j, (j < n)%nat -> 0 < c j) -> 0 <= Wq n c T t.
Proof.
  intros n c T t Hc. unfold Wq.
  assert (0 <= Sum n (fun j => / c j * (T t j * T t j))).
  { apply Sum_nonneg. intros j Hj.
    apply Rmult_le_pos.
    - left. apply Rinv_0_lt_compat. apply Hc; assumption.
    - apply Rle_0_sqr. }
  lra.
Qed.

(* Wq vanishes at t = 0 if the vector does.  Note 'T 0 j': the 0 here is the
   REAL number zero (the initial time), not the natural number.            *)
Lemma Wq_init0 : forall n c T,
  (forall j, (j < n)%nat -> T 0 j = 0) -> Wq n c T 0 = 0.
Proof.
  intros n c T H. unfold Wq.
  rewrite (Sum_zero n (fun j => / c j * (T 0 j * T 0 j)))
    by (intros j Hj; rewrite H by assumption; ring).
  ring.
Qed.

(* =====================================================================
   quad_zero — the workhorse behind convex-hull invariance.

   STATEMENT.  If
     (a) every c_j > 0,
     (b) Wq n c T has derivative W',
     (c) W' <= 0 everywhere,
     (d) T(0) = 0,
   then T(t) = 0 for every t >= 0 and every index j < n.

   WHY IT IS HERE.  The dissertation (and Narendra et al., point 3) argue
   that if theta*_p starts inside the convex hull it stays there, appealing
   implicitly to uniqueness of ODE solutions.  Coq's standard library has no
   ODE uniqueness theorem, but the Lyapunov route is elementary: the
   quadratic form starts at 0, cannot increase, and cannot be negative,
   hence is identically 0; and a vanishing positive-definite quadratic form
   forces the vector to vanish.

   PROOF.
     Hle  -- Wq(t) <= Wq(0), from the MVT lemma nonincr_of_nonpos_deriv.
             The underscore in 'nonincr_of_nonpos_deriv _ W' HD Hneg' asks
             Coq to infer that argument (the function) from the others.
     rewrite (Wq_init0 ...) in Hle
          -- rewrite INSIDE the hypothesis Hle, turning Wq(0) into 0.
     Hge  -- 0 <= Wq(t).
     Hz   -- combining the two: the sum itself is 0.  The
             'unfold Wq in Hle, Hge' unfolds in two hypotheses at once, so
             that lra sees the same expression in all three places.
     Hterm-- the j-th summand is 0, by Sum_eq0_all.
     Hci  -- / c j is nonzero (Rgt_not_eq : x > y implies x <> y).
     Rmult_integral
          -- a * b = 0 implies a = 0 or b = 0.  Applied twice: first to peel
             off / c j (impossible, hence 'contradiction'), then to the
             square T t j * T t j, whose two disjuncts are the same goal, so
             'assumption' closes both.
     'destruct ... as [H1|H1]'  -- case analysis on a disjunction, naming the
             hypothesis H1 in both branches.
     'contradiction'            -- there are hypotheses P and ~P in context.
   ===================================================================== *)
Lemma quad_zero : forall n (c : nat -> R) (T : R -> nat -> R) (W' : R -> R),
  (forall j, (j < n)%nat -> 0 < c j) ->
  Deriv (Wq n c T) W' ->
  (forall t, W' t <= 0) ->
  (forall j, (j < n)%nat -> T 0 j = 0) ->
  forall t, 0 <= t -> forall j, (j < n)%nat -> T t j = 0.
Proof.
  intros n c T W' Hc HD Hneg Hinit t Ht j Hj.
  assert (Hle : Wq n c T t <= Wq n c T 0)
    by (apply (nonincr_of_nonpos_deriv _ W' HD Hneg); assumption).
  rewrite (Wq_init0 n c T Hinit) in Hle.
  assert (Hge : 0 <= Wq n c T t) by (apply Wq_nonneg; assumption).
  assert (Hz : Sum n (fun k => / c k * (T t k * T t k)) = 0)
    by (unfold Wq in Hle, Hge; lra).
  assert (Hterm : / c j * (T t j * T t j) = 0).
  { apply (Sum_eq0_all n (fun k => / c k * (T t k * T t k))); try assumption.
    intros k Hk. apply Rmult_le_pos.
    - left. apply Rinv_0_lt_compat. apply Hc; assumption.
    - apply Rle_0_sqr. }
  assert (Hci : / c j <> 0).
  { apply Rgt_not_eq. apply Rinv_0_lt_compat. apply Hc; assumption. }
  destruct (Rmult_integral _ _ Hterm) as [H1|H1]; [contradiction|].
  destruct (Rmult_integral _ _ H1) as [H2|H2]; assumption.
Qed.

(* ---------------------------------------------------------------------
   The generic Lyapunov computation, stated once and reused three times.

   If every component of T obeys a gradient law of the form
       d/dt T_j = -(gam j * E t * phi t j)
   for some scalar signal E, then
       d/dt Wq d gam T = -(E * (T . phi)).

   Instantiations:
       T = tht i, E = eps i     gives equation 4.23
       T = tha,   E = ea/msq    gives convex-hull invariance

   Note E is a scalar function of time supplied by the caller: in this file
   it is always an identification error divided by m^2.

   Second bullet in detail.  The summand
       (1/gam j) * (T_j * -(gam j * E * phi_j))
   simplifies to  -E * (T_j * phi_j)  — this requires cancelling gam j
   against 1/gam j, which is a FIELD operation, hence 'field' rather than
   'ring', and hence the side condition discharged by 'apply gam_neq0'.
   Sum_scal_l then pulls -E out, leaving exactly dot d (T t) (phi t).
   --------------------------------------------------------------------- *)
Lemma grad_Wq_deriv : forall (T : R -> nat -> R) (E : R -> R),
  (forall j, (j < d)%nat -> Deriv (fun t => T t j) (fun t => - (gam j * E t * phi t j))) ->
  Deriv (Wq d gam T) (fun t => - (E t * dot d (T t) (phi t))).
Proof.
  intros T E HT.
  apply (D_ext (Wq d gam T)
               (fun t => Sum d (fun j => / gam j * (T t j * - (gam j * E t * phi t j))))).
  - intros; reflexivity.
  - intros t. unfold dot.
    rewrite (Sum_ext d
               (fun j => / gam j * (T t j * - (gam j * E t * phi t j)))
               (fun j => - E t * (T t j * phi t j)))
      by (intros j Hj; field; apply gam_neq0; assumption).
    rewrite Sum_scal_l. ring.
  - apply Wq_deriv. assumption.
Qed.

(** ** 4.22–4.23  Stability of the first-level estimator *)

(* (4.22): V = theta-tilde^T Gamma^{-1} theta-tilde / 2.

   ': R -> R' with no argument on the left means V1 i IS a function of time,
   defined by partially applying Wq.  'tht i' is again a partial application:
   the trajectory of the i-th parametric error.                            *)
Definition V1 (i : nat) : R -> R := Wq d gam (tht i).      (* (4.22) *)

(* ---------------------------------------------------------------------
   (4.23): V-dot = -eps^2 m^2.

   PROOF.  D_ext again.  The convenient derivative shape is the one
   grad_Wq_deriv produces, -(eps * (theta-tilde . phi)); the wanted one is
   -(eps * eps * m^2).

   SECOND BULLET — this is the whole argument, and it reads exactly like the
   dissertation:
     rewrite <- e_eq_dot_tht    replaces theta-tilde . phi by e   (4.15 used
                                BACKWARDS, hence '<-')
     rewrite (e_eq_eps_msq i t) replaces e by eps * m^2
     ring                       -(eps * (eps * m^2)) = -(eps * eps * m^2)
   --------------------------------------------------------------------- *)
Theorem V1_dyn : forall i, (i < N)%nat ->
  Deriv (V1 i) (fun t => - (eps i t * eps i t * msq t)).   (* (4.23) *)
Proof.
  intros i Hi. unfold V1.
  apply (D_ext (Wq d gam (tht i)) (fun t => - (eps i t * dot d (tht i t) (phi t)))).
  - intros; reflexivity.
  - intros t. rewrite <- e_eq_dot_tht. rewrite (e_eq_eps_msq i t). ring.
  - apply grad_Wq_deriv. intros j Hj. apply tht_law; assumption.
Qed.

(* ---------------------------------------------------------------------
   The consequence the dissertation actually wants: V cannot grow, hence
   theta-tilde is uniformly bounded.

   'Corollary' is the same keyword as Theorem.

   PROOF.  Feed V1_dyn to the MVT lemma and then show the derivative is <= 0.
     'apply (nonincr_of_nonpos_deriv _ _ (V1_dyn i Hi))' — the two
     underscores are the function and its derivative, both inferred from the
     third argument.
     Rle_0_sqr gives 0 <= Rsqr (eps i t); 'unfold Rsqr in Hsq' turns Rsqr x
     into x * x so that the hypothesis matches the goal syntactically.
     'nra' rather than 'lra' because the goal multiplies eps*eps by msq, a
     product of two unknown quantities.
   --------------------------------------------------------------------- *)
Corollary V1_nonincreasing : forall i, (i < N)%nat ->
  forall a b, a <= b -> V1 i b <= V1 i a.
Proof.
  intros i Hi.
  apply (nonincr_of_nonpos_deriv _ _ (V1_dyn i Hi)).
  intros t. pose proof (msq_pos t) as Hm.
  pose proof (Rle_0_sqr (eps i t)) as Hsq. unfold Rsqr in Hsq. nra.
Qed.

(** ** 4.30  Dynamics of the identification errors *)

(* phi^T Gamma phi, the scalar appearing in 4.30 and 4.44. *)
Definition phiGphi (t : R) : R := Sum d (fun j => gam j * (phi t j * phi t j)).

(* ---------------------------------------------------------------------
   Generic error dynamics, stated once and used for e_i, e_v and e_alpha.

   If T obeys the gradient law with scalar E, then

       d/dt (T . phi) = -(E * phi^T Gamma phi) + T . phi-dot

   which is equation 4.30 with T = theta-tilde_i and E = eps_i.

   SECOND BULLET.  The product rule gives, termwise,
       (-(gam_j E phi_j)) * phi_j   +   T_j * phid_j
   Sum_plus splits the sum in two; Sum_ext rewrites the first summand into
   -E * (gam_j (phi_j phi_j)); Sum_scal_l pulls -E out, producing exactly
   -E * phiGphi.  The second half is already dot d (T t) (phid t).

   THIRD BULLET.  D_Sum differentiates termwise; D_mult is the product rule
   on T_j * phi_j, whose two halves are the caller's hypothesis HT and the
   differentiability of phi (H_phi).
   --------------------------------------------------------------------- *)
Lemma gen_e_dyn : forall (T : R -> nat -> R) (E : R -> R),
  (forall j, (j < d)%nat -> Deriv (fun t => T t j) (fun t => - (gam j * E t * phi t j))) ->
  Deriv (fun t => dot d (T t) (phi t))
        (fun t => - (E t * phiGphi t) + dot d (T t) (phid t)).
Proof.
  intros T E HT.
  apply (D_ext
           (fun t => Sum d (fun j => T t j * phi t j))
           (fun t => Sum d (fun j => - (gam j * E t * phi t j) * phi t j
                                     + T t j * phid t j))).
  - intros; reflexivity.
  - intros t. unfold phiGphi, dot.
    rewrite Sum_plus.
    rewrite (Sum_ext d
               (fun j => - (gam j * E t * phi t j) * phi t j)
               (fun j => - E t * (gam j * (phi t j * phi t j))))
      by (intros; ring).
    rewrite Sum_scal_l. ring.
  - apply D_Sum. intros j Hj. apply D_mult; [apply HT; assumption | apply H_phi; assumption].
Qed.

(* ---------------------------------------------------------------------
   (4.30) itself.  The only work is converting between the two descriptions
   of the same function: 'e i' by definition, and 'dot d (tht i t) (phi t)'
   by theorem 4.15.

   'symmetry' flips the goal a = b into b = a; needed because e_eq_dot_tht
   points the other way round from what D_ext's first subgoal wants.
   --------------------------------------------------------------------- *)
Theorem e_dyn : forall i, (i < N)%nat ->
  Deriv (e i) (fun t => - (eps i t * phiGphi t) + dot d (tht i t) (phid t)).
Proof.
  intros i Hi.
  apply (D_ext (fun t => dot d (tht i t) (phi t))
               (fun t => - (eps i t * phiGphi t) + dot d (tht i t) (phid t))).
  - intros t. symmetry. apply e_eq_dot_tht.
  - intros; reflexivity.
  - apply gen_e_dyn. intros j Hj. apply tht_law; assumption.
Qed.

(** ** 4.31–4.40  Convex combinations and the virtual model *)

(* ---------------------------------------------------------------------
   (4.31): the convex weights beta_i.

   Two hypotheses, matching the two conditions of the text.  Watch which one
   the proofs actually use: H_beta_sum appears in every single theorem below,
   H_beta_rng in NONE of them.  That is a real observation about Chapter 4 —
   the identities 4.32-4.40 need only that the coefficients sum to one; the
   box constraint 0 <= beta_i <= 1 matters solely for the geometric
   interpretation (staying inside the hull rather than on its affine span).
   --------------------------------------------------------------------- *)
Variable beta : nat -> R.
Hypothesis H_beta_sum : Sum N beta = 1.                          (* (4.31) *)
Hypothesis H_beta_rng : forall i, (i < N)%nat -> 0 <= beta i <= 1. (* (4.31) *)

(* The virtual model.  thv t is the vector; the pattern is identical to th. *)
Definition thv  (t : R) (j : nat) : R := Sum N (fun i => th i t j * beta i). (* (4.31) *)
Definition zhv  (t : R) : R := dot d (thv t) (phi t).                        (* (4.32) *)
Definition ev   (t : R) : R := zhv t - z t.                                  (* (4.33) *)
Definition thtv (t : R) (j : nat) : R := thv t j - thstar j.                 (* (4.34) *)
Definition epsv (t : R) : R := ev t / msq t.

(* ---------------------------------------------------------------------
   A linear combination of the estimates yields the same linear combination
   of the model outputs.  Stated for an arbitrary coefficient vector c so it
   can serve both beta (4.32) and alpha* (4.42).

   In symbols:  sum_j (sum_i th_ij c_i) phi_j  =  sum_i c_i (sum_j th_ij phi_j).

   PROOF.  This is an exchange of summation order.
     unfold dot, zh, dot     (dot appears twice, hence the repetition)
     Sum_ext                 push phi_j inside the inner sum, using Sum_scal_r
     Sum_swap                exchange the two sums (discrete Fubini)
     apply Sum_ext           reduce to a per-i statement
     rewrite <- Sum_scal_r   pull c_i back out of the inner sum, backwards
     apply Sum_ext; ring     finish termwise
   --------------------------------------------------------------------- *)
Lemma dot_lincomb : forall (c : nat -> R) (t : R),
  dot d (fun j => Sum N (fun i => th i t j * c i)) (phi t)
  = Sum N (fun i => zh i t * c i).
Proof.
  intros c t. unfold dot, zh, dot.
  rewrite (Sum_ext d
             (fun j => Sum N (fun i => th i t j * c i) * phi t j)
             (fun j => Sum N (fun i => th i t j * c i * phi t j)))
    by (intros; rewrite Sum_scal_r; reflexivity).
  rewrite Sum_swap.
  apply Sum_ext. intros i Hi.
  rewrite <- Sum_scal_r. apply Sum_ext. intros j Hj. ring.
Qed.

(* =====================================================================
   (4.35): theta-tilde_v = sum_i beta_i theta-tilde_i.

   The mathematical content is one line — subtract theta* = (sum beta_i)
   theta* — and the Coq proof is that line, made explicit.

   PROOF, with the goal after each step:

     unfold thtv, thv, tht
        Sum N (fun i => th i t j * beta i) - thstar j
      = Sum N (fun i => (th i t j - thstar j) * beta i)

     rewrite (Sum_ext N A B) by (intros; ring)
        -- distribute inside the sum on the right; the 'by' clause proves
           (th_ij - thstar_j) beta_i = th_ij beta_i - thstar_j beta_i.
      = Sum N (fun i => th i t j * beta i - thstar j * beta i)

     rewrite Sum_minus       split the sum
     rewrite Sum_scal_l      pull thstar j out:  thstar j * Sum N beta
     rewrite H_beta_sum      Sum N beta becomes 1     <-- THE ONLY PLACE THE
                                                          CONVEXITY IS USED
     ring                    X - thstar j = X - thstar j * 1
   ===================================================================== *)
Theorem thtv_convex : forall t j, thtv t j = Sum N (fun i => tht i t j * beta i).
Proof.
  intros t j. unfold thtv, thv, tht.
  rewrite (Sum_ext N
             (fun i => (th i t j - thstar j) * beta i)
             (fun i => th i t j * beta i - thstar j * beta i))
    by (intros; ring).
  rewrite Sum_minus, Sum_scal_l, H_beta_sum. ring.
Qed.

(* ---------------------------------------------------------------------
   e_v is IDENTICALLY the convex combination of the e_i.

   The dissertation argues (between 4.37 and 4.40) that the two only agree
   exponentially, and coincide if e_v(0) = sum beta_i e_i(0).  With
   linear-regression models no such condition is needed: the identity is
   definitional, exactly as above, once you know sum beta_i = 1.

   Same proof skeleton as 4.35, with dot_lincomb doing the work of pushing
   the combination through the inner product.
   --------------------------------------------------------------------- *)
Theorem ev_convex : forall t, ev t = Sum N (fun i => e i t * beta i).
Proof.
  intros t. unfold ev, zhv, thv, e.
  rewrite dot_lincomb.
  rewrite (Sum_ext N (fun i => (zh i t - z t) * beta i)
                     (fun i => zh i t * beta i - z t * beta i))
    by (intros; ring).
  rewrite Sum_minus, Sum_scal_l, H_beta_sum. ring.
Qed.

(* The normalised version.  'unfold Rdiv' turns x / y into x * / y so that
   'ring' can handle it: ring cannot divide, but it can multiply by the atom
   / msq t.  This trick recurs throughout the file.                        *)
Theorem epsv_convex : forall t, epsv t = Sum N (fun i => eps i t * beta i).
Proof.
  intros t. unfold epsv, eps.
  rewrite (Sum_ext N (fun i => e i t / msq t * beta i)
                     (fun i => / msq t * (e i t * beta i)))
    by (intros; unfold Rdiv; ring).
  rewrite Sum_scal_l, <- ev_convex. unfold Rdiv. ring.
Qed.

(* The analogue of 4.15 for the virtual model; identical proof. *)
Theorem ev_eq_dot_thtv : forall t, ev t = dot d (thtv t) (phi t).
Proof.
  intros t. unfold ev, zhv, thtv. rewrite H_param. rewrite dot_minus_l. reflexivity.
Qed.

(* =====================================================================
   (4.36)/(4.40): the virtual model obeys an adaptive law of EXACTLY the
   same form as the first-level models.

   SECOND BULLET, which is the argument:
     each term differentiates to
         -(gam_j eps_i phi_j) * beta_i  +  th_ij * 0
     (the second half because beta_i is constant — D_const);
     Sum_ext rewrites this as  -(gam_j phi_j) * (eps_i beta_i);
     Sum_scal_l pulls the constant -(gam_j phi_j) out, leaving
     sum_i eps_i beta_i, which epsv_convex (used backwards, '<-') folds into
     epsv.

   THIRD BULLET: D_Sum termwise, then the product rule with D_const for the
   constant factor beta_i.
   ===================================================================== *)
Theorem thv_law : forall j, (j < d)%nat ->
  Deriv (fun t => thv t j) (fun t => - (gam j * epsv t * phi t j)).
Proof.
  intros j Hj. unfold thv.
  apply (D_ext
           (fun t => Sum N (fun i => th i t j * beta i))
           (fun t => Sum N (fun i => - (gam j * eps i t * phi t j) * beta i + th i t j * 0))).
  - intros; reflexivity.
  - intros t.
    rewrite (Sum_ext N
               (fun i => - (gam j * eps i t * phi t j) * beta i + th i t j * 0)
               (fun i => - (gam j * phi t j) * (eps i t * beta i)))
      by (intros; ring).
    rewrite Sum_scal_l, <- epsv_convex. ring.
  - apply D_Sum. intros i Hi.
    apply D_mult; [apply H_law; assumption | apply D_const].
Qed.

(* Same as tht_law, one level up: subtract the constant theta*. *)
Theorem thtv_law : forall j, (j < d)%nat ->
  Deriv (fun t => thtv t j) (fun t => - (gam j * epsv t * phi t j)).
Proof.
  intros j Hj. unfold thtv.
  apply (D_ext (fun t => thv t j - thstar j)
               (fun t => - (gam j * epsv t * phi t j) - 0)).
  - intros; reflexivity.
  - intros; ring.
  - apply D_minus; [apply thv_law; assumption | apply D_const].
Qed.

(* ---------------------------------------------------------------------
   (4.37) = (4.39).

   The dissertation derives the dynamics of sum_i beta_i e_i (4.37) and of
   e_v (4.39) separately and observes that the expressions coincide.  Here
   there is nothing to compare: ev_convex already showed the two are the same
   function, so a single theorem covers both.  All that remains is to
   instantiate gen_e_dyn at T = theta-tilde_v, E = eps_v.
   --------------------------------------------------------------------- *)
Theorem ev_dyn : Deriv ev (fun t => - (epsv t * phiGphi t) + dot d (thtv t) (phid t)).
Proof.
  apply (D_ext (fun t => dot d (thtv t) (phi t))
               (fun t => - (epsv t * phiGphi t) + dot d (thtv t) (phid t))).
  - intros t. symmetry. apply ev_eq_dot_thtv.
  - intros; reflexivity.
  - apply gen_e_dyn. intros j Hj. apply thtv_law; assumption.
Qed.

(** ** 4.41–4.45  The alpha* parametrization and invariance of the convex hull *)

(* ---------------------------------------------------------------------
   alpha*: the convex coefficients that reproduce theta*_p.

   CRITICAL MODELLING POINT.  (4.41) is assumed ONLY AT t = 0 (H_astar_init
   mentions 'th i 0 j').  That theta*_p remains a convex combination of the
   estimates at later times is not assumed — it is the theorem
   hull_invariance below.  Appendix A is what guarantees such an alpha*
   exists in the first place, given the known parameter bounds.
   --------------------------------------------------------------------- *)
Variable astar : nat -> R.
Hypothesis H_astar_sum : Sum N astar = 1.                          (* (4.41) *)
Hypothesis H_astar_rng : forall i, (i < N)%nat -> 0 <= astar i <= 1. (* (4.41) *)

Hypothesis H_astar_init : forall j, (j < d)%nat ->
  Sum N (fun i => th i 0 j * astar i) = thstar j.

(* tha = sum_i alpha*_i theta-tilde_i, the parametric error of the alpha*
   combination.  ea = sum_i alpha*_i e_i, its identification error (4.43). *)
Definition tha (t : R) (j : nat) : R := Sum N (fun i => tht i t j * astar i).
Definition ea  (t : R) : R := Sum N (fun i => e i t * astar i).   (* (4.43)/(4.45) *)

(* tha vanishes at t = 0.  This is H_astar_init rewritten in terms of the
   parametric errors; the proof is the same three lines as thtv_convex.

   'rewrite ..., H_astar_init by assumption' — the 'by' clause discharges the
   side condition (j < d)%nat generated by H_astar_init, using Hj.          *)
Lemma tha_init0 : forall j, (j < d)%nat -> tha 0 j = 0.
Proof.
  intros j Hj. unfold tha, tht.
  rewrite (Sum_ext N (fun i => (th i 0 j - thstar j) * astar i)
                     (fun i => th i 0 j * astar i - thstar j * astar i))
    by (intros; ring).
  rewrite Sum_minus, Sum_scal_l, H_astar_sum, H_astar_init by assumption. ring.
Qed.

(* ---------------------------------------------------------------------
   ea = tha . phi, i.e. the alpha*-combination behaves like a single model.

   PROOF.  Two Sum_ext rewrites and one Sum_swap:
     first, replace each e_i by theta-tilde_i . phi (theorem 4.15);
     second, push alpha*_i inside the inner sum;
     then exchange the order of summation and pull alpha*_i back out.
   --------------------------------------------------------------------- *)
Lemma ea_eq_dot_tha : forall t, ea t = dot d (tha t) (phi t).
Proof.
  intros t. unfold ea, tha, dot.
  rewrite (Sum_ext N (fun i => e i t * astar i)
                     (fun i => dot d (tht i t) (phi t) * astar i))
    by (intros i Hi; rewrite e_eq_dot_tht; reflexivity).
  unfold dot.
  rewrite (Sum_ext N (fun i => Sum d (fun j => tht i t j * phi t j) * astar i)
                     (fun i => Sum d (fun j => tht i t j * astar i * phi t j)))
    by (intros i Hi; rewrite <- Sum_scal_r; apply Sum_ext; intros; ring).
  rewrite Sum_swap.
  apply Sum_ext. intros j Hj. rewrite <- Sum_scal_r. reflexivity.
Qed.

(* ---------------------------------------------------------------------
   tha obeys a gradient law with scalar signal ea/m^2.

   Same shape as thv_law, with astar in place of beta.  The only extra step
   is that the scalar comes out as ea/m^2 rather than eps_v: the second
   bullet rewrites eps_i into (1/m^2) e_i (that is 'unfold eps, Rdiv'), pulls
   both constants out with two Sum_scal_l rewrites, and recognises what is
   left as ea.
   --------------------------------------------------------------------- *)
Lemma tha_law : forall j, (j < d)%nat ->
  Deriv (fun t => tha t j) (fun t => - (gam j * (ea t / msq t) * phi t j)).
Proof.
  intros j Hj. unfold tha.
  apply (D_ext
           (fun t => Sum N (fun i => tht i t j * astar i))
           (fun t => Sum N (fun i => - (gam j * eps i t * phi t j) * astar i + tht i t j * 0))).
  - intros; reflexivity.
  - intros t.
    rewrite (Sum_ext N
               (fun i => - (gam j * eps i t * phi t j) * astar i + tht i t j * 0)
               (fun i => - (gam j * phi t j) * (/ msq t * (e i t * astar i))))
      by (intros; unfold eps, Rdiv; ring).
    rewrite Sum_scal_l, Sum_scal_l. unfold ea, Rdiv. ring.
  - apply D_Sum. intros i Hi.
    apply D_mult; [apply tht_law; assumption | apply D_const].
Qed.

(* =====================================================================
   INVARIANCE OF THE CONVEX HULL.

   If theta*_p is in the convex hull of the initial estimates, it stays in
   the hull WITH THE SAME COEFFICIENTS for every t >= 0.  This is item 3 of
   Narendra-Wang-Chen; the dissertation asserts it (page 64, os parametros
   verdadeiros pertencem ao fecho convexo) without proof.

   STRUCTURE.  Everything is set up so that this is a single application of
   quad_zero to the vector tha, with c = gam.  Four bullets, one per
   hypothesis of quad_zero:

     1.  every gam j > 0                      -- exactly H_gam
     2.  Deriv (Wq d gam tha) W'  with W' = -(ea/m^2 * ea)
           grad_Wq_deriv gives -(ea/m^2 * (tha . phi)); ea_eq_dot_tha turns
           tha . phi into ea.  (Nested bullets '+' inside '-'; Coq forces a
           different bullet symbol at each depth.)
     3.  W' <= 0 everywhere
           -(ea/m^2 * ea) = -(ea^2)/m^2 <= 0 since m^2 > 0.  'nra' is needed
           because it is a product of unknowns.
     4.  tha(0) = 0                           -- exactly tha_init0

   Note there is no 'intros' at the start: the goal is literally the
   conclusion of quad_zero, so 'apply' matches it directly.
   ===================================================================== *)
Theorem hull_invariance : forall t, 0 <= t -> forall j, (j < d)%nat -> tha t j = 0.
Proof.
  apply (quad_zero d gam tha (fun t => - (ea t / msq t * ea t))).
  - exact H_gam.
  - apply (D_ext (Wq d gam tha) (fun t => - (ea t / msq t * dot d (tha t) (phi t)))).
    + intros; reflexivity.
    + intros t. rewrite <- ea_eq_dot_tha. reflexivity.
    + apply grad_Wq_deriv. apply tha_law.
  - intros t. pose proof (msq_pos t) as Hm.
    assert (Hinv : 0 <= / msq t) by (left; apply Rinv_0_lt_compat; assumption).
    pose proof (Rle_0_sqr (ea t)) as Hsq. unfold Rsqr in Hsq.
    unfold Rdiv. nra.
  - exact tha_init0.
Qed.

(* ---------------------------------------------------------------------
   (4.41) restated for all t >= 0, which is what the text uses from page 63
   onward.

   PROOF.  Take the hull-invariance fact as a hypothesis H, unfold it into a
   statement about th, and let lra finish.  Note the rewrites are applied
   'in H', i.e. to the hypothesis rather than the goal — the usual way to
   massage a fact you already have into the form you need.
   --------------------------------------------------------------------- *)
Corollary theta_star_in_hull : forall t, 0 <= t -> forall j, (j < d)%nat ->
  Sum N (fun i => th i t j * astar i) = thstar j.
Proof.
  intros t Ht j Hj.
  pose proof (hull_invariance t Ht j Hj) as H. unfold tha, tht in H.
  rewrite (Sum_ext N (fun i => (th i t j - thstar j) * astar i)
                     (fun i => th i t j * astar i - thstar j * astar i)) in H
    by (intros; ring).
  rewrite Sum_minus, Sum_scal_l, H_astar_sum in H. lra.
Qed.

(* ---------------------------------------------------------------------
   (4.45).  The dissertation states lim_{t->inf} sum_i alpha*_i e_i = 0 and
   discusses a nonzero e_alpha(0) decaying exponentially.  Under hypothesis
   H_param the quantity is exactly zero for every t >= 0.

   (The text's discussion applies to the practical situation where the filter
   states are not initialised consistently, which is outside model 4.8.)

   PROOF.  ea = tha . phi and every component of tha vanishes, so the sum is
   a sum of zeros — Sum_zero.
   --------------------------------------------------------------------- *)
Corollary ea_zero : forall t, 0 <= t -> ea t = 0.
Proof.
  intros t Ht. rewrite ea_eq_dot_tha. unfold dot.
  apply Sum_zero. intros j Hj. rewrite (hull_invariance t Ht j Hj). ring.
Qed.

(* (4.44) in general form: one more instantiation of gen_e_dyn. *)
Theorem ea_dyn_general :
  Deriv ea (fun t => - (ea t / msq t * phiGphi t) + dot d (tha t) (phid t)).
Proof.
  apply (D_ext (fun t => dot d (tha t) (phi t))
               (fun t => - (ea t / msq t * phiGphi t) + dot d (tha t) (phid t))).
  - intros t. symmetry. apply ea_eq_dot_tha.
  - intros; reflexivity.
  - apply gen_e_dyn. apply tha_law.
Qed.

(* ---------------------------------------------------------------------
   (4.44) exactly as printed: the tha . phi-dot term is absent because tha
   vanishes.

   The hypothesis is stated as an explicit premise rather than taken from
   hull_invariance because Deriv quantifies over ALL real t, whereas
   hull_invariance only covers t >= 0.  Stating it this way is the honest
   formulation.

   'replace X with 0. + ring. + ...' — replace generates two goals: the
   modified main goal (first bullet) and the obligation X = 0 (second).
   --------------------------------------------------------------------- *)
Theorem ea_dyn : (forall t j, (j < d)%nat -> tha t j = 0) ->
  Deriv ea (fun t => - (ea t / msq t * phiGphi t)).
Proof.
  intros Hz.
  apply (D_ext ea (fun t => - (ea t / msq t * phiGphi t) + dot d (tha t) (phid t))).
  - intros; reflexivity.
  - intros t.
    replace (dot d (tha t) (phid t)) with 0.
    + ring.
    + unfold dot. symmetry. apply Sum_zero. intros j Hj. rewrite Hz by assumption. ring.
  - apply ea_dyn_general.
Qed.

(** ** 4.46–4.51  Elimination of alpha_N *)

(* ---------------------------------------------------------------------
   M is N-1, so the model the text calls N is index M here.  The equation
   N = S M ('S' is the successor constructor on nat) is what makes the split
   of a Sum into 'all but the last, plus the last' a purely definitional
   step, since Sum recurses on the last index.
   --------------------------------------------------------------------- *)
Variable M : nat.
Hypothesis H_NM : N = S M.

(* (4.50): E_f = [eps_1 - eps_N, ..., eps_{N-1} - eps_N], a ROW vector, so
   Ev t is a function of the index i < M.                                  *)
Definition Ev (t : R) (i : nat) : R := eps i t - eps M t.       (* (4.50) *)

(* (4.47) in the exact form: sum_i eps_i alpha*_i = e_alpha / m^2.
   (Equal to zero once the hull invariance applies.)                       *)
Lemma sum_eps_astar : forall t, Sum N (fun i => eps i t * astar i) = ea t / msq t.
Proof.
  intros t. unfold eps, ea.
  rewrite (Sum_ext N (fun i => e i t / msq t * astar i)
                     (fun i => / msq t * (e i t * astar i)))
    by (intros; unfold Rdiv; ring).
  rewrite Sum_scal_l. unfold Rdiv. ring.
Qed.

(* =====================================================================
   (4.48)+(4.49)+(4.51): E_f alpha*_f = -eps_{N,f} (+ residual e_alpha/m^2).

   This is the algebraic heart of second-level adaptation, and the proof is
   worth following line by line.  The goal after each step:

     intros t
        Sum M (fun i => Ev t i * astar i) = - eps M t + ea t / msq t

     assert HS ... by (rewrite H_NM; reflexivity)
        HS : Sum N (fun i => eps i t * astar i)
           = Sum M (fun i => eps i t * astar i) + eps M t * astar M
        This is the split of equation 4.48.  Because Sum (S M) f is DEFINED
        as Sum M f + f M, once N is rewritten to S M the two sides are the
        same term and 'reflexivity' closes it.  No arithmetic is involved.

     assert HA ... ; rewrite H_astar_sum in HA
        HA : 1 = Sum M astar + astar M

     rewrite sum_eps_astar in HS
        HS : ea t / msq t = Sum M (...) + eps M t * astar M

     unfold Ev
        Sum M (fun i => (eps i t - eps M t) * astar i) = ...

     rewrite (Sum_ext M A B) by (intros; ring)
        Sum M (fun i => eps i t * astar i - eps M t * astar i) = ...

     rewrite Sum_minus, Sum_scal_l, HS
        Sum M (fun i => eps i t * astar i) - eps M t * Sum M astar
      = - eps M t + (Sum M (fun i => eps i t * astar i) + eps M t * astar M)

     assert HaM : astar M = 1 - Sum M astar   by lra     (from HA)
     rewrite HaM
        ... = - eps M t + (Sum M (...) + eps M t * (1 - Sum M astar))

     ring
        Both sides are now the same polynomial in the four atoms
        Sum M (fun i => eps i t * astar i), Sum M astar, eps M t,
        ea t / msq t.

   NOTE the final 'lra' inside HaM cannot be replaced by 'ring': it USES the
   hypothesis HA, and ring never looks at hypotheses.  Conversely the last
   step cannot be 'lra': it multiplies eps M t by Sum M astar, two unknowns.
   ===================================================================== *)
Theorem E_alpha_star : forall t,
  Sum M (fun i => Ev t i * astar i) = - eps M t + ea t / msq t.
Proof.
  intros t.
  assert (HS : Sum N (fun i => eps i t * astar i)
               = Sum M (fun i => eps i t * astar i) + eps M t * astar M)
    by (rewrite H_NM; reflexivity).
  assert (HA : Sum N astar = Sum M astar + astar M) by (rewrite H_NM; reflexivity).
  rewrite H_astar_sum in HA.
  rewrite sum_eps_astar in HS.
  unfold Ev.
  rewrite (Sum_ext M (fun i => (eps i t - eps M t) * astar i)
                     (fun i => eps i t * astar i - eps M t * astar i))
    by (intros; ring).
  rewrite Sum_minus, Sum_scal_l, HS.
  assert (HaM : astar M = 1 - Sum M astar) by lra.
  rewrite HaM. ring.
Qed.

(* (4.51) as printed, valid for t >= 0 by the hull-invariance corollary. *)
Corollary E_alpha_star_exact : forall t, 0 <= t ->
  Sum M (fun i => Ev t i * astar i) = - eps M t.
Proof.
  intros t Ht. rewrite E_alpha_star, (ea_zero t Ht). unfold Rdiv. ring.
Qed.

(** ** 4.52–4.58  Conventional second level adaptation *)

(* gamma_{n2,f}, the second-level adaptive gain of (4.52). *)
Variable gn : R.                                (* gamma_{n2,f} of (4.52) *)
Hypothesis H_gn : 0 < gn.

(* ---------------------------------------------------------------------
   A NESTED SECTION.  Everything from here to 'End SLA_conventional' may use
   the variable alp; outside, the results are automatically quantified over
   it.  A nested section is used because the SLAFF part below needs a
   DIFFERENT alpha obeying a different law, and giving both the same name in
   one scope would be contradictory.
   --------------------------------------------------------------------- *)
Section SLA_conventional.

Variable alp : R -> nat -> R.                   (* alpha_f(t) in R^M *)

(* (4.54) and the two contractions of E_f with alpha and alpha-tilde. *)
Definition alpt (t : R) (i : nat) : R := alp t i - astar i.              (* (4.54) *)
Definition Ealp  (t : R) : R := Sum M (fun i => Ev t i * alp t i).       (* E_f alpha_f *)
Definition Ealpt (t : R) : R := Sum M (fun i => Ev t i * alpt t i).      (* E_f alphatilde_f *)

(* ---------------------------------------------------------------------
   (4.52): alpha-dot_f = -gamma E_f^T E_f alpha_f - gamma E_f^T eps_{N,f}.

   E_f is a ROW vector (1 x M), so E_f^T E_f is the rank-one M x M matrix
   with entries E_i E_j, and

       (E_f^T E_f alpha_f)_i = E_i * (E_f alpha_f) = Ev t i * Ealp t.

   That is why no matrix type is needed: the law is stated componentwise with
   the scalar Ealp t doing the work of the matrix-vector product.
   --------------------------------------------------------------------- *)
Hypothesis H_sla : forall i, (i < M)%nat ->
  Deriv (fun t => alp t i)
        (fun t => - gn * (Ev t i * Ealp t) - gn * (Ev t i * eps M t)).

(* ---------------------------------------------------------------------
   E_f alpha_f = E_f alpha-tilde_f + E_f alpha*_f, with the last term
   evaluated by E_alpha_star.

   'rewrite <- E_alpha_star' uses that theorem BACKWARDS: it finds the
   pattern '- eps M t + ea t / msq t' in the goal and replaces it by
   'Sum M (fun i => Ev t i * astar i)'.  That is the trick that makes the
   remaining goal pure algebra.
   --------------------------------------------------------------------- *)
Lemma Ealp_split : forall t, Ealp t = Ealpt t + (- eps M t + ea t / msq t).
Proof.
  intros t. unfold Ealp, Ealpt, alpt.
  rewrite <- E_alpha_star.
  rewrite (Sum_ext M (fun i => Ev t i * (alp t i - astar i))
                     (fun i => Ev t i * alp t i - Ev t i * astar i))
    by (intros; ring).
  rewrite Sum_minus. ring.
Qed.

(* =====================================================================
   (4.55)+(4.56): alpha-tilde-dot = -gamma E^T E alpha-tilde
                                    - gamma E^T e_alpha/m^2.

   The whole content is in the second bullet, which is one rewrite plus ring:
   substituting Ealp = Ealpt - eps_M + ea/m^2 into the law makes the two
   eps_M terms cancel, leaving the e_alpha residual.  That cancellation is
   the passage from (4.52) to (4.56) in the text.
   ===================================================================== *)
Theorem alpt_dyn : forall i, (i < M)%nat ->
  Deriv (fun t => alpt t i)
        (fun t => - gn * (Ev t i * Ealpt t) - gn * (Ev t i * (ea t / msq t))).
Proof.
  intros i Hi. unfold alpt.
  apply (D_ext (fun t => alp t i - astar i)
               (fun t => (- gn * (Ev t i * Ealp t) - gn * (Ev t i * eps M t)) - 0)).
  - intros; reflexivity.
  - intros t. rewrite Ealp_split. ring.
  - apply D_minus; [apply H_sla; assumption | apply D_const].
Qed.

(** *** 4.57–4.58  Lyapunov analysis *)

(* ---------------------------------------------------------------------
   Two candidates are treated:

     Vr  =  (1/2) alpha-tilde^T alpha-tilde
              -- the reduced one, used by Narendra-Wang-Chen (their eq. 24);

     Vb  =  (1/2 gamma) (alpha-tilde^T alpha-tilde + (vec1 . alpha-tilde)^2)
              -- the dissertation's (4.57), built on the EXTENDED vector
                 alphabar-tilde = [alpha-tilde ; -vec1 alpha-tilde].

   Vr is Wq with all weights equal to 1.  '(fun _ => 1)' is the constant-one
   weight vector.
   --------------------------------------------------------------------- *)
Definition Vr : R -> R := Wq M (fun _ => 1) alpt.   (* (1/2) alphatilde^T alphatilde *)

(* ---------------------------------------------------------------------
   The CORRECT counterpart of (4.58):

       Vr-dot = -gamma (E alpha-tilde)^2 - gamma (E alpha-tilde)(e_alpha/m^2)

   PROOF.  Wq_deriv gives sum_i (1/1) alpha-tilde_i * alpha-tilde-dot_i;
   substituting the law and factoring the common scalar
   (-gamma Ealpt - gamma r) out with Sum_scal_l leaves sum_i E_i
   alpha-tilde_i, which IS Ealpt by definition.

   Three notations to note:
     'apply (D_ext f f'); [ tac1 | | tac3 ]' — the empty middle slot leaves
        the second subgoal open, to be handled by the tactics that follow.
        This is an alternative to bullets when only one subgoal is long.
     'set (r := ea t / msq t)' — introduce a local abbreviation for that
        expression in the goal.  Done here so that the later 'ring' sees an
        atom instead of a division it cannot handle.
     'rewrite Rinv_1' — Rinv_1 : / 1 = 1.  Needed because Wq_deriv leaves the
        weight as / 1 and ring cannot simplify inverses.
     'replace X with (Ealpt t) by reflexivity' — X and Ealpt t are the same
        term after unfolding the definition, so reflexivity closes it; the
        replace just puts the goal into the form ring expects.
   --------------------------------------------------------------------- *)
Theorem Vr_dyn :
  Deriv Vr (fun t => - gn * (Ealpt t * Ealpt t) - gn * (Ealpt t * (ea t / msq t))).
Proof.
  unfold Vr.
  apply (D_ext (Wq M (fun _ => 1) alpt)
               (fun t => Sum M (fun i => / 1 * (alpt t i *
                  (- gn * (Ev t i * Ealpt t) - gn * (Ev t i * (ea t / msq t)))))));
    [ intros; reflexivity | | apply Wq_deriv; apply alpt_dyn ].
  intros t. set (r := ea t / msq t).
  rewrite (Sum_ext M
             (fun i => / 1 * (alpt t i *
                (- gn * (Ev t i * Ealpt t) - gn * (Ev t i * r))))
             (fun i => (- gn * Ealpt t - gn * r) * (Ev t i * alpt t i)))
    by (intros; rewrite Rinv_1; ring).
  rewrite Sum_scal_l.
  replace (Sum M (fun i => Ev t i * alpt t i)) with (Ealpt t) by reflexivity.
  ring.
Qed.

(* ---------------------------------------------------------------------
   The conclusion Section 4.3 is after: with e_alpha = 0 the reduced Lyapunov
   function is nonincreasing, hence alpha-tilde_f is uniformly bounded.

   The hypothesis '(forall t, ea t = 0)' is written as a premise rather than
   derived from ea_zero because ea_zero only covers t >= 0 while the MVT
   lemma quantifies over all reals.
   --------------------------------------------------------------------- *)
Corollary Vr_nonincreasing : (forall t, ea t = 0) ->
  forall a b, a <= b -> Vr b <= Vr a.
Proof.
  intros Hea.
  apply (nonincr_of_nonpos_deriv _ _ Vr_dyn).
  intros t. rewrite (Hea t).
  replace (0 / msq t) with 0 by (unfold Rdiv; ring).
  pose proof (Rle_0_sqr (Ealpt t)) as Hsq. unfold Rsqr in Hsq. nra.
Qed.

(* ---------------------------------------------------------------------
   The dissertation's own candidate.

   Sb t = vec1 . alpha-tilde_f  and  SE t = vec1 . E_f, the two row-sums that
   appear when the extended vector alphabar-tilde is used.

   'Sum M (alpt t)' rather than 'Sum M (fun i => alpt t i)': these are the
   same function (eta-equivalence), but Coq's rewriting is syntactic, so the
   shorter form is chosen deliberately here to match what Sum_scal_l produces
   in Sb_dyn below.  This is a purely technical matter with no mathematical
   content.
   --------------------------------------------------------------------- *)
Definition Sb (t : R) : R := Sum M (alpt t).      (* vec1 . alphatilde_f *)
Definition SE (t : R) : R := Sum M (Ev t).        (* vec1 . E_f          *)

(* (4.57).  Note the 1/(2 gamma) normalisation, exactly as printed. *)
Definition Vb (t : R) : R :=
  / (2 * gn) * (Sum M (fun i => alpt t i * alpt t i) + Sb t * Sb t).   (* (4.57) *)

(* d/dt (vec1 . alpha-tilde) = -gamma (vec1 . E)(E alpha-tilde + e_alpha/m^2).
   Same factor-and-pull-out pattern as Vr_dyn.                            *)
Lemma Sb_dyn :
  Deriv Sb (fun t => - gn * (SE t * Ealpt t) - gn * (SE t * (ea t / msq t))).
Proof.
  apply (D_ext (fun t => Sum M (fun i => alpt t i))
               (fun t => Sum M (fun i => - gn * (Ev t i * Ealpt t)
                                         - gn * (Ev t i * (ea t / msq t))))).
  - intros; reflexivity.
  - intros t. set (r := ea t / msq t).
    rewrite (Sum_ext M
               (fun i => - gn * (Ev t i * Ealpt t) - gn * (Ev t i * r))
               (fun i => (- gn * Ealpt t - gn * r) * Ev t i))
      by (intros; ring).
    rewrite Sum_scal_l. unfold SE. ring.
  - apply D_Sum. apply alpt_dyn.
Qed.

(* =====================================================================
   THE EXACT DERIVATIVE OF THE DISSERTATION'S LYAPUNOV CANDIDATE (4.57).

       Vb-dot = -(E alpha-tilde + (vec1.alpha-tilde)(vec1.E))
                 * (E alpha-tilde + e_alpha/m^2)

   Compare (4.58), which asserts
       Vb-dot = -N alpha-tilde^T E^T E alpha-tilde
                - N alpha-tilde^T E^T e_alpha/m^2.

   The cross term Sb * SE is what (4.58) replaces by the factor N.  They are
   not equal, and the two corollaries below make that precise.

   PROOF.  Product rule on both halves of Vb (third bullet: D_scal for the
   leading constant, D_plus for the sum, D_Sum + D_mult for the quadratic
   part, D_mult on Sb * Sb).  The second bullet then factors the common
   scalar -2 gamma (Ealpt + r) out of the sum and lets 'field' cancel the
   1/(2 gamma), which is why the side condition gn <> 0 is produced and
   discharged by 'exact Hgn'.

   Observe that the gamma cancels completely: Vb-dot carries NO factor gn,
   whereas Vr-dot does.  That is only the different normalisation of the two
   candidates (Vb has 1/(2 gamma), Vr has 1/2), not a discrepancy.
   ===================================================================== *)
Theorem Vb_dyn :
  Deriv Vb (fun t => - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t))).
Proof.
  unfold Vb.
  apply (D_ext
           (fun t => / (2 * gn) * (Sum M (fun i => alpt t i * alpt t i) + Sb t * Sb t))
           (fun t => / (2 * gn) *
              (Sum M (fun i => (- gn * (Ev t i * Ealpt t)
                                - gn * (Ev t i * (ea t / msq t))) * alpt t i
                               + alpt t i * (- gn * (Ev t i * Ealpt t)
                                             - gn * (Ev t i * (ea t / msq t))))
               + ((- gn * (SE t * Ealpt t) - gn * (SE t * (ea t / msq t))) * Sb t
                  + Sb t * (- gn * (SE t * Ealpt t) - gn * (SE t * (ea t / msq t))))))).
  - intros; reflexivity.
  - intros t. set (r := ea t / msq t).
    rewrite (Sum_ext M
               (fun i => (- gn * (Ev t i * Ealpt t)
                          - gn * (Ev t i * r)) * alpt t i
                         + alpt t i * (- gn * (Ev t i * Ealpt t)
                                       - gn * (Ev t i * r)))
               (fun i => (- 2 * gn * (Ealpt t + r)) * (Ev t i * alpt t i)))
      by (intros; ring).
    rewrite Sum_scal_l.
    replace (Sum M (fun i => Ev t i * alpt t i)) with (Ealpt t) by reflexivity.
    assert (Hgn : gn <> 0) by lra.
    field. exact Hgn.
  - apply D_scal. apply D_plus.
    + apply D_Sum. intros i Hi. apply D_mult; apply alpt_dyn; assumption.
    + apply D_mult; apply Sb_dyn.
Qed.

(** *** The factor N of (4.58) does not follow *)

(* ---------------------------------------------------------------------
   FIRST DISCREPANCY, part 1: the two expressions disagree numerically.

   The corollary is stated as an implication whose hypotheses PIN DOWN a
   particular numerical situation: N = 3 (i.e. M = 2), e_alpha = 0,
   E alpha-tilde = 1, vec1.alpha-tilde = 1, vec1.E = 1.  Under those,
       exact value  = -( (1 + 1*1) * (1 + 0) ) = -2
       (4.58) value = -( 3 * (1*1) )           = -3
   and the conclusion asserts they are different.

   These values are realisable: with M = 2, E = (1,0) and alpha-tilde = (1,0)
   give E alpha-tilde = 1, vec1.E = 1, vec1.alpha-tilde = 1.

   'INR (S M)' is the number of models N as a real number.

   PROOF.  Rewrite each hypothesis into the goal, replace 0 / msq t by 0
   (which 'ring' can prove but 'lra' cannot see through), let 'simpl' compute
   INR 3 into 1+1+1, and finish with lra.
   --------------------------------------------------------------------- *)
Corollary Vb_deriv_differs_from_4_58 : forall t,
  (M = 2)%nat -> ea t = 0 -> Ealpt t = 1 -> Sb t = 1 -> SE t = 1 ->
  - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t))
  <> - (INR (S M) * (Ealpt t * Ealpt t)).
Proof.
  intros t HM He HE HS HSE.
  rewrite HE, HS, HSE, He, HM.
  replace (0 / msq t) with 0 by (unfold Rdiv; ring).
  simpl. lra.
Qed.

(* ---------------------------------------------------------------------
   FIRST DISCREPANCY, part 2, and the serious half: the exact derivative of
   the dissertation's candidate can be STRICTLY POSITIVE.

   Values: E alpha-tilde = 1, vec1.alpha-tilde = -2, vec1.E = 1, e_alpha = 0.
   Then Vb-dot = -((1 + (-2)(1)) * 1) = +1 > 0.

   Realisable with M = 2, E = (1,0), alpha-tilde = (1,-3): nothing in (4.52)
   constrains alpha_f to stay in [0,1]^M, since no projection is applied at
   the second level, so alpha-tilde can indeed be that negative.

   Consequently (4.57) is not a Lyapunov function for this system, and the
   boundedness of alpha-tilde_f claimed on page 66 does not follow from
   (4.57)+(4.58).  It DOES follow from Vr / Vr_nonincreasing above, so the
   conclusion of Section 4.3 survives; only this route to it does not.
   --------------------------------------------------------------------- *)
Corollary Vb_deriv_can_be_positive : forall t,
  ea t = 0 -> Ealpt t = 1 -> Sb t = -2 -> SE t = 1 ->
  0 < - ((Ealpt t + Sb t * SE t) * (Ealpt t + ea t / msq t)).
Proof.
  intros t He HE HS HSE.
  rewrite HE, HS, HSE, He.
  replace (0 / msq t) with 0 by (unfold Rdiv; ring).
  lra.
Qed.

End SLA_conventional.

(** ** 4.60–4.69  Second level adaptation with a forgetting factor (SLAFF) *)

Section SLA_forgetting.

(* sigma > 0, the forgetting factor of (4.63). *)
Variable sig : R.                              (* the forgetting factor sigma *)
Hypothesis H_sig : 0 < sig.

(* ---------------------------------------------------------------------
   M_f and v_f of (4.65).  Mf t i j is the (i,j) entry of the matrix M_f(t);
   again no matrix type is needed, just a doubly indexed family.
   --------------------------------------------------------------------- *)
Variable Mf : R -> nat -> nat -> R.            (* M_f of (4.65) *)
Variable vf : R -> nat -> R.                   (* v_f of (4.65) *)

Hypothesis H_Mf0 : forall i j, Mf 0 i j = 0.   (* M_f(0) = 0 *)
Hypothesis H_vf0 : forall i, vf 0 i = 0.       (* v_f(0) = 0 *)

(* (4.66): the ODEs generating M_f and v_f.  Taking these as the definition
   rather than the convolution integrals of (4.65) avoids needing Riemann
   integration; the next two theorems show the two descriptions agree.      *)
Hypothesis H_Mf : forall i j, (i < M)%nat -> (j < M)%nat ->
  Deriv (fun t => Mf t i j) (fun t => - sig * Mf t i j + Ev t i * Ev t j).
Hypothesis H_vf : forall i, (i < M)%nat ->
  Deriv (fun t => vf t i) (fun t => - sig * vf t i + Ev t i * eps M t).

(* =====================================================================
   (4.65) <-> (4.66): the integrating-factor identity.

   Saying M_f(t) = int_0^t e^{-sigma(t-tau)} E^T E dtau with M_f(0) = 0 is
   EXACTLY saying that e^{sigma t} M_f(t) has derivative e^{sigma t} E^T E.
   The latter is a differential statement, provable with the product rule,
   and is the rigorous content of (4.61)-(4.65).

   PROOF.  Product rule (third bullet: D_exp_lin for the exponential, H_Mf
   for the matrix).  The second bullet is pure algebra:
       sigma e^{st} M + e^{st}(-sigma M + E_i E_j) = e^{st} E_i E_j.
   ===================================================================== *)
Theorem Mf_integrating_factor : forall i j, (i < M)%nat -> (j < M)%nat ->
  Deriv (fun t => exp (sig * t) * Mf t i j)
        (fun t => exp (sig * t) * (Ev t i * Ev t j)).
Proof.
  intros i j Hi Hj.
  apply (D_ext (fun t => exp (sig * t) * Mf t i j)
               (fun t => sig * exp (sig * t) * Mf t i j
                         + exp (sig * t) * (- sig * Mf t i j + Ev t i * Ev t j))).
  - intros; reflexivity.
  - intros; ring.
  - apply D_mult; [apply D_exp_lin | apply H_Mf; assumption].
Qed.

(* The same for v_f. *)
Theorem vf_integrating_factor : forall i, (i < M)%nat ->
  Deriv (fun t => exp (sig * t) * vf t i)
        (fun t => exp (sig * t) * (Ev t i * eps M t)).
Proof.
  intros i Hi.
  apply (D_ext (fun t => exp (sig * t) * vf t i)
               (fun t => sig * exp (sig * t) * vf t i
                         + exp (sig * t) * (- sig * vf t i + Ev t i * eps M t))).
  - intros; reflexivity.
  - intros; ring.
  - apply D_mult; [apply D_exp_lin | apply H_vf; assumption].
Qed.

(* ---------------------------------------------------------------------
   MQ x t = x^T M_f(t) x, the quadratic form; EX x t = E_f(t) x.

   x is an arbitrary fixed vector: proving x^T M x >= 0 for every x is what
   positive semi-definiteness means.
   --------------------------------------------------------------------- *)
Definition MQ (x : nat -> R) (t : R) : R :=
  Sum M (fun i => x i * Sum M (fun j => Mf t i j * x j)).
Definition EX (x : nat -> R) (t : R) : R := Sum M (fun i => Ev t i * x i).

(* ---------------------------------------------------------------------
   The quadratic form inherits the ODE:  d/dt (x^T M x) = -sigma x^T M x
   + (E x)^2.

   PROOF.  A double Sum differentiation.  The inner Sum_ext plus Sum_comb
   evaluates the inner derivative as -sigma (sum_j M_ij x_j) + E_i (sum_j E_j
   x_j); the outer Sum_comb then splits the whole thing into -sigma MQ plus
   EX * EX.

   Sum_comb is used rather than chaining Sum_plus and Sum_scal_l because it
   matches the two-term pattern in one step, which makes the rewrite
   unambiguous.

   The third bullet nests D_Sum inside D_Sum; the D_const calls handle the
   constant factors x i and x j.
   --------------------------------------------------------------------- *)
Lemma MQ_dyn : forall x, Deriv (MQ x) (fun t => - sig * MQ x t + EX x t * EX x t).
Proof.
  intros x.
  apply (D_ext
           (fun t => Sum M (fun i => x i * Sum M (fun j => Mf t i j * x j)))
           (fun t => Sum M (fun i => 0 * Sum M (fun j => Mf t i j * x j)
              + x i * Sum M (fun j => (- sig * Mf t i j + Ev t i * Ev t j) * x j
                                      + Mf t i j * 0)))).
  - intros; reflexivity.
  - intros t.
    rewrite (Sum_ext M
      (fun i => 0 * Sum M (fun j => Mf t i j * x j)
         + x i * Sum M (fun j => (- sig * Mf t i j + Ev t i * Ev t j) * x j
                                 + Mf t i j * 0))
      (fun i => (- sig) * (x i * Sum M (fun j => Mf t i j * x j))
                + (Sum M (fun j => Ev t j * x j)) * (Ev t i * x i))).
    + rewrite Sum_comb. unfold MQ, EX. ring.
    + intros i Hi.
      rewrite (Sum_ext M
        (fun j => (- sig * Mf t i j + Ev t i * Ev t j) * x j + Mf t i j * 0)
        (fun j => (- sig) * (Mf t i j * x j) + (Ev t i) * (Ev t j * x j)))
        by (intros; ring).
      rewrite Sum_comb. ring.
  - apply D_Sum. intros i Hi.
    apply D_mult; [apply D_const|].
    apply D_Sum. intros j Hj.
    apply D_mult; [apply H_Mf; assumption | apply D_const].
Qed.

(* =====================================================================
   M_f is positive semi-definite for every t >= 0.

   The dissertation asserts this implicitly by writing M_f as a convolution
   integral of E^T E (4.65); with the ODE formulation it needs proof, and it
   is what makes the quadratic term of (4.69) sign definite.

   PROOF (the integrating-factor argument again).
     Hexp   -- e^{sigma t} (x^T M x) has derivative e^{sigma t} (E x)^2,
               which is >= 0 since exp > 0 and squares are >= 0.
     Hq0    -- x^T M(0) x = 0, because M(0) = 0 entrywise (H_Mf0).
     Hmono  -- therefore e^{sigma t}(x^T M x) is nondecreasing on [0,t], so
               it is at least its value at 0, namely 0.
     nra    -- divide by exp(sigma t) > 0 to conclude x^T M(t) x >= 0.  The
               division is a product of unknowns, hence nra and not lra.

     'apply (nondecr_of_nonneg_deriv _ _ Hexp); [| assumption]' — the two
     underscores are inferred; the '[| assumption]' leaves the first subgoal
     (nonnegativity of the derivative) open and closes the second (0 <= t)
     with the hypothesis Ht.
   ===================================================================== *)
Theorem Mf_psd : forall (x : nat -> R) t, 0 <= t -> 0 <= MQ x t.
Proof.
  intros x t Ht.
  assert (Hexp : Deriv (fun t => exp (sig * t) * MQ x t)
                       (fun t => exp (sig * t) * (EX x t * EX x t))).
  { apply (D_ext (fun t => exp (sig * t) * MQ x t)
                 (fun t => sig * exp (sig * t) * MQ x t
                           + exp (sig * t) * (- sig * MQ x t + EX x t * EX x t))).
    - intros; reflexivity.
    - intros; ring.
    - apply D_mult; [apply D_exp_lin | apply MQ_dyn]. }
  assert (Hq0 : MQ x 0 = 0).
  { unfold MQ. apply Sum_zero. intros i Hi.
    rewrite (Sum_zero M (fun j => Mf 0 i j * x j))
      by (intros j Hj; rewrite H_Mf0; ring). ring. }
  assert (Hmono : exp (sig * 0) * MQ x 0 <= exp (sig * t) * MQ x t).
  { apply (nondecr_of_nonneg_deriv _ _ Hexp); [| assumption].
    intros t0. apply Rmult_le_pos; [left; apply exp_pos | apply Rle_0_sqr]. }
  rewrite Hq0 in Hmono.
  assert (Hpos : 0 < exp (sig * t)) by apply exp_pos.
  nra.
Qed.

(** *** The SLAFF adaptive law (4.67) *)

(* A second alpha, obeying the SLAFF law rather than (4.52). *)
Variable alpF : R -> nat -> R.

Definition alpFt (t : R) (i : nat) : R := alpF t i - astar i.
Definition EalpF  (t : R) : R := Sum M (fun i => Ev t i * alpF t i).
Definition EalpFt (t : R) : R := Sum M (fun i => Ev t i * alpFt t i).

(* ---------------------------------------------------------------------
   qres = M_f alpha*_f + v_f, the residual that the exact form of (4.69)
   contains and the printed form omits (it writes only M_f alpha*_f).

   Both halves are needed: substituting alpha = alpha-tilde + alpha* into
   (4.67) produces M_f alpha*_f from the matrix term AND v_f from the
   accumulated forcing, and the two only combine into the intended
   convolution of e_alpha when taken together.
   --------------------------------------------------------------------- *)
Definition qres (t : R) (i : nat) : R :=
  Sum M (fun j => Mf t i j * astar j) + vf t i.

(* (4.67), componentwise. *)
Hypothesis H_slaff : forall i, (i < M)%nat ->
  Deriv (fun t => alpF t i)
        (fun t => gn * (- Sum M (fun j => Mf t i j * alpF t j)
                        - Ev t i * EalpF t - vf t i - Ev t i * eps M t)).

(* Same split as Ealp_split, for the SLAFF alpha. *)
Lemma EalpF_split : forall t, EalpF t = EalpFt t + (- eps M t + ea t / msq t).
Proof.
  intros t. unfold EalpF, EalpFt, alpFt.
  rewrite <- E_alpha_star.
  rewrite (Sum_ext M (fun i => Ev t i * (alpF t i - astar i))
                     (fun i => Ev t i * alpF t i - Ev t i * astar i))
    by (intros; ring).
  rewrite Sum_minus. ring.
Qed.

(* M_f alpha = M_f alpha-tilde + M_f alpha*, row by row.  'rewrite <-
   Sum_plus' re-assembles the two sums on the right into one so that
   Sum_ext can finish termwise.                                            *)
Lemma Mf_alpF_split : forall t i,
  Sum M (fun j => Mf t i j * alpF t j)
  = Sum M (fun j => Mf t i j * alpFt t j) + Sum M (fun j => Mf t i j * astar j).
Proof.
  intros t i. unfold alpFt.
  rewrite <- Sum_plus. apply Sum_ext. intros; ring.
Qed.

(* =====================================================================
   The SLAFF parametric-error dynamics: the correct counterpart of the step
   from (4.67) to (4.69).

       alpha-tilde-dot_i = gamma ( -(M_f alpha-tilde)_i
                                   - E_i (E alpha-tilde)
                                   - E_i e_alpha/m^2
                                   - qres_i )

   Second bullet: substitute the two splits and let ring cancel.  The eps_M
   terms cancel exactly as in alpt_dyn; what is left over is the residual
   qres, which is the term (4.69) records incompletely.

   NOTE there is deliberately no 'unfold alpFt' before the apply: unfolding
   would also expand alpFt inside the sums, after which Mf_alpF_split would
   no longer match syntactically.  D_ext's first subgoal closes by
   reflexivity anyway, since alpFt t i and alpF t i - astar i are the same
   term by definition.
   ===================================================================== *)
Theorem alpFt_dyn : forall i, (i < M)%nat ->
  Deriv (fun t => alpFt t i)
        (fun t => gn * (- Sum M (fun j => Mf t i j * alpFt t j)
                        - Ev t i * EalpFt t
                        - Ev t i * (ea t / msq t)
                        - qres t i)).
Proof.
  intros i Hi.
  apply (D_ext (fun t => alpF t i - astar i)
               (fun t => gn * (- Sum M (fun j => Mf t i j * alpF t j)
                               - Ev t i * EalpF t - vf t i - Ev t i * eps M t) - 0)).
  - intros; reflexivity.
  - intros t. rewrite EalpF_split, Mf_alpF_split. unfold qres. ring.
  - apply D_minus; [apply H_slaff; assumption | apply D_const].
Qed.

(* ---------------------------------------------------------------------
   The residual obeys  qres-dot = -sigma qres + E_i e_alpha/m^2.

   This is the identity the dissertation appeals to informally just after
   (4.69), where it evaluates the term as an integral of E^T e_alpha.  Note
   it is the residual M_f alpha* + v_f, not M_f alpha* alone, that satisfies
   this equation.

   Second bullet: Sum_comb evaluates the matrix half, E_alpha_star evaluates
   sum_j E_j alpha*_j, and the eps_M terms cancel against v_f's forcing.
   --------------------------------------------------------------------- *)
Lemma qres_dyn : forall i, (i < M)%nat ->
  Deriv (fun t => qres t i) (fun t => - sig * qres t i + Ev t i * (ea t / msq t)).
Proof.
  intros i Hi. unfold qres.
  apply (D_ext
           (fun t => Sum M (fun j => Mf t i j * astar j) + vf t i)
           (fun t => Sum M (fun j => (- sig * Mf t i j + Ev t i * Ev t j) * astar j
                                     + Mf t i j * 0)
                     + (- sig * vf t i + Ev t i * eps M t))).
  - intros; reflexivity.
  - intros t.
    rewrite (Sum_ext M
      (fun j => (- sig * Mf t i j + Ev t i * Ev t j) * astar j + Mf t i j * 0)
      (fun j => (- sig) * (Mf t i j * astar j) + (Ev t i) * (Ev t j * astar j)))
      by (intros; ring).
    rewrite Sum_comb, E_alpha_star. unfold qres. ring.
  - apply D_plus.
    + apply D_Sum. intros j Hj. apply D_mult; [apply H_Mf; assumption | apply D_const].
    + apply H_vf; assumption.
Qed.

(* =====================================================================
   When e_alpha vanishes, the residual vanishes identically.

   Combined with Mf_psd this is what makes (4.69) work.

   PROOF.  Another quad_zero, this time with unit weights: qres starts at 0
   (H_Mf0 and H_vf0), and with e_alpha = 0 its dynamics reduce to
   qres-dot = -sigma qres, so the quadratic form W = (1/2) sum qres_i^2 has
   derivative -sigma sum qres_i^2 <= 0.  Four bullets, one per hypothesis of
   quad_zero, exactly as in hull_invariance.
   ===================================================================== *)
Theorem qres_zero : (forall t, ea t = 0) ->
  forall t, 0 <= t -> forall i, (i < M)%nat -> qres t i = 0.
Proof.
  intros Hea.
  apply (quad_zero M (fun _ => 1) qres (fun t => - sig * Sum M (fun i => qres t i * qres t i))).
  - intros; lra.
  - apply (D_ext (Wq M (fun _ => 1) qres)
                 (fun t => Sum M (fun i => / 1 * (qres t i *
                    (- sig * qres t i + Ev t i * (ea t / msq t)))))).
    + intros; reflexivity.
    + intros t. rewrite (Hea t).
      rewrite (Sum_ext M
        (fun i => / 1 * (qres t i * (- sig * qres t i + Ev t i * (0 / msq t))))
        (fun i => - sig * (qres t i * qres t i)))
        by (intros; rewrite Rinv_1; unfold Rdiv; ring).
      rewrite Sum_scal_l. reflexivity.
    + apply Wq_deriv. apply qres_dyn.
  - intros t.
    assert (0 <= Sum M (fun i => qres t i * qres t i))
      by (apply Sum_nonneg; intros; apply Rle_0_sqr). nra.
  - intros i Hi. unfold qres.
    rewrite (Sum_zero M (fun j => Mf 0 i j * astar j))
      by (intros j Hj; rewrite H_Mf0; ring).
    rewrite H_vf0. ring.
Qed.

(** *** 4.68–4.69  Lyapunov analysis of SLAFF *)

(* (4.68) is the same candidate as (4.57).  We again use the reduced form. *)
Definition VrF : R -> R := Wq M (fun _ => 1) alpFt.        (* (4.68) *)

(* =====================================================================
   THE EXACT DERIVATIVE, to be compared with (4.69).

       VrF-dot = gamma ( -alpha-tilde^T M_f alpha-tilde
                         -(E alpha-tilde)^2
                         -(E alpha-tilde) e_alpha/m^2
                         -alpha-tilde^T qres )

   SECOND DISCREPANCY.  (4.69) states the same four terms but with a factor
   N on each (which does not follow, for the reason given at Vb_dyn) and with
   the last term written as -N alpha-tilde^T M_f alpha*_f rather than
   -N alpha-tilde^T (M_f alpha*_f + v_f).  The text's own justification one
   line later evaluates the term as an integral of E^T e_alpha, which is the
   value of the FULL residual qres, so the intent is right and only the
   printed expression is incomplete.

   PROOF.  Wq_deriv, then a single Sum_comb3 rewrite: the summand is
   reorganised into three pieces (matrix term, residual term, and the E term
   carrying the common scalar), each of which Sum_comb3 sums separately.
   ===================================================================== *)
Theorem VrF_dyn :
  Deriv VrF (fun t => gn * (- Sum M (fun i => alpFt t i * Sum M (fun j => Mf t i j * alpFt t j))
                            - EalpFt t * EalpFt t
                            - EalpFt t * (ea t / msq t)
                            - Sum M (fun i => alpFt t i * qres t i))).
Proof.
  unfold VrF.
  apply (D_ext (Wq M (fun _ => 1) alpFt)
               (fun t => Sum M (fun i => / 1 * (alpFt t i *
                  (gn * (- Sum M (fun j => Mf t i j * alpFt t j)
                         - Ev t i * EalpFt t
                         - Ev t i * (ea t / msq t)
                         - qres t i))))));
    [ intros; reflexivity | | apply Wq_deriv; apply alpFt_dyn ].
  intros t. set (r := ea t / msq t).
  rewrite (Sum_ext M
    (fun i => / 1 * (alpFt t i *
       (gn * (- Sum M (fun j => Mf t i j * alpFt t j)
              - Ev t i * EalpFt t - Ev t i * r - qres t i))))
    (fun i => (- gn) * (alpFt t i * Sum M (fun j => Mf t i j * alpFt t j))
              + (- gn) * (alpFt t i * qres t i)
              + (gn * (- EalpFt t - r)) * (Ev t i * alpFt t i)))
    by (intros; rewrite Rinv_1; ring).
  rewrite Sum_comb3.
  replace (Sum M (fun i => Ev t i * alpFt t i)) with (EalpFt t) by reflexivity.
  ring.
Qed.

(* =====================================================================
   THE CONCLUSION (4.69) IS AIMING AT: with e_alpha = 0 the derivative is
   negative semi-definite.

   Three ingredients, all proved above:
     qres_zero  kills the residual term (Sum_zero then makes the whole sum 0);
     Mf_psd     makes the quadratic form in M_f nonnegative, so its negative
                is <= 0;
     Rle_0_sqr  makes (E alpha-tilde)^2 nonnegative.
   'nra' then combines them with gn > 0.

   'unfold MQ in Hpsd' is needed because Mf_psd is stated in terms of the
   abbreviation MQ while the goal carries the sum written out.
   ===================================================================== *)
Theorem VrF_nonpos : (forall t, ea t = 0) ->
  forall t, 0 <= t ->
    gn * (- Sum M (fun i => alpFt t i * Sum M (fun j => Mf t i j * alpFt t j))
          - EalpFt t * EalpFt t
          - EalpFt t * (ea t / msq t)
          - Sum M (fun i => alpFt t i * qres t i)) <= 0.
Proof.
  intros Hea t Ht.
  rewrite (Hea t).
  rewrite (Sum_zero M (fun i => alpFt t i * qres t i))
    by (intros i Hi; rewrite (qres_zero Hea t Ht i Hi); ring).
  replace (0 / msq t) with 0 by (unfold Rdiv; ring).
  pose proof (Mf_psd (alpFt t) t Ht) as Hpsd. unfold MQ in Hpsd.
  pose proof (Rle_0_sqr (EalpFt t)) as Hsq. unfold Rsqr in Hsq.
  nra.
Qed.

End SLA_forgetting.

End Chapter4.
