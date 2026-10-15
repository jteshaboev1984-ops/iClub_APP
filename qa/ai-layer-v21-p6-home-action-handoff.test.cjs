"use strict";
const {test}=require("node:test"),a=require("node:assert/strict");
const {issueSyntheticHandoff,claimSyntheticHandoff,possibleChoices}=
 require("./ai-layer-v21-p6-home-action-handoff.cjs");
const {signPlan}=(()=>{ // use real HMAC via public crypto, no production keys
 const {createHmac}=require("node:crypto");
 return{signPlan(plan,key){
  const authorityHash=createHmac("sha256",key)
   .update(JSON.stringify(plan),"utf8").digest("hex");
  return {...plan,authorityHash};
 }};
})();
const OWNER="11111111-1111-4111-8111-111111111111";
const HANDLE="33333333-3333-4333-8333-333333333333";
const KEY=Buffer.alloc(32,0x4f);
function plan(){
 const now=Date.now();
 return signPlan({ownerId:OWNER,screenRevision:12,planRevision:12,
  issuedAtMs:now-100,expiresAtMs:now+20000,
  policyVersion:"home_next_actions_20261014_v1",
  priorityCoverage:{activeEnrollments:true,finalizedPractice:true,
   openTourArchives:true,ownerScope:true},
  actions:[{actionId:"next_continue_enrolled_subject_biology_11",
   actionCode:"continue_enrolled_subject",subjectKey:"biology",
   evidenceRevision:12,evidenceHash:"a".repeat(64),
   sourceHash:"b".repeat(64),sourceVersion:"synthetic-only-v1"}]},KEY);
}
test("§108 handoff token is opaque, only synthetic SQL insert and no academic write",()=>{
 let query;
 const p=plan();
 const result=issueSyntheticHandoff({
  sql:statement=>{
   query=statement;
   const match=/VALUES \('([0-9a-f]{64})'/.exec(statement);
   return match?.[1];
  },
  signingKey:KEY,userId:OWNER,contextHandle:HANDLE,locale:"ru",
  plan:p,delivered:{ready:true,reviewOnly:true,releaseAllowed:false,
   status:"candidate_only",expiresAtMs:p.expiresAtMs,
   actionCode:"continue_enrolled_subject",subjectKey:"biology"}
 });
 a.equal(result.ok,true);
 a.match(result.handoffToken,/^[A-Za-z0-9_-]{32}$/);
 a.equal(result.handoffToken.includes("biology"),false);
 a.equal(result.handoffToken.includes("11"),false);
 a.match(query,/INSERT INTO private\.iclub_ai_v21_home_action_handoffs_scratch/);
 a.doesNotMatch(query,/\bUPDATE\b|\bDELETE\b|practice_sessions_v4\s+SET/i);
 a.equal(result.navigationExecuted,false);
 a.equal(result.releaseAllowed,false);
});
test("§108 tamper, invented choices and invalid claim cannot consume token",()=>{
 const p=plan();
 const sql=()=>{throw Error("Should not read scratch for invalid claims");};
 const invalid={sql,signingKey:KEY,userId:OWNER,contextHandle:HANDLE,
  locale:"ru",handoffToken:"NOT-a-legitimate-token",
  actionCode:"continue_enrolled_subject",subjectKey:"biology"};
 a.equal(claimSyntheticHandoff(invalid).ok,false);
 a.equal(claimSyntheticHandoff({...invalid,handoffToken:"A".repeat(32),
  actionCode:"invented"}).ok,false);
 const result=issueSyntheticHandoff({...invalid,plan:{...p,
  actions:[{...p.actions[0],subjectKey:"economics"}]},
  delivered:{ready:true,reviewOnly:true,releaseAllowed:false,
   status:"candidate_only",expiresAtMs:p.expiresAtMs,
   actionCode:"continue_enrolled_subject",subjectKey:"biology"}});
 a.equal(result.ok,false,"Tampered HMAC must reject before any DB write");
 a.equal(possibleChoices({status:"selection_required",
   ready:true,reviewOnly:true,releaseAllowed:false,choices:[
    {actionCode:"continue_enrolled_subject",subjectKey:"biology"},
    {actionCode:"continue_enrolled_subject",subjectKey:"biology"}]}),null);
});
