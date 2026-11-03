-- Package 2 real migrated PostgreSQL source-quality acceptance.
-- Read-only: inspect the actual 81 canonical syllabus-mapped rows. Never
-- create synthetic students, grade learners or fabricate recommended minutes.
\set ON_ERROR_STOP on
DO $$
declare
  v_expected int;
  v_total int;
  v_p1 int;
  v_p5 int;
  v_no_source int;
  v_nonzero_norms int;
  v_reviewed int;
begin
  select count(*)::int into v_expected
    from private.exam_prep_syllabus_nodes s
    join private.exam_prep_program_versions p on p.id=s.program_version_id
    where p.program_key='math_as_p1_p5' and p.status='active'
      and s.component_code in ('P1','P5');
  select count(*)::int,
         count(*) filter(where w.component_code='P1')::int,
         count(*) filter(where w.component_code='P5')::int,
         count(*) filter(where nullif(btrim(w.source_book_chapter),'') is null
            or nullif(btrim(w.source_syllabus_section),'') is null
            or nullif(btrim(w.source_syllabus_url),'') is null)::int,
         count(*) filter(where w.estimated_core_min_minutes is not null
           or w.estimated_core_max_minutes is not null
           or w.estimated_revision_min_minutes is not null
           or w.estimated_revision_max_minutes is not null)::int,
         count(*) filter(where w.estimate_status<>'unreviewed')::int
    into v_total,v_p1,v_p5,v_no_source,v_nonzero_norms,v_reviewed
    from private.exam_prep_skill_workload_norms_v1 w
    join private.exam_prep_program_versions p on p.id=w.program_version_id
    where p.program_key='math_as_p1_p5' and p.status='active';
  if v_expected<>81 or v_total<>81 or v_p1<>45 or v_p5<>36 or
     v_no_source<>0 or v_nonzero_norms<>0 or v_reviewed<>0 then
    raise exception 'P2 FAIL: 81 skills must be source-bound, entirely unreviewed and without invented hour norms';
  end if;
  if (select count(*) from private.exam_prep_historical_topic_teaching_refs_v1 h
       join private.exam_prep_program_versions p on p.id=h.program_version_id
       where p.program_key='math_as_p1_p5' and p.status='active') <> 13 or
     (select coalesce(sum(h.suggested_guided_teaching_hours),0)
       from private.exam_prep_historical_topic_teaching_refs_v1 h
       join private.exam_prep_program_versions p on p.id=h.program_version_id
       where p.program_key='math_as_p1_p5' and p.status='active' and h.component_code='P1')<>90 or
     (select coalesce(sum(h.suggested_guided_teaching_hours),0)
       from private.exam_prep_historical_topic_teaching_refs_v1 h
       join private.exam_prep_program_versions p on p.id=h.program_version_id
       where p.program_key='math_as_p1_p5' and p.status='active' and h.component_code='P5')<>50 or
     exists(select 1 from private.exam_prep_historical_topic_teaching_refs_v1
       where approved_as_personal_study_norm or
             status<>'historical_reference_unverified_for_2026_27')
  then
    raise exception 'P2 FAIL: historical Cambridge topic GUIDE must remain 8 P1+5 P5, 90+50 teacher contact hours and not personal study norms';
  end if;
  raise notice 'PASS P2: 13 historical Cambridge 2020 Scheme of Work topics, 90h P1 + 50h P5 GUIDED teaching only; zero personalized hours';
  raise notice 'PASS P2: 81 actual source-mapped skills (45 P1,36 P5); all source refs present, all time norms NULL until independent academic approval';
end $$;
