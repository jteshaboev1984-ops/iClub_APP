-- Companion hardening for the preceding OFF-by-default frozen MCQ order migration.
-- Both migrations require disposable PostgreSQL rehearsal before any production installation.
BEGIN;
SET LOCAL lock_timeout='3s';
DO $preflight$
BEGIN
 IF to_regclass('private.exam_prep_mcq_order_rollout_v1') IS NULL
    OR (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton=true) IS DISTINCT FROM false
    OR (SELECT count(*) FROM private.exam_prep_session_items WHERE display_to_source IS NOT NULL)<>0
 THEN RAISE EXCEPTION 'MCQ mapping hardening: foundation missing or rollout unexpectedly active'; END IF;
END;$preflight$;

-- Protect BOTH private tables introduced by the foundation. There are no browser
-- policies; even accidental future table grants must not expose their rows.
ALTER TABLE private.exam_prep_mcq_order_rollout_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.exam_prep_mcq_order_function_backups_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE private.exam_prep_mcq_order_rollout_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON TABLE private.exam_prep_mcq_order_function_backups_v1 FROM PUBLIC,anon,authenticated;
DO $security$
DECLARE v_bad int;
BEGIN
 SELECT count(*) INTO v_bad FROM pg_tables
 WHERE schemaname='private' AND tablename IN
   ('exam_prep_mcq_order_rollout_v1','exam_prep_mcq_order_function_backups_v1')
 AND rowsecurity IS NOT TRUE;
 IF v_bad<>0 THEN RAISE EXCEPTION 'MCQ hardening: RLS not enabled for both new private tables'; END IF;
 IF EXISTS (
   SELECT 1 FROM information_schema.role_table_grants
   WHERE table_schema='private'
     AND table_name IN ('exam_prep_mcq_order_rollout_v1','exam_prep_mcq_order_function_backups_v1')
     AND grantee IN ('PUBLIC','anon','authenticated')
 ) THEN RAISE EXCEPTION 'MCQ hardening: browser table grants remain'; END IF;
END;$security$;

ALTER TABLE private.exam_prep_session_items DROP CONSTRAINT exam_prep_mcq_order_permutation_v1;
ALTER TABLE private.exam_prep_session_items ADD CONSTRAINT exam_prep_mcq_order_permutation_v1
CHECK (display_to_source IS NULL OR (
 COALESCE(array_ndims(display_to_source)=1,false)
 AND COALESCE(array_lower(display_to_source,1)=1,false)
 AND COALESCE(array_length(display_to_source,1)=4,false)
 AND COALESCE(display_to_source @> ARRAY[0,1,2,3]::smallint[],false)
));
CREATE OR REPLACE FUNCTION private.exam_prep_mcq_display_options_v1(p_options jsonb,p_map smallint[])
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path TO '' AS $fn$
BEGIN
 IF p_map IS NULL THEN RETURN p_options; END IF;
 IF p_options IS NULL OR COALESCE(jsonb_typeof(p_options)<>'array',true)
   OR COALESCE(jsonb_array_length(p_options)<>4,true)
   OR COALESCE(array_ndims(p_map)<>1,true)
   OR COALESCE(array_length(p_map,1)<>4,true)
   OR NOT COALESCE(p_map @> ARRAY[0,1,2,3]::smallint[],false)
 THEN RAISE EXCEPTION 'exam_prep_mcq_order_invalid_options'; END IF;
 RETURN jsonb_build_array(p_options->p_map[1],p_options->p_map[2],p_options->p_map[3],p_options->p_map[4]);
END;$fn$;
CREATE OR REPLACE FUNCTION private.exam_prep_mcq_display_letter_v1(p_selected text,p_map smallint[])
RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path TO '' AS $fn$
DECLARE v_source integer;v_index integer;
BEGIN
 IF p_map IS NULL THEN RETURN p_selected; END IF;
 IF NOT (COALESCE(array_ndims(p_map)=1,false) AND COALESCE(array_length(p_map,1)=4,false)
     AND COALESCE(p_map @> ARRAY[0,1,2,3]::smallint[],false))
 THEN RAISE EXCEPTION 'exam_prep_mcq_order_invalid_map'; END IF;
 IF p_selected IS NULL THEN RETURN NULL; END IF;
 IF length(p_selected)<>1 OR upper(p_selected) NOT IN ('A','B','C','D') THEN
    RAISE EXCEPTION 'exam_prep_mcq_order_invalid_selected_answer'; END IF;
 v_source:=ascii(upper(p_selected))-ascii('A');
 FOR v_index IN 1..4 LOOP
   IF p_map[v_index]=v_source THEN RETURN chr(64+v_index); END IF;
 END LOOP;
 RAISE EXCEPTION 'exam_prep_mcq_order_selected_answer_unmapped';
END;$fn$;
DO $postcheck$
BEGIN
 IF (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton=true) IS DISTINCT FROM false
 THEN RAISE EXCEPTION 'MCQ hardening accidentally enabled rollout'; END IF;
END;$postcheck$;
COMMIT;
