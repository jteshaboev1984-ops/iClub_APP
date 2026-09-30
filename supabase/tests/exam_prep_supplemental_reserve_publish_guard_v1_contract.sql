-- Supplemental-reserve publication guard v1 contract.
-- Runs after the full migration stack; all synthetic mutations are rolled back.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_cv bigint;
  v_floor jsonb;
  v_expected boolean:=false;
  v_failed boolean:=false;
  v_msg text;
BEGIN
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null then
    raise exception 'supplemental-reserve contract: floor function missing';
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or not has_function_privilege('service_role','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-reserve contract: ACL mismatch';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0';

  if v_program is null
     or not private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-QUA-01')
     or not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-01')
  then
    raise exception 'supplemental-reserve contract: established full-floor readiness changed';
  end if;

  -- Full governed surface includes AW1-4 and AW5-8 governed learning/reserve
  -- profiles plus AW9-12 and AW13-16 supplemental learning/reserve.
  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802)
        and release_mode='supplemental_learning'
        and require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4803,4804)
           and release_mode='supplemental_reserve'
           and require_written_understanding=false)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4805,4806)
           and release_mode='supplemental_learning'
           and require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4807,4808)
           and release_mode='supplemental_reserve'
           and require_written_understanding=false)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4809,4810)
           and release_mode='supplemental_learning'
           and require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4811,4812)
           and release_mode='supplemental_reserve'
           and require_written_understanding=false)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4813,4814)
           and release_mode='supplemental_learning'
           and require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1
         where content_version_id in (4815,4816)
           and release_mode='supplemental_reserve'
           and require_written_understanding=false)<>2
     or (select count(*) from private.exam_prep_content_release_profiles_v1)<>16
  then
    raise exception 'supplemental-reserve contract: governed release-profile surface drift';
  end if;

  if coalesce((private.exam_prep_supplemental_learning_floor_v1(4801)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4802)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4803)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4804)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4805)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4806)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4807)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4808)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4809)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4810)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4811)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4812)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4813)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4814)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4815)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4816)->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-reserve contract: governed supplemental floor is RED';
  end if;

  -- Negative fixture: an empty reserve version can neither become ready nor
  -- bypass publication. This avoids mutating the released AW1-4 versions.
  insert into private.exam_prep_content_versions(
    program_version_id,content_version,component_code,release_label,status,source_policy,source_level
  ) values (
    v_program,'ci_supplemental_reserve_guard_negative_v1','P1',
    'CI supplemental reserve negative fixture','draft',
    'Disposable CI-only original-content fixture used only to prove fail-closed supplemental reserve governance; no learner delivery.',
    3
  )
  returning id into v_cv;

  v_floor:=private.exam_prep_supplemental_reserve_floor_v1(v_cv);
  if coalesce((v_floor->>'ready')::boolean,false) then
    raise exception 'supplemental-reserve contract: empty no-profile fixture unexpectedly ready';
  end if;

  -- Constraint must reject unknown release modes.
  begin
    insert into private.exam_prep_content_release_profiles_v1(
      content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
    ) values(
      v_cv,'invalid_mode','ci-invalid-v1',false,
      'Disposable invalid release-mode fixture must be rejected by the release profile constraint.'
    );
  exception when check_violation then
    v_expected:=true;
  end;
  if not v_expected then
    raise exception 'supplemental-reserve contract: invalid release mode accepted';
  end if;

  insert into private.exam_prep_content_release_profiles_v1(
    content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
  ) values(
    v_cv,'supplemental_reserve','ci-negative-v1',false,
    'Disposable negative fixture: empty supplemental reserve draft must never bypass publication QA/floor gates.'
  );

  v_floor:=private.exam_prep_supplemental_reserve_floor_v1(v_cv);
  if coalesce((v_floor->>'ready')::boolean,false) then
    raise exception 'supplemental-reserve contract: empty profiled fixture unexpectedly ready';
  end if;

  begin
    update private.exam_prep_content_versions
    set status='published',published_at=now()
    where id=v_cv and status='draft';
  exception when others then
    v_failed:=true;
    v_msg:=sqlerrm;
  end;

  if not v_failed
     or position('exam_prep_supplemental_reserve_publish_floor_not_met' in coalesce(v_msg,''))=0
  then
    raise exception 'supplemental-reserve contract: empty synthetic publish did not fail closed: %',
      coalesce(v_msg,'NO ERROR');
  end if;

  if (select status from private.exam_prep_content_versions where id=v_cv)<>'draft' then
    raise exception 'supplemental-reserve contract: failed synthetic publish altered draft state';
  end if;
END
$$;

ROLLBACK;

DO $$
BEGIN
  if (select count(*) from private.exam_prep_content_release_profiles_v1)<>16
     or (select count(*) from private.exam_prep_content_versions
         where id in (4803,4804,4807,4808,4811,4812,4815,4816) and status='published')<>8 then
    raise exception 'supplemental-reserve contract: rollback disturbed released governance surface';
  end if;
END
$$;

\echo 'Supplemental-reserve publication guard v1 contract: GREEN'
