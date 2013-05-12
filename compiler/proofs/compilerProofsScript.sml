open HolKernel bossLib boolLib boolSimps listTheory rich_listTheory pred_setTheory relationTheory arithmeticTheory whileTheory pairTheory quantHeuristicsLib lcsymtacs sortingTheory finite_mapTheory alistTheory
open SatisfySimps miscLib BigStepTheory terminationTheory semanticsExtraTheory miscTheory ToBytecodeTheory CompilerTheory compilerTerminationTheory intLangExtraTheory pmatchTheory toIntLangProofsTheory toBytecodeProofsTheory bytecodeTerminationTheory bytecodeExtraTheory bytecodeEvalTheory
val _ = new_theory"compilerProofs"

val FOLDL_cce_aux_thm = store_thm("FOLDL_cce_aux_thm",
  ``∀c s. let s' = FOLDL cce_aux s c in
     ALL_DISTINCT (MAP (FST o FST) c) ∧
     EVERY (combin$C $< s.next_label) (MAP (FST o FST) c)
      ⇒
     ∃code.
     (s'.out = REVERSE code ++ s.out) ∧
     (s.next_label ≤ s'.next_label) ∧
     ALL_DISTINCT (FILTER is_Label code) ∧
     EVERY (λn. MEM n (MAP (FST o FST) c) ∨ between s.next_label s'.next_label n)
       (MAP dest_Label (FILTER is_Label code)) ∧
     ∃cs.
     ∀i. i < LENGTH c ⇒ let ((l,ccenv,ce),(az,body)) = EL i c in
         s.next_label ≤ (cs i).next_label ∧
         (∀j. j < i ⇒ (cs j).next_label ≤ (cs i).next_label) ∧
         ∃cc. ((compile (MAP CTEnv ccenv) (TCTail az 0) 0 (cs i) body).out = cc ++ (cs i).out) ∧
              l < (cs i).next_label ∧
              ∃bc0 bc1. (code = bc0 ++ Label l::REVERSE cc ++ bc1) ∧
                        EVERY (combin$C $< (cs i).next_label o dest_Label)
                          (FILTER is_Label bc0)``,
   Induct >- ( simp[Once SWAP_REVERSE] ) >>
   simp[] >>
   qx_gen_tac`p`>> PairCases_on`p` >>
   rpt gen_tac >>
   simp[cce_aux_def] >>
   strip_tac >>
   Q.PAT_ABBREV_TAC`s0 = s with out := X::y` >>
   qspecl_then[`MAP CTEnv p1`,`TCTail p3 0`,`0`,`s0`,`p4`]
     strip_assume_tac(CONJUNCT1 compile_append_out) >>
   Q.PAT_ABBREV_TAC`s1 = compile X Y Z A B` >>
   first_x_assum(qspecl_then[`s1`]mp_tac) >>
   simp[] >>
   discharge_hyps >- (
     fsrw_tac[ARITH_ss][EVERY_MEM,Abbr`s0`] >>
     rw[] >> res_tac >> DECIDE_TAC ) >>
   disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
   simp[Abbr`s0`] >>
   simp[Once SWAP_REVERSE] >>
   fs[] >> simp[] >>
   simp[FILTER_APPEND,FILTER_REVERSE,MEM_FILTER,ALL_DISTINCT_REVERSE,ALL_DISTINCT_APPEND] >>
   conj_tac >- (
     rfs[FILTER_APPEND] >>
     fs[EVERY_MAP,EVERY_FILTER,EVERY_REVERSE,between_def] >>
     fsrw_tac[DNF_ss,ARITH_ss][EVERY_MEM,MEM_MAP] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][]
       >- metis_tac[] >>
     res_tac >> fsrw_tac[ARITH_ss][] ) >>
   conj_tac >- (
     fs[EVERY_MAP,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
     fsrw_tac[DNF_ss][EVERY_MEM,between_def] >>
     rw[] >> spose_not_then strip_assume_tac >> res_tac >>
     fsrw_tac[ARITH_ss][] ) >>
   qexists_tac`λi. if i = 0 then (s with out := Label p0::s.out) else cs (i-1)` >>
   Cases >> simp[] >- (
     map_every qexists_tac[`[]`,`c0`] >> simp[] ) >>
   strip_tac >>
   first_x_assum(qspec_then`n`mp_tac) >>
   simp[UNCURRY] >> strip_tac >>
   simp[] >>
   conj_asm1_tac >- ( Cases >> simp[] ) >>
   qexists_tac`Label p0::(REVERSE bc ++ bc0)` >>
   simp[FILTER_APPEND,FILTER_REVERSE,EVERY_REVERSE,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM] >>
   qpat_assum`EVERY X (FILTER is_Label bc0)`mp_tac >>
   qpat_assum`EVERY X (MAP Y (FILTER is_Label bc))`mp_tac >>
   simp[EVERY_FILTER,EVERY_MAP,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def] >>
   asm_simp_tac(srw_ss()++ARITH_ss++DNF_ss)[EVERY_MEM] >>
   rw[] >> res_tac >> DECIDE_TAC)

val compile_code_env_thm = store_thm("compile_code_env_thm",
  ``∀ez s e. let s' = compile_code_env s e in
      ALL_DISTINCT (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY (combin$C $< s.next_label) (MAP (FST o FST o SND) (free_labs ez e)) ∧
      EVERY good_cd (free_labs ez e)
      ⇒
      ∃code.
      (s'.out = REVERSE code ++ s.out) ∧
      (s.next_label < s'.next_label) ∧
      ALL_DISTINCT (FILTER is_Label code) ∧
      EVERY (λn. MEM n (MAP (FST o FST o SND) (free_labs ez e)) ∨ between s.next_label s'.next_label n)
        (MAP dest_Label (FILTER is_Label code)) ∧
      ∀bs bc0 bc1.
        (bs.code = bc0 ++ code ++ bc1) ∧
        (bs.pc = next_addr bs.inst_length bc0) ∧
        ALL_DISTINCT (FILTER is_Label bc0) ∧
        (∀l1 l2. MEM l1 (MAP dest_Label (FILTER is_Label bc0)) ∧ ((l2 = s.next_label) ∨ MEM l2 (MAP (FST o FST o SND) (free_labs ez e))) ⇒ l1 < l2)
        ⇒
        EVERY (code_env_cd (bc0++code)) (free_labs ez e) ∧
        bc_next bs (bs with pc := next_addr bs.inst_length (bc0++code))``,
  rw[compile_code_env_def] >> rw[] >>
  `MAP SND (free_labs 0 e) = MAP SND (free_labs ez e)` by metis_tac[MAP_SND_free_labs_any_ez] >>
  fs[] >>
  Q.ISPECL_THEN[`MAP SND (free_labs ez e)`,`s''`]mp_tac FOLDL_cce_aux_thm >>
  simp[Abbr`s''`] >>
  discharge_hyps >- (
    fsrw_tac[ARITH_ss][EVERY_MEM,MAP_MAP_o] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  simp[Once SWAP_REVERSE,Abbr`s''''`] >>
  conj_tac >- (
    simp[ALL_DISTINCT_APPEND,FILTER_APPEND,MEM_FILTER,Abbr`l`] >>
    fs[EVERY_MAP,EVERY_FILTER] >> fs[EVERY_MEM] >>
    spose_not_then strip_assume_tac >> res_tac >>
    fsrw_tac[ARITH_ss][between_def,MEM_MAP,MAP_MAP_o] >>
    res_tac >> rw[] >> DECIDE_TAC ) >>
  conj_tac >- (
    fs[EVERY_MAP,EVERY_FILTER,is_Label_rwt,GSYM LEFT_FORALL_IMP_THM,between_def,Abbr`l`] >>
    reverse conj_tac >- (disj2_tac >> DECIDE_TAC) >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_MAP,FORALL_PROD,EXISTS_PROD] >>
    rw[] >> res_tac >>
    TRY(metis_tac[]) >>
    disj2_tac >> DECIDE_TAC ) >>
  rpt gen_tac >>
  strip_tac >>
  conj_tac >- (
    fs[EVERY_MEM] >>
    qx_gen_tac`z` >>
    PairCases_on`z` >> strip_tac >>
    simp[code_env_cd_def] >>
    qmatch_assum_abbrev_tac`MEM cd (free_labs ez e)` >>
    `∃i. i < LENGTH (free_labs ez e) ∧ (EL i (free_labs ez e) = cd)` by metis_tac[MEM_EL] >>
    qpat_assum`∀i. P ⇒ Q`(qspec_then`i`mp_tac) >>
    simp[EL_MAP] >>
    simp[Abbr`cd`] >> strip_tac >>
    qexists_tac`cs i`>>simp[] >>
    qexists_tac`bc0++Jump (Lab l)::bc0'` >>
    simp[] >>
    fs[EVERY_MEM,MEM_MAP,FILTER_APPEND] >>
    fsrw_tac[DNF_ss][] >- (
      rpt strip_tac >> res_tac >> DECIDE_TAC) >>
    rpt strip_tac >> res_tac >> DECIDE_TAC) >>
  `bc_fetch bs = SOME (Jump (Lab l))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0` >> simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def,bc_state_component_equality,bc_find_loc_def] >>
  match_mp_tac bc_find_loc_aux_append_code >>
  match_mp_tac bc_find_loc_aux_ALL_DISTINCT >>
  qexists_tac`LENGTH bc0 + 1 + LENGTH c0` >>
  simp[EL_APPEND2,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER] >>
  fs[Abbr`l`,EVERY_MAP,EVERY_FILTER,between_def] >>
  fsrw_tac[DNF_ss][EVERY_MEM,is_Label_rwt,MEM_MAP,EXISTS_PROD,FORALL_PROD,MEM_FILTER] >>
  rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] >>
  res_tac >> fsrw_tac[ARITH_ss][])

val code_env_cd_append = store_thm("code_env_cd_append",
  ``∀code cd code'. code_env_cd code cd ∧ ALL_DISTINCT (FILTER is_Label (code ++ code')) ⇒ code_env_cd (code ++ code') cd``,
  rw[] >> PairCases_on`cd` >>
  fs[code_env_cd_def] >>
  HINT_EXISTS_TAC>>simp[]>>
  HINT_EXISTS_TAC>>simp[])

val good_contab_def = Define`
  good_contab (m,w,n) =
    cmap_linv m w`

val env_rs_def = Define`
  env_rs cenv env rs rd s bs ⇔
    good_contab rs.contab ∧
    good_cmap cenv (cmap rs.contab) ∧
    set (MAP FST cenv) ⊆ FDOM (cmap rs.contab) ∧
    Short "" ∉ FDOM (cmap rs.contab) ∧
    (set rs.rbvars = set (MAP FST env)) ∧
    ALL_DISTINCT rs.rbvars ∧
    let Cs0 = MAP (v_to_Cv (cmap rs.contab |+ (Short "",0))) s in
    let Cenv0 = env_to_Cenv (cmap rs.contab |+ (Short "",0)) (MAP (λv. (v,THE (ALOOKUP env v))) rs.rbvars) in
    let rsz = LENGTH rs.rbvars in
    ∃Cenv Cs.
    LIST_REL syneq Cs0 Cs ∧ LIST_REL syneq Cenv0 Cenv ∧
    (BIGUNION (IMAGE all_Clocs (set Cs)) ⊆ count (LENGTH Cs)) ∧
    (BIGUNION (IMAGE all_Clocs (set Cenv)) ⊆ count (LENGTH Cs)) ∧
    EVERY all_vlabs Cs ∧ EVERY all_vlabs Cenv ∧
    (∀cd. cd ∈ vlabs_list Cs ⇒ code_env_cd bs.code cd) ∧
    (∀cd. cd ∈ vlabs_list Cenv ⇒ code_env_cd bs.code cd) ∧
    Cenv_bs rd Cs Cenv (GENLIST (λi. CTLet (rsz - i)) rsz) rsz bs`

val compile_shadows_thm = store_thm("compile_shadows_thm",
  ``∀vs bvs cs i. let cs' = compile_shadows bvs cs i vs in
      ∃code.
        (cs'.out = REVERSE code ++ cs.out) ∧
        (cs'.next_label = cs.next_label) ∧
        EVERY ($~ o is_Label) code ∧
        ∀bs bc0 u ws st.
          (bs.code = bc0 ++ code) ∧
          (bs.pc = next_addr bs.inst_length bc0) ∧
          (bs.stack = Block u ws::st) ∧
          (LENGTH vs + i ≤ LENGTH ws) ∧
          (LENGTH bvs ≤ LENGTH st) ∧
          set vs ⊆ set bvs ∧
          ALL_DISTINCT vs ∧ ALL_DISTINCT bvs
          ⇒
          let bs' =
          bs with <| pc := next_addr bs.inst_length (bc0 ++ code)
                   ; stack := Block u ws::
                     GENLIST (λx. if x < LENGTH bvs ∧ EL x bvs ∈ set vs then EL (THE (find_index (EL x bvs) vs i)) ws else EL x st)
                     (LENGTH st)
                   |> in
          bc_next^* bs bs'``,
  Induct >- (
    simp[compile_shadows_def,Once SWAP_REVERSE] >> rw[] >>
    simp[Once RTC_CASES1] >> disj1_tac >>
    simp[bc_state_component_equality] >>
    match_mp_tac EQ_SYM >>
    match_mp_tac GENLIST_EL >>
    simp[]) >>
  qx_gen_tac`v` >>
  simp[compile_shadows_def] >> rw[] >>
  Q.PAT_ABBREV_TAC`cs0 = cs with out := X` >>
  first_x_assum(qspecl_then[`bvs`,`cs0`,`i+1`]mp_tac) >>
  simp[] >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  simp[Abbr`cs0`,Once SWAP_REVERSE] >>
  rw[] >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs = SOME (Stack (Load 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0`>>simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (El i))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 1) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (Store (the 0 (find_index v bvs 1))))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 2) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qspecl_then[`bvs`,`v`,`1`]mp_tac find_index_MEM >>
  simp[] >> disch_then(Q.X_CHOOSE_THEN`m`strip_assume_tac) >>
  simp[] >>
  last_x_assum kall_tac >>
  last_x_assum kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  first_x_assum(qspecl_then[`bs1`,`TAKE (LENGTH bc0 + 3) bs.code`]mp_tac) >>
  simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,SUM_APPEND,FILTER_APPEND,ADD1] >>
  qmatch_abbrev_tac`bc_next^* bs1 bs2 ⇒ bc_next^* bs1 bs'` >>
  `bs2 = bs'` by (
    simp[Abbr`bs2`,Abbr`bs'`,bc_state_component_equality,SUM_APPEND,FILTER_APPEND] >>
    simp[LIST_EQ_REWRITE] >> gen_tac >> strip_tac >>
    Cases_on`x < LENGTH bvs` >> simp[] >- (
      Cases_on`EL x bvs = v` >> simp[] >- (
        simp[CompilerLibTheory.find_index_def] >>
        `x = m` by metis_tac[EL_ALL_DISTINCT_EL_EQ] >>
        simp[EL_APPEND1,EL_APPEND2] ) >>
      Cases_on`MEM (EL x bvs) vs` >> simp[] >- (
        simp[CompilerLibTheory.find_index_def] ) >>
      Cases_on`x<m`>> simp[EL_APPEND1,EL_APPEND2,EL_TAKE] >>
      Cases_on`m<x`>> simp[EL_APPEND1,EL_APPEND2,EL_TAKE,EL_DROP] >>
      `x=m`by simp[] >>
      metis_tac[EL_ALL_DISTINCT_EL_EQ] ) >>
    `m < x` by simp[] >>
    simp[EL_APPEND2,EL_DROP] ) >>
  simp[])

val compile_news_thm = store_thm("compile_news_thm",
  ``∀vs cs i. let cs' = compile_news cs i vs in
      ∃code.
        (cs'.out = REVERSE code ++ cs.out) ∧
        (cs'.next_label = cs.next_label) ∧
        EVERY ($~ o is_Label) code ∧
        ∀bs bc0 u ws st.
          (bs.code = bc0 ++ code) ∧
          (bs.pc = next_addr bs.inst_length bc0) ∧
          (bs.stack = Block u ws::st) ∧
          (LENGTH ws = LENGTH vs + i)
          ⇒
          let bs' =
          bs with <| pc := next_addr bs.inst_length (bc0 ++ code)
                   ; stack := Block u ws::(REVERSE (DROP i ws))++st
                   |> in
          bc_next^* bs bs'``,
  Induct >- (
    simp[compile_news_def,Once SWAP_REVERSE] >> rw[] >>
    simp[Once RTC_CASES1] >> disj1_tac >>
    simp[bc_state_component_equality,DROP_LENGTH_NIL]) >>
  qx_gen_tac`v` >>
  simp[compile_news_def] >> rw[] >>
  Q.PAT_ABBREV_TAC`cs0 = cs with out := X` >>
  first_x_assum(qspecl_then[`cs0`,`i+1`]mp_tac) >>
  simp[] >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  simp[Abbr`cs0`,Once SWAP_REVERSE] >>
  rw[] >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs = SOME (Stack (Load 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`bc0`>>simp[] ) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (Load 0))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 1) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (El i))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 2) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  simp[Once RTC_CASES1] >> disj2_tac >>
  `bc_fetch bs1 = SOME (Stack (Store 1))` by (
    match_mp_tac bc_fetch_next_addr >>
    qexists_tac`TAKE (LENGTH bc0 + 3) bs.code` >>
    simp[Abbr`bs1`,TAKE_APPEND1,TAKE_APPEND2,FILTER_APPEND,SUM_APPEND]) >>
  simp[bc_eval1_thm,bc_eval1_def] >>
  simp[bc_eval_stack_def,bump_pc_def,Abbr`bs1`] >>
  qpat_assum`bc_fetch X = Y`kall_tac >>
  qmatch_abbrev_tac`bc_next^* bs1 bs'` >>
  first_x_assum(qspecl_then[`bs1`,`TAKE (LENGTH bc0 + 4) bs.code`]mp_tac) >>
  simp[Abbr`bs1`,SUM_APPEND,FILTER_APPEND,TAKE_APPEND1,TAKE_APPEND2] >>
  qmatch_abbrev_tac`bc_next^* bs1 bs2 ⇒ bc_next^* bs1 bs'` >>
  `bs2 = bs'` by (
    simp[Abbr`bs2`,Abbr`bs'`,bc_state_component_equality,SUM_APPEND,FILTER_APPEND] >>
    simp[LIST_EQ_REWRITE] >> gen_tac >> strip_tac >>
    Cases_on`x<LENGTH vs`>>simp[EL_REVERSE,EL_APPEND1,EL_APPEND2,EL_DROP,PRE_SUB1,ADD1] >>
    `x = LENGTH vs` by simp[] >>
    simp[] ) >>
  simp[])

(* TODO: move *)
val PERM_PART = store_thm("PERM_PART",
  ``∀P L l1 l2 p q. (p,q) = PART P L l1 l2 ⇒ PERM (L ++ (l1 ++ l2)) (p++q)``,
  GEN_TAC THEN Induct >>
  simp[PART_DEF] >> rw[] >- (
    first_x_assum(qspecl_then[`h::l1`,`l2`,`p`,`q`]mp_tac) >>
    simp[] >>
    REWRITE_TAC[Once CONS_APPEND] >>
    strip_tac >>
    REWRITE_TAC[Once CONS_APPEND] >>
    full_simp_tac std_ss [APPEND_ASSOC] >>
    metis_tac[PERM_REWR,PERM_APPEND] ) >>
  first_x_assum(qspecl_then[`l1`,`h::l2`,`p`,`q`]mp_tac) >>
  simp[] >>
  REWRITE_TAC[Once CONS_APPEND] >>
  strip_tac >>
  REWRITE_TAC[Once CONS_APPEND] >>
  full_simp_tac std_ss [APPEND_ASSOC] >>
  metis_tac[PERM_REWR,PERM_APPEND,APPEND_ASSOC] )

val PERM_PARTITION = store_thm("PERM_PARTITION",
  ``∀P L A B. ((A,B) = PARTITION P L) ==> PERM L (A ++ B)``,
  METIS_TAC[PERM_PART,PARTITION_DEF,APPEND_NIL])

val EVERY2_REVERSE = store_thm("EVERY2_REVERSE",
  ``!R l1 l2. EVERY2 R l1 l2 ==> EVERY2 R (REVERSE l1) (REVERSE l2)``,
  rw[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >>
  rfs[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM,EL_REVERSE] >>
  first_x_assum match_mp_tac >>
  simp[])

val EVERY2_DROP = store_thm("EVERY2_DROP",
  ``∀R l1 l2 n. EVERY2 R l1 l2 ∧ n <= LENGTH l1 ==> EVERY2 R (DROP n l1) (DROP n l2)``,
  rw[EVERY2_EVERY,ZIP_DROP] >>
  match_mp_tac (MP_CANON EVERY_DROP) >>
  rw[] >> PROVE_TAC[])

val compile_fake_exp_val = store_thm("compile_fake_exp_val",
  ``∀menv cenv s env expf exp s' vs rd rs vars vv0 vv1 rs' bc0 bc bs bs'.
      evaluate menv cenv s env exp (s', Rval (Conv (Short "") vs)) ∧
      is_null menv ∧
      EVERY (closed menv) s ∧
      EVERY (closed menv) (MAP SND env) ∧
      EVERY (EVERY (closed menv) o MAP SND) (MAP SND menv) ∧
      FV exp ⊆ set (MAP (Short o FST) env) ∪ menv_dom menv ∧
      closed_under_cenv cenv menv env s ∧
      (∀v. v ∈ env_range env ∨ MEM v s ⇒ all_locs v ⊆ count (LENGTH s)) ∧
      LENGTH s' ≤ LENGTH rd.sm ∧
      env_rs cenv env rs rd s (bs with code := bc0) ∧
      ALL_DISTINCT vars ∧
      (LENGTH vars = LENGTH vs) ∧
      (PARTITION (λv. MEM v rs.rbvars) vars = (vv0,vv1)) ∧
      (compile_fake_exp rs vars expf = (rs',bc)) ∧
      (exp = expf (Con (Short "") (MAP (Var o Short) (vv0++vv1)))) ∧
      (bs.code = bc0 ++ bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      ALL_DISTINCT (FILTER is_Label bc0) ∧
      EVERY (combin$C $< rs.rnext_label o dest_Label) (FILTER is_Label bc0)
      ⇒
      ∃st rf rd'.
      let env' = ZIP(vv0++vv1,vs) ++ env in
      let bs' = bs with <|pc := next_addr bs.inst_length (bc0 ++ bc); stack := st; refs := rf|> in
      bc_next^* bs bs' ∧
      env_rs cenv env' rs' rd' s' bs'``,
  rpt gen_tac >>
  simp[compile_fake_exp_def,compile_Cexp_def,GSYM LEFT_FORALL_IMP_THM] >>
  simp[GSYM AND_IMP_INTRO] >>
  Q.PAT_ABBREV_TAC`Ce0 = exp_to_Cexp X (expf Y)` >>
  Q.PAT_ABBREV_TAC`p = label_closures Y X Ce0` >>
  PairCases_on`p`>>simp[]>> rpt strip_tac >>
  qpat_assum`Abbrev(Ce0 = X)`mp_tac >>
  Q.PAT_ABBREV_TAC`exp' = expf X` >>
  `exp' = exp` by (
    rw[Abbr`exp'`] >>
    rpt AP_TERM_TAC >>
    REWRITE_TAC[GSYM MAP_APPEND] >>
    simp[MAP_EQ_f] ) >>
  qpat_assum`exp = X`kall_tac >>
  qpat_assum`Abbrev(exp' = X)`kall_tac >>
  pop_assum SUBST1_TAC >>
  strip_tac >>
  fs[env_rs_def,LET_THM] >>
  qmatch_assum_abbrev_tac`LIST_REL syneq (env_to_Cenv cm env1) Cenv` >>
  `∃s1 vs1. evaluate menv cenv s env1 exp (s1,Rval (Conv (Short "") vs1)) ∧
            LIST_REL syneq (MAP (v_to_Cv cm) s') (MAP (v_to_Cv cm) s1) ∧
            LIST_REL syneq (MAP (v_to_Cv cm) vs) (MAP (v_to_Cv cm) vs1)`
      by cheat >>
  qspecl_then[`menv`,`cenv`,`s`,`env1`,`exp`,`(s1,Rval (Conv (Short "") vs1))`] mp_tac (CONJUNCT1 exp_to_Cexp_thm1) >>
  simp[] >>
  discharge_hyps >- (
    simp[Abbr`env1`] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_MAP] >>
    fsrw_tac[DNF_ss][EVERY_MEM,MEM_MAP,closed_under_cenv_def,FORALL_PROD] >>
    simp[GSYM FORALL_AND_THM,GSYM IMP_CONJ_THM] >> map_every qx_gen_tac[`k`,`v`] >> strip_tac >>
    Cases_on`ALOOKUP env k` >- (
      imp_res_tac ALOOKUP_NONE >>
      fs[MEM_MAP,FORALL_PROD] ) >>
    imp_res_tac ALOOKUP_MEM >>
    simp[] >> metis_tac[] ) >>
  disch_then (qspec_then `cm` mp_tac) >>
  discharge_hyps >- (
    fs[good_cmap_def,FAPPLY_FUPDATE_THM,Abbr`cm`] >>
    rw[] >>
    fs[SUBSET_DEF,MEM_MAP,GSYM LEFT_FORALL_IMP_THM] >>
    metis_tac[] ) >>
  `MAP FST env1 = rs.rbvars` by (
    simp[Abbr`env1`,MAP_MAP_o,combinTheory.o_DEF] ) >>
  simp[FORALL_PROD,GSYM LEFT_FORALL_IMP_THM] >>
  simp_tac(srw_ss()++DNF_ss)[] >>
  map_every qx_gen_tac [`Cs'0`,`Cv0`] >> strip_tac >>
  qspecl_then[`LENGTH rs.rbvars`,`rs.rnext_label`,`Ce0`]mp_tac(CONJUNCT1 label_closures_thm) >>
  discharge_hyps >- (
    simp[Abbr`Ce0`] >>
    match_mp_tac free_vars_exp_to_Cexp_matchable >>
    simp[] >>
    fsrw_tac[DNF_ss][SUBSET_DEF,MEM_FLAT,is_null_def,MEM_MAP] >>
    rw[] >> rfs[] >> res_tac >> fs[] >> metis_tac[]) >>
  simp[] >> strip_tac >>
  qpat_assum`X = bc`mp_tac >>
  Q.PAT_ABBREV_TAC`cce = compile_code_env X Y` >>
  qpat_assum`Abbrev(cce = X)`mp_tac >>
  Q.PAT_ABBREV_TAC`s0 = X with out := []` >>
  strip_tac >>
  qspecl_then[`LENGTH rs.rbvars`,`s0`,`p0`]mp_tac compile_code_env_thm >>
  simp[] >>
  discharge_hyps >- (
    simp[ALL_DISTINCT_GENLIST,EVERY_GENLIST,Abbr`s0`] ) >>
  disch_then(Q.X_CHOOSE_THEN`c0`strip_assume_tac) >>
  qmatch_assum_rename_tac`set (free_vars Ce) ⊆ set (free_vars Ce0)`[] >>
  Q.PAT_ABBREV_TAC`renv:ctenv = GENLIST X (LENGTH rs.rbvars)` >>
  qspecl_then[`renv`,`TCNonTail`,`LENGTH rs.rbvars`,`cce`,`Ce`](Q.X_CHOOSE_THEN`bc1`strip_assume_tac)(CONJUNCT1 compile_append_out) >>
  Q.PAT_ABBREV_TAC`cmp = compile renv X Y Z A` >>
  qspecl_then[`vv0`,`rs.rbvars`,`cmp`,`0`]mp_tac (INST_TYPE[alpha|->``:string``]compile_shadows_thm) >>
  simp[] >> disch_then(Q.X_CHOOSE_THEN`c1`strip_assume_tac) >>
  Q.PAT_ABBREV_TAC`csd = compile_shadows X Y Z A` >>
  Q.ISPECL_THEN[`vv1`,`csd`,`LENGTH vv0`]mp_tac compile_news_thm >>
  simp[] >> disch_then(Q.X_CHOOSE_THEN`c2`strip_assume_tac) >>
  simp[] >> rw[Abbr`s0`] >>
  last_x_assum(qspecl_then[`bs`,`bc0`]mp_tac) >>
  simp[] >>
  discharge_hyps >- (
    simp[MEM_MAP,MEM_GENLIST,MEM_FILTER,GSYM LEFT_FORALL_IMP_THM,is_Label_rwt] >>
    fs[EVERY_FILTER,is_Label_rwt,EVERY_MEM] >>
    fsrw_tac[DNF_ss,ARITH_ss][] >>
    rw[] >> res_tac >> DECIDE_TAC ) >>
  strip_tac >>
  qmatch_assum_abbrev_tac`bc_next bs bs1` >>
  qmatch_assum_abbrev_tac`Cevaluate Cs0 Cenv0 Ce0 (Cs'0,Rval Cv0)` >>
  fs[LET_THM] >>
  qspecl_then[`Cs0`,`Cenv0`,`Ce0`,`Cs'0,Rval Cv0`]mp_tac(CONJUNCT1 Cevaluate_syneq) >> simp[] >>
  disch_then(qspecl_then[`$=`,`Cs`,`Cenv`,`Ce`]mp_tac) >>
  `LENGTH Cenv0 = LENGTH rs.rbvars` by rw[Abbr`Cenv0`,env_to_Cenv_MAP,Abbr`env1`] >>
  `LENGTH Cenv = LENGTH rs.rbvars` by fs[EVERY2_EVERY,Abbr`env1`] >>
  simp[EXISTS_PROD] >>
  discharge_hyps >- (
    qpat_assum`LIST_REL syneq Cenv0 Cenv`mp_tac >>
    ntac 2 (pop_assum mp_tac) >>
    rpt (pop_assum kall_tac) >>
    simp[EVERY2_EVERY,EVERY_MEM,FORALL_PROD] >>
    simp[MEM_ZIP,GSYM LEFT_FORALL_IMP_THM] ) >>
  simp_tac(srw_ss()++DNF_ss)[] >>
  map_every qx_gen_tac[`Cs'`,`Cv`] >> strip_tac >>
  qspecl_then[`Cs`,`Cenv`,`Ce`,`(Cs',Rval Cv)`]mp_tac(CONJUNCT1 compile_val) >> simp[] >>
  disch_then(qspecl_then[`rd`,`cce`,`renv`,`LENGTH rs.rbvars`,`bs1`
    ,`bc0 ++ c0`,`REVERSE bc1 ++ c1 ++ c2 ++ [Stack Pop]`,`bc0 ++ c0`]mp_tac) >>
  `EVERY (code_env_cd (bc0 ++ c0)) (free_labs (LENGTH rs.rbvars) Ce)` by ( fs[Abbr`cce`] ) >>
  discharge_hyps >- (
    simp[Abbr`bs1`] >>
    conj_asm1_tac >- (
      simp[FILTER_APPEND,ALL_DISTINCT_APPEND] >>
      fsrw_tac[DNF_ss][EVERY_MEM,MEM_FILTER,is_Label_rwt,MEM_MAP,MEM_GENLIST,between_def] >>
      rw[] >> spose_not_then strip_assume_tac >> res_tac >> DECIDE_TAC ) >>
    conj_tac >- PROVE_TAC[code_env_cd_append] >>
    conj_tac >- PROVE_TAC[code_env_cd_append] >>
    conj_tac >- (
      match_mp_tac SUBSET_TRANS >>
      HINT_EXISTS_TAC >>
      simp[Abbr`Ce0`] >>
      match_mp_tac free_vars_exp_to_Cexp_matchable >>
      simp[] >>
      fs[Cenv_bs_def,EVERY2_EVERY] >>
      fsrw_tac[DNF_ss][SUBSET_DEF,is_null_def,MEM_MAP,MEM_FLAT] >>
      rw[] >> rfs[] >> res_tac >> fs[] >> metis_tac[]) >>
    conj_tac >- (
      match_mp_tac Cenv_bs_append_code >>
      qmatch_assum_abbrev_tac`bc_next bs bs1` >>
      qexists_tac`bs1 with code := bc0 ++ c0` >>
      simp[bc_state_component_equality,Abbr`bs1`] >>
      match_mp_tac Cenv_bs_append_code >>
      Q.PAT_ABBREV_TAC`pc = SUM (MAP X Y)` >>
      qexists_tac`bs with <| pc := pc ; code := bc0 |>` >>
      simp[bc_state_component_equality,Cenv_bs_with_pc]) >>
    fsrw_tac[DNF_ss,ARITH_ss][EVERY_MEM,between_def,MEM_MAP,FILTER_APPEND,ALL_DISTINCT_APPEND,MEM_FILTER,is_Label_rwt,MEM_GENLIST] >>
    rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
  disch_then(qspecl_then[`REVERSE bc1`]mp_tac o CONJUNCT1) >>
  simp[Abbr`bs1`] >>
  simp_tac(srw_ss()++DNF_ss)[code_for_push_def,LET_THM] >>
  map_every qx_gen_tac[`rf`,`rd'`,`bv`] >> strip_tac >>
  qmatch_assum_abbrev_tac`bc_next^* bs1 bs2` >>
  `∃Cvs. (Cv = CConv 0 Cvs) ∧ EVERY2 syneq (MAP (v_to_Cv cm) vs1) Cvs` by (
    qpat_assum`syneq X Cv0`mp_tac >>
    simp[v_to_Cv_def,Once IntLangTheory.syneq_cases] >> rw[] >>
    qpat_assum`syneq X Cv`mp_tac >>
    simp[Once IntLangTheory.syneq_cases] >>
    rw[Abbr`cm`] >> fs[vs_to_Cvs_MAP] >>
    metis_tac[EVERY2_syneq_trans] ) >>
  qpat_assum`Cv_bv X Cv bv`mp_tac >>
  simp[Once Cv_bv_cases] >>
  disch_then(Q.X_CHOOSE_THEN`bvs`strip_assume_tac) >>
  last_x_assum(qspecl_then[`bs2 with code := bc0++c0++REVERSE bc1++c1 `,`bc0++c0++REVERSE bc1`,`4`,`bvs`,`bs.stack`]mp_tac) >>
  discharge_hyps >- (
    simp[Abbr`bs2`] >>
    qpat_assum`PARTITION X Y = Z`(assume_tac o SYM) >>
    fs[PARTITION_DEF] >>
    imp_res_tac PART_LENGTH >>
    imp_res_tac PARTs_HAVE_PROP >>
    rfs[] >>
    conj_tac >- (
      rw[] >> fs[EVERY2_EVERY] >>
      qpat_assum`syneq Cv0 X`mp_tac >>
      qpat_assum`syneq X Cv0`mp_tac >>
      simp[Once IntLangTheory.syneq_cases] ) >>
    conj_tac >- (
      qpat_assum`Cenv_bs rd Cs Cenv renv (LENGTH rs.rbvars)X `mp_tac >>
      simp[Cenv_bs_def,EVERY2_EVERY,Abbr`renv`,EVERY_MEM,FORALL_PROD,MEM_ZIP,GSYM LEFT_FORALL_IMP_THM,CompilerLibTheory.el_check_def]>>
      strip_tac >>
      spose_not_then strip_assume_tac >>
      first_x_assum(qspec_then`LENGTH bs.stack`mp_tac) >>
      simp[] ) >>
    simp[SUBSET_DEF] >>
    metis_tac[ALL_DISTINCT_PERM,PARTITION_DEF,PERM_PARTITION,ALL_DISTINCT_APPEND] ) >>
  strip_tac >>
  qmatch_assum_abbrev_tac`bc_next^* bs2' bs3'` >>
  `bc_next^* (bs2' with code := bc0++c0++REVERSE bc1++c1++c2) (bs3' with code := bc0++c0++REVERSE bc1++c1++c2)` by (
    match_mp_tac RTC_bc_next_append_code >>
    map_every qexists_tac[`bs2'`,`bs3'`] >>
    simp[Abbr`bs2'`,Abbr`bs3'`,bc_state_component_equality] ) >>
  first_x_assum(qspecl_then[`bs3' with code := bc0 ++ c0 ++ REVERSE bc1 ++ c1 ++ c2`,`bc0++c0++REVERSE bc1++c1`,`4`,`bvs`]mp_tac) >>
  simp[Abbr`bs3'`] >>
  discharge_hyps >- (
    `LENGTH vv0 + LENGTH vv1 = LENGTH vars` by
      metis_tac[PART_LENGTH,PARTITION_DEF,LENGTH_NIL,ADD_0,ADD_ASSOC] >>
    fs[EVERY2_EVERY] ) >>
  strip_tac >>
  qmatch_assum_abbrev_tac`bc_next^* bs4 bs5` >>
  map_every qexists_tac[`TL bs5.stack`,`rf`,`rd'`
    ,`REVERSE (DROP (LENGTH vv0) Cvs) ++
      GENLIST (λx. if x < LENGTH rs.rbvars ∧ MEM (EL x rs.rbvars) vv0 then EL (THE (find_index (EL x rs.rbvars) vv0 0)) Cvs else EL x Cenv) (LENGTH Cenv)`
    ,`Cs'`] >>
  conj_tac >- (
    match_mp_tac (SIMP_RULE std_ss [transitive_def]RTC_TRANSITIVE) >>
    qexists_tac`bs2` >>
    conj_tac >- metis_tac[RTC_TRANSITIVE,transitive_def,RTC_SUBSET] >>
    qmatch_assum_abbrev_tac`bc_next^* bs2' bs3'` >>
    `bc_next^* (bs2' with code := bs.code) (bs3' with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs2'`,`bs3'`] >>
      simp[bc_state_component_equality,Abbr`bs2'`,Abbr`bs3'`] ) >>
    `bc_next^* (bs4 with code := bs.code) (bs5 with code := bs.code)` by (
      match_mp_tac RTC_bc_next_append_code >>
      map_every qexists_tac[`bs4`,`bs5`] >>
      simp[bc_state_component_equality,Abbr`bs4`,Abbr`bs5`] ) >>
    `bs4 with code := bs.code = bs3' with code := bs.code` by (
      simp[Abbr`bs4`,Abbr`bs3'`,bc_state_component_equality,Abbr`bs2'`] ) >>
    `bs2 = bs2' with code := bs.code` by (
      simp[Abbr`bs2'`,bc_state_component_equality,Abbr`bs2`] ) >>
    `bc_next^* bs2 (bs5 with code := bs.code)` by metis_tac[RTC_TRANSITIVE,transitive_def] >>
    simp_tac std_ss [Once RTC_CASES2] >> disj2_tac >>
    HINT_EXISTS_TAC >> simp[] >>
    qmatch_abbrev_tac`bc_next bs6 bs7` >>
    `bc_fetch bs6 = SOME (Stack Pop)` by (
      match_mp_tac bc_fetch_next_addr >>
      simp[Abbr`bs6`] >>
      CONV_TAC SWAP_EXISTS_CONV >>
      qexists_tac`[]` >> simp[Abbr`bs5`] ) >>
    simp[bc_eval1_thm,bc_eval1_def] >>
    simp[bc_eval_stack_def,Abbr`bs6`,bump_pc_def] >>
    simp[Abbr`bs5`,Abbr`bs7`,bc_state_component_equality,bc_eval_stack_def] >>
    simp[Abbr`bs2'`,SUM_APPEND,FILTER_APPEND,ADD1,Abbr`bs2`] ) >>
  simp[Abbr`bs5`] >>
  ntac 5 (pop_assum kall_tac) >>
  conj_tac >- (
    qpat_assum`PARTITION X Y = Z`(assume_tac o SYM) >>
    fs[PARTITION_DEF]>>
    imp_res_tac PART_LENGTH >>
    imp_res_tac PART_MEM >>
    imp_res_tac PARTs_HAVE_PROP >>
    fs[MAP_ZIP] >>
    fs[EXTENSION] >> metis_tac[] ) >>
  conj_tac >- (
    simp[ALL_DISTINCT_APPEND,ALL_DISTINCT_REVERSE] >>
    qpat_assum`PARTITION X Y = Z`(mp_tac o SYM) >>
    qpat_assum`ALL_DISTINCT vars`mp_tac >>
    qpat_assum`set rs.rbvars = X`(SUBST1_TAC o SYM) >>
    rpt (pop_assum kall_tac) >>
    simp[PARTITION_DEF] >>
    rw[] >> imp_res_tac PART_MEM >>
    imp_res_tac PARTs_HAVE_PROP >>
    imp_res_tac PERM_PART >> fs[] >>
    metis_tac[ALL_DISTINCT_PERM,ALL_DISTINCT_APPEND] ) >>
  conj_tac >- metis_tac[EVERY2_syneq_trans] >>
  conj_tac >- (
    match_mp_tac EVERY2_APPEND_suff >>
    conj_tac >- (
      simp[MAP_REVERSE,env_to_Cenv_MAP] >>
      match_mp_tac EVERY2_REVERSE >>
      match_mp_tac EVERY2_syneq_trans >>
      qexists_tac`DROP (LENGTH vv0) (MAP (v_to_Cv cm) vs)` >>
      reverse conj_tac >- (
        match_mp_tac EVERY2_DROP >>
        simp[] >>
        conj_tac >- metis_tac[EVERY2_syneq_trans] >>
        qsuff_tac`LENGTH (vv0 ++ vv1) = LENGTH vars`>-simp[] >>
        metis_tac[PERM_PARTITION,PERM_LENGTH] ) >>
      simp[MAP_MAP_o,combinTheory.o_DEF] >>
      qmatch_abbrev_tac`LIST_REL R l1 l2` >>
      qsuff_tac`l1 = l2`>-metis_tac[EVERY2_syneq_refl] >>
      simp[Abbr`l1`,Abbr`l2`,LIST_EQ_REWRITE] >>
      fs[EVERY2_EVERY,PARTITION_DEF] >>
      `LENGTH vs = LENGTH vv0 + LENGTH vv1` by (
        qpat_assum`X = (vv0,vv1)`(assume_tac o SYM) >>
        imp_res_tac PART_LENGTH >> fs[] ) >>
      simp[] >>
      rw[EL_MAP] >>
      simp[EL_DROP,EL_MAP] >>
      `ALL_DISTINCT (vv0 ++ vv1)` by (
        metis_tac[ALL_DISTINCT_PERM,PERM_PART,APPEND_NIL] ) >>
      ntac 3 (pop_assum mp_tac) >>
      rpt (pop_assum kall_tac) >>
      rw[] >>
      Q.PAT_ABBREV_TAC`al = ZIP (vv0++vv1,vs)` >>
      `ALL_DISTINCT (MAP FST al)` by (
        simp[Abbr`al`,MAP_ZIP] ) >>
      `MEM (EL x vv1, EL (x + LENGTH vv0) vs) al` by (
        simp[Abbr`al`,MEM_ZIP] >>
        qexists_tac`x + LENGTH vv0` >>
        simp[EL_APPEND2] ) >>
      imp_res_tac ALOOKUP_ALL_DISTINCT_MEM >>
      simp[ALOOKUP_APPEND] ) >>
    map_every qunabbrev_tac[`Cenv0`,`env1`] >>
    qpat_assum`EVERY2 syneq X Cenv`mp_tac >>

    reverse conj_tac >- (
      match_mp_tac EVERY2_syneq_trans >>
      qexists_tac`Cenv0` >> simp[] >>
      simp[Abbr`Cenv0`,Abbr`env1`] >>

    simp[]

  conj_tac >- (
    `v_to_ov rd'.sm v = Cv_to_ov (FST(SND rs.contab)) rd'.sm (v_to_Cv (cmap rs.contab) v)` by (
      match_mp_tac EQ_SYM >>
      match_mp_tac (CONJUNCT1 v_to_Cv_ov) >>
      qabbrev_tac`ct=rs.contab` >>
      PairCases_on`ct` >> fs[good_contab_def] >>
      qspecl_then[`menv`,`cenv`,`s`,`env`,`exp`,`s',Rval v`]mp_tac (CONJUNCT1 evaluate_all_cns) >>
      fs[good_cmap_def,closed_under_cenv_def] >>
      fs[SUBSET_DEF,MEM_MAP,EXISTS_PROD] >>
      metis_tac[]) >>
    qmatch_assum_abbrev_tac`v_to_ov rd'.sm v = Cv_to_ov m ss v1` >>
    `Cv_to_ov m ss v1 = Cv_to_ov m ss Cv` by PROVE_TAC[syneq_ov,syneq_trans] >>
    simp[] >>
    match_mp_tac (MP_CANON Cv_bv_ov) >>
    HINT_EXISTS_TAC >>
    simp[Abbr`ss`] ) >>
  conj_tac >- PROVE_TAC[EVERY2_syneq_trans] >>
  qspecl_then[`Cs`,`Cenv`,`Ce`,`Cs',Rval Cv`]mp_tac(CONJUNCT1 Cevaluate_Clocs) >>
  simp[] >> strip_tac >>
  qspecl_then[`Cs`,`Cenv`,`Ce`,`Cs',Rval Cv`]mp_tac(CONJUNCT1 Cevaluate_store_SUBSET) >>
  simp[] >> strip_tac >>
  conj_tac >- (
    match_mp_tac SUBSET_TRANS >>
    qexists_tac`count (LENGTH Cs)` >>
    simp[] >>
    simp[SUBSET_DEF] ) >>
  qspecl_then[`Cs`,`Cenv`,`Ce`,`Cs',Rval Cv`]mp_tac(CONJUNCT1 Cevaluate_all_vlabs) >>
  simp[] >> strip_tac >>
  qspecl_then[`Cs`,`Cenv`,`Ce`,`Cs',Rval Cv`]mp_tac(CONJUNCT1 Cevaluate_vlabs) >>
  simp[SUBSET_DEF,FORALL_PROD] >> strip_tac >>
  rfs[EVERY_MEM] >>
  `ALL_DISTINCT (FILTER is_Label (bc0 ++ c0 ++ REVERSE bc1))` by (
    simp[FILTER_APPEND,ALL_DISTINCT_APPEND,FILTER_REVERSE,ALL_DISTINCT_REVERSE] >>
    fsrw_tac[DNF_ss][MEM_FILTER,is_Label_rwt,EVERY_MAP,EVERY_FILTER,MEM_GENLIST,between_def,MEM_MAP] >>
    fsrw_tac[DNF_ss][EVERY_MEM] >>
    rw[] >> spose_not_then strip_assume_tac >> res_tac >> fsrw_tac[ARITH_ss][] ) >>
  conj_tac >- PROVE_TAC[code_env_cd_append,APPEND_ASSOC] >>
  conj_tac >- PROVE_TAC[code_env_cd_append,APPEND_ASSOC] >>
  match_mp_tac Cenv_bs_append_code >>
  HINT_EXISTS_TAC >>
  simp[bc_state_component_equality])

(* TODO: move?*)
val FV_dec_def = Define`
  (FV_dec (Dlet p e) = FV (Mat (Lit ARB) [(p,e)])) ∧
  (FV_dec (Dletrec defs) = FV (Letrec defs (Lit ARB))) ∧
  (FV_dec (Dtype _) = {})`
val _ = export_rewrites["FV_dec_def"]

(*
val compile_dec_val = store_thm("compile_dec_val",
  ``∀mn menv cenv s env dec res. evaluate_dec mn menv cenv s env dec res ⇒
     ∀s' cenv' env' rs rs' rd bc bs bc0.
      (res = (s',Rval (cenv',env'))) ∧
      (mn = NONE) ∧ is_null menv ∧
      EVERY (closed menv) s ∧
      EVERY (closed menv) (MAP SND env) ∧
      EVERY (EVERY (closed menv) o MAP SND) (MAP SND menv) ∧
      FV_dec dec ⊆ set (MAP (Short o FST) env) ∪ menv_dom menv ∧
      closed_under_cenv cenv menv env s ∧
      (∀v. v ∈ env_range env ∨ MEM v s ⇒ all_locs v ⊆ count (LENGTH s)) ∧
      LENGTH s' ≤ LENGTH rd.sm ∧
      env_rs cenv env rs rd s (bs with code := bc0) ∧
      (compile_dec rs dec = (rs',bc)) ∧
      (bs.code = bc0 ++ bc) ∧
      (bs.pc = next_addr bs.inst_length bc0) ∧
      ALL_DISTINCT (FILTER is_Label bc0) ∧
      EVERY (combin$C $< rs.rnext_label o dest_Label) (FILTER is_Label bc0)
      ⇒
      ∃bvs rf rd'.
      let bs' = bs with <|pc := next_addr bs.inst_length (bc0 ++ bc);
                          stack := bvs ++ bs.stack; refs := rf|> in
      bc_next^* bs bs' ∧
      env_rs cenv' env' rs' rd' s' bs'``,
  ho_match_mp_tac evaluate_dec_ind >>
  strip_tac >- (
    rpt gen_tac >>
    simp[compile_dec_def,compile_Cexp_def,GSYM LEFT_FORALL_IMP_THM] >>
    strip_tac >> rpt gen_tac >>
    Q.PAT_ABBREV_TAC`Ce0 = exp_to_Cexp X exp` >>
    Q.PAT_ABBREV_TAC`Cp = pat_to_Cpat X p` >>
    Q.PAT_ABBREV_TAC`q = label_closures Y X Ce0` >>
    PairCases_on`q`>>PairCases_on`Cp`>>simp[]>>
    compile_dec_def
    strip_tac >>
    qspecl_then[`menv`,`cenv`,`s`,`env`,`exp`,`(s',Rval v)`] mp_tac (CONJUNCT1 exp_to_Cexp_thm1) >>
    simp[] >>
    disch_then (qspec_then `cmap rs.contab` mp_tac) >>
    fs[env_rs_def] >>
    simp[FORALL_PROD,GSYM LEFT_FORALL_IMP_THM] >>
    simp_tac(srw_ss()++DNF_ss)[] >>
    simp[compile_dec_def,compile_Cexp_def] >> rw[] >>

    ... ) >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[compile_dec_def,FST_triple,compile_Cexp_def] >>
    ... ) >>
  strip_tac >- rw[] >>
  strip_tac >- (
    rw[compile_dec_def] >>
    FOLDL_number_constructors_thm
    ... ) >>
  strip_tac >- rw[])
*)

val _ = export_theory()
