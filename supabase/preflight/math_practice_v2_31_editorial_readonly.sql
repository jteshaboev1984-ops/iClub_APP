-- #574 / #577 — Mathematics Practice v2 editorial candidate: SELECT-ONLY live gate.
-- Safe to rerun. No protected question text/keys or learner data are returned.
-- Gate is valid BEFORE an individually approved future-serving cutover only.
with expected(question_id) as (
  select unnest(array[
    7506,7553,7555,7556,7558,7559,7573,7581,7586,7587,7590,7591,
    7593,7594,7597,7598,7599,7686,7710,7714,7727,7754,7761,7796,
    7809,7818,7829,7835,7838,7894,7900
  ]::bigint[])
), observed as (
 select e.question_id, q.id present_id,
   (q.subject_id=5 and q.is_active is true and
    m.lifecycle_state='published' and m.is_runtime_allowed is true and
    m.qa_math_status='passed' and m.qa_language_status='passed' and
    m.qa_technical_status='passed' and m.qa_tour_separation_status='passed' and
    m.content_key='MATH-P1-PRACTICE2-Q'||lpad((e.question_id-7484)::text,3,'0') and
    m.content_hash is not null and length(m.content_hash)=64) published_eligible,
   (select count(*) from public.practice_pool_questions ppq
     join public.practice_pools p on p.id=ppq.pool_id
     where ppq.question_id=e.question_id and ppq.is_active is true
       and p.is_active is true and p.subject_id=5) active_pool_count,
   (select count(*) from public.tour_questions tq where tq.question_id=e.question_id) tour_links,
   (select count(*) from public.practice_answers a where a.question_id=e.question_id) classic_answers,
   (select count(*) from public.practice_session_answers_v4 a where a.question_id=e.question_id) session_answers,
   (select count(*) from public.practice_drill_answers_v4 a where a.question_id=e.question_id) drill_answers
 from expected e
 left join public.questions q on q.id=e.question_id
 left join private.practice_v2_question_meta m on m.question_id=e.question_id
)
select count(*) target_count,
 count(distinct question_id) unique_target_count,
 count(present_id) live_question_count,
 count(*) filter(where published_eligible is true) eligible_count,
 count(*) filter(where active_pool_count=1) single_pool_count,
 coalesce(sum(tour_links),0) tour_link_count,
 count(*) filter(where classic_answers+session_answers+drill_answers>0) history_bearing_item_count,
 coalesce(sum(classic_answers),0) classic_answer_rows,
 coalesce(sum(session_answers),0) session_answer_rows,
 coalesce(sum(drill_answers),0) drill_answer_rows,
 (count(*)=31 and count(distinct question_id)=31 and count(present_id)=31 and
  count(*) filter(where published_eligible is true)=31 and
  count(*) filter(where active_pool_count=1)=31 and
  coalesce(sum(tour_links),0)=0 and
  count(*) filter(where classic_answers+session_answers+drill_answers>0)>=3) as preflight_ready
from observed;
