begin;

-- P2-68: synthetic-only academic virtual time.
-- The real server clock remains authoritative for real learners and for strict
-- timed-assessment security/deadlines. This clock exists only to accelerate
-- synthetic academic chronology (active week, evidence, corrections and
-- delayed-retention windows) without changing PostgreSQL/server time.

create table if not exists private.exam_prep_synthetic_run_clocks(
  run_id text primary key
    references private.exam_prep_synthetic_validation_runs(run_id) on delete restrict,
  virtual_now timestamptz not null,
  step_no integer not null default 0 check(step_no>=0),
  clock_status text not null default 'active' check(clock_status in ('active','frozen')),
  initialized_evidence_ref text not null check(char_length(trim(initialized_evidence_ref))>=8),
  last_reason text,
  initialized_at timestamptz not null default clock_timestamp(),
  updated_at timestamptz not null default clock_timestamp()
);

create table if not exists private.exam_prep_synthetic_timeline_events(
  id bigint generated always as identity primary key,
  run_id text not null
    references private.exam_prep_synthetic_validation_runs(run_id) on delete restrict,
  sequence_no integer not null check(sequence_no>=0),
  event_type text not null check(event_type in ('clock_initialized','clock_advanced','clock_frozen','checkpoint')),
  virtual_at timestamptz not null,
  details jsonb not null default '{}'::jsonb check(jsonb_typeof(details)='object'),
  created_at timestamptz not null default clock_timestamp(),
  unique(run_id,sequence_no)
);

create index if not exists exam_prep_synthetic_timeline_events_run_idx
  on private.exam_prep_synthetic_timeline_events(run_id,sequence_no);

alter table private.exam_prep_synthetic_run_clocks enable row level security;
alter table private.exam_prep_synthetic_timeline_events enable row level security;
revoke all on private.exam_prep_synthetic_run_clocks from public,anon,authenticated,service_role;
revoke all on private.exam_prep_synthetic_timeline_events from public,anon,authenticated,service_role;
grant select on private.exam_prep_synthetic_run_clocks to service_role;
grant select on private.exam_prep_synthetic_timeline_events to service_role;

create or replace function private.enforce_exam_prep_synthetic_clock_write_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if current_setting('iclub.exam_prep_synthetic_clock_write',true) is distinct from 'on' then
    raise exception 'exam_prep_synthetic_clock_direct_write_forbidden';
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_clock_write_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_run_clock_write_guard_v1
  on private.exam_prep_synthetic_run_clocks;
create trigger exam_prep_synthetic_run_clock_write_guard_v1
before insert or update on private.exam_prep_synthetic_run_clocks
for each row execute function private.enforce_exam_prep_synthetic_clock_write_v1();

create or replace function private.enforce_exam_prep_synthetic_timeline_append_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
begin
  if tg_op<>'INSERT' then
    raise exception 'exam_prep_synthetic_timeline_immutable';
  end if;
  if current_setting('iclub.exam_prep_synthetic_clock_write',true) is distinct from 'on' then
    raise exception 'exam_prep_synthetic_timeline_direct_write_forbidden';
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_exam_prep_synthetic_timeline_append_v1() from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_timeline_append_guard_v1
  on private.exam_prep_synthetic_timeline_events;
create trigger exam_prep_synthetic_timeline_append_guard_v1
before insert or update or delete on private.exam_prep_synthetic_timeline_events
for each row execute function private.enforce_exam_prep_synthetic_timeline_append_v1();

create or replace function private.initialize_exam_prep_synthetic_clock_v1(
  p_run_id text,
  p_evidence_ref text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_clock private.exam_prep_synthetic_run_clocks%rowtype;
  v_now timestamptz;
begin
  if p_evidence_ref is null or char_length(trim(p_evidence_ref))<8 then
    raise exception 'exam_prep_synthetic_clock_evidence_ref_required';
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;
  if v_run.run_status<>'running' or v_run.cleanup_status<>'not_started' then
    raise exception 'exam_prep_synthetic_clock_requires_running_clean_run';
  end if;
  if not exists(
    select 1 from private.exam_prep_synthetic_identities s
    where s.run_id=p_run_id and s.identity_status='active'
  ) then
    raise exception 'exam_prep_synthetic_clock_requires_active_identity';
  end if;

  select * into v_clock
  from private.exam_prep_synthetic_run_clocks
  where run_id=p_run_id
  for update;
  if v_clock.run_id is not null then
    if v_clock.clock_status<>'active' then
      raise exception 'exam_prep_synthetic_clock_not_active';
    end if;
    return jsonb_build_object(
      'run_id',v_clock.run_id,'virtual_now',v_clock.virtual_now,'step_no',v_clock.step_no,
      'clock_status',v_clock.clock_status,'idempotent',true
    );
  end if;

  v_now:=clock_timestamp();
  perform set_config('iclub.exam_prep_synthetic_clock_write','on',true);

  insert into private.exam_prep_synthetic_run_clocks(
    run_id,virtual_now,step_no,clock_status,initialized_evidence_ref,last_reason
  ) values(
    p_run_id,v_now,0,'active',trim(p_evidence_ref),'initialized'
  ) returning * into v_clock;

  insert into private.exam_prep_synthetic_timeline_events(
    run_id,sequence_no,event_type,virtual_at,details
  ) values(
    p_run_id,0,'clock_initialized',v_now,
    jsonb_build_object(
      'evidence_ref',trim(p_evidence_ref),
      'real_clock_at_initialization',clock_timestamp(),
      'strict_timed_security_clock','real_server_time',
      'academic_clock','synthetic_virtual_time'
    )
  );

  perform set_config('iclub.exam_prep_synthetic_clock_write','off',true);

  return jsonb_build_object(
    'run_id',v_clock.run_id,'virtual_now',v_clock.virtual_now,'step_no',v_clock.step_no,
    'clock_status',v_clock.clock_status,'idempotent',false
  );
exception when others then
  begin perform set_config('iclub.exam_prep_synthetic_clock_write','off',true); exception when others then null; end;
  raise;
end;
$$;
revoke all on function private.initialize_exam_prep_synthetic_clock_v1(text,text)
  from public,anon,authenticated;
grant execute on function private.initialize_exam_prep_synthetic_clock_v1(text,text)
  to service_role;

create or replace function private.advance_exam_prep_synthetic_clock_v1(
  p_run_id text,
  p_expected_virtual_now timestamptz,
  p_advance_seconds bigint,
  p_reason text
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_clock private.exam_prep_synthetic_run_clocks%rowtype;
  v_new timestamptz;
begin
  if p_expected_virtual_now is null then
    raise exception 'exam_prep_synthetic_clock_expected_time_required';
  end if;
  if p_advance_seconds is null or p_advance_seconds<1 or p_advance_seconds>1209600 then
    raise exception 'exam_prep_synthetic_clock_advance_out_of_range';
  end if;
  if p_reason is null or char_length(trim(p_reason))<8 then
    raise exception 'exam_prep_synthetic_clock_reason_required';
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=p_run_id
  for update;
  if v_run.run_id is null then raise exception 'exam_prep_synthetic_run_not_found'; end if;
  if v_run.run_status<>'running' or v_run.cleanup_status<>'not_started' then
    raise exception 'exam_prep_synthetic_clock_requires_running_clean_run';
  end if;

  select * into v_clock
  from private.exam_prep_synthetic_run_clocks
  where run_id=p_run_id
  for update;
  if v_clock.run_id is null then raise exception 'exam_prep_synthetic_clock_not_initialized'; end if;
  if v_clock.clock_status<>'active' then raise exception 'exam_prep_synthetic_clock_not_active'; end if;
  if v_clock.virtual_now is distinct from p_expected_virtual_now then
    raise exception 'exam_prep_synthetic_clock_stale_expected_time';
  end if;

  v_new:=v_clock.virtual_now + make_interval(secs=>p_advance_seconds::double precision);
  if v_new<=v_clock.virtual_now then raise exception 'exam_prep_synthetic_clock_must_move_forward'; end if;

  perform set_config('iclub.exam_prep_synthetic_clock_write','on',true);

  update private.exam_prep_synthetic_run_clocks
  set virtual_now=v_new,
      step_no=v_clock.step_no+1,
      last_reason=trim(p_reason),
      updated_at=clock_timestamp()
  where run_id=p_run_id
  returning * into v_clock;

  insert into private.exam_prep_synthetic_timeline_events(
    run_id,sequence_no,event_type,virtual_at,details
  ) values(
    p_run_id,v_clock.step_no,'clock_advanced',v_clock.virtual_now,
    jsonb_build_object(
      'advance_seconds',p_advance_seconds,
      'reason',trim(p_reason),
      'previous_virtual_now',p_expected_virtual_now
    )
  );

  perform set_config('iclub.exam_prep_synthetic_clock_write','off',true);

  return jsonb_build_object(
    'run_id',v_clock.run_id,'virtual_now',v_clock.virtual_now,'step_no',v_clock.step_no,
    'clock_status',v_clock.clock_status,'idempotent',false
  );
exception when others then
  begin perform set_config('iclub.exam_prep_synthetic_clock_write','off',true); exception when others then null; end;
  raise;
end;
$$;
revoke all on function private.advance_exam_prep_synthetic_clock_v1(text,timestamptz,bigint,text)
  from public,anon,authenticated;
grant execute on function private.advance_exam_prep_synthetic_clock_v1(text,timestamptz,bigint,text)
  to service_role;

create or replace function private.freeze_exam_prep_synthetic_clock_on_run_terminal_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_clock private.exam_prep_synthetic_run_clocks%rowtype;
begin
  if old.run_status is not distinct from new.run_status
     or new.run_status not in ('completed','failed','aborted') then
    return new;
  end if;

  select * into v_clock
  from private.exam_prep_synthetic_run_clocks
  where run_id=new.run_id
  for update;
  if v_clock.run_id is null or v_clock.clock_status='frozen' then
    return new;
  end if;

  perform set_config('iclub.exam_prep_synthetic_clock_write','on',true);

  update private.exam_prep_synthetic_run_clocks
  set clock_status='frozen',
      step_no=v_clock.step_no+1,
      last_reason='run_terminal:'||new.run_status,
      updated_at=clock_timestamp()
  where run_id=new.run_id
  returning * into v_clock;

  insert into private.exam_prep_synthetic_timeline_events(
    run_id,sequence_no,event_type,virtual_at,details
  ) values(
    new.run_id,v_clock.step_no,'clock_frozen',v_clock.virtual_now,
    jsonb_build_object('terminal_run_status',new.run_status)
  );

  perform set_config('iclub.exam_prep_synthetic_clock_write','off',true);
  return new;
exception when others then
  begin perform set_config('iclub.exam_prep_synthetic_clock_write','off',true); exception when others then null; end;
  raise;
end;
$$;
revoke all on function private.freeze_exam_prep_synthetic_clock_on_run_terminal_v1()
  from public,anon,authenticated;

drop trigger if exists exam_prep_synthetic_clock_freeze_on_run_terminal_v1
  on private.exam_prep_synthetic_validation_runs;
create trigger exam_prep_synthetic_clock_freeze_on_run_terminal_v1
after update of run_status on private.exam_prep_synthetic_validation_runs
for each row execute function private.freeze_exam_prep_synthetic_clock_on_run_terminal_v1();

create or replace function private.exam_prep_effective_academic_now_v1(p_user_id uuid)
returns timestamptz
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_identity private.exam_prep_synthetic_identities%rowtype;
  v_run private.exam_prep_synthetic_validation_runs%rowtype;
  v_clock private.exam_prep_synthetic_run_clocks%rowtype;
begin
  if p_user_id is null then
    raise exception 'exam_prep_academic_clock_user_required';
  end if;

  select * into v_identity
  from private.exam_prep_synthetic_identities
  where user_id=p_user_id;

  if v_identity.user_id is null then
    return now();
  end if;
  if v_identity.identity_status<>'active' then
    raise exception 'exam_prep_synthetic_identity_not_active';
  end if;

  select * into v_run
  from private.exam_prep_synthetic_validation_runs
  where run_id=v_identity.run_id;
  if v_run.run_id is null or v_run.run_status<>'running' or v_run.cleanup_status<>'not_started' then
    raise exception 'exam_prep_synthetic_virtual_clock_run_not_active';
  end if;

  select * into v_clock
  from private.exam_prep_synthetic_run_clocks
  where run_id=v_identity.run_id;
  if v_clock.run_id is null or v_clock.clock_status<>'active' then
    raise exception 'exam_prep_synthetic_virtual_clock_unavailable';
  end if;

  return v_clock.virtual_now;
end;
$$;
revoke all on function private.exam_prep_effective_academic_now_v1(uuid)
  from public,anon,authenticated;
grant execute on function private.exam_prep_effective_academic_now_v1(uuid)
  to service_role;

-- Stamp immutable/rebuildable academic chronology only for registered synthetic
-- identities. Real learner timestamps are returned untouched.
create or replace function private.stamp_exam_prep_synthetic_academic_time_v1()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_now timestamptz;
begin
  if new.user_id is null
     or not exists(select 1 from private.exam_prep_synthetic_identities s where s.user_id=new.user_id) then
    return new;
  end if;

  v_now:=private.exam_prep_effective_academic_now_v1(new.user_id);

  if tg_table_name='exam_prep_evidence_events' then
    new.created_at:=v_now;
  elsif tg_table_name='exam_prep_correction_cases' then
    if tg_op='INSERT' then
      new.opened_at:=v_now;
    end if;
    new.updated_at:=v_now;
    if tg_op='UPDATE'
       and new.resolved_at is not null
       and new.resolved_at is distinct from old.resolved_at then
      new.resolved_at:=v_now;
    end if;
  elsif tg_table_name='exam_prep_retest_events' then
    if tg_op='INSERT' then
      new.created_at:=v_now;
    end if;
    if tg_op='UPDATE'
       and new.completed_at is not null
       and new.completed_at is distinct from old.completed_at then
      new.completed_at:=v_now;
    end if;
  elsif tg_table_name='exam_prep_correction_actions' then
    new.created_at:=v_now;
  elsif tg_table_name='exam_prep_weekly_plans' then
    new.generated_at:=v_now;
  elsif tg_table_name='exam_prep_weekly_plan_items' then
    new.created_at:=v_now;
  end if;

  return new;
end;
$$;
revoke all on function private.stamp_exam_prep_synthetic_academic_time_v1()
  from public,anon,authenticated;

drop trigger if exists exam_prep_evidence_synthetic_time_v1 on private.exam_prep_evidence_events;
create trigger exam_prep_evidence_synthetic_time_v1
before insert on private.exam_prep_evidence_events
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

drop trigger if exists exam_prep_correction_case_synthetic_time_v1 on private.exam_prep_correction_cases;
create trigger exam_prep_correction_case_synthetic_time_v1
before insert or update on private.exam_prep_correction_cases
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

drop trigger if exists exam_prep_retest_event_synthetic_time_v1 on private.exam_prep_retest_events;
create trigger exam_prep_retest_event_synthetic_time_v1
before insert or update on private.exam_prep_retest_events
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

drop trigger if exists exam_prep_correction_action_synthetic_time_v1 on private.exam_prep_correction_actions;
create trigger exam_prep_correction_action_synthetic_time_v1
before insert on private.exam_prep_correction_actions
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

drop trigger if exists exam_prep_weekly_plan_synthetic_time_v1 on private.exam_prep_weekly_plans;
create trigger exam_prep_weekly_plan_synthetic_time_v1
before insert on private.exam_prep_weekly_plans
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

drop trigger if exists exam_prep_weekly_plan_item_synthetic_time_v1 on private.exam_prep_weekly_plan_items;
create trigger exam_prep_weekly_plan_item_synthetic_time_v1
before insert on private.exam_prep_weekly_plan_items
for each row execute function private.stamp_exam_prep_synthetic_academic_time_v1();

-- Patch only the exact current time-sensitive Core functions. Each count is
-- asserted first so a future definition drift fails the migration closed.
do $$
declare
  v_oid oid;
  v_def text;
  v_count int;
begin
  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_effective_active_week_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid';
  if v_oid is null then raise exception 'P2-68 active-week function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>1 then raise exception 'P2-68 active-week now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(p_user_id)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='rebuild_exam_prep_state_v1'
    and pg_get_function_identity_arguments(p.oid)='p_user_id uuid, p_component_code text';
  if v_oid is null then raise exception 'P2-68 state rebuild function missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>3 then raise exception 'P2-68 state rebuild now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(p_user_id)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_retest_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_correction_case_id uuid';
  if v_oid is null then raise exception 'P2-68 retest authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>3 then raise exception 'P2-68 retest authorizer now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(v_uid)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_plan_item_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_plan_id uuid, p_priority_order integer';
  if v_oid is null then raise exception 'P2-68 plan authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>6 then raise exception 'P2-68 plan authorizer now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(v_uid)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='generate_exam_prep_weekly_plan_safe_v3'
    and pg_get_function_identity_arguments(p.oid)='p_component_code text';
  if v_oid is null then raise exception 'P2-68 weekly planner v3 missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>4 then raise exception 'P2-68 weekly planner now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(v_uid)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='public' and p.proname='authorize_exam_prep_correction_safe_v1'
    and pg_get_function_identity_arguments(p.oid)='p_correction_case_id uuid';
  if v_oid is null then raise exception 'P2-68 correction authorizer missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>2 then raise exception 'P2-68 correction authorizer now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(v_uid)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_reconcile_finalized_session_v1'
    and pg_get_function_identity_arguments(p.oid)='';
  if v_oid is null then raise exception 'P2-68 correction reconciler missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'now()','')))/5;
  if v_count<>8 then raise exception 'P2-68 reconciler now() anchor drift count=%',v_count; end if;
  execute replace(v_def,'now()','private.exam_prep_effective_academic_now_v1(new.user_id)');

  select p.oid into v_oid
  from pg_proc p join pg_namespace n on n.oid=p.pronamespace
  where n.nspname='private' and p.proname='exam_prep_log_correction_action_v1'
    and pg_get_function_identity_arguments(p.oid)=
      'p_case_id uuid, p_action_type text, p_session_id uuid, p_evidence_id uuid, p_retest_event_id uuid, p_payload jsonb';
  if v_oid is null then raise exception 'P2-68 correction action logger missing'; end if;
  v_def:=pg_get_functiondef(v_oid);
  v_count:=(length(v_def)-length(replace(v_def,'clock_timestamp()','')))/17;
  if v_count<>1 then raise exception 'P2-68 correction action clock anchor drift count=%',v_count; end if;
  execute replace(v_def,'clock_timestamp()','private.exam_prep_effective_academic_now_v1(v_case.user_id)');
end
$$;

-- Re-assert browser boundary after CREATE OR REPLACE operations.
revoke all on function private.exam_prep_effective_active_week_v1(uuid) from public,anon,authenticated;
grant execute on function private.exam_prep_effective_active_week_v1(uuid) to service_role;
revoke all on function private.rebuild_exam_prep_state_v1(uuid,text) from public,anon,authenticated;
grant execute on function private.rebuild_exam_prep_state_v1(uuid,text) to service_role;
revoke execute on function public.authorize_exam_prep_retest_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_retest_safe_v1(uuid) to authenticated,service_role;
revoke execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) from public,anon;
grant execute on function public.authorize_exam_prep_plan_item_safe_v1(uuid,integer) to authenticated,service_role;
revoke execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) from public,anon;
grant execute on function public.generate_exam_prep_weekly_plan_safe_v3(text) to authenticated,service_role;
revoke execute on function public.authorize_exam_prep_correction_safe_v1(uuid) from public,anon;
grant execute on function public.authorize_exam_prep_correction_safe_v1(uuid) to authenticated,service_role;
revoke all on function private.exam_prep_reconcile_finalized_session_v1() from public,anon,authenticated;
revoke all on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb)
  from public,anon,authenticated;
grant execute on function private.exam_prep_log_correction_action_v1(uuid,text,uuid,uuid,uuid,jsonb)
  to service_role;

-- Structural acceptance: no browser can see/mutate the engineering clock.
do $$
begin
  if has_table_privilege('anon','private.exam_prep_synthetic_run_clocks','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_synthetic_run_clocks','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_synthetic_timeline_events','SELECT')
     or has_function_privilege('anon','private.initialize_exam_prep_synthetic_clock_v1(text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.initialize_exam_prep_synthetic_clock_v1(text,text)','EXECUTE')
     or has_function_privilege('authenticated','private.advance_exam_prep_synthetic_clock_v1(text,timestamptz,bigint,text)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_effective_academic_now_v1(uuid)','EXECUTE') then
    raise exception 'exam_prep_p2_68_browser_virtual_clock_exposed';
  end if;
end
$$;

commit;
