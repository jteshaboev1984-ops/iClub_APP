-- Native Economics: learner-owned mistake study and evidence-based follow-up.
-- Additive: no modifications to Math, old attempts, questions, or lesson progress.
BEGIN;

CREATE TABLE IF NOT EXISTS private.iclub_exam_native_mcq_study_progress_v1 (
  user_id uuid NOT NULL REFERENCES auth.users(id),
  source_session_id uuid NOT NULL REFERENCES private.iclub_exam_native_mcq_attempts_v1(id),
  skill_key text NOT NULL CHECK(length(skill_key) BETWEEN 8 AND 160),
  studied boolean NOT NULL DEFAULT false,
  studied_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  PRIMARY KEY(user_id,source_session_id,skill_key),
  CONSTRAINT econ_mcq_studied_time_ck CHECK ((studied AND studied_at IS NOT NULL) OR
    (NOT studied AND studied_at IS NULL))
);
CREATE INDEX IF NOT EXISTS econ_mcq_study_progress_session_idx
ON private.iclub_exam_native_mcq_study_progress_v1(source_session_id);
ALTER TABLE private.iclub_exam_native_mcq_study_progress_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_native_mcq_study_progress_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_native_mcq_study_progress_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_native_mcq_study_progress_v1 TO service_role;

-- Read-only personalized plan, derived from immutable finalized 30-item evidence.
-- "studied" is user-confirmed engagement, NOT claimed mastery. A subsequent
-- correct finalized paper answer is the only way to tag a previously missed skill as retested.
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_study_plan_v1(
  p_session_id uuid, p_language text DEFAULT 'ru'
) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE
  v_user uuid:=auth.uid();
  v_session private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_units jsonb;
  v_mistakes jsonb;
  v_priorities jsonb;
  v_weak_count integer;
  v_studied_count integer;
  v_retested_count integer;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL OR p_language NOT IN ('ru','uz','en') THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v_session
  FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE id=p_session_id AND user_id=v_user AND
    program_key='economics_9708' AND version_key='economics_2026_2028_v1';
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  IF v_session.status<>'finalized' THEN
    RETURN jsonb_build_object('ok',false,'code','finish_exam_first');
  END IF;

  WITH expanded AS (
    SELECT x.ord::integer item_order, x.item,
      x.item->>'skill_key' skill_key, (x.item->>'unit')::integer unit_no,
      (v_session.responses->(x.ord::text)->>'choice')::integer choice_idx
    FROM jsonb_array_elements(v_session.items) WITH ORDINALITY x(item,ord)
  ),
  scored AS (
    SELECT ex.*,
      (ex.choice_idx IS NOT NULL AND
        (ex.item->'display_order'->>ex.choice_idx)::integer =
          ascii(ex.item->>'key')-65) AS is_correct
    FROM expanded ex
  ),
  enriched AS (
    SELECT sc.item_order,sc.skill_key,sc.unit_no,sc.choice_idx,sc.is_correct,
      coalesce(theory.locales->p_language->>'title',sc.skill_key) title,
      coalesce(theory.locales->p_language->>'explanation','') lesson,
      coalesce(theory.locales->p_language->>'common_trap','') common_trap,
      coalesce(theory.locales->p_language->>'check_question','') check_question,
      coalesce(theory.locales->p_language->>'check_answer','') check_answer,
      coalesce(progress.studied,false) studied,
      EXISTS (
        SELECT 1
        FROM private.iclub_exam_native_mcq_attempts_v1 newer
        CROSS JOIN LATERAL jsonb_array_elements(newer.items)
          WITH ORDINALITY followup(item,ord)
        WHERE newer.user_id=v_user
          AND newer.program_key='economics_9708'
          AND newer.version_key=v_session.version_key
          AND newer.paper_code=v_session.paper_code
          AND newer.status='finalized'
          AND newer.started_at>v_session.finalized_at
          AND followup.item->>'skill_key'=sc.skill_key
          AND newer.responses ? followup.ord::text
          AND (
            followup.item->'display_order'->>
            ((newer.responses->(followup.ord::text)->>'choice')::integer)
          )::integer=ascii(followup.item->>'key')-65
      ) retested_correct
    FROM scored sc
    LEFT JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key='economics_9708' AND
         sk.version_key='economics_2026_2028_v1' AND
         sk.skill_key=sc.skill_key
    LEFT JOIN private.iclub_subject_library_theory theory
      ON theory.subject_key=sk.library_subject_key AND
         theory.version_key=sk.library_version_key AND
         theory.skill_key=sk.skill_key
    LEFT JOIN private.iclub_exam_native_mcq_study_progress_v1 progress
      ON progress.user_id=v_user AND progress.source_session_id=v_session.id
         AND progress.skill_key=sc.skill_key
  ),
  wrong AS (
    SELECT * FROM enriched WHERE NOT is_correct
  ),
  ranked AS (
    SELECT wrong.*,
      row_number() OVER (
        ORDER BY CASE WHEN choice_idx IS NULL THEN 1 ELSE 0 END,
          unit_no,item_order
      ) priority_position
    FROM wrong
    WHERE NOT retested_correct
  )
  SELECT
    (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'unit',unit_no,
      'total',total,
      'correct',correct,
      'incorrect',total-correct-unattempted,
      'unattempted',unattempted
    ) ORDER BY unit_no),'[]'::jsonb)
    FROM (
      SELECT unit_no,count(*)::integer total,
      count(*) FILTER(WHERE is_correct)::integer correct,
      count(*) FILTER(WHERE choice_idx IS NULL)::integer unattempted
      FROM enriched GROUP BY unit_no
    ) groups),
    (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'item_order',item_order,'skill_key',skill_key,'unit',unit_no,
      'title',title,'answered',choice_idx IS NOT NULL,
      'studied',studied,'retested_correct',retested_correct
    ) ORDER BY item_order),'[]'::jsonb) FROM wrong),
    (SELECT coalesce(jsonb_agg(jsonb_build_object(
      'priority',priority_position,'item_order',item_order,
      'skill_key',skill_key,'unit',unit_no,'title',title,
      'lesson',lesson,'common_trap',common_trap,
      'check_question',check_question,'check_answer',check_answer,
      'studied',studied,'retested_correct',false,
      'suggested_day',CASE priority_position
        WHEN 1 THEN 1 WHEN 2 THEN 2 WHEN 3 THEN 3
        WHEN 4 THEN 5 ELSE 7 END
    ) ORDER BY priority_position),'[]'::jsonb)
      FROM ranked WHERE priority_position<=5),
    (SELECT count(*)::integer FROM wrong),
    (SELECT count(*)::integer FROM wrong WHERE studied),
    (SELECT count(*)::integer FROM wrong WHERE retested_correct)
  INTO v_units,v_mistakes,v_priorities,v_weak_count,
       v_studied_count,v_retested_count;

  RETURN jsonb_build_object(
    'ok',true,'paper_code',v_session.paper_code,
    'session_id',v_session.id,'score',v_session.score,
    'out_of',30,'finalized_at',v_session.finalized_at,
    'week_horizon_days',7,
    'unit_results',v_units,'mistakes',v_mistakes,
    'priorities',v_priorities,'weak_count',v_weak_count,
    'studied_count',v_studied_count,
    'retested_correct_count',v_retested_count,
    'interpretation','Self-reported study does not imply mastery. Retest evidence requires a correct answer in a later completed exam.'
  );
END;
$f$;

-- Explicitly store a learner's review action; never alter test scores.
-- Error must be in their own finalized attempt.
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_mark_studied_v1(
  p_session_id uuid,p_skill_key text,p_studied boolean DEFAULT true
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE
  v_user uuid:=auth.uid();
  v_attempt private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_allowed boolean;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL OR p_skill_key IS NULL OR
     length(p_skill_key) NOT BETWEEN 8 AND 160 OR p_studied IS NULL THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v_attempt
  FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE id=p_session_id AND user_id=v_user AND
    program_key='economics_9708' AND
    version_key='economics_2026_2028_v1' AND status='finalized';
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;

  SELECT EXISTS(
    SELECT 1 FROM jsonb_array_elements(v_attempt.items)
      WITH ORDINALITY it(item,ord)
    WHERE it.item->>'skill_key'=p_skill_key
      AND (
        NOT (v_attempt.responses ? it.ord::text)
        OR (
          it.item->'display_order'->>
            ((v_attempt.responses->(it.ord::text)->>'choice')::integer)
        )::integer<>ascii(it.item->>'key')-65
      )
  ) INTO v_allowed;
  IF NOT v_allowed THEN
    RETURN jsonb_build_object('ok',false,'code','not_a_missed_skill');
  END IF;

  INSERT INTO private.iclub_exam_native_mcq_study_progress_v1
    (user_id,source_session_id,skill_key,studied,studied_at,updated_at)
  VALUES (v_user,v_attempt.id,p_skill_key,p_studied,
    CASE WHEN p_studied THEN clock_timestamp() ELSE NULL END,
    clock_timestamp())
  ON CONFLICT(user_id,source_session_id,skill_key)
  DO UPDATE SET studied=EXCLUDED.studied,
    studied_at=EXCLUDED.studied_at,updated_at=EXCLUDED.updated_at;
  RETURN jsonb_build_object('ok',true,'skill_key',p_skill_key,
    'studied',p_studied,'mastery_proven',false);
END;
$f$;

REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_study_plan_v1(uuid,text)
 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_mark_studied_v1(uuid,text,boolean)
 FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_study_plan_v1(uuid,text)
 TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_mark_studied_v1(uuid,text,boolean)
 TO authenticated;

DO $assert$
BEGIN
 IF EXISTS(SELECT 1 FROM private.iclub_exam_native_mcq_study_progress_v1)
    THEN RAISE EXCEPTION 'New study progress table unexpectedly nonempty'; END IF;
 IF has_table_privilege('anon','private.iclub_exam_native_mcq_study_progress_v1','SELECT')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_study_progress_v1','SELECT')
 OR has_function_privilege('anon','public.iclub_exam_native_mcq_study_plan_v1(uuid,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_native_mcq_mark_studied_v1(uuid,text,boolean)','EXECUTE')
 THEN RAISE EXCEPTION 'Private study progress privilege failure'; END IF;
 IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1
  WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
    AND status='draft' AND launch_enabled=false)
 THEN RAISE EXCEPTION 'Economics program unexpectedly enabled'; END IF;
END;
$assert$;
COMMIT;
