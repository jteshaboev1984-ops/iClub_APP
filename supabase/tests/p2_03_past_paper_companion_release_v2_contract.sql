-- P2-03 Past Paper Companion + original full simulations governed release contract v2.
-- Read-only acceptance gate. No synthetic users, no learner state mutation.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v_program bigint;
  v_bad int;
  v_p1_full int;
  v_p5_full int;
  v_p1_similar int;
  v_p5_similar int;
BEGIN
  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and status='active';
  if v_program is null then
    raise exception 'P2-03 v2 active canonical program missing';
  end if;

  if not exists(
    select 1 from private.exam_prep_product_roadmap_milestones
    where program_version_id=v_program
      and milestone_key='product_content_complete'
      and milestone_status='met'
      and product_label='Product Content-Complete'
      and can_force_learner_stage=false
      and can_raise_learner_mastery=false
      and can_label_learner_exam_ready=false
  ) then
    raise exception 'P2-03 v2 P2-01 dependency is not safely met';
  end if;

  if (select count(*) from private.exam_prep_paper_metadata
      where program_version_id=v_program
        and component_code in ('P1','P5')
        and resource_kind='official_past_paper_portal'
        and rights_status='metadata_only_external'
        and publication_status='approved'
        and source_level=4
        and official_url like 'https://www.cambridgeinternational.org/%'
        and nullif(btrim(title_en),'') is not null
        and nullif(btrim(title_ru),'') is not null
        and nullif(btrim(title_uz),'') is not null
        and nullif(btrim(notice_en),'') is not null
        and nullif(btrim(notice_ru),'') is not null
        and nullif(btrim(notice_uz),'') is not null)<>2
  then raise exception 'P2-03 v2 safe official metadata rows mismatch'; end if;

  if (select count(*) from private.exam_prep_paper_metadata
      where program_version_id=v_program and publication_status='approved' and component_code='P1')<>1
     or (select count(*) from private.exam_prep_paper_metadata
      where program_version_id=v_program and publication_status='approved' and component_code='P5')<>1
  then raise exception 'P2-03 v2 P1/P5 metadata symmetry mismatch'; end if;

  select count(*) into v_bad
  from information_schema.columns
  where table_schema='private'
    and table_name='exam_prep_paper_metadata'
    and lower(column_name) in (
      'question_text','question_text_en','question_text_ru','question_text_uz',
      'correct_answer','answer_key','mark_scheme','rubric','rubric_json','examiner_report'
    );
  if v_bad<>0 then
    raise exception 'P2-03 v2 protected-content column detected rows=%',v_bad;
  end if;

  if exists(
    select 1 from information_schema.role_table_grants
    where table_schema='private'
      and table_name='exam_prep_paper_metadata'
      and grantee in ('PUBLIC','anon','authenticated')
  ) then
    raise exception 'P2-03 v2 private metadata table exposed to learner roles';
  end if;

  if has_function_privilege('anon','public.get_exam_prep_past_paper_companion_safe_v1(text,text)','EXECUTE')
     or not has_function_privilege('authenticated','public.get_exam_prep_past_paper_companion_safe_v1(text,text)','EXECUTE')
  then
    raise exception 'P2-03 v2 companion RPC privilege boundary drift';
  end if;

  select
    count(*) filter(where p.component_code='P1' and t.attempt_kind='full_paper'),
    count(*) filter(where p.component_code='P5' and t.attempt_kind='full_paper'),
    count(*) filter(where p.component_code='P1' and t.attempt_kind in ('timed_section','modified_paper')),
    count(*) filter(where p.component_code='P5' and t.attempt_kind in ('timed_section','modified_paper'))
  into v_p1_full,v_p5_full,v_p1_similar,v_p5_similar
  from private.exam_prep_timed_assessment_contracts t
  join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
  join private.exam_prep_assessments a on a.id=t.assessment_id
  join private.exam_prep_content_versions cv on cv.id=a.content_version_id
  where p.program_version_id=v_program
    and p.component_code in ('P1','P5')
    and a.status='published'
    and t.status='published'
    and cv.status='published'
    and t.attempt_kind in ('timed_section','modified_paper','full_paper')
    and cv.source_policy like 'Original iClub-authored%';

  if v_p1_full<1 or v_p5_full<1 or v_p1_full<>v_p5_full then
    raise exception 'P2-03 v2 original full simulation symmetry mismatch P1=% P5=%',v_p1_full,v_p5_full;
  end if;
  if v_p1_similar<1 or v_p5_similar<1 or v_p1_similar<>v_p5_similar then
    raise exception 'P2-03 v2 Similar Practice symmetry mismatch P1=% P5=%',v_p1_similar,v_p5_similar;
  end if;

  select count(*) into v_bad
  from private.exam_prep_timed_assessment_contracts t
  join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
  join private.exam_prep_assessments a on a.id=t.assessment_id
  join private.exam_prep_content_versions cv on cv.id=a.content_version_id
  where p.program_version_id=v_program
    and t.status='published'
    and t.attempt_kind in ('timed_section','modified_paper','full_paper')
    and (
      a.status<>'published'
      or cv.status<>'published'
      or cv.source_policy not like 'Original iClub-authored%'
      or exists(
        select 1
        from private.exam_prep_assessment_items ai
        where ai.assessment_id=a.id
          and (ai.written_task_id is null or ai.question_id is not null)
      )
      or exists(
        select 1
        from private.exam_prep_assessment_items ai
        join private.exam_prep_written_tasks wt on wt.id=ai.written_task_id
        where ai.assessment_id=a.id
          and (
            wt.lifecycle_state<>'published'
            or wt.copyright_status<>'pass'
            or wt.qa_math_status<>'pass'
            or wt.qa_language_status<>'pass'
            or wt.qa_technical_status<>'pass'
            or nullif(btrim(wt.prompt_en),'') is null
            or nullif(btrim(wt.prompt_ru),'') is null
            or nullif(btrim(wt.prompt_uz),'') is null
            or jsonb_typeof(wt.rubric_json)<>'object'
          )
      )
    );
  if v_bad<>0 then
    raise exception 'P2-03 v2 original simulation/practice governance failed assessments=%',v_bad;
  end if;

  if exists(
    select 1
    from private.exam_prep_timed_assessment_contracts t
    join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
    join private.exam_prep_assessments a on a.id=t.assessment_id
    join private.exam_prep_content_versions cv on cv.id=a.content_version_id
    where p.program_version_id=v_program
      and t.attempt_kind in ('timed_section','modified_paper','full_paper')
      and t.status='published'
      and cv.source_policy !~* 'no protected question wording copied'
  ) then
    raise exception 'P2-03 v2 original-content source-policy attestation missing';
  end if;

  if (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P1'
        and t.status='published' and t.attempt_kind='full_paper'
        and t.comparison_scope='full' and t.strict_timing
        and t.marks_available=p.official_total_marks)<1
     or (select count(*) from private.exam_prep_timed_assessment_contracts t
      join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
      where p.program_version_id=v_program and p.component_code='P5'
        and t.status='published' and t.attempt_kind='full_paper'
        and t.comparison_scope='full' and t.strict_timing
        and t.marks_available=p.official_total_marks)<1
  then
    raise exception 'P2-03 v2 original full simulation paper-profile fidelity missing';
  end if;

  if exists(
    select 1
    from private.exam_prep_sessions s
    join private.exam_prep_assessments a on a.id=s.assessment_id
    join private.exam_prep_timed_assessment_contracts t on t.assessment_id=a.id
    join private.exam_prep_component_paper_profiles p on p.id=t.paper_profile_id
    where p.program_version_id=v_program
      and s.component_code<>a.component_code
  ) then
    raise exception 'P2-03 v2 historical component isolation drift';
  end if;
END
$$;

\echo 'P2-03 Past Paper Companion + original simulations release v2 contract: GREEN'
