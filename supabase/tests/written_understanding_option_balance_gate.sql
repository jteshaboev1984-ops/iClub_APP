\set ON_ERROR_STOP on

begin;

-- A visible answer-position pattern is a learner-facing correctness leak even when
-- the actual answer key stays private. The governed surface therefore keeps an
-- even distribution while preserving additive version history.
do $$
declare
  v_checks int;
  v_tasks int;
  v_dist jsonb;
  v_successors int;
  v_pairs int;
  v_bad int;
begin
  select count(*)::int,count(distinct written_task_id)::int
    into v_checks,v_tasks
  from private.exam_prep_written_understanding_checks
  where lifecycle_state='published';
  if v_checks<>52 or v_tasks<>49 then
    raise exception 'written-option-balance-gate: expected 52/49 published surface, got %/%',v_checks,v_tasks;
  end if;

  select jsonb_object_agg(correct_index,cnt order by correct_index)
    into v_dist
  from (
    select correct_index,count(*)::int cnt
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
    group by correct_index
  ) q;
  if v_dist<>jsonb_build_object('0',13,'1',13,'2',13,'3',13) then
    raise exception 'written-option-balance-gate: expected 13/13/13/13, got %',v_dist;
  end if;

  -- The history-bearing active/reference task is intentionally never re-versioned
  -- by the balancing migration.
  select count(*)::int into v_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key='P1CIR01-W01'
    and (c.lifecycle_state<>'published' or c.check_version<>'v1');
  if v_bad<>0 then
    raise exception 'written-option-balance-gate: P1CIR01 reference versions changed';
  end if;

  select count(*)::int into v_successors
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published'
    and wt.task_key<>'P1CIR01-W01'
    and right(c.check_version,5)='-bal1';
  if v_successors<>36 then
    raise exception 'written-option-balance-gate: expected 36 balanced successor versions, got %',v_successors;
  end if;

  select count(*)::int into v_pairs
  from private.exam_prep_written_understanding_checks newc
  join private.exam_prep_written_understanding_checks oldc
    on oldc.written_task_id=newc.written_task_id
   and oldc.check_order=newc.check_order
   and newc.check_version=oldc.check_version||'-bal1'
   and oldc.lifecycle_state='retired'
  join private.exam_prep_written_tasks wt on wt.id=newc.written_task_id
  where newc.lifecycle_state='published'
    and right(newc.check_version,5)='-bal1'
    and wt.task_key<>'P1CIR01-W01';
  if v_pairs<>36 then
    raise exception 'written-option-balance-gate: balanced successor/source pairing failed: %',v_pairs;
  end if;

  -- Successor versions may change option order only. Prompt/rationale, correct
  -- semantic option and the option multiset in each language must be identical.
  select count(*)::int into v_bad
  from private.exam_prep_written_understanding_checks newc
  join private.exam_prep_written_understanding_checks oldc
    on oldc.written_task_id=newc.written_task_id
   and oldc.check_order=newc.check_order
   and newc.check_version=oldc.check_version||'-bal1'
   and oldc.lifecycle_state='retired'
  where newc.lifecycle_state='published'
    and right(newc.check_version,5)='-bal1'
    and (
      newc.prompt_en<>oldc.prompt_en or newc.prompt_ru<>oldc.prompt_ru or newc.prompt_uz<>oldc.prompt_uz
      or newc.rationale_en<>oldc.rationale_en or newc.rationale_ru<>oldc.rationale_ru or newc.rationale_uz<>oldc.rationale_uz
      or newc.options_en->newc.correct_index<>oldc.options_en->oldc.correct_index
      or newc.options_ru->newc.correct_index<>oldc.options_ru->oldc.correct_index
      or newc.options_uz->newc.correct_index<>oldc.options_uz->oldc.correct_index
      or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_en) e(value))
         <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_en) e(value))
      or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_ru) e(value))
         <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_ru) e(value))
      or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_uz) e(value))
         <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_uz) e(value))
    );
  if v_bad<>0 then
    raise exception 'written-option-balance-gate: % successor versions changed semantic content',v_bad;
  end if;

  -- Any session-pinned old version remains resolvable after its source row retires.
  select count(*)::int into v_bad
  from private.exam_prep_written_session_check_snapshots cs
  cross join lateral jsonb_array_elements(cs.check_versions) s(value)
  left join private.exam_prep_written_understanding_checks c
    on c.written_task_id=cs.written_task_id
   and c.check_order=nullif(s.value->>'check_order','')::int
   and c.check_version=nullif(btrim(coalesce(s.value->>'check_version','')),'')
   and c.lifecycle_state in ('published','retired')
   and c.qa_math_status='pass' and c.qa_language_status='pass' and c.qa_technical_status='pass'
  where c.id is null;
  if v_bad<>0 then
    raise exception 'written-option-balance-gate: % pinned versions are unresolvable',v_bad;
  end if;
end $$;

rollback;

select 'WRITTEN_UNDERSTANDING_OPTION_BALANCE_GREEN' as result;
