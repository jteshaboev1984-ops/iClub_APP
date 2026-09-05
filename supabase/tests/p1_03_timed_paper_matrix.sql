\set ON_ERROR_STOP on
\echo 'P1-03 timed / modified-paper matrix'

begin;

do $$
declare
  v_program bigint;
  v_cv bigint;
  v_question bigint;
  v_meta bigint;
  v_written bigint;
  v_ass bigint;
  v_bad_ass bigint;
  v_bad_q bigint;
  v_p1_profile bigint;
  v_p5_profile bigint;
  v_core uuid := '00000000-0000-4000-8000-000000001031'::uuid;
  v_ai uuid := '00000000-0000-4000-8000-000000001032'::uuid;
  v_mentor uuid := '00000000-0000-4000-8000-000000001033'::uuid;
  v_uid uuid;
  v_auth jsonb;
  v_start jsonb;
  v_submit jsonb;
  v_view jsonb;
  v_result jsonb;
  v_review jsonb;
  v_catalog jsonb;
  v_session uuid;
  v_sessions uuid[] := '{}'::uuid[];
  v_norm jsonb;
  v_norm_core jsonb;
  v_state_core jsonb;
  v_state_ai jsonb;
  v_state_mentor jsonb;
  v_failed boolean;
  v_direct_auth uuid;
  v_after_session uuid;
  v_q public.questions%rowtype;
  v_w private.exam_prep_written_tasks%rowtype;
  v_after_result jsonb;
begin
  select id into v_program from private.exam_prep_program_versions
    where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  select id into v_cv from private.exam_prep_content_versions
    where content_version='p1_foundations_runway_v1' and component_code='P1' and status='published';
  select id into v_written from private.exam_prep_written_tasks
    where content_version_id=v_cv and task_key='P1QUA01-W01' and lifecycle_state='published';
  select id into v_p1_profile from private.exam_prep_component_paper_profiles
    where program_version_id=v_program and component_code='P1' and profile_version='9709_2026_2027_v1' and status='published';
  select id into v_p5_profile from private.exam_prep_component_paper_profiles
    where program_version_id=v_program and component_code='P5' and profile_version='9709_2026_2027_v1' and status='published';
  if v_program is null or v_cv is null or v_written is null or v_p1_profile is null or v_p5_profile is null then
    raise exception 'P1-03 matrix: required governed baseline missing';
  end if;

  -- Official component timing and proportional modified-paper rule.
  if private.exam_prep_timed_time_limit_v1(v_p1_profile,'official_full',75,null)<>6600 then raise exception 'P1-03 matrix: P1 official full timing'; end if;
  if private.exam_prep_timed_time_limit_v1(v_p5_profile,'official_full',50,null)<>4500 then raise exception 'P1-03 matrix: P5 official full timing'; end if;
  if private.exam_prep_timed_time_limit_v1(v_p1_profile,'proportional_marks',20,null)<>1760 then raise exception 'P1-03 matrix: P1 proportional timing'; end if;
  if private.exam_prep_timed_time_limit_v1(v_p5_profile,'proportional_marks',20,null)<>1800 then raise exception 'P1-03 matrix: P5 proportional timing'; end if;
  if private.exam_prep_timed_min_stage_v1('timed_section')<>2
     or private.exam_prep_timed_min_stage_v1('modified_paper')<>2
     or private.exam_prep_timed_min_stage_v1('diagnostic_full')<>2
     or private.exam_prep_timed_min_stage_v1('full_paper')<>3 then
    raise exception 'P1-03 matrix: timed operational-stage mapping drift';
  end if;
  v_failed:=false;
  begin
    perform private.exam_prep_timed_time_limit_v1(v_p1_profile,'proportional_marks',76,null);
  exception when others then
    if position('exam_prep_modified_marks_exceed_official' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 matrix: modified marks > official did not fail'; end if;

  -- One original, inactive, governed TIMED reserve item for the isolated test.
  insert into public.questions(
    subject_id,topic,subtopic,difficulty,qtype,question_text,options_text,correct_answer,explanation,image_url,is_active,
    question_text_ru,question_text_uz,question_text_en,options_text_ru,options_text_uz,options_text_en,
    explanation_ru,explanation_uz,explanation_en,book_ref,time_limit_sec,quality_flag,quality_status
  ) values(
    5,'P1 P1-03 isolated test','P1-QUA-01','medium','mcq','Which value equals 2 + 3?','["5","4","6","7"]','A','2 + 3 = 5.',null,false,
    'Чему равно 2 + 3?','2 + 3 nechaga teng?','Which value equals 2 + 3?',
    '["5","4","6","7"]','["5","4","6","7"]','["5","4","6","7"]',
    '2 + 3 = 5.','2 + 3 = 5.','2 + 3 = 5.','ExamPrep:P103:isolated-timed-q1',60,null,'draft'
  ) returning id into v_question;
  select * into v_q from public.questions where id=v_question;

  insert into private.exam_prep_question_content_meta(
    content_version_id,content_key,question_id,primary_skill_code,secondary_skill_codes,reserve_role,exposure_state,lifecycle_state,
    originality_attestation,provenance_note,official_scope_ref,coursebook_mapping_ref,
    copyright_status,qa_scope_status,qa_math_status,qa_language_status,qa_technical_status,diagnostic_rule_status,question_snapshot_md5,approved_at
  ) values(
    v_cv,'P103-TIMED-Q1',v_question,'P1-QUA-01','{}'::text[],'timed','withheld','reserve',
    'Synthetic isolated P1-03 CI fixture; original and rolled back.','P1-03 timed workflow contract fixture.',
    'Cambridge 9709 P1 timing workflow test','No coursebook question copied; synthetic arithmetic fixture only.',
    'pass','pass','pass','pass','pass','not_applicable',
    md5(concat_ws(chr(31),v_q.id::text,v_q.subject_id::text,coalesce(v_q.topic,''),coalesce(v_q.subtopic,''),
      coalesce(v_q.difficulty,''),coalesce(v_q.qtype,''),coalesce(v_q.question_text,''),coalesce(v_q.options_text,''),
      coalesce(v_q.correct_answer,''),coalesce(v_q.explanation,''),coalesce(v_q.image_url,''),coalesce(v_q.is_active::text,''),
      coalesce(v_q.question_text_ru,''),coalesce(v_q.question_text_uz,''),coalesce(v_q.question_text_en,''),
      coalesce(v_q.options_text_ru,''),coalesce(v_q.options_text_uz,''),coalesce(v_q.options_text_en,''),
      coalesce(v_q.explanation_ru,''),coalesce(v_q.explanation_uz,''),coalesce(v_q.explanation_en,''),
      coalesce(v_q.book_ref,''),coalesce(v_q.time_limit_sec::text,''),coalesce(v_q.quality_flag,''),coalesce(v_q.quality_status,''))),now()
  ) returning id into v_meta;

  -- Two-item 20-minute section: 1 objective mark + 3 written marks.
  insert into private.exam_prep_assessments(
    content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,approved_at
  ) values(v_cv,'p103_isolated_section','av1','P1','timed','published','P1-03 isolated timed section','P1-03 изолированный timed section','P1-03 ajratilgan timed section',now())
  returning id into v_ass;
  insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout)
  values(v_ass,1,v_question,null,'P1-QUA-01','timed',true),(v_ass,2,null,v_written,'P1-QUA-01','written',true);
  insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks)
  values(v_ass,1,1),(v_ass,2,3);
  insert into private.exam_prep_timed_assessment_contracts(
    assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
    strict_timing,comparison_scope,comparability_key,status,published_at
  ) values(v_ass,v_p1_profile,'tcv1','timed_section','fixed_section',4,1200,true,'section','p103-isolated-section-v1','published',now());

  -- Publication must reject assessment role spoofing if underlying governed metadata is not TIMED.
  select q.id into v_bad_q
  from private.exam_prep_question_content_meta m join public.questions q on q.id=m.question_id
  where m.content_version_id=v_cv and m.content_key='P1QUA01-M01';
  insert into private.exam_prep_assessments(
    content_version_id,assessment_key,assessment_version,component_code,assessment_type,status,title_en,title_ru,title_uz,approved_at
  ) values(v_cv,'p103_bad_role','av1','P1','timed','published','Bad-role negative fixture','Negative fixture','Negative fixture',now())
  returning id into v_bad_ass;
  insert into private.exam_prep_assessment_items(assessment_id,item_order,question_id,primary_skill_code,reserve_role,is_holdout)
  values(v_bad_ass,1,v_bad_q,'P1-QUA-01','timed',true);
  insert into private.exam_prep_timed_assessment_items(assessment_id,item_order,max_marks) values(v_bad_ass,1,1);
  v_failed:=false;
  begin
    insert into private.exam_prep_timed_assessment_contracts(
      assessment_id,paper_profile_id,contract_version,attempt_kind,timing_rule,marks_available,fixed_time_limit_sec,
      strict_timing,comparison_scope,comparability_key,status,published_at
    ) values(v_bad_ass,v_p1_profile,'tcv1','timed_section','fixed_section',1,900,true,'section','p103-bad-role','published',now());
  exception when others then
    if position('exam_prep_timed_governed_role_mismatch' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 matrix: governed role spoofing was accepted'; end if;

  -- Synthetic service modes. Global capabilities are ON only inside this rolled-back CI transaction;
  -- every academic path below is still the same Core deterministic RPC path.
  insert into auth.users(id,email,role,aud) values
    (v_core,'p103-core@invalid.example','authenticated','authenticated'),
    (v_ai,'p103-ai@invalid.example','authenticated','authenticated'),
    (v_mentor,'p103-mentor@invalid.example','authenticated','authenticated');
  insert into public.users(id,first_name,last_name,language_code) values
    (v_core,'P103','Core','en'),(v_ai,'P103','AI','en'),(v_mentor,'P103','Mentor','en');
  insert into private.exam_prep_feature_entitlements(user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from)
  values
    (v_core,'active',true,false,false,'p103-ci',now()-interval '1 hour'),
    (v_ai,'active',true,true,false,'p103-ci',now()-interval '1 hour'),
    (v_mentor,'active',true,false,true,'p103-ci',now()-interval '1 hour');
  update private.exam_prep_feature_config
    set rollout_state='controlled_beta',core_enabled=true,ai_enabled=true,mentor_enabled=true,kill_switch=false,updated_at=now()
    where program_key='math_as_p1_p5';

  -- Stage gate fixture: Stage 1 must fail closed; Stage 2 unlocks sections/diagnostic-full.
  insert into private.exam_prep_stage_states(
    user_id,program_version_id,component_code,engine_version,denominator_count,l0_count,l1_count,l2_count,l3_count,
    coverage_count,coverage_pct,open_correction_count,retest_due_count,evidence_stage_candidate,operational_stage,
    stage_gate_status,app_readiness_estimate,app_readiness_reason
  ) values
    (v_core,v_program,'P1','objective_state_v1',45,45,0,0,0,0,0,0,0,1,1,'synthetic_stage1_fixture',false,'P1-03 rollback-only fixture'),
    (v_ai,v_program,'P1','objective_state_v1',45,45,0,0,0,0,0,0,0,2,2,'synthetic_stage2_fixture',false,'P1-03 rollback-only fixture'),
    (v_mentor,v_program,'P1','objective_state_v1',45,45,0,0,0,0,0,0,0,2,2,'synthetic_stage2_fixture',false,'P1-03 rollback-only fixture');

  perform set_config('request.jwt.claim.sub',v_core::text,true);
  v_catalog:=public.get_exam_prep_timed_catalog_safe_v1('P1');
  if exists(select 1 from jsonb_array_elements(v_catalog->'assessments') j where (j->>'assessment_id')::bigint=v_ass) then
    raise exception 'P1-03 matrix: Stage 1 catalog exposed Stage 2 timed section';
  end if;
  v_failed:=false;
  begin
    perform public.authorize_exam_prep_timed_safe_v1(v_ass);
  exception when others then
    if position('exam_prep_timed_stage_gate_not_met' in sqlerrm)=0 then raise; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-03 matrix: Stage 1 direct authorization bypassed stage gate'; end if;

  update private.exam_prep_stage_states
    set evidence_stage_candidate=2,operational_stage=2,stage_gate_status='synthetic_stage2_fixture',derived_at=now()
    where user_id=v_core and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';
  v_catalog:=public.get_exam_prep_timed_catalog_safe_v1('P1');
  if not exists(select 1 from jsonb_array_elements(v_catalog->'assessments') j where (j->>'assessment_id')::bigint=v_ass and (j->>'min_operational_stage')::int=2 and (j->>'current_operational_stage')::int=2) then
    raise exception 'P1-03 matrix: Stage 2 catalog did not expose governed timed section %',v_catalog::text;
  end if;

  -- Same governed section must produce the same timing/academic contract for Core, AI and Mentor entitlements.
  foreach v_uid in array array[v_core,v_ai,v_mentor] loop
    perform set_config('request.jwt.claim.sub',v_uid::text,true);
    v_auth:=public.authorize_exam_prep_timed_safe_v1(v_ass);
    if (v_auth->>'current_operational_stage')::int<>2 or (v_auth->>'min_operational_stage')::int<>2 then
      raise exception 'P1-03 matrix: authorization stage snapshot wrong %',v_auth::text;
    end if;
    v_start:=public.start_exam_prep_session_safe_v1((v_auth->>'authorization_id')::uuid,'p103-start-'||right(v_uid::text,4)||'-0001');
    v_session:=(v_start->>'session_id')::uuid;
    v_sessions:=array_append(v_sessions,v_session);
    select timing_contract-'deadline_at' into v_norm from private.exam_prep_sessions where id=v_session;
    if v_norm_core is null then v_norm_core:=v_norm; elsif v_norm<>v_norm_core then raise exception 'P1-03 matrix: service-mode timing contract drift'; end if;
    if (v_norm->>'time_limit_sec')::int<>1200 or (v_norm->>'marks_available')::int<>4 or (v_norm->>'strict_timing')::boolean is not true then
      raise exception 'P1-03 matrix: bad immutable timing snapshot %',v_norm::text;
    end if;
  end loop;

  -- Core flow: feedback firewall while active, no generic finalizer, then post-attempt self review.
  perform set_config('request.jwt.claim.sub',v_core::text,true);
  v_session:=v_sessions[1];
  v_submit:=public.submit_exam_prep_response_safe_v1(v_session,1,'{"answer":"A"}'::jsonb,'p103-core-q1-0001',1000,'en');
  if v_submit ? 'is_correct' or v_submit ? 'selected_answer' or v_submit ? 'explanation' or v_submit ? 'diagnostic_feedback' then
    raise exception 'P1-03 matrix: active timed response leaked answer feedback: %',v_submit::text;
  end if;
  v_view:=public.get_exam_prep_session_safe_v1(v_session,'en');
  if (v_view->'items'->0) ? 'is_correct' or (v_view->'items'->0) ? 'selected_answer' then
    raise exception 'P1-03 matrix: active timed session projection leaked correctness';
  end if;
  v_failed:=false;
  begin perform public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  exception when others then if position('exam_prep_review_pack_requires_finalized_attempt' in sqlerrm)=0 then raise; end if; v_failed:=true; end;
  if not v_failed then raise exception 'P1-03 matrix: active review pack was exposed'; end if;
  v_submit:=public.submit_exam_prep_response_safe_v1(v_session,2,'{"artifact":{"working":"completed square working"}}'::jsonb,'p103-core-w1-0001',2000,'en');
  v_failed:=false;
  begin perform public.finalize_exam_prep_session_safe_v1(v_session,'p103-generic-final-0001');
  exception when others then if position('exam_prep_timed_requires_special_finalizer' in sqlerrm)=0 then raise; end if; v_failed:=true; end;
  if not v_failed then raise exception 'P1-03 matrix: generic finalizer accepted timed session'; end if;
  v_result:=public.finalize_exam_prep_timed_safe_v1(v_session,'p103-timed-final-0001','submitted');
  if (v_result->>'marks_in_time')::int<>1 or (v_result->>'pending_review_in_time_marks')::int<>3 or (v_result->>'unattempted_marks')::int<>0 then
    raise exception 'P1-03 matrix: pre-self-review decomposition wrong %',v_result::text;
  end if;
  if v_result->>'score_status'<>'pending_self_review' or (v_result->>'readiness_claim')::boolean then raise exception 'P1-03 matrix: false readiness/comparability claim'; end if;
  v_review:=public.get_exam_prep_timed_review_pack_safe_v1(v_session,'en');
  if jsonb_array_length(v_review->'items')<>1 or (v_review->'items'->0->'rubric') is null then raise exception 'P1-03 matrix: finalized written review pack missing'; end if;
  v_result:=public.submit_exam_prep_timed_written_self_mark_safe_v1(v_session,2,2,'p103-core-self-0001','Synthetic Core self review');
  if (v_result->>'marks_in_time')::int<>3 or (v_result->>'lost_answered_marks_in_time')::int<>1 or (v_result->>'pending_review_in_time_marks')::int<>0 then
    raise exception 'P1-03 matrix: self-review mark decomposition wrong %',v_result::text;
  end if;
  if (v_result->>'score_comparable')::boolean is not true or v_result->>'score_status'<>'provisional_comparable' or (v_result->>'readiness_claim')::boolean then
    raise exception 'P1-03 matrix: comparable provisional result semantics wrong %',v_result::text;
  end if;

  -- Identical AI-entitled and Mentor-entitled flows use identical deterministic Core evidence/state.
  for v_uid,v_session in select * from unnest(array[v_ai,v_mentor],array[v_sessions[2],v_sessions[3]]) loop
    perform set_config('request.jwt.claim.sub',v_uid::text,true);
    perform public.submit_exam_prep_response_safe_v1(v_session,1,'{"answer":"A"}'::jsonb,'p103-parity-q-'||right(v_uid::text,4),1000,'en');
    perform public.submit_exam_prep_response_safe_v1(v_session,2,'{"artifact":{"working":"completed square working"}}'::jsonb,'p103-parity-w-'||right(v_uid::text,4),2000,'en');
    perform public.finalize_exam_prep_timed_safe_v1(v_session,'p103-parity-f-'||right(v_uid::text,4),'submitted');
    perform public.submit_exam_prep_timed_written_self_mark_safe_v1(v_session,2,2,'p103-parity-s-'||right(v_uid::text,4),'Synthetic parity self review');
  end loop;

  perform private.rebuild_exam_prep_state_v1(v_core,'P1');
  perform private.rebuild_exam_prep_state_v1(v_ai,'P1');
  perform private.rebuild_exam_prep_state_v1(v_mentor,'P1');
  select jsonb_build_object('level',objective_level,'coverage',coverage_confirmed,'evidence_total',evidence_total,'objective',objective_evidence_count,'correct',correct_objective_count,'timed',timed_count,'written',written_count,'hold',hold_reason)
    into v_state_core from private.exam_prep_skill_states where user_id=v_core and component_code='P1' and skill_code='P1-QUA-01' and engine_version='objective_state_v1';
  select jsonb_build_object('level',objective_level,'coverage',coverage_confirmed,'evidence_total',evidence_total,'objective',objective_evidence_count,'correct',correct_objective_count,'timed',timed_count,'written',written_count,'hold',hold_reason)
    into v_state_ai from private.exam_prep_skill_states where user_id=v_ai and component_code='P1' and skill_code='P1-QUA-01' and engine_version='objective_state_v1';
  select jsonb_build_object('level',objective_level,'coverage',coverage_confirmed,'evidence_total',evidence_total,'objective',objective_evidence_count,'correct',correct_objective_count,'timed',timed_count,'written',written_count,'hold',hold_reason)
    into v_state_mentor from private.exam_prep_skill_states where user_id=v_mentor and component_code='P1' and skill_code='P1-QUA-01' and engine_version='objective_state_v1';
  if v_state_core is null or v_state_core<>v_state_ai or v_state_core<>v_state_mentor then
    raise exception 'P1-03 matrix: Core/AI/Mentor academic state drift core=% ai=% mentor=%',v_state_core::text,v_state_ai::text,v_state_mentor::text;
  end if;

  -- Rebuild is authoritative and may lower this tiny synthetic fixture below Stage 2.
  -- Restore Stage 2 only inside this rollback-only matrix so later cases continue testing timed semantics.
  update private.exam_prep_stage_states
    set evidence_stage_candidate=greatest(evidence_stage_candidate,2),operational_stage=2,
        stage_gate_status='synthetic_post_rebuild_stage2',derived_at=now()
    where user_id=v_core and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';

  -- Incomplete timed submission is legal and must be scored as unattempted marks, not as a generic incomplete-session error.
  perform set_config('request.jwt.claim.sub',v_core::text,true);
  v_auth:=public.authorize_exam_prep_timed_safe_v1(v_ass);
  v_start:=public.start_exam_prep_session_safe_v1((v_auth->>'authorization_id')::uuid,'p103-unattempted-start-0001');
  v_session:=(v_start->>'session_id')::uuid;
  perform public.submit_exam_prep_response_safe_v1(v_session,1,'{"answer":"A"}'::jsonb,'p103-unattempted-q-0001',1000,'en');
  v_result:=public.finalize_exam_prep_timed_safe_v1(v_session,'p103-unattempted-final-0001','submitted');
  if (v_result->>'answered_items')::int<>1 or (v_result->>'unattempted_items')::int<>1 or (v_result->>'unattempted_marks')::int<>3 then
    raise exception 'P1-03 matrix: unattempted classification wrong %',v_result::text;
  end if;

  -- Simulate elapsed wall time with a direct private fixture session to prove AFTER-TIME buckets.
  -- Direct insertion is test-only because waiting 20 real minutes in CI would be irrational; all bytes roll back.
  insert into private.exam_prep_session_authorizations(user_id,assessment_id,component_code,purpose,status,valid_until,reason)
    values(v_core,v_ass,'P1','timed','issued',now()+interval '1 hour','P1-03 synthetic after-time fixture') returning id into v_direct_auth;
  insert into private.exam_prep_sessions(
    authorization_id,user_id,program_version_id,content_version_id,assessment_id,assessment_version,component_code,session_type,status,
    client_idempotency_key,total_items,started_at,last_activity_at,timing_contract
  ) values(v_direct_auth,v_core,v_program,v_cv,v_ass,'av1','P1','timed','active','p103-after-session-0001',2,now()-interval '30 minutes',now(),'{}'::jsonb)
  returning id into v_after_session;
  select * into v_w from private.exam_prep_written_tasks where id=v_written;
  insert into private.exam_prep_session_items(
    session_id,item_order,item_kind,question_id,written_task_id,primary_skill_code,reserve_role,is_holdout,content_meta_id,question_snapshot_md5,item_version
  ) values
    (v_after_session,1,'question',v_question,null,'P1-QUA-01','timed',true,v_meta,v_q.id::text,null),
    (v_after_session,2,'written',null,v_written,'P1-QUA-01','written',true,null,null,'written:'||v_w.task_version);
  -- Fix the synthetic question item version to the production freeze convention; snapshot itself remains authoritative.
  update private.exam_prep_session_items set question_snapshot_md5=(select question_snapshot_md5 from private.exam_prep_question_content_meta where id=v_meta),
    item_version='qmd5:'||(select question_snapshot_md5 from private.exam_prep_question_content_meta where id=v_meta)
  where session_id=v_after_session and item_order=1;
  perform public.submit_exam_prep_response_safe_v1(v_after_session,1,'{"answer":"A"}'::jsonb,'p103-after-q-0001',1000,'en');
  perform public.submit_exam_prep_response_safe_v1(v_after_session,2,'{"artifact":{"working":"after-time working"}}'::jsonb,'p103-after-w-0001',2000,'en');
  v_after_result:=public.finalize_exam_prep_timed_safe_v1(v_after_session,'p103-after-final-0001','submitted');
  if (v_after_result->>'marks_in_time')::int<>0 or (v_after_result->>'marks_after_time')::int<>1 or (v_after_result->>'pending_review_after_time_marks')::int<>3 then
    raise exception 'P1-03 matrix: after-time objective/pending buckets wrong %',v_after_result::text;
  end if;
  v_after_result:=public.submit_exam_prep_timed_written_self_mark_safe_v1(v_after_session,2,3,'p103-after-self-0001','Synthetic after-time review');
  if (v_after_result->>'marks_in_time')::int<>0 or (v_after_result->>'marks_after_time')::int<>4 or (v_after_result->>'pending_review_after_time_marks')::int<>0 then
    raise exception 'P1-03 matrix: after-time self-review buckets wrong %',v_after_result::text;
  end if;

  -- A finalized timed result may rebuild the tiny synthetic state below Stage 2; restore only for the next auth test.
  update private.exam_prep_stage_states
    set evidence_stage_candidate=greatest(evidence_stage_candidate,2),operational_stage=2,
        stage_gate_status='synthetic_pre_active_stage2',derived_at=now()
    where user_id=v_core and program_version_id=v_program and component_code='P1' and engine_version='objective_state_v1';

  -- State rebuild already proved finalized-only. Explicitly prove an active timed response cannot enter state.
  v_auth:=public.authorize_exam_prep_timed_safe_v1(v_ass);
  v_start:=public.start_exam_prep_session_safe_v1((v_auth->>'authorization_id')::uuid,'p103-active-state-start-0001');
  v_session:=(v_start->>'session_id')::uuid;
  perform public.submit_exam_prep_response_safe_v1(v_session,1,'{"answer":"A"}'::jsonb,'p103-active-state-q-0001',500,'en');
  perform private.rebuild_exam_prep_state_v1(v_core,'P1');
  select jsonb_build_object('level',objective_level,'coverage',coverage_confirmed,'evidence_total',evidence_total,'objective',objective_evidence_count,'correct',correct_objective_count,'timed',timed_count,'written',written_count,'hold',hold_reason)
    into v_norm from private.exam_prep_skill_states where user_id=v_core and component_code='P1' and skill_code='P1-QUA-01' and engine_version='objective_state_v1';
  -- Core already has two finalized timed attempts before this active one; active response must not add a third timed evidence fact to state.
  if (v_norm->>'timed')::int<>2 then raise exception 'P1-03 matrix: active timed evidence leaked into state %',v_norm::text; end if;

end;
$$;

rollback;

\echo 'P1-03 timed / modified-paper matrix: GREEN'
