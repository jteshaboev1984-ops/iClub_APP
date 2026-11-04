-- Issue #450 P0-15: READ ONLY source-text call graph for authenticated
-- Mathematics Exam Prep RPCs. Never a release authorization, no user records.
-- Resolves fully-qualified private./public. exam_prep_* function references;
-- DYNAMIC SQL, unqualified calls, non-exam_prep wrappers and overload-specific
-- semantics are NOT proven by regex. Review exact source before a real epoch
-- write fence; never assume graph completeness because a test returns GREEN.
WITH RECURSIVE f AS (
 SELECT p.oid, n.nspname AS schema_name,p.proname,
        pg_get_function_identity_arguments(p.oid) AS signature,
        pg_get_functiondef(p.oid) AS definition,
        has_function_privilege('authenticated',p.oid,'EXECUTE') AS authenticated_callable,
        pg_get_functiondef(p.oid) ~*
         '(insert[[:space:]]+into|update|delete[[:space:]]+from)[[:space:]]+(private\.)?exam_prep_' AS direct_dml_candidate,
        pg_get_functiondef(p.oid) ILIKE '%exam_prep_require_core_access_v1%' AS names_core_guard,
        pg_get_functiondef(p.oid) ~*
         'release_epoch|academic_epoch|progress_epoch|prelaunch_epoch' AS names_release_epoch
 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace=n.oid
 WHERE n.nspname IN ('public','private') AND p.proname LIKE '%exam_prep%'
), edges AS (
 SELECT caller.oid AS caller_oid,target.oid AS target_oid
 FROM f caller
 CROSS JOIN LATERAL regexp_matches(
  caller.definition,'(private|public)\.(exam_prep_[a-z_0-9]+)[[:space:]]*\(','g'
 ) AS m(groups)
 JOIN f target ON target.schema_name=m.groups[1] AND target.proname=m.groups[2]
), path(root_oid,root_name,current_oid,visited,depth) AS (
 SELECT oid,proname,oid,ARRAY[oid]::oid[],0
 FROM f WHERE schema_name='public' AND authenticated_callable
 UNION ALL
 SELECT w.root_oid,w.root_name,e.target_oid,w.visited||e.target_oid,w.depth+1
 FROM path w JOIN edges e ON e.caller_oid=w.current_oid
 WHERE w.depth<5 AND NOT e.target_oid=ANY(w.visited)
), root_state AS (
 SELECT w.root_oid,w.root_name,
        bool_or(f.direct_dml_candidate) AS reaches_parsed_dml,
        bool_or(f.names_core_guard) AS reaches_parsed_core_guard,
        bool_or(f.names_release_epoch) AS reaches_parsed_epoch_marker,
        min(w.depth) FILTER(WHERE f.direct_dml_candidate) AS nearest_dml_depth,
        count(DISTINCT w.current_oid) AS parsed_reachable_functions
 FROM path w JOIN f ON f.oid=w.current_oid
 GROUP BY w.root_oid,w.root_name
), inventory AS (
 SELECT r.*,root.signature,root.direct_dml_candidate AS direct_root_dml
 FROM root_state r JOIN f root ON root.oid=r.root_oid
)
SELECT jsonb_build_object(
 'contract','P0-15_source-text_only_not_production_release_authority',
 'authenticated_root_rpcs',count(*),
 'parsed_reachable_write_candidates',count(*) FILTER(WHERE reaches_parsed_dml),
 'direct_root_dml_candidates',count(*) FILTER(WHERE direct_root_dml),
 'indirect_only_dml_candidates',count(*) FILTER(WHERE reaches_parsed_dml AND NOT direct_root_dml),
 'no_parsed_write_reference',count(*) FILTER(WHERE NOT reaches_parsed_dml),
 'write_candidates_without_named_core_guard',count(*) FILTER(
    WHERE reaches_parsed_dml AND NOT reaches_parsed_core_guard),
 'write_candidates_with_named_epoch_marker',count(*) FILTER(
    WHERE reaches_parsed_dml AND reaches_parsed_epoch_marker),
 'write_candidate_routes',coalesce(jsonb_agg(jsonb_build_object(
   'rpc',root_name,'signature',signature,
   'direct_dml',direct_root_dml,
   'min_dml_depth',nearest_dml_depth,
   'reachable_functions',parsed_reachable_functions,
   'names_core_guard_somewhere',reaches_parsed_core_guard,
   'names_epoch_marker_somewhere',reaches_parsed_epoch_marker)
   ORDER BY root_name,signature)
   FILTER(WHERE reaches_parsed_dml),'[]'::jsonb),
 'scope_warning','regex excludes dynamic/unqualified calls and nonmatching wrappers; do not authorize a release from this inventory'
) AS p0_15_readonly_rpc_graph
FROM inventory;
