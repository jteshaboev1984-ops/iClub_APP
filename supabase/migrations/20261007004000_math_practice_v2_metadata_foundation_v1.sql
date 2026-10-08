-- Mathematics Practice v2 — private runtime metadata foundation
-- Branch-only migration. No learner data or existing Tour/Practice records are changed.
-- The 495 new P1 questions will be staged separately with is_active=false and
-- attached to existing Mathematics Practice pools only during governed release.

create table if not exists private.practice_v2_question_meta (
  question_id bigint primary key
    references public.questions(id) on delete cascade,
  content_key text not null unique,
  release_version text not null,
  practice_no smallint not null check (practice_no between 1 and 7),
  primary_skill_code text not null,
  secondary_skill_codes text[] not null default '{}'::text[],
  question_role text not null,
  source_ref text not null,
  answer_contract jsonb not null default '{}'::jsonb,
  content_hash text not null,
  qa_math_status text not null default 'pending'
    check (qa_math_status in ('pending','passed','failed')),
  qa_language_status text not null default 'pending'
    check (qa_language_status in ('pending','passed','failed')),
  qa_technical_status text not null default 'pending'
    check (qa_technical_status in ('pending','passed','failed')),
  qa_tour_separation_status text not null default 'pending'
    check (qa_tour_separation_status in ('pending','passed','failed')),
  lifecycle_state text not null default 'draft'
    check (lifecycle_state in ('draft','approved','published','retired')),
  is_runtime_allowed boolean not null default false,
  approved_at timestamptz,
  published_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists practice_v2_question_meta_practice_skill_idx
  on private.practice_v2_question_meta(practice_no, primary_skill_code);

create index if not exists practice_v2_question_meta_runtime_idx
  on private.practice_v2_question_meta(is_runtime_allowed, lifecycle_state, practice_no);

create table if not exists private.practice_v2_diagnostic_catalog (
  diagnostic_code text primary key,
  release_version text not null,
  skill_code text not null,
  mistake_type text not null,
  inference_strength text not null
    check (inference_strength in ('specific','broad','unmapped')),
  feedback_ru text not null,
  feedback_uz text not null,
  feedback_en text not null,
  next_action_ru text not null,
  next_action_uz text not null,
  next_action_en text not null,
  approval_status text not null default 'draft'
    check (approval_status in ('draft','approved','retired')),
  is_runtime_allowed boolean not null default false,
  content_hash text not null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists practice_v2_diagnostic_catalog_skill_idx
  on private.practice_v2_diagnostic_catalog(skill_code, approval_status, is_runtime_allowed);

revoke all on table private.practice_v2_question_meta from anon, authenticated;
revoke all on table private.practice_v2_diagnostic_catalog from anon, authenticated;

comment on table private.practice_v2_question_meta is
'Private governed metadata for Mathematics P1 Practice v2 questions. Learner runtime may use only approved/published rows through server-side functions.';

comment on table private.practice_v2_diagnostic_catalog is
'Private governed catalog for deterministic Practice v2 diagnostic codes. AI cannot create or strengthen these diagnoses.';
