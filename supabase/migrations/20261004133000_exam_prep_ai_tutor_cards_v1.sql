-- Exam Prep AI Tutor Cards v1.
-- Separate learner-facing curated content from AI grounding source cards.
-- Additive only: no academic-state, entitlement, cohort, legacy or localStorage changes.

begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create table if not exists private.exam_prep_ai_tutor_cards (
  id uuid primary key default gen_random_uuid(),
  tutor_card_key text not null unique,
  component_code text not null check (component_code in ('P1','P5')),
  skill_code text not null,
  locale text not null check (locale in ('en','ru','uz')),
  content_version text not null,
  title text not null,
  main_explanation text not null,
  simple_explanation text not null,
  alternative_explanation text not null,
  focus_explanation text not null,
  source_card_key text not null
    references private.exam_prep_ai_source_cards(source_card_key)
    on update restrict on delete restrict,
  approval_status text not null default 'draft'
    check (approval_status in ('draft','approved','retired')),
  is_runtime_allowed boolean not null default false,
  content_hash text not null,
  approved_at timestamptz,
  approved_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint exam_prep_ai_tutor_cards_key_len
    check (char_length(tutor_card_key) between 3 and 180),
  constraint exam_prep_ai_tutor_cards_version_len
    check (char_length(content_version) between 1 and 120),
  constraint exam_prep_ai_tutor_cards_hash_len
    check (char_length(content_hash) between 16 and 160),
  constraint exam_prep_ai_tutor_cards_component_skill
    check (skill_code like component_code || '-%'),
  constraint exam_prep_ai_tutor_cards_runtime_requires_approval
    check ((not is_runtime_allowed) or approval_status='approved'),
  constraint exam_prep_ai_tutor_cards_approval_metadata
    check (
      (approval_status='approved' and approved_at is not null)
      or approval_status<>'approved'
    )
);

alter table private.exam_prep_ai_tutor_cards enable row level security;
alter table private.exam_prep_ai_tutor_cards force row level security;

create unique index if not exists exam_prep_ai_tutor_cards_version_uq
  on private.exam_prep_ai_tutor_cards(skill_code,locale,content_version);

create unique index if not exists exam_prep_ai_tutor_cards_runtime_uq
  on private.exam_prep_ai_tutor_cards(skill_code,locale)
  where is_runtime_allowed;

create index if not exists exam_prep_ai_tutor_cards_lookup_idx
  on private.exam_prep_ai_tutor_cards(component_code,skill_code,locale,approval_status,is_runtime_allowed);

revoke all on private.exam_prep_ai_tutor_cards from public,anon,authenticated;
grant select,insert,update,delete on private.exam_prep_ai_tutor_cards to service_role;

create or replace function public.get_exam_prep_ai_tutor_card_service_v1(
  p_component_code text,
  p_skill_code text,
  p_locale text
)
returns jsonb
language sql
stable
security definer
set search_path=''
as $fn$
  select coalesce((
    select jsonb_build_object(
      'tutor_card_key',c.tutor_card_key,
      'component_code',c.component_code,
      'skill_code',c.skill_code,
      'locale',c.locale,
      'content_version',c.content_version,
      'title',c.title,
      'main_explanation',c.main_explanation,
      'simple_explanation',c.simple_explanation,
      'alternative_explanation',c.alternative_explanation,
      'focus_explanation',c.focus_explanation,
      'source_card_key',c.source_card_key,
      'content_hash',c.content_hash
    )
    from private.exam_prep_ai_tutor_cards c
    where c.component_code=p_component_code
      and c.skill_code=p_skill_code
      and c.locale=lower(coalesce(p_locale,''))
      and c.approval_status='approved'
      and c.is_runtime_allowed
    limit 1
  ),'{}'::jsonb);
$fn$;

revoke all on function public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)
  from public,anon,authenticated;
grant execute on function public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)
  to service_role;

create or replace function public.get_exam_prep_ai_tutor_card_coverage_service_v1()
returns jsonb
language sql
stable
security definer
set search_path=''
as $fn$
  with canonical as (
    select n.component_code,n.skill_code
    from private.exam_prep_syllabus_nodes n
    join private.exam_prep_program_versions pv on pv.id=n.program_version_id
    where pv.program_key='math_as_p1_p5'
      and pv.version_key='p1_p5_canonical_v1_0'
      and pv.status='active'
  ),
  locales(locale) as (
    values ('en'::text),('ru'::text),('uz'::text)
  ),
  expected as (
    select c.component_code,c.skill_code,l.locale
    from canonical c cross join locales l
  ),
  actual as (
    select component_code,skill_code,locale
    from private.exam_prep_ai_tutor_cards
    where approval_status='approved' and is_runtime_allowed
  )
  select jsonb_build_object(
    'expected', (select count(*) from expected),
    'ready', (select count(*) from actual),
    'missing', (
      select count(*)
      from expected e
      left join actual a using(component_code,skill_code,locale)
      where a.skill_code is null
    ),
    'p1_ready', (select count(*) from actual where component_code='P1'),
    'p5_ready', (select count(*) from actual where component_code='P5')
  );
$fn$;

revoke all on function public.get_exam_prep_ai_tutor_card_coverage_service_v1()
  from public,anon,authenticated;
grant execute on function public.get_exam_prep_ai_tutor_card_coverage_service_v1()
  to service_role;

do $postcheck$
begin
  if to_regclass('private.exam_prep_ai_tutor_cards') is null then
    raise exception 'Tutor Card table missing';
  end if;

  if has_table_privilege('authenticated','private.exam_prep_ai_tutor_cards','SELECT')
     or has_table_privilege('anon','private.exam_prep_ai_tutor_cards','SELECT')
  then
    raise exception 'Tutor Card storage leaked to browser role';
  end if;

  if has_function_privilege(
      'authenticated',
      'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
      'EXECUTE'
    )
     or has_function_privilege(
      'anon',
      'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
      'EXECUTE'
    )
  then
    raise exception 'Tutor Card service lookup leaked to browser role';
  end if;

  if not has_function_privilege(
      'service_role',
      'public.get_exam_prep_ai_tutor_card_service_v1(text,text,text)',
      'EXECUTE'
    )
  then
    raise exception 'Tutor Card service lookup missing service_role access';
  end if;
end
$postcheck$;

commit;
