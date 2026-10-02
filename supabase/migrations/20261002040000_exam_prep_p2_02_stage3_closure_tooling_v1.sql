-- P2-02 Stage 3 Syllabus Closure tooling v1.
--
-- Additive read-only learner API around the already-governed Stage-3 evaluator.
-- No evidence/mastery/stage/history mutation. P1 and P5 remain independent.
-- Product Content-Complete remains only a product dependency and cannot close
-- a learner component.
begin;
set local lock_timeout='3s';
set local statement_timeout='90s';

create or replace function private.exam_prep_stage3_closure_payload_v1(
  p_user_id uuid,
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_program bigint;
  v_stage3 jsonb;
  v_tracker jsonb;
  v_modified_available int:=0;
  v_full_available int:=0;
  v_modified_completed int:=0;
  v_full_completed int:=0;
begin
  if p_user_id is null or not exists(select 1 from public.users u where u.id=p_user_id) then
    raise exception 'exam_prep_stage3_closure_user_not_found' using errcode='P0002';
  end if;
  if p_component_code not in ('P1','P5') then
    raise exception 'exam_prep_bad_component';
  end if;

  select pv.id into v_program
  from private.exam_prep_program_versions pv
  where pv.program_key='math_as_p1_p5'
    and pv.version_key='p1_p5_canonical_v1_0'
    and pv.status='active';
  if v_program is null then
    raise exception 'exam_prep_stage3_closure_program_missing';
  end if;

  v_stage3:=private.exam_prep_stage3_exit_status_v1(
    p_user_id,v_program,p_component_code
  );
  v_tracker:=private.exam_prep_syllabus_tracker_payload_v1(
    p_user_id,p_component_code
  );

  select
    count(*) filter(where t.attempt_kind='modified_paper')::int,
    count(*) filter(where t.attempt_kind='full_paper')::int
  into v_modified_available,v_full_available
  from private.exam_prep_timed_assessment_contracts t
  join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
  join private.exam_prep_assessments a on a.id=t.assessment_id
  where p.program_version_id=v_program
    and p.component_code=p_component_code
    and p.status='published'
    and t.status='published'
    and a.status='published'
    and t.attempt_kind in ('modified_paper','full_paper');

  select
    count(*) filter(where t.attempt_kind='modified_paper')::int,
    count(*) filter(where t.attempt_kind='full_paper')::int
  into v_modified_completed,v_full_completed
  from private.exam_prep_timed_attempt_results t
  join private.exam_prep_sessions s on s.id=t.session_id
  where t.user_id=p_user_id
    and t.component_code=p_component_code
    and s.user_id=p_user_id
    and s.program_version_id=v_program
    and s.component_code=p_component_code
    and s.status='finalized'
    and t.attempt_kind in ('modified_paper','full_paper');

  return jsonb_build_object(
    'component_code',p_component_code,
    'program_version_id',v_program,
    'closure',v_stage3,
    'coverage_ledger',jsonb_build_object(
      'denominator_count',v_tracker->'denominator_count',
      'area_count',v_tracker->'area_count',
      'coverage_count',v_tracker->'coverage_count',
      'coverage_pct',v_tracker->'coverage_pct',
      'l0_count',v_tracker->'l0_count',
      'l1_count',v_tracker->'l1_count',
      'l2_count',v_tracker->'l2_count',
      'l3_count',v_tracker->'l3_count',
      'open_correction_count',v_tracker->'open_correction_count',
      'denominator_credit_for_support',false
    ),
    'baseline_workflow',jsonb_build_object(
      'modified_paper_available_count',v_modified_available,
      'full_paper_available_count',v_full_available,
      'modified_paper_completed_count',v_modified_completed,
      'full_paper_completed_count',v_full_completed,
      'comparable_full_baseline_count',v_stage3->'comparable_full_baseline_count',
      'comparable_full_baseline_required',true
    ),
    'gate_law',jsonb_build_object(
      'coverage_required_pct',100,
      'all_skills_min_level',2,
      'key_skills_min_level',3,
      'component_separate',true,
      'calendar_can_close',false,
      'product_content_complete_can_close',false,
      'cross_component_compensation',false
    )
  );
end;
$$;

revoke all on function private.exam_prep_stage3_closure_payload_v1(uuid,text)
  from public,anon,authenticated;
grant execute on function private.exam_prep_stage3_closure_payload_v1(uuid,text)
  to service_role;

create or replace function public.get_exam_prep_stage3_closure_safe_v1(
  p_component_code text
)
returns jsonb
language plpgsql
stable
security definer
set search_path=''
as $$
declare
  v_uid uuid;
begin
  v_uid:=private.exam_prep_require_core_access_v1();
  return private.exam_prep_stage3_closure_payload_v1(v_uid,p_component_code);
end;
$$;

revoke all on function public.get_exam_prep_stage3_closure_safe_v1(text)
  from public,anon;
grant execute on function public.get_exam_prep_stage3_closure_safe_v1(text)
  to authenticated,service_role;

do $postcheck$
declare
  v_rule private.exam_prep_stage3_exit_rules%rowtype;
  v_p1_keys int;
  v_p5_keys int;
  v_p1_sections int;
  v_p5_sections int;
  v_p1_modified int;
  v_p5_modified int;
  v_p1_full int;
  v_p5_full int;
begin
  select * into v_rule
  from private.exam_prep_stage3_exit_rules
  where status='active';

  if v_rule.rule_version is null
     or v_rule.min_all_skill_level<>2
     or v_rule.min_key_skill_level<>3
     or not v_rule.require_comparable_full_baseline
     or v_rule.key_registry_status<>'approved'
  then
    raise exception 'P2-02 active Stage-3 closure rule is not governed/approved';
  end if;

  select
    count(*) filter(where k.component_code='P1'),
    count(*) filter(where k.component_code='P5'),
    count(distinct n.official_syllabus_section) filter(where k.component_code='P1'),
    count(distinct n.official_syllabus_section) filter(where k.component_code='P5')
  into v_p1_keys,v_p5_keys,v_p1_sections,v_p5_sections
  from private.exam_prep_stage3_key_skills k
  join private.exam_prep_syllabus_nodes n
    on n.program_version_id=k.program_version_id
   and n.component_code=k.component_code
   and n.skill_code=k.skill_code
  where k.rule_version=v_rule.rule_version;

  if v_p1_keys<>8 or v_p5_keys<>7 or v_p1_sections<>8 or v_p5_sections<>5 then
    raise exception 'P2-02 key registry breadth drift P1 keys=% sections=% P5 keys=% sections=%',
      v_p1_keys,v_p1_sections,v_p5_keys,v_p5_sections;
  end if;

  if not exists(
    select 1 from private.exam_prep_stage3_key_skills k
    where k.rule_version=v_rule.rule_version
      and k.component_code='P5'
      and k.skill_code='P5-GEO-01'
  ) then
    raise exception 'P2-02 P5 geometric key-skill coverage missing';
  end if;

  select
    count(*) filter(where p.component_code='P1' and t.attempt_kind='modified_paper'),
    count(*) filter(where p.component_code='P5' and t.attempt_kind='modified_paper'),
    count(*) filter(where p.component_code='P1' and t.attempt_kind='full_paper'),
    count(*) filter(where p.component_code='P5' and t.attempt_kind='full_paper')
  into v_p1_modified,v_p5_modified,v_p1_full,v_p5_full
  from private.exam_prep_timed_assessment_contracts t
  join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
  join private.exam_prep_assessments a on a.id=t.assessment_id
  where p.program_version_id=(
      select id from private.exam_prep_program_versions
      where program_key='math_as_p1_p5'
        and version_key='p1_p5_canonical_v1_0'
        and status='active'
    )
    and p.status='published'
    and t.status='published'
    and a.status='published'
    and t.attempt_kind in ('modified_paper','full_paper');

  if v_p1_modified<1 or v_p5_modified<1 or v_p1_full<1 or v_p5_full<1 then
    raise exception 'P2-02 baseline workflow missing P1 modified=% full=% P5 modified=% full=%',
      v_p1_modified,v_p1_full,v_p5_modified,v_p5_full;
  end if;

  if to_regprocedure('private.exam_prep_stage3_closure_payload_v1(uuid,text)') is null
     or to_regprocedure('public.get_exam_prep_stage3_closure_safe_v1(text)') is null
     or to_regprocedure('public.get_exam_prep_syllabus_tracker_safe_v1(text)') is null
  then
    raise exception 'P2-02 Stage-3 closure/tracker API missing';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_stage3_closure_safe_v1(text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_stage3_closure_safe_v1(text)','EXECUTE')
  then
    raise exception 'P2-02 Stage-3 closure API privilege boundary drift';
  end if;
end
$postcheck$;

commit;
