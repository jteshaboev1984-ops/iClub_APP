-- Rebalance one AW21-24 draft written-understanding answer position.
-- History-free draft only; semantic content is unchanged.
begin;
set local lock_timeout='3s';
set local statement_timeout='30s';

do $preflight$
begin
  if not exists(
    select 1
    from private.exam_prep_written_understanding_checks c
    join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
    where c.id=8965 and wt.id=15665 and wt.content_version_id=4821
      and c.lifecycle_state='draft' and wt.lifecycle_state='draft'
      and c.correct_index=1
  ) then
    raise exception 'aw21_24 written-check rebalance: expected draft target missing';
  end if;

  if exists(
    select 1 from private.exam_prep_written_sessions ws
    where ws.written_task_id=15665
  ) or exists(
    select 1 from private.exam_prep_written_session_check_snapshots cs
    where cs.written_task_id=15665
  ) then
    raise exception 'aw21_24 written-check rebalance: target has learner history';
  end if;
end
$preflight$;

update private.exam_prep_written_understanding_checks
set options_en='["Because a tangent has no real contact point","Because every tangent has gradient zero","Because the circle becomes a straight line","Because tangency gives one repeated intersection root"]'::jsonb,
    options_ru='["Потому что у касательной нет действительной точки касания","Потому что у любой касательной градиент равен нулю","Потому что окружность превращается в прямую","Потому что при касании получается один повторный корень пересечения"]'::jsonb,
    options_uz='["Chunki urinmada haqiqiy tegish nuqtasi yo‘q","Chunki har bir urinmaning gradienti nol","Chunki aylana to‘g‘ri chiziqqa aylanadi","Chunki urinmada bitta takroriy kesishish ildizi hosil bo‘ladi"]'::jsonb,
    correct_index=3
where id=8965 and written_task_id=15665 and lifecycle_state='draft';

do $postcheck$
begin
  if not exists(
    select 1 from private.exam_prep_written_understanding_checks
    where id=8965 and written_task_id=15665 and lifecycle_state='draft'
      and correct_index=3
      and options_en->>3='Because tangency gives one repeated intersection root'
      and options_ru->>3='Потому что при касании получается один повторный корень пересечения'
      and options_uz->>3='Chunki urinmada bitta takroriy kesishish ildizi hosil bo‘ladi'
  ) then
    raise exception 'aw21_24 written-check rebalance: semantic option pin failed';
  end if;

  if (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=0)<>5
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=1)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=2)<>4
     or (select count(*) from private.exam_prep_written_understanding_checks where id between 8964 and 8981 and correct_index=3)<>5
  then
    raise exception 'aw21_24 written-check rebalance: final answer-position distribution mismatch';
  end if;
end
$postcheck$;

commit;
