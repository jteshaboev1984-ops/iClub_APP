-- Issue #450 P0-08: read-only inventory of P1/P5 user-state tables proposed by draft PRs #469/#470.
-- READ ONLY. NOT release GO. No deletion or migration permission.
-- Initial Package 0's 32-table set predates these draft schema additions.
WITH proposed(table_name, proposed_pr, disposition) AS (
  VALUES
    ('exam_prep_periodic_study_report_receipts_v1'::text,469,'HOLD: no program_version_id; scope/retention needs an explicit decision'::text),
    ('exam_prep_learner_exam_dates_v1'::text,470,'REVIEW: program-scoped date records; must be added to approved reset manifest if released'::text)
), catalog AS (
  SELECT c.oid, c.relname, c.relrowsecurity
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
   WHERE n.nspname='private' AND c.relkind='r'
)
SELECT p.table_name,p.proposed_pr,
       (c.oid IS NOT NULL) AS installed_in_database,
       coalesce(c.relrowsecurity,false) AS rls_enabled_if_installed,
       coalesce((SELECT array_agg(a.attname::text ORDER BY a.attnum)
                   FROM pg_attribute a WHERE a.attrelid=c.oid
                     AND a.attnum>0 AND NOT a.attisdropped),ARRAY[]::text[]) AS actual_columns,
       coalesce((SELECT jsonb_agg(jsonb_build_object(
                 'referenced_table', con.confrelid::regclass::text,
                 'fk_name', con.conname) ORDER BY con.conname)
                   FROM pg_constraint con WHERE con.conrelid=c.oid AND con.contype='f'),'[]'::jsonb) AS outgoing_fks,
       p.disposition,
       'NO_GO: not in approved 32-table reset allowlist; cannot clear at release without revised sign-off'::text AS cleanup_gate
  FROM proposed p LEFT JOIN catalog c ON c.relname=p.table_name
 ORDER BY p.proposed_pr,p.table_name;
