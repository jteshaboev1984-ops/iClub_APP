-- Issue #450 P4-07, stacked DRAFT only. Do not apply to production.
-- Correct a demonstrable false execution-positive: signed written payload
-- {"artifact":{"text":"  \t\n "}} is accepted as an archived ungraded answer,
-- but whitespace-only text does not constitute performed written work.
-- Existing responses, Paper attempts, scores, mentor policy and access remain
-- unchanged. Non-text structured learner artifacts keep their prior treatment.
-- Preserve the original P4-02 execution predicates and score firewall.
BEGIN;
DO $p407$
DECLARE
  v_definition text;
BEGIN
  IF to_regprocedure('private.exam_prep_timed_execution_comparable_v1(uuid)') IS NULL THEN
    RAISE EXCEPTION 'P4-07 requires unmerged P4-02 execution contract';
  END IF;
  v_definition:=pg_get_functiondef('private.exam_prep_timed_execution_comparable_v1(uuid)'::regprocedure);
  IF position('r.learner_artifact NOT IN' IN v_definition)=0
    OR position('t.answered_items = (' IN v_definition)=0
    OR position('private.exam_prep_integrity_allows_timed_comparability_v1' IN v_definition)=0
    OR position('paper_comparability_epoch' IN v_definition)=0
    OR position('exam_series_snapshot' IN v_definition)=0
    OR position('SECURITY DEFINER' IN upper(v_definition))=0
    OR position('search_path TO ''''' IN v_definition)=0
    OR position('whitespace-only' IN v_definition)>0
    OR NOT has_function_privilege('service_role',
      'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
    OR has_function_privilege('anon',
      'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
    OR has_function_privilege('authenticated',
      'private.exam_prep_timed_execution_comparable_v1(uuid)','EXECUTE')
  THEN
    RAISE EXCEPTION 'P4-07 comparator source/ACL drift; fail closed';
  END IF;
END;
$p407$;

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
               AND r.learner_artifact NOT IN ('null'::jsonb,'{}'::jsonb,'[]'::jsonb)
             -- The native learner UI posts {text:...}. An all-whitespace
             -- text-only artifact is a skipped response, NOT executed working.
             -- Keep other non-empty legacy/structured artifacts eligible.
             AND NOT (
               jsonb_typeof(r.learner_artifact)='object'
               AND r.learner_artifact ? 'text'
               AND (r.learner_artifact-'text')='{}'::jsonb
               AND btrim(coalesce(r.learner_artifact->>'text',''), E' \t\n\r\f\v')=''
             ))
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
