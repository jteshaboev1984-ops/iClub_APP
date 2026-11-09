-- iClub Mathematics P1/P5, Issue #450, architect 2026-11-09 approved HYBRID.
-- SOURCE-ONLY DRAFT; no live SQL, Core activation, paid AI, Mentor or user data change.
-- No learner self-awarded marks, no legacy Paper responses or stage writes.
-- All functions use the EXISTING approved Core access authorizer.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_hybrid_s4_config_v1 (
  singleton boolean PRIMARY KEY DEFAULT true CHECK (singleton),
  paper_enabled boolean NOT NULL DEFAULT false,
  stage_gates_enabled boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (NOT stage_gates_enabled OR paper_enabled)
);
INSERT INTO private.exam_prep_hybrid_s4_config_v1(singleton,paper_enabled,stage_gates_enabled)
VALUES(true,false,false) ON CONFLICT(singleton) DO NOTHING;
ALTER TABLE private.exam_prep_hybrid_s4_config_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_hybrid_s4_config_v1 FROM PUBLIC,anon,authenticated;

CREATE TABLE IF NOT EXISTS private.exam_prep_hybrid_s4_sessions_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id) ON DELETE RESTRICT,
  assessment_id bigint NOT NULL REFERENCES private.exam_prep_assessments(id) ON DELETE RESTRICT,
  assessment_key text NOT NULL,
  assessment_version text NOT NULL,
  component_code text NOT NULL CHECK(component_code IN('P1','P5')),
  time_limit_sec integer NOT NULL CHECK(time_limit_sec BETWEEN 1 AND 14400),
  marks_available integer NOT NULL CHECK(marks_available IN(50,75)),
  client_start_key text NOT NULL CHECK(length(client_start_key) BETWEEN 12 AND 150),
  started_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  deadline_at timestamptz NOT NULL,
  closed_at timestamptz,
  closure_code text CHECK(closure_code IN('ended_by_learner','ended_early','time_expired')),
  review_revealed_at timestamptz,
  prior_review_seen boolean NOT NULL DEFAULT false,
  UNIQUE(user_id,client_start_key),
  CHECK((closed_at IS NULL AND closure_code IS NULL) OR
        (closed_at IS NOT NULL AND closure_code IS NOT NULL)),
  CHECK(review_revealed_at IS NULL OR closed_at IS NOT NULL),
  CHECK(deadline_at > started_at)
);
CREATE INDEX IF NOT EXISTS exam_prep_hybrid_s4_history_owner
ON private.exam_prep_hybrid_s4_sessions_v1(user_id,component_code,started_at DESC);
ALTER TABLE private.exam_prep_hybrid_s4_sessions_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_hybrid_s4_sessions_v1 FROM PUBLIC,anon,authenticated;

-- Approved answer keys are deliberately NOT inserted into public Git history.
-- The 12 source-audited question parts are CANDIDATES only until reviewed keys
-- and tested equivalence/units/rounding are privately approved.
CREATE TABLE IF NOT EXISTS private.exam_prep_hybrid_s4_checkpoint_keys_v1 (
  assessment_id bigint NOT NULL REFERENCES private.exam_prep_assessments(id) ON DELETE RESTRICT,
  item_order smallint NOT NULL CHECK(item_order BETWEEN 1 AND 30),
  part_label text NOT NULL CHECK(length(part_label) BETWEEN 1 AND 12),
  written_task_id bigint NOT NULL REFERENCES private.exam_prep_written_tasks(id) ON DELETE RESTRICT,
  source_task_version text NOT NULL,
  expected_numeric numeric,
  absolute_tolerance numeric NOT NULL DEFAULT 0 CHECK(absolute_tolerance >= 0 AND absolute_tolerance <= 1),
  review_state text NOT NULL DEFAULT 'candidate' CHECK(review_state IN('candidate','approved','disabled')),
  academic_review_ref text,
  approved_at timestamptz,
  PRIMARY KEY(assessment_id,item_order,part_label),
  CHECK(review_state<>'approved' OR
    (expected_numeric IS NOT NULL AND academic_review_ref IS NOT NULL AND
      length(trim(academic_review_ref))>=8 AND approved_at IS NOT NULL))
);
ALTER TABLE private.exam_prep_hybrid_s4_checkpoint_keys_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_hybrid_s4_checkpoint_keys_v1 FROM PUBLIC,anon,authenticated;

CREATE TABLE IF NOT EXISTS private.exam_prep_hybrid_s4_checks_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL REFERENCES private.exam_prep_hybrid_s4_sessions_v1(id) ON DELETE RESTRICT,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  assessment_id bigint NOT NULL,
  item_order smallint NOT NULL,
  part_label text NOT NULL,
  input_text text NOT NULL CHECK(length(input_text) BETWEEN 1 AND 80),
  matched boolean NOT NULL,
  client_request_key text NOT NULL CHECK(length(client_request_key) BETWEEN 12 AND 150),
  checked_at timestamptz NOT NULL DEFAULT clock_timestamp(),
  FOREIGN KEY(assessment_id,item_order,part_label)
    REFERENCES private.exam_prep_hybrid_s4_checkpoint_keys_v1(assessment_id,item_order,part_label),
  UNIQUE(session_id,item_order,part_label),
  UNIQUE(session_id,client_request_key)
);
ALTER TABLE private.exam_prep_hybrid_s4_checks_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_hybrid_s4_checks_v1 FROM PUBLIC,anon,authenticated;

CREATE OR REPLACE FUNCTION private.exam_prep_hybrid_s4_parse_numeric_v1(p_input text)
RETURNS numeric LANGUAGE plpgsql IMMUTABLE SET search_path TO ''
AS $s4num$
DECLARE v_text text; v_n numeric; v_d numeric;
BEGIN
  IF p_input IS NULL OR length(p_input)>80 THEN RETURN NULL; END IF;
  v_text:=trim(replace(p_input,',','.'));
  -- No browser expression evaluation, scientific code, units or arbitrary SQL casts.
  IF v_text ~ '^[+-]?[0-9]{1,12}(\.[0-9]{1,12})?$' THEN
    v_n:=v_text::numeric;
  ELSIF v_text ~ '^[+-]?[0-9]{1,12}/[1-9][0-9]{0,11}$' THEN
    v_n:=split_part(v_text,'/',1)::numeric;
    v_d:=split_part(v_text,'/',2)::numeric;
    v_n:=v_n/v_d;
  ELSE
    RETURN NULL;
  END IF;
  IF abs(v_n)>1000000000000 THEN RETURN NULL; END IF;
  RETURN v_n;
EXCEPTION WHEN numeric_value_out_of_range OR division_by_zero OR invalid_text_representation THEN
  RETURN NULL;
END;
$s4num$;
REVOKE ALL ON FUNCTION private.exam_prep_hybrid_s4_parse_numeric_v1(text)
FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.exam_prep_hybrid_s4_parse_numeric_v1(text) TO service_role;

-- Source-approved latest Paper versions only; never present archival versions as 8 unique forms.
CREATE OR REPLACE FUNCTION public.get_exam_prep_hybrid_s4_papers_safe_v1(p_component_code text)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4catalog$
DECLARE v_uid uuid; v_program bigint; v_enabled boolean; v_papers jsonb;
BEGIN
  v_uid:=private.exam_prep_require_core_access_v1();
  IF p_component_code NOT IN('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
  SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
  IF v_program IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
  SELECT paper_enabled INTO v_enabled FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton;
  IF v_enabled IS DISTINCT FROM true THEN
    RETURN jsonb_build_object('enabled',false,'papers','[]'::jsonb,'no_student_marks',true);
  END IF;
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
    'assessment_id',z.id,'paper_key',z.assessment_key,'assessment_version',z.assessment_version,
    'title',z.title,'component_code',z.component_code,
    'available_marks',z.marks_available,'time_limit_sec',z.official_duration_sec,
    'checkpoints_available',z.checkpoints_available) ORDER BY z.assessment_key),'[]'::jsonb)
  INTO v_papers
  FROM (
    SELECT DISTINCT ON(a.assessment_key)
      a.id,a.assessment_key,a.assessment_version,a.component_code,a.title_en AS title,
      c.marks_available,p.official_duration_sec,a.approved_at,
      (SELECT count(*)::int FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1 k
       WHERE k.assessment_id=a.id AND k.review_state='approved') checkpoints_available
    FROM private.exam_prep_assessments a
    JOIN private.exam_prep_timed_assessment_contracts c
      ON c.assessment_id=a.id AND c.attempt_kind='full_paper' AND c.status='published'
    JOIN private.exam_prep_component_paper_profiles p
      ON p.id=c.paper_profile_id AND p.component_code=a.component_code AND p.status='published'
    JOIN private.exam_prep_content_versions cv
      ON cv.id=a.content_version_id AND cv.program_version_id=v_program
    WHERE a.component_code=p_component_code AND a.status='published'
    ORDER BY a.assessment_key,a.approved_at DESC,a.id DESC
  ) z;
  RETURN jsonb_build_object('enabled',true,'component_code',p_component_code,
    'papers',v_papers,'no_student_marks',true,'written_method_marked',false,
    'mentor_marking_available',false,'ai_marking_available',false);
END;
$s4catalog$;

-- Start, idempotent by owner+key. A stale retry can recover its old row without double start.
CREATE OR REPLACE FUNCTION public.start_exam_prep_hybrid_s4_paper_safe_v1(
  p_assessment_id bigint,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $s4start$
DECLARE
 v_uid uuid; v_program bigint; v_enabled boolean;
 v_id bigint; v_key text; v_version text; v_component text;
 v_marks int; v_seconds int; v_when timestamptz; v_previous boolean;
 v_session private.exam_prep_hybrid_s4_sessions_v1%rowtype;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_idempotency_key IS NULL OR length(p_idempotency_key) NOT BETWEEN 12 AND 150 THEN
   RAISE EXCEPTION 'exam_prep_s4_bad_idempotency_key' USING ERRCODE='22023'; END IF;
 SELECT * INTO v_session FROM private.exam_prep_hybrid_s4_sessions_v1
  WHERE user_id=v_uid AND client_start_key=p_idempotency_key;
 IF v_session.id IS NOT NULL THEN
   IF v_session.assessment_id IS DISTINCT FROM p_assessment_id THEN
     RAISE EXCEPTION 'exam_prep_s4_start_key_conflict'; END IF;
   RETURN jsonb_build_object('session_id',v_session.id,'component_code',v_session.component_code,
     'started_at',v_session.started_at,'deadline_at',v_session.deadline_at,
     'closed_at',v_session.closed_at,'replayed',true,'no_marks_awarded',true);
 END IF;
 SELECT paper_enabled INTO v_enabled FROM private.exam_prep_hybrid_s4_config_v1 WHERE singleton;
 IF v_enabled IS DISTINCT FROM true THEN RAISE EXCEPTION 'exam_prep_s4_not_enabled' USING ERRCODE='42501'; END IF;
 SELECT program_version_id INTO v_program FROM private.exam_prep_exam_profiles WHERE user_id=v_uid;
 IF v_program IS NULL THEN RAISE EXCEPTION 'exam_prep_profile_required'; END IF;
 -- Only the CURRENT published revision of an approved Paper key.
 SELECT z.id,z.assessment_key,z.assessment_version,z.component_code,
   z.marks_available,z.official_duration_sec
 INTO v_id,v_key,v_version,v_component,v_marks,v_seconds
 FROM (
  SELECT DISTINCT ON(a.component_code,a.assessment_key)
    a.id,a.assessment_key,a.assessment_version,a.component_code,
    c.marks_available,p.official_duration_sec
  FROM private.exam_prep_assessments a
  JOIN private.exam_prep_timed_assessment_contracts c
    ON c.assessment_id=a.id AND c.attempt_kind='full_paper' AND c.status='published'
  JOIN private.exam_prep_component_paper_profiles p
    ON p.id=c.paper_profile_id AND p.component_code=a.component_code AND p.status='published'
  JOIN private.exam_prep_content_versions cv
    ON cv.id=a.content_version_id AND cv.program_version_id=v_program
  WHERE a.status='published' AND a.component_code IN ('P1','P5')
  ORDER BY a.component_code,a.assessment_key,a.approved_at DESC,a.id DESC
 ) z WHERE z.id=p_assessment_id;
 IF v_id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_paper_unavailable'; END IF;
 IF (v_component='P1' AND (v_marks<>75 OR v_seconds<>6600)) OR
    (v_component='P5' AND (v_marks<>50 OR v_seconds<>4500)) THEN
    RAISE EXCEPTION 'exam_prep_s4_profile_mismatch'; END IF;
 SELECT EXISTS(
   SELECT 1 FROM private.exam_prep_hybrid_s4_sessions_v1 s
   WHERE s.user_id=v_uid AND s.program_version_id=v_program
     AND s.component_code=v_component AND s.assessment_key=v_key
     AND s.review_revealed_at IS NOT NULL
 ) INTO v_previous;
 v_when:=clock_timestamp();
 INSERT INTO private.exam_prep_hybrid_s4_sessions_v1(
   user_id,program_version_id,assessment_id,assessment_key,assessment_version,
   component_code,time_limit_sec,marks_available,client_start_key,
   started_at,deadline_at,prior_review_seen
 ) VALUES(v_uid,v_program,v_id,v_key,v_version,v_component,v_seconds,v_marks,
   p_idempotency_key,v_when,v_when+make_interval(secs=>v_seconds),v_previous)
 ON CONFLICT(user_id,client_start_key) DO NOTHING;
 SELECT * INTO v_session FROM private.exam_prep_hybrid_s4_sessions_v1
  WHERE user_id=v_uid AND client_start_key=p_idempotency_key;
 IF v_session.id IS NULL OR v_session.assessment_id IS DISTINCT FROM p_assessment_id THEN
  RAISE EXCEPTION 'exam_prep_s4_start_conflict';
 END IF;
 RETURN jsonb_build_object('session_id',v_session.id,'component_code',v_session.component_code,
   'started_at',v_session.started_at,'deadline_at',v_session.deadline_at,
   'closed_at',v_session.closed_at,'prior_review_seen',v_session.prior_review_seen,
   'replayed',false,'no_marks_awarded',true);
END;
$s4start$;

-- Read a current or historical owner rehearsal; no rubric, answer key, or method marks.
CREATE OR REPLACE FUNCTION public.get_exam_prep_hybrid_s4_session_safe_v1(
 p_session_id uuid,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4get$
DECLARE v_uid uuid; v_s private.exam_prep_hybrid_s4_sessions_v1%rowtype;
 v_items jsonb; v_checkpoints jsonb; v_reviews jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_language NOT IN ('ru','uz','en') THEN RAISE EXCEPTION 'exam_prep_bad_language'; END IF;
 SELECT * INTO v_s FROM private.exam_prep_hybrid_s4_sessions_v1
  WHERE id=p_session_id AND user_id=v_uid;
 IF v_s.id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_session_not_found' USING ERRCODE='P0002'; END IF;
 SELECT COALESCE(jsonb_agg(jsonb_build_object(
   'item_order',i.item_order,'prompt',
   CASE p_language WHEN 'ru' THEN w.prompt_ru WHEN 'uz' THEN w.prompt_uz ELSE w.prompt_en END,
   'skill_code',i.primary_skill_code,
   'max_available_marks',t.max_marks
 ) ORDER BY i.item_order),'[]'::jsonb) INTO v_items
 FROM private.exam_prep_assessment_items i
 JOIN private.exam_prep_written_tasks w ON w.id=i.written_task_id
 JOIN private.exam_prep_timed_assessment_items t
  ON t.assessment_id=i.assessment_id AND t.item_order=i.item_order
 WHERE i.assessment_id=v_s.assessment_id;
 SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'item_order',k.item_order,'part_label',k.part_label,
  'checked',ck.id IS NOT NULL,
  'matched',ck.matched
 ) ORDER BY k.item_order,k.part_label),'[]'::jsonb) INTO v_checkpoints
 FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1 k
 LEFT JOIN private.exam_prep_hybrid_s4_checks_v1 ck
   ON ck.session_id=v_s.id AND ck.assessment_id=k.assessment_id
     AND ck.item_order=k.item_order AND ck.part_label=k.part_label
 WHERE k.assessment_id=v_s.assessment_id AND k.review_state='approved'
  AND v_s.closed_at IS NOT NULL;
 RETURN jsonb_build_object('contract','hybrid_s4_paper_v1',
  'session_id',v_s.id,'component_code',v_s.component_code,
  'assessment_id',v_s.assessment_id,'paper_key',v_s.assessment_key,
  'assessment_version',v_s.assessment_version,'time_limit_sec',v_s.time_limit_sec,
  'max_available_marks',v_s.marks_available,'started_at',v_s.started_at,
  'deadline_at',v_s.deadline_at,'closed_at',v_s.closed_at,
  'closure_code',v_s.closure_code,'review_revealed',v_s.review_revealed_at IS NOT NULL,
  'prior_review_seen',v_s.prior_review_seen,
  'items',v_items,'checkpoints',v_checkpoints,'writing_not_graded',true,
  'awarded_paper_marks',null,'full_paper_readiness','unknown',
  'self_grading',false,'mentor_marking_enabled',false,'ai_marking_enabled',false);
END;
$s4get$;

-- Learner-ended is NOT a verified completed mathematics exam.
CREATE OR REPLACE FUNCTION public.finish_exam_prep_hybrid_s4_paper_safe_v1(
 p_session_id uuid,p_reason text,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $s4finish$
DECLARE v_uid uuid; v_s private.exam_prep_hybrid_s4_sessions_v1%rowtype; v_now timestamptz;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_reason NOT IN('finish','early_exit','time_expired') OR
  p_idempotency_key IS NULL OR length(p_idempotency_key) NOT BETWEEN 12 AND 150
 THEN RAISE EXCEPTION 'exam_prep_s4_invalid_finish_request'; END IF;
 SELECT * INTO v_s FROM private.exam_prep_hybrid_s4_sessions_v1
 WHERE id=p_session_id AND user_id=v_uid FOR UPDATE;
 IF v_s.id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_session_not_found' USING ERRCODE='P0002'; END IF;
 IF v_s.closed_at IS NOT NULL THEN
  RETURN jsonb_build_object('closed',true,'replayed',true,'closure_code',v_s.closure_code,
   'closed_at',v_s.closed_at,'method_verified',false,'paper_marks',null); END IF;
 v_now:=clock_timestamp();
 UPDATE private.exam_prep_hybrid_s4_sessions_v1 SET
 closed_at=v_now,
 closure_code=CASE WHEN v_now>=v_s.deadline_at THEN 'time_expired'
   WHEN p_reason='early_exit' THEN 'ended_early' ELSE 'ended_by_learner' END
 WHERE id=v_s.id;
 RETURN jsonb_build_object('closed',true,'replayed',false,
  'closure_code',CASE WHEN v_now>=v_s.deadline_at THEN 'time_expired'
   WHEN p_reason='early_exit' THEN 'ended_early' ELSE 'ended_by_learner' END,
  'closed_at',v_now,'duration_seconds',floor(extract(epoch FROM (v_now-v_s.started_at)))::int,
  'method_verified',false,'paper_marks',null);
END;
$s4finish$;

-- A checkpoint result is a deterministic match of ONE final numeric subpart,
-- not a student-written mark. Never returns the secret answer/key/rubric.
CREATE OR REPLACE FUNCTION public.check_exam_prep_hybrid_s4_final_safe_v1(
 p_session_id uuid,p_item_order smallint,p_part_label text,
 p_answer text,p_idempotency_key text
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $s4check$
DECLARE v_uid uuid; v_s private.exam_prep_hybrid_s4_sessions_v1%rowtype;
 v_k private.exam_prep_hybrid_s4_checkpoint_keys_v1%rowtype;
 v_old private.exam_prep_hybrid_s4_checks_v1%rowtype;
 v_value numeric; v_matched boolean;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_idempotency_key IS NULL OR length(p_idempotency_key) NOT BETWEEN 12 AND 150 OR
    p_answer IS NULL OR length(trim(p_answer)) NOT BETWEEN 1 AND 80 THEN
  RAISE EXCEPTION 'exam_prep_s4_invalid_checkpoint_request'; END IF;
 -- Lock serializes check vs reveal of the same session.
 SELECT * INTO v_s FROM private.exam_prep_hybrid_s4_sessions_v1
 WHERE id=p_session_id AND user_id=v_uid FOR UPDATE;
 IF v_s.id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_session_not_found' USING ERRCODE='P0002'; END IF;
 SELECT * INTO v_old FROM private.exam_prep_hybrid_s4_checks_v1
 WHERE session_id=v_s.id AND item_order=p_item_order AND part_label=p_part_label;
 IF v_old.id IS NOT NULL THEN
   IF v_old.client_request_key IS DISTINCT FROM p_idempotency_key OR
      v_old.input_text IS DISTINCT FROM trim(p_answer) THEN
    RAISE EXCEPTION 'exam_prep_s4_checkpoint_immutable'; END IF;
   RETURN jsonb_build_object('status','checked','replayed',true,
     'item_order',p_item_order,'part_label',p_part_label,'matched',v_old.matched,
     'written_method_verified',false,'paper_marks_awarded',null,
     'independent_pre_reveal',NOT v_s.prior_review_seen);
 END IF;
 IF v_s.closed_at IS NULL OR v_s.review_revealed_at IS NOT NULL THEN
  RAISE EXCEPTION 'exam_prep_s4_check_only_after_end_before_reveal'; END IF;
 SELECT * INTO v_k FROM private.exam_prep_hybrid_s4_checkpoint_keys_v1
 WHERE assessment_id=v_s.assessment_id AND item_order=p_item_order
   AND part_label=p_part_label AND review_state='approved'
   AND expected_numeric IS NOT NULL AND approved_at IS NOT NULL;
 IF v_k.assessment_id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_checkpoint_not_approved'; END IF;
 v_value:=private.exam_prep_hybrid_s4_parse_numeric_v1(p_answer);
 IF v_value IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_unrecognized_numeric_format'; END IF;
 v_matched:=abs(v_value-v_k.expected_numeric)<=v_k.absolute_tolerance;
 INSERT INTO private.exam_prep_hybrid_s4_checks_v1(
  session_id,user_id,assessment_id,item_order,part_label,input_text,matched,client_request_key)
 VALUES(v_s.id,v_uid,v_s.assessment_id,p_item_order,p_part_label,trim(p_answer),v_matched,p_idempotency_key);
 RETURN jsonb_build_object('status','checked','replayed',false,
  'item_order',p_item_order,'part_label',p_part_label,'matched',v_matched,
  'written_method_verified',false,'paper_marks_awarded',null,
  'independent_pre_reveal',NOT v_s.prior_review_seen);
END;
$s4check$;

-- After end, reveal localized requirements + short guidance, never a self-mark form.
-- Opening review closes the optional answer-check window atomically.
CREATE OR REPLACE FUNCTION public.reveal_exam_prep_hybrid_s4_review_safe_v1(
 p_session_id uuid,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO ''
AS $s4review$
DECLARE v_uid uuid; v_s private.exam_prep_hybrid_s4_sessions_v1%rowtype;
 v_items jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_language NOT IN('ru','uz','en') THEN RAISE EXCEPTION 'exam_prep_bad_language'; END IF;
 SELECT * INTO v_s FROM private.exam_prep_hybrid_s4_sessions_v1
 WHERE id=p_session_id AND user_id=v_uid FOR UPDATE;
 IF v_s.id IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_session_not_found' USING ERRCODE='P0002'; END IF;
 IF v_s.closed_at IS NULL THEN RAISE EXCEPTION 'exam_prep_s4_review_requires_finished_paper'; END IF;
 IF v_s.review_revealed_at IS NULL THEN
   UPDATE private.exam_prep_hybrid_s4_sessions_v1
     SET review_revealed_at=clock_timestamp() WHERE id=v_s.id;
 END IF;
 SELECT COALESCE(jsonb_agg(jsonb_build_object(
   'item_order',i.item_order,'skill_code',i.primary_skill_code,
   'prompt',CASE p_language WHEN 'ru' THEN w.prompt_ru WHEN 'uz' THEN w.prompt_uz ELSE w.prompt_en END,
   'requirements',(SELECT COALESCE(jsonb_agg(
       CASE WHEN p_language='en' THEN c.value->>'rule'
       ELSE coalesce(cl.translated_rule,'Translation not approved') END
       ORDER BY c.ordinality),'[]'::jsonb)
     FROM jsonb_array_elements(w.rubric_json->'criteria') WITH ORDINALITY AS c(value,ordinality)
     LEFT JOIN private.exam_prep_written_criteria_locale_v1 cl
      ON cl.written_task_id=w.id AND cl.task_version=w.task_version
       AND cl.criterion_id=c.value->>'id' AND cl.language=p_language
       AND cl.review_state='approved'),
   'review_hint',CASE p_language WHEN 'ru' THEN w.self_review_ru
     WHEN 'uz' THEN w.self_review_uz ELSE w.self_review_en END
 ) ORDER BY i.item_order),'[]'::jsonb) INTO v_items
 FROM private.exam_prep_assessment_items i
 JOIN private.exam_prep_written_tasks w ON w.id=i.written_task_id
 WHERE i.assessment_id=v_s.assessment_id;
 RETURN jsonb_build_object('session_id',v_s.id,'review_revealed',true,
  'scope','criteria_and_short_hints_only','items',v_items,
  'full_worked_solutions_verified',false,
  'written_method_verified',false,'paper_marks_awarded',null,
  'mentor_marking_available',false,'ai_marking_available',false,
  'student_scoring',false);
END;
$s4review$;

CREATE OR REPLACE FUNCTION public.get_exam_prep_hybrid_s4_history_safe_v1(
 p_component_code text
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO ''
AS $s4history$
DECLARE v_uid uuid; v_history jsonb;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_component_code NOT IN ('P1','P5') THEN RAISE EXCEPTION 'exam_prep_bad_component'; END IF;
 SELECT COALESCE(jsonb_agg(jsonb_build_object(
  'session_id',s.id,'paper_key',s.assessment_key,
  'assessment_version',s.assessment_version,'started_at',s.started_at,
  'closed_at',s.closed_at,'closure_code',s.closure_code,
  'deadline_at',s.deadline_at,'review_revealed',s.review_revealed_at IS NOT NULL,
  'checkpoints_matched',(SELECT count(*)::int FROM private.exam_prep_hybrid_s4_checks_v1 ck
     WHERE ck.session_id=s.id AND ck.matched),
  'checkpoints_checked',(SELECT count(*)::int FROM private.exam_prep_hybrid_s4_checks_v1 ck
     WHERE ck.session_id=s.id)
 ) ORDER BY s.started_at DESC),'[]'::jsonb) INTO v_history
 FROM (SELECT * FROM private.exam_prep_hybrid_s4_sessions_v1
       WHERE user_id=v_uid AND component_code=p_component_code
       ORDER BY started_at DESC,id DESC LIMIT 30) s;
 RETURN jsonb_build_object('component_code',p_component_code,'sessions',v_history,
  'academic_credit',false,'full_paper_marks',null,'written_method_verified',false);
END;
$s4history$;

-- Every public endpoint is owner-bound by the existing Core access authorizer.
REVOKE ALL ON FUNCTION public.get_exam_prep_hybrid_s4_papers_safe_v1(text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.start_exam_prep_hybrid_s4_paper_safe_v1(bigint,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.get_exam_prep_hybrid_s4_session_safe_v1(uuid,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.finish_exam_prep_hybrid_s4_paper_safe_v1(uuid,text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.check_exam_prep_hybrid_s4_final_safe_v1(uuid,smallint,text,text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.reveal_exam_prep_hybrid_s4_review_safe_v1(uuid,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.get_exam_prep_hybrid_s4_history_safe_v1(text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_hybrid_s4_papers_safe_v1(text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.start_exam_prep_hybrid_s4_paper_safe_v1(bigint,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_hybrid_s4_session_safe_v1(uuid,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.finish_exam_prep_hybrid_s4_paper_safe_v1(uuid,text,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.check_exam_prep_hybrid_s4_final_safe_v1(uuid,smallint,text,text,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.reveal_exam_prep_hybrid_s4_review_safe_v1(uuid,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.get_exam_prep_hybrid_s4_history_safe_v1(text) TO authenticated,service_role;
COMMIT;
