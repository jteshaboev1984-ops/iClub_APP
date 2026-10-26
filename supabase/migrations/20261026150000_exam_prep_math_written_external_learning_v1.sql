-- iClub Mathematics P1/P5 written learning: additive, OFF by default.
-- Source contract: iClub_Exam_Prep_Math_P1_P5_Written_Contract_v1.0_FOR_APPROVAL.
-- DO NOT execute against production until authorized. No existing learner rows updated here.
-- Legacy safe RPC signatures are preserved; all new operations carry _written_v1/_v1 suffixes.

begin;

create table if not exists private.exam_prep_written_learning_config_v1 (
  component_code text primary key check (component_code in ('P1','P5')),
  enabled boolean not null default false
);
create table if not exists private.exam_prep_written_learning_allowlist_v1 (
  user_id uuid not null,
  component_code text not null check (component_code in ('P1','P5')),
  primary key (user_id, component_code)
);
create table if not exists private.exam_prep_written_step_advances_v1 (
  session_id uuid not null,
  item_order smallint not null check (item_order>0),
  user_id uuid not null,
  component_code text not null check (component_code in ('P1','P5')),
  written_task_id bigint not null references private.exam_prep_written_tasks(id) on delete restrict,
  item_version text not null,
  client_idempotency_key text not null check (char_length(client_idempotency_key) between 8 and 160),
  advanced_at timestamptz not null default now(),
  primary key(session_id,item_order),
  unique(session_id,client_idempotency_key),
  foreign key(session_id,item_order)
    references private.exam_prep_session_items(session_id,item_order) on delete restrict
);
create index if not exists exam_prep_written_step_advances_user_v1
  on private.exam_prep_written_step_advances_v1(user_id,component_code,advanced_at desc);
alter table private.exam_prep_written_learning_config_v1 enable row level security;
alter table private.exam_prep_written_learning_allowlist_v1 enable row level security;
alter table private.exam_prep_written_step_advances_v1 enable row level security;
revoke all on private.exam_prep_written_learning_config_v1 from public,anon,authenticated;
revoke all on private.exam_prep_written_learning_allowlist_v1 from public,anon,authenticated;
revoke all on private.exam_prep_written_step_advances_v1 from public,anon,authenticated;

-- A previously advanced session stays resumable after an emergency rollout OFF.
create or replace function private.exam_prep_written_learning_can_use_v1(p_uid uuid,p_session_id uuid)
returns boolean language sql stable security definer set search_path='' as $fn$
  select exists(
    select 1 from private.exam_prep_sessions s
    where s.id=p_session_id and s.user_id=p_uid and s.session_type='learning'
      and s.component_code in ('P1','P5')
      and (
        exists(
          select 1
          from private.exam_prep_written_learning_config_v1 cfg
          join private.exam_prep_written_learning_allowlist_v1 al
            on al.component_code=cfg.component_code and al.user_id=p_uid
          where cfg.component_code=s.component_code and cfg.enabled=true
        )
        or exists(
          select 1 from private.exam_prep_written_step_advances_v1 a
          where a.session_id=s.id and a.user_id=p_uid
        )
      )
  );
$fn$;
revoke all on function private.exam_prep_written_learning_can_use_v1(uuid,uuid)
  from public,anon,authenticated;

-- A legacy submit racing with the new advancement must fail, not double-credit.
create or replace function private.exam_prep_written_step_legacy_insert_guard_v1()
returns trigger language plpgsql security definer set search_path='' as $fn$
begin
  if new.response_kind='written' then
    -- Serialize the legacy written INSERT with the new written Next RPC.
    -- Both take the SAME session row lock; therefore exactly one outcome wins,
    -- even across two browser tabs or simultaneous old/new clients.
    perform 1 from private.exam_prep_sessions s
      where s.id=new.session_id
        and s.session_type='learning'
        and s.component_code in ('P1','P5')
      for update;
    if found and exists (
      select 1 from private.exam_prep_written_step_advances_v1 a
      where a.session_id=new.session_id and a.item_order=new.item_order
    ) then
      raise exception 'exam_prep_written_already_advanced';
    end if;
  end if;
  return new;
end $fn$;
revoke all on function private.exam_prep_written_step_legacy_insert_guard_v1()
  from public,anon,authenticated;
drop trigger if exists exam_prep_written_step_legacy_insert_guard_v1 on private.exam_prep_responses;
create trigger exam_prep_written_step_legacy_insert_guard_v1
  before insert on private.exam_prep_responses for each row
  execute function private.exam_prep_written_step_legacy_insert_guard_v1();

-- Existing read path remains unchanged. Extra fields never reinterpret answered.
create or replace function public.get_exam_prep_session_written_v1(
  p_session_id uuid,p_language text default 'en'
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_base jsonb;
  v_items jsonb;
  v_mode boolean;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  v_base:=public.get_exam_prep_session_safe_v1(p_session_id,p_language);
  v_mode:=private.exam_prep_written_learning_can_use_v1(v_uid,p_session_id);
  select coalesce(jsonb_agg(
    e.value || jsonb_build_object(
      'completion_status',case
        when coalesce((e.value->>'answered')::boolean,false) then 'answered'
        when a.session_id is not null then 'advanced_in_plan_only'
        else 'open' end,
      'is_complete',coalesce((e.value->>'answered')::boolean,false) or a.session_id is not null,
      'written_external',v_mode and v_s.session_type='learning'
        and e.value->>'item_kind'='written'
    ) order by e.ordinality
  ),'[]'::jsonb) into v_items
  from jsonb_array_elements(coalesce(v_base->'items','[]'::jsonb)) with ordinality e(value,ordinality)
  left join private.exam_prep_written_step_advances_v1 a
    on a.session_id=p_session_id and a.item_order=(e.value->>'item_order')::smallint
       and a.user_id=v_uid;
  return v_base || jsonb_build_object('items',v_items,'written_external_contract','math_written_external_learning_v1');
end $fn$;
revoke all on function public.get_exam_prep_session_written_v1(uuid,text) from public,anon;
grant execute on function public.get_exam_prep_session_written_v1(uuid,text) to authenticated,service_role;

-- Criteria only for the authenticated learner's active, learning, written item.
-- Return localized REQUIREMENTS only: no grades, answer key, raw rubric or model solution.
create or replace function public.get_exam_prep_written_criteria_safe_v1(
  p_session_id uuid,p_item_order integer,p_language text default 'en'
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_rubric jsonb;
  v_requirements jsonb;
  v_lang text:=lower(coalesce(p_language,'en'));
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if v_lang not in ('ru','uz','en') then raise exception 'exam_prep_bad_language'; end if;
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type<>'learning' or v_s.status<>'active'
     or not private.exam_prep_written_learning_can_use_v1(v_uid,p_session_id)
  then raise exception 'exam_prep_written_criteria_unavailable' using errcode='42501'; end if;
  select * into v_i from private.exam_prep_session_items
    where session_id=v_s.id and item_order=p_item_order and item_kind='written';
  if v_i.item_order is null then raise exception 'exam_prep_written_item_not_found' using errcode='P0002'; end if;
  -- Criteria belong to the current unfinished step only; do not expose future rubrics.
  if exists(
    select 1 from private.exam_prep_session_items si
    where si.session_id=p_session_id and si.item_order<p_item_order
      and not exists(select 1 from private.exam_prep_responses r
        where r.session_id=p_session_id and r.item_order=si.item_order)
      and not exists(select 1 from private.exam_prep_written_step_advances_v1 a
        where a.session_id=p_session_id and a.item_order=si.item_order)
  ) or exists(
    select 1 from private.exam_prep_responses r
    where r.session_id=p_session_id and r.item_order=p_item_order
  ) or exists(
    select 1 from private.exam_prep_written_step_advances_v1 a
    where a.session_id=p_session_id and a.item_order=p_item_order
  ) then raise exception 'exam_prep_written_criteria_not_current' using errcode='42501'; end if;
  select private.exam_prep_localized_written_rubric_v1(wt.rubric_json,v_lang)
    into v_rubric
  from private.exam_prep_written_tasks wt
  where wt.id=v_i.written_task_id
    and wt.component_code=v_s.component_code
    and v_i.item_version='written:'||wt.task_version
    and wt.lifecycle_state='published'
    and wt.qa_math_status='pass' and wt.qa_language_status='pass' and wt.qa_technical_status='pass';
  if v_rubric is null or v_rubric->>'localization_status'='unavailable' then
    return jsonb_build_object('available',false,'item_order',p_item_order);
  end if;
  select coalesce(jsonb_agg(btrim(c.value->>'rule') order by c.ordinality),'[]'::jsonb)
    into v_requirements
  from jsonb_array_elements(coalesce(v_rubric->'criteria','[]'::jsonb))
    with ordinality c(value,ordinality)
  where nullif(btrim(coalesce(c.value->>'rule','')),'') is not null;
  return jsonb_build_object('available',jsonb_array_length(v_requirements)>0,
    'item_order',p_item_order,'requirements',v_requirements);
end $fn$;
revoke all on function public.get_exam_prep_written_criteria_safe_v1(uuid,integer,text)
  from public,anon;
grant execute on function public.get_exam_prep_written_criteria_safe_v1(uuid,integer,text)
  to authenticated,service_role;

create or replace function public.get_exam_prep_written_step_status_safe_v1(
  p_session_id uuid,p_item_order integer
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_item private.exam_prep_session_items%rowtype;
  v_status text;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type<>'learning' then raise exception 'exam_prep_written_bad_session'; end if;
  select * into v_item from private.exam_prep_session_items
    where session_id=p_session_id and item_order=p_item_order and item_kind='written';
  if v_item.item_order is null then raise exception 'exam_prep_written_item_not_found' using errcode='P0002'; end if;
  v_status:='open';
  if exists(select 1 from private.exam_prep_responses r
      where r.session_id=p_session_id and r.item_order=p_item_order) then
    v_status:='answered_legacy';
  elsif exists(select 1 from private.exam_prep_written_step_advances_v1 a
      where a.session_id=p_session_id and a.item_order=p_item_order and a.user_id=v_uid) then
    v_status:='advanced';
  end if;
  return jsonb_build_object('session_id',p_session_id,'item_order',p_item_order,
    'status',v_status,'session_status',v_s.status,'component_code',v_s.component_code,
    'can_advance',v_s.status='active'
      and private.exam_prep_written_learning_can_use_v1(v_uid,p_session_id));
end $fn$;
revoke all on function public.get_exam_prep_written_step_status_safe_v1(uuid,integer)
  from public,anon;
grant execute on function public.get_exam_prep_written_step_status_safe_v1(uuid,integer)
  to authenticated,service_role;

create or replace function public.advance_exam_prep_written_step_safe_v1(
  p_session_id uuid,p_item_order integer,p_idempotency_key text
) returns jsonb language plpgsql security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_i private.exam_prep_session_items%rowtype;
  v_a private.exam_prep_written_step_advances_v1%rowtype;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160
    then raise exception 'exam_prep_bad_idempotency_key'; end if;
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type<>'learning' or v_s.component_code not in ('P1','P5')
    then raise exception 'exam_prep_written_bad_session'; end if;
  select * into v_a from private.exam_prep_written_step_advances_v1
    where session_id=p_session_id and client_idempotency_key=p_idempotency_key;
  if v_a.session_id is not null then
    if v_a.item_order<>p_item_order then raise exception 'exam_prep_written_key_conflict'; end if;
    return jsonb_build_object('session_id',p_session_id,'item_order',p_item_order,
      'status','advanced','replayed',true);
  end if;
  select * into v_i from private.exam_prep_session_items
    where session_id=p_session_id and item_order=p_item_order and item_kind='written';
  if v_i.item_order is null then raise exception 'exam_prep_written_item_not_found' using errcode='P0002'; end if;
  if exists(select 1 from private.exam_prep_written_step_advances_v1
      where session_id=p_session_id and item_order=p_item_order) then
    return jsonb_build_object('session_id',p_session_id,'item_order',p_item_order,
      'status','advanced','replayed',true);
  end if;
  if exists(select 1 from private.exam_prep_responses
      where session_id=p_session_id and item_order=p_item_order) then
    return jsonb_build_object('session_id',p_session_id,'item_order',p_item_order,
      'status','answered_legacy','replayed',true);
  end if;
  if v_s.status<>'active' or not private.exam_prep_written_learning_can_use_v1(v_uid,p_session_id)
    then raise exception 'exam_prep_written_not_authorized' using errcode='42501'; end if;
  -- Enforce exact next uncompleted question, including machine responses.
  if exists(
    select 1 from private.exam_prep_session_items earlier
    where earlier.session_id=p_session_id and earlier.item_order<p_item_order
      and not exists(select 1 from private.exam_prep_responses r
        where r.session_id=p_session_id and r.item_order=earlier.item_order)
      and not exists(select 1 from private.exam_prep_written_step_advances_v1 a
        where a.session_id=p_session_id and a.item_order=earlier.item_order)
  ) then raise exception 'exam_prep_written_step_out_of_order'; end if;
  insert into private.exam_prep_written_step_advances_v1(
    session_id,item_order,user_id,component_code,written_task_id,item_version,client_idempotency_key
  ) values(
    p_session_id,v_i.item_order,v_uid,v_s.component_code,v_i.written_task_id,
    v_i.item_version,p_idempotency_key
  );
  update private.exam_prep_sessions set last_activity_at=now() where id=p_session_id;
  return jsonb_build_object('session_id',p_session_id,'item_order',p_item_order,
    'status','advanced','replayed',false);
end $fn$;
revoke all on function public.advance_exam_prep_written_step_safe_v1(uuid,integer,text)
  from public,anon;
grant execute on function public.advance_exam_prep_written_step_safe_v1(uuid,integer,text)
  to authenticated,service_role;

-- All response rows retain their original meaning and old finalize RPC is untouched.
create or replace function public.finalize_exam_prep_session_written_v1(
  p_session_id uuid,p_idempotency_key text
) returns jsonb language plpgsql security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_response_count integer;
  v_advance_count integer;
  v_machine_count integer;
  v_machine_correct integer;
  v_written_saved integer;
  v_invalid integer;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_idempotency_key is null or char_length(p_idempotency_key) not between 8 and 160
    then raise exception 'exam_prep_bad_idempotency_key'; end if;
  select * into v_s from private.exam_prep_sessions
    where id=p_session_id and user_id=v_uid for update;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  if v_s.session_type in ('timed','paper') then raise exception 'exam_prep_timed_requires_special_finalizer'; end if;
  if v_s.status='abandoned' then raise exception 'exam_prep_session_abandoned'; end if;
  if not exists(select 1 from private.exam_prep_written_step_advances_v1
    where session_id=p_session_id) then
    return public.finalize_exam_prep_session_safe_v1(p_session_id,p_idempotency_key);
  end if;
  if v_s.session_type<>'learning' then raise exception 'exam_prep_written_bad_session'; end if;
  select count(*),count(*) filter(where response_kind='machine'),
         count(*) filter(where response_kind='machine' and is_correct),
         count(*) filter(where response_kind='written')
  into v_response_count,v_machine_count,v_machine_correct,v_written_saved
  from private.exam_prep_responses where session_id=p_session_id;
  select count(*) into v_advance_count
  from private.exam_prep_written_step_advances_v1 where session_id=p_session_id;
  select count(*) into v_invalid from private.exam_prep_written_step_advances_v1 a
  left join private.exam_prep_session_items si on si.session_id=a.session_id and si.item_order=a.item_order
  left join private.exam_prep_responses r on r.session_id=a.session_id and r.item_order=a.item_order
  where a.session_id=p_session_id and (si.item_kind is distinct from 'written' or r.id is not null);
  if v_invalid<>0 or v_response_count+v_advance_count<>v_s.total_items
    then raise exception 'exam_prep_session_incomplete'; end if;
  if v_s.status='finalized' then
    return jsonb_build_object('session_id',p_session_id,'status','finalized','replayed',true,
      'answered',v_response_count,'written_advanced',v_advance_count,
      'total_items',v_s.total_items);
  end if;
  update private.exam_prep_sessions
    set status='finalized',finalized_at=now(),last_activity_at=now(),
        finalize_idempotency_key=p_idempotency_key
    where id=p_session_id;
  -- Existing AFTER UPDATE finalize trigger synchronizes the weekly plan.
  -- No mastery evidence is written by this function.
  return jsonb_build_object('session_id',p_session_id,'status','finalized','replayed',false,
    'answered',v_response_count,'machine_correct',v_machine_correct,
    'machine_total',v_machine_count,'written_submitted',v_written_saved,
    'written_advanced',v_advance_count,'total_items',v_s.total_items);
end $fn$;
revoke all on function public.finalize_exam_prep_session_written_v1(uuid,text) from public,anon;
grant execute on function public.finalize_exam_prep_session_written_v1(uuid,text)
  to authenticated,service_role;

create or replace function public.get_exam_prep_session_review_written_v1(
  p_session_id uuid,p_language text default 'en'
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_base jsonb;
  v_items jsonb;
  v_advanced integer;
  v_written_saved integer;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select * into v_s from private.exam_prep_sessions where id=p_session_id and user_id=v_uid;
  if v_s.id is null then raise exception 'exam_prep_session_not_found' using errcode='P0002'; end if;
  v_base:=public.get_exam_prep_session_review_safe_v1(p_session_id,p_language);
  select coalesce(jsonb_agg(
    case when a.session_id is not null then
      (e.value - 'written_self_review' - 'learner_artifact' - 'written_rubric' - 'understanding_check')
        || jsonb_build_object('completion_status','advanced_in_plan_only')
    else e.value || jsonb_build_object(
      'completion_status',case when e.value->>'item_kind'='written'
        then 'written_submitted_legacy' else 'answered' end)
    end order by e.ordinality
  ),'[]'::jsonb) into v_items
  from jsonb_array_elements(coalesce(v_base->'items','[]'::jsonb)) with ordinality e(value,ordinality)
  left join private.exam_prep_written_step_advances_v1 a
    on a.session_id=p_session_id and a.item_order=(e.value->>'item_order')::smallint
      and a.user_id=v_uid;
  select count(*) into v_advanced from private.exam_prep_written_step_advances_v1
    where session_id=p_session_id and user_id=v_uid;
  v_written_saved:=coalesce((v_base->'summary'->>'written_total')::integer,0);
  return v_base || jsonb_build_object('items',v_items,'summary',
    (v_base->'summary') || jsonb_build_object(
      'written_submitted',v_written_saved,'written_advanced',v_advanced,
      'written_total',v_written_saved+v_advanced,
      'written_completed',v_written_saved+v_advanced
    ));
end $fn$;
revoke all on function public.get_exam_prep_session_review_written_v1(uuid,text)
  from public,anon;
grant execute on function public.get_exam_prep_session_review_written_v1(uuid,text)
  to authenticated,service_role;

create or replace function public.get_exam_prep_recent_results_written_v1(
  p_component_code text,p_limit integer default 10
) returns jsonb language plpgsql stable security definer set search_path='' as $fn$
declare
  v_uid uuid;
  v_base jsonb;
  v_rows jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  v_base:=public.get_exam_prep_recent_results_safe_v1(p_component_code,p_limit);
  select coalesce(jsonb_agg(
    e.value || jsonb_build_object(
      'written_submitted',coalesce((e.value->>'written_total')::integer,0),
      'written_advanced',coalesce((
        select count(*)::integer
        from private.exam_prep_written_step_advances_v1 a
        where a.session_id=(e.value->>'session_id')::uuid and a.user_id=v_uid
      ),0),
      'written_total',coalesce((e.value->>'written_total')::integer,0) +
        coalesce((select count(*)::integer
          from private.exam_prep_written_step_advances_v1 a
          where a.session_id=(e.value->>'session_id')::uuid and a.user_id=v_uid),0),
      'written_completed',coalesce((e.value->>'written_total')::integer,0) +
        coalesce((select count(*)::integer
          from private.exam_prep_written_step_advances_v1 a
          where a.session_id=(e.value->>'session_id')::uuid and a.user_id=v_uid),0)
    ) order by e.ordinality
  ),'[]'::jsonb) into v_rows
  from jsonb_array_elements(coalesce(v_base->'results','[]'::jsonb)) with ordinality e(value,ordinality);
  return v_base || jsonb_build_object('results',v_rows);
end $fn$;
revoke all on function public.get_exam_prep_recent_results_written_v1(text,integer)
  from public,anon;
grant execute on function public.get_exam_prep_recent_results_written_v1(text,integer)
  to authenticated,service_role;

comment on table private.exam_prep_written_step_advances_v1 is
  'Navigation only: advancement is NOT a submitted solution, verified correctness, score, or mastery.';
-- All config flags remain false / no allowlisted learners at migration completion.

commit;
