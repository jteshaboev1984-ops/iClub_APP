-- Mathematics Season 2 subject-scoped, SELECT-only source readiness report.
-- Structural evidence only; no question keys/stems leave the database.
-- No season dates, backend changes, Academic PASS, or production GO implied.
WITH tm AS (
 SELECT t.id,t.tour_no,t.is_active,t.start_date,t.end_date
 FROM public.tours t JOIN public.seasons s ON s.id=t.season_id
 WHERE s.season_no=2 AND t.subject_id=5
), per_tour AS (
 SELECT t.tour_no,
 count(tq.id)::int links,
 count(DISTINCT tq.question_id)::int ids,
 count(DISTINCT tq.order_no)::int orders,
 min(tq.order_no)::int min_order,max(tq.order_no)::int max_order,
 count(*) FILTER (WHERE tq.is_active AND q.is_active)::int active_items,
 count(*) FILTER (WHERE q.difficulty='easy')::int easy,
 count(*) FILTER (WHERE q.difficulty='medium')::int medium,
 count(*) FILTER (WHERE q.difficulty='hard')::int hard,
 count(*) FILTER (WHERE q.qtype='mcq')::int mcq,
 count(*) FILTER (WHERE q.qtype='input')::int input,
 count(*) FILTER (WHERE q.difficulty='hard' AND nullif(trim(q.image_url),'') IS NOT NULL)::int hard_images,
 count(*) FILTER (WHERE nullif(trim(q.question_text_en),'') IS NULL
 OR nullif(trim(q.question_text_ru),'') IS NULL
 OR nullif(trim(q.question_text_uz),'') IS NULL
 OR nullif(trim(q.explanation_en),'') IS NULL
 OR nullif(trim(q.explanation_ru),'') IS NULL
 OR nullif(trim(q.explanation_uz),'') IS NULL
 OR q.time_limit_sec IS NULL OR q.time_limit_sec<=0
 OR nullif(trim(q.book_ref),'') IS NULL)::int incomplete,
 count(*) FILTER (WHERE (q.qtype='mcq' AND (
  q.correct_answer NOT IN ('A','B','C','D')
  OR jsonb_array_length(q.options_text_en::jsonb)<>4
  OR jsonb_array_length(q.options_text_ru::jsonb)<>4
  OR jsonb_array_length(q.options_text_uz::jsonb)<>4))
  OR (q.qtype='input' AND (
  nullif(trim(q.correct_answer),'') IS NULL
  OR q.options_text_en::jsonb<>'[]'::jsonb
  OR q.options_text_ru::jsonb<>'[]'::jsonb
  OR q.options_text_uz::jsonb<>'[]'::jsonb)))::int bad_answer_shape,
 md5(string_agg(tq.question_id::text||':'||tq.order_no::text,'|' ORDER BY tq.order_no)) manifest_md5
 FROM tm t LEFT JOIN public.tour_questions tq ON tq.tour_id=t.id
 LEFT JOIN public.questions q ON q.id=tq.question_id
 GROUP BY t.tour_no
), overlap_counts AS (
 SELECT
 (SELECT count(*) FROM (SELECT tq.question_id
   FROM tm t JOIN public.tour_questions tq ON tq.tour_id=t.id
   WHERE tq.is_active GROUP BY tq.question_id HAVING count(*)>1) x)::int internal_duplicates,
 (SELECT count(DISTINCT a.question_id)
   FROM tm t JOIN public.tour_questions a ON a.tour_id=t.id
   JOIN public.tour_questions b ON b.question_id=a.question_id
   JOIN public.tours t1 ON t1.id=b.tour_id
   JOIN public.seasons s1 ON s1.id=t1.season_id
   WHERE s1.season_no=1 AND t1.subject_id=5 AND a.is_active AND b.is_active)::int s1_overlap,
 (SELECT count(DISTINCT a.question_id)
   FROM tm t JOIN public.tour_questions a ON a.tour_id=t.id
   JOIN public.practice_pool_questions ppq ON ppq.question_id=a.question_id
   JOIN public.practice_pools pp ON pp.id=ppq.pool_id
   WHERE pp.subject_id=5 AND pp.is_active AND ppq.is_active AND a.is_active)::int practice_overlap
)
-- Do not infer 'unseen' merely from zero Tour attempts. Record actual
-- issue/history tables and the public catalogue separately; external downloads
-- cannot be reconstructed from these counts.
, s2ids AS (
 SELECT DISTINCT tq.question_id id FROM tm t
 JOIN public.tour_questions tq ON tq.tour_id=t.id
), use_checks AS (
 SELECT
 (SELECT count(*) FROM public.tour_attempts a JOIN tm t ON t.id=a.tour_id)::int s2_attempts,
 (SELECT count(*) FROM public.tour_session_runtime_v4 a JOIN tm t ON t.id=a.tour_id)::int s2_runtime,
 (SELECT count(*) FROM public.tour_answers a JOIN s2ids q ON q.id=a.question_id)::int tour_answers,
 (SELECT count(*) FROM public.tour_session_answers_v4 a JOIN s2ids q ON q.id=a.question_id)::int tour_session_answers,
 (SELECT count(*) FROM public.practice_answers a JOIN s2ids q ON q.id=a.question_id)::int practice_answers,
 (SELECT count(*) FROM public.practice_session_answers_v4 a JOIN s2ids q ON q.id=a.question_id)::int practice_session_answers,
 (SELECT count(*) FROM public.practice_drill_answers_v4 a JOIN s2ids q ON q.id=a.question_id)::int practice_drill_answers,
 (SELECT count(*) FROM public.practice_sessions_v4 a
   WHERE a.question_ids && array(SELECT id FROM s2ids))::int practice_sessions_issued,
 (SELECT count(*) FROM public.practice_drill_sessions_v4 a
   WHERE a.question_ids && array(SELECT id FROM s2ids))::int practice_drill_sessions_issued,
 (SELECT count(*) FROM public.tour_session_runtime_v4 a
   WHERE a.question_ids && array(SELECT id FROM s2ids))::int tour_sessions_issued,
 (SELECT count(*) FROM public.tour_questions a JOIN s2ids q ON q.id=a.question_id
   WHERE a.tour_id NOT IN(SELECT id FROM tm))::int other_tour_assignments,
 (SELECT count(*) FROM public.practice_pool_questions a JOIN s2ids q ON q.id=a.question_id)::int any_practice_assignments,
 (SELECT count(*) FROM private.exam_prep_assessment_items a JOIN s2ids q ON q.id=a.question_id)::int exam_prep_reservations,
 (SELECT count(*) FROM public.question_version_links a
   WHERE a.old_question_id IN(SELECT id FROM s2ids)
     OR a.new_question_id IN(SELECT id FROM s2ids))::int version_links,
 (SELECT count(*) FROM public.safe_questions_public v JOIN s2ids q ON q.id=v.id)::int public_catalogue_visible_rows
)
SELECT
 (SELECT count(*) FROM tm)::int math_s2_tours,
 (SELECT count(*) FROM tm WHERE NOT is_active AND start_date IS NULL AND end_date IS NULL)::int draft_undated,
 (SELECT sum(links)::int FROM per_tour) total_links,
 (SELECT count(*) FROM per_tour WHERE links=20 AND ids=20 AND orders=20
   AND min_order=1 AND max_order=20 AND active_items=20
   AND easy=6 AND medium=9 AND hard=5 AND mcq=16 AND input=4
   AND hard_images=1 AND incomplete=0 AND bad_answer_shape=0)::int structure_pass_tours,
 internal_duplicates,s1_overlap,practice_overlap,
 uc.s2_attempts,uc.s2_runtime,uc.tour_answers,uc.tour_session_answers,
 uc.practice_answers,uc.practice_session_answers,uc.practice_drill_answers,
 uc.practice_sessions_issued,uc.practice_drill_sessions_issued,uc.tour_sessions_issued,
 uc.other_tour_assignments,uc.any_practice_assignments,
 uc.exam_prep_reservations,uc.version_links,
 uc.public_catalogue_visible_rows,
 (uc.s2_attempts+uc.s2_runtime+uc.tour_answers+uc.tour_session_answers
  +uc.practice_answers+uc.practice_session_answers+uc.practice_drill_answers
  +uc.practice_sessions_issued+uc.practice_drill_sessions_issued+uc.tour_sessions_issued
  +uc.other_tour_assignments+uc.any_practice_assignments
  +uc.exam_prep_reservations+uc.version_links)=0 AS no_recorded_use_or_scope_references,
 uc.public_catalogue_visible_rows=0 AS public_catalogue_sealed,
 (SELECT jsonb_agg(jsonb_build_object('tour',tour_no,'md5',manifest_md5) ORDER BY tour_no)
    FROM per_tour) manifest,
 (SELECT count(*)=7 FROM per_tour WHERE links=20 AND ids=20 AND orders=20
   AND min_order=1 AND max_order=20 AND active_items=20
   AND easy=6 AND medium=9 AND hard=5 AND mcq=16 AND input=4
   AND hard_images=1 AND incomplete=0 AND bad_answer_shape=0)
   AND internal_duplicates=0 AND s1_overlap=0 AND practice_overlap=0 AS structure_ready,
 false AS final_academic_and_release_go
FROM overlap_counts CROSS JOIN use_checks uc;