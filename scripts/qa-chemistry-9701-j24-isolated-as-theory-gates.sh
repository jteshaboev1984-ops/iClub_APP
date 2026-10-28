#!/usr/bin/env bash
# Synthetic, disposable PostgreSQL 17 only. Never read live Supabase.
set -Eeuo pipefail
[[ "${GITHUB_ACTIONS:-}" == true && "${PGHOST:-}" == 127.0.0.1 &&
   "${PGPORT:-}" == 5432 && "${PGUSER:-}" == postgres &&
   "${PGPASSWORD:-}" == postgres ]] || { echo 'Unsafe test environment'; exit 51; }
[[ -z "${DATABASE_URL:-}" && -z "${SUPABASE_DB_URL:-}" &&
   -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]] || { echo 'External credentials forbidden'; exit 52; }
psql -X -v ON_ERROR_STOP=1 -d postgres <<'SQL' >/dev/null
CREATE ROLE authenticated NOLOGIN;
CREATE ROLE anon NOLOGIN;
CREATE SCHEMA private;
CREATE SCHEMA auth;
CREATE TABLE auth.users(id uuid PRIMARY KEY);
INSERT INTO auth.users VALUES ('10000000-0000-4000-8000-000000000001'),('20000000-0000-4000-8000-000000000002');
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE AS $$
 SELECT NULLIF(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
CREATE FUNCTION auth.role() RETURNS text LANGUAGE sql STABLE AS $$
 SELECT current_setting('request.jwt.claim.role',true) $$;
CREATE FUNCTION auth.jwt() RETURNS jsonb LANGUAGE sql STABLE AS $$
 SELECT jsonb_build_object('is_anonymous',coalesce(current_setting('request.jwt.claim.is_anonymous',true),'false')) $$;
CREATE TABLE private.iclub_exam_chemistry_j12_release_gate_v1
 (source_snapshot_md5 text);
INSERT INTO private.iclub_exam_chemistry_j12_release_gate_v1 VALUES (md5('synthetic-source'));
CREATE TABLE private.iclub_exam_chemistry_p1_beta_members_v1
 (user_id uuid PRIMARY KEY, active boolean, consented_at timestamptz,
  owner_approved_at timestamptz, revoked_at timestamptz);
CREATE TABLE private.iclub_exam_core_skills_v1
 (program_key text,version_key text,library_subject_key text,library_version_key text,
  skill_key text PRIMARY KEY,level_code text,content_hash text);
CREATE TABLE private.iclub_subject_library_theory
 (subject_key text,version_key text,skill_key text PRIMARY KEY,tour_no integer,
  syllabus_point text,content_hash text,locales jsonb);
CREATE FUNCTION private.iclub_exam_chemistry_p1_math_beta_eligible_v1(p_user uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
 SELECT p_user='10000000-0000-4000-8000-000000000001'::uuid $$;
CREATE FUNCTION private.iclub_ai_has_active_protected_assessment_v1(p_user uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO '' AS $$
 SELECT current_setting('request.jwt.claim.active_exam',true)='true' $$;
INSERT INTO private.iclub_exam_chemistry_p1_beta_members_v1 VALUES
 ('10000000-0000-4000-8000-000000000001',true,now(),now(),null);
WITH fixture AS (
 SELECT 'CHEM9701-'||lpad(n::text,2,'0')||'-01' skill_key,
   ((n-1)/19)+1 tour,md5('theory-'||n) hash,n
 FROM generate_series(1,91) n
)
INSERT INTO private.iclub_exam_core_skills_v1
SELECT 'chemistry_9701','chemistry_2025_2027_v1',
       'chemistry','chemistry9701_20261022_stageb_draft',skill_key,'AS',hash FROM fixture;
WITH fixture AS (
 SELECT 'CHEM9701-'||lpad(n::text,2,'0')||'-01' skill_key,
   ((n-1)/19)+1 tour,md5('theory-'||n) hash,n
 FROM generate_series(1,91) n
)
INSERT INTO private.iclub_subject_library_theory
SELECT 'chemistry','chemistry9701_20261022_stageb_draft',skill_key,tour,
 CASE WHEN n=10 THEN 'NO_EXPLICIT_9701_OUTCOME' ELSE 'SYNTHETIC.1' END,
 hash,jsonb_build_object(
  'en',jsonb_build_object('title','Synthetic chemistry topic '||n,'explanation',repeat('Educational explanation. ',9)),
  'ru',jsonb_build_object('title','Тестовая тема '||n,'explanation',repeat('Проверка содержания. ',9)),
  'uz',jsonb_build_object('title','Sinov mavzusi '||n,'explanation',repeat('Tushuntirish va tekshiruv. ',9)))
FROM fixture;
INSERT INTO private.iclub_exam_core_skills_v1 VALUES
 ('chemistry_9701','chemistry_2025_2027_v1',
  'chemistry','chemistry9701_20261022_stageb_draft','CHEM9701-99-01','A',md5('secret-A'));
INSERT INTO private.iclub_subject_library_theory VALUES
 ('chemistry','chemistry9701_20261022_stageb_draft','CHEM9701-99-01',6,
  'A_SCORED',md5('secret-A'),
  jsonb_build_object('en',jsonb_build_object('title','A Level only','explanation',repeat('Restricted A-level explanation. ',9))));
SQL

psql -X -v ON_ERROR_STOP=1 -d postgres -f scripts/chemistry-9701-j24-as-theory-private-gated-api-v1.sql >/dev/null
psql -X -v ON_ERROR_STOP=1 -d postgres -f supabase/migrations/20261028153500_chemistry_9701_j25_as_theory_voluntary_consent_v1.sql >/dev/null
psql -X -v ON_ERROR_STOP=1 -d postgres <<'SQL'
DO $$
BEGIN
 IF has_function_privilege('anon','public.iclub_exam_chemistry_j24_theory_catalog_v1(text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_j24_theory_lesson_v1(text,text)','EXECUTE')
 THEN RAISE EXCEPTION 'Anon must not access AS Theory APIs'; END IF;
 IF NOT has_function_privilege('authenticated','public.iclub_exam_chemistry_j24_theory_catalog_v1(text)','EXECUTE')
 THEN RAISE EXCEPTION 'Authenticated RPC grant is missing'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j24_as_theory_control_v1 WHERE enabled)
 THEN RAISE EXCEPTION 'Default source gate must be OFF'; END IF;
 IF EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j25_as_theory_optins_v1)
 OR EXISTS(SELECT 1 FROM private.iclub_exam_chemistry_j25_as_theory_control_v1 WHERE release_phase<>'closed')
 THEN RAISE EXCEPTION 'J25 must have no automatic users or invitations'; END IF;
 IF has_function_privilege('anon','public.iclub_exam_chemistry_j25_grant_theory_consent_v1(text,text)','EXECUTE')
 OR has_function_privilege('anon','public.iclub_exam_chemistry_j25_revoke_theory_consent_v1()','EXECUTE')
 THEN RAISE EXCEPTION 'Anonymous J25 access must be denied'; END IF;
END $$;
-- Synthetic JWT identity and exact beta permission, but gate OFF.
SET request.jwt.claim.sub='10000000-0000-4000-8000-000000000001';
SET request.jwt.claim.role='authenticated';
SET ROLE authenticated;
DO $$
BEGIN
 IF (public.iclub_exam_chemistry_j24_theory_catalog_v1('en')->>'code')<>'not_available'
 THEN RAISE EXCEPTION 'Enabled read before owner review'; END IF;
END $$;
RESET ROLE;

-- No implicit enrollment from Mathematics: manually invite exactly one synthetic canary.
INSERT INTO private.iclub_exam_chemistry_j25_as_theory_optins_v1
 (user_id,invited_at,is_canary)
VALUES('10000000-0000-4000-8000-000000000001',now(),true);
SET ROLE authenticated;
DO $
BEGIN
 IF public.iclub_exam_chemistry_j25_grant_theory_consent_v1(
  'en','I_VOLUNTARILY_AGREE_TO_CHEMISTRY_AS_THEORY_BETA_V1')->>'code'<>'consent_recorded'
 THEN RAISE EXCEPTION 'Independent AS Theory consent failed'; END IF;
 IF public.iclub_exam_chemistry_j25_theory_consent_status_v1()->>'can_start'<>'false'
 THEN RAISE EXCEPTION 'Consent itself unlocked closed Theory'; END IF;
END $;
RESET ROLE;
UPDATE private.iclub_exam_chemistry_j25_as_theory_optins_v1
 SET owner_approved_at=now(),active=true WHERE is_canary=true AND consented_at IS NOT NULL;
UPDATE private.iclub_exam_chemistry_j25_as_theory_control_v1
 SET release_phase='canary',owner_go_at=now() WHERE id=1;
SET ROLE authenticated;
DO $
BEGIN
 IF public.iclub_exam_chemistry_j25_grant_theory_consent_v1(
  'en','I_VOLUNTARILY_AGREE_TO_CHEMISTRY_AS_THEORY_BETA_V1')->>'code'<>'already_recorded'
 THEN RAISE EXCEPTION 'Repeating consent must be idempotent'; END IF;
END $;
RESET ROLE;

-- Simulate later explicit academic/rights/owner approvals IN DISPOSABLE DATABASE ONLY.
UPDATE private.iclub_exam_chemistry_j24_as_theory_control_v1
SET enabled=true,owner_go_at=now(),academic_science_review_at=now(),
 trilingual_review_at=now(),rights_owner_attestation_at=now(),
 owner_backup_deferral_at=now(),
 approved_version='chemistry9701_20261022_stageb_draft',
 approved_source_md5=md5('synthetic-source'),
 approved_as_manifest_md5=(
 SELECT md5(string_agg(s.skill_key||':'||t.content_hash,'|' ORDER BY s.skill_key))
 FROM private.iclub_exam_core_skills_v1 s
 JOIN private.iclub_subject_library_theory t ON t.skill_key=s.skill_key
 WHERE s.level_code='AS'
 ),
 approved_skill_count=91,reviewed_evidence_ref='synthetic-ci-91-reviewed-items-j24'
WHERE id=1;
SET ROLE authenticated;
DO $$
DECLARE r jsonb; l jsonb;
BEGIN
 r=public.iclub_exam_chemistry_j24_theory_catalog_v1('en');
 IF r->>'ok'<>'true' OR r->>'count'<>'91'
  OR jsonb_array_length(r->'items')<>91
  OR (SELECT count(*) FROM jsonb_array_elements(r->'items') x
      WHERE (x->>'is_syllabus_outcome')::boolean=false)<>1
  OR r ? 'tutor' OR r ? 'answer_key'
 THEN RAISE EXCEPTION 'AS-only catalog contract failed: %',r; END IF;
 l=public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-01-01','ru');
 IF l->>'ok'<>'true' OR l->>'can_credit_mastery'<>'false'
  OR l ? 'tutor' OR l ? 'answer_key'
 THEN RAISE EXCEPTION 'AS-only lesson contract failed'; END IF;
 IF public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-99-01','en')->>'code'<>'not_available'
 THEN RAISE EXCEPTION 'A Level access leak'; END IF;
 IF public.iclub_exam_chemistry_j24_theory_lesson_v1('CHEM9701-01-01','de')->>'code'<>'invalid_request'
 THEN RAISE EXCEPTION 'Invalid locale incorrectly accepted'; END IF;
END $$;
SET request.jwt.claim.active_exam='true';
DO $$
BEGIN
 IF public.iclub_exam_chemistry_j24_theory_catalog_v1('ru')->>'code'<>'not_available'
 THEN RAISE EXCEPTION 'Theory exposed during active protected exam'; END IF;
END $$;
SET request.jwt.claim.active_exam='false';
RESET ROLE;
SET ROLE authenticated;
DO $
BEGIN
 IF public.iclub_exam_chemistry_j25_revoke_theory_consent_v1()->>'ok'<>'true'
 THEN RAISE EXCEPTION 'AS Theory consent revocation failed'; END IF;
 IF public.iclub_exam_chemistry_j24_theory_catalog_v1('en')->>'code'<>'not_available'
 THEN RAISE EXCEPTION 'Revoked learner still authorized'; END IF;
END $;
RESET ROLE;
UPDATE private.iclub_exam_chemistry_j25_as_theory_optins_v1
 SET revoked_at=NULL,consented_at=now(),owner_approved_at=now(),active=true
 WHERE is_canary=true;
UPDATE private.iclub_exam_chemistry_j24_as_theory_control_v1
SET approved_as_manifest_md5=md5('stale') WHERE id=1;
SET ROLE authenticated;
DO $$
BEGIN
 IF public.iclub_exam_chemistry_j24_theory_catalog_v1('en')->>'code'<>'not_available'
 THEN RAISE EXCEPTION 'Stale content manifest was accepted'; END IF;
END $$;
RESET ROLE;
UPDATE private.iclub_exam_chemistry_j24_as_theory_control_v1 SET enabled=false;
SELECT 'J24/J25 isolated AS-only Theory + voluntary canary consent firewall PASS (disposable data only)' as outcome;
SQL
