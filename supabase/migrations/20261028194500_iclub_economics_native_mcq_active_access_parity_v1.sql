-- Economics 9708: P0 authorization parity with the Mathematics Core model.
-- Existing tables, attempt ids, responses, user history, private written plans,
-- Mathematics functions and release switches are not modified.
-- Checked against LIVE pg_get_functiondef on 2026-10-28.
-- Read policy: finalized MCQ attempts/history remain owner-readable;
-- active question delivery and learning actions require current beta access.
-- Rollback: restore the five pre-migration definitions from the corresponding
-- historical functions/migrations (the migration is intentionally non-destructive).

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_answer_v1(p_session_id uuid, p_item_order integer, p_choice integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid:=auth.uid();
  v private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_key text;
  v_prior jsonb;
  v_same boolean;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL
     OR p_item_order<1 OR p_item_order>30 OR p_choice NOT BETWEEN 0 AND 3 THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v FROM private.iclub_exam_native_mcq_attempts_v1
    WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
    RETURN jsonb_build_object('ok',false,'code','not_authorized');
  END IF;
  -- No modification of completed or timed-out attempts, including duplicate requests.
  IF v.status<>'active' OR clock_timestamp()>=v.deadline_at THEN
    RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired');
  END IF;
  IF p_item_order>jsonb_array_length(v.items) THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  v_key:=p_item_order::text;
  v_prior:=v.responses->v_key;
  v_same:=v_prior IS NOT NULL AND (v_prior->>'choice')::integer=p_choice;
  IF v_same THEN
    RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',true,
      'selected_index',p_choice);
  END IF;
  -- Preserve the original submission timestamp while recording the last choice.
  UPDATE private.iclub_exam_native_mcq_attempts_v1
    SET responses=jsonb_set(responses,ARRAY[v_key],
      jsonb_build_object('choice',p_choice,'at',clock_timestamp(),
        'first_at',coalesce(v_prior->'first_at',v_prior->'at',
          to_jsonb(clock_timestamp()))),true)
    WHERE id=v.id AND user_id=v_user AND status='active';
  RETURN jsonb_build_object('ok',true,'saved',true,'unchanged',false,
    'revised',v_prior IS NOT NULL,'selected_index',p_choice);
END;
$function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_get_v1(p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE
  v_user uuid:=auth.uid();
  v private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_items jsonb;
  v_rows jsonb;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL OR p_language NOT IN ('en','ru','uz') THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE id=p_session_id AND user_id=v_user;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  -- Historical finalized results remain readable after beta access is revoked.
  IF v.status='active' THEN
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
    RETURN jsonb_build_object('ok',false,'code','not_authorized');
  END IF;
  END IF;
  SELECT jsonb_agg(jsonb_build_object(
    'order',ix.ord,'skill_key',ix.item->>'skill_key',
    'unit',(ix.item->>'unit')::int,
    'question',ix.item->'locales'->p_language->>'question',
    'options',(SELECT jsonb_agg((ix.item->'locales'->p_language->'options'->>((x.v)::int))
       ORDER BY x.ord) FROM jsonb_array_elements_text(ix.item->'display_order')
       WITH ORDINALITY x(v,ord)),
    'answered',v.responses ? ix.ord::text,
    'selected_index',CASE WHEN v.responses ? ix.ord::text
      THEN (v.responses->ix.ord::text->>'choice')::int ELSE NULL END,
    'correct_index',CASE WHEN v.status='finalized' THEN
       (SELECT (x.ord-1)::int
        FROM jsonb_array_elements_text(ix.item->'display_order') WITH ORDINALITY x(v,ord)
        WHERE (x.v)::int=ascii(ix.item->>'key')-65)
      ELSE NULL END,
    'explanation',CASE WHEN v.status='finalized' THEN
       ix.item->'locales'->p_language->>'explanation' ELSE NULL END
  ) ORDER BY ix.ord) INTO v_rows
  FROM jsonb_array_elements(v.items) WITH ORDINALITY ix(item,ord);
  RETURN jsonb_build_object('ok',true,'session_id',v.id,'paper_code',v.paper_code,
    'status',v.status,'deadline_at',v.deadline_at,'started_at',v.started_at,
    'time_remaining_seconds',greatest(0,ceil(extract(epoch FROM
      (v.deadline_at-clock_timestamp())))::int),
    'score',CASE WHEN v.status='finalized' THEN v.score ELSE NULL END,
    'session_kind',v.session_kind,'total_items',jsonb_array_length(v.items),'items',coalesce(v_rows,'[]'::jsonb));
END;
$function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_finish_v1(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user uuid:=auth.uid();
  v private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_score int; v_answered int;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  IF v.status<>'finalized' THEN
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
    RETURN jsonb_build_object('ok',false,'code','not_authorized');
  END IF;
  END IF;
  IF v.status='finalized' THEN RETURN jsonb_build_object('ok',true,
    'status','finalized','score',v.score,'out_of',jsonb_array_length(v.items),'duplicate',true); END IF;
  SELECT coalesce(sum(CASE
    WHEN v.responses ? ix.ord::text
     AND (ix.item->'display_order'->>(
       (v.responses->ix.ord::text->>'choice')::integer))::int =
        ascii(ix.item->>'key')-65
    THEN 1 ELSE 0 END),0)::int,
    count(*) FILTER(WHERE v.responses ? ix.ord::text)::int
  INTO v_score,v_answered
  FROM jsonb_array_elements(v.items) WITH ORDINALITY ix(item,ord);
  UPDATE private.iclub_exam_native_mcq_attempts_v1
    SET status='finalized',score=v_score,finalized_at=clock_timestamp()
  WHERE id=v.id AND user_id=v_user AND status='active';
  RETURN jsonb_build_object('ok',true,'status','finalized',
    'score',v_score,'out_of',jsonb_array_length(v.items),'answered',v_answered,'duplicate',false);
END;
$function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_mark_studied_v1(p_session_id uuid, p_skill_key text, p_studied boolean DEFAULT true)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
    RETURN jsonb_build_object('ok',false,'code','not_authorized');
  END IF;

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
$function$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_study_plan_v1(p_session_id uuid, p_language text DEFAULT 'ru'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
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
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
    RETURN jsonb_build_object('ok',false,'code','not_authorized');
  END IF;
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
    'ok',true,'paper_code',v_session.paper_code,'session_kind',v_session.session_kind,
    'session_id',v_session.id,'score',v_session.score,
    'out_of',jsonb_array_length(v_session.items),'finalized_at',v_session.finalized_at,
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
$function$;