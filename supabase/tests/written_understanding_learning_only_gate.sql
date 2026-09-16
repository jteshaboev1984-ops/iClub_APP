\set ON_ERROR_STOP on

begin;

-- Understanding companions are learning support. They must never silently alter
-- a published diagnostic, retest, mixed, timed section, mock or full-paper item.
do $$
declare
  v_checked int;
  v_learning int;
  v_nonlearning int;
  v_timed int;
  v_holdout int;
begin
  select count(distinct c.written_task_id)::int
    into v_checked
  from private.exam_prep_written_understanding_checks c
  where c.lifecycle_state='published';

  select count(distinct c.written_task_id)::int
    into v_learning
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_assessment_items ai on ai.written_task_id=c.written_task_id
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where c.lifecycle_state='published'
    and a.status='published'
    and a.assessment_type='learning';

  if v_checked<>49 or v_learning<>49 then
    raise exception 'written-understanding: expected all 49 checked tasks to have a published learning assessment; checked=%, learning=%',v_checked,v_learning;
  end if;

  select count(distinct c.written_task_id)::int
    into v_nonlearning
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_assessment_items ai on ai.written_task_id=c.written_task_id
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where c.lifecycle_state='published'
    and a.status='published'
    and a.assessment_type<>'learning';

  if v_nonlearning<>0 then
    raise exception 'written-understanding: % checked tasks leaked into published non-learning assessments',v_nonlearning;
  end if;

  select count(distinct c.written_task_id)::int
    into v_timed
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_assessment_items ai on ai.written_task_id=c.written_task_id
  join private.exam_prep_assessments a on a.id=ai.assessment_id and a.status='published'
  join private.exam_prep_timed_assessment_contracts tac on tac.assessment_id=a.id and tac.status='published'
  where c.lifecycle_state='published';

  if v_timed<>0 then
    raise exception 'written-understanding: % checked tasks leaked into published timed assessments',v_timed;
  end if;

  select count(distinct c.written_task_id)::int
    into v_holdout
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_assessment_items ai on ai.written_task_id=c.written_task_id
  join private.exam_prep_assessments a on a.id=ai.assessment_id
  where c.lifecycle_state='published'
    and a.status='published'
    and ai.is_holdout is true;

  if v_holdout<>0 then
    raise exception 'written-understanding: % checked tasks leaked into published holdout items',v_holdout;
  end if;
end $$;

rollback;

select 'WRITTEN_UNDERSTANDING_LEARNING_ONLY_GREEN' as result;
