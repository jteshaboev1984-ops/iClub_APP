-- READ-ONLY investigation and future release baseline. This file contains NO writes.
-- Production is live: compare with the LAST captured fingerprint and with
-- legitimate user events; do not demand equality when students have new activity.
-- No learner ID, response text or answer key is returned by this query.
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ READ ONLY;
WITH
attempts AS (
  SELECT count(*)::bigint AS n, min(id) AS first_id, max(id) AS last_id,
         md5(coalesce(string_agg(md5(to_jsonb(p)::text),'' ORDER BY id),'')) AS fingerprint,
         count(*) FILTER (WHERE is_lab IS TRUE)::bigint AS lab_rows,
         count(DISTINCT user_id)::bigint AS learners,
         max(created_at) AS newest_created_at
  FROM public.practice_attempts p
),
answers AS (
  SELECT count(*)::bigint AS n, min(id) AS first_id, max(id) AS last_id,
         md5(coalesce(string_agg(md5(to_jsonb(a)::text),'' ORDER BY id),'')) AS fingerprint,
         max(created_at) AS newest_created_at
  FROM public.practice_answers a
),
protection AS (
  SELECT
    (SELECT count(*) FROM public.practice_answers a LEFT JOIN public.practice_attempts p ON p.id=a.attempt_id WHERE p.id IS NULL)::bigint AS orphan_answers,
    (SELECT count(*) FROM public.practice_attempts p LEFT JOIN public.users u ON u.id=p.user_id WHERE u.id IS NULL)::bigint AS attempts_without_owner,
    (SELECT count(*) FROM public.practice_attempts p WHERE NOT EXISTS
      (SELECT 1 FROM public.practice_answers a WHERE a.attempt_id=p.id))::bigint AS attempts_without_answers,
    (SELECT count(*) FROM public.practice_review_events_v1 r LEFT JOIN public.practice_attempts p ON p.id=r.attempt_id WHERE p.id IS NULL)::bigint AS orphan_review_events,
    (SELECT count(*) FROM public.practice_answers a JOIN public.practice_attempts p ON p.id=a.attempt_id WHERE p.is_lab IS TRUE)::bigint AS lab_answers
),
legacy AS (
  SELECT
    (SELECT count(*) FROM public.users)::bigint AS users,
    (SELECT count(*) FROM public.tour_attempts)::bigint AS tour_attempts,
    (SELECT count(*) FROM public.tour_answers)::bigint AS tour_answers,
    (SELECT count(*) FROM public.certificates)::bigint AS certificates,
    (SELECT count(*) FROM public.practice_pools)::bigint AS practice_pools,
    (SELECT count(*) FROM public.practice_pool_questions)::bigint AS practice_pool_questions,
    (SELECT count(*) FROM public.tour_questions)::bigint AS tour_questions
)
SELECT jsonb_build_object(
  'captured_at',transaction_timestamp(),
  'practice_attempts',to_jsonb(attempts),
  'practice_answers',to_jsonb(answers),
  'integrity',to_jsonb(protection),
  'related_legacy_counts',to_jsonb(legacy),
  'historical_delta_resolved',false,
  'warning','An aggregate baseline alone cannot identify missing historical row IDs or distinguish an approved user reset from unauthorized deletion.'
) AS practice_integrity_snapshot
FROM attempts CROSS JOIN answers CROSS JOIN protection CROSS JOIN legacy;
COMMIT;
