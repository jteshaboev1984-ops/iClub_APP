"use strict";
// §52 QA-only proposed Home authorization. Never publishes student recommendations.
const locales=new Set(["ru","uz","en"]);
const needed=["readCurrentScreen","readServerPlan","verifyPlanAuthority","verifyAcademicEvidence","verifyEditorialRelease","nowMs"];
const deny=()=>({ready:false,reason:"in_development"});
const hash=s=>typeof s==="string"&&/^[a-f0-9]{64}$/.test(s);
const positive=n=>Number.isSafeInteger(n)&&n>0;
class QAHomeNextActionProof{
 constructor(s){for(const k of needed)if(typeof s?.[k]!=="function")throw Error("missing trusted service: "+k);this.s=s;}
 async check({userId,contextHandle,locale}={}){
  const s=this.s;
  if(!locales.has(locale)||typeof userId!=="string"||typeof contextHandle!=="string"||
    !userId||!contextHandle)return deny();
  try{
   const now=s.nowMs(),before=await s.readCurrentScreen(userId,contextHandle);
   if(!Number.isSafeInteger(now)||before?.ownerId!==userId||
     before.contextHandle!==contextHandle||before.surface!=="home"||
     before.currentView!=="home"||!positive(before.revision)||
     !Number.isSafeInteger(before.expiresAtMs)||before.expiresAtMs<=now)return deny();
   const plan=await s.readServerPlan(userId,contextHandle);
   if(plan?.ownerId!==userId||plan.screenRevision!==before.revision||
     !positive(plan.planRevision)||!hash(plan.authorityHash)||
     !Number.isSafeInteger(plan.issuedAtMs)||plan.issuedAtMs>now||
     !Number.isSafeInteger(plan.expiresAtMs)||plan.expiresAtMs<=now||
     plan.expiresAtMs>before.expiresAtMs||
     plan.expiresAtMs-plan.issuedAtMs>90000||
     !Array.isArray(plan.actions)||plan.actions.length<1||
     plan.actions.length>3)return deny();
   if(await s.verifyPlanAuthority(userId,before,plan)!==true)return deny();
   const seen=new Set();
   for(const a of plan.actions){
    if(!/^[a-z][a-z0-9_]{2,72}$/.test(a?.actionId)||seen.has(a.actionId)||
      !["continue_enrolled_subject","review_finalized_practice","review_open_tour_archive"].includes(a.actionCode)||
      !/^[a-z][a-z0-9_]{2,72}$/.test(a.subjectKey)||
      !positive(a.evidenceRevision)||!hash(a.evidenceHash)||
      !hash(a.sourceHash)||typeof a.sourceVersion!=="string")return deny();
    seen.add(a.actionId);
    const evidence=await s.verifyAcademicEvidence(userId,a);
    if(evidence?.allowed!==true||evidence.evidenceHash!==a.evidenceHash||
       evidence.evidenceRevision!==a.evidenceRevision)return deny();
    const release=await s.verifyEditorialRelease(locale,a);
    if(release?.ready!==true||release.sourceHash!==a.sourceHash||
       release.sourceVersion!==a.sourceVersion)return deny();
   }
   const after=await s.readCurrentScreen(userId,contextHandle),end=s.nowMs();
   if(after?.ownerId!==before.ownerId||after.contextHandle!==before.contextHandle||
     after.revision!==before.revision||after.expiresAtMs!==before.expiresAtMs||
     after.surface!==before.surface||after.currentView!==before.currentView||
     !Number.isSafeInteger(end)||end>=before.expiresAtMs||end>=plan.expiresAtMs)return deny();
   return{ready:true,ownerId:userId,screenRevision:before.revision,
    planRevision:plan.planRevision,authorityHash:plan.authorityHash,
    actionIds:[...seen],expiresAtMs:plan.expiresAtMs};
  }catch{return deny();}
 }
}
module.exports={QAHomeNextActionProof};
