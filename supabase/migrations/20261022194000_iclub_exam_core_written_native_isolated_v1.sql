-- Universal Exam Prep written Core: isolated native storage, NO learner activation.
-- All tables remain private, with RLS on and no anon/authenticated grants.
-- This migration does not modify any existing Mathematics/Practice/Tours tables.
CREATE TABLE IF NOT EXISTS private.iclub_exam_core_written_tasks_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  paper_code text NOT NULL,
  task_key text NOT NULL CHECK (length(task_key) BETWEEN 3 AND 120),
  task_version text NOT NULL CHECK (length(task_version) BETWEEN 1 AND 120),
  questions jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(questions)='object'),
  answer_requirements jsonb NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(answer_requirements)='object'),
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','review','approved','retired')),
  academic_review text NOT NULL DEFAULT 'pending' CHECK (academic_review IN ('pending','approved','rejected')),
  language_review text NOT NULL DEFAULT 'pending' CHECK (language_review IN ('pending','approved','rejected')),
  source_review text NOT NULL DEFAULT 'pending' CHECK (source_review IN ('pending','approved','rejected')),
  release_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key,task_key,task_version),
  FOREIGN KEY (program_key,version_key,paper_code)
    REFERENCES private.iclub_exam_core_papers_v1(program_key,version_key,paper_code)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK (NOT release_enabled OR
    (status='approved' AND academic_review='approved'
      AND language_review='approved' AND source_review='approved'
      AND questions ?& ARRAY['ru','uz','en']
      AND answer_requirements ?& ARRAY['ru','uz','en']))
);
CREATE TABLE IF NOT EXISTS private.iclub_exam_core_written_access_v1 (
  learner_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  program_key text NOT NULL,
  version_key text NOT NULL,
  core_access boolean NOT NULL DEFAULT false,
  status text NOT NULL DEFAULT 'inactive' CHECK (status IN ('inactive','active','revoked')),
  valid_from timestamptz,
  valid_until timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (learner_user_id,program_key,version_key),
  FOREIGN KEY (program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK (valid_until IS NULL OR valid_from IS NULL OR valid_until > valid_from)
);
CREATE TABLE IF NOT EXISTS private.iclub_exam_core_written_plans_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  learner_user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE RESTRICT,
  program_key text NOT NULL,
  version_key text NOT NULL,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','completed','archived')),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (id,learner_user_id,program_key,version_key),
  FOREIGN KEY (program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);
CREATE TABLE IF NOT EXISTS private.iclub_exam_core_written_plan_items_v1 (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL,
  learner_user_id uuid NOT NULL,
  program_key text NOT NULL,
  version_key text NOT NULL,
  task_key text NOT NULL,
  task_version text NOT NULL,
  priority_order integer NOT NULL CHECK (priority_order BETWEEN 1 AND 1000),
  task_token uuid NOT NULL DEFAULT gen_random_uuid(),
  mode text NOT NULL DEFAULT 'practice' CHECK (mode IN ('practice','timed')),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','advanced')),
  opened_at timestamptz,
  advanced_at timestamptz,
  advance_nonce text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (plan_id,priority_order),
  UNIQUE (task_token),
  FOREIGN KEY (plan_id,learner_user_id,program_key,version_key)
    REFERENCES private.iclub_exam_core_written_plans_v1(id,learner_user_id,program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY (program_key,version_key,task_key,task_version)
    REFERENCES private.iclub_exam_core_written_tasks_v1(program_key,version_key,task_key,task_version)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK ((status='pending' AND advanced_at IS NULL AND advance_nonce IS NULL)
    OR (status='advanced' AND advanced_at IS NOT NULL AND advance_nonce IS NOT NULL)),
  CHECK (advance_nonce IS NULL OR length(advance_nonce) BETWEEN 8 AND 120)
);
CREATE UNIQUE INDEX IF NOT EXISTS iclub_exam_written_nonce_once_v1
  ON private.iclub_exam_core_written_plan_items_v1(learner_user_id,advance_nonce)
  WHERE advance_nonce IS NOT NULL;
CREATE INDEX IF NOT EXISTS iclub_exam_written_plan_items_scan_v1
  ON private.iclub_exam_core_written_plan_items_v1(plan_id,priority_order,status);

ALTER TABLE private.iclub_exam_core_written_tasks_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_written_access_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_written_plans_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_core_written_plan_items_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.iclub_exam_core_written_tasks_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON TABLE private.iclub_exam_core_written_access_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON TABLE private.iclub_exam_core_written_plans_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON TABLE private.iclub_exam_core_written_plan_items_v1 FROM PUBLIC,anon,authenticated;

-- Closed internal advancement: only service_role can call this function until
-- a separately reviewed learner-facing wrapper is added. Release requires an
-- active native program, approved task, authenticated learner and assigned plan.
CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_advance_v1(
  p_item_id uuid,
  p_task_key text,
  p_task_version text,
  p_task_token uuid,
  p_idempotency_key text
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = ''
AS $function$
DECLARE
  v_user uuid := auth.uid();
  v_status text;
BEGIN
  IF v_user IS NULL THEN
    RAISE EXCEPTION 'written_access_denied' USING ERRCODE='42501';
  END IF;
  IF p_item_id IS NULL OR p_task_token IS NULL
    OR p_task_key IS NULL OR p_task_version IS NULL
    OR p_idempotency_key IS NULL
    OR length(btrim(p_idempotency_key)) < 8
    OR length(p_idempotency_key) > 120 THEN
    RAISE EXCEPTION 'written_request_invalid' USING ERRCODE='22023';
  END IF;

  SELECT i.status INTO v_status
  FROM private.iclub_exam_core_written_plan_items_v1 i
  JOIN private.iclub_exam_core_written_plans_v1 pl
    ON pl.id=i.plan_id AND pl.learner_user_id=i.learner_user_id
      AND pl.program_key=i.program_key AND pl.version_key=i.version_key
  JOIN private.iclub_exam_core_programs_v1 pg
    ON pg.program_key=i.program_key AND pg.version_key=i.version_key
  JOIN private.iclub_exam_core_written_tasks_v1 t
    ON t.program_key=i.program_key AND t.version_key=i.version_key
      AND t.task_key=i.task_key AND t.task_version=i.task_version
  JOIN private.iclub_exam_core_written_access_v1 ac
    ON ac.learner_user_id=i.learner_user_id
      AND ac.program_key=i.program_key AND ac.version_key=i.version_key
  WHERE i.id=p_item_id AND i.learner_user_id=v_user
    AND i.task_key=p_task_key AND i.task_version=p_task_version
    AND i.task_token=p_task_token
    AND i.mode='practice'
    AND pl.status='active'
    AND pg.integration_mode='native'
    AND pg.status='published' AND pg.launch_enabled=true
    AND t.status='approved' AND t.release_enabled=true
    AND t.academic_review='approved' AND t.language_review='approved'
    AND t.source_review='approved'
    AND ac.status='active' AND ac.core_access=true
    AND (ac.valid_from IS NULL OR ac.valid_from<=now())
    AND (ac.valid_until IS NULL OR ac.valid_until>now())
  FOR UPDATE OF i;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'written_item_not_available' USING ERRCODE='42501';
  END IF;

  IF v_status='advanced' THEN
    RETURN jsonb_build_object(
      'status','advanced','plan_item_id',p_item_id::text,
      'task_key',p_task_key,'task_version',p_task_version,
      'replayed',true);
  END IF;

  IF EXISTS (
    SELECT 1 FROM private.iclub_exam_core_written_plan_items_v1 i2
    WHERE i2.learner_user_id=v_user
      AND i2.advance_nonce=p_idempotency_key AND i2.id<>p_item_id
  ) THEN
    RAISE EXCEPTION 'written_idempotency_conflict' USING ERRCODE='23505';
  END IF;

  UPDATE private.iclub_exam_core_written_plan_items_v1
  SET status='advanced',advanced_at=now(),advance_nonce=p_idempotency_key
  WHERE id=p_item_id AND status='pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'written_advance_conflict' USING ERRCODE='40001';
  END IF;

  RETURN jsonb_build_object(
    'status','advanced','plan_item_id',p_item_id::text,
    'task_key',p_task_key,'task_version',p_task_version,
    'replayed',false);
END;
$function$;
REVOKE ALL ON FUNCTION private.iclub_exam_core_written_advance_v1(uuid,text,text,uuid,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_written_advance_v1(uuid,text,text,uuid,text)
  TO service_role;
