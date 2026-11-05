-- Issue #450, P0-16B READ ONLY pg_catalog trigger -> helper call graph.
-- NO learner data, NO writes. Source regex is triage, NOT an epoch/security proof.
-- Qualified call edges only; dynamic/unqualified SQL, overloaded routines,
-- trigger-trigger propagation, Edge/REST calls and SQL text false positives remain.
WITH RECURSIVE routines AS (
  SELECT p.oid, n.nspname AS schema_name, p.proname AS function_name,
         pg_get_functiondef(p.oid) AS source,
         pg_get_function_identity_arguments(p.oid) AS args,
         pg_get_functiondef(p.oid) ~*
           '(insert[[:space:]]+into|update[[:space:]]+|delete[[:space:]]+from|merge[[:space:]]+into)'
           AS direct_dml_text
  FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
  WHERE n.nspname IN ('public','private')
), trigger_roots AS (
  SELECT t.oid AS trigger_oid, c.relname AS table_name,
         t.tgname AS trigger_name, r.oid AS routine_oid,
         r.direct_dml_text AS root_direct_dml_text
  FROM pg_trigger t
  JOIN pg_class c ON c.oid=t.tgrelid
  JOIN pg_namespace n ON n.oid=c.relnamespace
  JOIN routines r ON r.oid=t.tgfoid
  WHERE NOT t.tgisinternal
    AND n.nspname='private' AND c.relname LIKE 'exam_prep_%'
), qualified_edges AS (
  SELECT r.oid AS caller_oid, target.oid AS target_oid
  FROM routines r
  CROSS JOIN LATERAL regexp_matches(
    r.source, '(public|private)[.]([a-z_][a-z_0-9]*)[[:space:]]*[(]', 'g'
  ) AS m(parts)
  JOIN routines target ON target.schema_name=m.parts[1]
      AND target.function_name=m.parts[2]
), walk(trigger_oid,routine_oid,visited,depth) AS (
  SELECT trigger_oid,routine_oid,ARRAY[routine_oid]::oid[],0
  FROM trigger_roots
  UNION ALL
  SELECT w.trigger_oid,e.target_oid,w.visited||e.target_oid,w.depth+1
  FROM walk w JOIN qualified_edges e ON e.caller_oid=w.routine_oid
  WHERE w.depth < 12 AND NOT e.target_oid=ANY(w.visited)
), reachable AS (
  SELECT w.trigger_oid, count(DISTINCT w.routine_oid) AS reachable_functions,
         max(w.depth) AS max_depth,
         bool_or(r.direct_dml_text) AS reaches_dml_text
  FROM walk w JOIN routines r ON r.oid=w.routine_oid
  GROUP BY w.trigger_oid
), report AS (
  SELECT t.table_name,t.trigger_name,t.root_direct_dml_text,
         r.reaches_dml_text,r.reachable_functions,r.max_depth
  FROM trigger_roots t JOIN reachable r ON r.trigger_oid=t.trigger_oid
)
SELECT jsonb_build_object(
 'contract','P0-16B_READ_ONLY_TRIGGER_TRANSITIVE_HEURISTIC_NO_GO',
 'trigger_bindings',count(*),
 'root_source_dml_bindings',count(*) FILTER(WHERE root_direct_dml_text),
 'transitive_dml_candidate_bindings',count(*) FILTER(WHERE reaches_dml_text),
 'nested_only_candidates',count(*) FILTER(WHERE reaches_dml_text AND NOT root_direct_dml_text),
 'with_qualified_helper_reach',count(*) FILTER(WHERE reachable_functions>1),
 'deepest_qualified_path',max(max_depth),
 'candidate_sample',coalesce(jsonb_agg(
   jsonb_build_object('table',table_name,'trigger',trigger_name,
     'direct',root_direct_dml_text,'reachable_functions',reachable_functions)
   ORDER BY table_name,trigger_name
 ) FILTER(WHERE reaches_dml_text AND NOT root_direct_dml_text),'[]'::jsonb),
 'limit','Source-text only, qualified functions only, depth<=12. NOT a complete trigger or release epoch proof.',
 'release_verdict','NO_GO_EXISTING_GATE_UNCHANGED'
) AS p0_16b_trigger_transitive_inventory
FROM report;
