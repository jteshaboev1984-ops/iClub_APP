-- P1-01: controlled-beta weekly governance, incidents and independent optional-service rollback.
--
-- Normative rules:
-- * metrics never self-authorize a GREEN release decision;
-- * weekly release decisions require an explicit governed staff reviewer;
-- * observable hard blockers may prevent a false GREEN;
-- * AI Assist runtime readiness is separate from entitlement/feature flags;
-- * AI Assist / Mentor Care can be paused without taking safe Core down;
-- * all operational mutation/read RPCs are service_role-only;
-- * migration is additive and does not create/enrol/activate a cohort.

begin;

create table if not exists private.exam_prep_optional_capability_status (
  capability_code text primary key check (capability_code in ('ai_assist')),
  runtime_status text not null check (runtime_status in ('not_deployed','shadow','ready','paused')),
  gate_version text,
  evidence jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by uuid
);

insert into private.exam_prep_optional_capability_status(capability_code,runtime_status,gate_version,evidence)
values('ai_assist','not_deployed',null,jsonb_build_object('reason','P1-01 governance baseline: AI runtime must be promoted by a later governed AI gate, not by entitlement flags.'))
on conflict(capability_code) do nothing;

create table if not exists private.exam_prep_beta_ops_incidents (
  id uuid primary key default gen_random_uuid(),
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  service_mode text check (service_mode in ('core','ai_assist','mentor_care')),
  component_code text check (component_code in ('P1','P5')),
  incident_type text not null check (incident_type in ('technical','support','content','academic','security','privacy','safeguarding','ai')),
  severity text not null check (severity in ('sev0','sev1','sev2','sev3')),
  status text not null default 'open' check (status in ('open','mitigating','resolved','closed')),
  title text not null check (char_length(trim(title)) between 5 and 240),
  details text not null check (char_length(trim(details)) between 10 and 4000),
  resolution_text text,
  detected_at timestamptz not null default now(),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  created_by uuid,
  updated_at timestamptz not null default now(),
  updated_by uuid,
  check ((status in ('resolved','closed') and resolved_at is not null) or status in ('open','mitigating'))
);

create index if not exists exam_prep_beta_ops_incidents_open_idx
on private.exam_prep_beta_ops_incidents(cohort_id,status,severity,service_mode,detected_at desc);

create table if not exists private.exam_prep_beta_weekly_reviews (
  id uuid primary key default gen_random_uuid(),
  cohort_id bigint not null references private.exam_prep_beta_cohorts(id) on delete cascade,
  review_no smallint not null check (review_no between 1 and 52),
  period_start timestamptz not null,
  period_end timestamptz not null,
  snapshot jsonb not null,
  snapshot_hash text not null,
  overall_decision text not null check (overall_decision in ('continue','hold_expansion','pause_all')),
  decision_reason text not null check (char_length(trim(decision_reason)) between 10 and 4000),
  reviewer_user_id uuid not null references public.users(id),
  created_at timestamptz not null default now(),
  unique(cohort_id,review_no),
  check (period_end > period_start)
);

create table if not exists private.exam_prep_beta_weekly_service_reviews (
  weekly_review_id uuid not null references private.exam_prep_beta_weekly_reviews(id) on delete cascade,
  service_mode text not null check (service_mode in ('core','ai_assist','mentor_care')),
  decision text not null check (decision in ('green','hold','rollback','not_applicable')),
  reason_text text not null check (char_length(trim(reason_text)) between 10 and 4000),
  created_at timestamptz not null default now(),
  primary key(weekly_review_id,service_mode)
);

alter table private.exam_prep_optional_capability_status enable row level security;
alter table private.exam_prep_beta_ops_incidents enable row level security;
alter table private.exam_prep_beta_weekly_reviews enable row level security;
alter table private.exam_prep_beta_weekly_service_reviews enable row level security;

revoke all on private.exam_prep_optional_capability_status from public,anon,authenticated;
revoke all on private.exam_prep_beta_ops_incidents from public,anon,authenticated;
revoke all on private.exam_prep_beta_weekly_reviews from public,anon,authenticated;
revoke all on private.exam_prep_beta_weekly_service_reviews from public,anon,authenticated;

grant select on private.exam_prep_optional_capability_status to service_role;
grant select,insert,update on private.exam_prep_beta_ops_incidents to service_role;
grant select,insert on private.exam_prep_beta_weekly_reviews to service_role;
grant select,insert on private.exam_prep_beta_weekly_service_reviews to service_role;

drop trigger if exists exam_prep_beta_ops_incidents_audit_v1 on private.exam_prep_beta_ops_incidents;
create trigger exam_prep_beta_ops_incidents_audit_v1
after insert or update or delete on private.exam_prep_beta_ops_incidents
for each row execute function private.exam_prep_audit_row_change_v1();

drop trigger if exists exam_prep_beta_weekly_reviews_audit_v1 on private.exam_prep_beta_weekly_reviews;
create trigger exam_prep_beta_weekly_reviews_audit_v1
after insert or update or delete on private.exam_prep_beta_weekly_reviews
for each row execute function private.exam_prep_audit_row_change_v1();

create or replace function private.exam_prep_beta_governance_reviewer_v1(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select exists(
    select 1
    from private.exam_prep_staff_roles r
    where r.user_id=p_user_id
      and r.role_code in ('lead_mentor','academic_moderator','mentor_ops','safeguarding_lead')
      and r.role_status='active'
      and r.valid_from<=now()
      and (r.valid_until is null or r.valid_until>now())
  );
$$;
revoke all on function private.exam_prep_beta_governance_reviewer_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_governance_reviewer_v1(uuid) to service_role;

-- Explicit operational incident log. It is deliberately separate from the
-- automatic metric snapshot because support/security incidents may be known
-- before they are representable in academic tables.
create or replace function public.record_exam_prep_beta_ops_incident_v1(
  p_cohort_key text,
  p_incident_type text,
  p_severity text,
  p_title text,
  p_details text,
  p_service_mode text default null,
  p_component_code text default null,
  p_reporter_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_id uuid;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if p_incident_type not in ('technical','support','content','academic','security','privacy','safeguarding','ai') then raise exception 'exam_prep_beta_bad_incident_type'; end if;
  if p_severity not in ('sev0','sev1','sev2','sev3') then raise exception 'exam_prep_beta_bad_incident_severity'; end if;
  if p_service_mode is not null and p_service_mode not in ('core','ai_assist','mentor_care') then raise exception 'exam_prep_beta_bad_service_mode'; end if;
  if p_component_code is not null and p_component_code not in ('P1','P5') then raise exception 'exam_prep_beta_bad_component'; end if;
  if p_reporter_user_id is not null and not exists(select 1 from public.users where id=p_reporter_user_id) then raise exception 'exam_prep_beta_reporter_not_found' using errcode='P0002'; end if;

  insert into private.exam_prep_beta_ops_incidents(
    cohort_id,service_mode,component_code,incident_type,severity,status,title,details,created_by,updated_by
  ) values(
    v_c.id,p_service_mode,p_component_code,p_incident_type,p_severity,'open',trim(p_title),trim(p_details),p_reporter_user_id,p_reporter_user_id
  ) returning id into v_id;

  return jsonb_build_object('incident_id',v_id,'cohort_key',p_cohort_key,'severity',p_severity,'status','open');
end;
$$;
revoke all on function public.record_exam_prep_beta_ops_incident_v1(text,text,text,text,text,text,text,uuid) from public,anon,authenticated;
grant execute on function public.record_exam_prep_beta_ops_incident_v1(text,text,text,text,text,text,text,uuid) to service_role;

create or replace function public.resolve_exam_prep_beta_ops_incident_v1(
  p_incident_id uuid,
  p_resolution_text text,
  p_resolver_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_i private.exam_prep_beta_ops_incidents%rowtype;
begin
  if p_resolution_text is null or char_length(trim(p_resolution_text)) not between 10 and 4000 then raise exception 'exam_prep_beta_incident_resolution_required'; end if;
  if not private.exam_prep_beta_governance_reviewer_v1(p_resolver_user_id) then raise exception 'exam_prep_beta_governance_reviewer_required' using errcode='42501'; end if;
  select * into v_i from private.exam_prep_beta_ops_incidents where id=p_incident_id for update;
  if v_i.id is null then raise exception 'exam_prep_beta_incident_not_found' using errcode='P0002'; end if;
  if v_i.status in ('resolved','closed') then raise exception 'exam_prep_beta_incident_already_resolved'; end if;
  update private.exam_prep_beta_ops_incidents
  set status='resolved',resolution_text=trim(p_resolution_text),resolved_at=now(),updated_at=now(),updated_by=p_resolver_user_id
  where id=v_i.id;
  return jsonb_build_object('incident_id',v_i.id,'status','resolved');
end;
$$;
revoke all on function public.resolve_exam_prep_beta_ops_incident_v1(uuid,text,uuid) from public,anon,authenticated;
grant execute on function public.resolve_exam_prep_beta_ops_incident_v1(uuid,text,uuid) to service_role;

-- Read-only weekly evidence snapshot. No GREEN/HOLD/ROLLBACK decision is derived.
create or replace function public.get_exam_prep_beta_weekly_snapshot_v1(
  p_cohort_key text,
  p_period_end timestamptz default now()
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_period_start timestamptz;
  v_monitor jsonb;
  v_ai_status text;
  v_service jsonb;
  v_component_mismatch int;
  v_nonmentor_human int;
  v_open_sev01 int;
  v_open_safeguarding int;
  v_pending_second int;
  v_hard_blockers jsonb;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.started_at is null then raise exception 'exam_prep_beta_weekly_requires_started_cohort'; end if;
  if p_period_end<=v_c.started_at then raise exception 'exam_prep_beta_bad_weekly_period'; end if;
  v_period_start:=greatest(v_c.started_at,p_period_end-interval '7 days');

  v_monitor:=public.get_exam_prep_controlled_beta_monitor_v1(p_cohort_key);
  select runtime_status into v_ai_status
  from private.exam_prep_optional_capability_status where capability_code='ai_assist';
  v_ai_status:=coalesce(v_ai_status,'not_deployed');

  with modes(service_mode) as (
    values ('core'::text),('ai_assist'::text),('mentor_care'::text)
  )
  select jsonb_object_agg(modes.service_mode,jsonb_build_object(
    'active_members',(select count(*) from private.exam_prep_beta_members bm where bm.cohort_id=v_c.id and bm.member_status='active' and bm.service_mode=modes.service_mode),
    'paused_members',(select count(*) from private.exam_prep_beta_members bm where bm.cohort_id=v_c.id and bm.member_status='paused' and bm.service_mode=modes.service_mode),
    'sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'finalized_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.status='finalized' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'abandoned_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.status='abandoned' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'p1_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.component_code='P1' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'p5_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.component_code='P5' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'timed_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.session_type='timed' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'paper_sessions',(select count(*) from private.exam_prep_sessions s join private.exam_prep_beta_members bm on bm.user_id=s.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and s.session_type='paper' and s.started_at>=v_period_start and s.started_at<=p_period_end),
    'evidence_events',(select count(*) from private.exam_prep_evidence_events e join private.exam_prep_beta_members bm on bm.user_id=e.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and e.created_at>=v_period_start and e.created_at<=p_period_end),
    'placements_confirmed',(select count(*) from private.exam_prep_component_placements p join private.exam_prep_beta_members bm on bm.user_id=p.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and p.placement_status='confirmed'),
    'placement_ambiguity',(select count(*) from private.exam_prep_component_placements p join private.exam_prep_beta_members bm on bm.user_id=p.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and p.ambiguity),
    'advanced_skip_human_pending',(select count(*) from private.exam_prep_component_placements p join private.exam_prep_beta_members bm on bm.user_id=p.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and p.advanced_skip_requires_human),
    'open_corrections',(select count(*) from private.exam_prep_correction_cases c join private.exam_prep_beta_members bm on bm.user_id=c.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and c.status<>'resolved'),
    'scheduled_retests',(select count(*) from private.exam_prep_retest_events r join private.exam_prep_beta_members bm on bm.user_id=r.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and r.status in ('scheduled','authorized')),
    'completed_retests',(select count(*) from private.exam_prep_retest_events r join private.exam_prep_beta_members bm on bm.user_id=r.user_id and bm.cohort_id=v_c.id where bm.service_mode=modes.service_mode and r.status='completed' and r.completed_at>=v_period_start and r.completed_at<=p_period_end)
  )) into v_service from modes;

  select count(*) into v_component_mismatch
  from private.exam_prep_evidence_events e
  join private.exam_prep_sessions s on s.id=e.session_id
  left join private.exam_prep_responses r on r.id=e.response_id
  join private.exam_prep_beta_members bm on bm.user_id=e.user_id and bm.cohort_id=v_c.id
  where e.created_at>=v_period_start and e.created_at<=p_period_end
    and (s.user_id<>e.user_id or s.component_code<>e.component_code or r.id is null or r.session_id<>e.session_id or r.user_id<>e.user_id);

  select count(*) into v_nonmentor_human
  from private.exam_prep_skill_states st
  join private.exam_prep_beta_members bm on bm.user_id=st.user_id and bm.cohort_id=v_c.id
  where bm.member_status='active' and bm.service_mode<>'mentor_care' and st.has_mentor_verified_evidence;

  select count(*) into v_open_sev01
  from private.exam_prep_beta_ops_incidents i
  where i.cohort_id=v_c.id and i.status in ('open','mitigating') and i.severity in ('sev0','sev1');

  select count(*) into v_open_safeguarding
  from private.exam_prep_safeguarding_events s
  join private.exam_prep_beta_members bm on bm.user_id=s.learner_user_id and bm.cohort_id=v_c.id
  where s.status<>'closed' and s.severity in ('urgent','critical');

  select count(*) into v_pending_second
  from private.exam_prep_mentor_reviews r
  join private.exam_prep_beta_members bm on bm.user_id=r.learner_user_id and bm.cohort_id=v_c.id
  where r.review_status='pending_second_check';

  v_hard_blockers:=jsonb_build_object(
    'entitlement_mismatches',coalesce((v_monitor#>>'{integrity,entitlement_mismatches}')::int,0),
    'mentor_readiness_violations',coalesce((v_monitor#>>'{integrity,mentor_readiness_violations}')::int,0),
    'queue_leakage',coalesce((v_monitor#>>'{integrity,queue_leakage}')::int,0),
    'component_evidence_mismatches',v_component_mismatch,
    'nonmentor_human_verified_state',v_nonmentor_human,
    'open_sev0_sev1_incidents',v_open_sev01,
    'open_urgent_critical_safeguarding',v_open_safeguarding
  );

  return jsonb_build_object(
    'cohort_key',p_cohort_key,
    'period_start',v_period_start,
    'period_end',p_period_end,
    'captured_at',now(),
    'p0_16_monitor',v_monitor,
    'service_metrics',v_service,
    'ai_runtime_status',v_ai_status,
    'mentor_pending_second_checks',v_pending_second,
    'hard_blockers',v_hard_blockers,
    'decision','NOT_DERIVED_BY_SYSTEM'
  );
end;
$$;
revoke all on function public.get_exam_prep_beta_weekly_snapshot_v1(text,timestamptz) from public,anon,authenticated;
grant execute on function public.get_exam_prep_beta_weekly_snapshot_v1(text,timestamptz) to service_role;

-- Human/governance decision recorder. Metrics can veto a false GREEN but can
-- never generate GREEN by themselves.
create or replace function public.record_exam_prep_beta_weekly_review_v1(
  p_cohort_key text,
  p_review_no smallint,
  p_period_end timestamptz,
  p_overall_decision text,
  p_core_decision text,
  p_ai_decision text,
  p_mentor_decision text,
  p_decision_reason text,
  p_core_reason text,
  p_ai_reason text,
  p_mentor_reason text,
  p_reviewer_user_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_snapshot jsonb;
  v_review uuid;
  v_expected int;
  v_ai_active int;
  v_mentor_active int;
  v_core_blockers int;
  v_mentor_blockers int;
  v_ai_status text;
begin
  if not private.exam_prep_beta_governance_reviewer_v1(p_reviewer_user_id) then raise exception 'exam_prep_beta_governance_reviewer_required' using errcode='42501'; end if;
  if p_overall_decision not in ('continue','hold_expansion','pause_all') then raise exception 'exam_prep_beta_bad_overall_decision'; end if;
  if p_core_decision not in ('green','hold','rollback') then raise exception 'exam_prep_beta_bad_core_decision'; end if;
  if p_ai_decision not in ('green','hold','rollback','not_applicable') then raise exception 'exam_prep_beta_bad_ai_decision'; end if;
  if p_mentor_decision not in ('green','hold','rollback','not_applicable') then raise exception 'exam_prep_beta_bad_mentor_decision'; end if;
  if p_decision_reason is null or char_length(trim(p_decision_reason)) not between 10 and 4000 then raise exception 'exam_prep_beta_weekly_reason_required'; end if;

  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('canary','active','paused') then raise exception 'exam_prep_beta_weekly_bad_cohort_status'; end if;

  select coalesce(max(review_no),0)+1 into v_expected from private.exam_prep_beta_weekly_reviews where cohort_id=v_c.id;
  if p_review_no<>v_expected then raise exception 'exam_prep_beta_weekly_review_must_be_sequential: expected %, got %',v_expected,p_review_no; end if;

  v_snapshot:=public.get_exam_prep_beta_weekly_snapshot_v1(p_cohort_key,p_period_end);
  v_ai_active:=coalesce((v_snapshot#>>'{service_metrics,ai_assist,active_members}')::int,0);
  v_mentor_active:=coalesce((v_snapshot#>>'{service_metrics,mentor_care,active_members}')::int,0);
  v_ai_status:=coalesce(v_snapshot->>'ai_runtime_status','not_deployed');

  if v_ai_active=0 and p_ai_decision<>'not_applicable' then raise exception 'exam_prep_beta_ai_decision_must_be_not_applicable_when_inactive'; end if;
  if v_ai_active>0 and p_ai_decision='not_applicable' then raise exception 'exam_prep_beta_ai_decision_required_when_active'; end if;
  if v_mentor_active=0 and p_mentor_decision<>'not_applicable' then raise exception 'exam_prep_beta_mentor_decision_must_be_not_applicable_when_inactive'; end if;
  if v_mentor_active>0 and p_mentor_decision='not_applicable' then raise exception 'exam_prep_beta_mentor_decision_required_when_active'; end if;

  v_core_blockers:=
    coalesce((v_snapshot#>>'{hard_blockers,entitlement_mismatches}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,component_evidence_mismatches}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,nonmentor_human_verified_state}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,open_sev0_sev1_incidents}')::int,0);
  v_mentor_blockers:=
    coalesce((v_snapshot#>>'{hard_blockers,mentor_readiness_violations}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,queue_leakage}')::int,0)+
    coalesce((v_snapshot#>>'{hard_blockers,open_urgent_critical_safeguarding}')::int,0);

  if p_core_decision='green' and v_core_blockers<>0 then raise exception 'exam_prep_beta_false_green_core_blockers=%',v_core_blockers; end if;
  if p_ai_decision='green' and v_ai_status<>'ready' then raise exception 'exam_prep_beta_false_green_ai_runtime_status=%',v_ai_status; end if;
  if p_mentor_decision='green' and v_mentor_blockers<>0 then raise exception 'exam_prep_beta_false_green_mentor_blockers=%',v_mentor_blockers; end if;

  if p_overall_decision='continue' and (p_core_decision<>'green' or (v_ai_active>0 and p_ai_decision<>'green') or (v_mentor_active>0 and p_mentor_decision<>'green')) then
    raise exception 'exam_prep_beta_continue_requires_all_active_services_green';
  end if;
  if p_core_decision='rollback' and p_overall_decision<>'pause_all' then raise exception 'exam_prep_beta_core_rollback_requires_pause_all'; end if;

  insert into private.exam_prep_beta_weekly_reviews(
    cohort_id,review_no,period_start,period_end,snapshot,snapshot_hash,overall_decision,decision_reason,reviewer_user_id
  ) values(
    v_c.id,p_review_no,(v_snapshot->>'period_start')::timestamptz,p_period_end,v_snapshot,md5(v_snapshot::text),p_overall_decision,trim(p_decision_reason),p_reviewer_user_id
  ) returning id into v_review;

  insert into private.exam_prep_beta_weekly_service_reviews(weekly_review_id,service_mode,decision,reason_text)
  values
    (v_review,'core',p_core_decision,trim(p_core_reason)),
    (v_review,'ai_assist',p_ai_decision,trim(p_ai_reason)),
    (v_review,'mentor_care',p_mentor_decision,trim(p_mentor_reason));

  insert into private.exam_prep_audit_events(program_key,actor_user_id,actor_role,event_type,object_type,object_id,metadata)
  values('math_as_p1_p5',p_reviewer_user_id,'beta_governance','beta_weekly_review_recorded','private.exam_prep_beta_weekly_reviews',v_review::text,
    jsonb_build_object('cohort_key',p_cohort_key,'review_no',p_review_no,'overall_decision',p_overall_decision));

  return jsonb_build_object('review_id',v_review,'cohort_key',p_cohort_key,'review_no',p_review_no,'overall_decision',p_overall_decision,'snapshot_hash',md5(v_snapshot::text));
end;
$$;
revoke all on function public.record_exam_prep_beta_weekly_review_v1(text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid) from public,anon,authenticated;
grant execute on function public.record_exam_prep_beta_weekly_review_v1(text,smallint,timestamptz,text,text,text,text,text,text,text,text,uuid) to service_role;

-- Independent optional-capability rollback. Core is deliberately excluded:
-- Core failure must use the global P0-16 pause/kill-switch path.
create or replace function public.pause_exam_prep_controlled_beta_service_v1(
  p_cohort_key text,
  p_service_mode text,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_count int;
begin
  if p_service_mode not in ('ai_assist','mentor_care') then raise exception 'exam_prep_beta_optional_service_only'; end if;
  if p_reason is null or char_length(trim(p_reason)) not between 10 and 1000 then raise exception 'exam_prep_beta_service_pause_reason_required'; end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('canary','active') then raise exception 'exam_prep_beta_cohort_not_live'; end if;

  update private.exam_prep_feature_entitlements e
  set entitlement_status='paused',updated_at=now(),updated_by=auth.uid()
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.user_id=e.user_id and m.member_status='active'
    and m.service_mode=p_service_mode and e.entitlement_status='active' and e.cohort_key=p_cohort_key;

  update private.exam_prep_beta_members
  set member_status='paused',paused_at=now(),updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='active' and service_mode=p_service_mode;
  get diagnostics v_count=row_count;

  if p_service_mode='mentor_care' then
    update private.exam_prep_mentor_service_status s
    set service_status='assigned_paused',status_reason='controlled_beta_service_paused: '||left(trim(p_reason),500),status_changed_at=now(),updated_at=now(),updated_by=auth.uid()
    from private.exam_prep_beta_members m
    where m.cohort_id=v_c.id and m.user_id=s.learner_user_id and m.member_status='paused' and m.service_mode='mentor_care' and s.service_status='assigned_active';
  end if;

  update private.exam_prep_feature_config
  set ai_enabled=exists(select 1 from private.exam_prep_beta_members m where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='ai_assist'),
      mentor_enabled=exists(select 1 from private.exam_prep_beta_members m where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='mentor_care'),
      updated_at=now(),updated_by=auth.uid()
  where id=1 and rollout_state='controlled_beta' and core_enabled and not kill_switch;

  return jsonb_build_object('cohort_key',p_cohort_key,'service_mode',p_service_mode,'status','paused','paused_members',v_count,'core_preserved',true,'reason',trim(p_reason));
end;
$$;
revoke all on function public.pause_exam_prep_controlled_beta_service_v1(text,text,text) from public,anon,authenticated;
grant execute on function public.pause_exam_prep_controlled_beta_service_v1(text,text,text) to service_role;

-- Resume an optional service only against the latest explicit GREEN review.
create or replace function public.resume_exam_prep_controlled_beta_service_v1(
  p_cohort_key text,
  p_service_mode text,
  p_weekly_review_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_c private.exam_prep_beta_cohorts%rowtype;
  v_latest uuid;
  v_decision text;
  v_bad int;
  v_count int;
  v_ai_status text;
begin
  if p_service_mode not in ('ai_assist','mentor_care') then raise exception 'exam_prep_beta_optional_service_only'; end if;
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key for update;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if v_c.cohort_status not in ('canary','active') then raise exception 'exam_prep_beta_cohort_not_live'; end if;

  select r.id into v_latest from private.exam_prep_beta_weekly_reviews r where r.cohort_id=v_c.id order by r.review_no desc limit 1;
  if v_latest is null or v_latest<>p_weekly_review_id then raise exception 'exam_prep_beta_resume_requires_latest_weekly_review'; end if;
  select s.decision into v_decision from private.exam_prep_beta_weekly_service_reviews s where s.weekly_review_id=v_latest and s.service_mode=p_service_mode;
  if v_decision<>'green' then raise exception 'exam_prep_beta_resume_requires_green_service_review'; end if;

  if p_service_mode='ai_assist' then
    select runtime_status into v_ai_status from private.exam_prep_optional_capability_status where capability_code='ai_assist';
    if coalesce(v_ai_status,'not_deployed')<>'ready' then raise exception 'exam_prep_beta_ai_runtime_not_ready'; end if;
  else
    select count(*) into v_bad
    from private.exam_prep_beta_members m
    where m.cohort_id=v_c.id and m.member_status='paused' and m.service_mode='mentor_care'
      and (
        not exists(select 1 from private.exam_prep_mentor_service_status s where s.learner_user_id=m.user_id and s.service_status in ('assigned_active','assigned_paused'))
        or not exists(
          select 1 from private.exam_prep_mentor_assignments a
          where a.learner_user_id=m.user_id and a.component_code in ('P1','P5') and a.assignment_status='active'
            and a.valid_from<=now() and (a.valid_until is null or a.valid_until>now())
            and exists(select 1 from private.exam_prep_staff_roles r where r.user_id=a.mentor_user_id and r.role_code in ('mentor','lead_mentor','academic_moderator') and r.role_status='active' and r.valid_from<=now() and (r.valid_until is null or r.valid_until>now()))
        )
      );
    if v_bad<>0 then raise exception 'exam_prep_beta_resume_mentor_readiness_violations=%',v_bad; end if;
  end if;

  update private.exam_prep_feature_entitlements e
  set entitlement_status='active',core_access=true,
      ai_assist=(p_service_mode='ai_assist'),mentor_care_entitled=(p_service_mode='mentor_care'),
      valid_from=now(),valid_until=null,updated_at=now(),updated_by=auth.uid()
  from private.exam_prep_beta_members m
  where m.cohort_id=v_c.id and m.user_id=e.user_id and m.member_status='paused' and m.service_mode=p_service_mode and e.cohort_key=p_cohort_key;

  update private.exam_prep_beta_members
  set member_status='active',paused_at=null,updated_at=now(),updated_by=auth.uid()
  where cohort_id=v_c.id and member_status='paused' and service_mode=p_service_mode;
  get diagnostics v_count=row_count;

  if p_service_mode='mentor_care' then
    update private.exam_prep_mentor_service_status s
    set service_status='assigned_active',status_reason='controlled_beta_service_resumed_after_green_review',status_changed_at=now(),updated_at=now(),updated_by=auth.uid()
    from private.exam_prep_beta_members m
    where m.cohort_id=v_c.id and m.user_id=s.learner_user_id and m.member_status='active' and m.service_mode='mentor_care' and s.service_status='assigned_paused';
  end if;

  update private.exam_prep_feature_config
  set ai_enabled=exists(select 1 from private.exam_prep_beta_members m where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='ai_assist'),
      mentor_enabled=exists(select 1 from private.exam_prep_beta_members m where m.cohort_id=v_c.id and m.member_status='active' and m.service_mode='mentor_care'),
      updated_at=now(),updated_by=auth.uid()
  where id=1 and rollout_state='controlled_beta' and core_enabled and not kill_switch;

  return jsonb_build_object('cohort_key',p_cohort_key,'service_mode',p_service_mode,'status','active','resumed_members',v_count,'weekly_review_id',p_weekly_review_id);
end;
$$;
revoke all on function public.resume_exam_prep_controlled_beta_service_v1(text,text,uuid) from public,anon,authenticated;
grant execute on function public.resume_exam_prep_controlled_beta_service_v1(text,text,uuid) to service_role;

-- Harden the P0-16 wave activation contract: AI entitlement may not activate
-- until a later governed AI layer has explicitly promoted runtime_status=ready.
create or replace function private.exam_prep_beta_ai_wave_ready_v1(p_cohort_id bigint,p_wave smallint)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select
    not exists(
      select 1 from private.exam_prep_beta_members m
      where m.cohort_id=p_cohort_id and m.member_status='approved' and m.activation_wave=p_wave and m.service_mode='ai_assist'
    )
    or exists(
      select 1 from private.exam_prep_optional_capability_status s
      where s.capability_code='ai_assist' and s.runtime_status='ready'
    );
$$;
revoke all on function private.exam_prep_beta_ai_wave_ready_v1(bigint,smallint) from public,anon,authenticated;
grant execute on function private.exam_prep_beta_ai_wave_ready_v1(bigint,smallint) to service_role;

-- Preserve the P0-16 activation implementation but add the AI runtime gate by
-- wrapping/revalidating before delegating to an internal renamed implementation.
alter function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint)
rename to activate_exam_prep_controlled_beta_wave_p0_16_internal_v1;
revoke all on function public.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(text,smallint) from public,anon,authenticated;
grant execute on function public.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(text,smallint) to service_role;

create or replace function public.activate_exam_prep_controlled_beta_wave_v1(p_cohort_key text,p_wave smallint)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare v_c private.exam_prep_beta_cohorts%rowtype;
begin
  select * into v_c from private.exam_prep_beta_cohorts where cohort_key=p_cohort_key;
  if v_c.id is null then raise exception 'exam_prep_beta_cohort_not_found' using errcode='P0002'; end if;
  if not private.exam_prep_beta_ai_wave_ready_v1(v_c.id,p_wave) then raise exception 'exam_prep_beta_ai_runtime_not_ready'; end if;
  return public.activate_exam_prep_controlled_beta_wave_p0_16_internal_v1(p_cohort_key,p_wave);
end;
$$;
revoke all on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) from public,anon,authenticated;
grant execute on function public.activate_exam_prep_controlled_beta_wave_v1(text,smallint) to service_role;

-- Deployment assertions: no cohort/entitlement activation and no client-visible
-- governance mutation surface.
do $$
declare v_bad int;
begin
  select count(*) into v_bad from private.exam_prep_beta_cohorts;
  if v_bad<>0 then raise exception 'P1-01 deployment must not create beta cohorts'; end if;
  select count(*) into v_bad from private.exam_prep_feature_entitlements where entitlement_status='active' and cohort_key is not null;
  if v_bad<>0 then raise exception 'P1-01 deployment must not activate beta entitlements'; end if;
  select count(*) into v_bad from private.exam_prep_feature_config where id=1 and (rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch);
  if v_bad<>0 then raise exception 'P1-01 deployment must remain fail-closed'; end if;

  select count(*) into v_bad
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public'
    and p.proname in (
      'record_exam_prep_beta_ops_incident_v1','resolve_exam_prep_beta_ops_incident_v1',
      'get_exam_prep_beta_weekly_snapshot_v1','record_exam_prep_beta_weekly_review_v1',
      'pause_exam_prep_controlled_beta_service_v1','resume_exam_prep_controlled_beta_service_v1',
      'activate_exam_prep_controlled_beta_wave_v1','activate_exam_prep_controlled_beta_wave_p0_16_internal_v1'
    )
    and (has_function_privilege('anon',p.oid,'EXECUTE') or has_function_privilege('authenticated',p.oid,'EXECUTE'));
  if v_bad<>0 then raise exception 'P1-01 governance RPC privilege leak count=%',v_bad; end if;
end;
$$;

commit;
