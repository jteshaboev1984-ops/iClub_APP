-- P2-01: formal Product Content-Complete milestone gate.
-- Product-only governance transition. No learner stage/mastery/readiness or legacy history changes.
begin;
set local lock_timeout='3s';
set local statement_timeout='120s';

create table if not exists private.exam_prep_product_content_complete_audits(
  id bigint generated always as identity primary key,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  gate_version text not null,
  audit_status text not null check(audit_status='passed'),
  metrics jsonb not null,
  source_note text not null,
  audited_at timestamptz not null default now(),
  unique(program_version_id,gate_version)
);
alter table private.exam_prep_product_content_complete_audits enable row level security;
revoke all on private.exam_prep_product_content_complete_audits from public,anon,authenticated;
grant select on private.exam_prep_product_content_complete_audits to service_role;

do $gate$
declare
  v_program bigint;
  v_bad int;
  v_pct numeric;
  v_runway jsonb;
begin
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then raise exception 'p2_01 active canonical program missing'; end if;

  if (select count(*) from private.exam_prep_skill_contracts where program_version_id=v_program)<>81
     or (select count(*) from private.exam_prep_skill_contracts where program_version_id=v_program and component_code='P1')<>45
     or (select count(*) from private.exam_prep_skill_contracts where program_version_id=v_program and component_code='P5')<>36
     or (select count(*) from private.exam_prep_syllabus_nodes where program_version_id=v_program)<>81
     or (select count(*) from private.exam_prep_skill_contracts where program_version_id=v_program and skill_code in ('P5-GEO-01','P5-GEO-02','P5-GEO-03'))<>3
  then raise exception 'p2_01 canonical 45+36 coverage mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_skill_contracts s
  where s.program_version_id=v_program
    and not private.exam_prep_skill_content_ready_v1(s.program_version_id,s.component_code,s.skill_code);
  if v_bad<>0 then raise exception 'p2_01 content-ready skills failed=%',v_bad; end if;

  select count(*) into v_bad
  from (
    select s.skill_code,
      count(distinct m.id) filter(where cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role='diagnostic') d,
      count(distinct m.id) filter(where cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role='retest') r,
      count(distinct m.id) filter(where cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role in ('learning','mixed')) lx,
      count(distinct wt.id) filter(where wcv.status='published' and wt.lifecycle_state='published') w
    from private.exam_prep_skill_contracts s
    left join private.exam_prep_question_content_meta m on m.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    left join private.exam_prep_written_tasks wt on wt.primary_skill_code=s.skill_code
    left join private.exam_prep_content_versions wcv on wcv.id=wt.content_version_id
    where s.program_version_id=v_program
    group by s.skill_code
  ) x
  where d<3 or r<4 or lx<8 or w<2;
  if v_bad<>0 then raise exception 'p2_01 annual per-skill depth failed=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  join public.questions q on q.id=m.question_id
  where cv.program_version_id=v_program and cv.status='published' and m.lifecycle_state in ('published','reserve')
    and (
      m.copyright_status<>'pass' or m.qa_scope_status<>'pass' or m.qa_math_status<>'pass'
      or m.qa_language_status<>'pass' or m.qa_technical_status<>'pass'
      or nullif(btrim(m.originality_attestation),'') is null
      or nullif(btrim(m.provenance_note),'') is null
      or nullif(btrim(m.official_scope_ref),'') is null
      or nullif(btrim(m.coursebook_mapping_ref),'') is null
      or nullif(btrim(q.question_text_en),'') is null
      or nullif(btrim(q.question_text_ru),'') is null
      or nullif(btrim(q.question_text_uz),'') is null
      or nullif(btrim(q.explanation_en),'') is null
      or nullif(btrim(q.explanation_ru),'') is null
      or nullif(btrim(q.explanation_uz),'') is null
    );
  if v_bad<>0 then raise exception 'p2_01 machine governance/i18n/source rows=%',v_bad; end if;

  select count(*) into v_bad
  from private.exam_prep_written_tasks wt
  join private.exam_prep_content_versions cv on cv.id=wt.content_version_id
  where cv.program_version_id=v_program and cv.status='published' and wt.lifecycle_state='published'
    and (
      wt.copyright_status<>'pass' or wt.qa_math_status<>'pass'
      or wt.qa_language_status<>'pass' or wt.qa_technical_status<>'pass'
      or nullif(btrim(wt.prompt_en),'') is null or nullif(btrim(wt.prompt_ru),'') is null or nullif(btrim(wt.prompt_uz),'') is null
      or nullif(btrim(wt.self_review_en),'') is null or nullif(btrim(wt.self_review_ru),'') is null or nullif(btrim(wt.self_review_uz),'') is null
      or jsonb_typeof(wt.rubric_json)<>'object'
      or jsonb_typeof(wt.rubric_json->'criteria')<>'array'
      or jsonb_array_length(wt.rubric_json->'criteria')=0
    );
  if v_bad<>0 then raise exception 'p2_01 written governance/i18n/rubric rows=%',v_bad; end if;

  if (select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id
      where cv.program_version_id=v_program and cv.status='published' and m.lifecycle_state in ('published','reserve') and m.reserve_role='diagnostic')<>243
     or (select count(*) from private.exam_prep_diagnostic_rules r join private.exam_prep_question_content_meta m on m.id=r.content_meta_id
         join private.exam_prep_content_versions cv on cv.id=m.content_version_id
         where cv.program_version_id=v_program and cv.status='published' and m.reserve_role='diagnostic' and r.status='approved')<>729
  then raise exception 'p2_01 diagnostic/rule cardinality mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_question_content_meta m
  join private.exam_prep_content_versions cv on cv.id=m.content_version_id
  join public.questions q on q.id=m.question_id
  where cv.program_version_id=v_program and cv.status='published' and m.reserve_role='diagnostic'
    and (q.qtype<>'mcq' or m.diagnostic_rule_status<>'approved'
      or (select count(*) from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.status='approved' and r.answer_kind='mcq_option'
            and r.answer_match<>q.correct_answer and r.weak_skill_code=m.primary_skill_code)<>3
      or exists(select 1 from private.exam_prep_diagnostic_rules r
          where r.content_meta_id=m.id and r.status='approved' and r.answer_match=q.correct_answer));
  if v_bad<>0 then raise exception 'p2_01 diagnostic metadata failed=%',v_bad; end if;

  if (select count(*) from private.exam_prep_mixed_nodes where program_version_id=v_program)<>23
     or (select count(*) from private.exam_prep_mixed_nodes where program_version_id=v_program and owner_component_code in ('P1','P5'))<>21
     or (select count(*) from private.exam_prep_mixed_nodes where program_version_id=v_program and owner_component_code is null)<>2
     or exists(select 1 from private.exam_prep_mixed_nodes where program_version_id=v_program and denominator_credit)
  then raise exception 'p2_01 mixed-node registry mismatch'; end if;

  select count(*) into v_bad
  from private.exam_prep_mixed_nodes n
  where n.program_version_id=v_program and n.owner_component_code in ('P1','P5')
    and not exists(
      select 1 from private.exam_prep_assessment_mixed_nodes am
      join private.exam_prep_assessments a on a.id=am.assessment_id
      where am.program_version_id=n.program_version_id and am.mixed_code=n.mixed_code
        and am.component_code=n.owner_component_code and a.component_code=n.owner_component_code and a.status='published'
    );
  if v_bad<>0 then raise exception 'p2_01 same-component mixed coverage failed=%',v_bad; end if;

  if exists(
    select 1 from private.exam_prep_mixed_nodes n
    join private.exam_prep_mixed_links l on l.program_version_id=n.program_version_id and l.mixed_code=n.mixed_code
    where n.program_version_id=v_program and n.owner_component_code in ('P1','P5')
      and l.linked_node_kind='skill' and l.linked_component_code<>n.owner_component_code
  ) or exists(
    select 1 from private.exam_prep_mixed_nodes n
    join private.exam_prep_assessment_mixed_nodes am on am.program_version_id=n.program_version_id and am.mixed_code=n.mixed_code
    where n.program_version_id=v_program and n.owner_component_code is null
  ) then raise exception 'p2_01 mixed component firewall failed'; end if;

  if (select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P1' and t.status='published' and t.attempt_kind='timed_section' and t.strict_timing)<2
     or (select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P5' and t.status='published' and t.attempt_kind='timed_section' and t.strict_timing)<2
     or (select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P1' and t.status='published' and t.attempt_kind='full_paper' and t.strict_timing and t.timing_rule='official_full' and t.comparison_scope='full')<1
     or (select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P5' and t.status='published' and t.attempt_kind='full_paper' and t.strict_timing and t.timing_rule='official_full' and t.comparison_scope='full')<1
  then raise exception 'p2_01 timed/full-cycle capacity missing'; end if;

  if (select count(*) from private.exam_prep_paper_metadata
      where program_version_id=v_program and component_code in ('P1','P5')
        and resource_kind='official_past_paper_portal' and rights_status='metadata_only_external'
        and publication_status='approved' and source_level=4)<>2
  then raise exception 'p2_01 Past Paper Companion metadata-only gate failed'; end if;

  with candidate as (
    select m.id from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    where cv.program_version_id=v_program and cv.status='published'
      and m.lifecycle_state in ('published','reserve') and m.reserve_role in ('retest','mixed')
  ), unseen as (
    select c.id from candidate c
    where not exists(select 1 from private.exam_prep_session_items si where si.content_meta_id=c.id)
  )
  select round(100.0*(select count(*) from unseen)/nullif((select count(*) from candidate),0),2)
  into v_pct;
  if coalesce(v_pct,0)<20 then raise exception 'p2_01 unseen reserve below 20%%: %',v_pct; end if;

  if not exists(select 1 from private.exam_prep_written_tasks where lifecycle_state='published' and
      (prompt_en ~* '\m(graph|sketch|diagram)\M' or rubric_json::text ~* '\m(graph|sketch|diagram)\M'))
     or not exists(select 1 from private.exam_prep_written_tasks where lifecycle_state='published' and
      (prompt_en ~* '\m(explain|justify|interpret|comment|conclusion|context)\M' or rubric_json::text ~* '\m(explain|justify|interpret|comment|conclusion|context|communication)\M'))
     or not exists(select 1 from private.exam_prep_written_tasks where lifecycle_state='published'
      and jsonb_typeof(rubric_json->'criteria')='array' and jsonb_array_length(rubric_json->'criteria')>=2)
  then raise exception 'p2_01 mentor written/graph/multipart/AO2 library gate failed'; end if;

  if not exists(
    select 1 from pg_constraint c join pg_class t on t.oid=c.conrelid join pg_namespace n on n.oid=t.relnamespace
    where n.nspname='private' and t.relname='exam_prep_mentor_queue_items' and c.contype='c'
      and pg_get_constraintdef(c.oid) like '%written_mastery%'
      and pg_get_constraintdef(c.oid) like '%graph_review%'
      and pg_get_constraintdef(c.oid) like '%mixed_timed_review%'
  ) then raise exception 'p2_01 mentor review queue contract missing'; end if;

  if (select count(*) from private.exam_prep_source_registry)=0
     or (select count(*) from private.exam_prep_question_mapping_versions)=0
     or (select count(*) from private.exam_prep_content_versions where program_version_id=v_program and status='published')=0
  then raise exception 'p2_01 version/source audit trail missing'; end if;

  v_runway:=public.get_exam_prep_content_runway_v1(24::smallint);
  if coalesce((v_runway->'components'->'P1'->>'ready_through_aw')::int,0)<24
     or coalesce((v_runway->'components'->'P5'->>'ready_through_aw')::int,0)<24
  then raise exception 'p2_01 terminal AW24 runway not complete'; end if;

  if not exists(
    select 1 from private.exam_prep_product_roadmap_milestones
    where program_version_id=v_program and milestone_key='product_content_complete'
      and milestone_kind='product_content_complete' and product_label='Product Content-Complete'
      and can_force_learner_stage=false and can_raise_learner_mastery=false and can_label_learner_exam_ready=false
  ) then raise exception 'p2_01 product/learner firewall missing'; end if;

  insert into private.exam_prep_product_content_complete_audits(
    program_version_id,gate_version,audit_status,metrics,source_note
  )
  values(
    v_program,'p2_01_product_content_complete_v1','passed',
    jsonb_build_object(
      'skills_total',81,'skills_p1',45,'skills_p5',36,'content_ready_skills',81,
      'annual_min_diagnostic',3,'annual_min_retest',4,'annual_min_learning_transfer',8,'annual_min_written',2,
      'governed_machine_questions',(select count(*) from private.exam_prep_question_content_meta m join private.exam_prep_content_versions cv on cv.id=m.content_version_id where cv.program_version_id=v_program and cv.status='published' and m.lifecycle_state in ('published','reserve')),
      'governed_written_tasks',(select count(*) from private.exam_prep_written_tasks wt join private.exam_prep_content_versions cv on cv.id=wt.content_version_id where cv.program_version_id=v_program and cv.status='published' and wt.lifecycle_state='published'),
      'diagnostic_items',243,'approved_diagnostic_rules',729,
      'mixed_nodes_total',23,'same_component_mixed_nodes',21,'cross_prerequisite_nodes',2,
      'p1_timed_sections',(select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id where p.program_version_id=v_program and p.component_code='P1' and t.status='published' and t.attempt_kind='timed_section'),
      'p5_timed_sections',(select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id where p.program_version_id=v_program and p.component_code='P5' and t.status='published' and t.attempt_kind='timed_section'),
      'p1_full_papers',(select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id where p.program_version_id=v_program and p.component_code='P1' and t.status='published' and t.attempt_kind='full_paper'),
      'p5_full_papers',(select count(*) from private.exam_prep_timed_assessment_contracts t join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id where p.program_version_id=v_program and p.component_code='P5' and t.status='published' and t.attempt_kind='full_paper'),
      'past_paper_companion_rows',2,'never_exposed_transfer_retest_pct',v_pct,
      'annual_holdout_rotation_target_pct','20-25',
      'product_content_complete_is_syllabus_closure',false,
      'product_content_complete_is_learner_exam_ready',false
    ),
    'Formal P2-01 product/content audit. Operational 600/10 and service-transition capacity remains an independent CI/release gate; this milestone never changes learner evidence, mastery, stage or readiness.'
  )
  on conflict(program_version_id,gate_version) do nothing;

  update private.exam_prep_product_roadmap_milestones
  set milestone_status='met',updated_at=now()
  where program_version_id=v_program and milestone_key='product_content_complete'
    and milestone_kind='product_content_complete' and product_label='Product Content-Complete'
    and milestone_status in ('scheduled','held')
    and can_force_learner_stage=false and can_raise_learner_mastery=false and can_label_learner_exam_ready=false;
end
$gate$;

do $postcheck$
begin
  if not exists(select 1 from private.exam_prep_product_content_complete_audits
    where gate_version='p2_01_product_content_complete_v1' and audit_status='passed')
     or not exists(select 1 from private.exam_prep_product_roadmap_milestones
    where milestone_key='product_content_complete' and milestone_status='met'
      and product_label='Product Content-Complete'
      and can_force_learner_stage=false and can_raise_learner_mastery=false and can_label_learner_exam_ready=false)
  then raise exception 'p2_01 Product Content-Complete final state missing'; end if;

  if exists(select 1 from private.exam_prep_product_roadmap_milestones
    where lower(product_label) like '%as ready%' or lower(product_label) like '%exam ready%')
  then raise exception 'p2_01 forbidden learner-readiness product label'; end if;
end
$postcheck$;

commit;
