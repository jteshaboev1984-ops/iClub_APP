-- iClub Economics: shared native session backbone for full Paper and 12-item
-- entry check. Older Paper sessions/answers are preserved byte-for-byte.
BEGIN;
SET LOCAL lock_timeout='4s';
SET LOCAL statement_timeout='90s';
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1
  ADD COLUMN IF NOT EXISTS session_kind text NOT NULL DEFAULT 'paper';
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1
  ADD CONSTRAINT economics_native_session_kind_ck
    CHECK(session_kind IN ('paper','diagnostic'));
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1
  DROP CONSTRAINT iclub_exam_native_mcq_attempts_v1_items_check;
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1
  ADD CONSTRAINT economics_native_session_item_count_ck
    CHECK(jsonb_typeof(items)='array' AND (
      (session_kind='paper' AND jsonb_array_length(items)=30)
      OR (session_kind='diagnostic' AND jsonb_array_length(items)=12)
    ));
CREATE UNIQUE INDEX economics_native_attempt_one_active_kind_uq
  ON private.iclub_exam_native_mcq_attempts_v1
  (user_id,program_key,version_key,paper_code,session_kind)
  WHERE status='active';
DROP INDEX private.economics_native_attempt_one_active_uq;

-- All former functions retain the same names and param types: additive only.
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_start_v1(
  p_paper_code text,p_client_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE
  v_user uuid:=auth.uid();
  v_version text:='economics_2026_2028_v1';
  v_id uuid:=gen_random_uuid();
  v_existing private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_items jsonb;
  v_limit int;
  v_count int;
BEGIN
  IF v_user IS NULL OR p_paper_code NOT IN ('P1','P3') OR
     length(coalesce(p_client_key,'')) NOT BETWEEN 12 AND 128 THEN
     RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  IF NOT private.iclub_exam_native_mcq_enrolled_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','not_enrolled');
  END IF;
  -- Gating on existing Math controlled-beta authorization; no QA open-all shortcut.
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','beta_not_authorized');
  END IF;
  -- Require both program and specific MCQ paper to be deliberately published.
  SELECT pa.duration_seconds INTO v_limit
  FROM private.iclub_exam_core_programs_v1 p
  JOIN private.iclub_exam_core_papers_v1 pa
    ON pa.program_key=p.program_key AND pa.version_key=p.version_key
  WHERE p.program_key='economics_9708' AND p.version_key=v_version
    AND p.integration_mode='native' AND p.status='published'
    AND p.launch_enabled=true AND pa.paper_code=p_paper_code
    AND pa.status='published' AND pa.assessment_kind='mcq'
    AND pa.mcq_count=30
    AND ((p_paper_code='P1' AND pa.level_code='AS' AND pa.duration_seconds=3600)
      OR (p_paper_code='P3' AND pa.level_code='A' AND pa.duration_seconds=4500));
  IF v_limit IS NULL THEN
     RETURN jsonb_build_object('ok',false,'code','not_available');
  END IF;
  -- Idempotency: return same attempt, never generate another one for a retry.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code
    AND client_key=p_client_key AND session_kind='paper';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status',v_existing.status,'resumed',true); END IF;
  -- One unfinished attempt per learner+paper. Expired attempt must be finalized first.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code AND status='active' AND session_kind='paper';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status','active','resumed',true); END IF;

  WITH quotas(unit_no,n) AS (
    SELECT * FROM (VALUES (1,4),(2,12),(3,3),(4,3),(5,3),(6,5)) a
    WHERE p_paper_code='P1'
    UNION ALL
    SELECT * FROM (VALUES (7,8),(8,7),(9,4),(10,3),(11,8)) a
    WHERE p_paper_code='P3'
  ), valid_sources AS (
    SELECT q.id, qc.skill_key,sk.syllabus_unit, qc.source_snapshot_md5,
      q.question_text_en,q.question_text_ru,q.question_text_uz,
      q.options_text_en::jsonb opt_en,q.options_text_ru::jsonb opt_ru,
      q.options_text_uz::jsonb opt_uz,
      q.explanation_en,q.explanation_ru,q.explanation_uz,q.correct_answer,
      row_number() OVER(PARTITION BY qc.skill_key
        ORDER BY md5(v_id::text||q.id::text)) unique_skill_rank
    FROM private.iclub_exam_core_question_candidates_v1 qc
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=qc.program_key AND sk.version_key=qc.version_key
      AND sk.skill_key=qc.skill_key
    JOIN private.iclub_exam_core_paper_skills_v1 ps
      ON ps.program_key=qc.program_key AND ps.version_key=qc.version_key
      AND ps.paper_code=qc.paper_code AND ps.skill_key=qc.skill_key
      AND ps.link_role=qc.link_role
    JOIN private.iclub_exam_core_question_review_v1 qr
      ON qr.program_key=qc.program_key AND qr.version_key=qc.version_key
      AND qr.legacy_question_id=qc.legacy_question_id
    JOIN public.questions q ON q.id=qc.legacy_question_id
    WHERE qc.program_key='economics_9708' AND qc.version_key=v_version
      AND qc.paper_code=p_paper_code AND qc.status='approved'
      AND qc.qa_scope_status='pass' AND qc.qa_academic_status='pass'
      AND qc.qa_language_status='pass' AND qc.qa_format_status='pass'
      AND sk.status='reviewed' AND ps.status='approved' AND sk.level_code=
        CASE WHEN p_paper_code='P1' THEN 'AS' ELSE 'A' END
      AND qc.link_role='direct'
      AND qr.source_snapshot_md5=qc.source_snapshot_md5
      AND q.subject_id=7 AND q.is_active AND q.quality_status='published'
      AND q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
      AND jsonb_array_length(q.options_text_en::jsonb)=4
      AND jsonb_array_length(q.options_text_ru::jsonb)=4
      AND jsonb_array_length(q.options_text_uz::jsonb)=4
      AND qc.source_snapshot_md5=md5(jsonb_build_object(
        'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
        'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
        'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
        'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
        'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
        'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
        'is_active',q.is_active
      )::text)
      AND q.id NOT IN (8751,9044,9732)
  ), unique_skills AS(
    SELECT * FROM valid_sources WHERE unique_skill_rank=1
  ), ranked AS(
    SELECT *,row_number() OVER(PARTITION BY syllabus_unit
      ORDER BY md5(v_id::text||'item'||id::text)) unit_rank
    FROM unique_skills
  ), chosen AS(
    SELECT r.* FROM ranked r JOIN quotas qu ON qu.unit_no=r.syllabus_unit
    WHERE r.unit_rank<=qu.n
  )
  SELECT jsonb_agg(jsonb_build_object(
    'source_id',id,'skill_key',skill_key,'unit',syllabus_unit,
    'snapshot_md5',source_snapshot_md5,'key',correct_answer,
    'locales',jsonb_build_object(
      'en',jsonb_build_object('question',question_text_en,'options',opt_en,'explanation',explanation_en),
      'ru',jsonb_build_object('question',question_text_ru,'options',opt_ru,'explanation',explanation_ru),
      'uz',jsonb_build_object('question',question_text_uz,'options',opt_uz,'explanation',explanation_uz)
    ),
    'display_order',(SELECT jsonb_agg(g.i ORDER BY md5(v_id::text||id::text||g.i::text))
      FROM generate_series(0,3) g(i))
  ) ORDER BY md5(v_id::text||'display'||id::text)),count(*)
  INTO v_items,v_count FROM chosen;
  IF v_count<>30 OR jsonb_array_length(v_items)<>30 THEN
    RETURN jsonb_build_object('ok',false,'code','insufficient_approved_questions');
  END IF;
  INSERT INTO private.iclub_exam_native_mcq_attempts_v1
    (id,user_id,program_key,version_key,paper_code,client_key,items,deadline_at)
  VALUES (v_id,v_user,'economics_9708',v_version,p_paper_code,p_client_key,
    v_items,clock_timestamp()+make_interval(secs=>v_limit));
  RETURN jsonb_build_object('ok',true,'session_id',v_id,'status','active',
    'resumed',false,'total_items',30,'duration_seconds',v_limit,'session_kind','paper');
EXCEPTION WHEN unique_violation THEN
  -- Concurrent retries fail closed; caller can resume through its authenticated status query.
  RETURN jsonb_build_object('ok',false,'code','concurrent_start_retry');
END;
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_start_diagnostic_v1(
  p_paper_code text,p_client_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE
  v_user uuid:=auth.uid();
  v_version text:='economics_2026_2028_v1';
  v_id uuid:=gen_random_uuid();
  v_existing private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_items jsonb;
  v_limit int;
  v_count int;
BEGIN
  IF v_user IS NULL OR p_paper_code NOT IN ('P1','P3') OR
     length(coalesce(p_client_key,'')) NOT BETWEEN 12 AND 128 THEN
     RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  IF NOT private.iclub_exam_native_mcq_enrolled_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','not_enrolled');
  END IF;
  -- Gating on existing Math controlled-beta authorization; no QA open-all shortcut.
  IF NOT private.iclub_exam_native_economics_beta_allowed_v1(v_user) THEN
     RETURN jsonb_build_object('ok',false,'code','beta_not_authorized');
  END IF;
  -- Require both program and specific MCQ paper to be deliberately published.
  SELECT 1200 INTO v_limit
  FROM private.iclub_exam_core_programs_v1 p
  JOIN private.iclub_exam_core_papers_v1 pa
    ON pa.program_key=p.program_key AND pa.version_key=p.version_key
  WHERE p.program_key='economics_9708' AND p.version_key=v_version
    AND p.integration_mode='native' AND p.status='published'
    AND p.launch_enabled=true AND pa.paper_code=p_paper_code
    AND pa.status='published' AND pa.assessment_kind='mcq'
    AND pa.mcq_count=30
    AND ((p_paper_code='P1' AND pa.level_code='AS' AND pa.duration_seconds=3600)
      OR (p_paper_code='P3' AND pa.level_code='A' AND pa.duration_seconds=4500));
  IF v_limit IS NULL THEN
     RETURN jsonb_build_object('ok',false,'code','not_available');
  END IF;
  -- Idempotency: return same attempt, never generate another one for a retry.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code
    AND client_key=p_client_key AND session_kind='diagnostic';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status',v_existing.status,'resumed',true); END IF;
  -- One unfinished attempt per learner+paper. Expired attempt must be finalized first.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code AND status='active' AND session_kind='diagnostic';
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status','active','resumed',true); END IF;

  WITH quotas(unit_no,n) AS (
    SELECT * FROM (VALUES (1,2),(2,2),(3,2),(4,2),(5,2),(6,2)) a
    WHERE p_paper_code='P1'
    UNION ALL
    SELECT * FROM (VALUES (7,3),(8,3),(9,2),(10,2),(11,2)) a
    WHERE p_paper_code='P3'
  ), valid_sources AS (
    SELECT q.id, qc.skill_key,sk.syllabus_unit, qc.source_snapshot_md5,
      q.question_text_en,q.question_text_ru,q.question_text_uz,
      q.options_text_en::jsonb opt_en,q.options_text_ru::jsonb opt_ru,
      q.options_text_uz::jsonb opt_uz,
      q.explanation_en,q.explanation_ru,q.explanation_uz,q.correct_answer,
      row_number() OVER(PARTITION BY qc.skill_key
        ORDER BY md5(v_id::text||q.id::text)) unique_skill_rank
    FROM private.iclub_exam_core_question_candidates_v1 qc
    JOIN private.iclub_exam_core_skills_v1 sk
      ON sk.program_key=qc.program_key AND sk.version_key=qc.version_key
      AND sk.skill_key=qc.skill_key
    JOIN private.iclub_exam_core_paper_skills_v1 ps
      ON ps.program_key=qc.program_key AND ps.version_key=qc.version_key
      AND ps.paper_code=qc.paper_code AND ps.skill_key=qc.skill_key
      AND ps.link_role=qc.link_role
    JOIN private.iclub_exam_core_question_review_v1 qr
      ON qr.program_key=qc.program_key AND qr.version_key=qc.version_key
      AND qr.legacy_question_id=qc.legacy_question_id
    JOIN public.questions q ON q.id=qc.legacy_question_id
    WHERE qc.program_key='economics_9708' AND qc.version_key=v_version
      AND qc.paper_code=p_paper_code AND qc.status='approved'
      AND qc.qa_scope_status='pass' AND qc.qa_academic_status='pass'
      AND qc.qa_language_status='pass' AND qc.qa_format_status='pass'
      AND sk.status='reviewed' AND ps.status='approved' AND sk.level_code=
        CASE WHEN p_paper_code='P1' THEN 'AS' ELSE 'A' END
      AND qc.link_role='direct'
      AND qr.source_snapshot_md5=qc.source_snapshot_md5
      AND q.subject_id=7 AND q.is_active AND q.quality_status='published'
      AND q.qtype='mcq' AND q.correct_answer ~ '^[A-D]$'
      AND jsonb_array_length(q.options_text_en::jsonb)=4
      AND jsonb_array_length(q.options_text_ru::jsonb)=4
      AND jsonb_array_length(q.options_text_uz::jsonb)=4
      AND qc.source_snapshot_md5=md5(jsonb_build_object(
        'topic',q.topic,'subtopic',q.subtopic,'difficulty',q.difficulty,'qtype',q.qtype,
        'q_en',q.question_text_en,'q_ru',q.question_text_ru,'q_uz',q.question_text_uz,
        'options_en',q.options_text_en,'options_ru',q.options_text_ru,'options_uz',q.options_text_uz,
        'correct_answer',q.correct_answer,'explanation_en',q.explanation_en,
        'explanation_ru',q.explanation_ru,'explanation_uz',q.explanation_uz,
        'image_url',q.image_url,'book_ref',q.book_ref,'quality_status',q.quality_status,
        'is_active',q.is_active
      )::text)
      AND q.id NOT IN (8751,9044,9732)
  ), unique_skills AS(
    SELECT * FROM valid_sources WHERE unique_skill_rank=1
  ), ranked AS(
    SELECT *,row_number() OVER(PARTITION BY syllabus_unit
      ORDER BY md5(v_id::text||'item'||id::text)) unit_rank
    FROM unique_skills
  ), chosen AS(
    SELECT r.* FROM ranked r JOIN quotas qu ON qu.unit_no=r.syllabus_unit
    WHERE r.unit_rank<=qu.n
  )
  SELECT jsonb_agg(jsonb_build_object(
    'source_id',id,'skill_key',skill_key,'unit',syllabus_unit,
    'snapshot_md5',source_snapshot_md5,'key',correct_answer,
    'locales',jsonb_build_object(
      'en',jsonb_build_object('question',question_text_en,'options',opt_en,'explanation',explanation_en),
      'ru',jsonb_build_object('question',question_text_ru,'options',opt_ru,'explanation',explanation_ru),
      'uz',jsonb_build_object('question',question_text_uz,'options',opt_uz,'explanation',explanation_uz)
    ),
    'display_order',(SELECT jsonb_agg(g.i ORDER BY md5(v_id::text||id::text||g.i::text))
      FROM generate_series(0,3) g(i))
  ) ORDER BY md5(v_id::text||'display'||id::text)),count(*)
  INTO v_items,v_count FROM chosen;
  IF v_count<>12 OR jsonb_array_length(v_items)<>12 THEN
    RETURN jsonb_build_object('ok',false,'code','insufficient_approved_questions');
  END IF;
  INSERT INTO private.iclub_exam_native_mcq_attempts_v1
    (id,user_id,program_key,version_key,paper_code,client_key,items,deadline_at,session_kind)
  VALUES (v_id,v_user,'economics_9708',v_version,p_paper_code,p_client_key,
    v_items,clock_timestamp()+make_interval(secs=>v_limit),'diagnostic');
  RETURN jsonb_build_object('ok',true,'session_id',v_id,'status','active',
    'resumed',false,'total_items',12,'duration_seconds',v_limit,'session_kind','diagnostic');
EXCEPTION WHEN unique_violation THEN
  -- Concurrent retries fail closed; caller can resume through its authenticated status query.
  RETURN jsonb_build_object('ok',false,'code','concurrent_start_retry');
END;
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_get_v1(
  p_session_id uuid,p_language text DEFAULT 'ru'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
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
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_answer_v1(
  p_session_id uuid,p_item_order integer,p_choice integer
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
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
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_finish_v1(
  p_session_id uuid
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
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
$f$;

CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_history_v1(
 p_paper_code text DEFAULT NULL
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid(); v_rows jsonb;
BEGIN
 IF v_user IS NULL OR (p_paper_code IS NOT NULL AND p_paper_code NOT IN('P1','P3')) THEN
   RETURN jsonb_build_object('ok',false,'code','invalid_request');
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
   'session_id',s.id,
   'paper_code',s.paper_code,'session_kind',s.session_kind,
   'status',s.status,
   'started_at',s.started_at,
   'deadline_at',s.deadline_at,
   'finalized_at',s.finalized_at,
   'score',CASE WHEN s.status='finalized' THEN s.score ELSE NULL END,
   'total_items',jsonb_array_length(s.items),
   'answered',(SELECT count(*) FROM jsonb_object_keys(s.responses))
 ) ORDER BY s.started_at DESC),'[]'::jsonb)
 INTO v_rows
 FROM (SELECT * FROM private.iclub_exam_native_mcq_attempts_v1
   WHERE user_id=v_user AND program_key='economics_9708'
   AND version_key='economics_2026_2028_v1'
   AND (p_paper_code IS NULL OR paper_code=p_paper_code)
   ORDER BY started_at DESC LIMIT 20) s;
 RETURN jsonb_build_object('ok',true,'sessions',v_rows);
END;
$f$;

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
    'ok',true,'paper_code',v_session.paper_code,'session_kind',v_session.session_kind,
    'session_id',v_session.id,'score',v_session.score,
    'out_of',jsonb_array_length(v_session.items),'finalized_at',v_session.finalized_at,
    'week_horizon_days',7,
    'unit_results',v_units,'mistakes',v_mistakes,
    'priorities',v_priorities,'weak_count',v_weak_count,
    'studied_count',v_studied_count,
    'retested_correct_count',v_retested_count,
    'interpretation','Self-reported study does not imply mastery. Retest evidence requires a correct answer in a later completed exam.'
  );
END;
$f$;

REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_start_diagnostic_v1(text,text) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_start_diagnostic_v1(text,text) TO authenticated;
DO $qa$
DECLARE v_old int; v_beta int;
BEGIN
 SELECT count(*) INTO v_old FROM private.iclub_exam_native_mcq_attempts_v1 WHERE session_kind='paper';
 IF v_old<>1 THEN RAISE EXCEPTION 'Existing production Paper count changed during rollout: %',v_old; END IF;
 IF EXISTS (SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1
    WHERE session_kind='paper' AND jsonb_array_length(items)<>30)
 THEN RAISE EXCEPTION 'Historical Paper contract altered'; END IF;
 IF EXISTS (SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1 WHERE session_kind='diagnostic')
 THEN RAISE EXCEPTION 'Unexpected diagnostic records before release'; END IF;
 SELECT count(*) INTO v_beta FROM public.users u WHERE private.iclub_exam_native_economics_beta_allowed_v1(u.id);
 IF v_beta<>3 THEN RAISE EXCEPTION 'Expected same three Math beta users, got %',v_beta; END IF;
 IF has_function_privilege('anon','public.iclub_exam_native_mcq_start_diagnostic_v1(text,text)','EXECUTE')
 OR has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','SELECT')
 OR (SELECT count(*) FROM private.exam_prep_program_versions WHERE program_key='math_as_p1_p5' AND status='active')<>1
 THEN RAISE EXCEPTION 'Access or Mathematics invariant failed'; END IF;
END $qa$;
COMMIT;
