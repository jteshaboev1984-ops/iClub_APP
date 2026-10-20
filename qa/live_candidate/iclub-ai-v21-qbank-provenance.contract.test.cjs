"use strict";
const {test}=require("node:test"),assert=require("node:assert/strict"),
 fs=require("node:fs"),path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,p),"utf8");
const old=read("iclub_ai_v21_owner_beta_admission_STAGE_OFF_20261020.sql");
const next=read("iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql");
const stage=read("iclub_ai_v21_practice_70_candidate_staging_20261020.sql");
const scratch=read("iclub-ai-v21-qbank-provenance.pgtest.cjs");
test("Existing 111-card legacy admission predicate is byte-for-byte retained",()=>{
 const begin="FROM private.iclub_ai_v21_owner_beta_source_releases beta";
 const end="AND src.context_key='question_'||q.id::text";
 const extract=t=>t.slice(t.indexOf(begin),t.indexOf(end,t.indexOf(begin))+end.length);
 assert.ok(old.includes(begin)&&next.includes(begin));
 assert.equal(extract(next),extract(old));
});
test("New owner-release gate starts with zero grants and no implied editor signoff",()=>{
 assert.match(next,/CREATE TABLE private\.iclub_ai_v21_qbank_owner_beta_releases/);
 assert.match(next,/enabled boolean NOT NULL DEFAULT false/);
 assert.match(next,/CHECK \(NOT enabled OR released_at IS NOT NULL\)/);
 assert.match(next,/rights_evidence_ref text NOT NULL/);
 assert.match(next,/academic_evidence_ref text NOT NULL/);
 assert.match(next,/locale_evidence_ref text NOT NULL/);
 assert.match(next,/owner_release_ref text NOT NULL/);
 assert.doesNotMatch(next,/INSERT INTO private\.iclub_ai_v21_qbank_owner_beta_releases/);
 assert.doesNotMatch(next,/UPDATE private\.iclub_ai_v21_academic_sources\s+SET/);
 assert.match(next,/count\(\*\) FROM private\.iclub_ai_v21_qbank_owner_beta_releases\)<>0/);
 assert.match(stage,/false,false,false,false,false,true,NULL/);
});
test("Generic path checks real source hashes, subject, question publication and active Practice",()=>{
 for (const fragment of [
  "beta.source_version=src.source_version",
  "beta.content_hash=src.content_hash",
  "beta.target_hash=src.target_hash",
  "beta.subject_key=src.subject_key",
  "beta.locale=src.locale",
  "subject.subject_key=src.subject_key AND subject.is_active",
  "q.is_active AND q.quality_status='published'",
  "btrim(src.body_text)=btrim(CASE src.locale",
  "src.content_hash=encode(extensions.digest(",
  "private.iclub_ai_v21_target_fingerprint_v1(",
  "public.practice_pool_questions pp",
  "count(DISTINCT sibling.locale)",
  "other.content_hash=sibling.content_hash",
  ")=3"
 ]) assert.ok(next.includes(fragment),fragment);
 assert.doesNotMatch(next,/WHERE\s+subject\.subject_key\s*=\s*'(chemistry|economics)'/);
 assert.doesNotMatch(next,/WHERE\s+q\.id\s+IN\s*\(/);
});
test("No client-readable owner grants, no provider call or learner academic writes",()=>{
 assert.match(next,/REVOKE ALL ON TABLE private\.iclub_ai_v21_qbank_owner_beta_releases[\s\S]+?service_role/);
 assert.match(next,/REVOKE ALL ON FUNCTION private\.iclub_ai_v21_source_admitted_v1/);
 assert.doesNotMatch(next,/GRANT (SELECT|INSERT|UPDATE) ON TABLE/);
 assert.doesNotMatch(next,/OPENAI_API_KEY|https:\/\/api\.openai\.com|public\.practice_attempts|INSERT INTO public\.questions|UPDATE public\.questions|DELETE FROM/);
 assert.match(scratch,/PGDATABASE\?\.startsWith\("iclub_ai_v21_scratch_"\)/);
 for (const failure of [
   "Partial localization release leaked","Revoked locale still exposed",
   "Tampered source body was admitted","Version drift not blocked",
   "Stale question fingerprint not blocked","Removed Practice source still admitted"
 ]) assert.ok(scratch.includes(failure));
});

test("Read-only editorial preflight never confuses metadata correctness with formal approval",()=>{
 const preflight=read("iclub_ai_v21_qbank_editorial_preflight_READ_ONLY_20261020.sql");
 assert.match(preflight,/STRICTLY SELECT ONLY/);
 assert.match(preflight,/PENDING_HUMAN_ACADEMIC_RIGHTS_LOCALE_AND_OWNER_RELEASE/);
 assert.match(preflight,/private\.iclub_ai_v21_target_fingerprint_v1/);
 assert.match(preflight,/private\.iclub_ai_v21_source_admitted_v1/);
 assert.match(preflight,/still_unapproved/);
 assert.match(preflight,/admitted_unexpected/);
 assert.match(preflight,/no_legacy_beta_release/);
 assert.match(preflight,/metadata_preflight_ok/);
 assert.doesNotMatch(preflight,/(?:^|\n)\s*(?:UPDATE|INSERT|DELETE|DROP|TRUNCATE|ALTER|CREATE|GRANT|REVOKE|CALL|DO)\b/im);
 assert.doesNotMatch(preflight,/\b(user_id|student_id|practice_answers|practice_sessions_v4|academic_deliveries)\b/i);
});
test("70-row editorial issue queue is explicitly unapproved, with 8 actionable findings",()=>{
 const csv=read("../../docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv");
 const lines=csv.trim().split(/\r?\n/),headers=lines[0].split(",");
 assert.equal(lines.length,71);
 for(const header of ["academic_review","rights_review","en_ru_uz_equivalence",
 "independent_editorial_publication","owner_beta_release","precheck_issues_severity",
 "remediation_instruction"])assert.ok(headers.includes(header),header);
 const flagged=lines.slice(1).filter(line=>/,"(MEDIUM|LOW)","/.test(line));
 assert.equal(flagged.length,8);
 for(const id of ["9241","10063","10073","10077","10081","10095","9465","9723"]){
   assert.ok(flagged.some(x=>x.includes(',"'+id+'",')),id);
 }
 for(const line of lines.slice(1)){
   assert.match(line,/"PENDING","PENDING","PENDING","PENDING","PENDING","NOT_APPROVED","NOT_AUTHORIZED"/);
 }
 assert.doesNotMatch(csv,/,"APPROVED","APPROVED"/);
});

test("Closed three-language editorial revision preserves immutable history without runtime grants",()=>{
 const sql=read("iclub_ai_v21_source_revision_history_QA_ONLY_UNAPPLIED_20261020.sql");
 const negative=read("iclub_ai_v21_revision_ledger_SCRATCH_TEST_ONLY_20261020.sql");
 for(const s of [
  "CREATE TABLE private.iclub_ai_v21_source_revision_archive",
  "BEFORE UPDATE OR DELETE",
  "CREATE FUNCTION private.iclub_ai_v21_stage_three_locale_revision_v1",
  "p_new_version",
  "FOR UPDATE",
  "private.iclub_ai_v21_academic_deliveries",
  "private.iclub_ai_v21_qbank_owner_beta_releases",
  "private.iclub_ai_v21_source_admitted_v1",
  "source_card_key=v_new_key",
  "published=false,revoked=true,approved_at=NULL",
  "REVOKE ALL ON FUNCTION private.iclub_ai_v21_stage_three_locale_revision_v1"
 ])assert.ok(sql.includes(s),s);
 assert.doesNotMatch(sql,/GRANT EXECUTE ON FUNCTION|UPDATE public.questions|DELETE FROM public.questions/);
 for(const s of ["Stale source version","Partial locale set admitted","Archived history was mutable",
  "Old released sources changed","Delivered source overwritten"])assert.ok(negative.includes(s),s);
});
