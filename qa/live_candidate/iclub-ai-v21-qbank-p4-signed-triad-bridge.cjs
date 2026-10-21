"use strict";
// QA-only content-to-P4 bridge for the existing practice_error registry.
// It neither publishes nor stages SQL. NEVER accept source snapshots from a browser.
const {createHash,createPublicKey,verify}=require("node:crypto");
const {verifyEditorialEvidence,signingBytes}=require("../ai-layer-v21-editorial-evidence.cjs");
const SHA=/^[a-f0-9]{64}$/;
const CODE=/^[a-z0-9][a-z0-9._-]{0,99}$/;
const UUID=/^[a-f0-9]{8}-[a-f0-9]{4}-[1-8][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$/i;
const LOCALES=["en","ru","uz"];
const ROLES=["academic","language"];
const SOURCE_KEYS=["surface_code","subject_key","context_key","locale",
 "source_card_key","source_version","publication_revision","body_text",
 "content_hash","target_hash","published","revoked","content_reviewed",
 "rights_reviewed","locale_reviewed","academic_qa_passed","approved_at",
 "original_source_hash"];
const QUESTION_KEYS=["id","subject_key","target_hash","is_active",
 "quality_status","in_active_practice_pool","original_hashes"];
const REVIEW_KEYS=["locale","manifest","signatures","additionalSignatures"];
const exact=(x,ks)=>!!x&&typeof x==="object"&&!Array.isArray(x)&&
 Object.keys(x).length===ks.length&&ks.every(k=>Object.hasOwn(x,k));
const sha=text=>createHash("sha256").update(text,"utf8").digest("hex");
const deny=reason=>Object.freeze({ok:false,reason,releaseAllowed:false});
const same=new Set(LOCALES);
// This deliberate P4 proof envelope corresponds to source_text = body_text
// and prepared_variants = '{}'::jsonb. It proves source identity only;
// older P4's prepared card delivery is NOT used or silently migrated.
const sourceEnvelopeHash=body=>sha(body+"\n{}");
function validateOriginal(s,q){
 if(!exact(s,SOURCE_KEYS)||s.surface_code!=="practice_error"
  ||s.subject_key!==q.subject_key||s.context_key!=="question_"+q.id
  ||!same.has(s.locale)||!CODE.test(s.source_card_key)
  ||!CODE.test(s.source_version)||!Number.isSafeInteger(s.publication_revision)
  ||s.publication_revision<1||typeof s.body_text!=="string"
  ||s.body_text.length<100||s.body_text.length>6000
  ||!SHA.test(s.content_hash)||!SHA.test(s.target_hash)
  ||!SHA.test(s.original_source_hash)
  ||s.content_hash!==sha(s.body_text)||s.target_hash!==q.target_hash
  ||s.original_source_hash!==q.original_hashes[s.locale]
  ||s.published!==false||s.revoked!==true||s.content_reviewed!==false
  ||s.rights_reviewed!==false||s.locale_reviewed!==false
  ||s.academic_qa_passed!==false||s.approved_at!==null) return false;
 return true;
}
function verifyAddedReview(signatures,trustRegistry,manifest,alreadyUsed,nowMs){
 if(!Array.isArray(signatures)||signatures.length!==2||
 !trustRegistry||!Array.isArray(trustRegistry.reviewers))return deny("extra_review_missing");
 const domains=new Set(),ids=new Set(alreadyUsed),keys=new Set();
 const bytes=signingBytes(manifest);
 for(const item of signatures){
  if(!exact(item,["domain","reviewerId","keyId","signature"])||
   !ROLES.includes(item.domain)||domains.has(item.domain)||
   !UUID.test(item.reviewerId)||ids.has(item.reviewerId)||
   !CODE.test(item.keyId)||keys.has(item.keyId)||
   typeof item.signature!=="string"||
   !/^[A-Za-z0-9_-]{86}$/.test(item.signature))
   return deny("extra_review_identity_invalid");
  const matched=trustRegistry.reviewers.filter(r=>
   r&&r.enabled===true&&r.domain===item.domain&&
   r.reviewerId===item.reviewerId&&r.keyId===item.keyId&&
   Number.isSafeInteger(r.validFromMs)&&r.validFromMs<=manifest.issuedAtMs&&
   Number.isSafeInteger(r.validUntilMs)&&r.validUntilMs>nowMs);
  if(matched.length!==1)return deny("extra_reviewer_untrusted");
  let good=false;
  try{
   const pk=createPublicKey(matched[0].publicKeyPem);
   good=pk.asymmetricKeyType==="ed25519"&&
    verify(null,bytes,pk,Buffer.from(item.signature,"base64url"));
  }catch{}
  if(!good)return deny("extra_review_signature_invalid");
  domains.add(item.domain);ids.add(item.reviewerId);keys.add(item.keyId);
 }
 if(domains.size!==2)return deny("extra_review_missing");
 return {ok:true};
}
function verifyAcademicTriad({question,sources,reviews,trustRegistry,nowMs,
 expectedReleaseRevision}={}){
 // The caller MUST be a trusted backend with fresh DB-sourced question,
 // sources and original hashes. This function is NOT a learner RPC.
 if(!exact(question,QUESTION_KEYS)||!Number.isSafeInteger(question.id)||
 question.id<1||!CODE.test(question.subject_key)||!SHA.test(question.target_hash)||
 question.is_active!==true||question.quality_status!=="published"||
 question.in_active_practice_pool!==true||
 !exact(question.original_hashes,LOCALES)||
 LOCALES.some(l=>!SHA.test(question.original_hashes[l])))
  return deny("question_authority_unavailable");
 if(!Array.isArray(sources)||sources.length!==3||
 !Array.isArray(reviews)||reviews.length!==3||
 !Number.isSafeInteger(nowMs)||
 !Number.isSafeInteger(expectedReleaseRevision)||expectedReleaseRevision<0)
  return deny("triad_missing");
 const smap=new Map(),rmap=new Map(),tickets=new Set(),keys=new Set();
 for(const s of sources){
  if(!validateOriginal(s,question)||smap.has(s.locale)||keys.has(s.source_card_key))
   return deny("source_integrity_or_locale");
  smap.set(s.locale,s);keys.add(s.source_card_key);
 }
 for(const r of reviews){
  if(!exact(r,REVIEW_KEYS)||!same.has(r.locale)||rmap.has(r.locale))
   return deny("review_locale_invalid");
  rmap.set(r.locale,r);
 }
 if(LOCALES.some(l=>!smap.has(l)||!rmap.has(l)))return deny("locale_set_incomplete");
 const versions=new Set(sources.map(s=>s.source_version));
 const revisions=new Set(sources.map(s=>s.publication_revision));
 if(versions.size!==1||revisions.size!==1)return deny("version_set_drift");
 const checked=[];
 for(const locale of LOCALES){
  const s=smap.get(locale),r=rmap.get(locale),m=r.manifest;
  if(!m||m.action!=="publish"||m.surface!=="practice"||
   m.feature!=="answer_explanation"||m.subject!==question.subject_key||
   m.topic!=="question_"+question.id||m.locale!==locale||
   m.sourceId!==s.source_card_key||m.sourceVersion!==s.source_version||
   m.sourceHash!==sourceEnvelopeHash(s.body_text)||
   m.expectedRevision!==expectedReleaseRevision)
   return deny("editorial_manifest_not_bound_to_source");
  if(tickets.has(m.ticketId))return deny("replayed_ticket_in_triad");
  tickets.add(m.ticketId);
  const signed=verifyEditorialEvidence({
   manifest:m,signatures:r.signatures,trustRegistry,nowMs});
  if(!signed.ok)return deny("p4_"+signed.reason);
  const first=Object.values(signed.attestation.reviewers);
  const extra=verifyAddedReview(r.additionalSignatures,trustRegistry,m,first,nowMs);
  if(!extra.ok)return extra;
  checked.push({locale,sourceCardKey:s.source_card_key,
   sourceContentHash:s.content_hash,targetHash:s.target_hash,
   signedManifestHash:signed.attestation.manifest_sha256});
 }
 // Verification of cryptographic *test* evidence is not a publication.
 // Original rights, independent reviewer registry, owner cohort permission,
 // active assessment and quota must all be checked by other live authorities.
 return Object.freeze({ok:true,releaseAllowed:false,
  next:"separately_authorized_editorial_and_owner_release",
  subject:question.subject_key,questionId:question.id,
  sourceVersion:sources[0].source_version,
  verifiedLocales:checked.map(x=>x.locale),
  proof:checked});
}
module.exports={verifyAcademicTriad,sourceEnvelopeHash};
