-- Contract for the supplemental-learning publication guard.
-- Runs only in disposable CI and rolls back all fixture mutations.
begin;

do $$
declare
  v_failed boolean:=false;
  v_msg text;
  v_program bigint;
begin
  if to_regclass('private.exam_prep_content_release_profiles_v1') is null
     or to_regprocedure('private.exam_prep_supplemental_learning_floor_v1(bigint)') is null
  then
    raise exception 'supplemental-learning contract: architecture missing';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1)<>0 then
    raise exception 'supplemental-learning contract: guard-only migration registered content unexpectedly';
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

  -- Register one still-pending draft only inside this rollback transaction.
  insert into private.exam_prep_content_release_profiles_v1(
    content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
  )
  select id,'supplemental_learning','ci-negative-v1',true,
         'Disposable negative fixture: pending draft must never bypass QA or baseline publication gates.'
  from private.exam_prep_content_versions
  where content_version='p1_aw01_04_alt_learning_draft_v1'
    and component_code='P1'
    and status='draft';

  if not found then
    raise exception 'supplemental-learning contract: expected AW1-4 P1 draft fixture missing';
  end if;

  begin
    update private.exam_prep_content_versions
    set status='published',published_at=now()
    where content_version='p1_aw01_04_alt_learning_draft_v1'
      and component_code='P1'
      and status='draft';
  exception when others then
    v_failed:=true;
    v_msg:=sqlerrm;
  end;

  if not v_failed
     or position('exam_prep_supplemental_learning_publish_floor_not_met' in coalesce(v_msg,''))=0
  then
    raise exception 'supplemental-learning contract: pending draft publish did not fail closed: %',coalesce(v_msg,'NO ERROR');
  end if;

  if exists(
    select 1
    from private.exam_prep_content_versions
    where content_version='p1_aw01_04_alt_learning_draft_v1'
      and status<>'draft'
  ) then
    raise exception 'supplemental-learning contract: failed publish altered draft state';
  end if;
end $$;

rollback;

select 'SUPPLEMENTAL_LEARNING_PUBLISH_GUARD_GREEN' as result;
