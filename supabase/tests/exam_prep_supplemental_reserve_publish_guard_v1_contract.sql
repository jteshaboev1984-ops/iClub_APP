-- Supplemental-reserve publication guard v1 contract.
-- Exercises the real AW1-4 annual reserve draft inside a rollback transaction.
\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
  v_expected boolean:=false;
  v_floor jsonb;
begin
  if to_regprocedure('private.exam_prep_supplemental_reserve_floor_v1(bigint)') is null then
    raise exception 'supplemental-reserve contract: floor function missing';
  end if;

  if has_function_privilege('anon','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or has_function_privilege('authenticated','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
     or not has_function_privilege('service_role','private.exam_prep_supplemental_reserve_floor_v1(bigint)','EXECUTE')
  then
    raise exception 'supplemental-reserve contract: ACL mismatch';
  end if;

  if exists(
    select 1
    from private.exam_prep_content_release_profiles_v1 p
    where p.release_mode='supplemental_learning'
      and coalesce((private.exam_prep_supplemental_learning_floor_v1(p.content_version_id)->>'ready')::boolean,false) is not true
  ) then
    raise exception 'supplemental-reserve contract: existing supplemental-learning floor regressed';
  end if;

  -- No profile means fail closed.
  v_floor:=private.exam_prep_supplemental_reserve_floor_v1(4803);
  if coalesce((v_floor->>'ready')::boolean,false) then
    raise exception 'supplemental-reserve contract: draft ready without explicit profile';
  end if;

  -- Constraint accepts only the two governed release modes.
  begin
    insert into private.exam_prep_content_release_profiles_v1(
      content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
    ) values(
      4803,'invalid_mode','ci-invalid-v1',false,
      'Disposable invalid release-mode fixture must be rejected by the release profile constraint.'
    );
  exception when check_violation then
    v_expected:=true;
  end;
  if not v_expected then
    raise exception 'supplemental-reserve contract: invalid release mode accepted';
  end if;
END
$$;

insert into private.exam_prep_content_release_profiles_v1(
  content_version_id,release_mode,profile_version,require_written_understanding,governance_basis
) values
  (4803,'supplemental_reserve','ci-aw01-04-reserve-v1',false,
   'Disposable CI profile proving reserve-only annual depth cannot bypass QA, holdout, baseline or annual-target gates.'),
  (4804,'supplemental_reserve','ci-aw01-04-reserve-v1',false,
   'Disposable CI profile proving reserve-only annual depth cannot bypass QA, holdout, baseline or annual-target gates.');

-- Even with a profile, raw draft rows must fail publication.
DO $$
DECLARE v_expected boolean:=false;
BEGIN
  BEGIN
    update private.exam_prep_content_versions
    set status='published',published_at=now()
    where id=4803 and status='draft';
  EXCEPTION WHEN OTHERS THEN
    if position('exam_prep_supplemental_reserve_publish_floor_not_met' in SQLERRM)>0 then
      v_expected:=true;
    else
      raise;
    end if;
  END;
  if not v_expected then
    raise exception 'supplemental-reserve contract: raw draft publication did not fail closed';
  end if;
END
$$;

-- Simulate the governed release transitions. Transaction rollback guarantees
-- that this test never persists a publication.
update private.exam_prep_diagnostic_rules r
set status='approved',approved_at=now()
from private.exam_prep_question_content_meta m
where m.id=r.content_meta_id
  and m.content_version_id in (4803,4804)
  and m.reserve_role='diagnostic'
  and r.rule_version='aw_reserve_v1'
  and r.status='draft';

update private.exam_prep_question_content_meta
set copyright_status='pass',
    qa_scope_status='pass',
    qa_math_status='pass',
    qa_language_status='pass',
    qa_technical_status='pass',
    diagnostic_rule_status=case when reserve_role='diagnostic' then 'approved' else 'not_applicable' end,
    lifecycle_state='reserve',
    exposure_state='withheld',
    approved_at=coalesce(approved_at,now()),
    updated_at=now()
where content_version_id in (4803,4804)
  and lifecycle_state='draft';

update private.exam_prep_assessments
set status='published',approved_at=coalesce(approved_at,now())
where content_version_id in (4803,4804)
  and status='draft';

update private.exam_prep_content_versions
set status='approved',approved_at=coalesce(approved_at,now())
where id in (4803,4804)
  and status='draft';

DO $$
DECLARE v1 jsonb; v2 jsonb;
BEGIN
  v1:=private.exam_prep_supplemental_reserve_floor_v1(4803);
  v2:=private.exam_prep_supplemental_reserve_floor_v1(4804);

  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true
  then
    raise exception 'supplemental-reserve contract: valid candidate floor not ready P1=% P5=%',v1,v2;
  end if;

  if (v1#>>'{counts,skills}')::int<>5
     or (v1#>>'{counts,questions}')::int<>25
     or (v1#>>'{counts,assessments}')::int<>13
     or (v2#>>'{counts,skills}')::int<>4
     or (v2#>>'{counts,questions}')::int<>20
     or (v2#>>'{counts,assessments}')::int<>11
  then
    raise exception 'supplemental-reserve contract: candidate cardinality mismatch P1=% P5=%',v1,v2;
  end if;
END
$$;

-- The trigger independently reruns the reserve floor.
update private.exam_prep_content_versions
set status='published',published_at=now()
where id in (4803,4804)
  and status='approved';

DO $$
DECLARE v_bad int;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='published')<>2 then
    raise exception 'supplemental-reserve contract: guarded publication did not complete';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta
      where content_version_id in (4803,4804)
        and lifecycle_state='reserve'
        and exposure_state='withheld')<>45 then
    raise exception 'supplemental-reserve contract: reserve exposure changed during publication';
  end if;

  if exists(
    select 1
    from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4803,4804)
      and (q.is_active or q.quality_status<>'draft')
  ) then
    raise exception 'supplemental-reserve contract: public source questions escaped isolation';
  end if;

  if exists(
    select 1 from private.exam_prep_written_tasks
    where content_version_id in (4803,4804)
  ) then
    raise exception 'supplemental-reserve contract: reserve-only version duplicated written tasks';
  end if;

  -- Prospective annual target is now met for all nine target skills.
  with expected(component_code,skill_code) as (values
    ('P1','P1-QUA-01'),('P1','P1-QUA-02'),('P1','P1-QUA-03'),('P1','P1-FUN-01'),('P1','P1-FUN-02'),
    ('P5','P5-DAT-01'),('P5','P5-DAT-02'),('P5','P5-DAT-04'),('P5','P5-DAT-06')
  ), q as (
    select cv.component_code,m.primary_skill_code skill_code,
      count(*) filter(where m.reserve_role='diagnostic') d,
      count(*) filter(where m.reserve_role='learning') l,
      count(*) filter(where m.reserve_role='retest') r,
      count(*) filter(where m.reserve_role='mixed') x
    from private.exam_prep_question_content_meta m
    join private.exam_prep_content_versions cv on cv.id=m.content_version_id
    join expected e on e.component_code=cv.component_code and e.skill_code=m.primary_skill_code
    where cv.status='published' and m.lifecycle_state in ('published','reserve')
    group by cv.component_code,m.primary_skill_code
  ), w as (
    select component_code,primary_skill_code skill_code,count(*) n
    from private.exam_prep_written_tasks
    where lifecycle_state='published'
      and primary_skill_code in (
        'P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-FUN-01','P1-FUN-02',
        'P5-DAT-01','P5-DAT-02','P5-DAT-04','P5-DAT-06'
      )
    group by component_code,primary_skill_code
  )
  select count(*) into v_bad
  from expected e
  left join q using(component_code,skill_code)
  left join w using(component_code,skill_code)
  where coalesce(q.d,0)<3
     or coalesce(q.l,0)+coalesce(q.x,0)<8
     or coalesce(q.r,0)<4
     or coalesce(w.n,0)<2;

  if v_bad<>0 then
    raise exception 'supplemental-reserve contract: published annual target not met rows=%',v_bad;
  end if;
END
$$;

ROLLBACK;

-- No test publication/profile survives rollback.
DO $$
BEGIN
  if exists(
    select 1 from private.exam_prep_content_release_profiles_v1
    where content_version_id in (4803,4804)
  ) then
    raise exception 'supplemental-reserve contract: profile rollback residue';
  end if;

  if (select count(*) from private.exam_prep_content_versions
      where id in (4803,4804) and status='draft')<>2
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4803,4804)
           and lifecycle_state='draft'
           and exposure_state='withheld')<>45
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4803,4804) and status='draft')<>24
  then
    raise exception 'supplemental-reserve contract: rollback did not restore draft state';
  end if;
END
$$;

\echo 'Supplemental-reserve publication guard v1 contract: GREEN'
