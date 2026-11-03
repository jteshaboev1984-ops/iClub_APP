-- Mathematics P1/P5: one in-app report after each completed plan-week and
-- diagnostic-anchored calendar month. Never a daily reminder, study-hour counter
-- or activity access quota. Existing academic records are read, never mutated.
create table if not exists private.exam_prep_periodic_study_report_receipts_v1 (
  user_id uuid not null references public.users(id) on delete cascade,
  period_kind text not null check (period_kind in ('week','month')),
  period_ended_at timestamptz not null,
  claimed_at timestamptz not null default now(),
  report_payload jsonb not null,
  primary key (user_id,period_kind,period_ended_at)
);
alter table private.exam_prep_periodic_study_report_receipts_v1 enable row level security;
revoke all on private.exam_prep_periodic_study_report_receipts_v1
  from public,anon,authenticated;

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
  select min(s.finalized_at) into v_diagnostic_anchor
    from private.exam_prep_sessions s
    where s.user_id=v_uid and
      s.program_version_id=v_profile.program_version_id and
      s.session_type='diagnostic' and s.status='finalized' and
      s.component_code in ('P1','P5') and s.finalized_at is not null;
  if v_diagnostic_anchor is null or v_diagnostic_anchor>v_now then
    return jsonb_build_object('contract_version','periodic_study_report_v1',
      'reports','[]'::jsonb,'daily_reminders',false);
  end if;

  -- Weekly periods follow the existing governed 7-day profile/weekly-goal
  -- clock, not browser midnights. No backlog of multiple old weeks at login.
  v_week_number:=floor(extract(epoch from (v_now-v_profile.created_at))/604800)::int;
  -- The canonical 36-week roadmap is a content plan, NOT a reporting cutoff.
  -- The learner can continue preparing after week 36 without losing summaries.
  if v_week_number between 1 and 156 then
    v_kind:='week';
    v_end:=v_profile.created_at+(v_week_number*interval '7 days');
    v_start:=greatest(v_end-interval '7 days',v_diagnostic_anchor);
    if v_start<v_end then
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
        (user_id,period_kind,period_ended_at,report_payload)
      values (v_uid,'week',v_end,v_report)
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
        (user_id,period_kind,period_ended_at,report_payload)
      values (v_uid,'month',v_end,v_report)
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
'Owner-only once-per-completed-week/month in-app study summaries, idempotently claimed across devices; never logs artificial time, locks studying or predicts Cambridge scores.';
