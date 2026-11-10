-- iClub subject AI content expansion — governed WORKPLAN ONLY (2026-10-08).
-- Additive, private, non-runtime tracking. NO legacy assessment/learner/AI config changes.
begin;
set local lock_timeout = '3s';
set local statement_timeout = '45s';

create table if not exists private.iclub_subject_ai_content_workplan_v1 (
  plan_key text primary key,
  plan_version text not null,
  document_path text not null,
  status text not null default 'active'
    check (status in ('active','completed','cancelled')),
  execution_scope text[] not null,
  deferred_scope text[] not null,
  academic_authority text not null,
  release_authorized boolean not null default false
    check (release_authorized = false),
  notes text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists private.iclub_subject_ai_content_stages_v1 (
  plan_key text not null references private.iclub_subject_ai_content_workplan_v1(plan_key)
    on update restrict on delete restrict,
  subject_key text not null
    check (subject_key in ('economics','chemistry','biology','informatics')),
  stage_no smallint not null check (stage_no between 0 and 6),
  stage_title text not null,
  status text not null default 'planned'
    check (status in ('planned','in_progress','blocked','completed','deferred')),
  evidence_path text,
  notes text not null default '',
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (plan_key,subject_key,stage_no),
  constraint subject_ai_defer_informatics_only
    check ((subject_key='informatics' and stage_no=0 and status='deferred')
           or (subject_key<>'informatics' and stage_no between 1 and 6))
);

alter table private.iclub_subject_ai_content_workplan_v1 enable row level security;
alter table private.iclub_subject_ai_content_workplan_v1 force row level security;
alter table private.iclub_subject_ai_content_stages_v1 enable row level security;
alter table private.iclub_subject_ai_content_stages_v1 force row level security;

revoke all on private.iclub_subject_ai_content_workplan_v1 from public,anon,authenticated;
revoke all on private.iclub_subject_ai_content_stages_v1 from public,anon,authenticated;
grant select,insert,update,delete on private.iclub_subject_ai_content_workplan_v1 to service_role;
grant select,insert,update,delete on private.iclub_subject_ai_content_stages_v1 to service_role;

insert into private.iclub_subject_ai_content_workplan_v1
 (plan_key,plan_version,document_path,status,execution_scope,deferred_scope,academic_authority,release_authorized,notes)
values (
 'subject_ai_content_expansion_v1',
 'v1.0_2026_10_08',
 'docs/subject-ai-content-expansion-master-plan-v1.md',
 'active',
 array['economics','chemistry','biology'],
 array['informatics'],
 'Current official Cambridge subject syllabus for the chosen qualification/exam year > internal canonical map > supplied coursebooks > Tour Map > legacy question metadata.',
 false,
 'Persistent until completed. Informatics scope on hold pending syllabus choice. All production AI and learner-state changes forbidden without separate approval.'
) on conflict(plan_key) do nothing;

with stages(stage_no, stage_title) as (
  values
   (1,'Academic syllabus/source/skill map'),
   (2,'Original RU/UZ/EN theory cards'),
   (3,'RU/UZ/EN learner-first Tutor Cards'),
   (4,'Practice explanations and deterministic diagnostics'),
   (5,'Academic, language, safety and regression QA'),
   (6,'Separate additive integration and release decision')
), subjects(subject_key) as (
  values ('economics'),('chemistry'),('biology')
)
insert into private.iclub_subject_ai_content_stages_v1
 (plan_key,subject_key,stage_no,stage_title,status,evidence_path,notes,started_at)
select
 'subject_ai_content_expansion_v1', sub.subject_key, st.stage_no, st.stage_title,
 case when sub.subject_key='economics' and st.stage_no=1 then 'in_progress' else 'planned' end,
 case when sub.subject_key='economics' and st.stage_no=1 then 'docs/economics-subject-ai-source-audit-v1.md' else null end,
 case when sub.subject_key='economics' and st.stage_no=1
   then 'Started with read-only source/bank reconciliation; canonical syllabus mapping still pending.'
   else 'Do not start until prior stage gate is met.' end,
 case when sub.subject_key='economics' and st.stage_no=1 then now() else null end
from subjects sub cross join stages st
on conflict(plan_key,subject_key,stage_no) do nothing;

insert into private.iclub_subject_ai_content_stages_v1
  (plan_key,subject_key,stage_no,stage_title,status,notes)
values
 ('subject_ai_content_expansion_v1','informatics',0,'Syllabus decision pending','deferred',
  'No Informatics/Computer Science implementation until architect approves 9618 vs 0478 and source alignment.')
on conflict(plan_key,subject_key,stage_no) do nothing;

do $verify$
declare v int;
begin
  select count(*) into v from private.iclub_subject_ai_content_stages_v1
    where plan_key='subject_ai_content_expansion_v1';
  if v <> 19 then raise exception 'Unexpected stage row count: %',v; end if;
  if has_table_privilege('anon','private.iclub_subject_ai_content_workplan_v1','SELECT')
     or has_table_privilege('authenticated','private.iclub_subject_ai_content_workplan_v1','SELECT')
     or has_table_privilege('anon','private.iclub_subject_ai_content_stages_v1','SELECT')
     or has_table_privilege('authenticated','private.iclub_subject_ai_content_stages_v1','SELECT')
  then raise exception 'Plan tracker exposed to browser roles'; end if;
end
$verify$;
commit;
