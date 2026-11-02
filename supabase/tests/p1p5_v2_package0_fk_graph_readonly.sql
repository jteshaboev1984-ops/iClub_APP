-- Mathematics P1/P5 #450 v2.0: current-schema FK DAG feasibility, read-only.
-- No mutation is performed. This is NOT permission to run production cleanup.
-- The only permitted candidate graph cut is two nullable, checked column links.
WITH RECURSIVE
candidate(name) AS (
VALUES ('exam_prep_component_access_gates'),('exam_prep_component_placements'),('exam_prep_correction_actions'),('exam_prep_correction_cases'),('exam_prep_evidence_events'),('exam_prep_exam_appointments'),('exam_prep_exam_map_revisions'),('exam_prep_exam_ops_confirmations'),('exam_prep_exam_profiles'),('exam_prep_human_review_recommendations'),('exam_prep_integrity_events'),('exam_prep_learning_review_starts_v1'),('exam_prep_legacy_evidence_references'),('exam_prep_prerequisite_states'),('exam_prep_progress_revalidation_cases'),('exam_prep_progress_revalidation_items'),('exam_prep_recovery_cases'),('exam_prep_responses'),('exam_prep_retest_events'),('exam_prep_session_authorizations'),('exam_prep_session_items'),('exam_prep_sessions'),('exam_prep_skill_states'),('exam_prep_stage_states'),('exam_prep_timed_attempt_results'),('exam_prep_timed_written_self_marks'),('exam_prep_weekly_flow_enrollment_v1'),('exam_prep_weekly_goal_snapshots'),('exam_prep_weekly_plan_items'),('exam_prep_weekly_plans'),('exam_prep_written_session_check_snapshots'),('exam_prep_written_step_advances_v1')
),
targets AS (
 SELECT ('private.'||name)::regclass::oid AS table_oid FROM candidate
),
all_edges AS (
 SELECT conrelid child,confrelid parent,conname,condeferrable,
        pg_get_constraintdef(oid) def
 FROM pg_constraint WHERE contype='f'
   AND confrelid IN (SELECT table_oid FROM targets)
),
internal_edges AS (
 SELECT * FROM all_edges WHERE child IN (SELECT table_oid FROM targets)
),
nullable_cuts AS (
 SELECT e.* FROM internal_edges e
 WHERE e.child='private.exam_prep_session_authorizations'::regclass
 AND (e.def LIKE 'FOREIGN KEY (consumed_session_id)%'
      OR e.def LIKE 'FOREIGN KEY (correction_case_id)%')
),
cut_edges AS (
 SELECT e.* FROM internal_edges e WHERE NOT EXISTS(
  SELECT 1 FROM nullable_cuts c WHERE c.conname=e.conname AND c.child=e.child)
),
paths(origin,node,visited,is_cycle) AS (
 SELECT e.child,e.parent,ARRAY[e.child,e.parent]::oid[],
        e.parent=e.child
 FROM cut_edges e
 UNION ALL
 SELECT p.origin,e.parent,p.visited||e.parent,e.parent=ANY(p.visited)
 FROM paths p JOIN cut_edges e ON e.child=p.node
 WHERE NOT p.is_cycle AND cardinality(p.visited)<=34
)
SELECT jsonb_build_object(
 'report','P0_FK_ACYCLIC_AFTER_TWO_EXPLICIT_NULLABLE_CUTS',
 'candidate_tables',(SELECT count(*) FROM candidate),
 'current_edges',(SELECT count(*) FROM internal_edges),
 'required_unlink_edges',(SELECT jsonb_agg(jsonb_build_object('name',conname,'definition',def) ORDER BY conname) FROM nullable_cuts),
 'retained_inbound_fks',(SELECT jsonb_agg(jsonb_build_object('child',child::regclass::text,'parent',parent::regclass::text,'definition',def) ORDER BY child::regclass::text) FROM all_edges WHERE child NOT IN (SELECT table_oid FROM targets)),
 'cycles_after_unlink',(SELECT count(*) FROM paths WHERE is_cycle),
 'mentor_queue_references',(SELECT count(*) FROM private.exam_prep_mentor_queue_items WHERE recommendation_id IS NOT NULL),
 'verdict',CASE WHEN (SELECT count(*) FROM candidate)=32
  AND (SELECT count(*) FROM nullable_cuts)=2
  AND (SELECT count(*) FROM paths WHERE is_cycle)=0
  AND (SELECT count(*) FROM all_edges WHERE child NOT IN (SELECT table_oid FROM targets))=1
  AND (SELECT count(*) FROM private.exam_prep_mentor_queue_items WHERE recommendation_id IS NOT NULL)=0
  THEN 'GRAPH_PRECHECK_PASS_NO_DELETE_AUTHORIZED' ELSE 'BLOCKED_SCHEMA_DRIFT_OR_UNRESOLVED_FK' END
) AS fk_graph_readonly_report;
