-- P2-03: Past Paper Companion metadata boundary.
-- Safe-by-design: stores only official external metadata/links plus references to
-- original iClub assessments. No Cambridge question text, diagrams, mark schemes,
-- examiner-report passages, answer keys, or private rubrics are stored here.

begin;

create table if not exists private.exam_prep_paper_metadata (
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check (component_code in ('P1','P5')),
  syllabus_code text not null default '9709' check (syllabus_code='9709'),
  paper_number smallint not null check (paper_number in (1,5)),
  resource_kind text not null check (resource_kind in ('official_past_paper_portal','official_paper_metadata')),
  exam_year smallint,
  exam_series text,
  variant_code text,
  official_url text not null,
  title_en text not null,
  title_ru text not null,
  title_uz text not null,
  notice_en text not null,
  notice_ru text not null,
  notice_uz text not null,
  rights_status text not null default 'metadata_only_external' check (rights_status='metadata_only_external'),
  publication_status text not null default 'draft' check (publication_status in ('draft','approved','retired')),
  provenance jsonb not null default '{}'::jsonb,
  source_checked_at timestamptz,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((component_code='P1' and paper_number=1) or (component_code='P5' and paper_number=5)),
  check (official_url like 'https://www.cambridgeinternational.org/%'),
  check ((resource_kind='official_past_paper_portal' and exam_year is null and exam_series is null and variant_code is null)
      or resource_kind='official_paper_metadata')
);

create unique index if not exists exam_prep_paper_metadata_identity_uidx
  on private.exam_prep_paper_metadata(
    program_version_id,component_code,resource_kind,
    coalesce(exam_year,0),coalesce(exam_series,''),coalesce(variant_code,'')
  );
create index if not exists exam_prep_paper_metadata_component_idx
  on private.exam_prep_paper_metadata(program_version_id,component_code,publication_status,resource_kind);

alter table private.exam_prep_paper_metadata enable row level security;
revoke all on private.exam_prep_paper_metadata from public,anon,authenticated;
grant select,insert,update on private.exam_prep_paper_metadata to service_role;
grant usage,select on sequence private.exam_prep_paper_metadata_id_seq to service_role;

do $$ begin
  create trigger exam_prep_paper_metadata_audit_v1
  after insert or update or delete on private.exam_prep_paper_metadata
  for each row execute function private.exam_prep_audit_row_change_v1();
exception when duplicate_object then null; end $$;

with pv as (
  select id from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active'
)
insert into private.exam_prep_paper_metadata(
  program_version_id,component_code,paper_number,resource_kind,official_url,
  title_en,title_ru,title_uz,notice_en,notice_ru,notice_uz,
  publication_status,provenance,source_checked_at,approved_at
)
select pv.id,'P1',1,'official_past_paper_portal',
  'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',
  'Official Cambridge past papers — Paper 1',
  'Официальные прошлые работы Cambridge — Paper 1',
  'Cambridge rasmiy oldingi imtihon ishlari — Paper 1',
  'Opens the official Cambridge 9709 resource page outside iClub. iClub does not copy the paper or mark scheme.',
  'Откроется официальная страница Cambridge 9709 вне iClub. iClub не копирует работу или схему оценивания.',
  'Cambridge 9709 rasmiy sahifasi iClub’dan tashqarida ochiladi. iClub imtihon ishini yoki baholash sxemasini ko‘chirmaydi.',
  'approved',jsonb_build_object('source','Cambridge International 9709 past papers page','copyright_boundary','metadata_and_external_link_only'),now(),now()
from pv
union all
select pv.id,'P5',5,'official_past_paper_portal',
  'https://www.cambridgeinternational.org/programmes-and-qualifications/cambridge-international-as-and-a-level-mathematics-9709/past-papers/',
  'Official Cambridge past papers — Paper 5',
  'Официальные прошлые работы Cambridge — Paper 5',
  'Cambridge rasmiy oldingi imtihon ishlari — Paper 5',
  'Opens the official Cambridge 9709 resource page outside iClub. iClub does not copy the paper or mark scheme.',
  'Откроется официальная страница Cambridge 9709 вне iClub. iClub не копирует работу или схему оценивания.',
  'Cambridge 9709 rasmiy sahifasi iClub’dan tashqarida ochiladi. iClub imtihon ishini yoki baholash sxemasini ko‘chirmaydi.',
  'approved',jsonb_build_object('source','Cambridge International 9709 past papers page','copyright_boundary','metadata_and_external_link_only'),now(),now()
from pv
on conflict do nothing;

create or replace function public.get_exam_prep_past_paper_companion_safe_v1(
  p_component_code text,
  p_language text default 'en'
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_lang text;
  v_external jsonb;
  v_full jsonb;
  v_similar jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_invalid_component'; end if;
  v_lang:=case when lower(coalesce(p_language,'')) in ('ru','uz','en') then lower(p_language) else 'en' end;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0' and status='active';
  if v_program is null then raise exception 'exam_prep_program_missing'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'resource_id',m.id,
    'resource_kind',m.resource_kind,
    'syllabus_code',m.syllabus_code,
    'component_code',m.component_code,
    'paper_number',m.paper_number,
    'exam_year',m.exam_year,
    'exam_series',m.exam_series,
    'variant_code',m.variant_code,
    'title',case v_lang when 'ru' then m.title_ru when 'uz' then m.title_uz else m.title_en end,
    'notice',case v_lang when 'ru' then m.notice_ru when 'uz' then m.notice_uz else m.notice_en end,
    'official_url',m.official_url,
    'rights_status',m.rights_status
  ) order by m.resource_kind,m.exam_year desc nulls last,m.exam_series,m.variant_code),'[]'::jsonb)
  into v_external
  from private.exam_prep_paper_metadata m
  where m.program_version_id=v_program and m.component_code=p_component_code and m.publication_status='approved';

  select coalesce(jsonb_agg(jsonb_build_object(
    'assessment_id',a.id,
    'assessment_key',a.assessment_key,
    'attempt_kind',t.attempt_kind,
    'marks_available',t.marks_available,
    'min_operational_stage',coalesce(t.min_operational_stage,3),
    'comparison_scope',t.comparison_scope,
    'is_original_iclub',true
  ) order by coalesce(t.min_operational_stage,3),a.id),'[]'::jsonb)
  into v_full
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv on cv.id=a.content_version_id and cv.program_version_id=v_program
  join private.exam_prep_timed_assessment_contracts t on t.assessment_id=a.id
  where a.component_code=p_component_code
    and a.status='published' and t.status='published'
    and t.attempt_kind='full_paper' and t.comparison_scope='full';

  select coalesce(jsonb_agg(jsonb_build_object(
    'assessment_id',a.id,
    'assessment_key',a.assessment_key,
    'attempt_kind',t.attempt_kind,
    'marks_available',t.marks_available,
    'min_operational_stage',coalesce(t.min_operational_stage,2),
    'comparison_scope',t.comparison_scope,
    'is_original_iclub',true
  ) order by case t.attempt_kind when 'timed_section' then 0 else 1 end,a.id),'[]'::jsonb)
  into v_similar
  from private.exam_prep_assessments a
  join private.exam_prep_content_versions cv on cv.id=a.content_version_id and cv.program_version_id=v_program
  join private.exam_prep_timed_assessment_contracts t on t.assessment_id=a.id
  where a.component_code=p_component_code
    and a.status='published' and t.status='published'
    and t.attempt_kind in ('timed_section','modified_paper');

  return jsonb_build_object(
    'component_code',p_component_code,
    'paper_number',case when p_component_code='P1' then 1 else 5 end,
    'external_resources',coalesce(v_external,'[]'::jsonb),
    'original_full_simulations',coalesce(v_full,'[]'::jsonb),
    'similar_practice',coalesce(v_similar,'[]'::jsonb),
    'copyright_boundary',jsonb_build_object(
      'stores_official_question_content',false,
      'stores_official_mark_schemes',false,
      'stores_official_answer_keys',false,
      'external_metadata_only',true
    )
  );
end;
$$;

revoke all on function public.get_exam_prep_past_paper_companion_safe_v1(text,text) from public,anon;
grant execute on function public.get_exam_prep_past_paper_companion_safe_v1(text,text) to authenticated,service_role;

do $$
declare v_bad int; v_rows int;
begin
  select count(*) into v_rows from private.exam_prep_paper_metadata where publication_status='approved';
  if v_rows<>2 then raise exception 'P2-03 expected exactly two approved official portal metadata rows, got %',v_rows; end if;

  select count(*) into v_bad
  from information_schema.columns
  where table_schema='private' and table_name='exam_prep_paper_metadata'
    and lower(column_name) in ('correct_answer','answer_key','mark_scheme','rubric','question_text','examiner_report');
  if v_bad<>0 then raise exception 'P2-03 protected-content column detected rows=%',v_bad; end if;

  select count(*) into v_bad
  from information_schema.role_table_grants
  where table_schema='private' and table_name='exam_prep_paper_metadata'
    and grantee in ('PUBLIC','anon','authenticated');
  if v_bad<>0 then raise exception 'P2-03 learner direct metadata-table grants rows=%',v_bad; end if;
end
$$;

commit;
