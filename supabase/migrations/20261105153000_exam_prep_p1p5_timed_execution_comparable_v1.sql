-- Issue #450, P4-02: separate objective execution conditions from VERIFIED SCORED evidence.
-- DRAFT migration only. Do NOT run on production without separate architect GO.
-- No existing function/table/row mutation. Written answers remain ungraded.
-- Based on 20261104110000 score comparator; retain ALL existing time,
-- integrity, paper epoch, series and learner/program match checks.
BEGIN;

CREATE OR REPLACE FUNCTION private.exam_prep_timed_execution_comparable_v1(p_session_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  SELECT coalesce((
    SELECT t.timing_comparable
       AND t.server_elapsed_sec>0
       AND t.answered_items>0  -- a blank or entirely skipped paper cannot satisfy execution evidence
       -- Independent saved-response proof: a claimed answered_items counter,
       -- historical self-awarded marks or a fabricated finalized row alone
       -- must NEVER qualify as a completed written Paper.
       AND t.answered_items = (
         SELECT count(*)::int
         FROM private.exam_prep_responses r
         JOIN private.exam_prep_session_items i
           ON i.session_id=r.session_id AND i.item_order=r.item_order
         WHERE r.session_id=t.session_id
           AND r.user_id=t.user_id
           AND (
             (i.item_kind='written' AND r.response_kind='written'
               AND r.learner_artifact IS NOT NULL
               AND r.learner_artifact NOT IN ('null'::jsonb,'{}'::jsonb,'[]'::jsonb))
             OR
             (i.item_kind='question' AND r.response_kind='machine'
               AND r.is_correct IS NOT NULL)
           )
       )
       AND t.attempt_kind<>'diagnostic_full'
       AND s.status='finalized'
       AND s.session_type IN ('timed','paper')
       AND s.user_id=t.user_id
       AND s.component_code=t.component_code
       AND private.exam_prep_integrity_allows_timed_comparability_v1(t.session_id)
       AND coalesce(nullif(s.timing_contract->>'paper_comparability_epoch','')::int,1)
             =coalesce(p.paper_comparability_epoch,1)
       AND (
         nullif(trim(p.exam_series),'') IS NULL
         OR lower(trim(coalesce(nullif(s.timing_contract->>'exam_series_snapshot',''),p.exam_series)))
              =lower(trim(p.exam_series))
       )
    FROM private.exam_prep_timed_attempt_results t
    JOIN private.exam_prep_sessions s ON s.id=t.session_id
    JOIN private.exam_prep_exam_profiles p
      ON p.user_id=t.user_id AND p.program_version_id=s.program_version_id
    WHERE t.session_id=p_session_id
  ),false);
$function$;
REVOKE ALL ON FUNCTION private.exam_prep_timed_execution_comparable_v1(uuid)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_timed_execution_comparable_v1(uuid)
  TO service_role;

-- Deliberately untouched: private.exam_prep_timed_score_comparable_v1().
-- No automatic marks, no student/AI-written grading, no stage auto-promotion.
COMMIT;
