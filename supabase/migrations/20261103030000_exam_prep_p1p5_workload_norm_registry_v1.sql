-- Mathematics P1/P5 Package 2, 2026-11-03.
-- Curriculum-grounded *source register*, NOT invented official Cambridge hours.
-- Stage 0: one draft row per existing 81 canonical skills; all numeric norm
-- fields NULL until a source-backed independent academic review accepts each.
-- No modifications to learner evidence, published questions, sessions or profile.

create table private.exam_prep_skill_workload_norms_v1 (
  program_version_id bigint not null,
  skill_code text not null,
  component_code text not null check(component_code in ('P1','P5')),
  source_syllabus_section text not null,
  source_syllabus_url text not null,
  source_book_chapter text not null,
  source_prerequisites text not null,
  estimated_core_min_minutes integer,
  estimated_core_max_minutes integer,
  estimated_revision_min_minutes integer,
  estimated_revision_max_minutes integer,
  estimate_status text not null default 'unreviewed'
    check (estimate_status in ('unreviewed','under_review','approved','retired')),
  estimate_provenance text not null default 'pending_academic_review'
    check (estimate_provenance in ('pending_academic_review','iclub_syllabus_aligned_estimate')),
  methodology_notes text,
  revision integer not null default 1 check(revision>=1),
  reviewed_by text,
  reviewed_at timestamptz,
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key(program_version_id,skill_code),
  foreign key(program_version_id,skill_code)
    references private.exam_prep_syllabus_nodes(program_version_id,skill_code)
    on update restrict on delete restrict,
  constraint exam_prep_workload_norm_range_check check(
    (estimated_core_min_minutes is null or estimated_core_min_minutes between 5 and 1200) and
    (estimated_core_max_minutes is null or estimated_core_max_minutes between 5 and 2400) and
    (estimated_revision_min_minutes is null or estimated_revision_min_minutes between 0 and 1200) and
    (estimated_revision_max_minutes is null or estimated_revision_max_minutes between 0 and 2400) and
    (estimated_core_min_minutes is null or estimated_core_max_minutes is null or
      estimated_core_max_minutes>=estimated_core_min_minutes) and
    (estimated_revision_min_minutes is null or estimated_revision_max_minutes is null or
      estimated_revision_max_minutes>=estimated_revision_min_minutes)
  ),
  constraint exam_prep_workload_norm_approval_check check(
    estimate_status <> 'approved' or (
      estimate_provenance='iclub_syllabus_aligned_estimate' and
      estimated_core_min_minutes is not null and
      estimated_core_max_minutes is not null and
      estimated_revision_min_minutes is not null and
      estimated_revision_max_minutes is not null and
      nullif(btrim(coalesce(methodology_notes,'')),'') is not null and
      nullif(btrim(coalesce(reviewed_by,'')),'') is not null and
      nullif(btrim(coalesce(approved_by,'')),'') is not null and
      reviewed_at is not null and approved_at is not null and
      reviewed_by<>approved_by and reviewed_at<=approved_at
    )
  )
);

alter table private.exam_prep_skill_workload_norms_v1 enable row level security;
revoke all on private.exam_prep_skill_workload_norms_v1 from public,anon,authenticated;
comment on table private.exam_prep_skill_workload_norms_v1 is
'Internal versioned iClub workload estimates for 2026-27 Cambridge 9709 P1/P5 skills. Not Cambridge-published personal hours, cannot become approved without review and independent approval.';

-- Seed only canonical published-program syllabus sources already evidenced in
-- database. No hardcoded third-party book text or guessed skill hours.
insert into private.exam_prep_skill_workload_norms_v1(
  program_version_id,skill_code,component_code,
  source_syllabus_section,source_syllabus_url,source_book_chapter,
  source_prerequisites
)
select s.program_version_id,s.skill_code,s.component_code,
       s.official_syllabus_section,s.official_source_url,
       s.book_chapter,s.prerequisites_text
from private.exam_prep_syllabus_nodes s
join private.exam_prep_program_versions p on p.id=s.program_version_id
where p.program_key='math_as_p1_p5'
  and p.status='active'
  and s.component_code in ('P1','P5')
  and nullif(btrim(s.official_syllabus_section),'') is not null
  and nullif(btrim(s.official_source_url),'') is not null
  and nullif(btrim(s.book_chapter),'') is not null
  and s.prerequisites_text is not null
on conflict do nothing;

do $$
declare v_n int; v_p1 int; v_p5 int;
begin
  select count(*),count(*) filter(where component_code='P1'),
                  count(*) filter(where component_code='P5')
    into v_n,v_p1,v_p5
  from private.exam_prep_skill_workload_norms_v1 w
  join private.exam_prep_program_versions p on p.id=w.program_version_id
  where p.program_key='math_as_p1_p5' and p.status='active';
  -- Fail closed on unexpected source drift: do not silently advertise a
  -- complete quantitative recommendation without source coverage.
  if v_n<>81 or v_p1<>45 or v_p5<>36 then
    raise exception 'exam_prep_workload_registry_source_coverage_mismatch';
  end if;
end $$;

create or replace function public.get_exam_prep_workload_norm_status_safe_v1()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$
declare
  v_uid uuid;
  v_version bigint;
  v_payload jsonb := '{}'::jsonb;
  v_component text;
  v_expected int;
  v_total int;
  v_approved int;
  v_missing int;
  v_revision int;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  select program_version_id into v_version from private.exam_prep_exam_profiles
  where user_id=v_uid;
  if v_version is null then raise exception 'exam_prep_profile_required'; end if;

  foreach v_component in array array['P1','P5'] loop
    select count(*) into v_expected from private.exam_prep_syllabus_nodes s
    where s.program_version_id=v_version and s.component_code=v_component;
    select count(*)::int,
           count(*) filter(where w.estimate_status='approved' and
              w.estimated_core_min_minutes is not null and
              w.estimated_core_max_minutes is not null and
              w.estimated_revision_min_minutes is not null and
              w.estimated_revision_max_minutes is not null)::int,
           max(w.revision)::int
      into v_total,v_approved,v_revision
      from private.exam_prep_skill_workload_norms_v1 w
      where w.program_version_id=v_version and w.component_code=v_component;
    v_missing:=greatest(v_expected-coalesce(v_total,0),0);
    v_payload:=v_payload||jsonb_build_object(
      v_component,jsonb_build_object(
        'component_code',v_component,
        'skills_expected',v_expected,
        'norm_rows',v_total,
        'approved_norms',v_approved,
        'not_ready_norms',greatest(v_expected-v_approved,0),
        'missing_source_rows',v_missing,
        'norm_revision',v_revision,
        'status',case when v_expected>0 and v_total=v_expected and
                v_approved=v_expected then 'all_norms_academically_approved'
              else 'academic_review_incomplete' end,
        'norms_kind','internal_iclub_estimate_based_on_cambridge_syllabus',
        'official_cambridge_per_skill_hours',false,
        'personal_hour_recommendation_available',false
      )
    );
  end loop;
  return jsonb_build_object(
    'contract_version','exam_prep_workload_norm_status_v1',
    'P1',v_payload->'P1','P5',v_payload->'P5',
    'numeric_recommendation_enabled',false,
    'reason','Syllabus sources alone do not prove personalized per-skill study hours. Require independent academic-approved norms and an audited scheduling engine.',
    'no_grade_forecast',true,
    'no_study_time_cap',true
  );
end;
$function$;

revoke all on function public.get_exam_prep_workload_norm_status_safe_v1()
  from public,anon;
grant execute on function public.get_exam_prep_workload_norm_status_safe_v1()
  to authenticated,service_role;
