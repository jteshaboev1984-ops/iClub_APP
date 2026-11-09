-- Exact migration version 20261109110109 already applied to existing Supabase.
-- Portable logical D03 source for ephemeral PG17/other environments; production apply had extra current-bank preflight guards.
-- Main-based v2.2 selective port of the EXISTING reviewed D03 migration.
-- Original draft: 20261104110000_exam_prep_p1p5_disable_written_self_marks_v1.sql.
-- NOT APPLIED to production by this PR; only deploy after isolated signed E2E and explicit Core GO.
-- Preserve history. This sets the old direct self-mark RPC to fail closed for stale clients.
BEGIN;

-- Approved Mathematics P1/P5 v2 D03 / Package4: completed writing is NOT graded.

-- No DELETE, TRUNCATE, archived attempt mutation, rollout switch or score retrofit.

-- Assumes reviewed source definitions for current prelaunch schema. Apply only after

-- independent combined exact-migration preflight and architect GO; this is DRAFT.



CREATE OR REPLACE FUNCTION private.exam_prep_timed_score_comparable_v1(p_session_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select coalesce((
    select t.timing_comparable
       and t.server_elapsed_sec>0
       and t.attempt_kind<>'diagnostic_full'
       and private.exam_prep_integrity_allows_timed_comparability_v1(t.session_id)
       and coalesce(nullif(s.timing_contract->>'paper_comparability_epoch','')::int,1)=coalesce(p.paper_comparability_epoch,1)
       and (
         nullif(trim(p.exam_series),'') is null
         or lower(trim(coalesce(nullif(s.timing_contract->>'exam_series_snapshot',''),p.exam_series)))=lower(trim(p.exam_series))
       )
       and coalesce(t.pending_review_in_time_marks,0)=0
       and coalesce(t.pending_review_after_time_marks,0)=0
    from private.exam_prep_timed_attempt_results t
    join private.exam_prep_sessions s on s.id=t.session_id
    join private.exam_prep_exam_profiles p on p.user_id=t.user_id and p.program_version_id=s.program_version_id
    where t.session_id=p_session_id
  ),false);
$function$;


CREATE OR REPLACE FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(p_session_id uuid, p_language text DEFAULT 'en'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_lang text;
  v_items jsonb;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  IF v_lang NOT IN ('en','ru','uz') THEN
    RAISE EXCEPTION 'exam_prep_bad_language';
  END IF;

  SELECT * INTO v_s
  FROM private.exam_prep_sessions
  WHERE id=p_session_id
    AND user_id=v_uid
    AND session_type IN ('timed','paper');

  IF v_s.id IS NULL THEN
    RAISE EXCEPTION 'exam_prep_timed_session_not_found' USING errcode='P0002';
  END IF;

  IF v_s.status<>'finalized'
     OR NOT EXISTS(
       SELECT 1
       FROM private.exam_prep_timed_attempt_results
       WHERE session_id=v_s.id
     )
  THEN
    RAISE EXCEPTION 'exam_prep_review_pack_requires_finalized_attempt';
  END IF;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'item_order',si.item_order,
        'primary_skill_code',si.primary_skill_code,
        'prompt',CASE v_lang
          WHEN 'ru' THEN wt.prompt_ru
          WHEN 'uz' THEN wt.prompt_uz
          ELSE wt.prompt_en
        END,
        'learner_artifact',r.learner_artifact,
        'max_marks',ti.max_marks,
        'rubric',private.exam_prep_localized_written_rubric_v1(wt.rubric_json,v_lang),
        'self_review',CASE v_lang
          WHEN 'ru' THEN wt.self_review_ru
          WHEN 'uz' THEN wt.self_review_uz
          ELSE wt.self_review_en
        END,
        'submitted_in_time',(r.answered_at<=nullif(v_s.timing_contract->>'deadline_at','')::timestamptz),
        'written_correctness','unknown'
      )
      ORDER BY si.item_order
    ),
    '[]'::jsonb
  )
  INTO v_items
  FROM private.exam_prep_session_items si
  JOIN private.exam_prep_timed_assessment_items ti
    ON ti.assessment_id=v_s.assessment_id
   AND ti.item_order=si.item_order
  JOIN private.exam_prep_written_tasks wt
    ON wt.id=si.written_task_id
  JOIN private.exam_prep_responses r
    ON r.session_id=si.session_id
   AND r.item_order=si.item_order
   AND r.response_kind='written'
  WHERE si.session_id=v_s.id
    AND si.item_kind='written';

  RETURN jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'items',v_items
  );
END;
$function$;


CREATE OR REPLACE FUNCTION public.get_exam_prep_timed_result_safe_v1(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_uid uuid; v_b private.exam_prep_timed_attempt_results%rowtype;
  v_pending_in integer; v_pending_after integer; v_earned_in integer; v_earned_after integer; v_lost_in integer; v_lost_after integer; v_score_comp boolean;
  v_integrity jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_b from private.exam_prep_timed_attempt_results where session_id=p_session_id and user_id=v_uid;
  if v_b.session_id is null then raise exception 'exam_prep_timed_result_not_found' using errcode='P0002'; end if;
  -- Written work is evidence of completion, never awarded marks or correctness.
  -- Pre-existing learner self-mark rows remain historical but are ignored.
  v_pending_in:=greatest(0,v_b.pending_review_in_time_marks);
  v_pending_after:=greatest(0,v_b.pending_review_after_time_marks);
  v_earned_in:=v_b.objective_marks_in_time;
  v_earned_after:=v_b.objective_marks_after_time;
  v_lost_in:=v_b.objective_lost_in_time_marks;
  v_lost_after:=v_b.objective_lost_after_time_marks;
  v_integrity:=private.exam_prep_integrity_status_v1(v_b.session_id);
  v_score_comp:=private.exam_prep_timed_score_comparable_v1(v_b.session_id);
  return jsonb_build_object(
    'session_id',v_b.session_id,'component_code',v_b.component_code,'attempt_kind',v_b.attempt_kind,'timing_rule',v_b.timing_rule,
    'comparison_scope',v_b.comparison_scope,'comparability_key',v_b.comparability_key,'strict_timing',v_b.strict_timing,
    'marks_available',v_b.marks_available,'time_limit_sec',v_b.time_limit_sec,'server_elapsed_sec',v_b.server_elapsed_sec,
    'answered_items',v_b.answered_items,'unattempted_items',v_b.unattempted_items,
    'marks_in_time',v_earned_in,'marks_after_time',v_earned_after,
    'lost_answered_marks_in_time',v_lost_in,'lost_answered_marks_after_time',v_lost_after,
    'pending_review_in_time_marks',v_pending_in,'pending_review_after_time_marks',v_pending_after,
    'unattempted_marks',v_b.unattempted_marks,'completion_reason',v_b.completion_reason,
    'timing_comparable',(v_b.timing_comparable and v_b.server_elapsed_sec>0 and coalesce((v_integrity->>'integrity_allows_comparability')::boolean,false)),
    'score_comparable',v_score_comp,
    'integrity_policy_version',v_integrity->>'policy_version',
    'integrity_status',v_integrity->>'status',
    'integrity_event_count',coalesce((v_integrity->>'event_count')::integer,0),
    'integrity_review_required',coalesce((v_integrity->>'review_required')::boolean,false),
    'in_time_percent',case when v_pending_in+v_pending_after>0 then null else round((100.0*v_earned_in/nullif(v_b.marks_available,0))::numeric,1) end,
    'result_scope','objective_only',
    'objective_marks_in_time',v_b.objective_marks_in_time,
    'objective_marks_after_time',v_b.objective_marks_after_time,
    'written_correctness',case when v_pending_in+v_pending_after>0 then 'unknown' else 'not_applicable' end,
    'score_status',case when v_pending_in+v_pending_after>0 then 'written_ungraded' when v_score_comp then 'provisional_comparable' else 'non_comparable' end,
    'readiness_claim',false,'finalized_at',v_b.finalized_at
  );
end;
$function$;


CREATE OR REPLACE FUNCTION private.exam_prep_stage5_readiness_status_v1(p_user_id uuid, p_program_version_id bigint, p_component_code text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_rule private.exam_prep_stage5_readiness_rules%rowtype;
  v_threshold private.exam_prep_stage5_thresholds%rowtype;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_raw jsonb;
  v_attempt jsonb;
  v_sid uuid;
  v_marks_in_time int;
  v_marks_available int;
  v_score numeric;
  v_scores_ok boolean:=true;
  v_unattempted_ok boolean:=true;
  v_after_time_ok boolean:=true;
  v_eval jsonb:='[]'::jsonb;
  v_attempt_count int:=0;
  v_below_l3 int:=0;
  v_open_corrections int:=0;
  v_ready boolean:=false;
  v_reason text:='rule_missing';
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select * into v_rule from private.exam_prep_stage5_readiness_rules where status='active' order by created_at desc limit 1;
  if v_rule.rule_version is null then
    return jsonb_build_object('ready',false,'reason_code','rule_missing','component_code',p_component_code,'stage6_unlocked',false);
  end if;

  v_raw:=private.exam_prep_stage5_raw_readiness_v1(p_user_id,p_program_version_id,p_component_code);
  v_attempt_count:=coalesce((v_raw->>'last_three_count')::int,0);
  v_below_l3:=coalesce((v_raw->>'below_l3_count')::int,0);
  v_open_corrections:=coalesce((v_raw->>'unresolved_correction_case_count')::int,0);

  select * into v_profile from private.exam_prep_exam_profiles
  where user_id=p_user_id and program_version_id=p_program_version_id;

  if v_profile.user_id is not null and nullif(trim(v_profile.exam_series),'') is not null and nullif(trim(v_profile.target_grade),'') is not null then
    select * into v_threshold
    from private.exam_prep_stage5_thresholds
    where status='approved'
      and program_version_id=p_program_version_id
      and component_code=p_component_code
      and lower(trim(exam_series_key))=lower(trim(v_profile.exam_series))
      and upper(trim(target_grade))=upper(trim(v_profile.target_grade))
    order by approved_at desc nulls last,id desc
    limit 1;
  end if;

  if v_threshold.id is not null and v_attempt_count=3 then
    for v_attempt in select value from jsonb_array_elements(coalesce(v_raw->'last_three_attempts','[]'::jsonb)) loop
      v_sid:=(v_attempt->>'session_id')::uuid;
      -- Only genuinely objective marks are eligible; written is unknown.
      select r.objective_marks_in_time,r.marks_available
        into v_marks_in_time,v_marks_available
      from private.exam_prep_timed_attempt_results r
      where r.session_id=v_sid and r.user_id=p_user_id and r.component_code=p_component_code;

      v_score:=case when coalesce(v_marks_available,0)>0 then (100.0*v_marks_in_time/v_marks_available) else null end;
      if v_score is null or v_score<v_threshold.min_in_time_score_pct then v_scores_ok:=false; end if;
      if (v_attempt->>'unattempted_share')::numeric>v_threshold.max_unattempted_share then v_unattempted_ok:=false; end if;
      if (v_attempt->>'after_time_share')::numeric>v_threshold.max_after_time_share then v_after_time_ok:=false; end if;

      v_eval:=v_eval || jsonb_build_array(v_attempt || jsonb_build_object(
        'marks_in_time',v_marks_in_time,
        'in_time_score_pct',round(v_score,2),
        'score_threshold_met',coalesce(v_score>=v_threshold.min_in_time_score_pct,false),
        'unattempted_threshold_met',coalesce((v_attempt->>'unattempted_share')::numeric<=v_threshold.max_unattempted_share,false),
        'after_time_threshold_met',coalesce((v_attempt->>'after_time_share')::numeric<=v_threshold.max_after_time_share,false)
      ));
    end loop;
  else
    v_scores_ok:=false;
    v_unattempted_ok:=false;
    v_after_time_ok:=false;
  end if;

  if v_rule.require_stage4_exit and not coalesce(((v_raw->'stage4_exit_status')->>'ready')::boolean,false) then
    v_reason:='stage4_exit_incomplete';
  elsif v_attempt_count<v_rule.min_comparable_full_attempts then
    v_reason:='three_comparable_attempts_incomplete';
  elsif v_threshold.id is null then
    v_reason:='threshold_configuration_pending';
  elsif v_rule.require_all_skills_l3 and v_below_l3<>0 then
    v_reason:='objective_skill_stability_incomplete';
  elsif v_rule.require_all_corrections_closed and v_open_corrections<>0 then
    v_reason:='corrective_cycles_open';
  elsif v_rule.require_last_three_above_threshold and not v_scores_ok then
    v_reason:='last_three_below_individual_threshold';
  elsif not v_unattempted_ok then
    v_reason:='unattempted_marks_not_minimal';
  elsif not v_after_time_ok then
    v_reason:='after_time_dependency_not_closed';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,
    'app_readiness_estimate',case when v_ready then 'STRONG_OBJECTIVE_EVIDENCE' else 'INSUFFICIENT_EVIDENCE' end,
    'reason_code',v_reason,
    'rule_version',v_rule.rule_version,
    'component_code',p_component_code,
    'program_version_id',p_program_version_id,
    'exam_series',v_profile.exam_series,
    'target_grade',v_profile.target_grade,
    'threshold_configured',(v_threshold.id is not null),
    'threshold_version',v_threshold.threshold_version,
    'min_in_time_score_pct',v_threshold.min_in_time_score_pct,
    'max_unattempted_share',v_threshold.max_unattempted_share,
    'max_after_time_share',v_threshold.max_after_time_share,
    'last_three_count',v_attempt_count,
    'last_three_evaluation',v_eval,
    'below_l3_count',v_below_l3,
    'unresolved_correction_case_count',v_open_corrections,
    'score_window_ready',v_scores_ok,
    'unattempted_gate_ready',v_unattempted_ok,
    'after_time_gate_ready',v_after_time_ok,
    'mentor_verified_readiness',false,
    'stage5_ready',v_ready,
    'stage6_unlocked',false
  );
end;
$function$;


CREATE OR REPLACE FUNCTION public.submit_exam_prep_timed_written_self_mark_safe_v1(
 p_session_id uuid,p_item_order integer,p_marks_awarded integer,p_idempotency_key text,p_review_note text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $no_self_marks$
BEGIN
 RAISE EXCEPTION 'exam_prep_written_self_marks_disabled' USING ERRCODE='42501';
END;
$no_self_marks$;
REVOKE ALL ON FUNCTION public.submit_exam_prep_timed_written_self_mark_safe_v1(uuid,integer,integer,text,text)
 FROM PUBLIC,anon,authenticated,service_role;


-- Keep owner-based public RPC access; revoke extra PUBLIC defaults defensively.

REVOKE ALL ON FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(uuid,text) FROM PUBLIC,anon;

REVOKE ALL ON FUNCTION public.get_exam_prep_timed_result_safe_v1(uuid) FROM PUBLIC,anon;

GRANT EXECUTE ON FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(uuid,text) TO authenticated,service_role;

GRANT EXECUTE ON FUNCTION public.get_exam_prep_timed_result_safe_v1(uuid) TO authenticated,service_role;

REVOKE ALL ON FUNCTION private.exam_prep_timed_score_comparable_v1(uuid) FROM PUBLIC,anon,authenticated;

REVOKE ALL ON FUNCTION private.exam_prep_stage5_readiness_status_v1(uuid,bigint,text) FROM PUBLIC,anon,authenticated;

COMMIT;

