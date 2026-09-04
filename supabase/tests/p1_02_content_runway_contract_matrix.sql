\set ON_ERROR_STOP on
\echo 'P1-02 completed content runway matrix'

do $$
declare
  v_program bigint;
  v_runway jsonb;
  v_aw2 jsonb;
  v_aw5 jsonb;
  v_tmp bigint;
  v_failed boolean:=false;
  v_skill text;
  v_p1_e2_ready int;
  v_p5_e2_ready int;
begin
  select id into v_program from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  if v_program is null then raise exception 'P1-02 matrix: canonical program missing'; end if;

  foreach v_skill in array array['P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P1',v_skill) then raise exception 'P1-02 matrix: P1 skill not ready: %',v_skill; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1',v_skill,1::smallint) then raise exception 'P1-02 matrix: P1 skill not AW1 eligible: %',v_skill; end if;
  end loop;
  foreach v_skill in array array['P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P5',v_skill) then raise exception 'P1-02 matrix: P5 skill not ready: %',v_skill; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P5',v_skill,1::smallint) then raise exception 'P1-02 matrix: P5 skill not AW1 eligible: %',v_skill; end if;
  end loop;

  if private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1','P1-COO-01',1::smallint) then raise exception 'P1-02 matrix: P1-COO-01 leaked into AW1'; end if;

  v_runway:=public.get_exam_prep_content_runway_v1(1::smallint);
  if not coalesce((v_runway->>'hard_floor_green')::boolean,false) then raise exception 'P1-02 matrix: AW1 hard floor should be green'; end if;
  if not coalesce((v_runway->>'target_4w_green')::boolean,false) then raise exception 'P1-02 matrix: AW1 four-week target should be green'; end if;
  if (v_runway#>>'{components,P1,ahead_weeks}')::int<4 or (v_runway#>>'{components,P5,ahead_weeks}')::int<4 then raise exception 'P1-02 matrix: AW1 must expose at least four governed weeks'; end if;

  v_aw2:=public.get_exam_prep_content_runway_v1(2::smallint);
  if not coalesce((v_aw2->>'hard_floor_green')::boolean,false) then raise exception 'P1-02 matrix: AW2 should retain hard floor'; end if;
  if not coalesce((v_aw2->>'target_4w_green')::boolean,false) then raise exception 'P1-02 matrix: AW2 four-week target should remain green after P5 E2 publication'; end if;
  if (v_aw2#>>'{components,P1,ahead_weeks}')::int<4 or (v_aw2#>>'{components,P5,ahead_weeks}')::int<4 then raise exception 'P1-02 matrix: AW2 must retain at least four governed weeks'; end if;

  foreach v_skill in array array['P1-FUN-06','P1-FUN-07','P1-FUN-08','P1-COO-01','P1-COO-02','P1-COO-03','P1-CIR-01','P1-TRI-01'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P1',v_skill) then raise exception 'P1-02 matrix: E2 P1 skill not content-ready: %',v_skill; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1',v_skill,5::smallint) then raise exception 'P1-02 matrix: E2 P1 skill not AW5 eligible: %',v_skill; end if;
  end loop;
  foreach v_skill in array array['P5-CNT-01','P5-CNT-02','P5-CNT-03','P5-CNT-04','P5-PRO-01','P5-PRO-03'] loop
    if not private.exam_prep_skill_content_ready_v1(v_program,'P5',v_skill) then raise exception 'P1-02 matrix: E2 P5 skill not content-ready: %',v_skill; end if;
    if not private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P5',v_skill,5::smallint) then raise exception 'P1-02 matrix: E2 P5 skill not AW5 eligible: %',v_skill; end if;
  end loop;

  select count(*) into v_p1_e2_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key='aw05_08_core_coverage_i' and r.component_code='P1' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P1',rs.skill_code);
  select count(*) into v_p5_e2_ready from private.exam_prep_content_runway_release_skills rs join private.exam_prep_content_runway_releases r on r.id=rs.release_id
  where r.release_key='aw05_08_core_coverage_i' and r.component_code='P5' and rs.required_for_release and private.exam_prep_skill_content_ready_v1(v_program,'P5',rs.skill_code);
  if v_p1_e2_ready<>8 or v_p5_e2_ready<>6 then raise exception 'P1-02 matrix: expected E2 readiness P1=8 P5=6, got P1=% P5=%',v_p1_e2_ready,v_p5_e2_ready; end if;

  v_aw5:=public.get_exam_prep_content_runway_v1(5::smallint);
  if coalesce((v_aw5->>'hard_floor_green')::boolean,false) is not true or coalesce((v_aw5->>'target_4w_green')::boolean,false) is not true then raise exception 'P1-02 matrix: global AW5 must be four-week green after P1+P5 E2 completion'; end if;
  if coalesce((v_aw5#>>'{components,P1,hard_floor_2w_green}')::boolean,false) is not true or coalesce((v_aw5#>>'{components,P1,target_4w_green}')::boolean,false) is not true then raise exception 'P1-02 matrix: P1 AW5 component runway should be fully green'; end if;
  if coalesce((v_aw5#>>'{components,P5,hard_floor_2w_green}')::boolean,false) is not true or coalesce((v_aw5#>>'{components,P5,target_4w_green}')::boolean,false) is not true then raise exception 'P1-02 matrix: P5 AW5 component runway should be fully green'; end if;

  insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
  values(v_program,'p102_contract_negative_fixture','P1','P1-02 negative publication fixture','draft','Synthetic isolated CI fixture; never production content.') returning id into v_tmp;
  begin
    update private.exam_prep_content_versions set status='published' where id=v_tmp;
    raise exception 'P1-02 matrix: empty version publication unexpectedly succeeded';
  exception when others then
    if sqlerrm='P1-02 matrix: empty version publication unexpectedly succeeded' then raise; end if;
    if position('exam_prep_content_publish_empty_version' in sqlerrm)=0 then raise exception 'P1-02 matrix: unexpected publication-guard error: %',sqlerrm; end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-02 matrix: publication guard was not exercised'; end if;
  delete from private.exam_prep_content_versions where id=v_tmp;

  if (select count(*) from public.questions where book_ref like 'ExamPrep:P1:p1_foundations_runway_v1:%')<>35 then raise exception 'P1-02 matrix: P1 opening authored count mismatch'; end if;
  if (select count(*) from public.questions where book_ref like 'ExamPrep:P5:p5_dat02_runway_v1:%')<>7 then raise exception 'P1-02 matrix: P5 DAT02 authored count mismatch'; end if;
  if (select count(*) from public.questions where book_ref like 'ExamPrep:P1:p1_e2_functions_bridge_v1:%')<>21 then raise exception 'P1-02 matrix: E2 functions authored count mismatch'; end if;
  if (select count(*) from public.questions where book_ref like 'ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:%')<>35 then raise exception 'P1-02 matrix: E2 coord/circ/trig authored count mismatch'; end if;
  if (select count(*) from public.questions where book_ref like 'ExamPrep:P5:p5_e2_counting_probability_v1:%')<>42 then raise exception 'P1-02 matrix: P5 E2 authored count mismatch'; end if;
  if exists(select 1 from public.questions where (
      book_ref like 'ExamPrep:P1:p1_foundations_runway_v1:%'
      or book_ref like 'ExamPrep:P5:p5_dat02_runway_v1:%'
      or book_ref like 'ExamPrep:P1:p1_e2_functions_bridge_v1:%'
      or book_ref like 'ExamPrep:P1:p1_e2_coordinate_circular_trig_v1:%'
      or book_ref like 'ExamPrep:P5:p5_e2_counting_probability_v1:%'
    ) and (is_active or quality_status is distinct from 'draft')) then raise exception 'P1-02 matrix: Exam Prep question leaked into legacy delivery'; end if;

  if exists(select 1 from private.exam_prep_feature_config where rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch) then raise exception 'P1-02 matrix: feature state escaped fail-closed'; end if;
  if (select count(*) from private.exam_prep_beta_cohorts)<>0 then raise exception 'P1-02 matrix: beta cohort residue'; end if;
  if (select count(*) from private.exam_prep_beta_members)<>0 then raise exception 'P1-02 matrix: beta member residue'; end if;
end;
$$;

select public.get_exam_prep_content_runway_v1(1::smallint) as aw1_runway;
select public.get_exam_prep_content_runway_v1(2::smallint) as aw2_runway;
select public.get_exam_prep_content_runway_v1(5::smallint) as aw5_p1_p5_complete;
\echo 'P1-02 completed content runway matrix: GREEN'
