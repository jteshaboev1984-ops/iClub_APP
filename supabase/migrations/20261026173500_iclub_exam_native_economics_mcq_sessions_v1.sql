-- iClub Economics 9708 — native MCQ sessions, isolated from legacy Mathematics.
-- Backward-compatible additive migration. Program/papers remain draft and disabled.
-- No learner attempts are created by this migration.
BEGIN;

CREATE TABLE IF NOT EXISTS private.iclub_exam_native_mcq_attempts_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id),
  program_key text NOT NULL,
  version_key text NOT NULL,
  paper_code text NOT NULL CHECK (paper_code IN ('P1','P3')),
  status text NOT NULL DEFAULT 'active' CHECK(status IN ('active','finalized')),
  client_key text NOT NULL CHECK(length(client_key) BETWEEN 12 AND 128),
  items jsonb NOT NULL CHECK(jsonb_typeof(items)='array' AND jsonb_array_length(items)=30),
  responses jsonb NOT NULL DEFAULT '{}'::jsonb CHECK(jsonb_typeof(responses)='object'),
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  deadline_at timestamptz NOT NULL,
  finalized_at timestamptz,
  score integer CHECK(score BETWEEN 0 AND 30),
  CONSTRAINT economics_native_attempt_program_fk
    FOREIGN KEY(program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key),
  CONSTRAINT economics_native_attempt_paper_fk
    FOREIGN KEY(program_key,version_key,paper_code)
    REFERENCES private.iclub_exam_core_papers_v1(program_key,version_key,paper_code),
  CONSTRAINT economics_native_attempt_complete_ck CHECK(
    (status='active' AND finalized_at IS NULL AND score IS NULL)
    OR (status='finalized' AND finalized_at IS NOT NULL AND score IS NOT NULL)
  )
);
CREATE UNIQUE INDEX IF NOT EXISTS economics_native_attempt_client_key_uq
ON private.iclub_exam_native_mcq_attempts_v1(user_id,program_key,version_key,paper_code,client_key);
CREATE UNIQUE INDEX IF NOT EXISTS economics_native_attempt_one_active_uq
ON private.iclub_exam_native_mcq_attempts_v1(user_id,program_key,version_key,paper_code)
WHERE status='active';
CREATE INDEX IF NOT EXISTS economics_native_attempt_user_history_idx
ON private.iclub_exam_native_mcq_attempts_v1(user_id,started_at DESC);
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_native_mcq_attempts_v1 FORCE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_native_mcq_attempts_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT ON private.iclub_exam_native_mcq_attempts_v1 TO service_role;

-- Shared invariant: only the signed-in owner with live Economics enrollment can access a session.
-- This is an internal helper with no client-side EXECUTE grant.
CREATE OR REPLACE FUNCTION private.iclub_exam_native_mcq_enrolled_v1(p_user uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path=''
AS $f$
SELECT p_user IS NOT NULL AND EXISTS(
  SELECT 1 FROM public.user_subjects us
  JOIN public.subjects subj ON subj.id=us.subject_id
  WHERE us.user_id=p_user AND subj.subject_key='economics' AND subj.is_active=true
);
$f$;
REVOKE ALL ON FUNCTION private.iclub_exam_native_mcq_enrolled_v1(uuid)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_native_mcq_enrolled_v1(uuid) TO service_role;

-- Start: server chooses exactly 30 distinct reviewed skills, with unit quotas.
-- Freeze all translations, all four option lists, answer and per-learner option permutation privately.
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
    AND client_key=p_client_key;
  IF FOUND THEN RETURN jsonb_build_object('ok',true,'session_id',v_existing.id,
    'status',v_existing.status,'resumed',true); END IF;
  -- One unfinished attempt per learner+paper. Expired attempt must be finalized first.
  SELECT * INTO v_existing FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE user_id=v_user AND program_key='economics_9708'
    AND version_key=v_version AND paper_code=p_paper_code AND status='active';
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
    'resumed',false,'total_items',30,'duration_seconds',v_limit);
EXCEPTION WHEN unique_violation THEN
  -- Concurrent retries fail closed; caller can resume through its authenticated status query.
  RETURN jsonb_build_object('ok',false,'code','concurrent_start_retry');
END;
$f$;

-- Read exactly the authenticated owner's frozen session.
-- Never expose key, unshown option index, grading, or explanation while active.
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
    'total_items',30,'items',coalesce(v_rows,'[]'::jsonb));
END;
$f$;

-- First response wins. No learner-owned score or source keys are accepted.
CREATE OR REPLACE FUNCTION public.iclub_exam_native_mcq_answer_v1(
  p_session_id uuid,p_item_order integer,p_choice integer
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $f$
DECLARE v_user uuid:=auth.uid();
  v private.iclub_exam_native_mcq_attempts_v1%ROWTYPE;
  v_key text;
  v_prior jsonb;
BEGIN
  IF v_user IS NULL OR p_session_id IS NULL
    OR p_item_order NOT BETWEEN 1 AND 30 OR p_choice NOT BETWEEN 0 AND 3 THEN
    RETURN jsonb_build_object('ok',false,'code','invalid_request');
  END IF;
  SELECT * INTO v FROM private.iclub_exam_native_mcq_attempts_v1
  WHERE id=p_session_id AND user_id=v_user FOR UPDATE;
  IF NOT FOUND THEN RETURN jsonb_build_object('ok',false,'code','not_found'); END IF;
  v_key:=p_item_order::text;
  v_prior:=v.responses->v_key;
  IF v_prior IS NOT NULL THEN
    RETURN jsonb_build_object('ok',true,'saved',true,'duplicate',true,
      'same_choice',((v_prior->>'choice')::int=p_choice));
  END IF;
  IF v.status<>'active' OR clock_timestamp()>=v.deadline_at THEN
    RETURN jsonb_build_object('ok',false,'code','attempt_closed_or_expired');
  END IF;
  UPDATE private.iclub_exam_native_mcq_attempts_v1
  SET responses=jsonb_set(responses,ARRAY[v_key],
    jsonb_build_object('choice',p_choice,'at',clock_timestamp()),true)
  WHERE id=v.id AND user_id=v_user;
  RETURN jsonb_build_object('ok',true,'saved',true,'duplicate',false);
END;
$f$;

-- Finish once, with actual server time. Source answer indices stay private.
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
    'status','finalized','score',v.score,'out_of',30,'duplicate',true); END IF;
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
    'score',v_score,'out_of',30,'answered',v_answered,'duplicate',false);
END;
$f$;

REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_get_v1(uuid,text) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_answer_v1(uuid,integer,integer) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.iclub_exam_native_mcq_finish_v1(uuid) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_start_v1(text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_get_v1(uuid,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_answer_v1(uuid,integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_native_mcq_finish_v1(uuid) TO authenticated;

DO $assert$
BEGIN
  IF EXISTS (SELECT 1 FROM private.iclub_exam_native_mcq_attempts_v1) THEN
    RAISE EXCEPTION 'Initial native attempt table not empty';
  END IF;
  IF has_table_privilege('authenticated','private.iclub_exam_native_mcq_attempts_v1','SELECT')
   OR has_table_privilege('anon','private.iclub_exam_native_mcq_attempts_v1','SELECT')
   OR has_function_privilege('anon','public.iclub_exam_native_mcq_start_v1(text,text)','EXECUTE') THEN
    RAISE EXCEPTION 'Native runtime privilege violation';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM private.iclub_exam_core_programs_v1
     WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
       AND status='draft' AND launch_enabled=false) THEN
    RAISE EXCEPTION 'Economics unexpectedly enabled during runtime migration';
  END IF;
  IF (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
      WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
      AND paper_code='P1' AND status='approved')<>36
   OR (SELECT count(*) FROM private.iclub_exam_core_question_candidates_v1
      WHERE program_key='economics_9708' AND version_key='economics_2026_2028_v1'
      AND paper_code='P3' AND status='approved')<>36
   OR (SELECT count(*) FROM private.exam_prep_program_versions
      WHERE program_key='math_as_p1_p5' AND status='active')<>1 THEN
    RAISE EXCEPTION 'Content or Math regression detected';
  END IF;
END;
$assert$;
COMMIT;
