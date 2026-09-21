-- DRAFT / DO NOT APPLY TO LIVE WITHOUT SEPARATE OWNER APPROVAL AND FULL DISPOSABLE PG17 TEST.
-- Server-owned per-session option permutation for P1 and P5. Old sessions retain NULL=identity.
-- NO client-only shuffle, old response rewrite, student deletion, or feature enablement here.
BEGIN;
SET LOCAL lock_timeout = '3s';
SET LOCAL statement_timeout = '90s';

DO $preflight$
BEGIN
  IF md5(pg_get_functiondef('public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure))<>'3af64460b1b77a8d2dc92b74ff8ffd64'
   OR md5(pg_get_functiondef('public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)'::regprocedure))<>'7f45d186beef533069012b96ffce24dd'
   OR md5(pg_get_functiondef('private.exam_prep_safe_response_payload_v1(uuid,text,boolean)'::regprocedure))<>'294961996fb3ef9acb572bed4fd76349'
  THEN RAISE EXCEPTION 'Exam Prep MCQ mapping: original function definition drift; refuse installation'; END IF;
  IF to_regclass('private.exam_prep_mcq_order_rollout_v1') IS NOT NULL
    OR EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema='private' AND table_name='exam_prep_session_items' AND column_name='display_to_source')
  THEN RAISE EXCEPTION 'Exam Prep MCQ mapping: already installed, refuse replay'; END IF;
  IF (SELECT count(DISTINCT q.id) FROM private.exam_prep_assessments a
      JOIN private.exam_prep_assessment_items ai ON ai.assessment_id=a.id
      JOIN public.questions q ON q.id=ai.question_id
      WHERE a.status='published' AND q.qtype='mcq'
        AND (q.correct_answer NOT IN ('A','B','C','D') OR q.options_text_en IS NULL OR q.options_text_ru IS NULL OR q.options_text_uz IS NULL))>0
  THEN RAISE EXCEPTION 'Exam Prep MCQ mapping: invalid published MCQ baseline'; END IF;
END;$preflight$;

CREATE TABLE private.exam_prep_mcq_order_rollout_v1 (
  singleton boolean PRIMARY KEY DEFAULT true CHECK(singleton),
  enabled boolean NOT NULL DEFAULT false,
  enabled_at timestamptz,
  CONSTRAINT mcq_rollout_time_consistency CHECK (enabled=false OR enabled_at IS NOT NULL)
);
INSERT INTO private.exam_prep_mcq_order_rollout_v1(singleton,enabled) VALUES(true,false);
REVOKE ALL ON private.exam_prep_mcq_order_rollout_v1 FROM PUBLIC,anon,authenticated;

CREATE TABLE private.exam_prep_mcq_order_function_backups_v1 (
  signature text PRIMARY KEY,
  definition text NOT NULL,
  definition_md5 text NOT NULL,
  captured_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO private.exam_prep_mcq_order_function_backups_v1(signature,definition,definition_md5)
SELECT p.oid::regprocedure::text, pg_get_functiondef(p.oid), md5(pg_get_functiondef(p.oid))
FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
WHERE (n.nspname='public' AND p.proname IN ('get_exam_prep_session_safe_v1','submit_exam_prep_response_safe_v1'))
   OR (n.nspname='private' AND p.proname='exam_prep_safe_response_payload_v1');
DO $backup$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_mcq_order_function_backups_v1)<>3 THEN
    RAISE EXCEPTION 'MCQ pre-change function backup incomplete'; END IF;
END;$backup$;
REVOKE ALL ON private.exam_prep_mcq_order_function_backups_v1 FROM PUBLIC,anon,authenticated;

ALTER TABLE private.exam_prep_session_items ADD COLUMN display_to_source smallint[] NULL;
ALTER TABLE private.exam_prep_session_items ADD CONSTRAINT exam_prep_mcq_order_permutation_v1
CHECK (display_to_source IS NULL OR (
 array_ndims(display_to_source)=1 AND array_lower(display_to_source,1)=1
 AND array_length(display_to_source,1)=4
 AND display_to_source @> ARRAY[0,1,2,3]::smallint[]
));

CREATE FUNCTION private.exam_prep_mcq_display_options_v1(p_options jsonb,p_map smallint[])
RETURNS jsonb LANGUAGE plpgsql IMMUTABLE SET search_path TO '' AS $fn$
BEGIN
 IF p_map IS NULL THEN RETURN p_options; END IF;
 IF p_options IS NULL OR jsonb_typeof(p_options)<>'array' OR jsonb_array_length(p_options)<>4
   OR array_length(p_map,1)<>4 OR NOT (p_map @> ARRAY[0,1,2,3]::smallint[])
 THEN RAISE EXCEPTION 'exam_prep_mcq_order_invalid_options'; END IF;
 RETURN jsonb_build_array(p_options->p_map[1],p_options->p_map[2],p_options->p_map[3],p_options->p_map[4]);
END;$fn$;

CREATE FUNCTION private.exam_prep_mcq_display_letter_v1(p_selected text,p_map smallint[])
RETURNS text LANGUAGE plpgsql IMMUTABLE SET search_path TO '' AS $fn$
DECLARE v_source integer;v_index integer;
BEGIN
 IF p_map IS NULL OR p_selected IS NULL THEN RETURN p_selected; END IF;
 IF length(p_selected)<>1 OR upper(p_selected) NOT IN ('A','B','C','D') THEN
    RAISE EXCEPTION 'exam_prep_mcq_order_invalid_selected_answer'; END IF;
 v_source:=ascii(upper(p_selected))-ascii('A');
 FOR v_index IN 1..4 LOOP
   IF p_map[v_index]=v_source THEN RETURN chr(64+v_index); END IF;
 END LOOP;
 RAISE EXCEPTION 'exam_prep_mcq_order_selected_answer_unmapped';
END;$fn$;
REVOKE ALL ON FUNCTION private.exam_prep_mcq_display_options_v1(jsonb,smallint[]) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION private.exam_prep_mcq_display_letter_v1(text,smallint[]) FROM PUBLIC,anon,authenticated;

CREATE FUNCTION private.exam_prep_mcq_frozen_order_insert_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO '' AS $fn$
DECLARE v_enabled boolean;v_q public.questions%rowtype;v_perm smallint[];
BEGIN
 SELECT enabled INTO v_enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton=true;
 IF NOT coalesce(v_enabled,false) OR NEW.item_kind<>'question' THEN RETURN NEW; END IF;
 SELECT * INTO v_q FROM public.questions WHERE id=NEW.question_id;
 IF v_q.id IS NULL THEN RAISE EXCEPTION 'exam_prep_mcq_missing_source'; END IF;
 IF v_q.qtype<>'mcq' THEN RETURN NEW; END IF;
 IF NEW.display_to_source IS NOT NULL OR
    jsonb_typeof(v_q.options_text_en::jsonb)<>'array' OR jsonb_array_length(v_q.options_text_en::jsonb)<>4 OR
    jsonb_typeof(v_q.options_text_ru::jsonb)<>'array' OR jsonb_array_length(v_q.options_text_ru::jsonb)<>4 OR
    jsonb_typeof(v_q.options_text_uz::jsonb)<>'array' OR jsonb_array_length(v_q.options_text_uz::jsonb)<>4
 THEN RAISE EXCEPTION 'exam_prep_mcq_order_invalid_source_options'; END IF;
 SELECT array_agg(n::smallint ORDER BY pg_catalog.gen_random_uuid()) INTO v_perm
 FROM pg_catalog.generate_series(0,3) AS n;
 NEW.display_to_source:=v_perm;
 RETURN NEW;
END;$fn$;
REVOKE ALL ON FUNCTION private.exam_prep_mcq_frozen_order_insert_v1() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER exam_prep_mcq_frozen_order_insert_v1
BEFORE INSERT ON private.exam_prep_session_items FOR EACH ROW
EXECUTE FUNCTION private.exam_prep_mcq_frozen_order_insert_v1();

-- Modify the THREE current server functions atomically. Never trust an unpinned regex over live SQL.
-- Functions remain identity-compatible while rollout.enabled=false; old frozen items have NULL map forever.
DO $rewrite$
DECLARE v_src text;v_old text;v_new text;v_sig regprocedure;
BEGIN
 v_sig:='public.get_exam_prep_session_safe_v1(uuid,text)'::regprocedure;
 v_src:=pg_get_functiondef(v_sig);
 v_old:='''selected_answer'',r.selected_answer,';
 v_new:='''selected_answer'',private.exam_prep_mcq_display_letter_v1(r.selected_answer,si.display_to_source),';
 IF (length(v_src)-length(replace(v_src,v_old,'')))<>length(v_old) THEN
   RAISE EXCEPTION 'get-session selected_answer anchor mismatch'; END IF;
 v_src:=replace(v_src,v_old,v_new);
 v_old:='coalesce(nullif(case v_lang when ''ru'' then q.options_text_ru when ''uz'' then q.options_text_uz else q.options_text_en end,''''),''[]'')::jsonb else null end,';
 v_new:='private.exam_prep_mcq_display_options_v1(coalesce(nullif(case v_lang when ''ru'' then q.options_text_ru when ''uz'' then q.options_text_uz else q.options_text_en end,''''),''[]'')::jsonb,si.display_to_source) else null end,';
 IF (length(v_src)-length(replace(v_src,v_old,'')))<>length(v_old) THEN
   RAISE EXCEPTION 'get-session localized options anchor mismatch'; END IF;
 EXECUTE replace(v_src,v_old,v_new);

 v_sig:='public.submit_exam_prep_response_safe_v1(uuid,integer,jsonb,text,integer,text)'::regprocedure;
 v_src:=pg_get_functiondef(v_sig);
 v_old:='v_eval:=private.exam_prep_eval_session_question_v1(v_s.id,v_i.item_order,v_answer,v_picked);';
 v_new:='IF v_i.display_to_source IS NOT NULL THEN
      IF v_picked IS NULL OR v_picked NOT BETWEEN 0 AND 3 OR nullif(btrim(coalesce(v_answer,'''') ),'''') IS NOT NULL THEN
        RAISE EXCEPTION ''exam_prep_mcq_display_index_required'';
      END IF;
      v_picked:=v_i.display_to_source[v_picked+1];
    END IF;
    v_eval:=private.exam_prep_eval_session_question_v1(v_s.id,v_i.item_order,v_answer,v_picked);';
 IF (length(v_src)-length(replace(v_src,v_old,'')))<>length(v_old) THEN
   RAISE EXCEPTION 'submit response scorer anchor mismatch'; END IF;
 EXECUTE replace(v_src,v_old,v_new);

 v_sig:='private.exam_prep_safe_response_payload_v1(uuid,text,boolean)'::regprocedure;
 v_src:=pg_get_functiondef(v_sig);
 v_old:='''selected_answer'',v_r.selected_answer,';
 v_new:='''selected_answer'',private.exam_prep_mcq_display_letter_v1(v_r.selected_answer,v_i.display_to_source),';
 IF (length(v_src)-length(replace(v_src,v_old,'')))<>length(v_old) THEN
   RAISE EXCEPTION 'response payload selected_answer anchor mismatch'; END IF;
 EXECUTE replace(v_src,v_old,v_new);
END;$rewrite$;

DO $postcheck$
BEGIN
 IF (SELECT enabled FROM private.exam_prep_mcq_order_rollout_v1 WHERE singleton=true) IS DISTINCT FROM false
   OR (SELECT count(*) FROM private.exam_prep_session_items WHERE display_to_source IS NOT NULL)<>0
   OR (SELECT count(*) FROM private.exam_prep_mcq_order_function_backups_v1)<>3
 THEN RAISE EXCEPTION 'Exam Prep permutation installation postcheck failed'; END IF;
END;$postcheck$;
COMMIT;
