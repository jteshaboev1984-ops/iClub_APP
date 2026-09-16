begin;

-- Balance the position of correct options across the governed written-understanding
-- surface without changing any mathematical content. Existing versions are never
-- rewritten: rows that need a new option order are retired and replaced by a
-- successor version. P1CIR01-W01 stays exactly on v1 because it is the live
-- history-bearing/reference task and may already be pinned in active sessions.
--
-- The resulting 52 published checks have a 13/13/13/13 correct-position split.
-- Old explicit versions remain evaluable because the established evaluator and
-- session-snapshot resolver accept QA-passed retired versions.

do $$
declare
  v_checks int;
  v_tasks int;
  v_reference int;
  v_nonreference int;
begin
  select count(*)::int,count(distinct written_task_id)::int
    into v_checks,v_tasks
  from private.exam_prep_written_understanding_checks
  where lifecycle_state='published';
  if v_checks<>52 or v_tasks<>49 then
    raise exception 'written-option-balance: expected 52 published checks across 49 tasks, got % across %',v_checks,v_tasks;
  end if;

  select count(*)::int into v_reference
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.task_key='P1CIR01-W01';
  if v_reference<>3 then
    raise exception 'written-option-balance: P1CIR01 reference surface changed: %',v_reference;
  end if;

  select count(*)::int into v_nonreference
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published' and wt.task_key<>'P1CIR01-W01';
  if v_nonreference<>49 then
    raise exception 'written-option-balance: expected 49 non-reference checks, got %',v_nonreference;
  end if;
end $$;

create temporary table _exam_prep_written_option_balance_v1 on commit drop as
with ranked as (
  select
    c.id as source_id,
    c.written_task_id,
    c.check_order,
    c.check_version as source_version,
    c.check_kind,
    c.prompt_en,c.prompt_ru,c.prompt_uz,
    c.options_en,c.options_ru,c.options_uz,
    c.correct_index as source_correct_index,
    c.rationale_en,c.rationale_ru,c.rationale_uz,
    c.qa_math_status,c.qa_language_status,c.qa_technical_status,
    wt.task_key,
    row_number() over (
      order by md5(wt.task_key||':'||c.check_order::text||':'||c.check_version),
               wt.task_key,c.check_order,c.check_version
    ) as rn
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where c.lifecycle_state='published'
    and wt.lifecycle_state='published'
    and wt.task_key<>'P1CIR01-W01'
), planned as (
  select r.*,
    case
      when rn<=13 then 3
      when rn<=25 then 0
      when rn<=37 then 1
      else 2
    end::smallint as target_correct_index
  from ranked r
)
select *
from planned
where source_correct_index<>target_correct_index;

do $$
declare
  v_changed int;
  v_target_dist jsonb;
begin
  select count(*)::int into v_changed
  from _exam_prep_written_option_balance_v1;
  if v_changed<>36 then
    raise exception 'written-option-balance: expected 36 successor versions, got %',v_changed;
  end if;

  select jsonb_object_agg(target_correct_index,cnt order by target_correct_index)
    into v_target_dist
  from (
    with all_nonref as (
      select
        c.correct_index,
        case
          when r.rn<=13 then 3
          when r.rn<=25 then 0
          when r.rn<=37 then 1
          else 2
        end::smallint as target_correct_index
      from private.exam_prep_written_understanding_checks c
      join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
      join (
        select c2.id,
          row_number() over (
            order by md5(wt2.task_key||':'||c2.check_order::text||':'||c2.check_version),
                     wt2.task_key,c2.check_order,c2.check_version
          ) as rn
        from private.exam_prep_written_understanding_checks c2
        join private.exam_prep_written_tasks wt2 on wt2.id=c2.written_task_id
        where c2.lifecycle_state='published'
          and wt2.lifecycle_state='published'
          and wt2.task_key<>'P1CIR01-W01'
      ) r on r.id=c.id
      where c.lifecycle_state='published'
        and wt.lifecycle_state='published'
        and wt.task_key<>'P1CIR01-W01'
    )
    select target_correct_index,count(*)::int as cnt
    from all_nonref
    group by target_correct_index
  ) q;

  if v_target_dist<>jsonb_build_object('0',12,'1',12,'2',12,'3',13) then
    raise exception 'written-option-balance: unexpected non-reference target distribution: %',v_target_dist;
  end if;
end $$;

-- Retire only the exact source versions whose option position needs to move.
update private.exam_prep_written_understanding_checks c
set lifecycle_state='retired'
from _exam_prep_written_option_balance_v1 b
where c.id=b.source_id
  and c.lifecycle_state='published';

-- Publish additive successor versions. jsonb_insert moves the existing correct
-- option to its governed target position while preserving distractor order and
-- keeping EN/RU/UZ arrays aligned.
insert into private.exam_prep_written_understanding_checks(
  written_task_id,check_order,check_version,check_kind,
  prompt_en,prompt_ru,prompt_uz,
  options_en,options_ru,options_uz,correct_index,
  rationale_en,rationale_ru,rationale_uz,
  lifecycle_state,qa_math_status,qa_language_status,qa_technical_status,approved_at
)
select
  b.written_task_id,
  b.check_order,
  b.source_version||'-bal1',
  b.check_kind,
  b.prompt_en,b.prompt_ru,b.prompt_uz,
  jsonb_insert(b.options_en - b.source_correct_index,array[b.target_correct_index::text],b.options_en->b.source_correct_index,false),
  jsonb_insert(b.options_ru - b.source_correct_index,array[b.target_correct_index::text],b.options_ru->b.source_correct_index,false),
  jsonb_insert(b.options_uz - b.source_correct_index,array[b.target_correct_index::text],b.options_uz->b.source_correct_index,false),
  b.target_correct_index,
  b.rationale_en,b.rationale_ru,b.rationale_uz,
  'published',b.qa_math_status,b.qa_language_status,b.qa_technical_status,now()
from _exam_prep_written_option_balance_v1 b
order by b.task_key,b.check_order;

-- Acceptance: published surface/cardinality is unchanged, answer positions are
-- balanced, reference v1 rows are untouched, and every successor is a pure option
-- permutation of its retired source with identical learner text/rationale.
do $$
declare
  v_checks int;
  v_tasks int;
  v_single int;
  v_multi int;
  v_max int;
  v_dist jsonb;
  v_pairs int;
  v_bad int;
  v_ref_bad int;
begin
  select count(*)::int,count(distinct written_task_id)::int
    into v_checks,v_tasks
  from private.exam_prep_written_understanding_checks
  where lifecycle_state='published';
  if v_checks<>52 or v_tasks<>49 then
    raise exception 'written-option-balance: published scope changed after versioning: %/%',v_checks,v_tasks;
  end if;

  select count(*) filter(where cnt=1)::int,
         count(*) filter(where cnt>1)::int,
         max(cnt)::int
    into v_single,v_multi,v_max
  from (
    select written_task_id,count(*)::int cnt
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
    group by written_task_id
  ) q;
  if v_single<>47 or v_multi<>2 or v_max<>3 then
    raise exception 'written-option-balance: per-task cardinality changed: single %, multi %, max %',v_single,v_multi,v_max;
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
    raise exception 'written-option-balance: final answer-position distribution is not 13/13/13/13: %',v_dist;
  end if;

  select count(*)::int into v_ref_bad
  from private.exam_prep_written_understanding_checks c
  join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
  where wt.task_key='P1CIR01-W01'
    and (c.lifecycle_state<>'published' or c.check_version<>'v1');
  if v_ref_bad<>0 then
    raise exception 'written-option-balance: P1CIR01 v1 reference rows were changed';
  end if;

  select count(*)::int into v_pairs
  from _exam_prep_written_option_balance_v1 b
  join private.exam_prep_written_understanding_checks oldc
    on oldc.id=b.source_id
   and oldc.lifecycle_state='retired'
  join private.exam_prep_written_understanding_checks newc
    on newc.written_task_id=b.written_task_id
   and newc.check_order=b.check_order
   and newc.check_version=b.source_version||'-bal1'
   and newc.lifecycle_state='published';
  if v_pairs<>36 then
    raise exception 'written-option-balance: expected 36 retired/published version pairs, got %',v_pairs;
  end if;

  select count(*)::int into v_bad
  from _exam_prep_written_option_balance_v1 b
  join private.exam_prep_written_understanding_checks oldc on oldc.id=b.source_id
  join private.exam_prep_written_understanding_checks newc
    on newc.written_task_id=b.written_task_id
   and newc.check_order=b.check_order
   and newc.check_version=b.source_version||'-bal1'
  where oldc.lifecycle_state<>'retired'
     or newc.lifecycle_state<>'published'
     or oldc.prompt_en<>newc.prompt_en or oldc.prompt_ru<>newc.prompt_ru or oldc.prompt_uz<>newc.prompt_uz
     or oldc.rationale_en<>newc.rationale_en or oldc.rationale_ru<>newc.rationale_ru or oldc.rationale_uz<>newc.rationale_uz
     or oldc.check_kind<>newc.check_kind
     or newc.correct_index<>b.target_correct_index
     or newc.options_en->newc.correct_index<>oldc.options_en->oldc.correct_index
     or newc.options_ru->newc.correct_index<>oldc.options_ru->oldc.correct_index
     or newc.options_uz->newc.correct_index<>oldc.options_uz->oldc.correct_index
     or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_en) e(value))
        <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_en) e(value))
     or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_ru) e(value))
        <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_ru) e(value))
     or (select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(newc.options_uz) e(value))
        <>(select jsonb_agg(e.value order by e.value::text) from jsonb_array_elements(oldc.options_uz) e(value));
  if v_bad<>0 then
    raise exception 'written-option-balance: % successor rows changed content instead of option order only',v_bad;
  end if;

  -- All existing session snapshots must still resolve to a QA-passed published or
  -- retired version after the balance migration.
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
    raise exception 'written-option-balance: % session snapshot versions became unresolvable',v_bad;
  end if;

  -- Learner-safe current payloads remain key/rationale-free.
  select count(*)::int into v_bad
  from (
    select distinct written_task_id
    from private.exam_prep_written_understanding_checks
    where lifecycle_state='published'
  ) t
  cross join (values('en'),('ru'),('uz')) l(lang)
  cross join lateral (
    select private.exam_prep_written_understanding_payload_v1(t.written_task_id,l.lang) payload
  ) p
  where p.payload::text ~ 'correct_index|rationale|all_correct|is_correct';
  if v_bad<>0 then
    raise exception 'written-option-balance: learner-safe payload leaked private evaluation data';
  end if;
end $$;

commit;
