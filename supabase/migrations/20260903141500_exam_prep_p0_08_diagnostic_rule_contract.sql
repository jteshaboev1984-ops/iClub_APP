-- P0-08: private, versioned diagnostic interpretation rules for Exam Prep content.
-- Rules are never client-readable before/after answer except via later safe response projection.

begin;
create table if not exists private.exam_prep_diagnostic_rules (
  id bigint generated always as identity primary key,
  content_meta_id bigint not null references private.exam_prep_question_content_meta(id) on delete cascade,
  rule_version text not null,
  answer_kind text not null check(answer_kind in ('mcq_option','exact_input','fallback')),
  answer_match text not null,
  distractor_code text null,
  mistake_type text not null,
  weak_skill_code text not null,
  feedback_en text not null,feedback_ru text not null,feedback_uz text not null,
  next_action_en text not null,next_action_ru text not null,next_action_uz text not null,
  status text not null default 'draft' check(status in ('draft','reviewed','approved','retired')),
  created_at timestamptz not null default now(),approved_at timestamptz null,
  unique(content_meta_id,rule_version,answer_kind,answer_match)
);
alter table private.exam_prep_diagnostic_rules enable row level security;
revoke all on private.exam_prep_diagnostic_rules from public,anon,authenticated;
grant all on private.exam_prep_diagnostic_rules to service_role;
grant usage,select on sequence private.exam_prep_diagnostic_rules_id_seq to service_role;
do $$ begin execute 'create trigger exam_prep_diagnostic_rules_audit_v1 after insert or update or delete on private.exam_prep_diagnostic_rules for each row execute function private.exam_prep_audit_row_change_v1()'; exception when duplicate_object then null; end $$;
commit;
