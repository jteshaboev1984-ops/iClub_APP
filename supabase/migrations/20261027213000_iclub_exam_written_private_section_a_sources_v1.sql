-- iClub Exam Prep: optional, governed Section A source material (P2/P4).
-- DORMANT: no content is approved, no learner plan/access is created, no legacy data touched.
-- This migration is additive except the compatible public written-open delegate.
BEGIN;
SET LOCAL lock_timeout = '4s';
SET LOCAL statement_timeout = '55s';

CREATE TABLE IF NOT EXISTS private.iclub_exam_written_source_cards_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  source_id text NOT NULL,
  source_version text NOT NULL,
  content jsonb NOT NULL CHECK (jsonb_typeof(content) = 'object'),
  content_sha256 text NOT NULL CHECK (content_sha256 ~ '^[a-f0-9]{64}$'),
  status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft','review','approved','retired')),
  academic_review text NOT NULL DEFAULT 'pending'
    CHECK (academic_review IN ('pending','approved','rejected')),
  language_review text NOT NULL DEFAULT 'pending'
    CHECK (language_review IN ('pending','approved','rejected')),
  source_review text NOT NULL DEFAULT 'pending'
    CHECK (source_review IN ('pending','approved','rejected')),
  release_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (program_key,version_key,source_id,source_version),
  FOREIGN KEY (program_key,version_key)
    REFERENCES private.iclub_exam_core_programs_v1(program_key,version_key)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  CHECK (NOT release_enabled OR
    (status='approved' AND academic_review='approved'
     AND language_review='approved' AND source_review='approved'
     AND content ?& ARRAY['en','ru','uz']))
);
CREATE TABLE IF NOT EXISTS private.iclub_exam_written_source_bindings_v1 (
  program_key text NOT NULL,
  version_key text NOT NULL,
  task_key text NOT NULL,
  task_version text NOT NULL,
  source_id text NOT NULL,
  source_version text NOT NULL,
  content_sha256 text NOT NULL CHECK (content_sha256 ~ '^[a-f0-9]{64}$'),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(program_key,version_key,task_key,task_version),
  FOREIGN KEY(program_key,version_key,task_key,task_version)
    REFERENCES private.iclub_exam_core_written_tasks_v1
      (program_key,version_key,task_key,task_version)
    ON UPDATE RESTRICT ON DELETE RESTRICT,
  FOREIGN KEY(program_key,version_key,source_id,source_version)
    REFERENCES private.iclub_exam_written_source_cards_v1
      (program_key,version_key,source_id,source_version)
    ON UPDATE RESTRICT ON DELETE RESTRICT
);

ALTER TABLE private.iclub_exam_written_source_cards_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_written_source_bindings_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.iclub_exam_written_source_cards_v1 FROM PUBLIC,anon,authenticated;
REVOKE ALL ON private.iclub_exam_written_source_bindings_v1 FROM PUBLIC,anon,authenticated;

-- A source belongs to an approved, actively assigned learner's exact question version.
-- The existing private open operation performs authentication, ownership, plan,
-- entitlement, item approval, and writes the idempotent opened_at event.
-- Calling it inside this function ensures the same protective checks are reused.
CREATE OR REPLACE FUNCTION private.iclub_exam_core_written_open_with_source_v2(
  p_item_id uuid,
  p_language text DEFAULT 'en'
) RETURNS jsonb
LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $function$
DECLARE
  v_base jsonb;
  v_source record;
  v_localized jsonb;
  v_paragraphs jsonb;
  v_table jsonb;
BEGIN
  IF p_language NOT IN ('en','ru','uz') THEN
    RAISE EXCEPTION 'written_locale_invalid' USING ERRCODE='22023';
  END IF;

  v_base := private.iclub_exam_core_written_open_v1(p_item_id,p_language);
  IF v_base->>'task_kind' <> 'written_external' THEN
    RAISE EXCEPTION 'written_task_invalid' USING ERRCODE='42501';
  END IF;

  -- Only Section A currently requires a data-response source.
  -- Non-Section-A practice remains backward compatible.
  IF split_part(v_base->>'task_key','.',2) <> 'A' THEN
    RETURN v_base;
  END IF;

  SELECT s.source_id,s.source_version,s.content_sha256,
         s.content->p_language AS localized
  INTO v_source
  FROM private.iclub_exam_written_source_bindings_v1 b
  JOIN private.iclub_exam_written_source_cards_v1 s
    ON s.program_key=b.program_key AND s.version_key=b.version_key
   AND s.source_id=b.source_id AND s.source_version=b.source_version
  WHERE b.program_key=v_base->>'program_key'
    AND b.version_key=v_base->>'program_version'
    AND b.task_key=v_base->>'task_key'
    AND b.task_version=v_base->>'task_version'
    AND b.content_sha256=s.content_sha256
    AND s.release_enabled=true AND s.status='approved'
    AND s.academic_review='approved' AND s.language_review='approved'
    AND s.source_review='approved'
    AND s.content ?& ARRAY['en','ru','uz']
    AND s.content_sha256 =
      encode(pg_catalog.sha256(pg_catalog.convert_to(s.content::text,'UTF8')),'hex');

  IF NOT FOUND OR v_source.localized IS NULL THEN
    RAISE EXCEPTION 'written_source_unavailable' USING ERRCODE='42501';
  END IF;

  v_localized := v_source.localized;
  v_paragraphs := v_localized->'paragraphs';
  v_table := v_localized->'table';
  IF jsonb_typeof(v_localized) <> 'object'
     OR NULLIF(btrim(v_localized->>'title'),'') IS NULL
     OR jsonb_typeof(v_paragraphs) <> 'array'
     OR jsonb_array_length(v_paragraphs) = 0
     OR EXISTS (
       SELECT 1 FROM jsonb_array_elements(v_paragraphs) AS p
       WHERE jsonb_typeof(p.value)<>'string'
          OR NULLIF(btrim(p.value #>> '{}'),'') IS NULL
     )
  THEN
    RAISE EXCEPTION 'written_source_locale_invalid' USING ERRCODE='42501';
  END IF;

  IF v_table IS NOT NULL AND jsonb_typeof(v_table) <> 'null' THEN
    IF jsonb_typeof(v_table)<>'object'
       OR jsonb_typeof(v_table->'columns')<>'array'
       OR jsonb_array_length(v_table->'columns')<2
       OR jsonb_typeof(v_table->'rows')<>'array'
       OR jsonb_array_length(v_table->'rows')=0
    THEN RAISE EXCEPTION 'written_source_table_invalid' USING ERRCODE='42501';
    END IF;
  END IF;

  -- No answer requirements, private mark schemes, or examiner feedback
  -- are included in this response. Criteria remains a separate explicit action.
  RETURN v_base || jsonb_build_object(
    'source',jsonb_build_object(
      'source_id',v_source.source_id,
      'source_version',v_source.source_version,
      'language',p_language,
      'title',v_localized->>'title',
      'paragraphs',v_paragraphs,
      'table',v_table
    )
  );
END;
$function$;

REVOKE ALL ON FUNCTION private.iclub_exam_core_written_open_with_source_v2(uuid,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION private.iclub_exam_core_written_open_with_source_v2(uuid,text)
  TO service_role;

-- Compatible signature: existing controller and the 5 other RPCs stay unchanged.
-- Section A now fails closed if the task is approved without approved source.
CREATE OR REPLACE FUNCTION public.iclub_exam_written_open_v1(
 p_item_id uuid,p_language text DEFAULT 'en'
) RETURNS jsonb LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path=''
AS $function$
BEGIN
 IF auth.uid() IS NULL THEN
   RETURN jsonb_build_object('ok',false,'code','not_authorized');
 END IF;
 RETURN private.iclub_exam_core_written_open_with_source_v2(p_item_id,p_language);
END;
$function$;
REVOKE ALL ON FUNCTION public.iclub_exam_written_open_v1(uuid,text)
  FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION public.iclub_exam_written_open_v1(uuid,text)
  TO authenticated;

-- Release-state preservation check; migration must not approve any draft.
DO $gate$
BEGIN
 IF EXISTS (
   SELECT 1 FROM private.iclub_exam_written_source_cards_v1
   WHERE release_enabled OR status='approved'
 )
 THEN RAISE EXCEPTION 'unexpected preapproved source during installation'; END IF;
 IF has_table_privilege('authenticated','private.iclub_exam_written_source_cards_v1','SELECT')
  OR has_table_privilege('anon','private.iclub_exam_written_source_bindings_v1','SELECT')
  OR has_function_privilege('anon',
    'public.iclub_exam_written_open_v1(uuid,text)','EXECUTE')
 THEN RAISE EXCEPTION 'written source exposure privilege violation'; END IF;
END;
$gate$;
COMMIT;
