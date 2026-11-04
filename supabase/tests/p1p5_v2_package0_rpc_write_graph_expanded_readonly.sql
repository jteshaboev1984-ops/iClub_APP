-- Issue #450 P0-16A, READ ONLY. Actual production pg_catalog ONLY.
-- Broaden P0-15 to QUALIFIED public/private helper calls and ANY textual DML.
-- Source-text triage is NOT an executable academic-epoch fence.
-- Does not read user rows, update academic records or grant release permission.
-- Known blind spots: unqualified/dynamic SQL, triggers, Edge/REST writers,
-- overloaded routines, comments/strings, schema drift and authenticated devices.
WITH RECURSIVE fn AS (
 SELECT p.oid,n.nspname AS schema_name,p.proname AS function_name,
  pg_get_function_identity_arguments(p.oid) AS signature,
  pg_get_functiondef(p.oid) AS definition,
  has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_callable,
  pg_get_functiondef(p.oid) ~* '(insert[[:space:]]+into|update[[:space:]]+|delete[[:space:]]+from|merge[[:space:]]+into|truncate[[:space:]]+)' AS any_dml_text,
  pg_get_functiondef(p.oid) ~* '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private[.])?exam_prep_' AS exam_prep_dml_text,
  pg_get_functiondef(p.oid) ~* '(release_epoch|academic_epoch|progress_epoch|prelaunch_epoch)' AS epoch_marker_text,
  pg_get_functiondef(p.oid) ~* 'execute[[:space:]]+(format[[:space:]]*[(]|[a-z_])' AS dynamic_execute_text
 FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname IN ('public','private')
), edges AS (
 SELECT f.oid AS caller_oid,g.oid AS target_oid
 FROM fn f CROSS JOIN LATERAL regexp_matches(
  f.definition,'(public|private)[.]([a-z_][a-z_0-9]*)[[:space:]]*[(]','g'
 ) AS m(parts)
 JOIN fn g ON g.schema_name=m.parts[1] AND g.function_name=m.parts[2]
), roots AS (
 SELECT * FROM fn WHERE schema_name='public' AND function_name LIKE '%exam_prep%'
 AND authenticated_callable
), walk(root_oid, current_oid, visited, depth) AS (
 SELECT oid,oid,ARRAY[oid]::oid[],0 FROM roots
 UNION ALL
 SELECT w.root_oid,e.target_oid,w.visited||e.target_oid,w.depth+1
 FROM walk w JOIN edges e ON e.caller_oid=w.current_oid
 WHERE w.depth<7 AND NOT e.target_oid=ANY(w.visited)
), states AS (
 SELECT w.root_oid,
  bool_or(f.any_dml_text) AS reaches_any_dml_text,
  bool_or(f.exam_prep_dml_text) AS reaches_exam_prep_dml_text,
  bool_or(f.epoch_marker_text) AS reaches_epoch_marker_text,
  bool_or(f.dynamic_execute_text) AS reaches_dynamic_execute_text,
  count(DISTINCT w.current_oid) AS reachable_function_count,
  max(w.depth) AS max_depth
 FROM walk w JOIN fn f ON f.oid=w.current_oid GROUP BY w.root_oid
), report AS (
 SELECT r.function_name,r.signature,md5(r.definition) AS source_md5,
        s.reaches_any_dml_text,s.reaches_exam_prep_dml_text,
        s.reaches_epoch_marker_text,s.reaches_dynamic_execute_text,
        s.reachable_function_count,s.max_depth
 FROM roots r JOIN states s ON s.root_oid=r.oid
)
SELECT jsonb_build_object(
 'contract','P0-16A_SELECT_only_source_text_review_NO_GO',
 'authenticated_named_roots',count(*),
 'reachable_any_dml_candidates',count(*) FILTER(WHERE reaches_any_dml_text),
 'reachable_exam_prep_dml_candidates',count(*) FILTER(WHERE reaches_exam_prep_dml_text),
 'other_dml_suspects',count(*) FILTER(WHERE reaches_any_dml_text AND NOT reaches_exam_prep_dml_text),
 'dynamic_sql_suspects_count',count(*) FILTER(WHERE reaches_dynamic_execute_text),
 'route_fingerprint_md5',md5(string_agg(function_name||'('||signature||'):'||source_md5,'|' ORDER BY function_name,signature)),
 'candidate_routes',coalesce(jsonb_agg(jsonb_build_object(
   'rpc',function_name,'signature',signature,'source_md5',source_md5,
   'reaches_exam_prep_dml',reaches_exam_prep_dml_text,
   'reaches_epoch_marker_text',reaches_epoch_marker_text,
   'reaches_dynamic_execute_text',reaches_dynamic_execute_text,
   'reachable_function_count',reachable_function_count,
   'max_depth',max_depth)
   ORDER BY function_name,signature)
   FILTER(WHERE reaches_any_dml_text),'[]'::jsonb),
 'proof_limits','Source regex is triage only; dynamic/unqualified calls, triggers, Edge/REST, overloads and runtime authorizations are NOT verified.',
 'release_verdict','NO_GO'
) AS p0_16a_source_inventory
FROM report;
