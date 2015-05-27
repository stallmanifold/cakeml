open preamble miscLib alistTheory optionTheory rich_listTheory miscTheory
     semanticPrimitivesTheory sourcePropsTheory evalPropsTheory modLangTheory modSemTheory modPropsTheory
     source_to_modTheory

val _ = new_theory "source_to_modProof";

(* TODO: move *)

val fst_alloc_defs = Q.prove (
`!next l. MAP FST (alloc_defs next l) = l`,
 induct_on `l` >>
 rw [alloc_defs_def]);

val alloc_defs_append = Q.prove (
`!n l1 l2. alloc_defs n (l1++l2) = alloc_defs n l1 ++ alloc_defs (n + LENGTH l1) l2`,
 induct_on `l1` >>
 srw_tac [ARITH_ss] [alloc_defs_def, arithmeticTheory.ADD1]);

(* value relation *)

val (v_rel_rules, v_rel_ind, v_rel_cases) = Hol_reln `
  (!genv lit.
    v_rel genv ((Litv lit):semanticPrimitives$v) ((Litv lit):modSem$v)) ∧
  (!genv cn vs vs'.
    vs_rel genv vs vs'
    ⇒
    v_rel genv (Conv cn vs) (Conv cn vs')) ∧
  (!genv mods tops menv cenv env x e env' env_i1.
    env_rel genv env env_i1 ∧
    set (MAP FST env') DIFF set (MAP FST env) ⊆ FDOM tops ∧
    global_env_inv genv mods tops menv (set (MAP FST env_i1)) env'
    ⇒
    v_rel genv (Closure (menv,cenv,env++env') x e)
                 (Closure (cenv, env_i1) x (compile_exp mods (DRESTRICT tops (COMPL (set (MAP FST env_i1))) \\ x) e))) ∧
  (* For expression level let recs *)
  (!genv mods tops menv cenv env funs x env' env_i1.
    env_rel genv env env_i1 ∧
    set (MAP FST env') DIFF set (MAP FST env) ⊆ FDOM tops ∧
    global_env_inv genv mods tops menv (set (MAP FST env_i1)) env'
    ⇒
    v_rel genv (Recclosure (menv,cenv,env++env') funs x)
                 (Recclosure (cenv,env_i1) (compile_funs mods (DRESTRICT tops (COMPL (set (MAP FST env_i1) ∪ set (MAP FST funs)))) funs) x)) ∧
  (* For top-level let recs *)
  (!genv mods tops menv cenv env funs x y e tops'.
    set (MAP FST env) ⊆ FDOM tops ∧
    global_env_inv genv mods tops menv {} env ∧
    MAP FST (REVERSE tops') = MAP FST funs ∧
    find_recfun x funs = SOME (y,e) ∧
    (* A syntactic way of relating the recursive function environment, rather
     * than saying that they build v_rel related environments, which looks to
     * require step-indexing *)
    (!x. x ∈ set (MAP FST funs) ⇒
         ?n y e.
           FLOOKUP (FEMPTY |++ tops') x = SOME n ∧
           n < LENGTH genv ∧
           find_recfun x funs = SOME (y,e) ∧
           EL n genv = SOME (Closure (cenv,[]) y (compile_exp mods ((tops |++ tops') \\ y) e)))
    ⇒
    v_rel genv (Recclosure (menv,cenv,env) funs x)
                 (Closure (cenv,[]) y (compile_exp mods ((tops |++ tops') \\ y) e))) ∧
  (!genv loc.
    v_rel genv (Loc loc) (Loc loc)) ∧
  (!vs.
    vs_rel genv vs vs_i1
    ⇒
    v_rel genv (Vectorv vs) (Vectorv vs_i1)) ∧
  (!genv.
    vs_rel genv [] []) ∧
  (!genv v vs v' vs'.
    v_rel genv v v' ∧
    vs_rel genv vs vs'
    ⇒
    vs_rel genv (v::vs) (v'::vs')) ∧
  (!genv.
    env_rel genv [] []) ∧
  (!genv x v env env' v'.
    env_rel genv env env' ∧
    v_rel genv v v'
    ⇒
    env_rel genv ((x,v)::env) ((x,v')::env')) ∧
  (!genv map shadowers env.
    (!x v.
       x ∉ shadowers ∧
       ALOOKUP env x = SOME v
       ⇒
       ?n v_i1.
         FLOOKUP map x = SOME n ∧
         n < LENGTH genv ∧
         EL n genv = SOME v_i1 ∧
         v_rel genv v v_i1)
    ⇒
    global_env_inv_flat genv map shadowers env) ∧
  (!genv mods tops menv shadowers env.
    global_env_inv_flat genv tops shadowers env ∧
    (!mn env'.
      ALOOKUP menv mn = SOME env'
      ⇒
      ?map.
        FLOOKUP mods mn = SOME map ∧
        global_env_inv_flat genv map {} env')
    ⇒
    global_env_inv genv mods tops menv shadowers env)`;

val v_rel_eqns = Q.store_thm ("v_rel_eqns",
  `(!genv l v.
    v_rel genv (Litv l) v ⇔
      (v = Litv l)) ∧
   (!genv b v. v_rel genv (Boolv b) v ⇔ (v = Boolv b)) ∧
   (!genv cn vs v.
    v_rel genv (Conv cn vs) v ⇔
      ?vs'. vs_rel genv vs vs' ∧ (v = Conv cn vs')) ∧
   (!genv l v.
    v_rel genv (Loc l) v ⇔
      (v = Loc l)) ∧
   (!genv vs v.
    v_rel genv (Vectorv vs) v ⇔
      ?vs'. vs_rel genv vs vs' ∧ (v = Vectorv vs')) ∧
   (!genv vs.
    vs_rel genv [] vs ⇔
      (vs = [])) ∧
   (!genv l v vs vs'.
    vs_rel genv (v::vs) vs' ⇔
      ?v' vs''. v_rel genv v v' ∧ vs_rel genv vs vs'' ∧ vs' = v'::vs'') ∧
   (!genv env'.
    env_rel genv [] env' ⇔
      env' = []) ∧
   (!genv x v env env'.
    env_rel genv ((x,v)::env) env' ⇔
      ?v' env''. v_rel genv v v' ∧ env_rel genv env env'' ∧ env' = ((x,v')::env'')) ∧
   (!genv map shadowers env genv.
    global_env_inv_flat genv map shadowers env ⇔
      (!x v.
        x ∉ shadowers ∧
        ALOOKUP env x = SOME v
        ⇒
        ?n v_i1.
          FLOOKUP map x = SOME n ∧
          n < LENGTH genv ∧
          EL n genv = SOME v_i1 ∧
          v_rel genv v v_i1)) ∧
  (!genv mods tops menv shadowers env genv.
    global_env_inv genv mods tops menv shadowers env ⇔
      global_env_inv_flat genv tops shadowers env ∧
      (!mn env'.
        ALOOKUP menv mn = SOME env'
        ⇒
        ?map.
          FLOOKUP mods mn = SOME map ∧
          global_env_inv_flat genv map {} env'))`,
  rw [semanticPrimitivesTheory.Boolv_def,modSemTheory.Boolv_def] >>
  rw [Once v_rel_cases] >>
  rw [Q.SPECL[`genv`,`[]`](CONJUNCT1(CONJUNCT2 v_rel_cases))] >>
  metis_tac []);

val vs_rel_list_rel = Q.prove (
  `!genv vs vs'. vs_rel genv vs vs' = LIST_REL (v_rel genv) vs vs'`,
   induct_on `vs` >>
   rw [v_rel_eqns] >>
   metis_tac []);

val vs_rel_append1 = Q.prove (
  `!genv vs v vs' v'.
    vs_rel genv (vs++[v]) (vs'++[v'])
    ⇔
    vs_rel genv vs vs' ∧
    v_rel genv v v'`,
  induct_on `vs` >>
  rw [] >>
  cases_on `vs'` >>
  rw [v_rel_eqns]
  >- (cases_on `vs` >>
      rw [v_rel_eqns]) >>
  metis_tac []);

val length_vs_rel = Q.prove (
  `!vs genv vs'.
    vs_rel genv vs vs'
    ⇒
    LENGTH vs = LENGTH vs'`,
  metis_tac[vs_rel_list_rel,LIST_REL_LENGTH])

val env_rel_dom = Q.prove (
  `!genv env env_i1.
    env_rel genv env env_i1
    ⇒
    MAP FST env = MAP FST env_i1`,
  induct_on `env` >>
  rw [v_rel_eqns] >>
  PairCases_on `h` >>
  fs [v_rel_eqns] >>
  rw [] >>
  metis_tac []);

val env_rel_lookup = Q.prove (
  `!genv menv env genv x v env'.
    ALOOKUP env x = SOME v ∧
    env_rel genv env env'
    ⇒
    ?v'.
      v_rel genv v v' ∧
      ALOOKUP env' x = SOME v'`,
  induct_on `env` >>
  rw [] >>
  PairCases_on `h` >>
  fs [] >>
  cases_on `h0 = x` >>
  fs [] >>
  rw [] >>
  fs [v_rel_eqns]);

val env_rel_append = Q.prove (
  `!genv env1 env2 env1' env2'.
    env_rel genv env1 env1' ∧
    env_rel genv env2 env2'
    ⇒
    env_rel genv (env1++env2) (env1'++env2')`,
   induct_on `env1` >>
   rw [v_rel_eqns] >>
   PairCases_on `h` >>
   fs [v_rel_eqns]);

val env_rel_reverse = Q.prove (
  `!genv env1 env2.
    env_rel genv env1 env2
    ⇒
    env_rel genv (REVERSE env1) (REVERSE env2)`,
   induct_on `env1` >>
   rw [v_rel_eqns] >>
   PairCases_on `h` >>
   fs [v_rel_eqns] >>
   match_mp_tac env_rel_append >>
   rw [v_rel_eqns]);

val length_env_rel = Q.prove (
  `!env genv env'.
    env_rel genv env env'
    ⇒
    LENGTH env = LENGTH env'`,
  induct_on `env` >>
  rw [v_rel_eqns] >>
  PairCases_on `h` >>
  fs [v_rel_eqns] >>
  metis_tac []);

val v_rel_weakening = Q.prove (
  `(!genv v v_i1.
    v_rel genv v v_i1
    ⇒
    ∀l. v_rel (genv++l) v v_i1) ∧
   (!genv vs vs_i1.
    vs_rel genv vs vs_i1
    ⇒
    !l. vs_rel (genv++l) vs vs_i1) ∧
   (!genv env env_i1.
    env_rel genv env env_i1
    ⇒
    !l. env_rel (genv++l) env env_i1) ∧
   (!genv map shadowers env.
    global_env_inv_flat genv map shadowers env
    ⇒
    !l. global_env_inv_flat (genv++l) map shadowers env) ∧
   (!genv mods tops menv shadowers env.
    global_env_inv genv mods tops menv shadowers env
    ⇒
    !l.global_env_inv (genv++l) mods tops menv shadowers env)`,
  ho_match_mp_tac v_rel_ind >>
  rw [v_rel_eqns]
  >- (rw [Once v_rel_cases] >>
      MAP_EVERY qexists_tac [`mods`, `tops`, `env`, `env'`] >>
      fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_rel_eqns])
  >- (rw [Once v_rel_cases] >>
      MAP_EVERY qexists_tac [`mods`, `tops`, `env`, `env'`] >>
      fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_rel_eqns])
  >- (rw [Once v_rel_cases] >>
      MAP_EVERY qexists_tac [`mods`, `tops`, `tops'`] >>
      fs [FDOM_FUPDATE_LIST, SUBSET_DEF, v_rel_eqns, EL_APPEND1] >>
      rw [] >>
      res_tac >>
      qexists_tac `n` >>
      rw [EL_APPEND1] >>
      decide_tac)
  >- metis_tac [DECIDE ``x < y ⇒ x < y + l:num``, EL_APPEND1]
  >- metis_tac []);

val (result_rel_rules, result_rel_ind, result_rel_cases) = Hol_reln `
  (∀genv v v'.
    f genv v v'
    ⇒
    result_rel f genv (Rval v) (Rval v')) ∧
  (∀genv v v'.
    v_rel genv v v'
    ⇒
    result_rel f genv (Rerr (Rraise v)) (Rerr (Rraise v'))) ∧
  (!genv a.
    result_rel f genv (Rerr (Rabort a)) (Rerr (Rabort a)))`;

val result_rel_eqns = Q.prove (
  `(!genv v r.
    result_rel f genv (Rval v) r ⇔
      ?v'. f genv v v' ∧ r = Rval v') ∧
   (!genv v r.
    result_rel f genv (Rerr (Rraise v)) r ⇔
      ?v'. v_rel genv v v' ∧ r = Rerr (Rraise v')) ∧
   (!genv v r a.
    result_rel f genv (Rerr (Rabort a)) r ⇔
      r = Rerr (Rabort a))`,
  rw [result_rel_cases] >>
  metis_tac []);

val (sv_rel_rules, sv_rel_ind, sv_rel_cases) = Hol_reln `
  (!genv v v'.
    v_rel genv v v'
    ⇒
    sv_rel genv (Refv v) (Refv v')) ∧
  (!genv w.
    sv_rel genv (W8array w) (W8array w)) ∧
  (!genv vs vs'.
    vs_rel genv vs vs'
    ⇒
    sv_rel genv (Varray vs) (Varray vs'))`;

val sv_rel_weakening = Q.prove (
  `(!genv sv sv_i1.
    sv_rel genv sv sv_i1
    ⇒
    ∀l. sv_rel (genv++l) sv sv_i1)`,
   rw [sv_rel_cases] >>
   metis_tac [v_rel_weakening]);

val (s_rel_rules, s_rel_ind, s_rel_cases) = Hol_reln `
  (!genv c s s'.
    LIST_REL (sv_rel genv) s s'
    ⇒
    s_rel genv (c,s,t) (c,s',t))`;

val (env_all_rel_rules, env_all_rel_ind, env_all_rel_cases) = Hol_reln `
  (!genv mods tops menv cenv env env' env_i1 locals.
    locals = set (MAP FST env) ∧
    global_env_inv genv mods tops menv locals env' ∧
    env_rel genv env env_i1
    ⇒
    env_all_rel genv mods tops (menv,cenv,env++env') (genv,cenv,env_i1) locals)`;

val match_result_rel_def = Define
  `(match_result_rel genv env' (Match env) (Match env_i1) =
     ?env''. env = env'' ++ env' ∧ env_rel genv env'' env_i1) ∧
   (match_result_rel genv env' No_match No_match = T) ∧
   (match_result_rel genv env' Match_type_error Match_type_error = T) ∧
   (match_result_rel genv env' _ _ = F)`;

(* semantic functions respect relation *)

val do_eq = Q.prove (
  `(!v1 v2 genv r v1_i1 v2_i1.
    do_eq v1 v2 = r ∧
    v_rel genv v1 v1_i1 ∧
    v_rel genv v2 v2_i1
    ⇒
    do_eq v1_i1 v2_i1 = r) ∧
   (!vs1 vs2 genv r vs1_i1 vs2_i1.
    do_eq_list vs1 vs2 = r ∧
    vs_rel genv vs1 vs1_i1 ∧
    vs_rel genv vs2 vs2_i1
    ⇒
    do_eq_list vs1_i1 vs2_i1 = r)`,
  ho_match_mp_tac terminationTheory.do_eq_ind >>
  rw [terminationTheory.do_eq_def, modSemTheory.do_eq_def, v_rel_eqns] >>
  rw [] >>
  rw [terminationTheory.do_eq_def, modSemTheory.do_eq_def, v_rel_eqns] >>
  imp_res_tac length_vs_rel >>
  fs []
  >- metis_tac []
  >- (rpt (qpat_assum `vs_rel env vs x0` (mp_tac o SIMP_RULE (srw_ss()) [Once v_rel_cases])) >>
      rw [] >>
      fs [vs_rel_list_rel, terminationTheory.do_eq_def, modSemTheory.do_eq_def] >>
      res_tac >>
      fs [modSemTheory.do_eq_def])
  >> TRY (
    CASE_TAC >>
    res_tac >>
    every_case_tac >>
    fs [] >>
    metis_tac []) >>
  fs [Once v_rel_cases] >>
  rw [modSemTheory.do_eq_def] );

val do_con_check = Q.prove (
  `!genv mods tops env cn es env_i1 locals.
    do_con_check (all_env_to_cenv env) cn (LENGTH es) ∧
    env_all_rel genv mods tops env env_i1 locals
    ⇒
    do_con_check (all_env_to_cenv env_i1) cn (LENGTH (compile_exps mods (DRESTRICT tops (COMPL locals)) es))`,
  rw [do_con_check_def] >>
  every_case_tac >>
  fs [env_all_rel_cases] >>
  rw [] >>
  fs [semanticPrimitivesTheory.all_env_to_cenv_def, modSemTheory.all_env_to_cenv_def] >>
  rw [] >>
  ntac 3 (pop_assum (fn _ => all_tac)) >>
  induct_on `es` >>
  rw [compile_exp_def]);

val char_list_to_v = prove(
  ``∀ls. v_rel genv (char_list_to_v ls) (char_list_to_v ls)``,
  Induct >> simp[semanticPrimitivesTheory.char_list_to_v_def,
                 modSemTheory.char_list_to_v_def,
                 v_rel_eqns])

val v_to_char_list = Q.prove (
  `!v1 v2 vs1.
    v_rel genv v1 v2 ∧
    v_to_char_list v1 = SOME vs1
    ⇒
    v_to_char_list v2 = SOME vs1`,
  ho_match_mp_tac terminationTheory.v_to_char_list_ind >>
  rw [terminationTheory.v_to_char_list_def] >>
  every_case_tac >>
  fs [v_rel_eqns, modSemTheory.v_to_char_list_def]);

val v_to_list = Q.prove (
  `!v1 v2 vs1.
    v_rel genv v1 v2 ∧
    v_to_list v1 = SOME vs1
    ⇒
    ?vs2.
      v_to_list v2 = SOME vs2 ∧
      vs_rel genv vs1 vs2`,
  ho_match_mp_tac terminationTheory.v_to_list_ind >>
  rw [terminationTheory.v_to_list_def] >>
  every_case_tac >>
  fs [v_rel_eqns, modSemTheory.v_to_list_def] >>
  rw [] >>
  every_case_tac >>
  fs [v_rel_eqns, modSemTheory.v_to_list_def] >>
  rw [] >>
  metis_tac [NOT_SOME_NONE, SOME_11]);

val do_app = Q.prove (
  `!genv s1 s2 op vs r s1_i1 vs_i1.
    do_app s1 op vs = SOME (s2, r) ∧
    LIST_REL (sv_rel genv) (FST s1) (FST s1_i1) ∧
    SND s1 = SND s1_i1 ∧
    vs_rel genv vs vs_i1
    ⇒
     ∃r_i1 s2_i1.
       LIST_REL (sv_rel genv) (FST s2) (FST s2_i1) ∧
       SND s2 = SND s2_i1 ∧
       result_rel v_rel genv r r_i1 ∧
       do_app s1_i1 op vs_i1 = SOME (s2_i1, r_i1)`,
  rpt gen_tac >>
  Cases_on `s1` >>
  Cases_on `s1_i1` >>
  Cases_on `op`
  >- ((* Opn *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Opb *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Equality *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      every_case_tac >>
      fs [] >>
      metis_tac [Boolv_11, do_eq, eq_result_11, eq_result_distinct])
  >- ((* Opapp *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Opassign *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_assign_def,store_v_same_type_def] >>
      every_case_tac >> fs[] >-
      metis_tac [EVERY2_LUPDATE_same, sv_rel_rules] >>
      fs[LIST_REL_EL_EQN,sv_rel_cases] >>
      rw[] >> rfs[] >> res_tac >> fs[])
  >- ((* Opref *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_alloc_def] >>
      rw [sv_rel_cases] >>
      metis_tac [LIST_REL_LENGTH])
  >- ((* Opderef *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def] >>
      imp_res_tac LIST_REL_LENGTH >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      rw [] >>
      fs [] >>
      rw [])
  >- ((* Aw8alloc *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_alloc_def] >>
      rw [sv_rel_cases] >>
      metis_tac [LIST_REL_LENGTH])
  >- ((* Aw8sub *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def] >>
      imp_res_tac LIST_REL_LENGTH >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      rw [] >>
      fs [] >>
      rw [markerTheory.Abbrev_def])
  >- ((* Aw8length *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def] >>
      imp_res_tac LIST_REL_LENGTH >>
      rw [] >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      rw [] >>
      fs [] >>
      rw [markerTheory.Abbrev_def])
  >- ((* Aw8update *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def, store_assign_def, store_v_same_type_def] >>
      imp_res_tac LIST_REL_LENGTH >>
      rw [] >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      rw [] >>
      fs [] >>
      rw [markerTheory.Abbrev_def, EL_LUPDATE] >>
      rw [])
  >- ((* Ord *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Chr *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Chopb *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* Explode *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      simp[char_list_to_v])
  >- ((* Implode *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      imp_res_tac v_to_char_list >>
      rw [])
  >- ((* Strlen *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def])
  >- ((* VfromList *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      imp_res_tac v_to_list >>
      rw [])
  >- ((* Vsub *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      rw [markerTheory.Abbrev_def] >>
      rw [markerTheory.Abbrev_def] >>
      fs [vs_rel_list_rel] >>
      imp_res_tac LIST_REL_LENGTH >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      fs [arithmeticTheory.NOT_GREATER_EQ, GSYM arithmeticTheory.LESS_EQ])
  >- ((* Vlength *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      rw [] >>
      metis_tac [LIST_REL_LENGTH, vs_rel_list_rel])
  >- ((* Aalloc *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_alloc_def] >>
      rw [sv_rel_cases, vs_rel_list_rel, LIST_REL_REPLICATE_same] >>
      metis_tac [LIST_REL_LENGTH])
  >- ((* Asub *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def] >>
      rw [] >>
      fs [vs_rel_list_rel] >>
      imp_res_tac LIST_REL_LENGTH >>
      fs [LET_THM, arithmeticTheory.NOT_GREATER_EQ, GSYM arithmeticTheory.LESS_EQ] >>
      every_case_tac >>
      fs [] >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      fs [] >>
      rw [] >>
      fs [vs_rel_list_rel] >>
      imp_res_tac LIST_REL_LENGTH >>
      fs [LIST_REL_EL_EQN] >>
      decide_tac)
  >- ((* Alength *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      rw [] >>
      fs [store_lookup_def, sv_rel_cases] >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN] >>
      res_tac >>
      fs [sv_rel_cases] >>
      metis_tac [store_v_distinct, store_v_11, LIST_REL_LENGTH, vs_rel_list_rel])
  >- ((* Aupdate *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def, store_assign_def, store_v_same_type_def] >>
      rw [] >>
      fs [vs_rel_list_rel] >>
      imp_res_tac LIST_REL_LENGTH >>
      fs [LET_THM, arithmeticTheory.NOT_GREATER_EQ, GSYM arithmeticTheory.LESS_EQ] >>
      every_case_tac >>
      fs [] >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      fs [] >>
      rw [] >>
      fs [vs_rel_list_rel] >>
      imp_res_tac LIST_REL_LENGTH >>
      fs [LIST_REL_EL_EQN] >>
      rw [markerTheory.Abbrev_def, EL_LUPDATE] >>
      rw [] >>
      decide_tac)
  >- ((* FFI *)
      rw [evalPropsTheory.do_app_cases, modSemTheory.do_app_def, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [v_rel_eqns, result_rel_cases, semanticPrimitivesTheory.prim_exn_def, modSemTheory.prim_exn_def] >>
      fs [store_lookup_def, store_assign_def, store_v_same_type_def] >>
      imp_res_tac LIST_REL_LENGTH >>
      rw [] >>
      every_case_tac >>
      fs [LIST_REL_EL_EQN, sv_rel_cases] >>
      res_tac >>
      rw [] >>
      fs [] >>
      rw [markerTheory.Abbrev_def, EL_LUPDATE] >>
      rw [] >>
      fs []));

val find_recfun = Q.prove (
  `!x funs e mods tops y.
    find_recfun x funs = SOME (y,e)
    ⇒
    find_recfun x (compile_funs mods tops funs) = SOME (y,compile_exp mods (tops \\ y) e)`,
   induct_on `funs` >>
   rw [Once find_recfun_def, compile_exp_def] >>
   PairCases_on `h` >>
   fs [] >>
   every_case_tac >>
   fs [Once find_recfun_def, compile_exp_def]);

val do_app_rec_help = Q.prove (
  `!genv menv'' cenv'' env' funs env''' env_i1' mods' tops' funs'.
    env_rel genv env' env_i1' ∧
    set (MAP FST env''') DIFF set (MAP FST env') ⊆ FDOM tops' ∧
    global_env_inv genv mods' tops' menv'' (set (MAP FST env_i1')) env'''
    ⇒
    env_rel genv
    (MAP
       (λ(fn,n,e). (fn,Recclosure (menv'',cenv'',env' ++ env''') funs' fn))
       funs)
    (MAP
       (λ(fn,n,e).
          (fn,
           Recclosure (cenv'',env_i1')
             (compile_funs mods'
                (DRESTRICT tops'
                   (COMPL (set (MAP FST env_i1') ∪ set (MAP FST funs'))))
                funs') fn))
       (compile_funs mods'
          (DRESTRICT tops'
             (COMPL (set (MAP FST env_i1') ∪ set (MAP FST funs')))) funs))`,
  induct_on `funs` >>
  rw [v_rel_eqns, compile_exp_def] >>
  PairCases_on `h` >>
  rw [v_rel_eqns, compile_exp_def] >>
  rw [Once v_rel_cases] >>
  MAP_EVERY qexists_tac [`mods'`, `tops'`, `env'`, `env'''`] >>
  rw [] >>
  fs [v_rel_eqns]);

val global_env_inv_add_locals = Q.prove (
  `!genv mods tops menv locals1 locals2 env.
    global_env_inv genv mods tops menv locals1 env
    ⇒
    global_env_inv genv mods tops menv (locals2 ∪ locals1) env`,
  rw [v_rel_eqns]);

val global_env_inv_extend2 = Q.prove (
  `!genv mods tops menv env tops' env' locals.
    MAP FST env' = REVERSE (MAP FST tops') ∧
    global_env_inv genv mods tops menv locals env ∧
    global_env_inv genv FEMPTY (FEMPTY |++ tops') [] locals env'
    ⇒
    global_env_inv genv mods (tops |++ tops') menv locals (env'++env)`,
  rw [v_rel_eqns, flookup_fupdate_list] >>
  full_case_tac >>
  fs [ALOOKUP_APPEND] >>
  full_case_tac >>
  fs [] >>
  res_tac >>
  fs [] >>
  rpt (pop_assum mp_tac) >>
  rw [] >>
  fs [ALOOKUP_FAILS] >>
  imp_res_tac ALOOKUP_MEM >>
  `set (MAP FST env') = set (REVERSE (MAP FST tops'))` by metis_tac [] >>
  fs [EXTENSION] >>
  metis_tac [pair_CASES, MEM_MAP, FST]);

val lookup_build_rec_env_lem = Q.prove (
  `!x cl_env funs' funs.
    ALOOKUP (MAP (λ(fn,n,e). (fn,Recclosure cl_env funs' fn)) funs) x = SOME v
    ⇒
    v = semanticPrimitives$Recclosure cl_env funs' x`,
  induct_on `funs` >>
  rw [] >>
  PairCases_on `h` >>
  fs [] >>
  every_case_tac >>
  fs []);

val do_opapp = Q.prove (
  `!genv vs vs_i1 env e.
    do_opapp vs = SOME (env, e) ∧
    vs_rel genv vs vs_i1
    ⇒
     ∃mods tops env_i1 locals.
       env_all_rel genv mods tops env env_i1 locals ∧
       do_opapp genv vs_i1 = SOME (env_i1, compile_exp mods (DRESTRICT tops (COMPL locals)) e)`,
   rw [do_opapp_cases, modSemTheory.do_opapp_def, vs_rel_list_rel] >>
   fs [LIST_REL_CONS1] >>
   rw []
   >- (qpat_assum `v_rel genv (Closure (menv'',cenv'',env'') n e) v1_i1` mp_tac >>
       rw [Once v_rel_cases] >>
       rw [] >>
       MAP_EVERY qexists_tac [`mods`, `tops`, `n INSERT set (MAP FST env_i1)`] >>
       rw [DRESTRICT_DOMSUB, compl_insert, env_all_rel_cases] >>
       MAP_EVERY qexists_tac [`(n, v2) :: env`, `env'`] >>
       rw [v_rel_eqns]
       >- metis_tac [env_rel_dom] >>
       fs [v_rel_eqns])
   >- (qpat_assum `v_rel genv (Recclosure (menv'',cenv'',env'') funs n') v1_i1` mp_tac >>
       rw [Once v_rel_cases] >>
       rw [] >>
       imp_res_tac find_recfun >>
       rw []
       >- (MAP_EVERY qexists_tac [`mods`, `tops`, `n'' INSERT set (MAP FST env_i1) ∪ set (MAP FST funs)`] >>
           rw [DRESTRICT_DOMSUB, compl_insert, env_all_rel_cases] >>
           rw []
           >- (MAP_EVERY qexists_tac [`(n'', v2)::build_rec_env funs (menv'',cenv'',env ++ env') env`, `env'`] >>
               rw [evalPropsTheory.build_rec_env_merge, EXTENSION]
               >- (rw [MEM_MAP, EXISTS_PROD] >>
                   imp_res_tac env_rel_dom >>
                   metis_tac [pair_CASES, FST, MEM_MAP, EXISTS_PROD, LAMBDA_PROD])
               >- metis_tac [INSERT_SING_UNION, global_env_inv_add_locals, UNION_COMM]
               >- (fs [v_rel_eqns, build_rec_env_merge] >>
                   match_mp_tac env_rel_append >>
                   rw [] >>
                   match_mp_tac do_app_rec_help >>
                   rw [] >>
                   fs [v_rel_eqns]))
           >- (
            simp[compile_funs_map,MAP_MAP_o,combinTheory.o_DEF,UNCURRY,ETA_AX] >>
            fs[FST_triple]))
       >- (MAP_EVERY qexists_tac [`mods`, `tops|++tops'`, `{n''}`] >>
           rw [DRESTRICT_UNIV, GSYM DRESTRICT_DOMSUB, compl_insert, env_all_rel_cases] >>
           MAP_EVERY qexists_tac [`[(n'',v2)]`, `build_rec_env funs (menv'',cenv'',env'') env''`] >>
           rw [evalPropsTheory.build_rec_env_merge, EXTENSION]
           >- (match_mp_tac global_env_inv_extend2 >>
               rw [MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, FST_triple, GSYM MAP_REVERSE]
               >- metis_tac [global_env_inv_add_locals, UNION_EMPTY] >>
               rw [v_rel_eqns] >>
               `MEM x (MAP FST funs)`
                         by (imp_res_tac ALOOKUP_MEM >>
                             fs [MEM_MAP] >>
                             PairCases_on `y` >>
                             rw [] >>
                             fs [] >>
                             metis_tac [FST, MEM_MAP, pair_CASES]) >>
               res_tac >>
               qexists_tac `n` >>
               rw [] >>
               `v = Recclosure (menv'',cenv'',env'') funs x` by metis_tac [lookup_build_rec_env_lem] >>
               rw [Once v_rel_cases] >>
               MAP_EVERY qexists_tac [`mods`, `tops`, `tops'`] >>
               rw [find_recfun_ALOOKUP])
           >- fs [v_rel_eqns, modPropsTheory.build_rec_env_merge])));

val build_conv = Q.prove (
  `!genv mods tops env cn vs v vs' env_i1 locals.
    (build_conv (all_env_to_cenv env) cn vs = SOME v) ∧
    env_all_rel genv mods tops env env_i1 locals ∧
    vs_rel genv vs vs'
    ⇒
    ∃v'.
      v_rel genv v v' ∧
      build_conv (all_env_to_cenv env_i1) cn vs' = SOME v'`,
  rw [semanticPrimitivesTheory.build_conv_def, modSemTheory.build_conv_def] >>
  every_case_tac >>
  rw [Once v_rel_cases] >>
  fs [env_all_rel_cases] >>
  rw [] >>
  fs [semanticPrimitivesTheory.all_env_to_cenv_def, modSemTheory.all_env_to_cenv_def]);

val pmatch = Q.prove (
  `(!cenv s p v env r env' env'' genv env_i1 s_i1 v_i1.
    pmatch cenv s p v env = r ∧
    env = env' ++ env'' ∧
    LIST_REL (sv_rel genv) s s_i1 ∧
    v_rel genv v v_i1 ∧
    env_rel genv env' env_i1
    ⇒
    ?r_i1.
      pmatch cenv s_i1 p v_i1 env_i1 = r_i1 ∧
      match_result_rel genv env'' r r_i1) ∧
   (!cenv s ps vs env r env' env'' genv env_i1 s_i1 vs_i1.
    pmatch_list cenv s ps vs env = r ∧
    env = env' ++ env'' ∧
    LIST_REL (sv_rel genv) s s_i1 ∧
    vs_rel genv vs vs_i1 ∧
    env_rel genv env' env_i1
    ⇒
    ?r_i1.
      pmatch_list cenv s_i1 ps vs_i1 env_i1 = r_i1 ∧
      match_result_rel genv env'' r r_i1)`,
  ho_match_mp_tac terminationTheory.pmatch_ind >>
  rw [terminationTheory.pmatch_def, modSemTheory.pmatch_def] >>
  fs [match_result_rel_def, modSemTheory.pmatch_def, v_rel_eqns] >>
  imp_res_tac LIST_REL_LENGTH
  >- (every_case_tac >>
      fs [match_result_rel_def])
  >- (every_case_tac >>
      fs [match_result_rel_def] >>
      metis_tac [length_vs_rel])
  >- (every_case_tac >>
      fs [match_result_rel_def]
      >- (fs [store_lookup_def] >>
          metis_tac [])
      >- (fs [store_lookup_def] >>
          metis_tac [length_vs_rel])
      >- (FIRST_X_ASSUM match_mp_tac >>
          rw [] >>
          fs [store_lookup_def, LIST_REL_EL_EQN, sv_rel_cases] >>
          res_tac >>
          fs [] >>
          rw [])
      >> (fs [store_lookup_def, LIST_REL_EL_EQN] >>
          rw [] >>
          fs [sv_rel_cases] >>
          res_tac >>
          fs []))
  >> TRY (
      CASE_TAC >>
      every_case_tac >>
      fs [match_result_rel_def] >>
      rw [] >>
      pop_assum mp_tac >>
      pop_assum mp_tac >>
      res_tac >>
      rw [] >>
      CCONTR_TAC >>
      fs [match_result_rel_def] >>
      metis_tac [match_result_rel_def, match_result_distinct]) >>
  fs [Once v_rel_cases] >>
  rw [modSemTheory.pmatch_def, match_result_rel_def]);

(* compiler correctness *)

val global_env_inv_lookup_top = Q.prove (
  `!genv mods tops menv shadowers env x v n.
    global_env_inv genv mods tops menv shadowers env ∧
    ALOOKUP env x = SOME v ∧
    x ∉ shadowers ∧
    FLOOKUP tops x = SOME n
    ⇒
    ?v_i1. LENGTH genv > n ∧ EL n genv = SOME v_i1 ∧ v_rel genv v v_i1`,
  rw [v_rel_eqns] >>
  res_tac >>
  full_simp_tac (srw_ss()++ARITH_ss) [] >>
  metis_tac []);

val global_env_inv_lookup_mod1 = Q.prove (
  `!genv mods tops menv shadowers env genv mn n env'.
    global_env_inv genv mods tops menv shadowers env ∧
    ALOOKUP menv mn = SOME env'
    ⇒
    ?n. FLOOKUP mods mn = SOME n`,
  rw [] >>
  fs [v_rel_eqns] >>
  metis_tac []);

val global_env_inv_lookup_mod2 = Q.prove (
  `!genv mods tops menv shadowers env genv mn n env' x v map.
    global_env_inv genv mods tops menv shadowers env ∧
    ALOOKUP menv mn = SOME env' ∧
    ALOOKUP env' x = SOME v ∧
    FLOOKUP mods mn = SOME map
    ⇒
    ?n. FLOOKUP map x = SOME n`,
  rw [] >>
  fs [v_rel_eqns] >>
  res_tac >>
  fs [] >>
  rw [] >>
  res_tac >>
  fs []);

val global_env_inv_lookup_mod3 = Q.prove (
  `!genv mods tops menv shadowers env genv mn n env' x v map n.
    global_env_inv genv mods tops menv shadowers env ∧
    ALOOKUP menv mn = SOME env' ∧
    ALOOKUP env' x = SOME v ∧
    FLOOKUP mods mn = SOME map ∧
    FLOOKUP map x = SOME n
    ⇒
    LENGTH genv > n ∧ ?v_i1. EL n genv = SOME v_i1 ∧ v_rel genv v v_i1`,
  rw [] >>
  fs [v_rel_eqns] >>
  res_tac >>
  fs [] >>
  rw [] >>
  res_tac >>
  full_simp_tac (srw_ss()++ARITH_ss) [] >>
  metis_tac []);

val compile_exp_correct = Q.prove (
  `(∀b env s e res.
     evaluate b env s e res ⇒
     (SND res ≠ Rerr (Rabort Rtype_error)) ⇒
     !genv mods tops s' r env_i1 s_i1 e_i1 locals.
       (res = (s',r)) ∧
       env_all_rel genv mods tops env env_i1 locals ∧
       s_rel genv s s_i1 ∧
       (e_i1 = compile_exp mods (DRESTRICT tops (COMPL locals)) e)
       ⇒
       ∃s'_i1 r_i1.
         result_rel v_rel genv r r_i1 ∧
         s_rel genv s' s'_i1 ∧
         evaluate b env_i1 s_i1 e_i1 (s'_i1, r_i1)) ∧
   (∀b env s es res.
     evaluate_list b env s es res ⇒
     (SND res ≠ Rerr (Rabort Rtype_error)) ⇒
     !genv mods tops s' r env_i1 s_i1 es_i1 locals.
       (res = (s',r)) ∧
       env_all_rel genv mods tops env env_i1 locals ∧
       s_rel genv s s_i1 ∧
       (es_i1 = compile_exps mods (DRESTRICT tops (COMPL locals)) es)
       ⇒
       ?s'_i1 r_i1.
         result_rel vs_rel genv r r_i1 ∧
         s_rel genv s' s'_i1 ∧
         evaluate_list b env_i1 s_i1 es_i1 (s'_i1, r_i1)) ∧
   (∀b env s v pes err_v res.
     evaluate_match b env s v pes err_v res ⇒
     (SND res ≠ Rerr (Rabort Rtype_error)) ⇒
     !genv mods tops s' r env_i1 s_i1 v_i1 pes_i1 err_v_i1 locals.
       (res = (s',r)) ∧
       env_all_rel genv mods tops env env_i1 locals ∧
       s_rel genv s s_i1 ∧
       v_rel genv v v_i1 ∧
       (pes_i1 = compile_pes mods (DRESTRICT tops (COMPL locals)) pes) ∧
       v_rel genv err_v err_v_i1
       ⇒
       ?s'_i1 r_i1.
         result_rel v_rel genv r r_i1 ∧
         s_rel genv s' s'_i1 ∧
         evaluate_match b env_i1 s_i1 v_i1 pes_i1 err_v_i1 (s'_i1, r_i1))`,
  ho_match_mp_tac bigStepTheory.evaluate_ind >>
  rw [] >>
  rw [Once modSemTheory.evaluate_cases,compile_exp_def] >>
  TRY (Cases_on `err`) >>
  fs [result_rel_eqns, v_rel_eqns]
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- metis_tac [build_conv, do_con_check, EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse]
  >- ((* TODO bug in metis, #259 *)res_tac >> srw_tac[boolSimps.DNF_ss][] >>
      rpt(first_assum(match_exists_tac o concl) >> simp[]) >> (* -- *)
      metis_tac [do_con_check, EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- metis_tac [do_con_check, EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse]
  >- (* Variable lookup *)
     (fs [env_all_rel_cases] >>
      cases_on `n` >>
      rw [compile_exp_def] >>
      fs [lookup_var_id_def] >>
      every_case_tac >>
      fs [ALOOKUP_APPEND, modSemTheory.all_env_to_env_def, modSemTheory.all_env_to_genv_def] >>
      rw []
      >- (every_case_tac >>
          fs []
          >- (fs [v_rel_eqns, FLOOKUP_DRESTRICT] >>
              every_case_tac >>
              fs [ALOOKUP_FAILS] >>
              res_tac >>
              every_case_tac >>
              fs [MEM_MAP] >>
              metis_tac [pair_CASES, FST, NOT_SOME_NONE])
          >- metis_tac [env_rel_lookup])
      >- (every_case_tac >>
          fs [FLOOKUP_DRESTRICT]
          >- metis_tac [global_env_inv_lookup_top] >>
          imp_res_tac ALOOKUP_MEM >>
          fs [MEM_MAP] >>
          metis_tac [pair_CASES, FST, NOT_SOME_NONE])
      >- metis_tac [NOT_SOME_NONE, global_env_inv_lookup_mod1]
      >- metis_tac [NOT_SOME_NONE, global_env_inv_lookup_mod2]
      >- metis_tac [global_env_inv_lookup_mod3])
  >- (* Closure creation *)
     (rw [Once v_rel_cases] >>
      fs [env_all_rel_cases, modSemTheory.all_env_to_cenv_def, modSemTheory.all_env_to_env_def] >>
      rw [] >>
      MAP_EVERY qexists_tac [`mods`, `tops`, `env'`, `env''`] >>
      imp_res_tac env_rel_dom >>
      rw []
      >- (fs [SUBSET_DEF, v_rel_eqns] >>
          rw [] >>
          `¬(ALOOKUP env'' x = NONE)` by metis_tac [ALOOKUP_FAILS, MEM_MAP, FST, pair_CASES] >>
          cases_on `ALOOKUP env'' x` >>
          fs [] >>
          res_tac >>
          fs [FLOOKUP_DEF])
      >- (imp_res_tac global_env_inv_lookup_top >>
          fs [] >>
          imp_res_tac disjoint_drestrict >>
          rw []))
  >- (* function application *)
     (srw_tac [boolSimps.DNF_ss] [PULL_EXISTS] >>
      res_tac >>
      rw [] >>
      LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
      rw [] >>
      fs [s_rel_cases] >>
      rw [] >>
      imp_res_tac do_opapp >>
      rw [] >>
      `genv = all_env_to_genv env_i1`
                 by fs [modSemTheory.all_env_to_genv_def, env_all_rel_cases] >>
      fs [] >>
      metis_tac [EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- (* function application *)
     (srw_tac [boolSimps.DNF_ss] [PULL_EXISTS] >>
      res_tac >>
      rw [] >>
      LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
      rw [] >>
      fs [s_rel_cases] >>
      rw [] >>
      imp_res_tac do_opapp >>
      rw [] >>
      `genv = all_env_to_genv env_i1`
                 by fs [modSemTheory.all_env_to_genv_def, env_all_rel_cases] >>
      fs [] >>
      metis_tac [EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- (* function application *)
     (srw_tac [boolSimps.DNF_ss] [PULL_EXISTS] >>
      res_tac >>
      rw [] >>
      LAST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env_i1`, `s_i1`, `locals`] mp_tac) >>
      rw [] >>
      fs [s_rel_cases] >>
      rw [] >>
      imp_res_tac do_opapp >>
      rw [] >>
      `genv = all_env_to_genv env_i1`
                 by fs [modSemTheory.all_env_to_genv_def, env_all_rel_cases] >>
      fs [] >>
      metis_tac [EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- (* primitive application *)
     (srw_tac [boolSimps.DNF_ss] [PULL_EXISTS] >>
      res_tac >>
      rw [] >>
      first_assum (fn th => assume_tac (MATCH_MP (SIMP_RULE (srw_ss()) [GSYM AND_IMP_INTRO] do_app) th)) >>
      rfs [s_rel_cases] >>
      pop_assum (qspecl_then [`genv`, `(s',t2)`, `REVERSE v''`] assume_tac) >>
      rfs [vs_rel_list_rel, EVERY2_REVERSE] >>
      rw [] >>
      disj1_tac >>
      MAP_EVERY qexists_tac [`r_i1`, `v''`, `s'`, `FST s2_i1`, `t2`] >>
      fs [compile_exps_reverse])
  >- ((* TODO bug in metis, #259 *)res_tac >> srw_tac[boolSimps.DNF_ss][] >>
      rpt(first_assum(match_exists_tac o concl) >> simp[]) >> (* -- *)
      metis_tac [do_con_check, EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- metis_tac [EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse]
  >- (fs [do_log_thm, semanticPrimitivesTheory.do_if_def] >>
      every_case_tac >>
      fs [v_rel_eqns, compile_exp_def] >>
      rw[] >> rfs[] >>
      first_assum(fn th=>
        first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
      first_assum(fn th=>
        first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      disj1_tac >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      rw[modSemTheory.do_if_def] >> fs[] >> fs[Boolv_def])
  >- (fs [do_log_thm] >>
      every_case_tac >>
      fs [v_rel_eqns, compile_exp_def] >>
      rw [v_rel_eqns] >>
      first_assum(fn th=>
        first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      rw[modSemTheory.do_if_def] >> fs[Boolv_def] >>
      simp[Bool_def] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[Once evaluate_cases,PULL_EXISTS] >>
      rw[do_app_def,Boolv_def,opb_lookup_def] >>
      metis_tac[PAIR])
  >- (fs [do_log_thm] >>
      every_case_tac >>
      fs [v_rel_eqns, compile_exp_def] >>
      rw [v_rel_eqns] >>
      first_assum(fn th=>
        first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
      rw[PULL_EXISTS] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      first_assum(match_exists_tac o concl) >> simp[])
  >- (cases_on `op` >>
      rw [] >>
      metis_tac [])
  >- (fs [semanticPrimitivesTheory.do_if_def] >>
     every_case_tac >> fs[] >> rw [] >> rfs[] >>
     first_assum(fn th=>
       first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
     first_assum(fn th=>
       first_x_assum(fn th2=>first_x_assum(strip_assume_tac o C MATCH_MP(CONJ th th2)))) >>
     first_assum(match_exists_tac o concl) >> simp[] >>
     first_assum(match_exists_tac o concl) >> simp[] >>
     disj1_tac >> rfs[] >>
     first_assum(match_exists_tac o concl) >> simp[] >>
     rw[modSemTheory.do_if_def] >>
     fs[v_rel_eqns] >> simp[Boolv_def] )
  >- metis_tac []
  >- metis_tac []
  >- (fs [v_rel_eqns] >>
      metis_tac [])
  >- metis_tac []
  >- metis_tac []
  >- (* Let *)
     (`?env'. env_i1 = (genv,cenv,env')` by fs [env_all_rel_cases] >>
      rw [] >>
      res_tac >>
      fs [] >>
      rw [] >>
      cases_on `n` >>
      fs [libTheory.opt_bind_def, compile_exp_def]
      >- metis_tac [compl_insert, DRESTRICT_DOMSUB] >>
      `env_all_rel genv mods tops (menv,cenv,(x, v) :: env)
                     (genv, cenv, (x,v')::env') (x INSERT locals)`
                 by (fs [env_all_rel_cases] >>
                     MAP_EVERY qexists_tac [`(x, v) :: env''`, `env'''`] >>
                     fs [v_rel_eqns] >>
                     rw []) >>
      metis_tac [compl_insert, DRESTRICT_DOMSUB])
  >- (cases_on `n` >>
      fs [compile_exp_def] >>
      metis_tac [])
  >- (cases_on `n` >>
      fs [compile_exp_def] >>
      metis_tac [])
  >- (* Letrec *)
     (rw [markerTheory.Abbrev_def] >>
      pop_assum mp_tac >>
      rw [] >>
      `?env'. env_i1 = (genv,cenv,env')` by fs [env_all_rel_cases] >>
      rw [] >>
      `env_all_rel genv mods tops (menv,cenv,build_rec_env funs (menv,cenv,env) env)
                                    (genv,cenv,build_rec_env (compile_funs mods (FOLDR (λk m. m \\ k) (DRESTRICT tops (COMPL locals)) (MAP FST funs)) funs) (cenv, env') env')
                                    (set (MAP FST funs) ∪ locals)`
                             by (fs [env_all_rel_cases] >>
                                 MAP_EVERY qexists_tac [`build_rec_env funs (menv,cenv,env'' ++ env''') env''`, `env'''`] >>
                                 rw [evalPropsTheory.build_rec_env_merge, EXTENSION]
                                 >- (rw [MEM_MAP, EXISTS_PROD] >>
                                    imp_res_tac env_rel_dom >>
                                    metis_tac [pair_CASES, FST, MEM_MAP, EXISTS_PROD, LAMBDA_PROD])
                                 >- metis_tac [INSERT_SING_UNION, global_env_inv_add_locals, UNION_COMM]
                                 >- (fs [v_rel_eqns, modPropsTheory.build_rec_env_merge] >>
                                     match_mp_tac env_rel_append >>
                                     rw [drestrict_iter_list, GSYM COMPL_UNION] >>
                                     imp_res_tac env_rel_dom >>
                                     rw [] >>
                                     match_mp_tac do_app_rec_help >>
                                     rw [] >>
                                     fs [v_rel_eqns] >>
                                     rw [SUBSET_DEF] >>
                                     `¬(ALOOKUP env''' x = NONE)`
                                            by (rw [ALOOKUP_FAILS] >>
                                                metis_tac [pair_CASES, FST, MEM_MAP]) >>
                                     cases_on `ALOOKUP env''' x` >>
                                     fs [] >>
                                     res_tac >>
                                     fs [FLOOKUP_DEF])) >>
       res_tac >>
       MAP_EVERY qexists_tac [`s'_i1'`, `r_i1'`] >>
       rw [] >>
       rw [] >>
       fs [drestrict_iter_list]
       >- metis_tac [compile_funs_dom]
       >- (`(\(x,y,z). x) = FST:tvarN # tvarN # exp -> tvarN` by (rw [FUN_EQ_THM] >>PairCases_on `x` >> rw []) >>
           rw [] >>
           fs [COMPL_UNION] >>
           metis_tac [INTER_COMM]))
  >- metis_tac []
  >- ((* TODO bug in metis, #259 *)res_tac >> srw_tac[boolSimps.DNF_ss][] >>
      rpt(first_assum(match_exists_tac o concl) >> simp[]) >> (* -- *)
      metis_tac [do_con_check, EVERY2_REVERSE, vs_rel_list_rel, compile_exps_reverse])
  >- metis_tac []
  >- metis_tac []
  >- metis_tac []
  >- (* Pattern matching *)
     (pop_assum mp_tac >>
      rw [] >>
      fs [s_rel_cases, env_all_rel_cases] >>
      rw [] >>
      `match_result_rel genv env''' (Match env') (pmatch cenv s'' p v_i1 env_i1')`
                    by metis_tac [pmatch] >>
      cases_on `pmatch cenv s'' p v_i1 env_i1'` >>
      fs [match_result_rel_def] >>
      rw [] >>
      fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``] >>
      FIRST_X_ASSUM (qspecl_then [`genv`, `mods`, `tops`, `env''''`, `env'''`, `a`, `s''`] mp_tac) >>
      rw [] >>
      fs [] >>
      imp_res_tac sourcePropsTheory.pmatch_extend >>
      fs [APPEND_11] >>
      rw [] >>
      imp_res_tac global_env_inv_add_locals >>
      fs [] >>
      rw [] >>
      MAP_EVERY qexists_tac [`(c,s'''',t')`, `r_i1`] >>
      rw [] >>
      fs [COMPL_UNION, drestrict_iter_list] >>
      metis_tac [INTER_COMM])
  >- (* Pattern matching *)
     (pop_assum mp_tac >>
      rw [] >>
      fs [s_rel_cases, env_all_rel_cases] >>
      rw [] >>
      `match_result_rel genv env'' (No_match) (pmatch cenv s'' p v_i1 env_i1')`
                    by metis_tac [pmatch] >>
      cases_on `pmatch cenv s'' p v_i1 env_i1'` >>
      fs [match_result_rel_def] >>
      rw [] >>
      fs [METIS_PROVE [] ``(((?x. P x) ∧ R ⇒ Q) ⇔ !x. P x ∧ R ⇒ Q) ∧ ((R ∧ (?x. P x) ⇒ Q) ⇔ !x. R ∧ P x ⇒ Q) ``]));

val alookup_alloc_defs_bounds = Q.prove (
  `!next l x n.
    ALOOKUP (alloc_defs next l) x = SOME n
    ⇒
    next <= n ∧ n < next + LENGTH l`,
  induct_on `l` >>
  rw [alloc_defs_def]  >>
  res_tac >>
  DECIDE_TAC);

val global_env_inv_flat_extend_lem = Q.prove (
  `!genv genv' env env_i1 x n v.
    env_rel genv' env env_i1 ∧
    ALOOKUP env x = SOME v ∧
    ALOOKUP (alloc_defs (LENGTH genv) (MAP FST env)) x = SOME n
    ⇒
    ?v_i1.
      EL n (genv ++ MAP SOME (MAP SND env_i1)) = SOME v_i1 ∧
      v_rel genv' v v_i1`,
  induct_on `env` >>
  rw [v_rel_eqns] >>
  PairCases_on `h` >>
  fs [alloc_defs_def] >>
  every_case_tac >>
  fs [] >>
  rw [] >>
  fs [v_rel_eqns] >>
  rw []
  >- metis_tac [EL_LENGTH_APPEND, NULL, HD]
  >- (FIRST_X_ASSUM (qspecl_then [`genv++[SOME v']`] mp_tac) >>
      rw [] >>
      metis_tac [APPEND, APPEND_ASSOC]));

val global_env_inv_extend = Q.prove (
  `!genv mods tops menv env env' env_i1.
    ALL_DISTINCT (MAP FST env') ∧
    env_rel genv env' env_i1
    ⇒
    global_env_inv (genv++MAP SOME (MAP SND (REVERSE env_i1))) FEMPTY (tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP FST env'))) [] ∅ env'`,
  rw [v_rel_eqns] >>
  fs [flookup_fupdate_list, ALOOKUP_APPEND] >>
  every_case_tac >>
  rw [RIGHT_EXISTS_AND_THM]
  >- (imp_res_tac ALOOKUP_NONE >>
      fs [MAP_REVERSE, fst_alloc_defs] >>
      imp_res_tac ALOOKUP_MEM >>
      fs [MEM_MAP] >>
      metis_tac [pair_CASES, FST])
  >- metis_tac [ALL_DISTINCT_REVERSE, LENGTH_REVERSE, fst_alloc_defs, alookup_distinct_reverse,
                LENGTH_MAP, length_env_rel, alookup_alloc_defs_bounds]
  >- (match_mp_tac global_env_inv_flat_extend_lem >>
      MAP_EVERY qexists_tac [`(REVERSE env')`, `x`] >>
      rw []
      >- metis_tac [env_rel_reverse, v_rel_weakening]
      >- metis_tac [alookup_distinct_reverse]
      >- metis_tac [alookup_distinct_reverse, MAP_REVERSE, fst_alloc_defs, ALL_DISTINCT_REVERSE]));

val env_rel_el = Q.prove (
  `!genv env env_i1.
    env_rel genv env env_i1 ⇔
    LENGTH env = LENGTH env_i1 ∧ !n. n < LENGTH env ⇒ (FST (EL n env) = FST (EL n env_i1)) ∧ v_rel genv (SND (EL n env)) (SND (EL n env_i1))`,
  induct_on `env` >>
  rw [v_rel_eqns]
  >- (cases_on `env_i1` >>
      fs []) >>
  PairCases_on `h` >>
  rw [v_rel_eqns] >>
  eq_tac >>
  rw [] >>
  rw []
  >- (cases_on `n` >>
      fs [])
  >- (cases_on `n` >>
      fs [])
  >- (cases_on `env_i1` >>
      fs [] >>
      FIRST_ASSUM (qspecl_then [`0`] mp_tac) >>
      SIMP_TAC (srw_ss()) [] >>
      rw [] >>
      qexists_tac `SND h` >>
      rw [] >>
      FIRST_X_ASSUM (qspecl_then [`SUC n`] mp_tac) >>
      rw []));

val find_recfun_el = Q.prove (
  `!f funs x e n.
    ALL_DISTINCT (MAP (\(f,x,e). f) funs) ∧
    n < LENGTH funs ∧
    EL n funs = (f,x,e)
    ⇒
    find_recfun f funs = SOME (x,e)`,
  simp[find_recfun_ALOOKUP] >>
  induct_on `funs` >>
  rw [] >>
  cases_on `n` >>
  fs [] >>
  PairCases_on `h` >>
  fs [] >>
  rw [] >>
  res_tac >>
  fs [MEM_MAP, MEM_EL, FORALL_PROD] >>
  metis_tac []);

val letrec_global_env_lem2 = Q.prove (
  `!funs x genv n.
    ALL_DISTINCT (MAP FST funs) ∧
    n < LENGTH funs ∧
    ALOOKUP (REVERSE (alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))) (EL n (MAP FST funs)) = SOME x
    ⇒
    x = LENGTH funs + LENGTH genv - (n + 1)`,
  induct_on `funs` >>
  rw [alloc_defs_def] >>
  PairCases_on `h` >>
  fs [alloc_defs_append, ALOOKUP_APPEND, REVERSE_APPEND] >>
  every_case_tac >>
  fs [alloc_defs_def] >>
  rw [] >>
  cases_on `n = 0` >>
  full_simp_tac (srw_ss()++ARITH_ss) [] >>
  `0 < n` by decide_tac >>
  fs [EL_CONS] >>
  `PRE n < LENGTH funs` by decide_tac >>
  res_tac >>
  srw_tac [ARITH_ss] [] >>
  fs [MEM_MAP, EL_MAP] >>
  LAST_X_ASSUM (qspecl_then [`EL (PRE n) funs`] mp_tac) >>
  rw [MEM_EL] >>
  metis_tac []);

val letrec_global_env_lem3 = Q.prove (
  `!funs x genv cenv tops mods.
    ALL_DISTINCT (MAP (λ(x,y,z). x) funs) ∧
    MEM x (MAP FST funs)
    ⇒
    ∃n y e'.
      FLOOKUP (FEMPTY |++ alloc_defs (LENGTH genv) (REVERSE (MAP FST funs))) x =
          SOME n ∧ n < LENGTH genv + LENGTH funs ∧
      find_recfun x funs = SOME (y,e') ∧
      EL n (genv ++ MAP (λ(p1,p1',p2).
                             SOME (Closure (cenv,[]) p1'
                                        (compile_exp mods ((tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP FST funs))) \\ p1') p2)))
                        (REVERSE funs)) =
        SOME (Closure (cenv,[]) y (compile_exp mods ((tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP FST funs))) \\ y) e'))`,
  rw [] >>
  fs [MEM_EL] >>
  rw [] >>
  MAP_EVERY qexists_tac [`LENGTH genv + LENGTH funs - (n + 1)`, `FST (SND (EL n funs))`, `SND (SND (EL n funs))`] >>
  srw_tac [ARITH_ss] [EL_APPEND2, flookup_fupdate_list]
  >- (every_case_tac >>
      rw []
      >- (imp_res_tac ALOOKUP_NONE >>
          fs [MAP_REVERSE, fst_alloc_defs] >>
          fs [MEM_MAP, FST_triple] >>
          pop_assum mp_tac >>
          rw [EL_MAP] >>
          qexists_tac `EL n funs` >>
          rw [EL_MEM])
      >- metis_tac [FST_triple, letrec_global_env_lem2])
  >- (rw [find_recfun_ALOOKUP] >>
      rpt (pop_assum mp_tac) >>
      Q.SPEC_TAC (`n`, `n`) >>
      induct_on `funs` >>
      rw [] >>
      cases_on `0 < n` >>
      rw [EL_CONS] >>
      PairCases_on `h` >>
      fs []
      >- (every_case_tac >>
          fs [] >>
          `PRE n < LENGTH funs` by decide_tac
          >- (fs [MEM_MAP, FST_triple] >>
              FIRST_X_ASSUM (qspecl_then [`EL (PRE n) funs`] mp_tac) >>
              rw [EL_MAP, EL_MEM])
          >- metis_tac []))
  >- (`LENGTH funs - (n + 1) < LENGTH funs` by decide_tac >>
      `LENGTH funs - (n + 1) < LENGTH (REVERSE funs)` by metis_tac [LENGTH_REVERSE] >>
      srw_tac [ARITH_ss] [EL_MAP, EL_REVERSE] >>
      `PRE (n + 1) = n` by decide_tac >>
      fs [] >>
      `?f x e. EL n funs = (f,x,e)` by metis_tac [pair_CASES] >>
      rw []));

val alookup_alloc_defs_bounds_rev = Q.prove (
  `!next l x n.
    ALOOKUP (REVERSE (alloc_defs next l)) x = SOME n
    ⇒
    next <= n ∧ n < next + LENGTH l`,
  induct_on `l` >>
  rw [alloc_defs_def]  >>
  fs [ALOOKUP_APPEND] >>
  every_case_tac >>
  fs [] >>
  rw [] >>
  res_tac >>
  DECIDE_TAC);

val letrec_global_env_lem = Q.prove (
  `!funs funs' menv cenv env v x x' genv.
    ALOOKUP (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs) x = SOME v ∧
    ALOOKUP (REVERSE (alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))) x = SOME x'
    ⇒
    v = SND (EL (LENGTH funs + LENGTH genv - (SUC x')) (MAP (λ(fn,n,e). (fn,Recclosure (menv,cenv,env) funs' fn)) funs))`,
  induct_on `funs` >>
  rw [alloc_defs_append] >>
  PairCases_on `h` >>
  fs [REVERSE_APPEND, alloc_defs_def, ALOOKUP_APPEND] >>
  every_case_tac >>
  fs [] >>
  srw_tac [ARITH_ss] [arithmeticTheory.ADD1] >>
  res_tac >>
  rw [arithmeticTheory.ADD1] >>
  imp_res_tac alookup_alloc_defs_bounds_rev >>
  fs [] >>
  `LENGTH funs + LENGTH genv − x' = SUC (LENGTH funs + LENGTH genv − (x'+1))` by decide_tac >>
  rw []);

val letrec_global_env = Q.prove (
  `!genv.
    ALL_DISTINCT (MAP (\(x,y,z). x) funs) ∧
    global_env_inv genv mods tops menv {} env
    ⇒
    global_env_inv (genv ++ (MAP (λ(p1,p1',p2). SOME (Closure (cenv,[]) p1' p2))
                                 (compile_funs mods (tops |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))
                                                  (REVERSE funs))))
                 FEMPTY
                 (FEMPTY |++ alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs)))
                 []
                 ∅
                 (build_rec_env funs (menv,cenv,env) [])`,
  rw [evalPropsTheory.build_rec_env_merge] >>
  rw [v_rel_eqns, flookup_fupdate_list] >>
  every_case_tac >>
  rw [compile_funs_map, MAP_MAP_o, combinTheory.o_DEF, LAMBDA_PROD, RIGHT_EXISTS_AND_THM]
  >- (imp_res_tac ALOOKUP_NONE >>
      fs [MAP_REVERSE, fst_alloc_defs] >>
      imp_res_tac ALOOKUP_MEM >>
      fs [MEM_MAP] >>
      rw [] >>
      fs [LAMBDA_PROD, FORALL_PROD] >>
      PairCases_on `y` >>
      fs [] >>
      metis_tac [])
  >- (imp_res_tac alookup_alloc_defs_bounds_rev >>
      fs [])
  >- (imp_res_tac letrec_global_env_lem >>
      imp_res_tac alookup_alloc_defs_bounds_rev >>
      rw [EL_APPEND2] >>
      fs [] >>
      srw_tac [ARITH_ss] [EL_MAP, EL_REVERSE] >>
      `(PRE (LENGTH funs + LENGTH genv − x')) = (LENGTH funs + LENGTH genv − SUC x')` by decide_tac >>
      rw [] >>
      `?f x e. EL (LENGTH funs + LENGTH genv − SUC x') funs = (f,x,e)` by metis_tac [pair_CASES] >>
      rw [Once v_rel_cases] >>
      MAP_EVERY qexists_tac [`mods`,
                             `tops`,
                             `e`,
                             `alloc_defs (LENGTH genv) (REVERSE (MAP (λ(f,x,e). f) funs))`] >>
      rw []
      >- (fs [v_rel_eqns, SUBSET_DEF] >>
          rw [] >>
          `¬(ALOOKUP env x''' = NONE)` by metis_tac [ALOOKUP_NONE] >>
          cases_on `ALOOKUP env x'''` >>
          fs [] >>
          res_tac >>
          fs [FLOOKUP_DEF])
      >- metis_tac [v_rel_weakening]
      >- rw [MAP_REVERSE, fst_alloc_defs, FST_triple]
      >- (`LENGTH funs + LENGTH genv − SUC x' < LENGTH funs` by decide_tac >>
          metis_tac [find_recfun_el])
      >- metis_tac [letrec_global_env_lem3,FST_triple]))
  |> SIMP_RULE(srw_ss())[FUPDATE_LIST,FST_triple,compile_funs_map,MAP_MAP_o,UNCURRY,combinTheory.o_DEF,
                         evalPropsTheory.build_rec_env_merge,MAP_REVERSE]

val compile_dec_correct = Q.prove (
  `!ck mn mods tops d menv cenv env s s' r genv s_i1 next' tops' d_i1 tdecs tdecs'.
    r ≠ Rerr (Rabort Rtype_error) ∧
    evaluate_dec ck mn (menv,cenv,env) (s,tdecs) d ((s',tdecs'),r) ∧
    global_env_inv genv mods tops menv {} env ∧
    s_rel genv s s_i1 ∧
    compile_dec (LENGTH genv) mn mods tops d = (next',tops',d_i1)
    ⇒
    ?s'_i1 r_i1.
      evaluate_dec ck genv cenv (s_i1,tdecs) d_i1 ((s'_i1,tdecs'),r_i1) ∧
      (!cenv' env'.
        r = Rval (cenv',env')
        ⇒
        ?env'_i1.
          r_i1 = Rval (cenv', MAP SND env'_i1) ∧
          next' = LENGTH (genv ++ MAP SOME (MAP SND env'_i1)) ∧
          env_rel (genv ++ MAP SOME (MAP SND env'_i1)) env' (REVERSE env'_i1) ∧
          s_rel (genv ++ MAP SOME (MAP SND env'_i1)) s' s'_i1 ∧
          MAP FST env' = REVERSE (MAP FST tops') ∧
          global_env_inv (genv ++ MAP SOME (MAP SND env'_i1)) FEMPTY (FEMPTY |++ tops') [] {} env') ∧
      (!err.
        r = Rerr err
        ⇒
        ?err_i1.
          r_i1 = Rerr err_i1 ∧
          result_rel (\a b c. T) genv (Rerr err) (Rerr err_i1) ∧
          s_rel genv s' s'_i1)`,
  rw [bigStepTheory.evaluate_dec_cases, modSemTheory.evaluate_dec_cases, compile_dec_def] >>
  every_case_tac >>
  fs [LET_THM] >>
  rw [FUPDATE_LIST, result_rel_eqns]
  >- (`env_all_rel genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
            by fs [env_all_rel_cases, v_rel_eqns] >>
      imp_res_tac compile_exp_correct >> fs [] >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      fs [DRESTRICT_UNIV, result_rel_cases, semanticPrimitivesTheory.all_env_to_cenv_def] >>
      rw [] >>
      fs [s_rel_cases] >>
      rw [PULL_EXISTS] >>
      simp[Once modSemTheory.evaluate_cases,PULL_EXISTS] >>
      ONCE_REWRITE_TAC[CONJ_COMM] >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      first_x_assum(mp_tac o MATCH_MP(REWRITE_RULE[GSYM AND_IMP_INTRO] (CONJUNCT1 pmatch))) >>
      rw[] >>
      pop_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
      disch_then(fn th => first_x_assum(mp_tac o MATCH_MP th)) >>
      rw[v_rel_eqns] >>
      cases_on`pmatch cenv s' p v'' []` >> fs[match_result_rel_def]>>
      simp[Once modSemTheory.evaluate_cases] >>
      simp[Once modSemTheory.evaluate_cases] >>
      simp[do_con_check_def,build_conv_def,PULL_EXISTS] >>
      imp_res_tac pmatch_evaluate_list >> rfs[] >>
      pop_assum (qspecl_then [`t2`, `genv`, `count'`, `ck`] strip_assume_tac) >>
      simp[MAP_REVERSE] >>
      CONV_TAC(STRIP_QUANT_CONV(lift_conjunct_conv(same_const``modSem$evaluate_list`` o fst o strip_comb))) >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      imp_res_tac env_rel_dom >>
      qexists_tac`REVERSE a` >>
      simp[MAP_REVERSE] >>
      `pat_bindings p [] = MAP FST env'`
             by (imp_res_tac pmatch_extend >>
                 fs [] >>
                 rw [] >>
                 metis_tac [LENGTH_MAP, length_env_rel]) >>
      simp[] >>
      conj_tac >- metis_tac[v_rel_weakening] >>
      conj_tac >- metis_tac[sv_rel_weakening,LIST_REL_mono] >>
      conj_tac >- simp[fst_alloc_defs] >>
      rw[GSYM FUPDATE_LIST] >>
      imp_res_tac global_env_inv_extend >>
      pop_assum mp_tac >> discharge_hyps >- metis_tac[] >>
      disch_then(qspec_then`FEMPTY`strip_assume_tac) >>
      first_x_assum(mp_tac o MATCH_MP(REWRITE_RULE[GSYM AND_IMP_INTRO] global_env_inv_lookup_top)) >>
      imp_res_tac ALOOKUP_MEM >>
      disch_then(fn th => first_x_assum(mp_tac o MATCH_MP th)) >> simp[] >>
      simp[FLOOKUP_DEF] >>
      discharge_hyps_keep >- (
        simp[FDOM_FUPDATE_LIST,fst_alloc_defs] >>
        first_assum(CHANGED_TAC o SUBST1_TAC o SYM) >>
        simp[MEM_MAP,EXISTS_PROD] >> metis_tac[] ) >>
      strip_tac >> simp[] >>
      fs[MAP_REVERSE])
  >- (`env_all_rel genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
            by fs [env_all_rel_cases, v_rel_eqns] >>
      imp_res_tac compile_exp_correct >> fs [] >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      fs [DRESTRICT_UNIV, result_rel_cases, semanticPrimitivesTheory.all_env_to_cenv_def, s_rel_cases] >>
      rw [PULL_EXISTS] >>
      simp[Once modSemTheory.evaluate_cases,PULL_EXISTS] >>
      srw_tac[boolSimps.DNF_ss][] >> disj1_tac >>
      first_assum(match_exists_tac o concl) >> simp[] >>
      simp[Once evaluate_cases] >>
      first_x_assum(mp_tac o MATCH_MP(REWRITE_RULE[GSYM AND_IMP_INTRO] (CONJUNCT1 pmatch))) >>
      rw[] >>
      pop_assum(fn th => first_assum(mp_tac o MATCH_MP th)) >>
      disch_then(fn th => first_x_assum(mp_tac o MATCH_MP th)) >>
      rw[v_rel_eqns] >>
      cases_on`pmatch cenv s' p v'' []` >> fs[match_result_rel_def]>>
      simp[Once modSemTheory.evaluate_cases,PULL_EXISTS] )
  >- (`env_all_rel genv mods tops (menv,cenv,env) (genv,cenv,[]) {}`
            by fs [env_all_rel_cases, v_rel_eqns] >>
      imp_res_tac compile_exp_correct >> fs [] >> rfs[] >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      first_x_assum(fn th => first_x_assum(strip_assume_tac o MATCH_MP th)) >>
      fs [DRESTRICT_UNIV, result_rel_cases, semanticPrimitivesTheory.all_env_to_cenv_def, s_rel_cases] >>
      rw [PULL_EXISTS] >>
      simp[Once modSemTheory.evaluate_cases,PULL_EXISTS] >>
      srw_tac[boolSimps.DNF_ss][] >> disj2_tac >>
      first_assum(match_exists_tac o concl) >> simp[])
  >- (rw [fupdate_list_foldl] >>
      Q.PAT_ABBREV_TAC `tops' = (tops |++ X)` >>
      qexists_tac `MAP (λ(f,x,e). (f, Closure (cenv,[]) x e)) (compile_funs mods tops' (REVERSE funs))` >>
      simp[compile_funs_map,MAP_MAP_o,combinTheory.o_DEF,UNCURRY,fst_alloc_defs,
           evalPropsTheory.build_rec_env_merge,MAP_REVERSE,ETA_AX] >>
      conj_tac >- (
          simp[env_rel_el,EL_MAP,UNCURRY] >>
          rw [Once v_rel_cases] >>
          MAP_EVERY qexists_tac [`mods`, `tops`, `SND(SND(EL n funs))`, `alloc_defs (LENGTH genv) (REVERSE (MAP FST funs))`] >>
          rw [] >>
          UNABBREV_ALL_TAC >>
          rw [SUBSET_DEF, FDOM_FUPDATE_LIST, FUPDATE_LIST_THM]
          >- (fs [v_rel_eqns] >>
              `~(ALOOKUP env x = NONE)` by metis_tac [ALOOKUP_NONE] >>
              cases_on `ALOOKUP env x` >>
              fs [] >>
              res_tac >>
              fs [FLOOKUP_DEF])
          >- metis_tac [v_rel_weakening]
          >- rw [MAP_REVERSE, fst_alloc_defs, FST_triple]
          >- metis_tac [find_recfun_el,SND,PAIR]
          >- (simp[LAMBDA_PROD] >> metis_tac [MAP_REVERSE, letrec_global_env_lem3])) >>
      conj_tac
      >- (fs [s_rel_cases] >>
          metis_tac [sv_rel_weakening, LIST_REL_mono])
      >> (
        unabbrev_all_tac >>
        metis_tac[letrec_global_env,FUPDATE_LIST,FST_triple]))
  >- fs [v_rel_eqns]
  >- fs [v_rel_eqns]
  >- (rw [PULL_EXISTS, type_defs_to_new_tdecs_def, build_tdefs_def, check_dup_ctors_def] >>
      unabbrev_all_tac >>
      rw [ALL_DISTINCT, Once v_rel_cases] >>
      rw [Once v_rel_cases, fmap_eq_flookup, flookup_fupdate_list])
  >- EVAL_TAC
  >- (EVAL_TAC >> simp[])
  >- EVAL_TAC
  >> fs [v_rel_eqns]);

val compile_decs_correct = Q.prove (
`!ck mn mods tops ds menv cenv env s s' r genv s_i1 tdecs s'_i1 tdecs' next' tops' ds_i1 cenv'.
  r ≠ Rerr (Rabort Rtype_error) ∧
  evaluate_decs ck mn (menv,cenv,env) (s,tdecs) ds ((s',tdecs'),cenv',r) ∧
  global_env_inv genv mods tops menv {} env ∧
  s_rel genv s s_i1 ∧
  compile_decs (LENGTH genv) mn mods tops ds = (next',tops',ds_i1)
  ⇒
  ∃s'_i1 new_genv new_genv' new_env' r_i1.
   new_genv' = MAP SND new_genv ∧
   evaluate_decs ck genv cenv (s_i1,tdecs) ds_i1 ((s'_i1,tdecs'),cenv',new_genv',r_i1) ∧
   s_rel (genv ++ MAP SOME new_genv') s' s'_i1 ∧
   (!new_env.
     r = Rval new_env
     ⇒
     r_i1 = NONE ∧
     next' = LENGTH (genv ++ MAP SOME new_genv') ∧
     env_rel (genv ++ MAP SOME new_genv') new_env (REVERSE new_genv) ∧
     MAP FST new_env = REVERSE (MAP FST tops') ∧
     global_env_inv (genv ++ MAP SOME new_genv') FEMPTY (FEMPTY |++ tops') [] {} new_env) ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1 new_env.
       r_i1 = SOME err_i1 ∧
       next' ≥ LENGTH (genv++MAP SOME new_genv') ∧
       result_rel (\a b c. T) (genv ++ MAP SOME new_genv') (Rerr err) (Rerr err_i1))`,
 induct_on `ds` >>
 rw [compile_decs_def] >>
 rator_x_assum `bigStep$evaluate_decs` (mp_tac o SIMP_RULE (srw_ss()) [Once bigStepTheory.evaluate_decs_cases]) >>
 rw [Once modSemTheory.evaluate_decs_cases, FUPDATE_LIST, result_rel_eqns]
 >- rw [v_rel_eqns] >>
 fs [LET_THM] >>
 `?next' tops' d_i1. dec_to_i1 (LENGTH genv) mn mods tops h = (next',tops',d_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 `?s2' tdecs2. s2 = (s2',tdecs2)` by metis_tac [pair_CASES] >>
 fs [] >>
 imp_res_tac dec_to_i1_correct >>
 pop_assum mp_tac >>
 rw [] >>
 fs [result_rel_eqns] >>
 `?envC' env'. v' = (envC',env')` by metis_tac [pair_CASES] >>
 rw [] >>
 fs [fupdate_list_foldl] >>
 rw []
 >- fs [v_rel_eqns]
 >- (`?next''' tops''' ds_i1. decs_to_i1 next'' mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1)`
                   by metis_tac [pair_CASES] >>
     fs [result_rel_cases] >>
     rw [] >>
     fs []
     >- (MAP_EVERY qexists_tac [`s'_i1`, `[]`, `SOME (Rraise v')`] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac)
     >- (MAP_EVERY qexists_tac [`s'_i1`, `[]`] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac))
 >- (`?next''' tops''' ds_i1. decs_to_i1 (LENGTH genv + LENGTH env'_i1) mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1)`
               by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     `r' ≠ Rerr Rtype_error`
               by (cases_on `r'` >>
                   fs [combine_dec_result_def]) >>
     `global_env_inv (genv ++ MAP SOME (MAP SND env'_i1)) mods (tops |++ tops'') menv ∅ (new_env ++ env)`
             by metis_tac [v_rel_weakening, global_env_inv_extend2] >>
     FIRST_X_ASSUM (qspecl_then [`ck`, `mn`, `mods`, `tops |++ tops''`, `menv`,
                                 `merge_alist_mod_env ([],new_tds) cenv`, `new_env ++ env`,
                                 `s2'`, `s'`, `r'`, `genv ++ MAP SOME (MAP SND env'_i1)`, `s'_i1`,
                                 `tdecs2`, `tdecs'`, `next'`, `tops'''`, `ds_i1'`, `new_tds'`] mp_tac) >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i1'`, `env'_i1++new_genv`, `r_i1`] >>
     rw []
     >- (disj2_tac >>
         MAP_EVERY qexists_tac [`(s'_i1,tdecs2)`, `new_tds'`, `new_tds`, `MAP SND env'_i1`, `MAP SND new_genv`] >>
         rw [combine_dec_result_def, MAP_REVERSE])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def])
     >- (cases_on `r'` >>
         full_simp_tac (srw_ss()++ARITH_ss) [combine_dec_result_def])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def] >>
         rw [REVERSE_APPEND] >>
         metis_tac [env_rel_append, v_rel_weakening, MAP_REVERSE])
     >- (cases_on `r'` >>
         full_simp_tac (srw_ss()++ARITH_ss) [combine_dec_result_def] >>
         rw [])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def] >>
         rw [REVERSE_APPEND] >>
         fs [MAP_REVERSE, GSYM FUPDATE_LIST, FUPDATE_LIST_APPEND] >>
         metis_tac [FUPDATE_LIST_APPEND, global_env_inv_extend2, APPEND_ASSOC, v_rel_weakening])
     >- (cases_on `r'` >>
         fs [combine_dec_result_def, MAP_REVERSE, GSYM FUPDATE_LIST, FUPDATE_LIST_APPEND,
             REVERSE_APPEND] >>
         rw [] >>
         imp_res_tac dec_to_i1_num_bindings >>
         imp_res_tac decs_to_i1_num_bindings >>
         decide_tac)));

val global_env_inv_extend2 = Q.prove (
`!genv mods tops menv env tops' env'.
  MAP FST env' = REVERSE (MAP FST tops') ∧
  global_env_inv genv mods tops menv {} env ∧
  global_env_inv genv FEMPTY (FEMPTY |++ tops') [] {} env'
  ⇒
  global_env_inv genv mods (tops |++ tops') menv {} (env'++env)`,
 rw [v_rel_eqns, flookup_fupdate_list] >>
 full_case_tac >>
 fs [ALOOKUP_APPEND] >>
 full_case_tac >>
 fs [] >>
 res_tac >>
 fs [] >>
 rpt (pop_assum mp_tac) >>
 rw [] >>
 imp_res_tac ALOOKUP_NONE >>
 imp_res_tac ALOOKUP_MEM >>
 metis_tac [MEM_REVERSE, MEM_MAP, FST]);

val dec_to_i1_num_bindings = Q.prove (
`!next mn mods tops d next' tops' d_i1.
  dec_to_i1 next mn mods tops d = (next',tops',d_i1)
  ⇒
  next' = next + dec_to_dummy_env d_i1`,
 rw [dec_to_i1_def] >>
 every_case_tac >>
 fs [LET_THM] >>
 rw [dec_to_dummy_env_def, funs_to_i1_map] >>
 metis_tac []);

val decs_to_i1_num_bindings = Q.prove (
`!next mn mods tops ds next' tops' ds_i1.
  decs_to_i1 next mn mods tops ds = (next',tops',ds_i1)
  ⇒
  next' = next + decs_to_dummy_env ds_i1`,
 induct_on `ds` >>
 rw [decs_to_i1_def] >>
 rw [decs_to_dummy_env_def] >>
 fs [LET_THM] >>
 `?next'' tops'' ds_i1''. dec_to_i1 next mn mods tops h = (next'',tops'',ds_i1'')` by metis_tac [pair_CASES] >>
 fs [fupdate_list_foldl] >>
 `?next''' tops''' ds_i1'''. decs_to_i1 next'' mn mods (tops |++ tops'') ds = (next''',tops''',ds_i1''')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [decs_to_dummy_env_def] >>
 res_tac >>
 rw [] >>
 imp_res_tac dec_to_i1_num_bindings >>
 rw [] >>
 decide_tac);

val global_env_inv_extend_mod = Q.prove (
`!genv new_genv mods tops tops' menv new_env env mn.
  global_env_inv genv mods tops menv ∅ env ∧
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv)) FEMPTY (FEMPTY |++ tops') [] ∅ new_env
  ⇒
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv)) (mods |+ (mn,FEMPTY |++ tops')) tops ((mn,new_env)::menv) ∅ env`,
 rw [last (CONJUNCTS v_rel_eqns)]
 >- metis_tac [v_rel_weakening] >>
 every_case_tac >>
 rw [FLOOKUP_UPDATE] >>
 fs [v_rel_eqns] >>
 res_tac >>
 qexists_tac `map'` >>
 rw [] >>
 res_tac  >>
 qexists_tac `n` >>
 qexists_tac `v_i1` >>
 rw []
 >- decide_tac >>
 metis_tac [v_rel_weakening, EL_APPEND1]);

val global_env_inv_extend_mod_err = Q.prove (
`!genv new_genv mods tops tops' menv new_env env mn new_genv'.
  mn ∉ set (MAP FST menv) ∧
  global_env_inv genv mods tops menv ∅ env
  ⇒
  global_env_inv (genv ++ MAP SOME (MAP SND new_genv) ++ new_genv')
                 (mods |+ (mn,FEMPTY |++ tops')) tops menv ∅ env`,
 rw [last (CONJUNCTS v_rel_eqns)]
 >- metis_tac [v_rel_weakening] >>
 rw [FLOOKUP_UPDATE]
 >- metis_tac [ALOOKUP_MEM, MEM_MAP, pair_CASES, FST] >>
 fs [v_rel_eqns] >>
 rw [] >>
 res_tac >>
 rw [] >>
 res_tac  >>
 qexists_tac `n` >>
 qexists_tac `v_i1` >>
 rw []
 >- decide_tac >>
 metis_tac [v_rel_weakening, EL_APPEND1, APPEND_ASSOC]);

val no_dup_types_to_i1_helper = Q.prove (
`!next mn menv env ds next' menv' ds_i1. 
  decs_to_i1 next mn menv env ds = (next',menv',ds_i1) ⇒
  FLAT (MAP (\d. case d of Dtype tds => MAP (\(tvs,tn,ctors). tn) tds | _ => []) ds)
  =
  FLAT (MAP (\d. case d of Dtype_i1 mn tds => MAP (\(tvs,tn,ctors). tn) tds | _ => []) ds_i1)`,
 induct_on `ds` >>
 rw [decs_to_i1_def] >>
 rw [] >>
 `?next1 new_env1 d'. dec_to_i1 next mn menv env h = (next1,new_env1,d')` by metis_tac [pair_CASES] >>
 fs [LET_THM] >>
 `?next2 new_env2 ds'. (decs_to_i1 next1 mn menv (FOLDL (λenv (k,v). env |+ (k,v)) env new_env1) ds) = (next2,new_env2,ds')` by metis_tac [pair_CASES] >> 
 fs [] >>
 rw [] >>
 every_case_tac >>
 fs [dec_to_i1_def, LET_THM] >>
 rw [] >>
 metis_tac []);

val no_dup_types_to_i1 = Q.prove (
`!next mn menv env ds next' menv' ds_i1. 
  decs_to_i1 next mn menv env ds = (next',menv',ds_i1) ∧
  no_dup_types ds 
  ⇒
  no_dup_types_i1 ds_i1`,
 induct_on `ds` >>
 rw [decs_to_i1_def]
 >- fs [no_dup_types_def, no_dup_types_i1_def, decs_to_types_i1_def] >>
 `?next1 new_env1 d'. dec_to_i1 next mn menv env h = (next1,new_env1,d')` by metis_tac [pair_CASES] >>
 fs [LET_THM] >>
 `?next2 new_env2 ds'. (decs_to_i1 next1 mn menv (FOLDL (λenv (k,v). env |+ (k,v)) env new_env1) ds) = (next2,new_env2,ds')` by metis_tac [pair_CASES] >> 
 fs [] >>
 rw [] >>
 res_tac >>
 cases_on `h` >>
 fs [dec_to_i1_def, LET_THM] >>
 rw [] >>
 fs [decs_to_types_def, no_dup_types_def, decs_to_types_i1_def, no_dup_types_i1_def, ALL_DISTINCT_APPEND] >>
 rw [] >>
 metis_tac [no_dup_types_to_i1_helper]);

val to_i1_prompt_mods_ok = Q.prove (
`!l mn mods tops ds l' tops' ds_i1.
  decs_to_i1 l (SOME mn) mods tops ds = (l',tops',ds_i1)
  ⇒
  prompt_mods_ok (SOME mn) ds_i1`,
 induct_on `ds` >>
 rw [LET_THM, decs_to_i1_def, prompt_mods_ok_def] >>
 rw [] >>
 fs [prompt_mods_ok_def] >>
 `?x y z. dec_to_i1 l (SOME mn) mods tops h = (x,y,z)` by metis_tac [pair_CASES] >>
 fs [] >>
 `?x' y' z'. (decs_to_i1 x (SOME mn) mods (FOLDL (λenv (k,v). env |+ (k,v)) tops y) ds) = (x',y',z')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw []
 >- (every_case_tac >>
     fs [dec_to_i1_def] >>
     every_case_tac >>
     fs [LET_THM])
 >- metis_tac []);

val to_i1_invariant_def = Define `
to_i1_invariant genv mods tops menv env s s_i1 mod_names ⇔
  set (MAP FST menv) ⊆ mod_names ∧
  global_env_inv genv mods tops menv {} env ∧
  s_rel genv s s_i1`;

val top_to_i1_correct = Q.store_thm ("top_to_i1_correct",
`!mods tops t ck menv cenv env s s' r genv s_i1 next' tops' mods' prompt_i1 cenv' tdecs tdecs' mod_names mod_names'.
  r ≠ Rerr Rtype_error ∧
  to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
  evaluate_top ck (menv,cenv,env) (s,tdecs,mod_names) t ((s',tdecs',mod_names'),cenv',r) ∧
  top_to_i1 (LENGTH genv) mods tops t = (next',mods',tops',prompt_i1)
  ⇒
  ∃s'_i1 new_genv r_i1.
   evaluate_prompt_i1 ck genv cenv (s_i1,tdecs,mod_names) prompt_i1 ((s'_i1,tdecs',mod_names'),cenv',new_genv,r_i1) ∧
   next' = LENGTH  (genv ++ new_genv) ∧
   (!new_menv new_env.
     r = Rval (new_menv, new_env)
     ⇒
     r_i1 = NONE ∧
     to_i1_invariant (genv ++ new_genv) mods' tops' (new_menv++menv) (new_env++env) s' s'_i1 mod_names') ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1.
       r_i1 = SOME err_i1 ∧
       result_rel (\a b c. T) (genv ++ new_genv) (Rerr err) (Rerr err_i1) ∧
       to_i1_invariant (genv ++ new_genv) mods' tops menv env s' s'_i1 mod_names')`,
 rw [evaluate_top_cases, evaluate_prompt_i1_cases, top_to_i1_def, LET_THM, to_i1_invariant_def] >>
 fs [] >>
 rw []
 >- (`?next'' tops'' d_i1. dec_to_i1 (LENGTH genv) NONE mods tops d = (next'',tops'',d_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac dec_to_i1_correct >>
     fs [result_rel_cases] >>
     fs [fupdate_list_foldl] >>
     rw [] >>
     MAP_EVERY qexists_tac [`s'_i1`, `MAP SOME (MAP SND env'_i1)`] >>
     rw [mod_cenv_def, update_mod_state_def] >>
     rw [Once evaluate_decs_i1_cases] >>
     rw [Once evaluate_decs_i1_cases] >>
     fs []
     >- (qexists_tac `MAP SND env'_i1` >>
         rw [no_dup_types_i1_def] >>
         fs [evaluate_dec_cases] >>
         rw [] >>
         fs [dec_to_i1_def, LET_THM] >>
         simp [prompt_mods_ok_def, decs_to_types_i1_def] >>
         BasicProvers.VAR_EQ_TAC >>
         simp [] >>
         metis_tac [APPEND, ALL_DISTINCT, APPEND_NIL])
     >- metis_tac [global_env_inv_extend2, v_rel_weakening])
 >- (`?next'' tops'' d_i1. dec_to_i1 (LENGTH genv) NONE mods tops d = (next'',tops'',d_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac dec_to_i1_correct >>
     pop_assum mp_tac >>
     rw [] >>
     rw [mod_cenv_def] >>
     fs [result_rel_cases] >>
     rw [] >>
     fs [fupdate_list_foldl] >>
     fs [] >>
     rw []
     >- (MAP_EVERY qexists_tac [`s'_i1`, `GENLIST (\n. NONE) (decs_to_dummy_env [d_i1])`, `SOME (Rraise v')`] >>
         rw []
         >- (ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             fs [] >>
             rw [update_mod_state_def] >>
             fs [evaluate_dec_cases] >>
             rw [] >>
             fs [dec_to_i1_def, LET_THM] >>
             rw [no_dup_types_i1_def, decs_to_types_i1_def, prompt_mods_ok_def])
         >- (rw [decs_to_dummy_env_def] >>
             metis_tac [dec_to_i1_num_bindings])
         >- metis_tac [v_rel_weakening]
         >- metis_tac [v_rel_weakening]
         >- (fs [s_rel_cases] >>
             metis_tac [sv_rel_weakening, LIST_REL_mono]))
     >- (MAP_EVERY qexists_tac [`s'_i1`, `GENLIST (\n. NONE) (decs_to_dummy_env [d_i1])`] >>
         rw []
         >- (ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             ONCE_REWRITE_TAC [evaluate_decs_i1_cases] >>
             rw [] >>
             fs [evaluate_dec_i1_cases] >>
             rw [update_mod_state_def] >>
             fs [evaluate_dec_cases] >>
             rw [] >>
             fs [dec_to_i1_def, LET_THM] >>
             rw [no_dup_types_i1_def, decs_to_types_i1_def, prompt_mods_ok_def])
         >- (rw [decs_to_dummy_env_def] >>
             metis_tac [dec_to_i1_num_bindings])
         >- metis_tac [v_rel_weakening]
         >- (fs [s_rel_cases] >>
             metis_tac [sv_rel_weakening, LIST_REL_mono])))
 >- (`?next'' tops'' ds_i1. decs_to_i1 (LENGTH genv) (SOME mn) mods tops ds = (next'',tops'',ds_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac decs_to_i1_correct >>
     fs [] >>
     rw [mod_cenv_def] >>
     MAP_EVERY qexists_tac [`s'_i1`, `MAP SOME (MAP SND new_genv)`] >>
     rw [fupdate_list_foldl, update_mod_state_def] >>
     fs [SUBSET_DEF] >>
     `prompt_mods_ok (SOME mn) ds_i1` by metis_tac [to_i1_prompt_mods_ok] >>
     metis_tac [global_env_inv_extend_mod, no_dup_types_to_i1, no_dup_types_to_i1])
 >- (`?next'' tops'' ds_i1. decs_to_i1 (LENGTH genv) (SOME mn) mods tops ds = (next'',tops'',ds_i1)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     imp_res_tac decs_to_i1_correct >>
     pop_assum mp_tac >>
     rw [mod_cenv_def] >>
     MAP_EVERY qexists_tac [`s'_i1`,
                            `MAP SOME (MAP SND new_genv) ++ GENLIST (λn. NONE) (decs_to_dummy_env ds_i1 − LENGTH (MAP SND new_genv))`,
                            `SOME err_i1`] >>
     rw []
     >- (MAP_EVERY qexists_tac [`MAP SND new_genv`] >>
         rw [update_mod_state_def] >>
         metis_tac [no_dup_types_to_i1, to_i1_prompt_mods_ok])
     >- (imp_res_tac decs_to_i1_num_bindings >>
         decide_tac)
     >- (fs [result_rel_cases] >>
         rw [] >>
         metis_tac [v_rel_weakening])
     >- fs [SUBSET_DEF]
     >- (rw [fupdate_list_foldl] >>
         `mn ∉ set (MAP FST menv)`
                    by (fs [SUBSET_DEF] >>
                        metis_tac []) >>
         metis_tac [global_env_inv_extend_mod_err])
         >- (fs [s_rel_cases] >>
             metis_tac [sv_rel_weakening, LIST_REL_mono])));

val prog_to_i1_correct = Q.store_thm ("prog_to_i1_correct",
`!mods tops ck menv cenv env s prog s' r genv s_i1 next' tops' mods'  cenv' prog_i1 tdecs mod_names tdecs' mod_names'.
  r ≠ Rerr Rtype_error ∧
  evaluate_prog ck (menv,cenv,env) (s,tdecs,mod_names) prog ((s',tdecs',mod_names'),cenv',r) ∧
  to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
  prog_to_i1 (LENGTH genv) mods tops prog = (next',mods',tops',prog_i1)
  ⇒
  ∃s'_i1 new_genv r_i1.
   evaluate_prog_i1 ck genv cenv (s_i1,tdecs,mod_names) prog_i1 ((s'_i1,tdecs',mod_names'),cenv',new_genv,r_i1) ∧
   (!new_menv new_env.
     r = Rval (new_menv, new_env)
     ⇒
     next' = LENGTH (genv ++ new_genv) ∧
     r_i1 = NONE ∧
     to_i1_invariant (genv ++ new_genv) mods' tops' (new_menv++menv) (new_env++env) s' s'_i1 mod_names') ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1.
       r_i1 = SOME err_i1 ∧
       result_rel (\a b c. T) (genv ++ new_genv) (Rerr err) (Rerr err_i1))`,
 induct_on `prog` >>
 rw [LET_THM, prog_to_i1_def]
 >- fs [Once evaluate_prog_cases, Once evaluate_prog_i1_cases] >>
 `?next'' mods'' tops'' prompt_i1. top_to_i1 (LENGTH genv) mods tops h = (next'',mods'',tops'',prompt_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 `?next' mods' tops' prog_i1. prog_to_i1 next'' mods'' tops'' prog = (next',mods',tops',prog_i1)` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 qpat_assum `evaluate_prog a b c d e` (mp_tac o SIMP_RULE (srw_ss()) [Once evaluate_prog_cases]) >>
 rw [] >>
 rw [Once evaluate_prog_i1_cases] >>
 `?s2' tdecs2' mod_names2'. s2 = (s2',tdecs2',mod_names2')` by metis_tac [pair_CASES] >>
 rw []
 >- (`∃s'_i1 new_genv.
      evaluate_prompt_i1 ck genv cenv (s_i1,tdecs,mod_names) prompt_i1
         ((s'_i1,tdecs2',mod_names2'),new_tds,new_genv,NONE) ∧
      next'' = LENGTH genv + LENGTH new_genv ∧
      to_i1_invariant (genv ++ new_genv) mods'' tops'' (new_mods ++ menv) (new_env ++ env) s2' s'_i1 mod_names2'`
                 by (imp_res_tac top_to_i1_correct >>
                     fs [] >>
                     metis_tac []) >>
     fs [] >>
     FIRST_X_ASSUM (qspecl_then [`mods''`, `tops''`, `ck`, `new_mods ++ menv`, `merge_alist_mod_env new_tds cenv`, `new_env ++ env`, `s2'`, `s'`, `r'`, `genv++new_genv`, `s'_i1`] mp_tac) >>
     rw [] >>
     FIRST_X_ASSUM (qspecl_then [`new_tds'`, `tdecs2'`, `mod_names2'`, `tdecs'`, `mod_names'`] mp_tac) >>
     rw [] >>
     `r' ≠ Rerr Rtype_error`
            by (Cases_on `r'` >>
                fs [combine_mod_result_def]) >>
     rw [] >>
     cases_on `r'` >>
     fs [combine_mod_result_def]
     >- (`?menv' env'. a = (menv',env')` by metis_tac [pair_CASES] >>
         rw [] >>
         MAP_EVERY qexists_tac [`s'_i1'`, `new_genv++new_genv'`] >>
         srw_tac [ARITH_ss] [] >>
         fs [] >>
         metis_tac [])
     >- (fs [result_rel_cases] >>
         rw [] >>
         metis_tac [v_rel_weakening, APPEND_ASSOC, LENGTH_APPEND, MAP_APPEND]))
 >- (imp_res_tac top_to_i1_correct >>
     pop_assum mp_tac >>
     rw [] >>
     fs [result_rel_cases] >>
     rw [] >>
     metis_tac [v_rel_weakening, APPEND_ASSOC, LENGTH_APPEND]));

val prog_to_i1_mods = Q.prove (
`!l mods tops prog l' mods' tops' prog_i1.
  prog_to_i1 l mods tops prog = (l',mods', tops',prog_i1)
  ⇒
  prog_to_mods prog
  =
  prog_i1_to_mods prog_i1`,
 induct_on `prog` >>
 rw [prog_to_i1_def, LET_THM, prog_i1_to_mods_def, prog_to_mods_def] >>
 rw [] >>
 `?w x y z. top_to_i1 l mods tops h = (w,x,y,z)` by metis_tac [pair_CASES] >>
 fs [] >>
 `?w' x' y' z'. prog_to_i1 w x y prog = (w',x',y',z')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 fs [top_to_i1_def] >>
 every_case_tac >>
 rw [] >>
 fs [LET_THM]
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l'' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [])
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l'' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [])
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l'' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [prog_to_mods_def, prog_i1_to_mods_def] >>
     metis_tac [])
 >- (fs [prog_to_mods_def, prog_i1_to_mods_def] >>
     metis_tac [])
 >- (`?a b c. dec_to_i1 l NONE mods tops d = (a,b,c)` by metis_tac [pair_CASES] >>
     fs []));

val prog_to_i1_top_types = Q.prove (
`!l mods tops prog l' mods' tops' prog_i1.
  prog_to_i1 l mods tops prog = (l',mods', tops',prog_i1)
  ⇒
  prog_to_top_types prog
  =
  prog_i1_to_top_types prog_i1`,
 induct_on `prog` >>
 rw [prog_to_i1_def, LET_THM] >>
 rw [] >>
 `?w x y z. top_to_i1 l mods tops h = (w,x,y,z)` by metis_tac [pair_CASES] >>
 fs [prog_to_top_types_def, prog_i1_to_top_types_def] >>
 `?w' x' y' z'. prog_to_i1 w x y prog = (w',x',y',z')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 fs [top_to_i1_def] >>
 every_case_tac >>
 rw [] >>
 fs [LET_THM]
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l'' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [])
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l'' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     metis_tac [])
 >- (`?a b c. dec_to_i1 l NONE mods tops d = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     res_tac >>
     rw [] >>
     fs [dec_to_i1_def] >>
     every_case_tac >>
     fs [LET_THM] >>
     rw [decs_to_types_def, decs_to_types_i1_def])
 >- (`?a b c. dec_to_i1 l NONE mods tops d = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw []));

val prog_to_i1_mods_ok = Q.prove (
`!l mods tops prog l' mods' tops' prog_i1.
  prog_to_i1 l mods tops prog = (l',mods', tops',prog_i1)
  ⇒
  EVERY (λp. case p of Prompt_i1 mn ds => prompt_mods_ok mn ds) prog_i1`,
 induct_on `prog` >>
 rw [prog_to_i1_def, LET_THM] >>
 rw [] >>
 `?w x y z. top_to_i1 l mods tops h = (w,x,y,z)` by metis_tac [pair_CASES] >>
 fs [] >>
 `?w' x' y' z'. prog_to_i1 w x y prog = (w',x',y',z')` by metis_tac [pair_CASES] >>
 fs [] >>
 rw [] >>
 fs [top_to_i1_def] >>
 every_case_tac >>
 rw [] >>
 fs [LET_THM]
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l''' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     metis_tac [to_i1_prompt_mods_ok])
 >- (`?a b c. dec_to_i1 l NONE mods tops d = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [prompt_mods_ok_def] >>
     fs [dec_to_i1_def] >>
     every_case_tac >>
     fs [LET_THM])
 >- (`?a b c. decs_to_i1 l (SOME s) mods tops l''' = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     rw [] >>
     metis_tac [to_i1_prompt_mods_ok])
 >- (`?a b c. dec_to_i1 l NONE mods tops d = (a,b,c)` by metis_tac [pair_CASES] >>
     fs [] >>
     metis_tac []));

val whole_prog_to_i1_correct = Q.store_thm ("whole_prog_to_i1_correct",
`!mods tops ck menv cenv env s prog s' r genv s_i1 next' tops' mods'  cenv' prog_i1 tdecs mod_names tdecs' mod_names'.
  r ≠ Rerr Rtype_error ∧
  evaluate_whole_prog ck (menv,cenv,env) (s,tdecs,mod_names) prog ((s',tdecs',mod_names'),cenv',r) ∧
  to_i1_invariant genv mods tops menv env s s_i1 mod_names ∧
  prog_to_i1 (LENGTH genv) mods tops prog = (next',mods',tops',prog_i1)
  ⇒
  ∃s'_i1 new_genv r_i1.
   evaluate_whole_prog_i1 ck genv cenv (s_i1,tdecs,mod_names) prog_i1 ((s'_i1,tdecs',mod_names'),cenv',new_genv,r_i1) ∧
   (!new_menv new_env.
     r = Rval (new_menv, new_env)
     ⇒
     next' = LENGTH (genv ++ new_genv) ∧
     r_i1 = NONE ∧
     to_i1_invariant (genv ++ new_genv) mods' tops' (new_menv++menv) (new_env++env) s' s'_i1 mod_names') ∧
   (!err.
     r = Rerr err
     ⇒
     ?err_i1.
       r_i1 = SOME err_i1 ∧
       result_rel (\a b c. T) (genv ++ new_genv) (Rerr err) (Rerr err_i1))`,
 rw [evaluate_whole_prog_i1_def, evaluate_whole_prog_def] >>
 every_case_tac
 >- (imp_res_tac prog_to_i1_correct >>
     fs [] >>
     cases_on `r` >>
     fs [] >>
     metis_tac []) >>
 rw [result_rel_cases] >>
 CCONTR_TAC >>
 fs [] >>
 rw [] >>
 fs [no_dup_mods_def, no_dup_mods_i1_def, no_dup_top_types_def, no_dup_top_types_i1_def] >>
 metis_tac [prog_to_i1_mods, prog_to_i1_top_types, prog_to_i1_mods_ok, NOT_EVERY]);

val _ = export_theory ();
