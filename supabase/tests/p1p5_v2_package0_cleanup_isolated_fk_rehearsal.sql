-- ISOLATED PostgreSQL 17 ONLY. NOT FOR PRODUCTION.
-- Mathematics P1/P5 / Issue #450 / Package 0:
-- Demonstrate real FK RESTRICT cycle, retained-table blocker, targeted
-- learner cleanup, protected other-user/Practice/Tours invariants, replay,
-- and full rollback using synthetic data. This is a SMALL MODEL of the real
-- schema, NOT a rehearsal of all 122 production tables.
\set ON_ERROR_STOP on
BEGIN;
CREATE SCHEMA p1p5_package0_isolated;
SET LOCAL search_path TO p1p5_package0_isolated;

CREATE TABLE learners(id integer PRIMARY KEY);
CREATE TABLE authorizations(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id) ON DELETE RESTRICT,
  consumed_session_id integer NULL
);
CREATE TABLE sessions(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id) ON DELETE RESTRICT,
  authorization_id integer NOT NULL REFERENCES authorizations(id) ON DELETE RESTRICT
);
ALTER TABLE authorizations
  ADD CONSTRAINT authorizations_consumed_session_fk
  FOREIGN KEY(consumed_session_id) REFERENCES sessions(id) ON DELETE RESTRICT;

CREATE TABLE responses(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id) ON DELETE RESTRICT,
  session_id integer NOT NULL REFERENCES sessions(id) ON DELETE RESTRICT
);
CREATE TABLE evidence_events(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id),
  response_id integer NOT NULL REFERENCES responses(id) ON DELETE RESTRICT,
  session_id integer NOT NULL REFERENCES sessions(id) ON DELETE RESTRICT
);
CREATE TABLE correction_cases(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id),
  opened_from_evidence_id integer NOT NULL REFERENCES evidence_events(id) ON DELETE RESTRICT
);
ALTER TABLE authorizations ADD COLUMN correction_case_id integer
  REFERENCES correction_cases(id) ON DELETE RESTRICT;
CREATE TABLE recommendations(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id) ON DELETE RESTRICT
);
CREATE TABLE retained_mentor_queue(
  id integer PRIMARY KEY,
  recommendation_id integer NOT NULL REFERENCES recommendations(id) ON DELETE RESTRICT
);
CREATE TABLE profiles(
  id integer PRIMARY KEY,
  user_id integer NOT NULL REFERENCES learners(id)
);
CREATE TABLE practice_attempts(user_id integer NOT NULL REFERENCES learners(id),id integer PRIMARY KEY);
CREATE TABLE tour_attempts(user_id integer NOT NULL REFERENCES learners(id),id integer PRIMARY KEY);
CREATE TABLE certificates(user_id integer NOT NULL REFERENCES learners(id),id integer PRIMARY KEY);

INSERT INTO learners(id) VALUES (1),(2);
INSERT INTO authorizations(id,user_id) VALUES (11,1),(12,2);
INSERT INTO sessions(id,user_id,authorization_id) VALUES (101,1,11),(102,2,12);
UPDATE authorizations SET consumed_session_id=101 WHERE id=11;
UPDATE authorizations SET consumed_session_id=102 WHERE id=12;
INSERT INTO responses(id,user_id,session_id) VALUES (201,1,101),(202,2,102);
INSERT INTO evidence_events(id,user_id,response_id,session_id)
VALUES (251,1,201,101),(252,2,202,102);
INSERT INTO correction_cases(id,user_id,opened_from_evidence_id)
VALUES (351,1,251),(352,2,252);
UPDATE authorizations SET correction_case_id=351 WHERE id=11;
UPDATE authorizations SET correction_case_id=352 WHERE id=12;
INSERT INTO recommendations(id,user_id) VALUES (301,1),(302,2);
INSERT INTO retained_mentor_queue(id,recommendation_id) VALUES (401,302);
INSERT INTO profiles(id,user_id) VALUES (501,1),(502,2);
INSERT INTO practice_attempts(id,user_id) VALUES (601,1),(602,2);
INSERT INTO tour_attempts(id,user_id) VALUES (701,1),(702,2);
INSERT INTO certificates(id,user_id) VALUES (801,1),(802,2);

SAVEPOINT before_cleanup;
-- Negative: deleting active parent before unlinking authorizations fails closed.
DO $$
BEGIN
  BEGIN
    DELETE FROM sessions WHERE id=101;
    RAISE EXCEPTION 'FAIL: cyclic RESTRICT link did not reject early session deletion';
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'PASS: early session delete rejected by real PostgreSQL FK';
  END;
END $$;
-- Negative: a retained Mentor queue link forbids deleting its recommendation.
SAVEPOINT mentor_blocker;
INSERT INTO retained_mentor_queue(id,recommendation_id) VALUES (403,301);
DO $$
BEGIN
  BEGIN
    DELETE FROM recommendations WHERE id=301;
    RAISE EXCEPTION 'FAIL: retained mentor link did not block recommendation deletion';
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'PASS: retained Mentor queue FK blocks deletion';
  END;
END $$;
ROLLBACK TO SAVEPOINT mentor_blocker;

-- Negative: even if the direct session link is detached, the other
-- authorization -> correction -> evidence -> response -> session cycle
-- keeps correction cases protected until the second nullable FK is detached.
SAVEPOINT correction_blocker;
UPDATE authorizations SET consumed_session_id=NULL WHERE user_id=1;
DO $$
BEGIN
  BEGIN
    DELETE FROM correction_cases WHERE id=351;
    RAISE EXCEPTION 'FAIL: second real FK cycle did not reject correction deletion';
  EXCEPTION WHEN foreign_key_violation THEN
    RAISE NOTICE 'PASS: second correction/evidence/session cycle requires separate unlink';
  END;
END $$;
ROLLBACK TO SAVEPOINT correction_blocker;

-- Positive targeted cleanup: explicit unlink, then leaves to root, only user 1.
UPDATE authorizations
SET consumed_session_id=NULL,correction_case_id=NULL WHERE user_id=1;
DELETE FROM correction_cases WHERE user_id=1;
DELETE FROM evidence_events WHERE user_id=1;
DELETE FROM responses WHERE user_id=1;
DELETE FROM sessions WHERE user_id=1;
DELETE FROM authorizations WHERE user_id=1;
DELETE FROM recommendations WHERE user_id=1;
DELETE FROM profiles WHERE user_id=1;

DO $$
BEGIN
  IF (SELECT count(*) FROM learners)<>2 OR
     (SELECT count(*) FROM practice_attempts)<>2 OR
     (SELECT count(*) FROM tour_attempts)<>2 OR
     (SELECT count(*) FROM certificates)<>2 OR
     (SELECT count(*) FROM authorizations WHERE user_id=2)<>1 OR
     (SELECT count(*) FROM sessions WHERE user_id=2)<>1 OR
     (SELECT count(*) FROM responses WHERE user_id=2)<>1 OR
     (SELECT count(*) FROM evidence_events WHERE user_id=2)<>1 OR
     (SELECT count(*) FROM correction_cases WHERE user_id=2)<>1 OR
     (SELECT count(*) FROM retained_mentor_queue)<>1 OR
     (SELECT count(*) FROM profiles WHERE user_id=1)<>0 OR
     (SELECT count(*) FROM sessions WHERE user_id=1)<>0 OR
     (SELECT count(*) FROM authorizations WHERE user_id=1)<>0 OR
     (SELECT count(*) FROM recommendations WHERE user_id=1)<>0 OR
     (SELECT count(*) FROM correction_cases WHERE user_id=1)<>0 OR
     (SELECT count(*) FROM evidence_events WHERE user_id=1)<>0
  THEN RAISE EXCEPTION 'FAIL: cleanup preservation or target scope mismatch'; END IF;
  RAISE NOTICE 'PASS: math test-state cleared, non-target and protected app state preserved';
END $$;

-- Positive: replay same targeted cleanup is idempotent.
UPDATE authorizations
SET consumed_session_id=NULL,correction_case_id=NULL WHERE user_id=1;
DELETE FROM correction_cases WHERE user_id=1;
DELETE FROM evidence_events WHERE user_id=1;
DELETE FROM responses WHERE user_id=1;
DELETE FROM sessions WHERE user_id=1;
DELETE FROM authorizations WHERE user_id=1;
DELETE FROM recommendations WHERE user_id=1;
DELETE FROM profiles WHERE user_id=1;

-- Restore all artificially cleaned data, ensuring rollback is genuine.
ROLLBACK TO SAVEPOINT before_cleanup;
DO $$
BEGIN
  IF (SELECT count(*) FROM authorizations)<>2 OR
     (SELECT count(*) FROM sessions)<>2 OR
     (SELECT count(*) FROM responses)<>2 OR
     (SELECT count(*) FROM evidence_events)<>2 OR
     (SELECT count(*) FROM correction_cases)<>2 OR
     (SELECT count(*) FROM recommendations)<>2 OR
     (SELECT count(*) FROM profiles)<>2 OR
     (SELECT count(*) FROM practice_attempts)<>2 OR
     (SELECT count(*) FROM tour_attempts)<>2 OR
     (SELECT count(*) FROM certificates)<>2 OR
     (SELECT count(*) FROM authorizations WHERE user_id=1 AND consumed_session_id=101 AND correction_case_id=351)<>1
  THEN RAISE EXCEPTION 'FAIL: test-only rollback did not restore original model'; END IF;
  RAISE NOTICE 'PASS: full test-only rollback restored all original rows';
END $$;
ROLLBACK;
