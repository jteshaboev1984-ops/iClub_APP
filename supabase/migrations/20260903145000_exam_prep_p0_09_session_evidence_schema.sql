-- P0-09: authoritative Exam Prep session / response / evidence foundation.
-- Additive only; no legacy Practice/Tour/history writes.
-- Client gets ZERO direct table grants. All learner access is through membership-bound safe RPCs.

begin;

create table if not exists private.exam_prep_session_authorizations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  assessment_id bigint not null references private.exam_prep_assessments(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  purpose text not null check(purpose in ('diagnostic','learning','retest','mixed','timed','paper')),
  status text not null default 'issued' check(status in ('issued','consumed','revoked','expired')),
  issued_at timestamptz not null default now(),
  valid_until timestamptz null,
  consumed_at timestamptz null,
  consumed_session_id uuid null,
  issued_by uuid null,
  reason text not null,
  check(valid_until is null or valid_until>issued_at)
);
create index if not exists exam_prep_session_authorizations_user_idx on private.exam_prep_session_authorizations(user_id,status,valid_until);

create table if not exists private.exam_prep_sessions (
  id uuid primary key default gen_random_uuid(),
  authorization_id uuid not null unique references private.exam_prep_session_authorizations(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  content_version_id bigint not null references private.exam_prep_content_versions(id) on delete restrict,
  assessment_id bigint not null references private.exam_prep_assessments(id) on delete restrict,
  assessment_version text not null,
  component_code text not null check(component_code in ('P1','P5')),
  session_type text not null check(session_type in ('diagnostic','learning','retest','mixed','timed','paper')),
  status text not null default 'active' check(status in ('active','finalized','abandoned')),
  client_idempotency_key text not null check(char_length(client_idempotency_key) between 8 and 160),
  total_items smallint not null check(total_items>0),
  started_at timestamptz not null default now(),
  last_activity_at timestamptz not null default now(),
  finalized_at timestamptz null,
  finalize_idempotency_key text null,
  timing_contract jsonb not null default '{}'::jsonb,
  unique(user_id,client_idempotency_key),
  check((status='finalized' and finalized_at is not null) or status<>'finalized')
);

alter table private.exam_prep_session_authorizations
  add constraint exam_prep_session_authorizations_consumed_session_fkey
  foreign key(consumed_session_id) references private.exam_prep_sessions(id) on delete restrict;
create unique index if not exists exam_prep_session_authorizations_consumed_session_uidx
  on private.exam_prep_session_authorizations(consumed_session_id) where consumed_session_id is not null;
create index if not exists exam_prep_sessions_user_status_idx on private.exam_prep_sessions(user_id,status,started_at desc);

create table if not exists private.exam_prep_session_items (
  session_id uuid not null references private.exam_prep_sessions(id) on delete cascade,
  item_order smallint not null check(item_order>0),
  item_kind text not null check(item_kind in ('question','written')),
  question_id bigint null references public.questions(id) on delete restrict,
  written_task_id bigint null references private.exam_prep_written_tasks(id) on delete restrict,
  primary_skill_code text not null,
  reserve_role text not null check(reserve_role in ('diagnostic','learning','retest','mixed','timed','written')),
  is_holdout boolean not null default false,
  content_meta_id bigint null references private.exam_prep_question_content_meta(id) on delete restrict,
  question_snapshot_md5 text null,
  item_version text not null,
  created_at timestamptz not null default now(),
  primary key(session_id,item_order),
  check((question_id is not null)::int + (written_task_id is not null)::int = 1),
  check((item_kind='question' and question_id is not null and content_meta_id is not null and question_snapshot_md5 is not null)
     or (item_kind='written' and written_task_id is not null and content_meta_id is null and question_snapshot_md5 is null))
);
create index if not exists exam_prep_session_items_question_idx on private.exam_prep_session_items(question_id) where question_id is not null;

create table if not exists private.exam_prep_responses (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null,
  item_order smallint not null,
  user_id uuid not null references public.users(id) on delete cascade,
  client_idempotency_key text not null check(char_length(client_idempotency_key) between 8 and 160),
  response_kind text not null check(response_kind in ('machine','written')),
  user_answer text null,
  picked_index integer null check(picked_index is null or picked_index between 0 and 25),
  learner_artifact jsonb null,
  selected_answer text null,
  is_correct boolean null,
  evaluator_version text not null,
  elapsed_ms integer null check(elapsed_ms is null or elapsed_ms>=0),
  answered_at timestamptz not null default now(),
  foreign key(session_id,item_order) references private.exam_prep_session_items(session_id,item_order) on delete restrict,
  unique(session_id,item_order),
  unique(session_id,client_idempotency_key),
  check((response_kind='machine' and is_correct is not null and learner_artifact is null)
     or (response_kind='written' and is_correct is null and learner_artifact is not null))
);
create index if not exists exam_prep_responses_user_idx on private.exam_prep_responses(user_id,answered_at desc);

create table if not exists private.exam_prep_evidence_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text not null,
  session_id uuid not null references private.exam_prep_sessions(id) on delete restrict,
  response_id uuid not null references private.exam_prep_responses(id) on delete restrict,
  evidence_type text not null check(evidence_type in ('diagnostic','learning','retest','mixed','timed','written')),
  verification_status text not null check(verification_status in ('app_verified','self_reviewed','human_review_recommended','mentor_verified','mentor_disputed')),
  is_correct boolean null,
  evidence_payload jsonb not null default '{}'::jsonb,
  source_version text not null,
  created_at timestamptz not null default now(),
  unique(response_id,skill_code,evidence_type),
  check((verification_status='app_verified' and is_correct is not null) or verification_status<>'app_verified')
);
create index if not exists exam_prep_evidence_user_component_idx on private.exam_prep_evidence_events(user_id,component_code,skill_code,created_at desc);

-- P0-09 creates correction/retest anchors only. P0-10 owns deterministic transition logic.
create table if not exists private.exam_prep_correction_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text not null,
  status text not null default 'open' check(status in ('open','remediating','retest_due','resolved','reopened')),
  opened_from_evidence_id uuid null references private.exam_prep_evidence_events(id) on delete restrict,
  opened_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz null,
  engine_version text null,
  reason jsonb not null default '{}'::jsonb
);
create index if not exists exam_prep_correction_cases_user_idx on private.exam_prep_correction_cases(user_id,component_code,status);

create table if not exists private.exam_prep_retest_events (
  id uuid primary key default gen_random_uuid(),
  correction_case_id uuid not null references private.exam_prep_correction_cases(id) on delete restrict,
  user_id uuid not null references public.users(id) on delete cascade,
  component_code text not null check(component_code in ('P1','P5')),
  skill_code text not null,
  status text not null default 'scheduled' check(status in ('scheduled','authorized','completed','cancelled')),
  due_not_before timestamptz null,
  authorization_id uuid null references private.exam_prep_session_authorizations(id) on delete restrict,
  completed_session_id uuid null references private.exam_prep_sessions(id) on delete restrict,
  created_at timestamptz not null default now(),
  completed_at timestamptz null
);
create index if not exists exam_prep_retest_events_user_idx on private.exam_prep_retest_events(user_id,component_code,status,due_not_before);

-- Frozen/append-only facts cannot be rewritten, including by service code. Corrections are new events/cases, never response edits.
create or replace function private.exam_prep_block_immutable_mutation_v1()
returns trigger language plpgsql security invoker set search_path='' as $$
begin
  raise exception 'immutable_exam_prep_fact';
end; $$;
revoke all on function private.exam_prep_block_immutable_mutation_v1() from public,anon,authenticated;

create trigger exam_prep_session_items_immutable_v1 before update or delete on private.exam_prep_session_items for each row execute function private.exam_prep_block_immutable_mutation_v1();
create trigger exam_prep_responses_immutable_v1 before update or delete on private.exam_prep_responses for each row execute function private.exam_prep_block_immutable_mutation_v1();
create trigger exam_prep_evidence_events_immutable_v1 before update or delete on private.exam_prep_evidence_events for each row execute function private.exam_prep_block_immutable_mutation_v1();

-- All P0-09 tables are private/server-only. No direct learner grants.
do $$ declare t text; begin
  foreach t in array array[
    'exam_prep_session_authorizations','exam_prep_sessions','exam_prep_session_items','exam_prep_responses',
    'exam_prep_evidence_events','exam_prep_correction_cases','exam_prep_retest_events'
  ] loop
    execute format('alter table private.%I enable row level security',t);
    execute format('revoke all on private.%I from public,anon,authenticated',t);
    execute format('grant all on private.%I to service_role',t);
  end loop;
end $$;

-- Governance/audit for mutable authority and session headers. High-volume response/evidence facts are themselves append-only audit facts.
do $$ begin
  execute 'create trigger exam_prep_session_authorizations_audit_v1 after insert or update or delete on private.exam_prep_session_authorizations for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_sessions_audit_v1 after insert or update or delete on private.exam_prep_sessions for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_correction_cases_audit_v1 after insert or update or delete on private.exam_prep_correction_cases for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;
do $$ begin
  execute 'create trigger exam_prep_retest_events_audit_v1 after insert or update or delete on private.exam_prep_retest_events for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null; end $$;

commit;
