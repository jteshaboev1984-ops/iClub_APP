BEGIN;
SET LOCAL lock_timeout='3s';
SET LOCAL statement_timeout='90s';

DO $preflight$
BEGIN
  IF md5(pg_get_functiondef('public.reset_practice_progress_safe_v4()'::regprocedure))
     <> '97df3ea3875759ea497665bb798f9ab9'
  THEN
    RAISE EXCEPTION 'practice reset archive: reset function drift';
  END IF;
  IF to_regclass('private.practice_reset_archives_v1') IS NOT NULL THEN
    RAISE EXCEPTION 'practice reset archive: table already exists';
  END IF;
END
$preflight$;

CREATE TABLE private.practice_reset_archives_v1 (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  source_function text NOT NULL DEFAULT 'reset_practice_progress_safe_v4',
  practice_sessions jsonb NOT NULL DEFAULT '[]'::jsonb,
  drill_sessions jsonb NOT NULL DEFAULT '[]'::jsonb,
  practice_attempts jsonb NOT NULL DEFAULT '[]'::jsonb,
  practice_answers jsonb NOT NULL DEFAULT '[]'::jsonb,
  counts jsonb NOT NULL,
  payload_md5 text NOT NULL CHECK (payload_md5 ~ '^[0-9a-f]{32}$')
);

CREATE INDEX practice_reset_archives_v1_user_time_idx
  ON private.practice_reset_archives_v1(user_id,created_at DESC);

ALTER TABLE private.practice_reset_archives_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.practice_reset_archives_v1 FROM PUBLIC,anon,authenticated;
GRANT SELECT,INSERT ON TABLE private.practice_reset_archives_v1 TO service_role;
REVOKE ALL ON SEQUENCE private.practice_reset_archives_v1_id_seq FROM PUBLIC,anon,authenticated;
GRANT USAGE,SELECT ON SEQUENCE private.practice_reset_archives_v1_id_seq TO service_role;

CREATE OR REPLACE FUNCTION public.reset_practice_progress_safe_v4()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public','pg_temp'
AS $function$
DECLARE
  v_uid uuid:=auth.uid();
  v_sessions integer:=0;
  v_drills integer:=0;
  v_attempts integer:=0;
  v_answers integer:=0;
  v_archive_id bigint;
  v_sessions_snapshot jsonb:='[]'::jsonb;
  v_drills_snapshot jsonb:='[]'::jsonb;
  v_attempts_snapshot jsonb:='[]'::jsonb;
  v_answers_snapshot jsonb:='[]'::jsonb;
  v_counts jsonb;
  v_payload jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'authentication_required';
  END IF;

  SELECT coalesce(jsonb_agg(to_jsonb(s) ORDER BY s.id),'[]'::jsonb)
  INTO v_sessions_snapshot
  FROM public.practice_sessions_v4 s
  WHERE s.user_id=v_uid;

  SELECT coalesce(jsonb_agg(to_jsonb(d) ORDER BY d.id),'[]'::jsonb)
  INTO v_drills_snapshot
  FROM public.practice_drill_sessions_v4 d
  WHERE d.user_id=v_uid;

  SELECT coalesce(jsonb_agg(to_jsonb(a) ORDER BY a.id),'[]'::jsonb)
  INTO v_attempts_snapshot
  FROM public.practice_attempts a
  WHERE a.user_id=v_uid
    AND coalesce(a.is_lab,false)=false;

  SELECT coalesce(jsonb_agg(to_jsonb(pa) ORDER BY pa.id),'[]'::jsonb)
  INTO v_answers_snapshot
  FROM public.practice_answers pa
  JOIN public.practice_attempts a ON a.id=pa.attempt_id
  WHERE a.user_id=v_uid
    AND coalesce(a.is_lab,false)=false;

  v_sessions:=jsonb_array_length(v_sessions_snapshot);
  v_drills:=jsonb_array_length(v_drills_snapshot);
  v_attempts:=jsonb_array_length(v_attempts_snapshot);
  v_answers:=jsonb_array_length(v_answers_snapshot);

  v_counts:=jsonb_build_object(
    'practice_sessions',v_sessions,
    'drill_sessions',v_drills,
    'practice_attempts',v_attempts,
    'practice_answers',v_answers
  );

  v_payload:=jsonb_build_object(
    'practice_sessions',v_sessions_snapshot,
    'drill_sessions',v_drills_snapshot,
    'practice_attempts',v_attempts_snapshot,
    'practice_answers',v_answers_snapshot,
    'counts',v_counts
  );

  INSERT INTO private.practice_reset_archives_v1(
    user_id,practice_sessions,drill_sessions,practice_attempts,practice_answers,counts,payload_md5
  )
  VALUES(
    v_uid,v_sessions_snapshot,v_drills_snapshot,v_attempts_snapshot,v_answers_snapshot,v_counts,md5(v_payload::text)
  )
  RETURNING id INTO v_archive_id;

  DELETE FROM public.practice_drill_sessions_v4
  WHERE user_id=v_uid;

  DELETE FROM public.practice_sessions_v4
  WHERE user_id=v_uid;

  DELETE FROM public.practice_attempts
  WHERE user_id=v_uid
    AND coalesce(is_lab,false)=false;

  RETURN jsonb_build_object(
    'ok',true,
    'reset_archive_id',v_archive_id,
    'deleted_practice_sessions',v_sessions,
    'deleted_drill_sessions',v_drills,
    'deleted_practice_attempts',v_attempts,
    'archived_practice_answers',v_answers
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.reset_practice_progress_safe_v4() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.reset_practice_progress_safe_v4() TO authenticated,service_role;

DO $postcheck$
DECLARE
  v_bad integer;
BEGIN
  SELECT count(*) INTO v_bad
  FROM pg_tables
  WHERE schemaname='private'
    AND tablename='practice_reset_archives_v1'
    AND rowsecurity IS NOT TRUE;
  IF v_bad<>0 THEN
    RAISE EXCEPTION 'practice reset archive: RLS not enabled';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.role_table_grants
    WHERE table_schema='private'
      AND table_name='practice_reset_archives_v1'
      AND grantee IN ('PUBLIC','anon','authenticated')
  ) THEN
    RAISE EXCEPTION 'practice reset archive: browser grant detected';
  END IF;

  IF position('practice_reset_archives_v1' in pg_get_functiondef('public.reset_practice_progress_safe_v4()'::regprocedure))=0 THEN
    RAISE EXCEPTION 'practice reset archive: reset function did not bind archive';
  END IF;
END
$postcheck$;

COMMIT;
