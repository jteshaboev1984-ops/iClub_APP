-- Mathematics P1/P5 Extra Hard v1: PRIVATE, OPTIONAL, NONCREDIT.
-- DRAFT ONLY: protected task table starts EMPTY; earlier lost draft tasks were
-- replaced by newly authored 12 on 2026-11-06. The v2 migration updates only
-- the bank version metadata, never private question contents or learner history.
-- Without explicit release control + academic approval + content checksum,
-- no authenticated learner receives task prompts or protected solution keys.
-- No shared public.questions, existing Paper/diagnostic reserve or mastery writes.
-- No production execution authorized by this draft PR / source migration.
BEGIN;

CREATE TABLE IF NOT EXISTS private.exam_prep_extra_hard_release_v1 (
 program_key text PRIMARY KEY,
 bank_version text NOT NULL,
 enabled boolean NOT NULL DEFAULT false,
 academic_approved boolean NOT NULL DEFAULT false,
 updated_at timestamptz NOT NULL DEFAULT now(),
 CHECK (NOT enabled OR academic_approved)
);
REVOKE ALL ON private.exam_prep_extra_hard_release_v1 FROM PUBLIC,anon,authenticated;
GRANT ALL ON private.exam_prep_extra_hard_release_v1 TO service_role;
ALTER TABLE private.exam_prep_extra_hard_release_v1 ENABLE ROW LEVEL SECURITY;

INSERT INTO private.exam_prep_extra_hard_release_v1(program_key,bank_version,enabled,academic_approved)
VALUES ('math_as_p1_p5','secure-bank-v1-pending',false,false)
ON CONFLICT (program_key) DO NOTHING;

CREATE TABLE IF NOT EXISTS private.exam_prep_extra_hard_tasks_v1 (
 task_key text PRIMARY KEY,
 program_version_id bigint NOT NULL REFERENCES private.exam_prep_program_versions(id),
 bank_version text NOT NULL,
 component_code text NOT NULL CHECK(component_code IN ('P1','P5')),
 primary_skill_code text NOT NULL,
 official_section text NOT NULL,
 book_map text NOT NULL,
 title_i18n jsonb NOT NULL,
 prompt_i18n jsonb NOT NULL,
 solution_i18n jsonb NOT NULL,
 exact_answer text NOT NULL,
 source_kind text NOT NULL DEFAULT 'iclub_original' CHECK(source_kind='iclub_original'),
 qa_math text NOT NULL DEFAULT 'pending' CHECK(qa_math IN ('pending','approved')),
 qa_languages text NOT NULL DEFAULT 'pending' CHECK(qa_languages IN ('pending','approved')),
 qa_technical text NOT NULL DEFAULT 'pending' CHECK(qa_technical IN ('pending','approved')),
 lifecycle_status text NOT NULL DEFAULT 'draft' CHECK(lifecycle_status IN ('draft','approved','published','retired')),
 content_sha256 text NULL CHECK(content_sha256 IS NULL OR content_sha256 ~ '^[0-9a-f]{64}$'),
 created_at timestamptz NOT NULL DEFAULT now(),
 published_at timestamptz NULL,
 CHECK (jsonb_typeof(title_i18n)='object' AND jsonb_typeof(prompt_i18n)='object' AND jsonb_typeof(solution_i18n)='object'),
 CHECK (lifecycle_status <> 'published' OR
   (qa_math='approved' AND qa_languages='approved' AND qa_technical='approved'
    AND content_sha256 IS NOT NULL AND published_at IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS exam_prep_extra_hard_tasks_published_v1_idx
ON private.exam_prep_extra_hard_tasks_v1(program_version_id,component_code)
WHERE lifecycle_status='published';
REVOKE ALL ON private.exam_prep_extra_hard_tasks_v1 FROM PUBLIC,anon,authenticated;
GRANT ALL ON private.exam_prep_extra_hard_tasks_v1 TO service_role;
ALTER TABLE private.exam_prep_extra_hard_tasks_v1 ENABLE ROW LEVEL SECURITY;

-- Immutable after publish: future corrections must create new versioned keys.
CREATE OR REPLACE FUNCTION private.exam_prep_extra_hard_immutable_v1()
RETURNS trigger LANGUAGE plpgsql SET search_path TO '' AS $$
BEGIN
 IF OLD.lifecycle_status='published' AND (
  NEW.prompt_i18n IS DISTINCT FROM OLD.prompt_i18n OR
  NEW.solution_i18n IS DISTINCT FROM OLD.solution_i18n OR
  NEW.title_i18n IS DISTINCT FROM OLD.title_i18n OR
  NEW.exact_answer IS DISTINCT FROM OLD.exact_answer OR
  NEW.content_sha256 IS DISTINCT FROM OLD.content_sha256 OR
  NEW.primary_skill_code IS DISTINCT FROM OLD.primary_skill_code
 ) THEN
  RAISE EXCEPTION 'exam_prep_extra_hard_published_content_immutable' USING ERRCODE='42501';
 END IF;
 RETURN NEW;
END;
$$;
REVOKE ALL ON FUNCTION private.exam_prep_extra_hard_immutable_v1() FROM PUBLIC,anon,authenticated;
DO $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM pg_trigger
               WHERE tgrelid='private.exam_prep_extra_hard_tasks_v1'::regclass
                 AND tgname='exam_prep_extra_hard_content_lock_v1') THEN
  CREATE TRIGGER exam_prep_extra_hard_content_lock_v1
  BEFORE UPDATE ON private.exam_prep_extra_hard_tasks_v1
  FOR EACH ROW EXECUTE FUNCTION private.exam_prep_extra_hard_immutable_v1();
 END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS private.exam_prep_extra_hard_attempts_v1 (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 user_id uuid NOT NULL REFERENCES auth.users(id),
 task_key text NOT NULL REFERENCES private.exam_prep_extra_hard_tasks_v1(task_key),
 status text NOT NULL DEFAULT 'started' CHECK(status IN ('started','submitted')),
 response_text text NULL CHECK(response_text IS NULL OR char_length(response_text) BETWEEN 1 AND 10000),
 submit_idempotency_key text NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 submitted_at timestamptz NULL,
 UNIQUE(user_id,task_key),
 CHECK ((status='started' AND submitted_at IS NULL AND response_text IS NULL)
        OR (status='submitted' AND submitted_at IS NOT NULL AND response_text IS NOT NULL AND submit_idempotency_key IS NOT NULL))
);
CREATE INDEX IF NOT EXISTS exam_prep_extra_hard_attempts_owner_v1_idx
 ON private.exam_prep_extra_hard_attempts_v1(user_id,created_at DESC);
REVOKE ALL ON private.exam_prep_extra_hard_attempts_v1 FROM PUBLIC,anon,authenticated;
GRANT ALL ON private.exam_prep_extra_hard_attempts_v1 TO service_role;
ALTER TABLE private.exam_prep_extra_hard_attempts_v1 ENABLE ROW LEVEL SECURITY;

-- PUBLIC REPO: NO original question bank or worked solutions committed.
-- Author, academically review and ingest protected items through a PRIVATE
-- controlled DB import after explicit approval; never reuse the public examples.

-- All four public endpoints require the existing Math Core authorization.
-- No RPC changes base exam_prep_sessions, skill_states, stages or credits.
CREATE OR REPLACE FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(
 p_component_code text,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
 v_uid uuid;
 v_program bigint;
 v_control private.exam_prep_extra_hard_release_v1%ROWTYPE;
 v_items jsonb:='[]'::jsonb;
 v_lang text:=lower(coalesce(p_language,'en'));
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF p_component_code NOT IN ('P1','P5') OR v_lang NOT IN ('en','ru','uz')
 THEN RAISE EXCEPTION 'exam_prep_extra_hard_bad_component_or_language' USING ERRCODE='22023'; END IF;
 SELECT id INTO v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active' ORDER BY id DESC LIMIT 1;
 SELECT * INTO v_control FROM private.exam_prep_extra_hard_release_v1
 WHERE program_key='math_as_p1_p5';
 IF v_program IS NULL OR NOT coalesce(v_control.enabled,false)
     OR NOT coalesce(v_control.academic_approved,false) THEN
  RETURN jsonb_build_object('available',false,'component_code',p_component_code,
    'items','[]'::jsonb,'reason_code','content_preparing','noncredit',true);
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object(
  'task_key',t.task_key,'title',t.title_i18n->>v_lang,
  'primary_skill_code',t.primary_skill_code,'noncredit',true
 ) ORDER BY t.task_key),'[]'::jsonb) INTO v_items
 FROM private.exam_prep_extra_hard_tasks_v1 t
 WHERE t.program_version_id=v_program AND t.component_code=p_component_code
 AND t.bank_version=v_control.bank_version AND t.lifecycle_status='published'
 AND t.qa_math='approved' AND t.qa_languages='approved'
 AND t.qa_technical='approved' AND t.content_sha256 IS NOT NULL;
 RETURN jsonb_build_object('available',jsonb_array_length(v_items)>0,
   'component_code',p_component_code,'items',v_items,'noncredit',true,
   'reason_code',CASE WHEN jsonb_array_length(v_items)>0 THEN 'ready' ELSE 'content_preparing' END);
END;
$$;

CREATE OR REPLACE FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(
 p_task_key text,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
 v_uid uuid;
 v_program bigint;
 v_lang text:=lower(coalesce(p_language,'en'));
 v_task private.exam_prep_extra_hard_tasks_v1%ROWTYPE;
 v_attempt private.exam_prep_extra_hard_attempts_v1%ROWTYPE;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF v_lang NOT IN ('en','ru','uz') THEN
  RAISE EXCEPTION 'exam_prep_extra_hard_bad_language' USING ERRCODE='22023'; END IF;
 SELECT id INTO v_program FROM private.exam_prep_program_versions
 WHERE program_key='math_as_p1_p5' AND status='active' ORDER BY id DESC LIMIT 1;
 SELECT t.* INTO v_task FROM private.exam_prep_extra_hard_tasks_v1 t
 JOIN private.exam_prep_extra_hard_release_v1 r ON r.program_key='math_as_p1_p5'
 WHERE t.task_key=p_task_key AND t.program_version_id=v_program
 AND t.bank_version=r.bank_version AND r.enabled AND r.academic_approved
 AND t.lifecycle_status='published' AND t.qa_math='approved'
 AND t.qa_languages='approved' AND t.qa_technical='approved'
 AND t.content_sha256 IS NOT NULL;
 IF v_task.task_key IS NULL THEN RAISE EXCEPTION 'exam_prep_extra_hard_unavailable' USING ERRCODE='42501'; END IF;
 INSERT INTO private.exam_prep_extra_hard_attempts_v1(user_id,task_key)
 VALUES(v_uid,v_task.task_key)
 ON CONFLICT(user_id,task_key) DO NOTHING;
 SELECT * INTO v_attempt FROM private.exam_prep_extra_hard_attempts_v1
 WHERE user_id=v_uid AND task_key=v_task.task_key;
 RETURN jsonb_build_object('attempt_id',v_attempt.id,'status',v_attempt.status,
  'component_code',v_task.component_code,'prompt',v_task.prompt_i18n->>v_lang,
  'title',v_task.title_i18n->>v_lang,'response_text',v_attempt.response_text,
  'solution',CASE WHEN v_attempt.status='submitted' THEN v_task.solution_i18n->>v_lang ELSE null END,
  'written_correctness','unknown','noncredit',true);
END;
$$;

CREATE OR REPLACE FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(
 p_attempt_id uuid,p_response_text text,p_idempotency_key text,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
 v_uid uuid;
 v_lang text:=lower(coalesce(p_language,'en'));
 v_answer text:=nullif(btrim(coalesce(p_response_text,'')),'');
 v_attempt private.exam_prep_extra_hard_attempts_v1%ROWTYPE;
 v_task private.exam_prep_extra_hard_tasks_v1%ROWTYPE;
 v_gate private.exam_prep_extra_hard_release_v1%ROWTYPE;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF v_lang NOT IN ('en','ru','uz') OR v_answer IS NULL OR char_length(v_answer)>10000
  OR char_length(coalesce(p_idempotency_key,'')) NOT BETWEEN 12 AND 150
 THEN RAISE EXCEPTION 'exam_prep_extra_hard_invalid_submission' USING ERRCODE='22023'; END IF;
 SELECT * INTO v_attempt FROM private.exam_prep_extra_hard_attempts_v1
 WHERE id=p_attempt_id AND user_id=v_uid FOR UPDATE;
 IF v_attempt.id IS NULL THEN RAISE EXCEPTION 'exam_prep_extra_hard_attempt_not_found' USING ERRCODE='P0002'; END IF;
 SELECT * INTO v_task FROM private.exam_prep_extra_hard_tasks_v1 WHERE task_key=v_attempt.task_key;
 SELECT * INTO v_gate FROM private.exam_prep_extra_hard_release_v1 WHERE program_key='math_as_p1_p5';
 IF NOT coalesce(v_gate.enabled,false) OR NOT coalesce(v_gate.academic_approved,false)
  OR v_task.lifecycle_status<>'published' OR v_task.bank_version<>v_gate.bank_version THEN
  RAISE EXCEPTION 'exam_prep_extra_hard_unavailable' USING ERRCODE='42501'; END IF;
 IF v_attempt.status='submitted' THEN
  IF v_attempt.submit_idempotency_key IS DISTINCT FROM p_idempotency_key
   THEN RAISE EXCEPTION 'exam_prep_extra_hard_already_submitted' USING ERRCODE='23505'; END IF;
  RETURN jsonb_build_object('attempt_id',v_attempt.id,'saved',true,'replayed',true,
    'response_text',v_attempt.response_text,'solution',v_task.solution_i18n->>v_lang,
    'written_correctness','unknown','noncredit',true);
 END IF;
 UPDATE private.exam_prep_extra_hard_attempts_v1
 SET response_text=v_answer,submit_idempotency_key=p_idempotency_key,
     submitted_at=now(),status='submitted'
 WHERE id=v_attempt.id AND user_id=v_uid AND status='started';
 RETURN jsonb_build_object('attempt_id',v_attempt.id,'saved',true,'replayed',false,
   'response_text',v_answer,'solution',v_task.solution_i18n->>v_lang,
   'written_correctness','unknown','noncredit',true);
END;
$$;

CREATE OR REPLACE FUNCTION public.get_my_exam_prep_extra_hard_attempt_safe_v1(
 p_attempt_id uuid,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO '' AS $$
DECLARE
 v_uid uuid;
 v_lang text:=lower(coalesce(p_language,'en'));
 v_attempt private.exam_prep_extra_hard_attempts_v1%ROWTYPE;
 v_task private.exam_prep_extra_hard_tasks_v1%ROWTYPE;
BEGIN
 v_uid:=private.exam_prep_require_core_access_v1();
 IF v_lang NOT IN ('en','ru','uz') THEN RAISE EXCEPTION 'exam_prep_extra_hard_bad_language' USING ERRCODE='22023'; END IF;
 SELECT * INTO v_attempt FROM private.exam_prep_extra_hard_attempts_v1
 WHERE id=p_attempt_id AND user_id=v_uid;
 IF v_attempt.id IS NULL THEN RAISE EXCEPTION 'exam_prep_extra_hard_attempt_not_found' USING ERRCODE='P0002'; END IF;
 SELECT * INTO v_task FROM private.exam_prep_extra_hard_tasks_v1 WHERE task_key=v_attempt.task_key;
 RETURN jsonb_build_object('attempt_id',v_attempt.id,'status',v_attempt.status,
  'title',v_task.title_i18n->>v_lang,'prompt',v_task.prompt_i18n->>v_lang,
  'response_text',v_attempt.response_text,
  'solution',CASE WHEN v_attempt.status='submitted' THEN v_task.solution_i18n->>v_lang ELSE null END,
  'written_correctness','unknown','noncredit',true);
END;
$$;

-- Default PUBLIC EXECUTE on SECURITY DEFINER routines is explicitly removed.
REVOKE ALL ON FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text) FROM PUBLIC,anon;
REVOKE ALL ON FUNCTION public.get_my_exam_prep_extra_hard_attempt_safe_v1(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_extra_hard_catalog_safe_v1(text,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.start_my_exam_prep_extra_hard_safe_v1(text,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.submit_my_exam_prep_extra_hard_safe_v1(uuid,text,text,text) TO authenticated,service_role;
GRANT EXECUTE ON FUNCTION public.get_my_exam_prep_extra_hard_attempt_safe_v1(uuid,text) TO authenticated,service_role;
COMMIT;
