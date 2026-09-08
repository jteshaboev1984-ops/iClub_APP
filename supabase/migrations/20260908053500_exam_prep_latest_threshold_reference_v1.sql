-- P2-05 latest official Cambridge threshold reference v1.
-- Stores the latest published Zone-4 component thresholds as learner-visible reference metadata only.
-- IMPORTANT: this migration does NOT approve a Stage-5 readiness threshold and therefore cannot unlock READY.
-- P1/P5 remain separate; no combined 12+52 threshold is used for cross-component compensation.

begin;

create table if not exists private.exam_prep_threshold_references (
  id bigint generated always as identity primary key,
  reference_version text not null,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  paper_code text not null,
  exam_series text not null,
  series_sort_key date not null,
  target_grade text not null check(upper(target_grade) in ('A','B','C','D','E')),
  raw_threshold_mark smallint not null check(raw_threshold_mark>=0),
  maximum_raw_mark smallint not null check(maximum_raw_mark>0 and raw_threshold_mark<=maximum_raw_mark),
  status text not null default 'active' check(status in ('active','retired')),
  source_url text not null,
  incident_url text null,
  special_note_code text not null,
  source_note text not null,
  created_at timestamptz not null default now(),
  unique(reference_version,program_version_id,component_code,target_grade)
);

create unique index if not exists exam_prep_threshold_references_one_active_idx
  on private.exam_prep_threshold_references(program_version_id,component_code,upper(target_grade))
  where status='active';

alter table private.exam_prep_threshold_references enable row level security;
revoke all on private.exam_prep_threshold_references from public,anon,authenticated;
grant all on private.exam_prep_threshold_references to service_role;
grant usage,select on sequence private.exam_prep_threshold_references_id_seq to service_role;

do $$ begin
  execute 'create trigger exam_prep_threshold_references_audit_v1 after insert or update or delete on private.exam_prep_threshold_references for each row execute function private.exam_prep_audit_row_change_v1()';
exception when duplicate_object then null;
end $$;

update private.exam_prep_threshold_references
set status='retired'
where status='active'
  and reference_version<>'cambridge_9709_june_2026_zone4_reference_v1';

with active_program as (
  select id
  from private.exam_prep_program_versions
  where status='active'
  order by created_at desc,id desc
  limit 1
), rows(component_code,paper_code,target_grade,raw_mark,max_mark,special_note_code,incident_url) as (
  values
    ('P1','9709/12','A',61,75,'paper12_replacement','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/'),
    ('P1','9709/12','B',51,75,'paper12_replacement','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/'),
    ('P1','9709/12','C',37,75,'paper12_replacement','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/'),
    ('P1','9709/12','D',23,75,'paper12_replacement','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/'),
    ('P1','9709/12','E',10,75,'paper12_replacement','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-level-mathematics-june-2026-exam-series/'),
    ('P5','9709/52','A',41,50,'paper52_assessed_marks','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/'),
    ('P5','9709/52','B',35,50,'paper52_assessed_marks','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/'),
    ('P5','9709/52','C',28,50,'paper52_assessed_marks','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/'),
    ('P5','9709/52','D',21,50,'paper52_assessed_marks','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/'),
    ('P5','9709/52','E',13,50,'paper52_assessed_marks','https://www.cambridgeinternational.org/exam-administration/cambridge-exams-officers-guide/update-a-s-a-level-mathematics-june-2026-exam-series-paper-52/')
)
insert into private.exam_prep_threshold_references(
  reference_version,program_version_id,component_code,paper_code,exam_series,series_sort_key,
  target_grade,raw_threshold_mark,maximum_raw_mark,status,source_url,incident_url,special_note_code,source_note
)
select
  'cambridge_9709_june_2026_zone4_reference_v1',
  p.id,
  r.component_code,
  r.paper_code,
  'June 2026',
  date '2026-06-01',
  r.target_grade,
  r.raw_mark,
  r.max_mark,
  'active',
  'https://www.cambridgeinternational.org/Images/761530-mathematics-9709-june-2026-grade-threshold-table.pdf',
  r.incident_url,
  r.special_note_code,
  'Latest published official Cambridge 9709 component threshold available to iClub on 2026-09-08 for the Zone-4 P1/P5 route. Reference only: it is not a prediction or guarantee for a future exam series, no 5-10 percentage-point iClub buffer is added, and it is not an approved Stage-5 readiness gate. June 2026 had special security handling: 9709/12 was replaced in zones 3/4 and 9709/52 used assessed marks in zones 3/4. P1 and P5 remain separate.'
from active_program p
cross join rows r
on conflict(reference_version,program_version_id,component_code,target_grade)
do update set
  paper_code=excluded.paper_code,
  exam_series=excluded.exam_series,
  series_sort_key=excluded.series_sort_key,
  raw_threshold_mark=excluded.raw_threshold_mark,
  maximum_raw_mark=excluded.maximum_raw_mark,
  status='active',
  source_url=excluded.source_url,
  incident_url=excluded.incident_url,
  special_note_code=excluded.special_note_code,
  source_note=excluded.source_note;

create or replace function private.exam_prep_latest_threshold_reference_v1(
  p_program_version_id bigint,
  p_component_code text,
  p_target_grade text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_row private.exam_prep_threshold_references%rowtype;
  v_grade text:=upper(trim(coalesce(p_target_grade,'')));
begin
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select * into v_row
  from private.exam_prep_threshold_references r
  where r.program_version_id=p_program_version_id
    and r.component_code=p_component_code
    and r.status='active'
    and upper(r.target_grade)=v_grade
  order by r.series_sort_key desc,r.created_at desc,r.id desc
  limit 1;

  if v_row.id is null then
    return jsonb_build_object(
      'available',false,
      'component_code',p_component_code,
      'target_grade',nullif(v_grade,''),
      'reference_only',true,
      'readiness_gate_active',false
    );
  end if;

  return jsonb_build_object(
    'available',true,
    'reference_version',v_row.reference_version,
    'component_code',v_row.component_code,
    'paper_code',v_row.paper_code,
    'exam_series',v_row.exam_series,
    'target_grade',upper(v_row.target_grade),
    'raw_threshold_mark',v_row.raw_threshold_mark,
    'maximum_raw_mark',v_row.maximum_raw_mark,
    'threshold_pct',round(100.0*v_row.raw_threshold_mark/nullif(v_row.maximum_raw_mark,0),2),
    'source_url',v_row.source_url,
    'incident_url',v_row.incident_url,
    'special_note_code',v_row.special_note_code,
    'reference_only',true,
    'readiness_gate_active',false,
    'no_cross_component_compensation',true
  );
end;
$$;

revoke all on function private.exam_prep_latest_threshold_reference_v1(bigint,text,text) from public,anon,authenticated;
grant execute on function private.exam_prep_latest_threshold_reference_v1(bigint,text,text) to service_role;

create or replace function public.get_exam_prep_readiness_safe_v1(p_component_code text)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
  v_program bigint;
  v_target_grade text;
  v_result jsonb;
  v_reference jsonb;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  if p_component_code not in ('P1','P5') then raise exception 'exam_prep_bad_component'; end if;

  select program_version_id,target_grade
  into v_program,v_target_grade
  from private.exam_prep_exam_profiles
  where user_id=v_uid;

  if v_program is null then raise exception 'exam_prep_profile_required'; end if;

  v_result:=private.exam_prep_stage5_readiness_status_v1(v_uid,v_program,p_component_code);
  v_reference:=private.exam_prep_latest_threshold_reference_v1(v_program,p_component_code,v_target_grade);

  return (v_result - 'threshold_version') || jsonb_build_object('threshold_reference',v_reference);
end;
$$;

revoke execute on function public.get_exam_prep_readiness_safe_v1(text) from public,anon;
grant execute on function public.get_exam_prep_readiness_safe_v1(text) to authenticated,service_role;

do $$
declare
  v_program bigint;
  v_count int;
  v_approved int;
  v_p1 jsonb;
  v_p5 jsonb;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where status='active'
  order by created_at desc,id desc
  limit 1;

  select count(*) into v_count
  from private.exam_prep_threshold_references
  where program_version_id=v_program and status='active';
  if v_count<>10 then
    raise exception 'Threshold reference v1: expected 10 active P1/P5 grade rows, got %',v_count;
  end if;

  v_p1:=private.exam_prep_latest_threshold_reference_v1(v_program,'P1','A');
  v_p5:=private.exam_prep_latest_threshold_reference_v1(v_program,'P5','A');
  if (v_p1->>'raw_threshold_mark')::int<>61 or (v_p1->>'maximum_raw_mark')::int<>75 then
    raise exception 'Threshold reference v1: P1 A reference mismatch';
  end if;
  if (v_p5->>'raw_threshold_mark')::int<>41 or (v_p5->>'maximum_raw_mark')::int<>50 then
    raise exception 'Threshold reference v1: P5 A reference mismatch';
  end if;

  select count(*) into v_approved
  from private.exam_prep_stage5_thresholds
  where status='approved';
  if v_approved<>0 then
    raise exception 'Threshold reference v1: reference release must not approve Stage-5 readiness thresholds';
  end if;
end $$;

commit;
