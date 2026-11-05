-- Issue #450 / Package 0 / P0-16B. READ ONLY pg_catalog trigger inventory.
-- Run against production for metadata inspection ONLY; no learner rows are read.
-- This is a detection aid, NOT proof of complete epoch enforcement or release GO.
-- A function can cause writes through nested calls, dynamic SQL or triggers:
-- direct source-text patterns are conservative triage, not a security verdict.
WITH bound AS (
  SELECT
    n.nspname AS table_schema,
    c.relname AS table_name,
    t.tgname AS trigger_name,
    t.tgenabled AS enabled_mode,
    t.tgtype::integer AS event_bits,
    t.tgfoid AS trigger_function_oid,
    pn.nspname AS function_schema,
    p.proname AS function_name,
    md5(pg_get_functiondef(p.oid)) AS function_source_md5,
    pg_get_functiondef(p.oid) ~*
      '(insert[[:space:]]+into|update[[:space:]]+|delete[[:space:]]+from|merge[[:space:]]+into)'
      AS direct_dml_text
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  JOIN pg_proc p ON p.oid = t.tgfoid
  JOIN pg_namespace pn ON pn.oid = p.pronamespace
  WHERE NOT t.tgisinternal
    AND n.nspname = 'private'
    AND c.relname LIKE 'exam_prep_%'
),
per_table AS (
  SELECT table_name, count(*) AS bindings,
         count(*) FILTER (WHERE direct_dml_text) AS direct_dml_candidates
  FROM bound
  GROUP BY table_name
),
per_function AS (
  SELECT function_schema, function_name, function_source_md5,
         count(*) AS bindings,
         bool_or(direct_dml_text) AS direct_dml_candidate
  FROM bound
  GROUP BY function_schema, function_name, function_source_md5
)
SELECT jsonb_build_object(
  'contract', 'P0-16B_READ_ONLY_TRIGGER_SOURCE_AUDIT_NOT_RELEASE_GO',
  'trigger_bindings', (SELECT count(*) FROM bound),
  'exam_prep_tables_with_triggers', (SELECT count(*) FROM per_table),
  'unique_trigger_functions', (SELECT count(*) FROM per_function),
  'direct_dml_trigger_bindings',
    (SELECT count(*) FROM bound WHERE direct_dml_text),
  'direct_dml_function_candidates',
    (SELECT count(*) FROM per_function WHERE direct_dml_candidate),
  'event_insert_bindings',
    (SELECT count(*) FROM bound WHERE (event_bits & 4) <> 0),
  'event_update_bindings',
    (SELECT count(*) FROM bound WHERE (event_bits & 16) <> 0),
  'event_delete_bindings',
    (SELECT count(*) FROM bound WHERE (event_bits & 8) <> 0),
  'high_impact_table_bindings',
    (SELECT count(*) FROM bound WHERE table_name IN
      ('exam_prep_sessions','exam_prep_stage_states',
       'exam_prep_responses','exam_prep_weekly_plans','exam_prep_retest_events')),
  'source_fingerprint_md5',
    (SELECT md5(string_agg(
      table_schema || '.' || table_name || ':' || trigger_name || ':' ||
      function_schema || '.' || function_name || ':' || function_source_md5,
      '|' ORDER BY table_name,trigger_name,function_schema,function_name
    )) FROM bound),
  'direct_dml_candidate_functions',
    (SELECT coalesce(jsonb_agg(
      jsonb_build_object(
        'name',function_schema || '.' || function_name,
        'trigger_bindings',bindings,
        'source_md5',function_source_md5
      ) ORDER BY function_schema,function_name
    ),'[]'::jsonb) FROM per_function WHERE direct_dml_candidate),
  'highest_trigger_density_tables',
    (SELECT coalesce(jsonb_agg(
      jsonb_build_object('table',table_name,
        'trigger_bindings',bindings,'direct_dml_candidates',direct_dml_candidates)
      ORDER BY bindings DESC, table_name
    ),'[]'::jsonb) FROM
      (SELECT * FROM per_table ORDER BY bindings DESC,table_name LIMIT 12) x),
  'review_limitations',
    'No dynamic/unqualified nested-call, Edge/REST, RLS, alternate-schema, overload or runtime epoch proof. Counts are snapshot-dependent.',
  'release_verdict','NO_GO_EXISTING_GATE_UNCHANGED'
) AS p0_16b_trigger_inventory;
