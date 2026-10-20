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
 for(const s of ["Old version admitted for overwrite","Partial locale set admitted","Archived history was mutable",
  "Old released sources changed","Delivered source overwritten"])assert.ok(negative.includes(s),s);
});

test("Trilingual reviewed-content proposal remains a hash-pinned unapproved draft",()=>{
 const p=JSON.parse(read("../../docs/iclub-ai-v21-3-trilingual-curated-content-proposals-20261020.json"));
 assert.equal(p.status,"NOT_APPROVED_NOT_STAGED_NOT_RELEASED");
 assert.equal(p.owner_release,"NOT_AUTHORIZED");
 for(const k of ["editorial_reviewer","rights_reviewer","language_reviewer"])
  assert.equal(p[k],"PENDING");
 assert.equal(p.cards.length,3);
 assert.deepEqual(p.cards.map(x=>x.question_id).sort((a,b)=>a-b),[9465,9723,10095]);
 for(const c of p.cards){
  assert.match(c.target_hash,/^[a-f0-9]{64}$/);
  assert.equal(c.source_version_current,"qbank_exact_explanation_draft_v1");
  assert.equal(Object.keys(c.translations).sort().join(","),"en,ru,uz");
  for(const lang of ["en","ru","uz"]){
   assert.match(c.original_hashes[lang],/^[a-f0-9]{64}$/);
   assert.ok(c.translations[lang].length>=100);
  }
 }
 const econ=p.cards.find(x=>x.question_id===9465);
 assert.match(econ.translations.uz,/40.*50.*30/);
 assert.match(econ.translations.uz,/35.*45.*50/);
 const shift=p.cards.find(x=>x.question_id===9723);
 for(const l of ["en","ru","uz"]){
  assert.ok(shift.translations[l].includes("400 − 2P = 100 + P"));
  assert.ok(shift.translations[l].includes("370 − 2P = 70 + P"));
 }
});

test("P4 editorial handoff: all 70 live questions have hash-bound trilingual pending review, no fabricated signoffs",()=>{
 const csv=read("../../docs/iclub-ai-v21-qbank-70-editorial-review-queue-20261020.csv");
 const decode=line=>{
  let quote=false,buf="",cells=[];
  for(let i=0;i<line.length;i++){
   const ch=line[i];
   if(ch==='"'){if(quote&&line[i+1]==='"'){buf+='"';i++;}else quote=!quote;}
   else if(ch===','&&!quote){cells.push(buf);buf="";}
   else buf+=ch;
  }
  cells.push(buf);
  return cells;
 };
 const lines=csv.trimEnd().split(/\r?\n/),head=decode(lines[0]);
 assert.equal(lines.length,71);
 const required=[
  "snapshot_source_version","snapshot_publication_revision","snapshot_target_sha256",
  "snapshot_content_sha256_en","snapshot_content_sha256_ru","snapshot_content_sha256_uz",
  "technical_integrity_preflight","p4_existing_contract",
  "content_gate","rights_gate","source_version_gate","correctness_gate",
  "negative_tests_gate","exam_security_gate","locale_gate","accessibility_gate",
  "signed_content_review","signed_rights_review","signed_technical_review",
  "release_owner_authorization"
 ];
 required.forEach(k=>assert.ok(head.includes(k),k));
 const counts={chemistry:0,economics:0}, seen=new Set(),keys=new Set();
 for(const line of lines.slice(1)){
  const val=decode(line);
  assert.equal(val.length,head.length);
  const r=Object.fromEntries(head.map((k,i)=>[k,val[i]]));
  assert.ok(["chemistry","economics"].includes(r.subject_key));
  assert.ok(!seen.has(r.subject_key+":"+r.question_id));
  seen.add(r.subject_key+":"+r.question_id);
  counts[r.subject_key]++;
  assert.equal(r.snapshot_source_version,"qbank_exact_explanation_draft_v1");
  assert.equal(r.snapshot_publication_revision,"1");
  assert.match(r.snapshot_target_sha256,/^[a-f0-9]{64}$/);
  for(const lang of ["en","ru","uz"]){
   assert.match(r["snapshot_content_sha256_"+lang],/^[a-f0-9]{64}$/);
   assert.ok(r["source_card_key_"+lang]);
   assert.ok(!keys.has(r["source_card_key_"+lang]));
   keys.add(r["source_card_key_"+lang]);
  }
  assert.equal(r.technical_integrity_preflight,"PASS_HASH_AND_ACTIVE_SOURCE_ONLY");
  assert.equal(r.p4_existing_contract,"DIFFERENT_SURFACE_AND_STORAGE__NO_AUTOMATIC_RELEASE");
  for(const g of ["content_gate","rights_gate","source_version_gate",
   "correctness_gate","negative_tests_gate","exam_security_gate",
   "locale_gate","accessibility_gate"])assert.equal(r[g],"PENDING",g);
  for(const g of ["signed_content_review","signed_rights_review",
   "signed_technical_review"])assert.equal(r[g],"MISSING");
  assert.equal(r.release_owner_authorization,"NOT_AUTHORIZED");
  assert.equal(r.independent_editorial_publication,"NOT_APPROVED");
 }
 assert.deepEqual(counts,{chemistry:35,economics:35});
 assert.equal(keys.size,210);
 const p4Source=read("../sql_drafts/iclub_ai_source_proof_bundle_v21_UNAPPLIED.sql");
 const liveGateway=read("iclub_ai_v21_qbank_owner_provenance_GATE_ONLY_UNAPPLIED_20261020.sql");
 assert.match(p4Source,/\(surface_code='practice' AND feature_code='answer_explanation'\)/);
 assert.match(liveGateway,/src.surface_code='practice_error'/);
 // Old P4 hashes an envelope, live runtime hashes just answer text.
 // Copying a live digest into a P4 ticket is NOT a valid source proof.
 assert.ok(p4Source.includes("v.source_text||E'\\n'||v.prepared_variants::text"));
 assert.ok(liveGateway.includes("convert_to(src.body_text,'UTF8')"));
 assert.match(p4Source,/PRIMARY KEY\(surface_code,subject_key,feature_code,topic_key,locale,source_id,source_version\)/);
 assert.doesNotMatch(csv,/"APPROVED","APPROVED"/);
});

test("Former P4 signed verifier cannot silently publish unreconciled live sources",()=>{
 const {verifyEditorialEvidence,GATES}=require("../ai-layer-v21-editorial-evidence.cjs");
 const draft=Object.fromEntries(GATES.map(k=>[k,false]));
 const make=(surface,qaEvidence)=>({
  protocol:"iclub-ai-editorial-evidence-v21",
  ticketId:"77777777-7777-4777-8777-777777777777",action:"publish",
  surface,subject:"economics",feature:"answer_explanation",
  topic:"question_9465",locale:"en",
  sourceId:"iclub_qbank_draft_20261020_economics_9465_en",
  sourceVersion:"qbank_exact_explanation_draft_v1",
  sourceHash:"d57ac7f27b1901506b66dc979e27c8c8468e518ed329f193f75c4b57974d4f88",
  expectedRevision:1,qaEvidence,reason:"",
  issuedAtMs:1800000000000,expiresAtMs:1800000050000
 });
 const nowMs=1800000001000;
 const oldRoute=verifyEditorialEvidence({
  manifest:make("practice_error",draft),trustRegistry:null,signatures:[],nowMs
 });
 assert.equal(oldRoute.ok,false);
 assert.equal(oldRoute.reason,"manifest_invalid"); // Different surface grammar.
 const canonicalButNotReviewed=verifyEditorialEvidence({
  manifest:make("practice",draft),trustRegistry:null,signatures:[],nowMs
 });
 assert.equal(canonicalButNotReviewed.ok,false);
 assert.equal(canonicalButNotReviewed.reason,"manifest_invalid");
 const unsafeBooleanShortcut=verifyEditorialEvidence({
  manifest:make("practice",Object.fromEntries(GATES.map(k=>[k,true]))),
  trustRegistry:null,signatures:[],nowMs
 });
 assert.equal(unsafeBooleanShortcut.ok,false);
 assert.equal(unsafeBooleanShortcut.reason,"trust_registry_missing");
 assert.equal("attestation" in unsafeBooleanShortcut,false);
});
