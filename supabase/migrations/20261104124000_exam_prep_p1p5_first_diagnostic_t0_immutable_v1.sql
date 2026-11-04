-- Issue #450 / D09-02: immutable ORIGINAL diagnostic T0 capture for NEW
-- genuine Stage0 completion transitions. DRAFT/NO_GO, additive only.
-- Existing completed beta learners are NOT forcibly backfilled or re-anchored.
-- No rewrite of the canonical stable shared weekly plan generator.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_diagnostic_t0_snapshots_v1 (
 user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
 program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
 component_code text NOT NULL CHECK(component_code IN ('P1','P5')),
 diagnostic_completed_at timestamptz NOT NULL,
 captured_at timestamptz NOT NULL DEFAULT clock_timestamp(),
 capture_rule_version text NOT NULL,
 capture_source text NOT NULL DEFAULT 'first_verified_stage0_transition'
   CHECK(capture_source='first_verified_stage0_transition'),
 PRIMARY KEY(user_id,program_version_id,component_code)
);
ALTER TABLE private.exam_prep_diagnostic_t0_snapshots_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_diagnostic_t0_snapshots_v1
 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.exam_prep_diagnostic_t0_snapshots_v1 TO service_role;
-- The definer placement writer owns INSERT. No public or service API user
-- may later change an academic origin. Admin account deletion can still
-- cascade-clean these rows; an UPDATE, however, must never rewrite T0.
CREATE OR REPLACE FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path TO ''
AS $immutable$
BEGIN
 RAISE EXCEPTION 'exam_prep_diagnostic_t0_immutable' USING ERRCODE='42501';
END;
$immutable$;
REVOKE ALL ON FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1()
 FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_immutable_update_v1
 ON private.exam_prep_diagnostic_t0_snapshots_v1;
CREATE TRIGGER exam_prep_diagnostic_t0_immutable_update_v1
 BEFORE UPDATE ON private.exam_prep_diagnostic_t0_snapshots_v1
 FOR EACH ROW EXECUTE FUNCTION private.reject_exam_prep_diagnostic_t0_update_v1();

CREATE OR REPLACE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $capture$
DECLARE
 v_completed timestamptz;
BEGIN
 IF NEW.stage0_complete IS DISTINCT FROM true
   OR NEW.component_code NOT IN ('P1','P5') THEN RETURN NEW; END IF;

 -- The academic placement has just completed for the first time. The LAST
 -- finalized diagnostic at THAT instant ends multi-step Stage0 if present.
 -- Never derive a new T0 from a later retest, paper, review or profile edit.
 SELECT max(s.finalized_at) INTO v_completed
 FROM private.exam_prep_sessions s
 WHERE s.user_id=NEW.user_id
   AND s.program_version_id=NEW.program_version_id
   AND s.component_code=NEW.component_code
   AND s.session_type='diagnostic'
   AND s.status='finalized'
   AND s.finalized_at IS NOT NULL;
 IF v_completed IS NULL THEN
   -- Some legacy/synthetic placements may be manually marked complete but
   -- lack finalized diagnostic evidence. Never forge a completion epoch.
   RETURN NEW;
 END IF;
 INSERT INTO private.exam_prep_diagnostic_t0_snapshots_v1(
  user_id,program_version_id,component_code,diagnostic_completed_at,capture_rule_version
 ) VALUES(
  NEW.user_id,NEW.program_version_id,NEW.component_code,v_completed,NEW.rule_version
 )
 ON CONFLICT(user_id,program_version_id,component_code) DO NOTHING;
 RETURN NEW;
END;
$capture$;
REVOKE ALL ON FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1()
 FROM PUBLIC,anon,authenticated;
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_stage0_insert_v1
 ON private.exam_prep_component_placements;
CREATE TRIGGER exam_prep_diagnostic_t0_stage0_insert_v1
 AFTER INSERT ON private.exam_prep_component_placements
 FOR EACH ROW WHEN(NEW.stage0_complete IS TRUE)
 EXECUTE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1();
DROP TRIGGER IF EXISTS exam_prep_diagnostic_t0_stage0_update_v1
 ON private.exam_prep_component_placements;
CREATE TRIGGER exam_prep_diagnostic_t0_stage0_update_v1
 AFTER UPDATE OF stage0_complete ON private.exam_prep_component_placements
 FOR EACH ROW WHEN(NEW.stage0_complete IS TRUE AND OLD.stage0_complete IS DISTINCT FROM TRUE)
 EXECUTE FUNCTION private.capture_exam_prep_diagnostic_t0_stage0_v1();

-- Read-only D09 v1 projection now PREFERS the immutable first Stage0 T0
-- when recorded, while legacy students retain clearly labeled derived date.

CREATE OR REPLACE FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $periods$
DECLARE
 v_uid uuid;
 v_profile private.exam_prep_exam_profiles%ROWTYPE;
 v_now timestamptz;
 v_component text;
 v_finished boolean;
 v_anchor timestamptz;
 v_original private.exam_prep_diagnostic_t0_snapshots_v1%ROWTYPE;
 v_anchor_frozen boolean;
 v_anchor_source text;
 v_periods integer;
 v_current_start timestamptz;
 v_next_end timestamptz;
 v_out jsonb:='{}'::jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 SELECT * INTO v_profile
 FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_profile.user_id IS NULL OR v_profile.program_version_id IS NULL THEN
  RAISE EXCEPTION 'exam_prep_profile_required' USING ERRCODE='42501';
 END IF;
 v_now:=private.exam_prep_effective_academic_now_v1(v_uid);

 FOREACH v_component IN ARRAY ARRAY['P1','P5'] LOOP
  v_finished:=false;
  v_anchor:=null;
  v_original:=null;
  v_anchor_frozen:=false;
  v_anchor_source:='current_horizon_latest_finalized_diagnostic';
  v_periods:=null;
  v_current_start:=null;
  v_next_end:=null;

  SELECT coalesce(p.stage0_complete,false) INTO v_finished
  FROM private.exam_prep_component_placements p
  WHERE p.user_id=v_uid AND p.program_version_id=v_profile.program_version_id
    AND p.component_code=v_component
  ORDER BY p.derived_at DESC LIMIT 1;
  v_finished:=coalesce(v_finished,false);
  IF v_finished THEN
   -- The first verified Stage0 transition is frozen server-side once.
   -- Historical completed beta profiles without a frozen row fall back to
   -- the old derived horizon, explicitly marked NOT immutable.
   SELECT * INTO v_original
   FROM private.exam_prep_diagnostic_t0_snapshots_v1 t
   WHERE t.user_id=v_uid AND t.program_version_id=v_profile.program_version_id
     AND t.component_code=v_component;
   IF v_original.user_id IS NOT NULL THEN
     v_anchor:=v_original.diagnostic_completed_at;
     v_anchor_frozen:=true;
     v_anchor_source:='first_verified_stage0_transition';
   ELSE
     SELECT max(s.finalized_at) INTO v_anchor
     FROM private.exam_prep_sessions s
     WHERE s.user_id=v_uid AND s.program_version_id=v_profile.program_version_id
       AND s.component_code=v_component AND s.session_type='diagnostic'
       AND s.status='finalized' AND s.finalized_at IS NOT NULL;
   END IF;
  END IF;

  IF v_anchor IS NOT NULL AND v_anchor<=v_now THEN
   v_periods:=private.exam_prep_full_periods_from_t0_v1(v_anchor,v_now);
   v_current_start:=v_anchor+v_periods*interval '7 days';
   v_next_end:=v_current_start+interval '7 days';
  END IF;

  v_out:=v_out||jsonb_build_object(v_component,jsonb_build_object(
   'component_code',v_component,
   'status',CASE WHEN NOT v_finished THEN 'diagnostic_pending'
                 WHEN v_anchor IS NULL THEN 'diagnostic_completion_unknown'
                 WHEN v_anchor>v_now THEN 'diagnostic_in_future'
                 ELSE 'diagnostic_period_ready' END,
   'diagnostic_completed_at',v_anchor,
   'completed_7day_periods',v_periods,
   'current_period_no',CASE WHEN v_periods IS NULL THEN NULL ELSE v_periods+1 END,
   'current_period_started_at',v_current_start,
   'next_period_ends_at',v_next_end,
   'anchor_source',v_anchor_source,
   'anchor_immutable',v_anchor_frozen,
   'calendar_promotes_stage',false
  ));
 END LOOP;

 RETURN jsonb_build_object(
  'contract_version','diagnostic_period_readonly_v1',
  'period_duration_days',7,
  'P1',v_out->'P1','P5',v_out->'P5',
  'account_planner_week_unchanged',true,
  'no_schedule_change',true,
  'study_minutes_recorded',false
 );
END;
$periods$;
REVOKE ALL ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1()
 TO authenticated,service_role;
COMMENT ON FUNCTION public.get_exam_prep_diagnostic_periods_safe_v1() IS
 'Owner-only D09 P1/P5 7-day projection: immutable first verified Stage0 transitions for new learners; legacy completions without a snapshot remain transparently derived. Does not mutate the shared weekly planner.';

-- D09-02: period report must reuse the SAME frozen T0 as the P1/P5 read
-- projection; a later repeated diagnostic cannot restart report receipts.
-- No deletion, rewrite, or backfill of previously issued receipts.
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

      v_report:=jsonb_build_object(
        'period_kind','week','period_started_at',v_start,
        'period_ended_at',v_end,'source','finalized_exam_prep_sessions',
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
