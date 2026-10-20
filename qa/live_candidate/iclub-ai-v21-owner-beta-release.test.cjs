"use strict";
const {test}=require("node:test"),a=require("node:assert/strict"),fs=require("node:fs"),path=require("node:path");
const read=p=>fs.readFileSync(path.join(__dirname,p),"utf8");
const stage=read("iclub_ai_v21_owner_beta_admission_STAGE_OFF_20261020.sql");
const activation=read("iclub_ai_v21_owner_beta_ACTIVATE_20261020.sql");
const rollback=read("iclub_ai_v21_owner_beta_PAUSE_20261020.sql");
const adapter=read("iclub-ai-v21-browser-adapter.js");
const edge=read("iclub-ai-v21-prepared/index.ts");
const shell=fs.readFileSync(path.join(__dirname,"../ai-v21-real-preview-ui-snapshot.js"),"utf8");
test("Independent owner-beta admission never impersonates four human review approvals",()=>{
 a.match(stage,/owner_authorized_closed_beta_20261020/);
 a.match(stage,/CREATE TABLE private\.iclub_ai_v21_owner_beta_source_releases/);
 a.match(stage,/source_card_key text PRIMARY KEY/);
 a.match(stage,/release_basis text NOT NULL/);
 a.match(stage,/src\.surface_code='practice_error' AND NOT src\.published AND src\.revoked/);
 a.match(stage,/NOT src\.content_reviewed AND NOT src\.rights_reviewed/);
 a.match(stage,/NOT src\.locale_reviewed AND NOT src\.academic_qa_passed/);
 a.match(stage,/src\.approved_at IS NULL/);
 a.match(stage,/legacy\.approval_status='approved'/);
 a.match(stage,/legacy\.rights_status='original_iclub'/);
 a.match(stage,/legacy\.body_text=src\.body_text/);
 a.match(stage,/beta\.source_version=src\.source_version/);
 a.match(stage,/beta\.content_hash=src\.content_hash/);
 a.match(stage,/beta\.target_hash=src\.target_hash/);
 a.doesNotMatch(stage,/UPDATE private\.iclub_ai_v21_academic_sources\s+SET/);
});
test("Exact wrong-question / subject / signed-owner / protected exam gates survive admission change",()=>{
 for(const s of ["ps.legacy_attempt_id=pa.id",
  "ps.status='finalized'","answer.answered_at IS NOT NULL",
  "answer.is_correct IS FALSE","pa.user_id=p_user_id",
  "enrolled.user_id=p_user_id",
  "private.iclub_ai_has_active_protected_assessment_v1",
  "private.iclub_subscription_entitlements",
  "source.target_hash IS DISTINCT FROM",
  "source.content_hash",
  "usage.committed_count>=3",
  "private.iclub_ai_v21_beta_members",
  "private.iclub_ai_v21_academic_deliveries"])
  a.ok(stage.includes(s),"Missing hard boundary: "+s);
 a.match(stage,/REVOKE ALL ON FUNCTION public\.deliver_iclub_ai_v21_academic_service/);
 a.match(stage,/TO service_role/);
 a.doesNotMatch(stage,/GRANT EXECUTE ON FUNCTION public\.deliver_iclub_ai_v21_academic_service[\s\S]+?\bTO authenticated/);
});
test("No subject-list routing, and all three discoverable surfaces share one admission policy",()=>{
 a.equal((stage.match(/private\.iclub_ai_v21_source_admitted_v1\(src\)/g)||[]).length,3);
 a.equal((stage.match(/private\.iclub_ai_v21_source_admitted_v1\(source\)/g)||[]).length,1);
 a.match(stage,/p_surface='tour_archive'/);
 a.match(stage,/p_surface='lesson_topic'/);
 a.match(stage,/src\.target_hash=private\.iclub_ai_v21_target_fingerprint_v1/);
 a.match(edge,/get_iclub_ai_v21_academic_capabilities_service/);
 a.match(edge,/deliver_iclub_ai_v21_academic_service/);
 a.match(edge,/p_user_id:authenticated\.id/);
 a.match(adapter,/availableAcademic/);
 a.match(adapter,/askAcademic/);
 a.match(shell,/explainAcademic/);
 a.doesNotMatch(stage,/WHERE subject_key\s*=\s*'(chemistry|economics)'/);
});
test("Activation admits only opted-in cohort; no paid generation and no grades/Math writes",()=>{
 a.match(activation,/count\(\*\) FROM private\.iclub_ai_v21_beta_members/);
 a.match(activation,/NOT enabled AND NOT provider_enabled/);
 a.match(activation,/owner_beta_source_releases/);
 a.match(activation,/private\.iclub_ai_v21_source_admitted_v1/);
 a.match(activation,/UPDATE private\.iclub_ai_v21_academic_policy SET enabled=true/);
 a.match(activation,/generation_enabled/);
 a.doesNotMatch(stage+activation,/OPENAI_API_KEY|api\.openai\.com|signUp\(/);
 a.doesNotMatch(stage+activation,/UPDATE public\.(?:questions|practice_attempts|practice_sessions_v4|tour_attempts)/);
 a.doesNotMatch(stage+activation,/\bTRUNCATE\b|\bDELETE FROM\b|\bDROP TABLE\b/);
});
test("Single reversible stop independent of Math Tutor and existing prepared Help",()=>{
 a.match(rollback,/UPDATE private\.iclub_ai_v21_academic_policy SET enabled=false/);
 a.match(rollback,/UPDATE private\.iclub_ai_v21_owner_beta_source_releases SET enabled=false/);
 a.doesNotMatch(rollback,/practice_sessions|exam_prep|iclub_ai_v21_beta_control|DELETE FROM|TRUNCATE/);
});
