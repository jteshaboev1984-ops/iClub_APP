-- P0-06: canonical Cambridge AS Mathematics P1+P5 registry.
-- Source: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0.xlsx
-- Canonical map version: 01_Academic_Syllabus_Source_Map_P1_P5_v1.0
-- Deterministic source-data SHA256: b3d78f8b6ea0b2a6694deee0ff045022aafe53ff9b5da0a923c2ded39e10959b
-- Additive only. No legacy questions/Practice/Tours/ratings/certificates are updated or deleted.

-- Final acceptance gate for P0-06. No user-facing capability is enabled here.
-- If any invariant is violated this migration fails and P0-06 is not accepted.

begin;

do $$
declare
  v_program_version_id bigint;
  v_p1_count integer;
  v_p5_count integer;
  v_p1_areas integer;
  v_p5_areas integer;
  v_pr_nodes integer;
  v_edges integer;
  v_mixed integer;
  v_links integer;
  v_geo integer;
  v_bad integer;
begin
  select id into v_program_version_id
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0'
    and canonical_skill_map_version='01_Academic_Syllabus_Source_Map_P1_P5_v1.0'
    and status='active';

  if v_program_version_id is null then
    raise exception 'P0-06 invariant failed: canonical active program version missing';
  end if;

  select count(*) filter (where component_code='P1'),
         count(*) filter (where component_code='P5'),
         count(distinct official_syllabus_section) filter (where component_code='P1'),
         count(distinct official_syllabus_section) filter (where component_code='P5')
  into v_p1_count, v_p5_count, v_p1_areas, v_p5_areas
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program_version_id;

  select count(*) into v_pr_nodes
  from private.exam_prep_prerequisite_nodes
  where program_version_id=v_program_version_id;

  select count(*) into v_edges
  from private.exam_prep_prerequisite_edges
  where program_version_id=v_program_version_id;

  select count(*) into v_mixed
  from private.exam_prep_mixed_nodes
  where program_version_id=v_program_version_id;

  select count(*) into v_links
  from private.exam_prep_mixed_links
  where program_version_id=v_program_version_id;

  select count(*) into v_geo
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program_version_id
    and component_code='P5'
    and skill_code in ('P5-GEO-01','P5-GEO-02','P5-GEO-03');

  if v_p1_count <> 45 or v_p5_count <> 36 then
    raise exception 'P0-06 invariant failed: skill counts P1=% P5=% expected 45/36', v_p1_count, v_p5_count;
  end if;
  if v_p1_areas <> 8 or v_p5_areas <> 5 then
    raise exception 'P0-06 invariant failed: area counts P1=% P5=% expected 8/5', v_p1_areas, v_p5_areas;
  end if;
  if v_pr_nodes <> 11 then
    raise exception 'P0-06 invariant failed: prerequisite node count % expected 11', v_pr_nodes;
  end if;
  if v_edges <> 184 then
    raise exception 'P0-06 invariant failed: prerequisite edge count % expected 184', v_edges;
  end if;
  if v_mixed <> 23 then
    raise exception 'P0-06 invariant failed: mixed node count % expected 23', v_mixed;
  end if;
  if v_links <> 77 then
    raise exception 'P0-06 invariant failed: mixed link count % expected 77', v_links;
  end if;
  if v_geo <> 3 then
    raise exception 'P0-06 invariant failed: geometric distribution nodes % expected 3', v_geo;
  end if;

  select count(*) into v_bad
  from (
    select component_code, min(sequence_no) mn, max(sequence_no) mx, count(*) ct, count(distinct sequence_no) dct
    from private.exam_prep_syllabus_nodes
    where program_version_id=v_program_version_id
    group by component_code
  ) s
  where (component_code='P1' and (mn<>1 or mx<>45 or ct<>45 or dct<>45))
     or (component_code='P5' and (mn<>1 or mx<>36 or ct<>36 or dct<>36));
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: component sequence denominator is not exact';
  end if;

  select count(*) into v_bad
  from private.exam_prep_syllabus_nodes
  where program_version_id=v_program_version_id
    and ((component_code='P1' and skill_code not like 'P1-%')
      or (component_code='P5' and skill_code not like 'P5-%'));
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: skill-code/component firewall violation count=%', v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_prerequisite_edges e
  join private.exam_prep_syllabus_nodes t
    on t.program_version_id=e.program_version_id and t.skill_code=e.to_skill_code
  where e.program_version_id=v_program_version_id
    and (e.is_mastery_crediting
      or e.target_component_code <> t.component_code
      or not (
        exists (
          select 1 from private.exam_prep_syllabus_nodes s
          where s.program_version_id=e.program_version_id and s.skill_code=e.from_node_code
        )
        or exists (
          select 1 from private.exam_prep_prerequisite_nodes p
          where p.program_version_id=e.program_version_id and p.prerequisite_code=e.from_node_code
        )
      ));
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: prerequisite graph violation count=%', v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_prerequisite_nodes
  where program_version_id=v_program_version_id and is_mastery_crediting;
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: foundation prerequisite can credit mastery';
  end if;

  select count(*) into v_bad
  from private.exam_prep_mixed_nodes
  where program_version_id=v_program_version_id and denominator_credit;
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: mixed node denominator credit found';
  end if;

  select count(*) into v_bad
  from private.exam_prep_mixed_links ml
  where ml.program_version_id=v_program_version_id
    and (
      (ml.linked_node_kind='skill' and not exists (
        select 1
        from private.exam_prep_syllabus_nodes s
        where s.program_version_id=ml.program_version_id
          and s.skill_code=ml.linked_node_code
          and s.component_code=ml.linked_component_code
      ))
      or
      (ml.linked_node_kind='foundation' and (
        ml.linked_component_code is not null
        or not exists (
          select 1
          from private.exam_prep_prerequisite_nodes p
          where p.program_version_id=ml.program_version_id
            and p.prerequisite_code=ml.linked_node_code
        )
      ))
    );
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: mixed link resolution violation count=%', v_bad;
  end if;

  select count(*) into v_bad
  from private.exam_prep_mixed_links
  where program_version_id=v_program_version_id and mixed_code='MX-X-02';
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: MX-X-02 must not link academic nodes';
  end if;

  select count(*) into v_bad
  from private.exam_prep_feature_config
  where id=1 and (
    rollout_state <> 'off'
    or core_enabled
    or ai_enabled
    or mentor_enabled
    or not kill_switch
  );
  if v_bad <> 0 then
    raise exception 'P0-06 invariant failed: Exam Prep capability gate is not OFF';
  end if;

  update private.exam_prep_program_versions
  set updated_at=now()
  where id=v_program_version_id;
end;
$$;

commit;
