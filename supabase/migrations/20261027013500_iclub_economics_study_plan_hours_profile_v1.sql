-- Economic weekly study advice is based on the student's saved Economics
-- hours budget, never on Math profile or browser-supplied grade.
BEGIN;
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
        ORDER BY CASE WHEN studied THEN 1 ELSE 0 END,
          CASE WHEN choice_idx IS NULL THEN 1 ELSE 0 END,
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
    'exam_series',(SELECT p.exam_series FROM private.iclub_exam_native_economics_profiles_v1 p WHERE p.user_id=v_user),
    'target_grade',(SELECT p.target_grade FROM private.iclub_exam_native_economics_profiles_v1 p WHERE p.user_id=v_user),
    'weekly_economics_hours',(SELECT p.economics_hours_budget FROM private.iclub_exam_native_economics_profiles_v1 p WHERE p.user_id=v_user),
    'suggested_minutes_per_topic',coalesce(
      (SELECT least(40,greatest(5,
        floor((p.economics_hours_budget*60)/greatest(1,jsonb_array_length(v_priorities)))::integer))
       FROM private.iclub_exam_native_economics_profiles_v1 p WHERE p.user_id=v_user),
      20),
    'unit_results',v_units,'mistakes',v_mistakes,
    'priorities',v_priorities,'weak_count',v_weak_count,
    'studied_count',v_studied_count,
    'retested_correct_count',v_retested_count,
    'interpretation','Self-reported study does not imply mastery. Retest evidence requires a correct answer in a later completed exam.'
  );
END;
$f$;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_study_plan_v1(uuid,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_study_plan_v1(uuid,text) TO authenticated;
DO $assert$
BEGIN
 IF has_function_privilege('anon','public.iclub_exam_native_mcq_study_plan_v1(uuid,text)','EXECUTE')
 OR (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND status='active')<>1
 THEN RAISE EXCEPTION 'Study plan access/Mathematics baseline unexpectedly changed'; END IF;
END;$assert$;
COMMIT;