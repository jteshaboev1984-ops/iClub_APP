-- Issue #450 P0-09: ISOLATED PostgreSQL 17 ONLY.
-- MODEL of a future release-epoch authorization gate, NOT a production migration,
-- NOT an executable release cleanup. Synthetic identities and test data only.
-- Never copy these functions/roles/GUC into a live DB.
\set ON_ERROR_STOP on
BEGIN;
DO $guard$
BEGIN
  IF current_database() <> 'iclub_p1p5_package0_test'
     OR current_setting('server_version_num')::int < 170000 THEN
    RAISE EXCEPTION 'P0-09 DISPOSABLE ONLY: refused database %', current_database();
  END IF;
END
$guard$;

CREATE ROLE p0_mock_learner NOLOGIN;
CREATE ROLE p0_mock_release_executor NOLOGIN;
CREATE SCHEMA p0_09_fixture;
REVOKE ALL ON SCHEMA p0_09_fixture FROM PUBLIC;
GRANT USAGE ON SCHEMA p0_09_fixture TO p0_mock_learner, p0_mock_release_executor;

CREATE TABLE p0_09_fixture.gate (
  program text PRIMARY KEY,
  epoch integer NOT NULL CHECK(epoch > 0),
  accepting_writes boolean NOT NULL,
  active_attempts integer NOT NULL DEFAULT 0 CHECK(active_attempts >= 0),
  unknown_fk_or_schema_drift boolean NOT NULL DEFAULT false
);
CREATE TABLE p0_09_fixture.test_progress (
  id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  learner text NOT NULL,
  program text NOT NULL,
  epoch integer NOT NULL,
  payload text NOT NULL
);
CREATE TABLE p0_09_fixture.protected_data (
  kind text NOT NULL,
  learner text NOT NULL,
  payload text NOT NULL,
  PRIMARY KEY (kind,learner)
);
CREATE TABLE p0_09_fixture.one_shot_ticket (
  id bigint PRIMARY KEY,
  program text NOT NULL,
  expected_epoch integer NOT NULL,
  approved_sha text NOT NULL,
  explicit_approval boolean NOT NULL DEFAULT false,
  production_backup_restored boolean NOT NULL DEFAULT false,
  retention_scope_reviewed boolean NOT NULL DEFAULT false,
  expected_target_rows integer NOT NULL CHECK(expected_target_rows >= 0),
  protected_fingerprint text NOT NULL,
  consumed boolean NOT NULL DEFAULT false
);
CREATE TABLE p0_09_fixture.ticket_learners (
  ticket_id bigint NOT NULL REFERENCES p0_09_fixture.one_shot_ticket(id),
  learner text NOT NULL,
  PRIMARY KEY (ticket_id,learner)
);
CREATE TABLE p0_09_fixture.reset_receipt (
  ticket_id bigint PRIMARY KEY REFERENCES p0_09_fixture.one_shot_ticket(id),
  observed_sha text NOT NULL,
  deleted_count integer NOT NULL,
  new_epoch integer NOT NULL
);

INSERT INTO p0_09_fixture.gate(program,epoch,accepting_writes)
VALUES ('math_as_p1_p5',1,true),('economics_as',1,true);
INSERT INTO p0_09_fixture.test_progress(learner,program,epoch,payload) VALUES
('math_u1','math_as_p1_p5',1,'beta answer A'),
('math_u1','math_as_p1_p5',1,'beta answer B'),
('math_u2','math_as_p1_p5',1,'must keep other learner'),
('math_u1','economics_as',1,'must keep other program');
INSERT INTO p0_09_fixture.protected_data(kind,learner,payload) VALUES
('tour','math_u1','tour-score-12'),
('practice','math_u1','practice-history'),
('certificate','math_u2','certificate-proof'),
('ai_entitlement','math_u1','consent-preserved'),
('audit','math_u1','historical-audit-retained');

-- The simulation's identity derives from the actual PostgreSQL SESSION_USER
-- fixture role, not a caller-supplied user ID or mutable custom GUC.
CREATE FUNCTION p0_09_fixture.mock_submit(p_learner text,p_program text,p_epoch int,p_payload text)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $f$
DECLARE v_gate p0_09_fixture.gate%ROWTYPE;
BEGIN
  IF session_user <> 'p0_mock_learner' OR p_learner <> 'math_u1' THEN
    RAISE EXCEPTION 'unauthorized_fixture_learner';
  END IF;
  SELECT * INTO v_gate FROM p0_09_fixture.gate
   WHERE program=p_program FOR SHARE;
  IF NOT FOUND OR NOT v_gate.accepting_writes OR v_gate.epoch <> p_epoch THEN
    RAISE EXCEPTION 'stale_or_paused_epoch';
  END IF;
  INSERT INTO p0_09_fixture.test_progress(learner,program,epoch,payload)
  VALUES (p_learner,p_program,p_epoch,p_payload);
END $f$;

-- Never publicly grant this future-release analogue. One private fixture role
-- may call it; real production will need an independently audited executor.
CREATE FUNCTION p0_09_fixture.mock_release_once(p_ticket_id bigint,p_sha text)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $f$
DECLARE
  v_ticket p0_09_fixture.one_shot_ticket%ROWTYPE;
  v_gate p0_09_fixture.gate%ROWTYPE;
  v_protected text;
  v_count integer;
BEGIN
  IF session_user <> 'p0_mock_release_executor' THEN
    RAISE EXCEPTION 'release_role_denied';
  END IF;
  SELECT * INTO v_ticket FROM p0_09_fixture.one_shot_ticket
    WHERE id=p_ticket_id FOR UPDATE;
  IF NOT FOUND OR v_ticket.consumed
     OR NOT v_ticket.explicit_approval
     OR NOT v_ticket.production_backup_restored
     OR NOT v_ticket.retention_scope_reviewed
     OR v_ticket.program <> 'math_as_p1_p5'
     OR v_ticket.approved_sha <> p_sha
     OR length(p_sha) <> 40 THEN
    RAISE EXCEPTION 'unapproved_or_replayed_release';
  END IF;
  SELECT * INTO v_gate FROM p0_09_fixture.gate
    WHERE program=v_ticket.program FOR UPDATE;
  IF NOT FOUND OR v_gate.epoch <> v_ticket.expected_epoch
     OR v_gate.accepting_writes OR v_gate.active_attempts <> 0
     OR v_gate.unknown_fk_or_schema_drift THEN
    RAISE EXCEPTION 'release_preflight_rejected';
  END IF;
  IF NOT EXISTS(SELECT 1 FROM p0_09_fixture.ticket_learners
    WHERE ticket_id=p_ticket_id) THEN
    RAISE EXCEPTION 'empty_scope_rejected';
  END IF;
  SELECT md5(coalesce(string_agg(kind||':'||learner||':'||payload,'|' ORDER BY kind,learner),''))
    INTO v_protected FROM p0_09_fixture.protected_data;
  IF v_protected <> v_ticket.protected_fingerprint THEN
    RAISE EXCEPTION 'protected_fingerprint_drift';
  END IF;
  SELECT count(*) INTO v_count
  FROM p0_09_fixture.test_progress s
  WHERE s.program=v_ticket.program
    AND s.epoch=v_ticket.expected_epoch
    AND EXISTS(SELECT 1 FROM p0_09_fixture.ticket_learners a
      WHERE a.ticket_id=p_ticket_id AND a.learner=s.learner);
  IF v_count <> v_ticket.expected_target_rows THEN
    RAISE EXCEPTION 'target_count_changed';
  END IF;

  -- Deletion is STRICTLY on fabricated fixture rows, never any app table.
  DELETE FROM p0_09_fixture.test_progress s
  WHERE s.program=v_ticket.program
    AND s.epoch=v_ticket.expected_epoch
    AND EXISTS(SELECT 1 FROM p0_09_fixture.ticket_learners a
      WHERE a.ticket_id=p_ticket_id AND a.learner=s.learner);
  GET DIAGNOSTICS v_count = ROW_COUNT;
  UPDATE p0_09_fixture.gate SET epoch=epoch+1,accepting_writes=true
    WHERE program=v_ticket.program;
  UPDATE p0_09_fixture.one_shot_ticket SET consumed=true
    WHERE id=p_ticket_id;
  INSERT INTO p0_09_fixture.reset_receipt(ticket_id,observed_sha,deleted_count,new_epoch)
  VALUES (p_ticket_id,p_sha,v_count,v_ticket.expected_epoch+1);
  RETURN v_count;
END $f$;

REVOKE ALL ON ALL TABLES IN SCHEMA p0_09_fixture FROM PUBLIC;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA p0_09_fixture FROM PUBLIC;
GRANT EXECUTE ON FUNCTION p0_09_fixture.mock_submit(text,text,int,text) TO p0_mock_learner;
GRANT EXECUTE ON FUNCTION p0_09_fixture.mock_release_once(bigint,text) TO p0_mock_release_executor;

DO $rights$
BEGIN
 IF has_function_privilege('p0_mock_learner',
    'p0_09_fixture.mock_release_once(bigint,text)','EXECUTE')
 OR has_function_privilege('p0_mock_learner',
    'p0_09_fixture.test_progress','DELETE') THEN
    RAISE EXCEPTION 'fixture learner mistakenly receives destructive rights';
 END IF;
 IF has_function_privilege('p0_mock_release_executor',
    'p0_09_fixture.mock_submit(text,text,integer,text)','EXECUTE') THEN
    RAISE EXCEPTION 'release executor may submit learner answers';
 END IF;
END $rights$;

-- Real privileges: learner can submit only through an owner/epoch checked API.
SET SESSION AUTHORIZATION p0_mock_learner;
SELECT p0_09_fixture.mock_submit('math_u1','math_as_p1_p5',1,'beta answer C');
RESET SESSION AUTHORIZATION;

INSERT INTO p0_09_fixture.one_shot_ticket(
  id,program,expected_epoch,approved_sha,expected_target_rows,protected_fingerprint)
SELECT 90,'math_as_p1_p5',1,repeat('a',40),3,
 md5(coalesce(string_agg(kind||':'||learner||':'||payload,'|' ORDER BY kind,learner),''))
FROM p0_09_fixture.protected_data;
INSERT INTO p0_09_fixture.ticket_learners VALUES (90,'math_u1');

-- All release operations are denied until INDEPENDENT gates are satisfied.
SET SESSION AUTHORIZATION p0_mock_release_executor;
DO $negative$
DECLARE denied boolean := false;
BEGIN
  BEGIN
    PERFORM p0_09_fixture.mock_release_once(90,repeat('a',40));
  EXCEPTION WHEN OTHERS THEN
    denied := true;
  END;
  IF NOT denied THEN RAISE EXCEPTION 'missing approval/restore unexpectedly passed'; END IF;
END $negative$;
RESET SESSION AUTHORIZATION;

UPDATE p0_09_fixture.one_shot_ticket SET
 explicit_approval=true,production_backup_restored=true,retention_scope_reviewed=true WHERE id=90;
UPDATE p0_09_fixture.gate SET accepting_writes=false,active_attempts=1
 WHERE program='math_as_p1_p5';

-- Old mobile tab cannot write while maintenance is active.
SET SESSION AUTHORIZATION p0_mock_learner;
DO $maintenance$
DECLARE denied boolean := false;
BEGIN
  BEGIN PERFORM p0_09_fixture.mock_submit('math_u1','math_as_p1_p5',1,'late beta');
  EXCEPTION WHEN OTHERS THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'paused program accepted old beta answer'; END IF;
END $maintenance$;
RESET SESSION AUTHORIZATION;

SET SESSION AUTHORIZATION p0_mock_release_executor;
DO $inflight$
DECLARE denied boolean := false;
BEGIN
  BEGIN PERFORM p0_09_fixture.mock_release_once(90,repeat('a',40));
  EXCEPTION WHEN OTHERS THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'active attempt allowed reset'; END IF;
END $inflight$;
RESET SESSION AUTHORIZATION;

UPDATE p0_09_fixture.gate SET active_attempts=0,unknown_fk_or_schema_drift=true
 WHERE program='math_as_p1_p5';
SET SESSION AUTHORIZATION p0_mock_release_executor;
DO $drift$
DECLARE denied boolean := false;
BEGIN
  BEGIN PERFORM p0_09_fixture.mock_release_once(90,repeat('a',40));
  EXCEPTION WHEN OTHERS THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'unreviewed schema/FK drift allowed reset'; END IF;
END $drift$;
RESET SESSION AUTHORIZATION;
UPDATE p0_09_fixture.gate SET unknown_fk_or_schema_drift=false
 WHERE program='math_as_p1_p5';

-- The wrong SHA cannot authorize release, even with a valid ticket.
SET SESSION AUTHORIZATION p0_mock_release_executor;
DO $sha$
DECLARE denied boolean := false;
BEGIN
  BEGIN PERFORM p0_09_fixture.mock_release_once(90,repeat('b',40));
  EXCEPTION WHEN OTHERS THEN denied := true; END;
  IF NOT denied THEN RAISE EXCEPTION 'wrong release SHA was accepted'; END IF;
END $sha$;
RESET SESSION AUTHORIZATION;

-- Successful single-use release is simulated, then its transaction is rolled
-- back to prove the one-shot receipt, epoch bump and deletion are atomic.
SAVEPOINT before_simulated_release;
SET SESSION AUTHORIZATION p0_mock_release_executor;
SELECT p0_09_fixture.mock_release_once(90,repeat('a',40)) AS expected_deleted_three;
RESET SESSION AUTHORIZATION;
DO $post$
DECLARE v_count integer;
BEGIN
 SELECT count(*) INTO v_count FROM p0_09_fixture.test_progress
   WHERE program='math_as_p1_p5' AND learner='math_u1' AND epoch=1;
 IF v_count<>0 THEN RAISE EXCEPTION 'test beta rows survived approved reset'; END IF;
 IF (SELECT epoch FROM p0_09_fixture.gate WHERE program='math_as_p1_p5')<>2
 OR (SELECT count(*) FROM p0_09_fixture.reset_receipt)<>1 THEN
   RAISE EXCEPTION 'epoch/receipt not atomic';
 END IF;
 IF (SELECT count(*) FROM p0_09_fixture.protected_data)<>5
 OR (SELECT count(*) FROM p0_09_fixture.test_progress WHERE learner='math_u2')<>1
 OR (SELECT count(*) FROM p0_09_fixture.test_progress WHERE program='economics_as')<>1 THEN
   RAISE EXCEPTION 'protected data or other learner/program changed';
 END IF;
END $post$;

SET SESSION AUTHORIZATION p0_mock_release_executor;
DO $replay$
DECLARE denied boolean := false;
BEGIN
 BEGIN PERFORM p0_09_fixture.mock_release_once(90,repeat('a',40));
 EXCEPTION WHEN OTHERS THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'one-shot replay succeeded'; END IF;
END $replay$;
RESET SESSION AUTHORIZATION;

SET SESSION AUTHORIZATION p0_mock_learner;
DO $stale$
DECLARE denied boolean := false;
BEGIN
 BEGIN PERFORM p0_09_fixture.mock_submit('math_u1','math_as_p1_p5',1,'stale old tab');
 EXCEPTION WHEN OTHERS THEN denied := true; END;
 IF NOT denied THEN RAISE EXCEPTION 'old epoch replay succeeded'; END IF;
END $stale$;
SELECT p0_09_fixture.mock_submit('math_u1','math_as_p1_p5',2,'fresh epoch learning');
RESET SESSION AUTHORIZATION;
ROLLBACK TO SAVEPOINT before_simulated_release;

DO $rollback$
BEGIN
 IF (SELECT count(*) FROM p0_09_fixture.test_progress
     WHERE program='math_as_p1_p5' AND learner='math_u1' AND epoch=1)<>3
 OR (SELECT epoch FROM p0_09_fixture.gate WHERE program='math_as_p1_p5')<>1
 OR (SELECT count(*) FROM p0_09_fixture.reset_receipt)<>0
 OR (SELECT consumed FROM p0_09_fixture.one_shot_ticket WHERE id=90) THEN
   RAISE EXCEPTION 'rollback failed to restore original scoped beta state';
 END IF;
 RAISE NOTICE 'PASS P0-09: role denial, approvals/backup, quiescence, drift, exact SHA, one-shot, old epoch rejection, protected other-user/program, atomic rollback';
END $rollback$;
ROLLBACK;
-- Transaction-level ROLLBACK erases all roles, schema, synthetic data and functions.
