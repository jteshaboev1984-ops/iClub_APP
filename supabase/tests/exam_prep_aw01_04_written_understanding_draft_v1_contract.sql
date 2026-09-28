-- Contract for draft written-understanding checks attached to AW1-4 alternate packs.
begin;
do $$
declare
  v_bad int;
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8901 and 8909
        and written_task_id between 15601 and 15609
        and lifecycle_state='draft'
        and qa_math_status='pending'
        and qa_language_status='pending'
        and qa_technical_status='pending')<>9
  then
    raise exception 'aw01_04_written_checks_v1 draft set missing';
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
    );
  if v_bad<>0 then
    raise exception 'aw01_04_written_checks_v1 structural/trilingual rows invalid=%',v_bad;
  end if;

  -- Draft checks are invisible to learner payloads in all supported languages.
  select count(*) into v_bad
  from generate_series(15601,15609) wt(id)
  cross join (values('en'),('ru'),('uz')) l(lang)
  where private.exam_prep_written_understanding_payload_v1(wt.id,l.lang)<>'[]'::jsonb;
  if v_bad<>0 then
    raise exception 'aw01_04_written_checks_v1 draft check leaked into learner payload rows=%',v_bad;
  end if;

  -- Parent written tasks are also still draft and unapproved.
  if exists(
    select 1
    from private.exam_prep_written_tasks wt
    where wt.id between 15601 and 15609
      and (
        wt.lifecycle_state<>'draft'
        or wt.qa_math_status<>'pending'
        or wt.qa_language_status<>'pending'
        or wt.qa_technical_status<>'pending'
      )
  ) then
    raise exception 'aw01_04_written_checks_v1 parent written task state drift';
  end if;

  -- Correct-index diversity guard catches accidental "always first option" authoring.
  if (select count(distinct correct_index) from private.exam_prep_written_understanding_checks where id between 8901 and 8909)<3 then
    raise exception 'aw01_04_written_checks_v1 correct-index diversity too low';
  end if;
end
$$;
rollback;
