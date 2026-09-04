\set ON_ERROR_STOP on
\echo 'P1-02 content runway contract matrix'

do $$
declare
  v_program bigint;
  v_runway jsonb;
  v_tmp bigint;
  v_failed boolean:=false;
begin
  select id into v_program from private.exam_prep_program_versions
  where program_key='math_as_p1_p5' and version_key='p1_p5_canonical_v1_0';
  if v_program is null then raise exception 'P1-02 matrix: canonical program missing'; end if;

  -- Existing P5 opening slice must be recognized by the generic floor, not special-cased.
  if not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-01') then raise exception 'P1-02 matrix: P5-DAT-01 should be ready'; end if;
  if not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-04') then raise exception 'P1-02 matrix: P5-DAT-04 should be ready'; end if;
  if not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-06') then raise exception 'P1-02 matrix: P5-DAT-06 should be ready'; end if;

  -- Planned but not-yet-authored runway must remain RED.
  if private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-02') then raise exception 'P1-02 matrix: P5-DAT-02 false green'; end if;
  if private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-QUA-01') then raise exception 'P1-02 matrix: P1-QUA-01 false green'; end if;

  if not private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P5','P5-DAT-01',1::smallint) then raise exception 'P1-02 matrix: governed scheduled P5-DAT-01 should be eligible'; end if;
  if private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P5','P5-DAT-02',1::smallint) then raise exception 'P1-02 matrix: missing P5-DAT-02 should not be eligible'; end if;
  if private.exam_prep_skill_runway_ready_for_week_v1(v_program,'P1','P1-QUA-01',1::smallint) then raise exception 'P1-02 matrix: missing P1-QUA-01 should not be eligible'; end if;

  v_runway:=public.get_exam_prep_content_runway_v1(1::smallint);
  if coalesce((v_runway->>'hard_floor_green')::boolean,false) then raise exception 'P1-02 matrix: incomplete runway cannot be hard-floor green'; end if;
  if coalesce((v_runway->>'target_4w_green')::boolean,false) then raise exception 'P1-02 matrix: incomplete runway cannot be target green'; end if;

  -- Empty/partial future content can never be published.
  insert into private.exam_prep_content_versions(program_version_id,content_version,component_code,release_label,status,source_policy)
  values(v_program,'p102_contract_negative_fixture','P1','P1-02 negative publication fixture','draft','Synthetic isolated CI fixture; never production content.')
  returning id into v_tmp;
  begin
    update private.exam_prep_content_versions set status='published' where id=v_tmp;
    raise exception 'P1-02 matrix: empty version publication unexpectedly succeeded';
  exception when others then
    if sqlerrm='P1-02 matrix: empty version publication unexpectedly succeeded' then raise; end if;
    if position('exam_prep_content_publish_empty_version' in sqlerrm)=0 then
      raise exception 'P1-02 matrix: unexpected publication-guard error: %',sqlerrm;
    end if;
    v_failed:=true;
  end;
  if not v_failed then raise exception 'P1-02 matrix: publication guard was not exercised'; end if;
  delete from private.exam_prep_content_versions where id=v_tmp;

  -- Deployment invariant: no cohort or feature activation.
  if exists(select 1 from private.exam_prep_feature_config where rollout_state<>'off' or core_enabled or ai_enabled or mentor_enabled or not kill_switch) then
    raise exception 'P1-02 matrix: feature state escaped fail-closed';
  end if;
  if (select count(*) from private.exam_prep_beta_cohorts)<>0 then raise exception 'P1-02 matrix: beta cohort residue'; end if;
  if (select count(*) from private.exam_prep_beta_members)<>0 then raise exception 'P1-02 matrix: beta member residue'; end if;
end;
$$;

select public.get_exam_prep_content_runway_v1(1::smallint) as runway_before_new_content;
\echo 'P1-02 content runway contract matrix: GREEN'
