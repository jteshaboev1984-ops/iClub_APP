-- AW17-20 supplemental-learning release v1 contract.
\set ON_ERROR_STOP on

DO $$
DECLARE
  v1 jsonb;
  v2 jsonb;
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='published')<>2 then
    raise exception 'aw17_20 learning release: target versions not published';
  end if;

  if (select count(*) from private.exam_prep_content_release_profiles_v1
      where content_version_id in (4817,4818)
        and release_mode='supplemental_learning'
        and profile_version='aw17_20_alt_release_v1'
        and require_written_understanding)<>2 then
    raise exception 'aw17_20 learning release: profile mismatch';
  end if;

  v1:=private.exam_prep_supplemental_learning_floor_v1(4817);
  v2:=private.exam_prep_supplemental_learning_floor_v1(4818);

  if coalesce((v1->>'ready')::boolean,false) is not true
     or coalesce((v2->>'ready')::boolean,false) is not true then
    raise exception 'aw17_20 learning release: supplemental floor red P1=% P5=%',v1,v2;
  end if;

  if (v1#>>'{counts,skills}')::int<>6
     or (v1#>>'{counts,questions}')::int<>18
     or (v1#>>'{counts,assessments}')::int<>6
     or (v1#>>'{counts,written_tasks}')::int<>6
     or (v1#>>'{counts,written_understanding_checks}')::int<>6
     or (v2#>>'{counts,skills}')::int<>5
     or (v2#>>'{counts,questions}')::int<>15
     or (v2#>>'{counts,assessments}')::int<>5
     or (v2#>>'{counts,written_tasks}')::int<>5
     or (v2#>>'{counts,written_understanding_checks}')::int<>5 then
    raise exception 'aw17_20 learning release: floor cardinality mismatch P1=% P5=%',v1,v2;
  end if;

  if exists(
    select 1 from private.exam_prep_question_content_meta m
    join public.questions q on q.id=m.question_id
    where m.content_version_id in (4817,4818)
      and (q.is_active or q.quality_status<>'draft')
  ) then raise exception 'aw17_20 learning release: public source isolation changed'; end if;

  if (select count(*) from private.exam_prep_written_understanding_checks
      where lifecycle_state='published')<>133
     or (select count(distinct written_task_id)
         from private.exam_prep_written_understanding_checks
         where lifecycle_state='published')<>130 then
    raise exception 'aw17_20 learning release: written-understanding surface mismatch after later governed releases';
  end if;

  if exists(
    select 1 from private.exam_prep_sessions s join private.exam_prep_assessments a on a.id=s.assessment_id
    where a.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.practice_answers pa join private.exam_prep_question_content_meta m on m.question_id=pa.question_id
    where m.content_version_id in (4817,4818)
  ) or exists(
    select 1 from public.tour_answers ta join private.exam_prep_question_content_meta m on m.question_id=ta.question_id
    where m.content_version_id in (4817,4818)
  ) then raise exception 'aw17_20 learning release: target history unexpectedly exists in CI fixture'; end if;
END
$$;

BEGIN;

update private.exam_prep_assessments
set status='retired'
where content_version_id in (4817,4818) and status='published';

update private.exam_prep_question_content_meta
set lifecycle_state='retired',exposure_state='retired',updated_at=now()
where content_version_id in (4817,4818)
  and lifecycle_state='published' and exposure_state='released';

update private.exam_prep_written_understanding_checks c
set lifecycle_state='retired'
from private.exam_prep_written_tasks wt
where wt.id=c.written_task_id
  and wt.content_version_id in (4817,4818)
  and c.lifecycle_state='published';

update private.exam_prep_written_tasks
set lifecycle_state='retired'
where content_version_id in (4817,4818) and lifecycle_state='published';

update private.exam_prep_content_versions
set status='retired',retired_at=now()
where id in (4817,4818) and status='published';

DO $$
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='retired')<>2
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4817,4818) and status='retired')<>11
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4817,4818)
           and lifecycle_state='retired' and exposure_state='retired')<>33
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id in (4817,4818) and lifecycle_state='retired')<>11
     or (select count(*) from private.exam_prep_written_understanding_checks c
         join private.exam_prep_written_tasks wt on wt.id=c.written_task_id
         where wt.content_version_id in (4817,4818) and c.lifecycle_state='retired')<>11 then
    raise exception 'aw17_20 learning release: retirement rehearsal failed';
  end if;

  if (select count(*) from private.exam_prep_question_content_meta where content_version_id in (4817,4818))<>33
     or (select count(*) from private.exam_prep_written_tasks where content_version_id in (4817,4818))<>11
     or (select count(*) from private.exam_prep_assessments where content_version_id in (4817,4818))<>11 then
    raise exception 'aw17_20 learning release: retirement deleted governed rows';
  end if;
END
$$;

ROLLBACK;

DO $$
BEGIN
  if (select count(*) from private.exam_prep_content_versions
      where id in (4817,4818) and status='published')<>2
     or (select count(*) from private.exam_prep_assessments
         where content_version_id in (4817,4818) and status='published')<>11
     or (select count(*) from private.exam_prep_question_content_meta
         where content_version_id in (4817,4818)
           and lifecycle_state='published' and exposure_state='released')<>33
     or (select count(*) from private.exam_prep_written_tasks
         where content_version_id in (4817,4818) and lifecycle_state='published')<>11 then
    raise exception 'aw17_20 learning release: rollback did not restore governed release';
  end if;
END
$$;

\echo 'AW17-20 supplemental-learning release v1 contract: GREEN'
