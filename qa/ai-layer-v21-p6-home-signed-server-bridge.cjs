"use strict";
// §88: QA-only bridge from a real-schema *scratch* scanner into the separately
// verified signed Home plan contract. Never mounted by active app/Edge.
// The ownerId must come from trusted Auth, NOT from browser JSON.
const {createHmac,timingSafeEqual}=require("node:crypto");
const CODE_INTENT=Object.freeze({
 review_finalized_practice:"study",
 review_open_tour_archive:"competitive",
 continue_enrolled_subject:"study"
});
const isObject=x=>!!x&&typeof x==="object"&&!Array.isArray(x);
const id=x=>typeof x==="string"&&/^[a-z][a-z0-9_]{1,79}$/.test(x);
const uuid=x=>typeof x==="string"&&/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(x);
const digest=x=>typeof x==="string"&&/^[a-f0-9]{64}$/.test(x);
const positive=x=>Number.isSafeInteger(x)&&x>0;
const denied=()=>Object.freeze({ready:false,reason:"in_development"});
const cleanTime=x=>Number.isSafeInteger(x)&&x>=0;
// Commercial check MUST bind a server-side owner, subject, intended action
// and a versioned entitlement. Plain allowed=true from a shadow/legacy
// passthrough fallback cannot grant new Global AI recommendations.
function accessApproved(proof,userId,subjectKey,intent){
 return isObject(proof)&&proof.allowed===true&&proof.verified===true&&
  proof.userId===userId&&proof.subjectKey===subjectKey&&
  proof.intent===intent&&positive(proof.revision)&&
  proof.source==="server_enforced_subject_access_v1"&&
  (proof.mode==="commercial"||
   (proof.mode==="grandfathered"&&proof.legacyOwnerVerified===true))&&
  (intent!=="competitive"||proof.competitiveSelectionVerified===true);
}
const matching=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const policyVersion="home_next_actions_20261014_v1";
function mac(key,data){
 return createHmac("sha256",key).update(JSON.stringify(data),"utf8").digest("hex");
}
function signPlan(plan,key){
 const {authorityHash:_unused,...unsigned}=plan;
 return Object.freeze({...unsigned,authorityHash:mac(key,unsigned)});
}
function verifySignedPlan(plan,key){
 if(!isObject(plan)||!digest(plan.authorityHash))return false;
 const {authorityHash,...unsigned}=plan;
 const expected=mac(key,unsigned);
 return timingSafeEqual(Buffer.from(expected,"hex"),Buffer.from(authorityHash,"hex"));
}
function servicesValid(s){
 return isObject(s)&&["readCurrentScreen","readServerScan",
  "verifyAcademicEvidence","verifySubjectAccess","readEditorialRelease",
  "nowMs"].every(k=>typeof s[k]==="function")&&
  Buffer.isBuffer(s.signingKey)&&s.signingKey.length>=32;
}
async function buildHomePlan(s,{userId,contextHandle,locale}={}){
 if(!servicesValid(s)||!uuid(userId)||!uuid(contextHandle)||
  !["ru","uz","en"].includes(locale))return denied();
 try{
  const now=s.nowMs(),screen=await s.readCurrentScreen(userId,contextHandle);
  if(!cleanTime(now)||!isObject(screen)||screen.ownerId!==userId||
   screen.contextHandle!==contextHandle||screen.surface!=="home"||
   screen.currentView!=="home"||!positive(screen.revision)||
   !cleanTime(screen.expiresAtMs)||screen.expiresAtMs<=now||
   screen.expiresAtMs-now>90000)return denied();
  const scan=await s.readServerScan(userId,contextHandle);
  if(scan?.allowed!==true||scan.review_only!==true||
   scan.source_publication!==false||scan.rights_approved!==false||
   scan.owner_id!==userId||scan.context_handle!==contextHandle||
   scan.screen_revision!==screen.revision||
   scan.policy_version!==policyVersion||scan.complete_scan!==true||
   !Array.isArray(scan.candidates)||scan.candidates.length<1||
   scan.candidates.length>3)return denied();
  const actions=[],seen=new Set();
  for(const v of scan.candidates){
   const intent=CODE_INTENT[v?.actionCode];
   if(!intent||!id(v.subjectKey)||!positive(v.evidenceId)||
     !positive(v.evidenceRevision))return denied();
   const actionId="next_"+v.actionCode+"_"+v.subjectKey+"_"+v.evidenceId;
   if(actionId.length>72||seen.has(actionId))return denied();
   seen.add(actionId);
   const access=await s.verifySubjectAccess(userId,v.subjectKey,intent);
   if(!accessApproved(access,userId,v.subjectKey,intent))
    return denied();
   const ev=await s.verifyAcademicEvidence(userId,v);
   if(ev?.allowed!==true||ev.evidenceId!==v.evidenceId||
    ev.evidenceRevision!==v.evidenceRevision||!digest(ev.evidenceHash)||
    ev.subjectKey!==v.subjectKey||ev.actionCode!==v.actionCode)
    return denied();
   const release=await s.readEditorialRelease(locale,v.actionCode,v.subjectKey);
   if(release?.ready!==true||release.rightsApproved!==true||
    release.contentApproved!==true||release.sourceConflict!==false||
    !digest(release.sourceHash)||typeof release.sourceVersion!=="string"||
    release.sourceVersion.length<1)return denied();
   actions.push({actionId,actionCode:v.actionCode,subjectKey:v.subjectKey,
    evidenceRevision:v.evidenceRevision,evidenceHash:ev.evidenceHash,
    sourceHash:release.sourceHash,sourceVersion:release.sourceVersion});
  }
  // Exact re-read of the *whole* server scan, not a browser-reported tile.
  const finalScan=await s.readServerScan(userId,contextHandle);
  const finalScreen=await s.readCurrentScreen(userId,contextHandle);
  const end=s.nowMs();
  if(!matching(scan,finalScan)||!matching(screen,finalScreen)||
   !cleanTime(end)||end<now||end>=screen.expiresAtMs)return denied();
  for(const [index,v] of scan.candidates.entries()){
   const intent=CODE_INTENT[v.actionCode];
   const lastAccess=await s.verifySubjectAccess(userId,v.subjectKey,intent);
   if(!accessApproved(lastAccess,userId,v.subjectKey,intent))
    return denied();
   // An independently approved source or academic proof can be revoked while
   // commercial rights and current-screen reads are awaited. Revalidate both
   // hashes/versions immediately before signing; do not trust old booleans.
   const latestEvidence=await s.verifyAcademicEvidence(userId,v);
   const earlier=actions[index];
   if(latestEvidence?.allowed!==true||
    latestEvidence.evidenceId!==v.evidenceId||
    latestEvidence.evidenceRevision!==earlier.evidenceRevision||
    latestEvidence.evidenceHash!==earlier.evidenceHash||
    latestEvidence.subjectKey!==v.subjectKey||
    latestEvidence.actionCode!==v.actionCode)return denied();
   const latestRelease=await s.readEditorialRelease(locale,v.actionCode,v.subjectKey);
   if(latestRelease?.ready!==true||latestRelease.rightsApproved!==true||
    latestRelease.contentApproved!==true||latestRelease.sourceConflict!==false||
    latestRelease.sourceHash!==earlier.sourceHash||
    latestRelease.sourceVersion!==earlier.sourceVersion)return denied();
  }
  // Final screen/scan read after every await in the revalidation cycle.
  const stableScreen=await s.readCurrentScreen(userId,contextHandle);
  const stableScan=await s.readServerScan(userId,contextHandle);
  const signedAt=s.nowMs();
  if(!matching(screen,stableScreen)||!matching(scan,stableScan)||
    !cleanTime(signedAt)||signedAt<end||signedAt>=screen.expiresAtMs)
   return denied();
  const expiresAtMs=Math.min(screen.expiresAtMs,signedAt+30000);
  if(!Number.isSafeInteger(expiresAtMs)||expiresAtMs<=end)return denied();
  const signed=signPlan({ownerId:userId,screenRevision:screen.revision,
   planRevision:screen.revision,issuedAtMs:signedAt,expiresAtMs,
   policyVersion,priorityCoverage:{
    activeEnrollments:true,finalizedPractice:true,
    openTourArchives:true,ownerScope:true
   },actions},s.signingKey);
  return Object.freeze({ready:true,reviewOnly:true,plan:signed,
   betaAllowed:false,providerAllowed:false,productionAllowed:false});
 }catch{return denied();}
}
module.exports={buildHomePlan,verifySignedPlan};
