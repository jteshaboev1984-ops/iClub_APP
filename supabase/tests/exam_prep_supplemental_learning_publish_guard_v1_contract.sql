-- Contract for the supplemental-learning publication guard.
-- Runs only in disposable CI and rolls back the negative fixture.
begin;

do $$
declare
  v_failed boolean:=false;
  v_msg text;
  v_program bigint;
  v_fixture_id bigint;
  v_p1 jsonb;
  v_p5 jsonb;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then
    raise exception 'supplemental-learning contract: architecture missing';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4801,4802)
        and release_mode='supplemental_learning'
        and profile_version='supplemental_learning_v1'
        and require_written_understanding)<>2
  then
    raise exception 'supplemental-learning contract: governed AW1-4 release profiles missing';
  end if;

  v_p1:=private.exam_prep_supplemental_learning_floor_v1(4801);
  v_p5:=private.exam_prep_supplemental_learning_floor_v1(4802);
  if coalesce((v_p1->>'ready')::boolean,false) is not true
     or coalesce((v_p5->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-learning contract: published target floor failed P1=% P5=%',v_p1,v_p5;
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
    and version_key='p1_p5_canonical_v1_0'
    and status='active';

  if v_program is null
     or not private.exam_prep_skill_content_ready_v1(v_program,'P1','P1-QUA-01')
     or not private.exam_prep_skill_content_ready_v1(v_program,'P5','P5-DAT-01')
  then
    raise exception 'supplemental-learning contract: established full-floor readiness changed';
  end if;

  -- A deliberately empty disposable supplemental version must still fail closed.
  select coalesce(max(id),0)+100000 into v_fixture_id
  from private.exam_prep_content_versions;

  insert into private.exam_prep_content_versions(
    id,program_version_id,content_version,component_code,release_label,status,source_policy,source_level
  ) values (
    v_fixture_id,v_program,'ci_supplemental_negative_fixture_v1','P1',
    'CI supplemental negative fixture','draft',
    'Original disposable CI fixture used only to prove the supplemental-learning publication gate fails closed.',
    3
  );

  insert into private.exam_prep_content_release_profiles_v1(
    content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
  ) values (
    v_fixture_id,'supplemental_learning','ci-negative-v1',true,
    'Disposable negative fixture: empty supplemental content must never bypass publication governance.'
  );

  begin
    update private.exam_prep_content_versions
    set status='published',published_at=now()
    where id=v_fixture_id and status='draft';
  exception when others then
    v_failed:=true;
    v_msg:=sqlerrm;
  end;

  if not v_failed
     or position('exam_prep_supplemental_learning_publish_floor_not_met' in coalesce(v_msg,''))=0
  then
    raise exception 'supplemental-learning contract: empty fixture publish did not fail closed: %',coalesce(v_msg,'NO ERROR');
  end if;

  if exists(
    select 1 from private.exam_prep_content_versions
    where id=v_fixture_id and status<>'draft'
  ) then
    raise exception 'supplemental-learning contract: failed fixture publish altered state';
  end if;
end $$;

rollback;

select 'SUPPLEMENTAL_LEARNING_PUBLISH_GUARD_GREEN' as result;
