-- Issue #450 P0-10: CI-ONLY OVERLAY, NOT a standalone executable SQL migration.
-- Contains four injection sections for the previously verified 32-table
-- disposable transaction. NO PRODUCTION SQL. Every section lives inside the
-- original BEGIN ... ROLLBACK, after the original two-user guard succeeds.
-- PR #469 and #470 table definitions are copied as SYNTHETIC prospective
-- mirrors; these are not the official merged migrations.
-- P0-10 SECTION SETUP
DO $p0_gate$
BEGIN
  IF current_database()<>'postgres'
     OR current_setting('iclub.e2e_isolated',true) IS DISTINCT FROM 'true'
     OR (SELECT count(*) FROM public.users)<>2
     OR (SELECT count(*) FROM auth.users)<>2
  THEN RAISE EXCEPTION 'P0-10 refused: not the disposable two-user PG17'; END IF;
  IF to_regclass('private.exam_prep_learner_exam_dates_v1') IS NOT NULL
     OR to_regclass('private.exam_prep_periodic_study_report_receipts_v1') IS NOT NULL
  THEN RAISE EXCEPTION 'P0-10 future table already installed; compare exact migration before running';
  END IF;
END $p0_gate$;

-- SYNTHETIC mirrors of exact CREATE TABLE field layout in draft PR #470/#469.
CREATE TABLE private.exam_prep_learner_exam_dates_v1 (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  component_code text not null check(component_code in ('P1','P5')),
  exam_date date null,
  source text not null default 'learner_selected' check(source='learner_selected'),
  updated_at timestamptz not null default now(),
  primary key(user_id,program_version_id,component_code)
);
ALTER TABLE private.exam_prep_learner_exam_dates_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_learner_exam_dates_v1 FROM public,anon,authenticated;

CREATE TABLE private.exam_prep_periodic_study_report_receipts_v1 (
  user_id uuid not null references public.users(id) on delete cascade,
  program_version_id bigint not null references private.exam_prep_program_versions(id) on delete restrict,
  diagnostic_anchor_at timestamptz not null,
  period_kind text not null check (period_kind in ('week','month')),
  period_ended_at timestamptz not null,
  claimed_at timestamptz not null default now(),
  report_payload jsonb not null,
  primary key (user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at)
);
ALTER TABLE private.exam_prep_periodic_study_report_receipts_v1 ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON private.exam_prep_periodic_study_report_receipts_v1 FROM public,anon,authenticated;

CREATE TEMP TABLE p0_future_selected_program AS
  SELECT DISTINCT program_version_id
  FROM private.exam_prep_sessions
  WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid
    AND program_version_id IS NOT NULL
  ORDER BY program_version_id LIMIT 1;

DO $p0_source$
BEGIN
 IF (SELECT count(*) FROM p0_future_selected_program)<>1 THEN
   RAISE EXCEPTION 'P0-10 cannot select genuine CI Math program version';
 END IF;
 IF (SELECT count(*) FROM information_schema.columns
   WHERE table_schema='private'
     AND table_name='exam_prep_periodic_study_report_receipts_v1'
     AND column_name='program_version_id')<>1 OR
    (SELECT count(*) FROM information_schema.columns
     WHERE table_schema='private'
       AND table_name='exam_prep_periodic_study_report_receipts_v1'
       AND column_name='diagnostic_anchor_at')<>1 THEN
   RAISE EXCEPTION 'P0-11 draft receipt version/diagnostic scoping absent';
 END IF;
 IF has_table_privilege('authenticated','private.exam_prep_learner_exam_dates_v1','DELETE')
    OR has_table_privilege('anon','private.exam_prep_learner_exam_dates_v1','DELETE')
    OR has_table_privilege('authenticated','private.exam_prep_periodic_study_report_receipts_v1','DELETE')
 THEN RAISE EXCEPTION 'P0-10 future tables grant client delete rights'; END IF;
END $p0_source$;

INSERT INTO private.exam_prep_learner_exam_dates_v1
 (user_id,program_version_id,component_code,exam_date)
SELECT '11111111-1111-4111-8111-111111111191'::uuid,
       p.program_version_id,c.component_code,c.exam_date
FROM p0_future_selected_program p
CROSS JOIN (VALUES ('P1',DATE '2027-04-10'),('P5',DATE '2027-05-09'))
  AS c(component_code,exam_date);
INSERT INTO private.exam_prep_learner_exam_dates_v1
 (user_id,program_version_id,component_code,exam_date)
SELECT '22222222-2222-4222-8222-222222222292'::uuid,
       p.program_version_id,'P5',DATE '2027-05-12'
FROM p0_future_selected_program p;

INSERT INTO private.exam_prep_periodic_study_report_receipts_v1
 (user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at,report_payload)
SELECT '11111111-1111-4111-8111-111111111191'::uuid,
       p.program_version_id,'2026-09-01T09:00:00Z'::timestamptz,
       'week','2026-11-02T00:00:00Z','{"test":"old_math_beta_receipt"}'::jsonb
FROM p0_future_selected_program p
UNION ALL
SELECT '22222222-2222-4222-8222-222222222292'::uuid,
       p.program_version_id,'2026-09-01T09:00:00Z'::timestamptz,
       'week','2026-11-02T00:00:00Z','{"test":"other_learner_receipt"}'::jsonb
FROM p0_future_selected_program p
UNION ALL
SELECT '11111111-1111-4111-8111-111111111191'::uuid,
       p.program_version_id,'2026-10-01T09:00:00Z'::timestamptz,
       'week','2026-11-02T00:00:00Z','{"test":"fresh_cycle_same_period"}'::jsonb
FROM p0_future_selected_program p;
-- A replay in the SAME cycle is ignored, but a fresh completed diagnostic
-- is entitled to its own receipt, even if week-end timestamps coincide.
DO $p0_receipt$
DECLARE v_inserted integer;
BEGIN
 WITH attempted AS (
   INSERT INTO private.exam_prep_periodic_study_report_receipts_v1
     (user_id,program_version_id,diagnostic_anchor_at,period_kind,period_ended_at,report_payload)
   SELECT '11111111-1111-4111-8111-111111111191'::uuid,
          p.program_version_id,'2026-09-01T09:00:00Z'::timestamptz,
          'week','2026-11-02T00:00:00Z','{"test":"duplicate_old_cycle"}'::jsonb
   FROM p0_future_selected_program p ON CONFLICT DO NOTHING RETURNING 1
 )
 SELECT count(*) INTO v_inserted FROM attempted;
 IF v_inserted<>0 OR
    (SELECT count(*) FROM private.exam_prep_periodic_study_report_receipts_v1)<>3
 THEN RAISE EXCEPTION 'P0-11 per diagnostic-cycle receipt uniqueness broken'; END IF;
 RAISE NOTICE 'PASS P0-11 same-period reports separated by diagnostic cycle; replay denied';
END $p0_receipt$;
CREATE TEMP TABLE p0_future_before AS SELECT
 (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
    WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid) AS target_dates,
 (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
    WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid) AS other_dates,
 (SELECT count(*) FROM private.exam_prep_periodic_study_report_receipts_v1
    WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid) AS target_receipts,
 (SELECT count(*) FROM private.exam_prep_periodic_study_report_receipts_v1
    WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid) AS other_receipts,
 (SELECT md5(coalesce(string_agg(user_id::text||':'||component_code||':'||exam_date::text,
     '|' ORDER BY user_id,component_code),'')) FROM private.exam_prep_learner_exam_dates_v1) AS dates_fingerprint,
 (SELECT md5(coalesce(string_agg(user_id::text||':'||program_version_id::text||':'||diagnostic_anchor_at::text||':'||period_kind||':'||report_payload::text,
     '|' ORDER BY user_id,diagnostic_anchor_at,period_kind),'')) FROM private.exam_prep_periodic_study_report_receipts_v1) AS receipts_fingerprint;

-- Negative: a previously unknown retained FK must block deletion rather than
-- being bypassed. Savepoint removes the simulated new FK after proof.
SAVEPOINT p0_unknown_future_fk_probe;
CREATE TABLE private.p0_10_unreviewed_date_link (
  id integer primary key,
  user_id uuid not null,
  program_version_id bigint not null,
  component_code text not null,
  foreign key(user_id,program_version_id,component_code)
    references private.exam_prep_learner_exam_dates_v1(user_id,program_version_id,component_code)
    on delete restrict
);
INSERT INTO private.p0_10_unreviewed_date_link
SELECT 1,d.user_id,d.program_version_id,d.component_code
 FROM private.exam_prep_learner_exam_dates_v1 d
 WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
   AND d.component_code='P1';
DO $p0_unknown$
DECLARE rejected boolean:=false;
BEGIN
 BEGIN
   DELETE FROM private.exam_prep_learner_exam_dates_v1 d
    WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
      AND d.component_code='P1';
 EXCEPTION WHEN foreign_key_violation THEN rejected:=true;
 END;
 IF NOT rejected THEN RAISE EXCEPTION 'P0-10 drift test failed: unknown FK did not stop delete'; END IF;
END $p0_unknown$;
ROLLBACK TO SAVEPOINT p0_unknown_future_fk_probe;

DO $p0_counts$
BEGIN
 IF (SELECT target_dates FROM p0_future_before)<>2
 OR (SELECT other_dates FROM p0_future_before)<>1
 OR (SELECT target_receipts FROM p0_future_before)<>2
 OR (SELECT other_receipts FROM p0_future_before)<>1
 THEN RAISE EXCEPTION 'P0-10 failed to seed exact prospective scope'; END IF;
 RAISE NOTICE 'PASS P0-10 prospective new-table source/privilege, two-user/receipt setup, unknown-FK stop';
END $p0_counts$;

-- P0-10 SECTION FIRST_DELETE
-- Extend the legacy 32-table synthetic reset INSIDE its original savepoint.
-- Receipt retention remains HOLD for release policy approval, despite the
-- draft program+diagnostic-cycle scoping now preventing old/new collisions.
-- No claim of a full release-ready reset.
DELETE FROM private.exam_prep_learner_exam_dates_v1 d
WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
  AND d.program_version_id IN (SELECT program_version_id FROM p0_future_selected_program);
DO $p0_first$
BEGIN
 IF EXISTS(SELECT 1 FROM private.exam_prep_learner_exam_dates_v1
           WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid)
 OR (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid)<>1
 OR (SELECT md5(coalesce(string_agg(user_id::text||':'||program_version_id::text||':'||diagnostic_anchor_at::text||':'||period_kind||':'||report_payload::text,
   '|' ORDER BY user_id,diagnostic_anchor_at,period_kind),'')) FROM private.exam_prep_periodic_study_report_receipts_v1)
   IS DISTINCT FROM (SELECT receipts_fingerprint FROM p0_future_before)
 THEN RAISE EXCEPTION 'P0-10 future date scope or receipt retention violated'; END IF;
 RAISE NOTICE 'PASS P0-10 first scoped future-date cleanup; all receipts HELD';
END $p0_first$;

-- P0-10 SECTION SECOND_DELETE
-- Repeated exact scoped action must be idempotent, not touch other learner.
DELETE FROM private.exam_prep_learner_exam_dates_v1 d
WHERE d.user_id='11111111-1111-4111-8111-111111111191'::uuid
  AND d.program_version_id IN (SELECT program_version_id FROM p0_future_selected_program);
DO $p0_second$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid)<>1
 OR (SELECT count(*) FROM private.exam_prep_periodic_study_report_receipts_v1)<>3
 THEN RAISE EXCEPTION 'P0-10 repeat unexpectedly changed protected records'; END IF;
 RAISE NOTICE 'PASS P0-10 future date repeat idempotent';
END $p0_second$;

-- P0-10 SECTION POST_ROLLBACK
-- Only the inner SAVEPOINT rolled back: all synthetic prelaunch rows must now
-- be exactly as before the delete. Outer ROLLBACK drops both new tables.
DO $p0_revert$
BEGIN
 IF (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id='11111111-1111-4111-8111-111111111191'::uuid)<>2
 OR (SELECT count(*) FROM private.exam_prep_learner_exam_dates_v1
     WHERE user_id='22222222-2222-4222-8222-222222222292'::uuid)<>1
 OR (SELECT md5(coalesce(string_agg(user_id::text||':'||component_code||':'||exam_date::text,
       '|' ORDER BY user_id,component_code),''))
       FROM private.exam_prep_learner_exam_dates_v1)
    IS DISTINCT FROM (SELECT dates_fingerprint FROM p0_future_before)
 OR (SELECT md5(coalesce(string_agg(user_id::text||':'||program_version_id::text||':'||diagnostic_anchor_at::text||':'||period_kind||':'||report_payload::text,
       '|' ORDER BY user_id,diagnostic_anchor_at,period_kind),''))
       FROM private.exam_prep_periodic_study_report_receipts_v1)
    IS DISTINCT FROM (SELECT receipts_fingerprint FROM p0_future_before)
 THEN RAISE EXCEPTION 'P0-10 combined SAVEPOINT restoration was not byte-equivalent'; END IF;
 RAISE NOTICE 'PASS P0-10 32 existing + future dates synthetic delete/repeat/restore; receipt retention remains NO_GO';
END $p0_revert$;
