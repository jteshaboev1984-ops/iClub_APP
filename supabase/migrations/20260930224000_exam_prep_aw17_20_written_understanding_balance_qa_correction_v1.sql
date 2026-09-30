-- AW17-20 written-understanding answer-position QA correction v1.
-- Draft/history-free checks only. Reorders options without changing semantic content.
begin;
set local lock_timeout='3s';
set local statement_timeout='60s';

do $preflight$
begin
  if (select count(*) from private.exam_prep_written_understanding_checks
      where id between 8953 and 8963
        and lifecycle_state='draft'
        and check_version='aw18-v1')<>11 then
    raise exception 'aw17_20 check-balance QA: expected 11 draft checks';
  end if;

  if exists(
    select 1
    from private.exam_prep_written_session_check_snapshots cs
    where cs.written_task_id in (15653,15654)
  ) then
    raise exception 'aw17_20 check-balance QA: target draft checks already have session snapshots';
  end if;
end
$preflight$;

-- Move P1SER03-AW18 correct semantic option from index 0 to index 2.
update private.exam_prep_written_understanding_checks
set options_en='["Every arithmetic progression starts at zero","The two known terms must be consecutive","The first term cancels and the remaining difference equals the gap in term numbers multiplied by d","The sum formula always gives d directly"]'::jsonb,
    options_ru='["Любая арифметическая прогрессия начинается с нуля","Два известных члена обязательно должны быть соседними","Первый член сокращается, а оставшаяся разность равна разности номеров членов, умноженной на d","Формула суммы всегда напрямую даёт d"]'::jsonb,
    options_uz='["Har bir arifmetik progressiya noldan boshlanadi","Ikki ma’lum had albatta ketma-ket bo‘lishi kerak","Birinchi had qisqaradi va qolgan ayirma had raqamlari farqining d ga ko‘paytmasiga teng bo‘ladi","Yig‘indi formulasi d ni doim bevosita beradi"]'::jsonb,
    correct_index=2
where id=8953
  and written_task_id=15653
  and lifecycle_state='draft'
  and correct_index=0;

-- Move P1SER04-AW18 correct semantic option from index 1 to index 3.
update private.exam_prep_written_understanding_checks
set options_en='["It changes a geometric progression into an arithmetic progression","It always makes the quotient equal to r","It removes all powers of r","The first term cancels and the quotient becomes r³"]'::jsonb,
    options_ru='["Это превращает геометрическую прогрессию в арифметическую","Отношение всегда сразу равно r","Все степени r исчезают","Первый член сокращается, и отношение становится r³"]'::jsonb,
    options_uz='["Bu geometrik progressiyani arifmetik progressiyaga aylantiradi","Nisbat har doim darhol r ga teng bo‘ladi","r ning barcha darajalari yo‘qoladi","Birinchi had qisqaradi va nisbat r³ ga teng bo‘ladi"]'::jsonb,
    correct_index=3
where id=8954
  and written_task_id=15654
  and lifecycle_state='draft'
  and correct_index=1;

do $postcheck$
declare
  v_dist jsonb;
  v_bad int;
begin
  select jsonb_object_agg(correct_index,n order by correct_index) into v_dist
  from (
    select correct_index,count(*)::int n
    from private.exam_prep_written_understanding_checks
    where id between 8953 and 8963
    group by correct_index
  ) x;

  if v_dist<>jsonb_build_object('0',2,'1',2,'2',4,'3',3) then
    raise exception 'aw17_20 check-balance QA: local distribution mismatch=%',v_dist;
  end if;

  select count(*) into v_bad
  from private.exam_prep_written_understanding_checks c
  where c.id in (8953,8954)
    and (
      c.lifecycle_state<>'draft'
      or c.qa_math_status<>'pending'
      or c.qa_language_status<>'pending'
      or c.qa_technical_status<>'pending'
      or c.check_version<>'aw18-v1'
      or jsonb_array_length(c.options_en)<>4
      or jsonb_array_length(c.options_ru)<>4
      or jsonb_array_length(c.options_uz)<>4
    );
  if v_bad<>0 then
    raise exception 'aw17_20 check-balance QA: target row state drift=%',v_bad;
  end if;

  if not exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id=8953 and correct_index=2
      and options_en->>2='The first term cancels and the remaining difference equals the gap in term numbers multiplied by d'
  ) or not exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id=8954 and correct_index=3
      and options_en->>3='The first term cancels and the quotient becomes r³'
  ) then
    raise exception 'aw17_20 check-balance QA: correct semantic option moved incorrectly';
  end if;
end
$postcheck$;

commit;
