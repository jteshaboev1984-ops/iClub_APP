"use strict";
// All signing keys below are ephemeral synthetic keys generated only in CI.
const {test}=require("node:test"),assert=require("node:assert/strict");
const {generateKeyPairSync,sign,createHash}=require("node:crypto");
const {signingBytes,GATES}=require("../ai-layer-v21-editorial-evidence.cjs");
const {verifyAcademicTriad,sourceEnvelopeHash}=
 require("./iclub-ai-v21-qbank-p4-signed-triad-bridge.cjs");
const SHA=x=>createHash("sha256").update(x,"utf8").digest("hex");
const NOW=1800000000000,REV=0,LOCALES=["en","ru","uz"];
const DOMAINS=["content","rights","technical","academic","language"];
const UIDS=[
 "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
 "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb",
 "cccccccc-cccc-4ccc-8ccc-cccccccccccc",
 "dddddddd-dddd-4ddd-8ddd-dddddddddddd",
 "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee"];
function makeFixture(){
 const original={
  en:"Original independently owned practice-bank explanation in English.",
  ru:"Оригинальный принадлежащий iClub текст объяснения для тестового задания.",
  uz:"iClub asl manbasi bo‘yicha o‘quv izohining sintetik namunasi."
 };
 const question={id:9465,subject_key:"economics",target_hash:"a".repeat(64),
  is_active:true,quality_status:"published",in_active_practice_pool:true,
  original_hashes:Object.fromEntries(LOCALES.map(l=>[l,SHA(original[l])]))};
 const data={
  en:"SYNTHETIC ONLY: accurate worked practice explanation that explains all of the arithmetic with transparent steps, without any student details, intended for local tests.",
  ru:"СИНТЕТИЧЕСКИЙ ТЕСТ: объяснение экономической задачи с подробным разбором расчётов, без персональных данных и без публикации настоящим ученикам.",
  uz:"FAQAT SINTETIK QA: iqtisodiy masala yechimini barcha bosqichlari bilan tushuntiruvchi izoh; haqiqiy o‘quvchi ma’lumotlari ishlatilmaydi."
 };
 const sources=LOCALES.map(locale=>({
  surface_code:"practice_error",subject_key:"economics",
  context_key:"question_9465",locale,
  source_card_key:"synthetic_qbank_9465_"+locale,
  source_version:"synthetic_draft_v2",publication_revision:2,
  body_text:data[locale],content_hash:SHA(data[locale]),
  target_hash:question.target_hash,
  published:false,revoked:true,content_reviewed:false,
  rights_reviewed:false,locale_reviewed:false,academic_qa_passed:false,
  approved_at:null,original_source_hash:question.original_hashes[locale]}));
 const trustRegistry={revision:"synthetic_trust_1",reviewers:[]};
 const keypairs={};
 DOMAINS.forEach((domain,i)=>{
  const pair=generateKeyPairSync("ed25519");keypairs[domain]=pair;
  trustRegistry.reviewers.push({
   domain,reviewerId:UIDS[i],keyId:"synthetic_"+domain,
   publicKeyPem:pair.publicKey.export({format:"pem",type:"spki"}),
   enabled:true,validFromMs:NOW-10000,validUntilMs:NOW+1000000});
 });
 const reviews=sources.map((source,i)=>{
  const manifest={
   protocol:"iclub-ai-editorial-evidence-v21",
   ticketId:"0000000"+(i+1)+"-aaaa-4aaa-8aaa-aaaaaaaaaaaa",
   action:"publish",surface:"practice",subject:"economics",
   feature:"answer_explanation",topic:"question_9465",locale:source.locale,
   sourceId:source.source_card_key,sourceVersion:source.source_version,
   sourceHash:sourceEnvelopeHash(source.body_text),
   expectedRevision:REV,
   qaEvidence:Object.fromEntries(GATES.map(k=>[k,true])),
   reason:"",issuedAtMs:NOW-1000,expiresAtMs:NOW+100000
  };
  function signer(domain){
   const idx=DOMAINS.indexOf(domain);
   return {domain,reviewerId:UIDS[idx],keyId:"synthetic_"+domain,
    signature:sign(null,signingBytes(manifest),keypairs[domain].privateKey)
      .toString("base64url")};
  }
  return {locale:source.locale,manifest,
   signatures:DOMAINS.slice(0,3).map(signer),
   additionalSignatures:DOMAINS.slice(3).map(signer)};
 });
 return {question,sources,reviews,trustRegistry,nowMs:NOW,
  expectedReleaseRevision:REV};
}
const check=opts=>verifyAcademicTriad(opts);
test("synthetic five-role P4 proofs verify three exact historical-source locales but NEVER release",()=>{
 const r=check(makeFixture());
 assert.equal(r.ok,true);
 assert.equal(r.releaseAllowed,false);
 assert.equal(r.next,"separately_authorized_editorial_and_owner_release");
 assert.deepEqual(r.verifiedLocales,LOCALES);
 assert.equal(r.proof.length,3);
 assert.match(r.proof[0].signedManifestHash,/^[a-f0-9]{64}$/);
 assert.equal("publish" in r,false);
 assert.equal("provider" in r,false);
});
test("default no keys and no content signoff stay DENY",()=>{
 const f=makeFixture();f.trustRegistry=null;
 assert.equal(check(f).ok,false);
 const g=makeFixture();g.reviews[0].signatures=[];
 assert.equal(check(g).ok,false);
 const h=makeFixture();h.reviews[1].manifest.qaEvidence.rights_approved=false;
 assert.equal(check(h).ok,false);
});
test("source mismatch, forged question context, wrong subject and hash drift DENY",()=>{
 const mutations=[
  f=>f.sources[0].body_text+="tampered",
  f=>f.sources[1].subject_key="chemistry",
  f=>f.question.target_hash="b".repeat(64),
  f=>f.question.original_hashes.uz="c".repeat(64),
  f=>f.sources[2].original_source_hash="0".repeat(64),
  f=>f.sources[1].published=true,
  f=>f.sources[1].revoked=false,
  f=>f.sources[1].rights_reviewed=true,
  f=>f.sources[0].source_card_key="forged",
  f=>f.sources[1].locale="en",
  f=>f.question.in_active_practice_pool=false,
  f=>f.question.is_active=false,
  f=>f.question.quality_status="draft"
 ];
 for(const mutate of mutations){
  const f=makeFixture();mutate(f);
  assert.equal(check(f).ok,false,mutate.toString());
 }
});
test("language set and source version or issuance revision mismatches DENY",()=>{
 const mutations=[
  f=>f.sources.pop(),
  f=>f.reviews.pop(),
  f=>f.sources[1].source_version="different_v1",
  f=>f.sources[2].publication_revision=3,
  f=>f.reviews[0].manifest.locale="uz",
  f=>f.reviews[1].manifest.expectedRevision=2,
  f=>f.reviews[2].manifest.sourceHash=f.sources[0].content_hash,
  f=>f.reviews[1].manifest.topic="question_9000",
  f=>f.reviews[0].manifest.ticketId=f.reviews[1].manifest.ticketId,
  f=>f.reviews[0].manifest.feature="topic_explanation",
  f=>f.reviews[1].manifest.surface="practice_error"
 ];
 for(const mutate of mutations){
  const f=makeFixture();mutate(f);
  assert.equal(check(f).ok,false,mutate.toString());
 }
});
test("independent academic and language reviewers cannot be forged or reused",()=>{
 const mutations=[
  f=>f.reviews[1].additionalSignatures.pop(),
  f=>f.reviews[1].additionalSignatures[0].signature=
    f.reviews[0].additionalSignatures[0].signature,
  f=>f.reviews[1].additionalSignatures[1].reviewerId=
    f.reviews[1].signatures[0].reviewerId,
  f=>f.reviews[1].additionalSignatures[0].keyId=
    f.reviews[1].signatures[0].keyId,
  f=>f.trustRegistry.reviewers[3].enabled=false,
  f=>f.trustRegistry.reviewers[4].validUntilMs=NOW-100,
  f=>f.reviews[1].additionalSignatures[0].domain="rights"
 ];
 for(const mutate of mutations){
  const f=makeFixture();mutate(f);
  assert.equal(check(f).ok,false,mutate.toString());
 }
});
test("future date expired signature and replay of reviewers DENY",()=>{
 const f=makeFixture();f.nowMs=NOW+200000;
 assert.equal(check(f).ok,false);
 const g=makeFixture();
 g.reviews[0].signatures[1].reviewerId=g.reviews[0].signatures[0].reviewerId;
 assert.equal(check(g).ok,false);
});
test("old P4 digest differs from bare live digest and is exact via empty JSONB envelope",()=>{
 const f=makeFixture();
 for(const s of f.sources){
  assert.equal(s.content_hash,SHA(s.body_text));
  assert.equal(sourceEnvelopeHash(s.body_text),SHA(s.body_text+"\n{}"));
  assert.notEqual(sourceEnvelopeHash(s.body_text),s.content_hash);
 }
});
