-- STAGED RELEASE CANDIDATE ONLY. NOT a Supabase migration; do not apply in production.
-- Contains schema and RPC definitions ONLY. NO protected MCQ items, keys, user data.
-- Prerequisites: isolated Postgres/Supabase auth E2E, verified selective backup and rollback.
-- Economics 9708 P1/P3 first unseen same-skill retest. Independent of historic exam grades.

begin;

create table private.iclub_econ_retest_control_v1 (
  id smallint primary key default 1 check (id=1),
  issuance_enabled boolean not null default false,
  updated_at timestamptz not null default now()
);
insert into private.iclub_econ_retest_control_v1(id,issuance_enabled)
values (1,false);

create table private.iclub_econ_retest_sources_v1 (
  item_key text not null,
  content_version text not null,
  program_key text not null default 'economics_9708'
    check (program_key='economics_9708'),
  version_key text not null default 'economics_2026_2028_v1'
    check (version_key='economics_2026_2028_v1'),
  paper_code text not null check (paper_code in ('P1','P3')),
  skill_key text not null,
  source_sha256 text not null check (source_sha256 ~ '^[a-f0-9]{64}$'),
  locales jsonb not null check (jsonb_typeof(locales)='object'),
  answer_key text not null check (answer_key in ('A','B','C','D')),
  academic_status text not null default 'hold'
    check (academic_status in ('hold','approved','retired')),
  language_status text not null default 'hold'
    check (language_status in ('hold','pass')),
  semantic_distinct_status text not null default 'hold'
    check (semantic_distinct_status in ('hold','pass')),
  release_enabled boolean not null default false,
  created_at timestamptz not null default now(),
  primary key(item_key,content_version),
  unique(program_key,version_key,paper_code,skill_key,content_version),
  check (not release_enabled or
     (academic_status='approved' and language_status='pass'
      and semantic_distinct_status='pass')),
  foreign key(program_key,version_key,skill_key)
    references private.iclub_exam_core_skills_v1(program_key,version_key,skill_key)
);
create index iclub_econ_retest_sources_skill_v1
  on private.iclub_econ_retest_sources_v1(paper_code,skill_key)
  where release_enabled;

create table private.iclub_econ_retest_sessions_v1 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  source_session_id uuid not null
    references private.iclub_exam_native_mcq_attempts_v1(id),
  source_item_order integer not null check(source_item_order between 1 and 30),
  paper_code text not null check(paper_code in ('P1','P3')),
  skill_key text not null,
  item_key text not null,
  content_version text not null,
  request_key text not null check(length(request_key) between 12 and 128),
  status text not null default 'active'
    check(status in ('active','finalized')),
  selected_index integer check(selected_index between 0 and 3),
  is_correct boolean,
  submit_key text,
  issued_at timestamptz not null default clock_timestamp(),
  deadline_at timestamptz not null,
  finalized_at timestamptz,
  foreign key(item_key,content_version)
    references private.iclub_econ_retest_sources_v1(item_key,content_version),
  unique(user_id,request_key),
  unique(user_id,source_session_id,source_item_order),
  unique(user_id,item_key),
  check ((status='active' and selected_index is null
       and is_correct is null and finalized_at is null and submit_key is null)
    or (status='finalized' and selected_index is not null
       and is_correct is not null and finalized_at is not null and submit_key is not null))
);
create index iclub_econ_retest_sessions_owner_v1
  on private.iclub_econ_retest_sessions_v1(user_id,source_session_id);

alter table private.iclub_econ_retest_control_v1 enable row level security;
alter table private.iclub_econ_retest_sources_v1 enable row level security;
alter table private.iclub_econ_retest_sessions_v1 enable row level security;
revoke all on private.iclub_econ_retest_control_v1 from public,anon,authenticated;
revoke all on private.iclub_econ_retest_sources_v1 from public,anon,authenticated;
revoke all on private.iclub_econ_retest_sessions_v1 from public,anon,authenticated;
-- No client-facing policies: all access is through owner-checked RPC only.

-- Do not allow in-place modifications of issued original question content.
create function private.iclub_econ_retest_protect_issued_source_v1()
returns trigger language plpgsql set search_path='' as $$
begin
  if exists (
    select 1 from private.iclub_econ_retest_sessions_v1 s
    where s.item_key=old.item_key and s.content_version=old.content_version
  ) then
    if tg_op='DELETE' then
      raise exception 'issued_source_is_immutable';
    end if;
    if (new.item_key,new.content_version,new.program_key,new.version_key,
        new.paper_code,new.skill_key,new.source_sha256,new.locales,new.answer_key)
       is distinct from
       (old.item_key,old.content_version,old.program_key,old.version_key,
        old.paper_code,old.skill_key,old.source_sha256,old.locales,old.answer_key)
    then raise exception 'issued_source_content_is_immutable'; end if;
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end; $$;
create trigger iclub_econ_retest_protect_issued_source_v1
before update or delete on private.iclub_econ_retest_sources_v1
for each row execute function private.iclub_econ_retest_protect_issued_source_v1();

-- Strictly authorize verified, still-existing, non-anonymous Supabase sessions.
create function private.iclub_econ_retest_current_user_v1()
returns uuid language plpgsql stable security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_sid uuid;
  v_claims jsonb:=auth.jwt(); v_exp text;
begin
  if v_user is null or v_claims is null
     or coalesce(v_claims->>'is_anonymous','false')='true'
     or (select is_anonymous from auth.users where id=v_user) is distinct from false
  then return null; end if;
  v_exp:=v_claims->>'exp';
  if v_exp is null or v_exp !~ '^[0-9]+$'
     or to_timestamp(v_exp::bigint)<=clock_timestamp()
  then return null; end if;
  if coalesce(v_claims->>'session_id','') !~
        '^[0-9a-fA-F-]{36}$' then return null; end if;
  v_sid:=(v_claims->>'session_id')::uuid;
  if not exists (
    select 1 from auth.sessions s
    where s.id=v_sid and s.user_id=v_user
      and (s.not_after is null or s.not_after>clock_timestamp())
  ) then return null; end if;
  return v_user;
exception when others then return null;
end; $$;

-- New issuance must originate from an owned FINALIZED incorrect source item.
create function public.iclub_econ_retest_start_v1(
  p_source_session_id uuid, p_source_item_order integer, p_request_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.iclub_econ_retest_current_user_v1();
  v_exam private.iclub_exam_native_mcq_attempts_v1%rowtype;
  v_old_item jsonb; v_old_choice integer; v_old_key integer;
  v_skill text; v_prior private.iclub_econ_retest_sessions_v1%rowtype;
  v_source private.iclub_econ_retest_sources_v1%rowtype; v_new_id uuid;
begin
  if v_user is null then return jsonb_build_object('ok',false,'code','not_authorized'); end if;
  if p_source_session_id is null or p_source_item_order not between 1 and 30
    or length(coalesce(p_request_key,'')) not between 12 and 128
  then return jsonb_build_object('ok',false,'code','invalid_request'); end if;
  -- Serialise every user's simultaneous starts, not just identical request keys.
  perform pg_advisory_xact_lock(hashtextextended('econ-retest:'||v_user::text,0));
  if not coalesce((select issuance_enabled
       from private.iclub_econ_retest_control_v1 where id=1),false)
  then return jsonb_build_object('ok',false,'code','not_available'); end if;
  if not private.iclub_exam_native_mcq_enrolled_v1(v_user)
     or not private.iclub_exam_native_economics_beta_allowed_v1(v_user)
  then return jsonb_build_object('ok',false,'code','beta_not_authorized'); end if;
  select * into v_exam from private.iclub_exam_native_mcq_attempts_v1
  where id=p_source_session_id and user_id=v_user
    and program_key='economics_9708'
    and version_key='economics_2026_2028_v1'
    and paper_code in ('P1','P3')
    and status='finalized' and finalized_at is not null;
  if not found then return jsonb_build_object('ok',false,'code','source_not_found'); end if;
  if p_source_item_order>jsonb_array_length(v_exam.items)
  then return jsonb_build_object('ok',false,'code','invalid_request'); end if;
  v_old_item:=v_exam.items->(p_source_item_order-1);
  v_skill:=v_old_item->>'skill_key';
  if v_skill is null or length(v_skill)<3 then
    return jsonb_build_object('ok',false,'code','no_skill_mapping'); end if;
  if coalesce(v_old_item->>'key','') !~ '^[A-D]$'
    or jsonb_typeof(v_old_item->'display_order') is distinct from 'array'
    or jsonb_array_length(v_old_item->'display_order')<>4
  then return jsonb_build_object('ok',false,'code','invalid_source_evidence'); end if;
  v_old_choice:=(v_exam.responses->p_source_item_order::text->>'choice')::integer;
  v_old_key:=ascii(v_old_item->>'key')-65;
  if v_old_choice is null or v_old_choice not between 0 and 3
  then return jsonb_build_object('ok',false,'code','no_recorded_wrong_answer'); end if;
  if (v_old_item->'display_order'->>v_old_choice)::integer=v_old_key
  then return jsonb_build_object('ok',false,'code','not_an_error'); end if;
  -- Stable idempotency key: retry returns the SAME session after authorization.
  select * into v_prior from private.iclub_econ_retest_sessions_v1
   where user_id=v_user and request_key=p_request_key;
  if found then
    if v_prior.source_session_id<>p_source_session_id
       or v_prior.source_item_order<>p_source_item_order
    then return jsonb_build_object('ok',false,'code','request_key_reused'); end if;
    return jsonb_build_object('ok',true,'session_id',v_prior.id,
     'status',v_prior.status,'resumed',true); end if;
  -- Every specific wrong answer can be independently retested only once
  -- in v1, regardless of completed/expired status or request-key rotation.
  select * into v_prior from private.iclub_econ_retest_sessions_v1
   where user_id=v_user and source_session_id=p_source_session_id
     and source_item_order=p_source_item_order
   order by issued_at desc limit 1;
  if found then
    if v_prior.status='active' then
      if v_prior.deadline_at<=clock_timestamp() then
        return jsonb_build_object('ok',false,'code','prior_retest_expired');
      end if;
      return jsonb_build_object('ok',true,'session_id',v_prior.id,
        'status','active','resumed',true);
    end if;
    return jsonb_build_object('ok',false,'code','already_retested');
  end if;

  select r.* into v_source
  from private.iclub_econ_retest_sources_v1 r
  join private.iclub_exam_core_skills_v1 sk
    on sk.program_key=r.program_key and sk.version_key=r.version_key
     and sk.skill_key=r.skill_key
  join private.iclub_exam_core_paper_skills_v1 ps
    on ps.program_key=r.program_key and ps.version_key=r.version_key
     and ps.paper_code=r.paper_code and ps.skill_key=r.skill_key
  where r.program_key='economics_9708'
    and r.version_key='economics_2026_2028_v1'
    and r.paper_code=v_exam.paper_code and r.skill_key=v_skill
    and r.release_enabled and r.academic_status='approved'
    and r.language_status='pass' and r.semantic_distinct_status='pass'
    and sk.status='reviewed' and ps.status='approved' and ps.link_role='direct'
    and sk.level_code=case when v_exam.paper_code='P1' then 'AS' else 'A' end
    -- Exclude all previously issued original items, even if unanswered.
    and not exists (
      select 1 from private.iclub_econ_retest_sessions_v1 seen
      where seen.user_id=v_user
        and seen.item_key=r.item_key
    )
    -- Defence-in-depth for future native exams containing original item_keys.
    and not exists (
      select 1 from private.iclub_exam_native_mcq_attempts_v1 past
      cross join lateral jsonb_array_elements(past.items) shown
      where past.user_id=v_user
        and shown->>'item_key'=r.item_key
    )
  order by r.created_at,r.item_key,r.content_version limit 1;
  if not found then
    return jsonb_build_object('ok',false,'code','no_unseen_approved_item'); end if;
  if not (
     jsonb_typeof(v_source.locales->'en'->'options')='array'
     and jsonb_typeof(v_source.locales->'ru'->'options')='array'
     and jsonb_typeof(v_source.locales->'uz'->'options')='array'
     and jsonb_array_length(v_source.locales->'en'->'options')=4
     and jsonb_array_length(v_source.locales->'ru'->'options')=4
     and jsonb_array_length(v_source.locales->'uz'->'options')=4
     and length(coalesce(v_source.locales->'en'->>'question',''))>10
     and length(coalesce(v_source.locales->'ru'->>'question',''))>10
     and length(coalesce(v_source.locales->'uz'->>'question',''))>10
  ) then return jsonb_build_object('ok',false,'code','invalid_source'); end if;
  insert into private.iclub_econ_retest_sessions_v1
    (user_id,source_session_id,source_item_order,paper_code,skill_key,
     item_key,content_version,request_key,deadline_at)
  values (v_user,p_source_session_id,p_source_item_order,v_exam.paper_code,v_skill,
    v_source.item_key,v_source.content_version,p_request_key,
    clock_timestamp()+interval '10 minutes') returning id into v_new_id;
  return jsonb_build_object('ok',true,'session_id',v_new_id,
    'status','active','resumed',false);
exception when unique_violation then
  return jsonb_build_object('ok',false,'code','concurrent_retry');
end; $$;

-- Only owner can read; active question never includes answer_key or explanation.
create function public.iclub_econ_retest_get_v1(p_session_id uuid,p_language text default 'en')
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_user uuid:=private.iclub_econ_retest_current_user_v1();
  v_s private.iclub_econ_retest_sessions_v1%rowtype;
  v_q private.iclub_econ_retest_sources_v1%rowtype; v_l jsonb;
begin
  if v_user is null then return jsonb_build_object('ok',false,'code','not_authorized'); end if;
  if p_language not in ('en','ru','uz') or p_session_id is null then
    return jsonb_build_object('ok',false,'code','invalid_request'); end if;
  select * into v_s from private.iclub_econ_retest_sessions_v1
   where id=p_session_id and user_id=v_user;
  if not found then return jsonb_build_object('ok',false,'code','not_found'); end if;
  if v_s.status='active' and clock_timestamp()>v_s.deadline_at then
    return jsonb_build_object('ok',false,'code','expired'); end if;
  select * into v_q from private.iclub_econ_retest_sources_v1
   where item_key=v_s.item_key and content_version=v_s.content_version;
  v_l:=v_q.locales->p_language;
  return jsonb_build_object('ok',true,'session_id',v_s.id,
    'status',v_s.status,'paper_code',v_s.paper_code,'skill_key',v_s.skill_key,
    'started_at',v_s.issued_at,'deadline_at',v_s.deadline_at,
    'question',v_l->>'question','options',v_l->'options',
    'selected_index',case when v_s.status='finalized' then v_s.selected_index else null end,
    'is_correct',case when v_s.status='finalized' then v_s.is_correct else null end,
    'correct_index',case when v_s.status='finalized' then ascii(v_q.answer_key)-65 else null end,
    'explanation',case when v_s.status='finalized' then v_l->>'explanation' else null end);
end; $$;

-- Resume an already-issued unexpired attempt using server-owned state only.
-- No new question is created. Works across client reloads and after issuance OFF.
create function public.iclub_econ_retest_resume_v1(p_source_session_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_user uuid:=private.iclub_econ_retest_current_user_v1();
  v_s private.iclub_econ_retest_sessions_v1%rowtype;
begin
  if v_user is null then return jsonb_build_object('ok',false,'code','not_authorized'); end if;
  select * into v_s
  from private.iclub_econ_retest_sessions_v1
  where user_id=v_user and status='active' and deadline_at>clock_timestamp()
    and (p_source_session_id is null or source_session_id=p_source_session_id)
  order by issued_at desc limit 1;
  if not found then return jsonb_build_object('ok',false,'code','no_active_attempt'); end if;
  return jsonb_build_object('ok',true,'session_id',v_s.id,'status','active',
    'source_session_id',v_s.source_session_id,'resumed',true);
end; $$;

-- One immutable server-scored answer. Concurrent calls lock the SAME session.
create function public.iclub_econ_retest_submit_v1(
 p_session_id uuid,p_selected_index integer,p_submit_key text)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_user uuid:=private.iclub_econ_retest_current_user_v1();
  v_s private.iclub_econ_retest_sessions_v1%rowtype;
  v_key text; v_correct boolean;
begin
  if v_user is null then return jsonb_build_object('ok',false,'code','not_authorized'); end if;
  if p_session_id is null or p_selected_index not between 0 and 3
    or length(coalesce(p_submit_key,'')) not between 12 and 128
  then return jsonb_build_object('ok',false,'code','invalid_request'); end if;
  select * into v_s from private.iclub_econ_retest_sessions_v1
   where id=p_session_id and user_id=v_user for update;
  if not found then return jsonb_build_object('ok',false,'code','not_found'); end if;
  if v_s.status='finalized' then
    if v_s.submit_key=p_submit_key and v_s.selected_index=p_selected_index then
      return jsonb_build_object('ok',true,'status','finalized',
        'is_correct',v_s.is_correct,'duplicate',true); end if;
    return jsonb_build_object('ok',false,'code','already_finalized');
  end if;
  if clock_timestamp()>v_s.deadline_at then
    return jsonb_build_object('ok',false,'code','expired'); end if;
  -- Kill switch stops NEW issuance; an already-issued answer may finish.
  select answer_key into v_key from private.iclub_econ_retest_sources_v1
   where item_key=v_s.item_key and content_version=v_s.content_version;
  if v_key is null then return jsonb_build_object('ok',false,'code','source_not_found'); end if;
  v_correct:=(p_selected_index=ascii(v_key)-65);
  update private.iclub_econ_retest_sessions_v1
    set status='finalized',selected_index=p_selected_index,
      is_correct=v_correct,submit_key=p_submit_key,finalized_at=clock_timestamp()
    where id=v_s.id and status='active';
  return jsonb_build_object('ok',true,'status','finalized',
    'is_correct',v_correct,'duplicate',false);
end; $$;

-- Prevent exposure via the DEFAULT PUBLIC function EXECUTE grant.
revoke all on function private.iclub_econ_retest_protect_issued_source_v1() from public,anon,authenticated;
revoke all on function private.iclub_econ_retest_current_user_v1() from public,anon,authenticated;
revoke all on function public.iclub_econ_retest_start_v1(uuid,integer,text) from public,anon,authenticated;
revoke all on function public.iclub_econ_retest_get_v1(uuid,text) from public,anon,authenticated;
revoke all on function public.iclub_econ_retest_resume_v1(uuid) from public,anon,authenticated;
revoke all on function public.iclub_econ_retest_submit_v1(uuid,integer,text) from public,anon,authenticated;
grant execute on function public.iclub_econ_retest_start_v1(uuid,integer,text) to authenticated;
grant execute on function public.iclub_econ_retest_get_v1(uuid,text) to authenticated;
grant execute on function public.iclub_econ_retest_resume_v1(uuid) to authenticated;
grant execute on function public.iclub_econ_retest_submit_v1(uuid,integer,text) to authenticated;
-- Defined in private schema; SECURITY DEFINER public RPC can call this helper.
-- Keep private schema out of Supabase exposed API schemas.

commit;

-- PAUSE: no source data imported, no approved flags and issuance_enabled=false.
-- Emergency stop: update private.iclub_econ_retest_control_v1
--   set issuance_enabled=false,updated_at=clock_timestamp() where id=1;
-- Recovery: revert NEW FUNCTION GRANTS/deployment; preserve all retest sessions.
-- Do not DROP these tables if they contain student results.
