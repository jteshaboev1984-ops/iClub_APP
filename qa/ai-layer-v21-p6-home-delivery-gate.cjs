"use strict";
// §104: QA-only PRE-DELIVERY guard for Home HTTP responses.
// Even after the Home plan is HMAC-signed and priority is selected,
// user rights, source rights and screen can change. Reject on drift.
// This is NOT a serializable DB transaction or authorization for production.
const {verifySignedPlan,accessApproved}=
 require("./ai-layer-v21-p6-home-signed-server-bridge.cjs");
const INTENT=Object.freeze({
 review_finalized_practice:"study",
 review_open_tour_archive:"competitive",
 continue_enrolled_subject:"study"
});
const uuid=x=>typeof x==="string"&&
 /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(x);
const ident=x=>typeof x==="string"&&/^[a-z][a-z0-9_]{1,79}$/.test(x);
const digest=x=>typeof x==="string"&&/^[a-f0-9]{64}$/.test(x);
const integer=x=>Number.isSafeInteger(x)&&x>0;
const equal=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const blocked=()=>Object.freeze({ready:false,reason:"in_development"});
function validServices(s){
 return s&&Buffer.isBuffer(s.signingKey)&&s.signingKey.length>=32&&
  ["nowMs","readCurrentScreen","readServerScan","verifySubjectAccess",
   "verifyAcademicEvidence","readEditorialRelease"].every(k=>typeof s[k]==="function");
}
async function validateBeforeHomeDelivery(s,{userId,contextHandle,locale,plan,choice}={}){
 if(!validServices(s)||!uuid(userId)||!uuid(contextHandle)||
  !["ru","uz","en"].includes(locale)||!plan||!choice||
  !verifySignedPlan(plan,s.signingKey))return blocked();
 try{
  const now=s.nowMs();
  if(!integer(now)||plan.ownerId!==userId||
    plan.screenRevision!==plan.planRevision||
    !integer(plan.planRevision)||!integer(plan.issuedAtMs)||
    !integer(plan.expiresAtMs)||now<plan.issuedAtMs||
    now>=plan.expiresAtMs||plan.expiresAtMs-plan.issuedAtMs>30000||
    plan.policyVersion!=="home_next_actions_20261014_v1"||
    !Array.isArray(plan.actions)||plan.actions.length<1||
    plan.actions.length>3||
    choice.ready!==true||choice.reviewOnly!==true||
    choice.releaseAllowed!==false||
    choice.expiresAtMs!==plan.expiresAtMs||
    choice.screenRevision!==plan.screenRevision||
    choice.planRevision!==plan.planRevision)return blocked();
  const expectedIds=plan.actions.map(a=>a.actionId).sort();
  const unique=new Set(expectedIds);
  if(unique.size!==expectedIds.length)return blocked();
  const only=choice.status==="candidate_only"&&plan.actions.length===1&&
   choice.actionId===plan.actions[0].actionId&&
   choice.actionCode===plan.actions[0].actionCode&&
   choice.subjectKey===plan.actions[0].subjectKey;
  const tie=choice.status==="selection_required"&&
   Array.isArray(choice.candidateActionIds)&&
   equal([...choice.candidateActionIds].sort(),expectedIds)&&
   plan.actions.length>=2;
  if(!only&&!tie)return blocked();
  const screen=await s.readCurrentScreen(userId,contextHandle);
  const scan=await s.readServerScan(userId,contextHandle);
  if(screen?.ownerId!==userId||screen.contextHandle!==contextHandle||
   screen.surface!=="home"||screen.currentView!=="home"||
   screen.revision!==plan.screenRevision||
   !integer(screen.expiresAtMs)||screen.expiresAtMs<plan.expiresAtMs||
   scan?.allowed!==true||scan.owner_id!==userId||
   scan.context_handle!==contextHandle||
   scan.screen_revision!==plan.screenRevision||
   scan.complete_scan!==true||scan.review_only!==true||
   scan.source_publication!==false||scan.rights_approved!==false||
   scan.policy_version!==plan.policyVersion||
   !Array.isArray(scan.candidates)||
   scan.candidates.length!==plan.actions.length)return blocked();
  const rows=new Map();
  for(const v of scan.candidates){
   if(!INTENT[v?.actionCode]||!ident(v.subjectKey)||
    !integer(v.evidenceId)||!integer(v.evidenceRevision))return blocked();
   const key="next_"+v.actionCode+"_"+v.subjectKey+"_"+v.evidenceId;
   if(rows.has(key))return blocked();
   rows.set(key,v);
  }
  for(const a of plan.actions){
   const v=rows.get(a.actionId);
   if(!v||v.actionCode!==a.actionCode||v.subjectKey!==a.subjectKey||
    v.evidenceRevision!==a.evidenceRevision||!digest(a.evidenceHash)||
    !digest(a.sourceHash)||typeof a.sourceVersion!=="string"||
    !a.sourceVersion)return blocked();
   const intent=INTENT[v.actionCode];
   const access=await s.verifySubjectAccess(userId,v.subjectKey,intent);
   if(!accessApproved(access,userId,v.subjectKey,intent))return blocked();
   const evidence=await s.verifyAcademicEvidence(userId,v);
   if(evidence?.allowed!==true||evidence.evidenceId!==v.evidenceId||
    evidence.evidenceRevision!==a.evidenceRevision||
    evidence.evidenceHash!==a.evidenceHash||
    evidence.subjectKey!==a.subjectKey||
    evidence.actionCode!==a.actionCode)return blocked();
   const release=await s.readEditorialRelease(locale,a.actionCode,a.subjectKey);
   if(release?.ready!==true||release.rightsApproved!==true||
    release.contentApproved!==true||release.sourceConflict!==false||
    release.sourceHash!==a.sourceHash||
    release.sourceVersion!==a.sourceVersion)return blocked();
  }
  // Re-read the exact complete scan and owner-screen after the last async
  // evidence/source verification. Never silently select a new priority.
  const finalScan=await s.readServerScan(userId,contextHandle);
  const finalScreen=await s.readCurrentScreen(userId,contextHandle);
  const finish=s.nowMs();
  if(!equal(scan,finalScan)||!equal(screen,finalScreen)||
   !integer(finish)||finish<now||finish>=plan.expiresAtMs||
   finish>=screen.expiresAtMs)return blocked();
  const result={ready:true,reviewOnly:true,releaseAllowed:false,
    expiresAtMs:plan.expiresAtMs,status:choice.status};
  if(only){result.actionCode=choice.actionCode;result.subjectKey=choice.subjectKey;}
  else result.candidateActionIds=[...choice.candidateActionIds].sort();
  return Object.freeze(result);
 }catch{return blocked();}
}
module.exports={validateBeforeHomeDelivery};
