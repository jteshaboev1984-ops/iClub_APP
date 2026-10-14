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
   // Snapshot before ANY asynchronous signer, academic or locale checks.
   // Re-reading only the screen does not catch planner/release revocation.
   const signedPlanSnapshot=JSON.stringify(plan);
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
   // A released/reprioritized plan or revoked source can change DURING
   // the initial checks. Reject if the authoritative plan is no longer exact,
   // or any rights/accreditation changed while those checks were pending.
   const lastPlan=await s.readServerPlan(userId,contextHandle);
   if(JSON.stringify(plan)!==signedPlanSnapshot||
     JSON.stringify(lastPlan)!==signedPlanSnapshot||
     await s.verifyPlanAuthority(userId,before,lastPlan)!==true)return deny();
   for(const a of lastPlan.actions){
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
     !Number.isSafeInteger(end)||end<now||
     end>=before.expiresAtMs||end>=plan.expiresAtMs)return deny();
   // The owner-approved PRIORITY policy may run only on a planner with
   // authority-signed evidence that all three categories were enumerated.
   // A boolean from the browser or an unsigned display tile is insufficient.
   const coverage=plan.priorityCoverage;
   const canRank=plan.policyVersion==="home_next_actions_20261014_v1"&&
    coverage&&typeof coverage==="object"&&!Array.isArray(coverage)&&
    Object.keys(coverage).sort().join(",")===
     "activeEnrollments,finalizedPractice,openTourArchives,ownerScope"&&
    Object.values(coverage).every(x=>x===true);
   return{ready:true,ownerId:userId,screenRevision:before.revision,
    planRevision:plan.planRevision,authorityHash:plan.authorityHash,
    actionIds:[...seen],expiresAtMs:plan.expiresAtMs,
    priorityPolicyReady:canRank===true,
    // Metadata only: never include grades, content, answer keys or personal data.
    priorityCandidates:canRank===true?plan.actions.map(a=>({
     actionId:a.actionId,actionCode:a.actionCode,subjectKey:a.subjectKey
    })):[]};
  }catch{return deny();}
 }
}
module.exports={QAHomeNextActionProof};
