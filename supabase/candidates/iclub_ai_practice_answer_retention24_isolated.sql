-- A disposable PG17 wrapper for the ACTUAL candidate daily-cleanup SQL.
-- This test never modifies production or registers a real scheduled task.
DO $isolated$
BEGIN
 IF current_setting('iclub.isolated_practice_context',true) IS DISTINCT FROM 'true'
 THEN RAISE EXCEPTION 'REFUSED: daily cleanup rehearsal only in disposable PG17'; END IF;
END $isolated$;

-- Local cron.schedule stub to verify the name, daily cadence and SQL body.
-- pg_cron is already installed on production; no additional dependency.
CREATE SCHEMA cron;
CREATE TABLE cron.iclub_ai_daily_cleanup_schedule_test(
 job_name text PRIMARY KEY, schedule text NOT NULL, command text NOT NULL
);
CREATE FUNCTION cron.schedule(job_name text, schedule text, command text)
RETURNS bigint LANGUAGE plpgsql AS $stub$
BEGIN
 INSERT INTO cron.iclub_ai_daily_cleanup_schedule_test
 VALUES(job_name,schedule,command)
 ON CONFLICT (job_name) DO UPDATE SET
 schedule=excluded.schedule,command=excluded.command;
 RETURN 1;
END;
$stub$;

\ir iclub_ai_practice_answer_daily_cleanup_v1.sql
