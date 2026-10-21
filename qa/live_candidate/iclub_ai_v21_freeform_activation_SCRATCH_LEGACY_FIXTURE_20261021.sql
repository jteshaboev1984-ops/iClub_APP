-- disposable-scratch ONLY: never run against live Supabase.
CREATE TABLE private.iclub_ai_v21_academic_sources(
 source_card_key text PRIMARY KEY, admitted boolean NOT NULL);
INSERT INTO private.iclub_ai_v21_academic_sources
SELECT 'synthetic_existing_beta_'||n,true FROM generate_series(1,111) AS n;
CREATE FUNCTION private.iclub_ai_v21_source_admitted_v1(
  p_source private.iclub_ai_v21_academic_sources)
RETURNS boolean LANGUAGE sql STABLE SET search_path=''
AS $sql$ SELECT (p_source).admitted $sql$;
CREATE TABLE private.iclub_ai_v21_qbank_owner_beta_releases(
 synthetic_key text PRIMARY KEY);
CREATE TABLE private.iclub_ai_v21_qbank_signed_review_receipts(
 synthetic_key text PRIMARY KEY);
