-- P2-06 Stage 6 Final Calibration / exam-operations matrix.
-- All synthetic learner writes are rollback-only. Legacy and academic evidence must remain unchanged.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_user uuid:='00000000-0000-4000-8000-000000002206'::uuid;
  v_ops jsonb;
  v_ops2 jsonb;
  v_stage6_def text;
  v_before jsonb;
  v_after jsonb;
BEGIN
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then raise exception 'P2-06 active canonical program missing'; end if;

  if to_regprocedure('private.exam_prep_exam_ops_status_v1(uuid,bigint,text)') is null
     or to_regprocedure('public.get_exam_prep_exam_ops_safe_v1(text)') is null
     or to_regprocedure('public.save_my_exam_prep_exam_appointment_v1(text,timestamptz)') is null
     or to_regprocedure('public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean)') is null
     or to_regprocedure('public.get_exam_prep_final_calibration_safe_v1(text)') is null
  then raise exception 'P2-06 exam-operations API surface missing'; end if;

  if has_function_privilege('anon','public.get_exam_prep_exam_ops_safe_v1(text)','EXECUTE')
     or has_function_privilege('anon','public.save_my_exam_prep_exam_appointment_v1(text,timestamptz)','EXECUTE')
     or has_function_privilege('anon','public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean)','EXECUTE')
  then raise exception 'P2-06 anon must not access exam-operations APIs'; end if;

  if not has_function_privilege('authenticated','public.get_exam_prep_exam_ops_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.save_my_exam_prep_exam_appointment_v1(text,timestamptz)','EXECUTE')
     or not has_function_privilege('authenticated','public.set_my_exam_prep_exam_ops_confirmation_v1(text,text,boolean)','EXECUTE')
  then raise exception 'P2-06 authenticated exam-operations API grant missing'; end if;

  if not exists(
    select 1 from private.exam_prep_stage6_rules
    where status='active'
      and require_stage5_readiness
      and allow_new_mastery_claims=false
  ) then raise exception 'P2-06 Stage-6 no-new-mastery rule missing'; end if;

  if (select count(*) from private.exam_prep_exam_ops_checklist_items where active)<>7
     or (select count(*) from private.exam_prep_exam_ops_checklist_items
         where active
           and nullif(btrim(title_en),'') is not null
           and nullif(btrim(title_ru),'') is not null
           and nullif(btrim(title_uz),'') is not null)<>7
  then raise exception 'P2-06 expected seven trilingual active checklist items'; end if;

  if not exists(
    select 1 from private.exam_prep_exam_ops_checklist_items
    where item_code='major_work_stop_understood'
      and active and item_kind='taper'
      and title_en like '%24 hours%'
      and title_ru like '%24 часа%'
      and title_uz like '%24 soat%'
  ) then raise exception 'P2-06 24-hour major-work stop checklist item missing'; end if;

  if exists(select 1 from private.exam_prep_exam_calendar where status='final_verified' and source_url not like 'https://%cambridgeinternational.org/%')
  then raise exception 'P2-06 verified final timetable source is not official Cambridge'; end if;

  select pg_get_functiondef('public.get_exam_prep_final_calibration_safe_v1(text)'::regprocedure)
  into v_stage6_def;
  if position('exam_operations' in lower(v_stage6_def))=0
     or position('new_mastery_allowed'',false' in lower(v_stage6_def))=0
  then raise exception 'P2-06 final calibration is not bound to safe exam operations'; end if;

  insert into auth.users(id,email,role,aud)
  values(v_user,'p206-final-calibration@invalid.example','authenticated','authenticated');

  insert into public.users(id,first_name,last_name,language_code)
  values(v_user,'P206','Final Calibration','en');

  insert into private.exam_prep_feature_entitlements(
    user_id,entitlement_status,core_access,ai_assist,mentor_care_entitled,cohort_key,valid_from
  ) values(v_user,'active',true,false,false,'p206-final-calibration',now());

  insert into private.exam_prep_exam_profiles(
    user_id,program_version_id,exam_series,target_grade,
    total_student_hours_available,mathematics_hours_budget,active_week_no,
    created_by,updated_by
  ) values(v_user,v_program,'June 2027','A',12,6,33,v_user,v_user);

  update private.exam_prep_feature_config
  set rollout_state='controlled_beta',core_enabled=true,
      ai_enabled=false,mentor_enabled=false,kill_switch=false,updated_at=now()
  where id=1;

  perform set_config('request.jwt.claim.sub',v_user::text,true);
  perform set_config('request.jwt.claim.role','authenticated',true);

  select jsonb_build_object(
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'evidence_events',(select count(*) from private.exam_prep_evidence_events),
    'skill_states',(select count(*) from private.exam_prep_skill_states),
    'stage_states',(select count(*) from private.exam_prep_stage_states),
    'correction_cases',(select count(*) from private.exam_prep_correction_cases),
    'timed_results',(select count(*) from private.exam_prep_timed_attempt_results)
  ) into v_before;

  v_ops:=public.save_my_exam_prep_exam_appointment_v1('P1',clock_timestamp()+interval '48 hours');

  if v_ops->>'component_code'<>'P1'
     or v_ops->>'calibration_mode'<>'targeted_taper'
     or coalesce((v_ops->>'school_start_time_confirmed')::boolean,false) is not true
     or (v_ops->>'major_work_stop_rule_hours')::int<>24
     or ((v_ops->>'scheduled_start_at')::timestamptz-(v_ops->>'major_work_stop_at')::timestamptz)<>interval '24 hours'
     or coalesce((v_ops->>'new_mastery_allowed')::boolean,true)
     or coalesce((v_ops->>'readiness_can_be_created_by_checklist')::boolean,true)
  then raise exception 'P2-06 targeted-taper appointment payload mismatch=%',v_ops; end if;

  v_ops:=public.set_my_exam_prep_exam_ops_confirmation_v1('P1','school_date_session_checked',true);
  if (v_ops->>'checklist_confirmed')::int<>1
     or (v_ops->>'checklist_total')::int<>7
     or coalesce((select (x->>'confirmed')::boolean
                  from jsonb_array_elements(v_ops->'checklist_items') x
                  where x->>'item_code'='school_date_session_checked'),false) is not true
  then raise exception 'P2-06 checklist confirmation was not persisted inside rollback fixture=%',v_ops; end if;

  v_ops2:=public.save_my_exam_prep_exam_appointment_v1('P1',clock_timestamp()+interval '23 hours');
  if v_ops2->>'calibration_mode'<>'stop_major_work'
     or not exists(
       select 1 from jsonb_array_elements(v_ops2->'notifications') n
       where n->>'code'='major_work_stop_active'
     )
  then raise exception 'P2-06 24-hour stop mode did not activate=%',v_ops2; end if;

  if (public.get_exam_prep_exam_ops_safe_v1('P1')->>'calibration_mode')<>'stop_major_work'
  then raise exception 'P2-06 safe exam-ops reader does not reflect confirmed start time'; end if;

  begin
    perform public.get_exam_prep_exam_ops_safe_v1('P3');
    raise exception 'P2-06 invalid component unexpectedly accepted';
  exception when others then
    if sqlerrm not like '%exam_prep_bad_component%' then raise; end if;
  end;

  select jsonb_build_object(
    'practice_answers',(select count(*) from public.practice_answers),
    'tour_answers',(select count(*) from public.tour_answers),
    'certificates',(select count(*) from public.certificates),
    'evidence_events',(select count(*) from private.exam_prep_evidence_events),
    'skill_states',(select count(*) from private.exam_prep_skill_states),
    'stage_states',(select count(*) from private.exam_prep_stage_states),
    'correction_cases',(select count(*) from private.exam_prep_correction_cases),
    'timed_results',(select count(*) from private.exam_prep_timed_attempt_results)
  ) into v_after;

  if v_after<>v_before then
    raise exception 'P2-06 exam operations mutated academic/legacy state before=% after=%',v_before,v_after;
  end if;
END
$$;

ROLLBACK;

DO $$
BEGIN
  if exists(select 1 from auth.users where email='p206-final-calibration@invalid.example')
     or exists(select 1 from public.users where id='00000000-0000-4000-8000-000000002206'::uuid)
  then raise exception 'P2-06 rollback fixture residue remains'; end if;
END
$$;

\echo 'P2-06 Final Calibration / exam operations matrix: GREEN'
