BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='90s';

DO $preflight$
BEGIN
  IF md5(pg_get_functiondef('public.get_exam_prep_timed_review_pack_safe_v1(uuid,text)'::regprocedure))
     <> 'f6e4f8ec087952343c485b84b1b190ad'
  THEN
    RAISE EXCEPTION 'rubric localization: timed review function drift';
  END IF;
END
$preflight$;

CREATE OR REPLACE FUNCTION private.exam_prep_localized_written_rubric_v1(
  p_rubric jsonb,
  p_language text
)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path=''
AS $fn$
DECLARE
  v_lang text:=lower(coalesce(p_language,'en'));
  v_key text;
  v_missing integer:=0;
  v_criteria jsonb;
BEGIN
  IF v_lang NOT IN ('en','ru','uz') THEN
    RAISE EXCEPTION 'exam_prep_bad_language';
  END IF;

  IF p_rubric IS NULL THEN
    RETURN NULL;
  END IF;

  IF v_lang='en' THEN
    RETURN p_rubric || jsonb_build_object('localization_status','complete');
  END IF;

  v_key:=CASE v_lang WHEN 'ru' THEN 'rule_ru' ELSE 'rule_uz' END;

  SELECT count(*) INTO v_missing
  FROM jsonb_array_elements(coalesce(p_rubric->'criteria','[]'::jsonb)) c
  WHERE nullif(btrim(coalesce(c->>v_key,'')),'') IS NULL;

  IF v_missing>0 THEN
    RETURN jsonb_build_object(
      'max_marks',p_rubric->'max_marks',
      'criteria','[]'::jsonb,
      'localization_status','unavailable'
    );
  END IF;

  SELECT coalesce(
    jsonb_agg(
      (c - 'rule' - 'rule_ru' - 'rule_uz')
      || jsonb_build_object('rule',c->>v_key)
      ORDER BY ord
    ),
    '[]'::jsonb
  )
  INTO v_criteria
  FROM jsonb_array_elements(coalesce(p_rubric->'criteria','[]'::jsonb))
       WITH ORDINALITY x(c,ord);

  RETURN (p_rubric - 'criteria')
    || jsonb_build_object(
      'criteria',v_criteria,
      'localization_status','complete'
    );
END
$fn$;

REVOKE ALL ON FUNCTION private.exam_prep_localized_written_rubric_v1(jsonb,text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_localized_written_rubric_v1(jsonb,text)
TO service_role;

CREATE OR REPLACE FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(
  p_session_id uuid,
  p_language text DEFAULT 'en'
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path=''
AS $$
DECLARE
  v_uid uuid;
  v_s private.exam_prep_sessions%rowtype;
  v_lang text;
  v_items jsonb;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  v_lang:=lower(coalesce(p_language,'en'));
  IF v_lang NOT IN ('en','ru','uz') THEN
    RAISE EXCEPTION 'exam_prep_bad_language';
  END IF;

  SELECT * INTO v_s
  FROM private.exam_prep_sessions
  WHERE id=p_session_id
    AND user_id=v_uid
    AND session_type IN ('timed','paper');

  IF v_s.id IS NULL THEN
    RAISE EXCEPTION 'exam_prep_timed_session_not_found' USING errcode='P0002';
  END IF;

  IF v_s.status<>'finalized'
     OR NOT EXISTS(
       SELECT 1
       FROM private.exam_prep_timed_attempt_results
       WHERE session_id=v_s.id
     )
  THEN
    RAISE EXCEPTION 'exam_prep_review_pack_requires_finalized_attempt';
  END IF;

  SELECT coalesce(
    jsonb_agg(
      jsonb_build_object(
        'item_order',si.item_order,
        'primary_skill_code',si.primary_skill_code,
        'prompt',CASE v_lang
          WHEN 'ru' THEN wt.prompt_ru
          WHEN 'uz' THEN wt.prompt_uz
          ELSE wt.prompt_en
        END,
        'learner_artifact',r.learner_artifact,
        'max_marks',ti.max_marks,
        'rubric',private.exam_prep_localized_written_rubric_v1(wt.rubric_json,v_lang),
        'self_review',CASE v_lang
          WHEN 'ru' THEN wt.self_review_ru
          WHEN 'uz' THEN wt.self_review_uz
          ELSE wt.self_review_en
        END,
        'submitted_in_time',(r.answered_at<=nullif(v_s.timing_contract->>'deadline_at','')::timestamptz),
        'self_marked',(sm.session_id IS NOT NULL),
        'self_marks_awarded',sm.marks_awarded
      )
      ORDER BY si.item_order
    ),
    '[]'::jsonb
  )
  INTO v_items
  FROM private.exam_prep_session_items si
  JOIN private.exam_prep_timed_assessment_items ti
    ON ti.assessment_id=v_s.assessment_id
   AND ti.item_order=si.item_order
  JOIN private.exam_prep_written_tasks wt
    ON wt.id=si.written_task_id
  JOIN private.exam_prep_responses r
    ON r.session_id=si.session_id
   AND r.item_order=si.item_order
   AND r.response_kind='written'
  LEFT JOIN private.exam_prep_timed_written_self_marks sm
    ON sm.session_id=si.session_id
   AND sm.item_order=si.item_order
  WHERE si.session_id=v_s.id
    AND si.item_kind='written';

  RETURN jsonb_build_object(
    'session_id',v_s.id,
    'status',v_s.status,
    'items',v_items
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(uuid,text)
FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_timed_review_pack_safe_v1(uuid,text)
TO authenticated,service_role;

DO $postcheck$
DECLARE
  v_ru jsonb;
  v_complete jsonb;
BEGIN
  v_ru:=private.exam_prep_localized_written_rubric_v1(
    '{"max_marks":2,"criteria":[{"id":"m","rule":"English criterion","marks":2}]}'::jsonb,
    'ru'
  );
  IF v_ru->>'localization_status'<>'unavailable'
     OR jsonb_array_length(v_ru->'criteria')<>0
  THEN
    RAISE EXCEPTION 'rubric localization fallback failed';
  END IF;

  v_complete:=private.exam_prep_localized_written_rubric_v1(
    '{"max_marks":2,"criteria":[{"id":"m","rule":"English criterion","rule_ru":"Русский критерий","rule_uz":"O‘zbek mezoni","marks":2}]}'::jsonb,
    'ru'
  );
  IF v_complete->>'localization_status'<>'complete'
     OR v_complete->'criteria'->0->>'rule'<>'Русский критерий'
     OR (v_complete->'criteria'->0 ? 'rule_ru')
     OR (v_complete->'criteria'->0 ? 'rule_uz')
  THEN
    RAISE EXCEPTION 'rubric localization projection failed';
  END IF;
END
$postcheck$;

COMMIT;
