#!/usr/bin/env bash
# J-22: physically dump and restore SYNTHETIC production-shaped academic records in disposable CI only.
# Never connects to Supabase and never loads/export actual learner records.
set -Eeuo pipefail
[[ "${GITHUB_ACTIONS:-}" == "true" ]] || { echo "Requires isolated GitHub Actions"; exit 31; }
[[ "${PGHOST:-}" == "127.0.0.1" && "${PGPORT:-}" == "5432" ]] || { echo "Remote PostgreSQL is forbidden"; exit 32; }
[[ "${PGUSER:-}" == "postgres" && "${PGDATABASE:-}" == "postgres" ]] || { echo "Unexpected PostgreSQL role/db"; exit 33; }
[[ "${PGPASSWORD:-}" == "postgres" ]] || { echo "Only disposable test database credentials allowed"; exit 34; }
[[ -z "${DATABASE_URL:-}" && -z "${SUPABASE_DB_URL:-}" && -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]] || { echo "Forbidden production credentials"; exit 35; }

source_db=iclub_j22_source
restored_db=iclub_j22_restored
testlog=/tmp/iclub-j22-restore-result.txt
snapshot=/tmp/iclub-j22-synthetic.dump
test -z "$(psql -X -Atqc "select datname from pg_database where datname in ('$source_db','$restored_db')" postgres)" || {
  echo "Disposable database names already exist. Refusing overwrite."; exit 36;
}
psql -X -v ON_ERROR_STOP=1 -d postgres -c "CREATE DATABASE $source_db;" >/dev/null
psql -X -v ON_ERROR_STOP=1 -d postgres -c "CREATE DATABASE $restored_db;" >/dev/null

psql -X -v ON_ERROR_STOP=1 -d "$source_db" <<'SQL' >/dev/null
CREATE SCHEMA private;
CREATE TABLE private.exam_prep_responses (
  id uuid PRIMARY KEY, session_id uuid NOT NULL, item_order smallint NOT NULL,
  user_id uuid NOT NULL, client_idempotency_key text NOT NULL,
  response_kind text NOT NULL, user_answer text, picked_index integer,
  learner_artifact jsonb, selected_answer text, is_correct boolean,
  evaluator_version text NOT NULL, elapsed_ms integer, answered_at timestamptz NOT NULL,
  UNIQUE(session_id,client_idempotency_key)
);
CREATE TABLE public.practice_attempts (
  id bigint PRIMARY KEY, user_id uuid NOT NULL, subject_id bigint NOT NULL,
  score integer NOT NULL, percent numeric NOT NULL, time_seconds integer NOT NULL,
  created_at timestamptz NOT NULL, is_lab boolean NOT NULL, bank_generation integer
);
CREATE TABLE public.practice_answers (
  id bigint PRIMARY KEY, attempt_id bigint NOT NULL REFERENCES public.practice_attempts(id),
  question_id bigint NOT NULL, user_answer text, is_correct boolean NOT NULL,
  time_spent integer NOT NULL, created_at timestamptz NOT NULL
);
CREATE TABLE private.iclub_subject_library_cross_tour_v1 (
  subject_key text NOT NULL, version_key text NOT NULL, skill_key text NOT NULL,
  source_tour text NOT NULL, level_code text NOT NULL, paper_code text NOT NULL,
  syllabus_point text NOT NULL, content_hash text NOT NULL, locales jsonb NOT NULL,
  tutor_by_locale jsonb NOT NULL, state text NOT NULL, created_at timestamptz NOT NULL,
  PRIMARY KEY(subject_key,version_key,skill_key)
);
CREATE TABLE private.iclub_exam_chemistry_j12_release_gate_v1(
  version_key text PRIMARY KEY, expected_skills integer, theory_skills integer, lab_skills integer,
  armed boolean, owner_explicit_go boolean, rights_reviewed boolean,
  backup_restore_tested boolean, currently_hidden boolean, can_publish boolean
);
CREATE TABLE private.iclub_exam_chemistry_j13_learning_control_v1(
  id smallint PRIMARY KEY CHECK (id=1), paper3_enabled boolean NOT NULL,
  paper5_enabled boolean NOT NULL, tutor_sources_enabled boolean NOT NULL
);
ALTER TABLE private.exam_prep_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.exam_prep_responses FORCE ROW LEVEL SECURITY;
ALTER TABLE public.practice_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_attempts FORCE ROW LEVEL SECURITY;
ALTER TABLE public.practice_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.practice_answers FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_subject_library_cross_tour_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_subject_library_cross_tour_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j12_release_gate_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j12_release_gate_v1 FORCE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j13_learning_control_v1 ENABLE ROW LEVEL SECURITY;
ALTER TABLE private.iclub_exam_chemistry_j13_learning_control_v1 FORCE ROW LEVEL SECURITY;

INSERT INTO private.exam_prep_responses
(id,session_id,item_order,user_id,client_idempotency_key,response_kind,user_answer,
 is_correct,evaluator_version,elapsed_ms,answered_at) VALUES
('10000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',1,
'30000000-0000-4000-8000-000000000001','j22-synthetic-answer-1','text','synthetic math answer',true,'synthetic-v1',18000,'2026-10-28T00:00:00Z'),
('10000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000001',2,
'30000000-0000-4000-8000-000000000001','j22-synthetic-answer-2','text','synthetic corrected answer',false,'synthetic-v1',22000,'2026-10-28T00:01:00Z');
INSERT INTO public.practice_attempts
VALUES (101,'30000000-0000-4000-8000-000000000002',10,1,50,72,'2026-10-28T00:00:00Z',false,2);
INSERT INTO public.practice_answers VALUES
(201,101,501,'A',true,10,'2026-10-28T00:00:01Z'),
(202,101,502,'B',false,11,'2026-10-28T00:00:02Z');
INSERT INTO private.iclub_subject_library_cross_tour_v1
SELECT 'chemistry','chemistry9701_20261022_stageb_draft',
 'CHEM9701-LAB-'||lpad(n::text,2,'0'),'synthetic-tour',
 CASE WHEN n<=6 THEN 'AS' ELSE 'A' END,
 CASE WHEN n<=6 THEN 'P3' ELSE 'P5' END,
 'synthetic-syllabus','synthetic-sha-'||n,
 jsonb_build_object('en',jsonb_build_object('title','Synthetic lesson '||n),
                    'ru',jsonb_build_object('title','Синтетический материал '||n),
                    'uz',jsonb_build_object('title','Sinov materiali '||n)),
 jsonb_build_object('en',jsonb_build_object('text','synthetic'),
                    'ru',jsonb_build_object('text','synthetic'),
                    'uz',jsonb_build_object('text','synthetic')),
 'draft','2026-10-28T00:00:00Z'
FROM generate_series(1,12) n;
INSERT INTO private.iclub_exam_chemistry_j12_release_gate_v1 VALUES
('chemistry9701_20261022_stageb_draft',166,154,12,false,false,false,false,true,false);
INSERT INTO private.iclub_exam_chemistry_j13_learning_control_v1 VALUES(1,false,false,false);

CREATE FUNCTION private.j22_fingerprint() RETURNS text LANGUAGE sql STABLE AS $$
SELECT md5(
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.id),'') FROM private.exam_prep_responses t) || ':' ||
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.id),'') FROM public.practice_attempts t) || ':' ||
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.id),'') FROM public.practice_answers t) || ':' ||
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.skill_key),'') FROM private.iclub_subject_library_cross_tour_v1 t) || ':' ||
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.version_key),'') FROM private.iclub_exam_chemistry_j12_release_gate_v1 t) || ':' ||
  (SELECT coalesce(string_agg(t::text,'|' ORDER BY t.id),'') FROM private.iclub_exam_chemistry_j13_learning_control_v1 t)
);
$$;
SQL

before="$(psql -X -At -d "$source_db" -c 'SELECT private.j22_fingerprint()')"
[[ "$before" =~ ^[0-9a-f]{32}$ ]] || { echo "Source fingerprint is invalid"; exit 41; }
pg_dump --no-owner --no-acl --format=custom -d "$source_db" -f "$snapshot"
test -s "$snapshot"
pg_restore --exit-on-error --no-owner --no-acl --dbname="$restored_db" "$snapshot" >/dev/null
after="$(psql -X -At -d "$restored_db" -c 'SELECT private.j22_fingerprint()')"
[[ "$before" == "$after" ]] || { echo "Restored academic fingerprint mismatch"; exit 42; }
for q in \
 "SELECT count(*)=2 FROM private.exam_prep_responses" \
 "SELECT count(*)=1 FROM public.practice_attempts" \
 "SELECT count(*)=2 FROM public.practice_answers" \
 "SELECT count(*)=12 FROM private.iclub_subject_library_cross_tour_v1" \
 "SELECT count(*)=6 FROM private.iclub_subject_library_cross_tour_v1 WHERE paper_code='P3' AND level_code='AS' AND state='draft'" \
 "SELECT count(*)=6 FROM private.iclub_subject_library_cross_tour_v1 WHERE paper_code='P5' AND level_code='A' AND state='draft'" \
 "SELECT NOT can_publish AND NOT armed AND NOT backup_restore_tested AND currently_hidden FROM private.iclub_exam_chemistry_j12_release_gate_v1" \
 "SELECT NOT paper3_enabled AND NOT paper5_enabled AND NOT tutor_sources_enabled FROM private.iclub_exam_chemistry_j13_learning_control_v1" \
 "SELECT count(*)=6 FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ('public','private') AND c.relname IN ('exam_prep_responses','practice_attempts','practice_answers','iclub_subject_library_cross_tour_v1','iclub_exam_chemistry_j12_release_gate_v1','iclub_exam_chemistry_j13_learning_control_v1') AND c.relrowsecurity AND c.relforcerowsecurity" \
 "SELECT count(*)=1 FROM pg_constraint WHERE contype='f' AND conrelid='public.practice_answers'::regclass" ; do
  [[ "$(psql -X -At -d "$restored_db" -c "$q")" == "t" ]] || { echo "Restored schema, gate, relations or academic data invalid"; exit 43; }
done

# Simulated data loss is made in the synthetic source ONLY. Restored database must remain intact.
psql -X -v ON_ERROR_STOP=1 -d "$source_db" -c "DELETE FROM public.practice_answers WHERE id=202" >/dev/null
[[ "$(psql -X -At -d "$source_db" -c 'SELECT private.j22_fingerprint()')" != "$before" ]] || {
  echo "Synthetic loss simulation did not alter source"; exit 44;
}
[[ "$(psql -X -At -d "$restored_db" -c 'SELECT private.j22_fingerprint()')" == "$before" ]] || {
  echo "Restored copy changed after independent source corruption"; exit 45;
}
printf '%s\n' 'J22 SYNTHETIC POSTGRES BACKUP + SEPARATE DATABASE RESTORE GREEN' \
 'scope=disposable_postgres17_only; real_production_backup_restore=NOT_PROVEN' \
 'tables=6; synthetic_math=2; synthetic_practice_attempts=1; synthetic_practice_answers=2; synthetic_chemistry_lab=12' \
 'rls_force=6/6; foreign_keys=1; chemistry_release_off=true; corrupted_source_isolated=true' \
 'source_and_restored_fingerprint_match=true; no_secrets_or_user_records_exported=true' > "$testlog"
cat "$testlog"
