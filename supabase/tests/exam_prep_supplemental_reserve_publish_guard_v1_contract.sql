-- Supplemental-reserve publication guard v1 contract.
-- After the full migration stack the real AW1-4 reserve packs are published.
-- This test verifies their governed floor and uses only a disposable synthetic
-- empty version for negative/fail-closed proof.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_program bigint;
  v_cv bigint;
  v_floor jsonb;
  v_failed boolean:=false;
  v_msg text;
  v_bad_mode boolean:=false;
BEGIN
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null
     or to_regclass('private.exam_prep_content_release_profiles_v1') is null
  then
    raise exception 'supplemental-reserve contract: architecture missing';
  end if;

  if has_table_privilege('anon','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_table_privilege('authenticated','private.exam_prep_content_release_profiles_v1','SELECT')
     or has_function_privilege('anon','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or not has_function_privilege('service_role','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-reserve contract: ACL mismatch';
  end if;

  -- Existing learning path remains governed.
  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802)
        and release_mode='supplemental_learning'
        and require_written_understanding)<>2
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4801)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_learning_floor_v1(4802)->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-reserve contract: supplemental-learning path regressed';
  end if;

  -- Released reserve packs are explicit, withheld and floor-ready.
  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4803,4804)
        and release_mode='supplemental_reserve'
        and profile_version='aw01_04_annual_reserve_release_v1'
        and not require_written_understanding)<>2
     or (select count(*) from private.exam_prep_content_versions
         where id in (4803,4804) and status='published')<>2
  then
    raise exception 'supplemental-reserve contract: governed reserve-profile surface drift';
  end if;

  if coalesce((private.exam_prep_supplemental_reserve_floor_v1(4803)->>'ready')::boolean,false) is not true
     or coalesce((private.exam_prep_supplemental_reserve_floor_v1(4804)->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-reserve contract: released reserve floor is RED';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1)<>4 then
    raise exception 'supplemental-reserve contract: unexpected governed profile count';
  end if;

  select id into v_program
  from private.exam_prep_program_versions
  where program_key='math_as_p1_p5'
    and version_key='p1_p5_canonical_v1_0';

  insert into private.exam_prep_content_versions(
    program_version_id,content_version,component_code,release_label,status,source_policy,source_level
  ) values (
    v_program,'ci_supplemental_reserve_guard_negative_v1','P1',
    'CI supplemental reserve negative fixture','draft',
    'Disposable CI-only original-content fixture used only to prove fail-closed reserve publication governance; no learner delivery.',
    3
  )
  returning id into v_cv;

  begin
    insert into private.exam_prep_content_release_profiles_v1(
      content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
    ) values(
      v_cv,'invalid_mode','ci-invalid-v1',false,
      'Disposable invalid release-mode fixture must be rejected by the private release-profile constraint.'
    );
  exception when check_violation then
    v_bad_mode:=true;
  end;
  if not v_bad_mode then
    raise exception 'supplemental-reserve contract: invalid release mode accepted';
  end if;

  insert into private.exam_prep_content_release_profiles_v1(
    content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
  ) values(
    v_cv,'supplemental_reserve','ci-negative-v1',false,
    'Disposable negative fixture: empty supplemental reserve must never bypass publication QA/floor gates.'
  );

  v_floor:=private.exam_prep_supplemental_reserve_floor_v1(v_cv);
  if coalesce((v_floor->>'ready')::boolean,true) is not false then
    raise exception 'supplemental-reserve contract: empty reserve floor not RED';
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
  if (select count(*) from private.exam_prep_content_release_profiles_v1)<>4
     or exists(
       select 1 from private.exam_prep_content_versions
       where content_version='ci_supplemental_reserve_guard_negative_v1'
     )
  then
    raise exception 'supplemental-reserve contract: rollback residue';
  end if;
END
$$;

\echo 'Supplemental-reserve publication guard v1 contract: GREEN'
