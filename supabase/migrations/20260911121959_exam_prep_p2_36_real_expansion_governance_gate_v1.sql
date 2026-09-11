begin;

-- P2-36: expanded beta is a real-evidence governance transition, not a calendar
-- or synthetic-test transition. Synthetic development activity cannot count toward
-- the four weekly reviews required for expansion.

create table if not exists private.exam_prep_beta_expansion_controls(
  cohort_id bigint primary key references private.exam_prep_beta_cohorts(id) on delete restrict,
  development_data_state text not null default 'synthetic_present'
    check(development_data_state in ('synthetic_present','clean','real_monitoring')),
  real_review_epoch_started_at timestamptz,
  cleanup_evidence_ref text,
  required_validation_generation text not null default 'p2_36_expansion_v1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
revoke all on private.exam_prep_beta_expansion_controls from public,anon,authenticated;
grant select,insert,update on private.exam_prep_beta_expansion_controls to service_role;

create table if not exists private.exam_prep_beta_expansion_validation_evidence(
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete restrict,
  validation_key text not null check(validation_key in ('scale_600_10','service_transition')),
  validation_generation text not null,
  status text not null check(status in ('passed','failed')),
  source_ref text not null,
  metadata jsonb not null default '{}'::jsonb,
  validated_at timestamptz not null default now(),
  primary key(cohort_id,validation_key,validation_generation)
);
revoke all on private.exam_prep_beta_expansion_validation_evidence from public,anon,authenticated;
grant select,insert,update on private.exam_prep_beta_expansion_validation_evidence to service_role;

insert into private.exam_prep_beta_expansion_controls(
  cohort_id,development_data_state,required_validation_generation
)
select c.id,'synthetic_present','p2_36_expansion_v1'
from private.exam_prep_beta_cohorts c
on conflict(cohort_id) do nothing;

create or replace function private.exam_prep_beta_expansion_gate_v1(p_cohort_key text)
returns jsonb
language plpgsql
stable security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_ctl private.exam_prep_beta_expansion_controls%rowtype;
  v_reviews int:=0;
  v_green_last4 int:=0;
  v_first_last4 timestamptz;
  v_last_last4 timestamptz;
  v_sev0 int:=0;
  v_open_sev1 int:=0;
  v_validations int:=0;
  v_active_week smallint:=1;
  v_runway jsonb;
  v_runway_green boolean:=false;
  v_ready boolean:=false;
  v_reason text:='control_missing';
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;

  select * into v_ctl from private.exam_prep_beta_expansion_controls where cohort_id=v_c.id;
  if v_ctl.cohort_id is null then
    return jsonb_build_object('ready',false,'reason_code','expansion_control_missing','cohort_key',p_cohort_key);
  end if;

  if v_ctl.development_data_state<>'real_monitoring' or v_ctl.real_review_epoch_started_at is null then
    return jsonb_build_object(
      'ready',false,'reason_code','real_monitoring_not_armed','cohort_key',p_cohort_key,
      'development_data_state',v_ctl.development_data_state,
      'real_review_epoch_started_at',v_ctl.real_review_epoch_started_at,
      'required_validation_generation',v_ctl.required_validation_generation
    );
  end if;

  select count(*)::int into v_reviews
  from private.exam_prep_beta_weekly_reviews r
  where r.cohort_id=v_c.id and r.period_end>=v_ctl.real_review_epoch_started_at;

  with last4 as (
    select r.*
    from private.exam_prep_beta_weekly_reviews r
    where r.cohort_id=v_c.id and r.period_end>=v_ctl.real_review_epoch_started_at
    order by r.review_no desc
    limit 4
  )
  select
    count(*) filter(
      where l.overall_decision='continue'
        and exists(
          select 1 from private.exam_prep_beta_weekly_service_reviews sr
          where sr.weekly_review_id=l.id and sr.service_mode='core' and sr.decision='green'
        )
        and not exists(
          select 1 from private.exam_prep_beta_weekly_service_reviews sr
          where sr.weekly_review_id=l.id and sr.decision not in ('green','not_applicable')
        )
    )::int,
    min(l.period_end),max(l.period_end)
  into v_green_last4,v_first_last4,v_last_last4
  from last4 l;

  select count(*)::int into v_sev0
  from private.exam_prep_beta_ops_incidents i
  where i.cohort_id=v_c.id and i.severity='sev0'
    and coalesce(i.detected_at,i.created_at)>=v_ctl.real_review_epoch_started_at;

  select count(*)::int into v_open_sev1
  from private.exam_prep_beta_ops_incidents i
  where i.cohort_id=v_c.id and i.severity='sev1' and i.status in ('open','mitigating');

  select count(*)::int into v_validations
  from private.exam_prep_beta_expansion_validation_evidence e
  where e.cohort_id=v_c.id
    and e.validation_generation=v_ctl.required_validation_generation
    and e.status='passed'
    and e.validation_key in ('scale_600_10','service_transition');

  v_active_week:=least(36,greatest(1,
    floor(extract(epoch from (now()-v_ctl.real_review_epoch_started_at))/604800)::int+1
  ))::smallint;
  v_runway:=public.get_exam_prep_content_runway_v1(v_active_week);
  v_runway_green:=coalesce((v_runway->>'target_4w_green')::boolean,false)
    and coalesce((v_runway->>'hard_floor_green')::boolean,false);

  if now()<v_ctl.real_review_epoch_started_at+interval '28 days' then
    v_reason:='active_weeks_1_4_incomplete';
  elsif v_reviews<4 then
    v_reason:='four_real_weekly_reviews_incomplete';
  elsif v_green_last4<>4 then
    v_reason:='last_four_reviews_not_green';
  elsif v_first_last4 is null or v_last_last4 is null or v_last_last4-v_first_last4<interval '18 days' then
    v_reason:='weekly_review_cadence_incomplete';
  elsif v_last_last4<v_ctl.real_review_epoch_started_at+interval '28 days' then
    v_reason:='fourth_week_not_complete';
  elsif v_sev0<>0 then
    v_reason:='sev0_in_real_review_epoch';
  elsif v_open_sev1<>0 then
    v_reason:='release_blocking_sev1_open';
  elsif v_validations<>2 then
    v_reason:='scale_or_service_transition_validation_missing';
  elsif not v_runway_green then
    v_reason:='four_week_content_runway_not_green';
  else
    v_reason:='ready';
    v_ready:=true;
  end if;

  return jsonb_build_object(
    'ready',v_ready,'reason_code',v_reason,'cohort_key',p_cohort_key,
    'development_data_state',v_ctl.development_data_state,
    'real_review_epoch_started_at',v_ctl.real_review_epoch_started_at,
    'active_week_from_real_epoch',v_active_week,
    'real_weekly_review_count',v_reviews,
    'green_last_four_count',v_green_last4,
    'last_four_first_period_end',v_first_last4,
    'last_four_latest_period_end',v_last_last4,
    'sev0_since_real_epoch',v_sev0,
    'open_release_blocking_sev1',v_open_sev1,
    'required_validation_generation',v_ctl.required_validation_generation,
    'passed_required_validations',v_validations,
    'content_runway_target_4w_green',coalesce((v_runway->>'target_4w_green')::boolean,false),
    'content_runway_hard_floor_green',coalesce((v_runway->>'hard_floor_green')::boolean,false),
    'current_wave',v_c.current_wave,'planned_size',v_c.planned_size
  );
end;
$$;
revoke all on function private.exam_prep_beta_expansion_gate_v1(text) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_expansion_gate_v1(text) to service_role;

create or replace function public.get_exam_prep_beta_expansion_gate_v1(p_cohort_key text)
returns jsonb
language sql
stable security definer
set search_path=''
as $$
  select private.exam_prep_beta_expansion_gate_v1(p_cohort_key);
$$;
revoke all on function public.get_exam_prep_beta_expansion_gate_v1(text) from public,anon,authenticated;
grant execute on function public.get_exam_prep_beta_expansion_gate_v1(text) to service_role;

create or replace function public.record_exam_prep_expansion_validation_v1(
  p_cohort_key text,p_validation_key text,p_validation_generation text,p_source_ref text,p_metadata jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_ctl private.exam_prep_beta_expansion_controls%rowtype;
begin
  if p_validation_key not in ('scale_600_10','service_transition') then raise exception 'exam_prep_bad_expansion_validation_key'; end if;
  if p_source_ref is null or char_length(trim(p_source_ref))<8 then raise exception 'exam_prep_expansion_validation_source_required'; end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  select * into v_ctl from private.exam_prep_beta_expansion_controls where cohort_id=v_c.id;
  if v_ctl.cohort_id is null then raise exception 'exam_prep_expansion_control_missing'; end if;
  if p_validation_generation is distinct from v_ctl.required_validation_generation then
    raise exception 'exam_prep_expansion_validation_generation_mismatch';
  end if;
  insert into private.exam_prep_beta_expansion_validation_evidence(
    cohort_id,validation_key,validation_generation,status,source_ref,metadata,validated_at
  ) values(v_c.id,p_validation_key,p_validation_generation,'passed',trim(p_source_ref),coalesce(p_metadata,'{}'::jsonb),now())
  on conflict(cohort_id,validation_key,validation_generation) do update set
    status='passed',source_ref=excluded.source_ref,metadata=excluded.metadata,validated_at=now();
  return jsonb_build_object('cohort_key',p_cohort_key,'validation_key',p_validation_key,'validation_generation',p_validation_generation,'status','passed');
end;
$$;
revoke all on function public.record_exam_prep_expansion_validation_v1(text,text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.record_exam_prep_expansion_validation_v1(text,text,text,text,jsonb) to service_role;

create or replace function public.arm_exam_prep_beta_real_monitoring_v1(p_cohort_key text,p_cleanup_evidence_ref text)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_residue int:=0;
begin
  if p_cleanup_evidence_ref is null or char_length(trim(p_cleanup_evidence_ref))<8 then raise exception 'exam_prep_cleanup_evidence_ref_required'; end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if exists(select 1 from private.exam_prep_beta_weekly_reviews r where r.cohort_id=v_c.id) then
    raise exception 'exam_prep_real_monitoring_requires_zero_prior_weekly_reviews';
  end if;

  select
    (select count(*) from private.exam_prep_exam_profiles p join private.exam_prep_beta_members bm on bm.user_id=p.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_evidence_events e join private.exam_prep_beta_members bm on bm.user_id=e.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_correction_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_retest_events x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_weekly_plans x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_recovery_cases x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_skill_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_stage_states x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')+
    (select count(*) from private.exam_prep_component_placements x join private.exam_prep_beta_members bm on bm.user_id=x.user_id and bm.cohort_id=v_c.id where bm.member_status='active')
  into v_residue;

  if v_residue<>0 then raise exception 'exam_prep_synthetic_progress_cleanup_incomplete rows=%',v_residue; end if;

  insert into private.exam_prep_beta_expansion_controls(
    cohort_id,development_data_state,real_review_epoch_started_at,cleanup_evidence_ref,required_validation_generation,updated_at
  ) values(v_c.id,'real_monitoring',now(),trim(p_cleanup_evidence_ref),'p2_36_expansion_v1',now())
  on conflict(cohort_id) do update set
    development_data_state='real_monitoring',real_review_epoch_started_at=now(),
    cleanup_evidence_ref=excluded.cleanup_evidence_ref,updated_at=now();

  insert into private.exam_prep_audit_events(
    program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata
  ) values(
    'math_as_p1_p5',auth.uid(),'service_role','beta_real_monitoring_armed',
    'private.exam_prep_beta_expansion_controls',v_c.id::text,
    jsonb_build_object('cohort_key',p_cohort_key,'cleanup_evidence_ref',trim(p_cleanup_evidence_ref),'synthetic_progress_rows',v_residue)
  );

  return jsonb_build_object('cohort_key',p_cohort_key,'development_data_state','real_monitoring','real_review_epoch_started_at',now(),'synthetic_progress_rows',v_residue);
end;
$$;
revoke all on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) from public,anon,authenticated;
grant execute on function public.arm_exam_prep_beta_real_monitoring_v1(text,text) to service_role;

-- Weekly reviews are real governance evidence. They cannot be recorded while the
-- cohort is still carrying development/synthetic learner state, cannot be future-dated,
-- and cannot be compressed into multiple same-day "weeks".
do $$
declare
  v_oid oid;
  v_def text;
  v_old text;
  v_new text;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='record_exam_prep_beta_weekly_review_v2'
    and pg_get_function_identity_arguments(p.oid)='p_cohort_key text, p_review_no smallint, p_period_end timestamp with time zone, p_overall_decision text, p_core_decision text, p_ai_decision text, p_mentor_decision text, p_decision_reason text, p_core_reason text, p_ai_reason text, p_mentor_reason text, p_reviewer_user_id uuid';
  if v_oid is null then raise exception 'P2-36 weekly review v2 missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_ai_status text;'||chr(10)||'begin';
  v_new:='  v_ai_status text;'||chr(10)||'  v_expansion_ctl private.exam_prep_beta_expansion_controls%rowtype;'||chr(10)||'  v_last_review_end timestamptz;'||chr(10)||'begin';
  if position(v_old in v_def)=0 then raise exception 'P2-36 weekly declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  if v_c.cohort_status not in (''canary'',''active'',''paused'') then raise exception ''exam_prep_beta_weekly_bad_cohort_status''; end if;'||chr(10)||chr(10)||
         '  select coalesce(max(review_no),0)+1 into v_expected';
  v_new:='  if v_c.cohort_status not in (''canary'',''active'',''paused'') then raise exception ''exam_prep_beta_weekly_bad_cohort_status''; end if;'||chr(10)||
         '  select * into v_expansion_ctl from private.exam_prep_beta_expansion_controls where cohort_id=v_c.id;'||chr(10)||
         '  if v_expansion_ctl.cohort_id is null or v_expansion_ctl.development_data_state<>''real_monitoring'' or v_expansion_ctl.real_review_epoch_started_at is null then'||chr(10)||
         '    raise exception ''exam_prep_beta_real_monitoring_not_armed'';'||chr(10)||
         '  end if;'||chr(10)||
         '  if p_period_end>now()+interval ''5 minutes'' then raise exception ''exam_prep_beta_weekly_future_period_not_allowed''; end if;'||chr(10)||
         '  select max(period_end) into v_last_review_end from private.exam_prep_beta_weekly_reviews where cohort_id=v_c.id;'||chr(10)||chr(10)||
         '  select coalesce(max(review_no),0)+1 into v_expected';
  if position(v_old in v_def)=0 then raise exception 'P2-36 weekly control anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  if p_review_no<>v_expected then'||chr(10)||
         '    raise exception ''exam_prep_beta_weekly_review_must_be_sequential: expected %, got %'',v_expected,p_review_no;'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  v_snapshot:=public.get_exam_prep_beta_weekly_snapshot_v2(p_cohort_key,p_period_end);';
  v_new:='  if p_review_no<>v_expected then'||chr(10)||
         '    raise exception ''exam_prep_beta_weekly_review_must_be_sequential: expected %, got %'',v_expected,p_review_no;'||chr(10)||
         '  end if;'||chr(10)||
         '  if p_period_end < v_expansion_ctl.real_review_epoch_started_at + (p_review_no::int * interval ''7 days'') then'||chr(10)||
         '    raise exception ''exam_prep_beta_weekly_review_period_incomplete'';'||chr(10)||
         '  end if;'||chr(10)||
         '  if v_last_review_end is not null and p_period_end < v_last_review_end + interval ''6 days'' then'||chr(10)||
         '    raise exception ''exam_prep_beta_weekly_review_cadence_too_short'';'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  v_snapshot:=public.get_exam_prep_beta_weekly_snapshot_v2(p_cohort_key,p_period_end);';
  if position(v_old in v_def)=0 then raise exception 'P2-36 weekly cadence anchor missing'; end if;
  execute replace(v_def,v_old,v_new);

  -- Expanded waves (wave 2+) require the real-evidence expansion gate. Wave 1 is untouched.
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='activate_exam_prep_controlled_beta_wave_p0_16_internal_v1'
    and pg_get_function_identity_arguments(p.oid)='p_cohort_key text, p_wave smallint';
  if v_oid is null then raise exception 'P2-36 beta activation internal missing'; end if;
  v_def:=pg_get_functiondef(v_oid);

  v_old:='  v_cfg private.exam_prep_feature_config%rowtype;'||chr(10)||'begin';
  v_new:='  v_cfg private.exam_prep_feature_config%rowtype;'||chr(10)||'  v_expansion jsonb;'||chr(10)||'begin';
  if position(v_old in v_def)=0 then raise exception 'P2-36 activation declaration anchor missing'; end if;
  v_def:=replace(v_def,v_old,v_new);

  v_old:='  if p_wave<>v_c.current_wave+1 then'||chr(10)||
         '    raise exception ''exam_prep_beta_wave_must_be_next: current %, requested %'',v_c.current_wave,p_wave;'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  select count(*) into v_wave_count';
  v_new:='  if p_wave<>v_c.current_wave+1 then'||chr(10)||
         '    raise exception ''exam_prep_beta_wave_must_be_next: current %, requested %'',v_c.current_wave,p_wave;'||chr(10)||
         '  end if;'||chr(10)||
         '  if v_c.current_wave>=1 then'||chr(10)||
         '    v_expansion:=private.exam_prep_beta_expansion_gate_v1(p_cohort_key);'||chr(10)||
         '    if not coalesce((v_expansion->>''ready'')::boolean,false) then'||chr(10)||
         '      raise exception ''exam_prep_beta_expansion_gate_not_ready: %'',coalesce(v_expansion->>''reason_code'',''unknown'');'||chr(10)||
         '    end if;'||chr(10)||
         '  end if;'||chr(10)||chr(10)||
         '  select count(*) into v_wave_count';
  if position(v_old in v_def)=0 then raise exception 'P2-36 activation gate anchor missing'; end if;
  execute replace(v_def,v_old,v_new);
end $$;

revoke execute on function public.record_exam_prep_beta_weekly_review_v2(text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid) from public,anon;
grant execute on function public.record_exam_prep_beta_weekly_review_v2(text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid) to authenticated,service_role;

commit;
