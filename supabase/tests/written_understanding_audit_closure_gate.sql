\set ON_ERROR_STOP on

begin;

-- Governance gate for the governed 104-task written-reasoning audit.
-- The target is intentionally NOT 90/90 companion coverage: protected exam items
-- and two learning tasks whose companion would reveal the requested answer remain
-- no-companion by design.
do $$
declare
  v_audit text[] := array[
    'P1CIR01-W01','P1FP02-Q03','P1TB01-Q01','P1TB01-Q03','P1FUN01-W01','P1FUN02-W01','P1FUN03-W01','P1FP01-Q02',
    'P1INT03-W01','P1INT04-W01','P1QUA02-W01','P1QUA04-W01','P1SER01-W01','P1SER02-W01','P1SER05-W01','P1TB02-Q02',
    'P5BIN02-W01','P5FP03-Q04','P5BIN03-W01','P5CNT01-W01','P5CNT02-W01','P5CNT03-W01','P5CNT04-W01','P5CNT05-W01',
    'P5DAT07-W01','P5DRV01-W01','P5DRV03-W01','P5FP02-Q06','P5FP03-Q05','P5GEO02-W01','P5FP01-Q06','P5MM01-Q04',
    'P5NOR06-W01','P5PRO01-W01','P5PRO02-W01','P5PRO04-W01','P5FP03-Q03','P5MM01-Q02','P5PRO05-W01',
    'P1QUA01-AW02','P1QUA02-AW02','P1QUA03-AW02','P1FUN01-AW02','P1FUN02-AW02',
    'P5DAT01-AW02','P5DAT02-AW02','P5DAT04-AW02','P5DAT06-AW02',
    'P1CIR02-W01','P1COO06-W01','P1DIF01-W01','P1FP01-Q08','P1TRI02-W01','P1TRI03-W01',
    'P5DAT01-W01','P5DAT06-W01','P5DAT08-W01','P5DRV02-W01','P5GEO03-W01',
    'P1COO03-W01','P1DIF05-W01','P1DIF07-W01','P1FUN05-W01','P1FUN06-W01','P1FUN07-W01','P1FUN08-W01','P1TRI04-W01',
    'P5BIN01-W01','P5DAT04-W01','P5DAT05-W01','P5GEO01-W01','P5NOR01-W01','P5FP01-Q03','P5FP02-Q03','P5PRO06-W01','P5TB02-Q02',
    'P1FUN06-AW06','P1FUN07-AW06','P1FUN08-AW06','P1COO01-AW06','P1COO02-AW06','P1COO03-AW06','P1CIR01-AW06','P1TRI01-AW06',
    'P5CNT01-AW06','P5CNT02-AW06','P5CNT03-AW06','P5CNT04-AW06','P5PRO01-AW06','P5PRO03-AW06',
    'P1QUA04-AW10','P1QUA05-AW10','P1QUA06-AW10','P1FUN03-AW10','P1FUN04-AW10','P1FUN05-AW10','P1COO04-AW10','P1CIR02-AW10',
    'P5DAT03-AW10','P5DAT05-AW10','P5DAT07-AW10','P5CNT05-AW10','P5PRO02-AW10','P5PRO04-AW10'
  ];
  v_learning_no_companion text[] := array['P1FUN07-W01','P5DAT05-W01'];
  v_protected_no_companion text[] := array[
    'P1FP01-Q02','P1FP01-Q08','P1FP02-Q03','P1TB01-Q01','P1TB01-Q03','P1TB02-Q02',
    'P5FP01-Q03','P5FP01-Q06','P5FP02-Q03','P5FP02-Q06','P5FP03-Q03','P5FP03-Q04','P5FP03-Q05',
    'P5MM01-Q02','P5MM01-Q04','P5TB02-Q02'
  ];
  v_total int;
  v_checks int;
  v_checked int;
  v_unchecked int;
  v_bad int;
begin
  if cardinality(v_audit)<>104 then
    raise exception 'written-audit-closure: audit key list must contain 104 entries';
  end if;
  if cardinality(v_learning_no_companion)<>2 or cardinality(v_protected_no_companion)<>16 then
    raise exception 'written-audit-closure: exclusion cardinality changed';
  end if;

  select count(*)::int into v_total
  from private.exam_prep_written_tasks wt
  where wt.lifecycle_state='published' and wt.task_key=any(v_audit);
  if v_total<>104 then
    raise exception 'written-audit-closure: expected 104 published audited tasks, found %',v_total;
  end if;

  select count(*)::int,count(distinct c.written_task_id)::int
    into v_checks,v_checked
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.lifecycle_state='published' and wt.task_key=any(v_audit);
  if v_checks<>89 or v_checked<>86 then
    raise exception 'written-audit-closure: expected 89 checks across 86 audited tasks, got % across %',v_checks,v_checked;
  end if;

  -- No companion is allowed to drift outside the governed audit without explicit
  -- review of this closure contract.
  select count(distinct c.written_task_id)::int into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.lifecycle_state='published'
    and not (wt.task_key=any(v_audit));
  if v_bad<>0 then
    raise exception 'written-audit-closure: % checked tasks exist outside the governed audit',v_bad;
  end if;

  select count(*)::int into v_unchecked
  from private.exam_prep_written_tasks wt
  where wt.lifecycle_state='published' and wt.task_key=any(v_audit)
    and not exists(
      select 1 from private.exam_prep_written_understanding_checks c
      where c.written_task_id=wt.id and c.lifecycle_state='published'
    );
  if v_unchecked<>18 then
    raise exception 'written-audit-closure: expected exactly 18 intentional no-companion tasks, found %',v_unchecked;
  end if;

  -- The only learning-only no-companion tasks are the two cases where a simple
  -- structured check would disclose the central answer/method requested by the task.
  select count(*)::int into v_bad
  from private.exam_prep_written_tasks wt
  where wt.lifecycle_state='published' and wt.task_key=any(v_learning_no_companion)
    and (
      exists(select 1 from private.exam_prep_written_understanding_checks c where c.written_task_id=wt.id and c.lifecycle_state='published')
      or not exists(
        select 1 from private.exam_prep_assessment_items ai
        join private.exam_prep_assessments a on a.id=ai.assessment_id
        where ai.written_task_id=wt.id and a.status='published' and a.assessment_type='learning' and ai.is_holdout is false
      )
      or exists(
        select 1 from private.exam_prep_assessment_items ai
        join private.exam_prep_assessments a on a.id=ai.assessment_id
        where ai.written_task_id=wt.id and a.status='published'
          and (a.assessment_type<>'learning' or ai.is_holdout is true
               or exists(select 1 from private.exam_prep_timed_assessment_contracts tc where tc.assessment_id=a.id and tc.status='published'))
      )
    );
  if v_bad<>0 then
    raise exception 'written-audit-closure: learning no-companion boundary changed for % tasks',v_bad;
  end if;

  -- Protected audit tasks remain unconfigured and must still have a protected
  -- paper/timed/holdout placement.
  select count(*)::int into v_bad
  from private.exam_prep_written_tasks wt
  where wt.lifecycle_state='published' and wt.task_key=any(v_protected_no_companion)
    and (
      exists(select 1 from private.exam_prep_written_understanding_checks c where c.written_task_id=wt.id and c.lifecycle_state='published')
      or not exists(
        select 1 from private.exam_prep_assessment_items ai
        join private.exam_prep_assessments a on a.id=ai.assessment_id
        where ai.written_task_id=wt.id and a.status='published'
          and (a.assessment_type<>'learning' or ai.is_holdout is true
               or exists(select 1 from private.exam_prep_timed_assessment_contracts tc where tc.assessment_id=a.id and tc.status='published'))
      )
    );
  if v_bad<>0 then
    raise exception 'written-audit-closure: protected no-companion boundary changed for % tasks',v_bad;
  end if;

  -- Every unchecked audited task must be in exactly one approved exclusion set.
  select count(*)::int into v_bad
  from private.exam_prep_written_tasks wt
  where wt.lifecycle_state='published' and wt.task_key=any(v_audit)
    and not exists(select 1 from private.exam_prep_written_understanding_checks c where c.written_task_id=wt.id and c.lifecycle_state='published')
    and not (wt.task_key=any(v_learning_no_companion) or wt.task_key=any(v_protected_no_companion));
  if v_bad<>0 then
    raise exception 'written-audit-closure: % unchecked audited tasks are not governed exclusions',v_bad;
  end if;
end $$;

rollback;

select 'WRITTEN_UNDERSTANDING_AUDIT_CLOSURE_GREEN' as result;
