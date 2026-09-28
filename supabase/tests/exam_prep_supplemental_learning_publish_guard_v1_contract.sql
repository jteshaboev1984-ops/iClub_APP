-- Contract for the supplemental-learning publication guard.
-- Runs only in disposable CI and rolls back all fixture mutations.
begin;

do $$
declare
  v_failed boolean:=false;
  v_msg text;
  v_program bigint;
  v_cv bigint;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then
    raise exception 'supplemental-learning contract: architecture missing';
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_learning_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_learning_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-learning contract: private architecture exposed to browser roles';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0';

  if v_program is null
     or not private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-QUA-01')
     or not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-01')
  then
    raise exception 'supplemental-learning contract: established full-floor readiness changed';
  end if;

  -- The live migration stack currently has exactly the two governed AW1-4
  -- supplemental release profiles.
  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802)
        and release_mode='supplemental_learning'
        and require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1)<>2
  then
    raise exception 'supplemental-learning contract: governed release-profile surface drift';
  end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4801)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4802)->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-learning contract: released AW1-4 supplemental floor is RED';
  end if;

  -- Negative fixture: a registered but empty supplemental version must never
  -- bypass the publication guard. Use an isolated synthetic content version
  -- rather than mutating the already-published AW1-4 packs.
  insert into private.exam_prep_content_versions(
    program_version_id,content_version,component_code,release_label,status,source_policy,source_level
  ) values (
    v_program,'ci_supplemental_guard_negative_v1','P1',
    'CI supplemental negative fixture','draft',
    'Disposable CI-only original-content fixture used only to prove fail-closed supplemental publication governance; no learner delivery.',
    3
  )
  returning id into v_cv;

  insert into private.exam_prep_content_release_profiles_v1(
    content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
  ) values (
    v_cv,'supplemental_learning','ci-negative-v1',true,
    'Disposable negative fixture: empty supplemental draft must never bypass publication QA/floor gates.'
  );

  begin
    update private.exam_prep_content_versions
    set status='published',published_at=now()
    where id=v_cv and status='draft';
  exception when others then
    v_failed:=true;
    v_msg:=sqlerrm;
  end;

  if not v_failed
     or position('exam_prep_supplemental_learning_publish_floor_not_met' in coalesce(v_msg,''))=0
  then
    raise exception 'supplemental-learning contract: empty synthetic publish did not fail closed: %',
      coalesce(v_msg,'NO ERROR');
  end if;

  if (select status from private.exam_prep_content_versions where id=v_cv)<>'draft' then
    raise exception 'supplemental-learning contract: failed synthetic publish altered draft state';
  end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(v_cv)->>'ready')::boolean,true) is not false then
    raise exception 'supplemental-learning contract: empty synthetic supplemental floor not RED';
  end if;
end $$;

rollback;

select 'SUPPLEMENTAL_LEARNING_PUBLISH_GUARD_GREEN' as result;
