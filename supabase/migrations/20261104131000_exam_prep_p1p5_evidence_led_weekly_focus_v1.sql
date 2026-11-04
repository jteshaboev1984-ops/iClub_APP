-- D09-05/Package3: completed academic week can suggest up to 3 existing
-- result-led learning actions without fictitious hours or plan changes.
-- Additive to immutable weekly receipts; DRAFT/NO_GO, no production writes.
BEGIN;

-- D09-05: Factual, deduplicated evidence-led candidates for the one completed
-- weekly digest. This is NOT a generator, exam-grade prediction or time norm.
-- Uses exactly the existing reviewed P2-09 81-skill remaining-work engine.
CREATE OR REPLACE FUNCTION private.exam_prep_current_evidence_next_focus_v1(
 p_user_id uuid,p_program_version_id bigint
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY INVOKER
SET search_path TO '' AS $evidence_focus$
DECLARE v_items jsonb;
BEGIN
 IF p_user_id IS NULL OR p_program_version_id IS NULL
 THEN RAISE EXCEPTION 'exam_prep_evidence_focus_identity_required'; END IF;
 WITH paper_inputs AS (
   SELECT 'P1'::text AS component_code,
     private.exam_prep_remaining_work_internal_v1(p_user_id,p_program_version_id,'P1') AS body
   UNION ALL
   SELECT 'P5'::text AS component_code,
     private.exam_prep_remaining_work_internal_v1(p_user_id,p_program_version_id,'P5') AS body
 ),
 eligible AS (
   SELECT p.component_code,
     i.value->>'skill_code' AS skill_code,
     i.value->>'evidence_status' AS evidence_status,
     n.official_syllabus_section AS syllabus_section,
     act.value AS next_action,
     CASE act.value
       WHEN 'correction' THEN 1
       WHEN 'delayed_retest' THEN 2
       WHEN 'mixed_transfer' THEN 3
       WHEN 'targeted_practice' THEN 4
       WHEN 'targeted_check' THEN 5
       WHEN 'written_work_unscored' THEN 6
       ELSE 99 END AS weight
   FROM paper_inputs p
   CROSS JOIN LATERAL jsonb_array_elements(p.body->'items') AS i(value)
   CROSS JOIN LATERAL jsonb_array_elements_text(i.value->'pending_actions') AS act(value)
   JOIN private.exam_prep_syllabus_nodes n
     ON n.program_version_id=p_program_version_id
     AND n.component_code=p.component_code
     AND n.skill_code=i.value->>'skill_code'
   WHERE act.value IN ('correction','delayed_retest','mixed_transfer',
     'targeted_practice','targeted_check','written_work_unscored')
     AND i.value->>'evidence_status' IN ('unobserved',
       'observed_unconfirmed','objective_coverage_confirmed')
 ),
 one_phase_per_skill AS (
   SELECT DISTINCT ON (component_code,skill_code)
     component_code,skill_code,evidence_status,syllabus_section,next_action,weight
   FROM eligible ORDER BY component_code,skill_code,weight,next_action
 ),
 balanced AS (
   SELECT *,
     row_number() OVER (
       PARTITION BY component_code ORDER BY weight,skill_code
     ) AS paper_position
   FROM one_phase_per_skill
 ),
 chosen AS (
   SELECT * FROM balanced
   ORDER BY CASE WHEN paper_position=1 THEN 0 ELSE 1 END,
     weight,component_code,skill_code
   LIMIT 3
 )
 SELECT coalesce(jsonb_agg(jsonb_build_object(
   'component_code',component_code,
   'syllabus_section',syllabus_section,
   'skill_code',skill_code,
   'next_action',next_action,
   'evidence_status',evidence_status,
   'source','existing_P2_09_current_objective_evidence'
 ) ORDER BY CASE WHEN paper_position=1 THEN 0 ELSE 1 END,
   weight,component_code,skill_code),'[]'::jsonb)
 INTO v_items FROM chosen;
 RETURN jsonb_build_object(
  'contract_version','exam_prep_weekly_evidence_focus_v1',
  'items',v_items,'maximum_items',3,
  'read_at','report_claim_time_not_historical_week_end',
  'basis','current_81_skill_objective_evidence_and_open_corrections',
  'unknown_skill_is_not_failed',true,
  'not_additional_weekly_plan',true,
  'existing_plan_ids_and_priorities_unchanged',true,
  'student_selected_math_hours_unchanged',true,
  'recommended_weekly_hours',null,
  'recommended_daily_minutes',null,
  'recommendation_accept_enabled',false,
  'academic_grades_changed',false,'learning_access_capped',false
 );
END;
$evidence_focus$;
REVOKE ALL ON FUNCTION private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_current_evidence_next_focus_v1(uuid,bigint)
 TO service_role;

create or replace function public.claim_exam_prep_periodic_study_report_safe_v1()
returns jsonb
language plpgsql
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_profile private.exam_prep_exam_profiles%rowtype;
  v_now timestamptz;
  v_diagnostic_anchor timestamptz;
  v_week_number int;
  v_month_number int;
  v_anchor_months int;
  v_end timestamptz;
  v_start timestamptz;
  v_kind text;
  v_report jsonb;
  v_added jsonb;
  v_results jsonb := '[]'::jsonb;
  v_p1 int;
  v_p5 int;
  v_timed_p1 int;
  v_timed_p5 int;
  v_p1_adherence jsonb;
  v_p5_adherence jsonb;
  v_source_end timestamptz;
  v_focus jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_profile from private.exam_prep_exam_profiles
    where user_id=v_uid;
  if v_profile.user_id is null or v_profile.program_version_id is null then
    raise exception 'exam_prep_profile_required';
  end if;
  v_now:=private.exam_prep_effective_academic_now_v1(v_uid);
  -- Use the first ACTUALLY COMPLETE component diagnostic, not merely a
  -- finalized partial screening session or a provisional placement.
  -- Once the first verified Stage0 T0 is frozen, later diagnostics cannot
  -- restart an already-running week or calendar month (or redeliver it).
  -- Historical pre-install students have no frozen T0 and keep derived dates.
  select min(coalesce(t0.diagnostic_completed_at,d.completed_at)) into v_diagnostic_anchor
  from (
    select s.component_code,max(s.finalized_at) as completed_at
    from private.exam_prep_sessions s
    where s.user_id=v_uid and
      s.program_version_id=v_profile.program_version_id and
      s.session_type='diagnostic' and s.status='finalized' and
      s.component_code in ('P1','P5') and s.finalized_at is not null
    group by s.component_code
  ) d
  join lateral (
    select p.stage0_complete
    from private.exam_prep_component_placements p
    where p.user_id=v_uid and p.program_version_id=v_profile.program_version_id
      and p.component_code=d.component_code
    order by p.derived_at desc limit 1
  ) placement on placement.stage0_complete is true
  left join private.exam_prep_diagnostic_t0_snapshots_v1 t0
    on t0.user_id=v_uid
   and t0.program_version_id=v_profile.program_version_id
   and t0.component_code=d.component_code;
  if v_diagnostic_anchor is null or v_diagnostic_anchor>v_now then
    return jsonb_build_object('contract_version','periodic_study_report_v1',
      'reports','[]'::jsonb,'daily_reminders',false);
  end if;

  -- D09: weekly reports begin after exactly one completed 7-day period
  -- from the FIRST genuinely complete paper diagnostic, not profile signup.
  -- A profile created months earlier cannot shift or pre-emit the summary.
  -- Keep the existing one-per-(owner,program,anchor,kind,end) receipt and
  -- no-backlog policy. The independent P1/P5 diagnostic periods are
  -- projected read-only by get_exam_prep_component_periods_safe_v1.
  v_week_number:=floor(extract(epoch from (v_now-v_diagnostic_anchor))/604800)::int;
  -- Week 36 is a curriculum model, not a study-access or reporting limit.
  if v_week_number between 1 and 156 then
    v_kind:='week';
    v_end:=v_diagnostic_anchor+(v_week_number*interval '7 days');
    v_start:=v_end-interval '7 days';
    if v_end<=v_now and v_start>=v_diagnostic_anchor then
      v_p1_adherence:=null; v_p5_adherence:=null;
      -- Existing verified due-goal proof is optional; don't infer missed hours
      -- from zero app sessions or incorrect/ambiguous historical goal snapshots.
      begin
        v_p1_adherence:=public.get_exam_prep_previous_week_adherence_safe_v1('P1');
      exception when others then v_p1_adherence:=null;
      end;
      begin
        v_p5_adherence:=public.get_exam_prep_previous_week_adherence_safe_v1('P5');
      exception when others then v_p5_adherence:=null;
      end;
      if v_p1_adherence is not null then
        v_source_end:=nullif(v_p1_adherence->>'week_ended_at','')::timestamptz;
        if v_source_end is distinct from v_end then v_p1_adherence:=null; end if;
      end if;
      if v_p5_adherence is not null then
        v_source_end:=nullif(v_p5_adherence->>'week_ended_at','')::timestamptz;
        if v_source_end is distinct from v_end then v_p5_adherence:=null; end if;
      end if;
      select
        count(*) filter (where s.component_code='P1' and s.session_type in ('learning','mixed','retest'))::int,
        count(*) filter (where s.component_code='P5' and s.session_type in ('learning','mixed','retest'))::int,
        count(*) filter (where s.component_code='P1' and s.session_type='timed')::int,
        count(*) filter (where s.component_code='P5' and s.session_type='timed')::int
      into v_p1,v_p5,v_timed_p1,v_timed_p5
      from private.exam_prep_sessions s
      where s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
        and s.finalized_at>=v_start and s.finalized_at<v_end
        and s.status='finalized';

      -- The remainder projection uses only current verified objective-skill
      -- states at claim time; it does NOT reconstruct scores at the week end.
      v_focus:=private.exam_prep_current_evidence_next_focus_v1(
        v_uid,v_profile.program_version_id);
      v_report:=jsonb_build_object(
        'period_kind','week','period_started_at',v_start,
        'period_ended_at',v_end,'source','finalized_exam_prep_sessions',
        'evidence_next_steps',v_focus,
        'P1',jsonb_build_object('finalized_learning_sessions',v_p1,
          'finalized_timed_sessions',v_timed_p1,'verified_week_goals',v_p1_adherence),
        'P5',jsonb_build_object('finalized_learning_sessions',v_p5,
          'finalized_timed_sessions',v_timed_p5,'verified_week_goals',v_p5_adherence),
        'learning_minutes',null,'outside_iclub_activity','unknown',
        'can_continue_learning',true,'access_limit_changed',false,
        'suggested_minutes_per_day',null,'no_auto_schedule_change',true
      );
      insert into private.exam_prep_periodic_study_report_receipts_v1
        (user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at,report_payload)
      values (v_uid,v_profile.program_version_id,v_diagnostic_anchor,'week',v_end,v_report)
      on conflict do nothing
      returning report_payload into v_added;
      if v_added is not null then v_results:=v_results||jsonb_build_array(v_added); end if;
    end if;
  end if;

  -- Monthly reports start at the first actually completed component diagnostic.
  -- Month N is anchor + N calendar months (not "30 days" or 4 pretend weeks).
  v_month_number:=(
    (extract(year from v_now at time zone 'Asia/Tashkent')::int -
     extract(year from v_diagnostic_anchor at time zone 'Asia/Tashkent')::int)*12 +
    (extract(month from v_now at time zone 'Asia/Tashkent')::int -
     extract(month from v_diagnostic_anchor at time zone 'Asia/Tashkent')::int)
  );
  if v_month_number>=1 then
    v_end:=((v_diagnostic_anchor at time zone 'Asia/Tashkent')+
      make_interval(months=>v_month_number)) at time zone 'Asia/Tashkent';
    if v_end>v_now then v_month_number:=v_month_number-1; end if;
    if v_month_number>=1 then
      v_start:=((v_diagnostic_anchor at time zone 'Asia/Tashkent')+
        make_interval(months=>v_month_number-1)) at time zone 'Asia/Tashkent';
      v_end:=((v_diagnostic_anchor at time zone 'Asia/Tashkent')+
      make_interval(months=>v_month_number)) at time zone 'Asia/Tashkent';
      select
        count(*) filter (where s.component_code='P1' and s.session_type in ('learning','mixed','retest'))::int,
        count(*) filter (where s.component_code='P5' and s.session_type in ('learning','mixed','retest'))::int,
        count(*) filter (where s.component_code='P1' and s.session_type='timed')::int,
        count(*) filter (where s.component_code='P5' and s.session_type='timed')::int
      into v_p1,v_p5,v_timed_p1,v_timed_p5
      from private.exam_prep_sessions s
      where s.user_id=v_uid and s.program_version_id=v_profile.program_version_id
        and s.finalized_at>=v_start and s.finalized_at<v_end
        and s.status='finalized';

      v_report:=jsonb_build_object(
        'period_kind','month','period_started_at',v_start,
        'period_ended_at',v_end,'source','finalized_exam_prep_sessions',
        'P1',jsonb_build_object('finalized_learning_sessions',v_p1,
          'finalized_timed_sessions',v_timed_p1),
        'P5',jsonb_build_object('finalized_learning_sessions',v_p5,
          'finalized_timed_sessions',v_timed_p5),
        'learning_minutes',null,'outside_iclub_activity','unknown',
        'can_continue_learning',true,'access_limit_changed',false,
        'suggested_minutes_per_day',null,'no_auto_schedule_change',true
      );
      v_added:=null;
      insert into private.exam_prep_periodic_study_report_receipts_v1
        (user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at,report_payload)
      values (v_uid,v_profile.program_version_id,v_diagnostic_anchor,'month',v_end,v_report)
      on conflict do nothing
      returning report_payload into v_added;
      if v_added is not null then v_results:=v_results||jsonb_build_array(v_added); end if;
    end if;
  end if;
  return jsonb_build_object('contract_version','periodic_study_report_v1',
    'reports',v_results,'daily_reminders',false,
    'report_periods','completed_week_and_completed_month_only',
    'no_inferred_study_minutes',true);
end;
$function$;

revoke all on function public.claim_exam_prep_periodic_study_report_safe_v1()
  from public,anon;
grant execute on function public.claim_exam_prep_periodic_study_report_safe_v1()
  to authenticated,service_role;
comment on function public.claim_exam_prep_periodic_study_report_safe_v1() is
'Owner-only once-per-completed-week/month in-app study summaries, unique per syllabus program and completed diagnostic cycle across devices; never logs artificial time, locks studying or predicts Cambridge scores.';

COMMIT;
