-- Historical filename retained for CI stability.
-- Release contract for written-understanding companions attached to the AW1-4
-- supplemental learning packs.
begin;
do $$
declare
  v_bad int;
  v_payload jsonb;
  v_eval jsonb;
  r record;
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8901 and 8909
        and written_task_id between 15601 and 15609
        and lifecycle_state='published'
        and qa_math_status='pass'
        and qa_language_status='pass'
        and qa_technical_status='pass'
        and approved_at is not null)<>9
  then
    raise exception 'aw01_04_written_checks_v1 published set missing';
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  where c.id between 8901 and 8909
    and (
      c.check_kind<>'mcq'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
      or c.correct_index not between 0 and 3
      or nullif(btrim(c.prompt_en),'') is null
      or nullif(btrim(c.prompt_ru),'') is null
      or nullif(btrim(c.prompt_uz),'') is null
      or nullif(btrim(c.rationale_en),'') is null
      or nullif(btrim(c.rationale_ru),'') is null
      or nullif(btrim(c.rationale_uz),'') is null
      or nullif(btrim(c.check_version),'') is null
    );
  if v_bad<>0 then
    raise exception 'aw01_04_written_checks_v1 structural/trilingual rows invalid=%',v_bad;
  end if;

  -- Parent written tasks are fully governed learning tasks.
  if (select count(*) from private.exam_prep_written_tasks wt
      where wt.id between 15601 and 15609
        and wt.lifecycle_state='published'
        and wt.copyright_status='pass'
        and wt.qa_math_status='pass'
        and wt.qa_language_status='pass'
        and wt.qa_technical_status='pass')<>9
  then
    raise exception 'aw01_04_written_checks_v1 parent written task publication drift';
  end if;

  -- Every supported language exposes exactly one safe companion; answer keys and
  -- rationales remain server-private.
  select count(*) into v_bad
  from generate_series(15601,15609) wt(id)
  cross join (values('en'),('ru'),('uz')) l(lang)
  cross join lateral (
    select private.exam_prep_written_understanding_payload_v1(wt.id,l.lang) payload
  ) p
  where jsonb_array_length(p.payload)<>1
     or p.payload::text ~ 'correct_index|rationale|all_correct|is_correct'
     or coalesce(p.payload->0->>'check_version','')<>'v1';
  if v_bad<>0 then
    raise exception 'aw01_04_written_checks_v1 safe learner payload failures=%',v_bad;
  end if;

  -- Exact answer-position map and deterministic evaluator result.
  for r in
    select * from (values
      (8901,15601,0),(8902,15602,1),(8903,15603,2),
      (8904,15604,3),(8905,15605,0),(8906,15606,1),
      (8907,15607,2),(8908,15608,3),(8909,15609,3)
    ) x(check_id,written_task_id,correct_index)
  loop
    if not exists(
      select 1 from private.exam_prep_written_understanding_checks c
      where c.id=r.check_id
        and c.written_task_id=r.written_task_id
        and c.correct_index=r.correct_index
        and c.check_order=1
        and c.check_version='v1'
        and c.lifecycle_state='published'
    ) then
      raise exception 'aw01_04_written_checks_v1 expected mapping missing check=%',r.check_id;
    end if;

    v_eval:=private.exam_prep_evaluate_written_understanding_v1(
      r.written_task_id,
      jsonb_build_array(jsonb_build_object(
        'check_order',1,
        'check_version','v1',
        'picked_index',r.correct_index
      ))
    );
    if coalesce((v_eval->>'configured')::boolean,false) is not true
       or coalesce((v_eval->>'submitted')::boolean,false) is not true
       or coalesce((v_eval->>'all_correct')::boolean,false) is not true
       or coalesce((v_eval->>'correct')::int,-1)<>1
    then
      raise exception 'aw01_04_written_checks_v1 deterministic evaluation failed task=% eval=%',r.written_task_id,v_eval;
    end if;
  end loop;

  if (select jsonb_object_agg(correct_index,n order by correct_index)
      from (
        select correct_index,count(*)::int n
        from private.exam_prep_written_understanding_checks
        where id between 8901 and 8909
        group by correct_index
      ) d)<>jsonb_build_object('0',2,'1',2,'2',2,'3',3)
  then
    raise exception 'aw01_04_written_checks_v1 new-pack answer-position balance drift';
  end if;

  -- The global published surface remains near-even after adding the nine checks.
  if (select jsonb_object_agg(correct_index,n order by correct_index)
      from (
        select correct_index,count(*)::int n
        from private.exam_prep_written_understanding_checks
        where lifecycle_state='published'
        group by correct_index
      ) d)<>jsonb_build_object('0',15,'1',15,'2',15,'3',16)
  then
    raise exception 'aw01_04_written_checks_v1 global answer-position balance drift';
  end if;
end
$$;
rollback;
