-- P1-04 AI safety foundation v1.
-- Additive/dormant: no model calls, no academic-state mutation, no learner AI enablement.
-- AI remains independently gated by feature config + entitlement + runtime status + policy.

create table if not exists private.exam_prep_ai_policy (
  id smallint primary key default 1 check (id = 1),
  policy_version text not null default 'exam_prep_ai_policy_v1',
  generation_enabled boolean not null default false,
  allowed_interactions text[] not null default array[
    'established_error_explanation',
    'weekly_plan_narration',
    'progress_summary',
    'repeated_error_summary',
    'theory_explanation',
    'multilingual_explanation',
    'mentor_report_draft'
  ]::text[],
  allowed_locales text[] not null default array['ru','uz','en']::text[],
  max_user_text_chars integer not null default 2000 check (max_user_text_chars between 0 and 12000),
  max_output_chars integer not null default 5000 check (max_output_chars between 256 and 20000),
  max_daily_requests integer not null default 30 check (max_daily_requests between 1 and 500),
  model_timeout_ms integer not null default 12000 check (model_timeout_ms between 1000 and 60000),
  prompt_version text not null default 'exam_prep_ai_prompt_v1',
  retrieval_policy_version text not null default 'exam_prep_ai_retrieval_v1',
  response_schema_version text not null default 'exam_prep_ai_response_v1',
  updated_at timestamptz not null default now(),
  updated_by uuid null
);

insert into private.exam_prep_ai_policy (id)
values (1)
on conflict (id) do nothing;

create table if not exists private.exam_prep_ai_source_cards (
  id uuid primary key default gen_random_uuid(),
  source_card_key text not null unique,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text null,
  card_type text not null check (card_type in (
    'theory',
    'error_explanation',
    'progress_context',
    'weekly_plan_context',
    'syllabus_metadata',
    'mentor_context'
  )),
  locale text not null check (locale in ('ru','uz','en')),
  source_version text not null,
  title text not null,
  body_text text not null,
  approval_status text not null default 'draft' check (approval_status in ('draft','approved','retired')),
  rights_status text not null default 'original_iclub' check (rights_status in (
    'original_iclub',
    'official_public_metadata',
    'licensed',
    'blocked'
  )),
  is_runtime_allowed boolean not null default false,
  content_hash text not null,
  approved_at timestamptz null,
  approved_by uuid null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (char_length(source_card_key) between 3 and 160),
  check (char_length(source_version) between 1 and 120),
  check (char_length(content_hash) between 16 and 160),
  check (not is_runtime_allowed or (approval_status = 'approved' and rights_status <> 'blocked'))
);

create index if not exists exam_prep_ai_source_cards_runtime_idx
  on private.exam_prep_ai_source_cards(component_code, locale, card_type, is_runtime_allowed)
  where approval_status = 'approved';

create table if not exists private.exam_prep_ai_audit (
  request_id uuid primary key,
  user_id uuid null references public.users(id) on delete set null,
  component_code text not null check (component_code in ('P1','P5')),
  interaction_type text not null,
  requested_locale text not null check (requested_locale in ('ru','uz','en')),
  mode text not null check (mode in (
    'deterministic_only',
    'verified_template',
    'generated',
    'cached',
    'fallback',
    'blocked',
    'no_source',
    'unavailable'
  )),
  session_ref uuid null,
  deterministic_snapshot_hash text null,
  evidence_ids uuid[] not null default '{}'::uuid[],
  source_card_keys text[] not null default '{}'::text[],
  guard_decisions jsonb not null default '{}'::jsonb,
  policy_version text not null,
  prompt_version text not null,
  retrieval_policy_version text not null,
  response_schema_version text not null,
  model_provider text null,
  model_id text null,
  latency_ms integer null check (latency_ms is null or latency_ms >= 0),
  input_tokens integer null check (input_tokens is null or input_tokens >= 0),
  output_tokens integer null check (output_tokens is null or output_tokens >= 0),
  estimated_cost_usd numeric(12,6) null check (estimated_cost_usd is null or estimated_cost_usd >= 0),
  fallback_reason text null,
  safety_flags text[] not null default '{}'::text[],
  output_hash text null,
  created_at timestamptz not null default now()
);

create index if not exists exam_prep_ai_audit_user_created_idx
  on private.exam_prep_ai_audit(user_id, created_at desc);
create index if not exists exam_prep_ai_audit_mode_created_idx
  on private.exam_prep_ai_audit(mode, created_at desc);

create table if not exists private.exam_prep_ai_daily_usage (
  user_id uuid not null references public.users(id) on delete cascade,
  usage_date date not null default current_date,
  request_count integer not null default 0 check (request_count >= 0),
  generated_count integer not null default 0 check (generated_count >= 0),
  input_tokens bigint not null default 0 check (input_tokens >= 0),
  output_tokens bigint not null default 0 check (output_tokens >= 0),
  estimated_cost_usd numeric(14,6) not null default 0 check (estimated_cost_usd >= 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, usage_date)
);

alter table private.exam_prep_ai_policy enable row level security;
alter table private.exam_prep_ai_source_cards enable row level security;
alter table private.exam_prep_ai_audit enable row level security;
alter table private.exam_prep_ai_daily_usage enable row level security;

revoke all on private.exam_prep_ai_policy from public, anon, authenticated;
revoke all on private.exam_prep_ai_source_cards from public, anon, authenticated;
revoke all on private.exam_prep_ai_audit from public, anon, authenticated;
revoke all on private.exam_prep_ai_daily_usage from public, anon, authenticated;

grant all on private.exam_prep_ai_policy to service_role;
grant all on private.exam_prep_ai_source_cards to service_role;
grant all on private.exam_prep_ai_audit to service_role;
grant all on private.exam_prep_ai_daily_usage to service_role;

create or replace function public.get_exam_prep_ai_guard_v1(
  p_component_code text,
  p_interaction_type text,
  p_requested_locale text,
  p_user_text_length integer default 0
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_policy private.exam_prep_ai_policy%rowtype;
  v_cfg private.exam_prep_feature_config%rowtype;
  v_ent private.exam_prep_feature_entitlements%rowtype;
  v_runtime text := 'not_deployed';
  v_active_protected boolean := false;
  v_used integer := 0;
begin
  if v_uid is null then
    raise exception 'exam_prep_ai_auth_required';
  end if;

  if p_component_code not in ('P1','P5') then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','invalid_component');
  end if;

  select * into v_policy from private.exam_prep_ai_policy where id=1;
  if not found then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','policy_missing');
  end if;

  if p_interaction_type is null or not (p_interaction_type = any(v_policy.allowed_interactions)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','interaction_not_allowed');
  end if;

  if p_requested_locale is null or not (p_requested_locale = any(v_policy.allowed_locales)) then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','locale_not_allowed');
  end if;

  if coalesce(p_user_text_length,0) < 0 or coalesce(p_user_text_length,0) > v_policy.max_user_text_chars then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','input_too_long','max_chars',v_policy.max_user_text_chars);
  end if;

  if p_interaction_type = 'mentor_report_draft' then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','mentor_actor_required');
  end if;

  select * into v_cfg from private.exam_prep_feature_config where id=1;
  select * into v_ent
  from private.exam_prep_feature_entitlements
  where user_id=v_uid
    and entitlement_status='active'
    and (valid_from is null or valid_from<=now())
    and (valid_until is null or valid_until>now());

  select runtime_status into v_runtime
  from private.exam_prep_optional_capability_status
  where capability_code='ai_assist';
  v_runtime := coalesce(v_runtime,'not_deployed');

  if v_cfg.id is null
     or v_cfg.kill_switch
     or v_cfg.rollout_state='off'
     or not v_cfg.core_enabled
     or v_ent.user_id is null
     or not coalesce(v_ent.core_access,false) then
    return jsonb_build_object('allowed',false,'mode','unavailable','reason','core_not_available');
  end if;

  if not v_cfg.ai_enabled
     or not coalesce(v_ent.ai_assist,false)
     or v_runtime <> 'ready'
     or not v_policy.generation_enabled then
    return jsonb_build_object(
      'allowed',false,
      'mode','unavailable',
      'reason','ai_disabled',
      'runtime_status',v_runtime,
      'policy_generation_enabled',v_policy.generation_enabled
    );
  end if;

  select exists(
    select 1
    from private.exam_prep_sessions s
    where s.user_id=v_uid
      and s.component_code=p_component_code
      and s.status='active'
      and s.session_type in ('diagnostic','retest','mixed','timed','paper')
  ) into v_active_protected;

  if v_active_protected then
    return jsonb_build_object('allowed',false,'mode','blocked','reason','active_assessment');
  end if;

  select coalesce(u.request_count,0) into v_used
  from private.exam_prep_ai_daily_usage u
  where u.user_id=v_uid and u.usage_date=current_date;
  v_used := coalesce(v_used,0);

  if v_used >= v_policy.max_daily_requests then
    return jsonb_build_object('allowed',false,'mode','fallback','reason','daily_budget_exhausted');
  end if;

  return jsonb_build_object(
    'allowed',true,
    'mode','ready',
    'component_code',p_component_code,
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

revoke all on function public.get_exam_prep_ai_guard_v1(text,text,text,integer) from public, anon;
grant execute on function public.get_exam_prep_ai_guard_v1(text,text,text,integer) to authenticated, service_role;

create or replace function public.get_exam_prep_ai_source_cards_service_v1(
  p_component_code text,
  p_locale text,
  p_card_type text default null,
  p_skill_code text default null,
  p_limit integer default 8
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'source_card_key',x.source_card_key,
    'component_code',x.component_code,
    'skill_code',x.skill_code,
    'card_type',x.card_type,
    'locale',x.locale,
    'source_version',x.source_version,
    'title',x.title,
    'body_text',x.body_text,
    'content_hash',x.content_hash
  ) order by x.source_card_key),'[]'::jsonb)
  from (
    select c.*
    from private.exam_prep_ai_source_cards c
    where c.component_code=p_component_code
      and c.locale=p_locale
      and c.approval_status='approved'
      and c.is_runtime_allowed
      and c.rights_status in ('original_iclub','official_public_metadata','licensed')
      and (p_card_type is null or c.card_type=p_card_type)
      and (p_skill_code is null or c.skill_code is null or c.skill_code=p_skill_code)
    order by c.source_card_key
    limit greatest(1,least(coalesce(p_limit,8),20))
  ) x;
$$;

revoke all on function public.get_exam_prep_ai_source_cards_service_v1(text,text,text,text,integer) from public, anon, authenticated;
grant execute on function public.get_exam_prep_ai_source_cards_service_v1(text,text,text,text,integer) to service_role;

create or replace function public.record_exam_prep_ai_audit_service_v1(
  p_request_id uuid,
  p_user_id uuid,
  p_component_code text,
  p_interaction_type text,
  p_requested_locale text,
  p_mode text,
  p_guard_decisions jsonb,
  p_policy_version text,
  p_prompt_version text,
  p_retrieval_policy_version text,
  p_response_schema_version text,
  p_session_ref uuid default null,
  p_deterministic_snapshot_hash text default null,
  p_evidence_ids uuid[] default '{}'::uuid[],
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
set search_path = ''
as $$
declare
  v_inserted uuid;
begin
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_ai_invalid_component'; end if;
  if p_requested_locale not in ('ru','uz','en') then raise exception 'exam_prep_ai_invalid_locale'; end if;
  if p_mode not in ('deterministic_only','verified_template','generated','cached','fallback','blocked','no_source','unavailable') then
    raise exception 'exam_prep_ai_invalid_mode';
  end if;

  insert into private.exam_prep_ai_audit(
    request_id,user_id,component_code,interaction_type,requested_locale,mode,session_ref,
    deterministic_snapshot_hash,evidence_ids,source_card_keys,guard_decisions,policy_version,
    prompt_version,retrieval_policy_version,response_schema_version,model_provider,model_id,
    latency_ms,input_tokens,output_tokens,estimated_cost_usd,fallback_reason,safety_flags,output_hash
  ) values (
    p_request_id,p_user_id,p_component_code,p_interaction_type,p_requested_locale,p_mode,p_session_ref,
    p_deterministic_snapshot_hash,coalesce(p_evidence_ids,'{}'::uuid[]),coalesce(p_source_card_keys,'{}'::text[]),
    coalesce(p_guard_decisions,'{}'::jsonb),p_policy_version,p_prompt_version,p_retrieval_policy_version,
    p_response_schema_version,p_model_provider,p_model_id,p_latency_ms,p_input_tokens,p_output_tokens,
    p_estimated_cost_usd,p_fallback_reason,coalesce(p_safety_flags,'{}'::text[]),p_output_hash
  )
  on conflict (request_id) do nothing
  returning request_id into v_inserted;

  if v_inserted is null then
    return false;
  end if;

  if p_user_id is not null then
    insert into private.exam_prep_ai_daily_usage(
      user_id,usage_date,request_count,generated_count,input_tokens,output_tokens,estimated_cost_usd,updated_at
    ) values (
      p_user_id,current_date,1,case when p_mode='generated' then 1 else 0 end,
      coalesce(p_input_tokens,0),coalesce(p_output_tokens,0),coalesce(p_estimated_cost_usd,0),now()
    )
    on conflict (user_id,usage_date) do update set
      request_count=private.exam_prep_ai_daily_usage.request_count+1,
      generated_count=private.exam_prep_ai_daily_usage.generated_count+case when excluded.generated_count>0 then 1 else 0 end,
      input_tokens=private.exam_prep_ai_daily_usage.input_tokens+excluded.input_tokens,
      output_tokens=private.exam_prep_ai_daily_usage.output_tokens+excluded.output_tokens,
      estimated_cost_usd=private.exam_prep_ai_daily_usage.estimated_cost_usd+excluded.estimated_cost_usd,
      updated_at=now();
  end if;

  return true;
end;
$$;

revoke all on function public.record_exam_prep_ai_audit_service_v1(uuid,uuid,text,text,text,text,jsonb,text,text,text,text,uuid,text,uuid[],text[],text,text,integer,integer,integer,numeric,text,text[],text) from public, anon, authenticated;
grant execute on function public.record_exam_prep_ai_audit_service_v1(uuid,uuid,text,text,text,text,jsonb,text,text,text,text,uuid,text,uuid[],text[],text,text,integer,integer,integer,numeric,text,text[],text) to service_role;

create or replace function public.get_exam_prep_ai_operational_snapshot_v1()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'policy', jsonb_build_object(
      'policy_version',p.policy_version,
      'generation_enabled',p.generation_enabled,
      'prompt_version',p.prompt_version,
      'retrieval_policy_version',p.retrieval_policy_version,
      'response_schema_version',p.response_schema_version,
      'max_daily_requests',p.max_daily_requests
    ),
    'runtime_status', coalesce((select s.runtime_status from private.exam_prep_optional_capability_status s where s.capability_code='ai_assist'),'not_deployed'),
    'runtime_source_cards', (select count(*) from private.exam_prep_ai_source_cards c where c.approval_status='approved' and c.is_runtime_allowed and c.rights_status<>'blocked'),
    'audit_24h', coalesce((select jsonb_object_agg(q.mode,q.cnt) from (
      select a.mode,count(*)::int cnt from private.exam_prep_ai_audit a where a.created_at>=now()-interval '24 hours' group by a.mode
    ) q),'{}'::jsonb)
  )
  from private.exam_prep_ai_policy p
  where p.id=1;
$$;

revoke all on function public.get_exam_prep_ai_operational_snapshot_v1() from public, anon, authenticated;
grant execute on function public.get_exam_prep_ai_operational_snapshot_v1() to service_role;
