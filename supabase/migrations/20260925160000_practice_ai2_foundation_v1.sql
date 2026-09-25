-- AI-2 Practice AI foundation v1.
-- Additive, default-OFF and non-authoritative.
-- No existing Practice/Tour attempt, answer, score, recommendation, rating or certificate row is modified.

begin;

create table if not exists private.practice_ai_policy (
  id smallint primary key default 1 check (id=1),
  rollout_state text not null default 'off' check (rollout_state in ('off','shadow','controlled_beta','general')),
  enabled boolean not null default false,
  generation_enabled boolean not null default false,
  kill_switch boolean not null default false,
  allowed_interactions text[] not null default array['post_answer_explanation','practice_result_summary']::text[],
  allowed_locales text[] not null default array['ru','uz','en']::text[],
  max_user_text_chars integer not null default 0 check (max_user_text_chars between 0 and 2000),
  max_output_chars integer not null default 1200 check (max_output_chars between 200 and 5000),
  max_daily_requests integer not null default 20 check (max_daily_requests between 1 and 200),
  model_timeout_ms integer not null default 12000 check (model_timeout_ms between 1000 and 30000),
  policy_version text not null default 'practice_ai_policy_v1',
  prompt_version text not null default 'practice_ai_prompt_v1',
  retrieval_policy_version text not null default 'practice_ai_retrieval_v1',
  response_schema_version text not null default 'practice_ai_response_v1',
  updated_at timestamptz not null default now()
);

insert into private.practice_ai_policy(id)
values(1)
on conflict(id) do nothing;

create table if not exists private.practice_ai_entitlements (
  user_id uuid primary key references public.users(id) on delete cascade,
  entitlement_status text not null default 'inactive' check (entitlement_status in ('inactive','active','paused','revoked')),
  post_answer_enabled boolean not null default false,
  result_summary_enabled boolean not null default false,
  valid_from timestamptz null,
  valid_until timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (valid_until is null or valid_from is null or valid_until>valid_from)
);

create table if not exists private.practice_ai_source_cards (
  source_card_key text primary key,
  subject_key text not null,
  question_id bigint null references public.questions(id) on delete cascade,
  topic text null,
  subtopic text null,
  card_type text not null check (card_type in ('answer_explanation','result_context','theory')),
  locale text not null check (locale in ('ru','uz','en')),
  source_version text not null,
  title text not null,
  body_text text not null,
  approval_status text not null default 'draft' check (approval_status in ('draft','approved','rejected')),
  rights_status text not null default 'blocked' check (rights_status in ('original_iclub','official_public_metadata','licensed','blocked')),
  is_runtime_allowed boolean not null default false,
  content_hash text not null,
  approved_at timestamptz null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(source_card_key) between 3 and 180),
  check (char_length(source_version) between 1 and 120),
  check (char_length(content_hash) between 16 and 160),
  check (not is_runtime_allowed or (approval_status='approved' and rights_status<>'blocked'))
);

create index if not exists practice_ai_source_cards_runtime_idx
  on private.practice_ai_source_cards(subject_key,locale,card_type,is_runtime_allowed)
  where approval_status='approved';

create index if not exists practice_ai_source_cards_question_idx
  on private.practice_ai_source_cards(question_id,locale,card_type)
  where approval_status='approved' and is_runtime_allowed;

create table if not exists private.practice_ai_audit (
  request_id uuid primary key,
  user_id uuid null references public.users(id) on delete set null,
  interaction_type text not null,
  requested_locale text not null check (requested_locale in ('ru','uz','en')),
  mode text not null check (mode in ('deterministic_only','verified_template','generated','cached','fallback','blocked','no_source','unavailable')),
  subject_id bigint null references public.subjects(id) on delete set null,
  session_id bigint null,
  attempt_id bigint null,
  question_id bigint null references public.questions(id) on delete set null,
  deterministic_snapshot_hash text null,
  source_card_keys text[] not null default '{}'::text[],
  guard_decisions jsonb not null default '{}'::jsonb,
  policy_version text not null,
  prompt_version text not null,
  retrieval_policy_version text not null,
  response_schema_version text not null,
  model_provider text null,
  model_id text null,
  latency_ms integer null check (latency_ms is null or latency_ms>=0),
  input_tokens integer null check (input_tokens is null or input_tokens>=0),
  output_tokens integer null check (output_tokens is null or output_tokens>=0),
  estimated_cost_usd numeric(12,6) null check (estimated_cost_usd is null or estimated_cost_usd>=0),
  fallback_reason text null,
  safety_flags text[] not null default '{}'::text[],
  output_hash text null,
  created_at timestamptz not null default now()
);

create index if not exists practice_ai_audit_user_created_idx
  on private.practice_ai_audit(user_id,created_at desc);

create table if not exists private.practice_ai_daily_usage (
  user_id uuid not null references public.users(id) on delete cascade,
  usage_date date not null default current_date,
  request_count integer not null default 0 check (request_count>=0),
  generated_count integer not null default 0 check (generated_count>=0),
  input_tokens bigint not null default 0 check (input_tokens>=0),
  output_tokens bigint not null default 0 check (output_tokens>=0),
  estimated_cost_usd numeric(14,6) not null default 0 check (estimated_cost_usd>=0),
  updated_at timestamptz not null default now(),
  primary key(user_id,usage_date)
);

alter table private.practice_ai_policy enable row level security;
alter table private.practice_ai_entitlements enable row level security;
alter table private.practice_ai_source_cards enable row level security;
alter table private.practice_ai_audit enable row level security;
alter table private.practice_ai_daily_usage enable row level security;

revoke all on private.practice_ai_policy from public,anon,authenticated;
revoke all on private.practice_ai_entitlements from public,anon,authenticated;
revoke all on private.practice_ai_source_cards from public,anon,authenticated;
revoke all on private.practice_ai_audit from public,anon,authenticated;
revoke all on private.practice_ai_daily_usage from public,anon,authenticated;

grant all on private.practice_ai_policy to service_role;
grant all on private.practice_ai_entitlements to service_role;
grant all on private.practice_ai_source_cards to service_role;
grant all on private.practice_ai_audit to service_role;
grant all on private.practice_ai_daily_usage to service_role;

create or replace function private.practice_ai_has_active_protected_assessment_v1(p_user_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_tour boolean:=false;
  v_exam boolean:=false;
begin
  if p_user_id is null then return true; end if;

  select exists(
    select 1
    from public.tour_attempts ta
    where ta.user_id=p_user_id
      and ta.status='in_progress'
  ) into v_tour;

  begin
    v_exam:=private.exam_prep_has_active_protected_assessment_v1(p_user_id);
  exception
    when undefined_function then
      v_exam:=true;
  end;

  return coalesce(v_tour,false) or coalesce(v_exam,true);
end;
$$;

revoke all on function private.practice_ai_has_active_protected_assessment_v1(uuid)
  from public,anon,authenticated;
grant execute on function private.practice_ai_has_active_protected_assessment_v1(uuid)
  to service_role;

create or replace function public.get_practice_ai_guard_v1(
  p_interaction_type text,
  p_requested_locale text,
  p_user_text_length integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_policy private.practice_ai_policy%rowtype;
  v_ent private.practice_ai_entitlements%rowtype;
  v_used integer:=0;
begin
  if v_uid is null then
    raise exception 'practice_ai_auth_required';
  end if;

  select * into v_policy from private.practice_ai_policy where id=1;
  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','policy_missing');
  end if;

  if p_interaction_type is null or not (p_interaction_type=any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_requested_locale is null or not (p_requested_locale=any(v_policy.allowed_locales)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','locale_not_allowed');
  end if;

  if coalesce(p_user_text_length,0)<0 or coalesce(p_user_text_length,0)>v_policy.max_user_text_chars then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','input_too_long');
  end if;

  if private.practice_ai_has_active_protected_assessment_v1(v_uid) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select * into v_ent
  from private.practice_ai_entitlements
  where user_id=v_uid
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  if v_policy.kill_switch
     or v_policy.rollout_state='off'
     or not v_policy.enabled
     or not v_policy.generation_enabled
     or v_ent.user_id is null then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','ai_disabled');
  end if;

  if p_interaction_type='post_answer_explanation' and not coalesce(v_ent.post_answer_enabled,false) then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','interaction_not_entitled');
  end if;

  if p_interaction_type='practice_result_summary' and not coalesce(v_ent.result_summary_enabled,false) then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','interaction_not_entitled');
  end if;

  select coalesce(u.request_count,0) into v_used
  from private.practice_ai_daily_usage u
  where u.user_id=v_uid and u.usage_date=current_date;

  if coalesce(v_used,0)>=v_policy.max_daily_requests then
    return jsonb_build_object('allowed',false,'mode','fallback','reason','daily_budget_exhausted');
  end if;

  return jsonb_build_object(
    'allowed',true,
    'mode','ready',
    'interaction_type',p_interaction_type,
    'requested_locale',p_requested_locale,
    'policy_version',v_policy.policy_version,
    'prompt_version',v_policy.prompt_version,
    'retrieval_policy_version',v_policy.retrieval_policy_version,
    'response_schema_version',v_policy.response_schema_version,
    'max_output_chars',v_policy.max_output_chars,
    'model_timeout_ms',v_policy.model_timeout_ms
  );
end;
$$;

revoke all on function public.get_practice_ai_guard_v1(text,text,integer)
  from public,anon;
grant execute on function public.get_practice_ai_guard_v1(text,text,integer)
  to authenticated,service_role;

create or replace function public.get_practice_ai_answer_context_service_v1(
  p_user_id uuid,
  p_session_id bigint,
  p_question_id bigint,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_locale text:=case when p_locale in ('ru','uz','en') then p_locale else 'en' end;
  v_result jsonb;
begin
  if p_user_id is null or p_session_id is null or p_question_id is null then
    return null;
  end if;

  select jsonb_build_object(
    'context_type','practice_answer_v1',
    'subject_id',s.subject_id,
    'subject_key',sub.subject_key,
    'subject_title',sub.title,
    'session_id',s.id,
    'question_id',q.id,
    'topic',q.topic,
    'subtopic',q.subtopic,
    'qtype',q.qtype,
    'is_correct',a.is_correct,
    'user_answer',a.user_answer,
    'time_spent',a.time_spent,
    'diagnostic_mapped',false,
    'diagnostic',null
  )
  into v_result
  from public.practice_sessions_v4 s
  join public.practice_session_answers_v4 a
    on a.session_id=s.id and a.question_id=p_question_id
  join public.questions q
    on q.id=a.question_id and q.subject_id=s.subject_id
  join public.subjects sub
    on sub.id=s.subject_id
  where s.id=p_session_id
    and s.user_id=p_user_id
    and p_question_id=any(s.question_ids)
    and a.answered_at is not null;

  return v_result;
end;
$$;

revoke all on function public.get_practice_ai_answer_context_service_v1(uuid,bigint,bigint,text)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_answer_context_service_v1(uuid,bigint,bigint,text)
  to service_role;

create or replace function public.get_practice_ai_result_context_service_v1(
  p_user_id uuid,
  p_attempt_id bigint,
  p_locale text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_result jsonb;
begin
  if p_user_id is null or p_attempt_id is null then return null; end if;

  with owned as (
    select pa.id,pa.subject_id,pa.score,pa.percent,pa.time_seconds,pa.created_at
    from public.practice_attempts pa
    where pa.id=p_attempt_id and pa.user_id=p_user_id and coalesce(pa.is_lab,false)=false
  ),
  answers as (
    select a.question_id,a.is_correct,a.time_spent,q.topic,q.subtopic
    from owned o
    join public.practice_answers a on a.attempt_id=o.id
    join public.questions q on q.id=a.question_id and q.subject_id=o.subject_id
  ),
  weak_topics as (
    select topic,subtopic,count(*)::int as wrong_count
    from answers
    where is_correct=false
    group by topic,subtopic
    order by count(*) desc,topic,subtopic
    limit 8
  ),
  diag as (
    select d.mistake_type,d.weak_skill,count(*)::int as occurrence_count
    from public.user_answer_diagnosis d
    where d.user_id=p_user_id
      and d.attempt_type='practice'
      and d.attempt_id=p_attempt_id
      and d.is_correct=false
      and (d.mistake_type is not null or d.weak_skill is not null)
    group by d.mistake_type,d.weak_skill
    order by count(*) desc,d.mistake_type,d.weak_skill
    limit 8
  )
  select jsonb_build_object(
    'context_type','practice_result_v1',
    'attempt_id',o.id,
    'subject_id',o.subject_id,
    'subject_key',s.subject_key,
    'subject_title',s.title,
    'score',o.score,
    'percent',o.percent,
    'time_seconds',o.time_seconds,
    'question_count',(select count(*) from answers),
    'wrong_count',(select count(*) from answers where is_correct=false),
    'weak_topics',coalesce((select jsonb_agg(jsonb_build_object(
      'topic',w.topic,'subtopic',w.subtopic,'wrong_count',w.wrong_count
    )) from weak_topics w),'[]'::jsonb),
    'diagnostic_patterns',coalesce((select jsonb_agg(jsonb_build_object(
      'mistake_type',d.mistake_type,'weak_skill',d.weak_skill,'occurrence_count',d.occurrence_count
    )) from diag d),'[]'::jsonb)
  )
  into v_result
  from owned o
  join public.subjects s on s.id=o.subject_id;

  return v_result;
end;
$$;

revoke all on function public.get_practice_ai_result_context_service_v1(uuid,bigint,text)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_result_context_service_v1(uuid,bigint,text)
  to service_role;

create or replace function public.get_practice_ai_source_cards_service_v1(
  p_subject_key text,
  p_locale text,
  p_card_type text,
  p_question_id bigint default null,
  p_topic text default null,
  p_subtopic text default null,
  p_limit integer default 6
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'source_card_key',x.source_card_key,
    'subject_key',x.subject_key,
    'question_id',x.question_id,
    'topic',x.topic,
    'subtopic',x.subtopic,
    'card_type',x.card_type,
    'locale',x.locale,
    'source_version',x.source_version,
    'title',x.title,
    'body_text',x.body_text,
    'content_hash',x.content_hash
  ) order by x.rank_order,x.source_card_key),'[]'::jsonb)
  from (
    select c.*,
      case
        when p_question_id is not null and c.question_id=p_question_id then 1
        when p_topic is not null and c.question_id is null and c.topic=p_topic
             and ((p_subtopic is not null and c.subtopic=p_subtopic) or c.subtopic is null) then 2
        when c.question_id is null and c.topic is null then 3
        else 9
      end as rank_order
    from private.practice_ai_source_cards c
    where c.subject_key=p_subject_key
      and c.locale=p_locale
      and c.card_type=p_card_type
      and c.approval_status='approved'
      and c.is_runtime_allowed
      and c.rights_status in ('original_iclub','official_public_metadata','licensed')
      and (
        (p_question_id is not null and c.question_id=p_question_id)
        or
        (p_topic is not null and c.question_id is null and c.topic=p_topic
          and (c.subtopic is null or c.subtopic=p_subtopic))
        or
        (c.question_id is null and c.topic is null)
      )
    order by rank_order,c.source_card_key
    limit greatest(1,least(coalesce(p_limit,6),12))
  ) x;
$$;

revoke all on function public.get_practice_ai_source_cards_service_v1(text,text,text,bigint,text,text,integer)
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_source_cards_service_v1(text,text,text,bigint,text,text,integer)
  to service_role;

create or replace function public.record_practice_ai_audit_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_interaction_type text,
  p_requested_locale text,
  p_mode text,
  p_guard_decisions jsonb,
  p_policy_version text,
  p_prompt_version text,
  p_retrieval_policy_version text,
  p_response_schema_version text,
  p_subject_id bigint default null,
  p_session_id bigint default null,
  p_attempt_id bigint default null,
  p_question_id bigint default null,
  p_deterministic_snapshot_hash text default null,
  p_source_card_keys text[] default '{}'::text[],
  p_model_provider text default null,
  p_model_id text default null,
  p_latency_ms integer default null,
  p_input_tokens integer default null,
  p_output_tokens integer default null,
  p_estimated_cost_usd numeric default null,
  p_fallback_reason text default null,
  p_safety_flags text[] default '{}'::text[],
  p_output_hash text default null
)
returns boolean
language plpgsql
security definer
set search_path=''
as $$
declare
  v_inserted uuid;
begin
  if p_requested_locale not in ('ru','uz','en') then raise exception 'practice_ai_invalid_locale'; end if;
  if p_mode not in ('deterministic_only','verified_template','generated','cached','fallback','blocked','no_source','unavailable') then
    raise exception 'practice_ai_invalid_mode';
  end if;

  insert into private.practice_ai_audit(
    request_id,user_id,interaction_type,requested_locale,mode,subject_id,session_id,attempt_id,question_id,
    deterministic_snapshot_hash,source_card_keys,guard_decisions,policy_version,prompt_version,
    retrieval_policy_version,response_schema_version,model_provider,model_id,latency_ms,input_tokens,
    output_tokens,estimated_cost_usd,fallback_reason,safety_flags,output_hash
  ) values (
    p_request_id,p_user_id,p_interaction_type,p_requested_locale,p_mode,p_subject_id,p_session_id,p_attempt_id,p_question_id,
    p_deterministic_snapshot_hash,coalesce(p_source_card_keys,'{}'::text[]),coalesce(p_guard_decisions,'{}'::jsonb),
    p_policy_version,p_prompt_version,p_retrieval_policy_version,p_response_schema_version,p_model_provider,p_model_id,
    p_latency_ms,p_input_tokens,p_output_tokens,p_estimated_cost_usd,p_fallback_reason,
    coalesce(p_safety_flags,'{}'::text[]),p_output_hash
  )
  on conflict(request_id) do nothing
  returning request_id into v_inserted;

  if v_inserted is null then return false; end if;

  if p_user_id is not null then
    insert into private.practice_ai_daily_usage(
      user_id,usage_date,request_count,generated_count,input_tokens,output_tokens,estimated_cost_usd,updated_at
    ) values (
      p_user_id,current_date,1,case when p_mode='generated' then 1 else 0 end,
      coalesce(p_input_tokens,0),coalesce(p_output_tokens,0),coalesce(p_estimated_cost_usd,0),now()
    )
    on conflict(user_id,usage_date) do update set
      request_count=private.practice_ai_daily_usage.request_count+1,
      generated_count=private.practice_ai_daily_usage.generated_count+case when excluded.generated_count>0 then 1 else 0 end,
      input_tokens=private.practice_ai_daily_usage.input_tokens+excluded.input_tokens,
      output_tokens=private.practice_ai_daily_usage.output_tokens+excluded.output_tokens,
      estimated_cost_usd=private.practice_ai_daily_usage.estimated_cost_usd+excluded.estimated_cost_usd,
      updated_at=now();
  end if;

  return true;
end;
$$;

revoke all on function public.record_practice_ai_audit_service_v1(uuid,uuid,text,text,text,jsonb,text,text,text,text,bigint,bigint,bigint,bigint,text,text[],text,text,integer,integer,integer,numeric,text,text[],text)
  from public,anon,authenticated;
grant execute on function public.record_practice_ai_audit_service_v1(uuid,uuid,text,text,text,jsonb,text,text,text,text,bigint,bigint,bigint,bigint,text,text[],text,text,integer,integer,integer,numeric,text,text[],text)
  to service_role;

create or replace function public.get_practice_ai_operational_snapshot_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $$
  select jsonb_build_object(
    'policy',jsonb_build_object(
      'rollout_state',p.rollout_state,
      'enabled',p.enabled,
      'generation_enabled',p.generation_enabled,
      'kill_switch',p.kill_switch,
      'policy_version',p.policy_version,
      'prompt_version',p.prompt_version,
      'retrieval_policy_version',p.retrieval_policy_version,
      'response_schema_version',p.response_schema_version,
      'max_daily_requests',p.max_daily_requests
    ),
    'active_entitlements',(
      select count(*) from private.practice_ai_entitlements e
      where e.entitlement_status='active'
        and (e.valid_from is null or e.valid_from<=now())
        and (e.valid_until is null or e.valid_until>now())
    ),
    'runtime_source_cards',(
      select count(*) from private.practice_ai_source_cards c
      where c.approval_status='approved'
        and c.is_runtime_allowed
        and c.rights_status<>'blocked'
    ),
    'audit_24h',coalesce((
      select jsonb_object_agg(q.mode,q.cnt)
      from (
        select a.mode,count(*)::int cnt
        from private.practice_ai_audit a
        where a.created_at>=now()-interval '24 hours'
        group by a.mode
      ) q
    ),'{}'::jsonb)
  )
  from private.practice_ai_policy p
  where p.id=1;
$$;

revoke all on function public.get_practice_ai_operational_snapshot_v1()
  from public,anon,authenticated;
grant execute on function public.get_practice_ai_operational_snapshot_v1()
  to service_role;

commit;
