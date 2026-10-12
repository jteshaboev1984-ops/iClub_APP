// iClub AI Layer v2.1 — cross-subject, source-first admission (QA ONLY).
// NO imports from Exam Prep, no provider calls, tariffs, DB access or writes.
// Every dependency here is an authenticated read-only server mock. Production
// implementation must replace them with verified RPCs; these tests cannot
// authorize a real student or release any AI feature.
'use strict';
const inventory=require('./ai-layer-v21-subject-readiness-inventory.snapshot.json');
const ACTIVE=new Set(inventory.subjects.filter(s=>s.active).map(s=>s.subject));
const VALID_LOCALE=new Set(['ru','uz','en']);
const FAIL=reason=>({ok:false,reason,charge:0,providerCallRequired:false});
const integerId=v=>typeof v==='number'&&Number.isSafeInteger(v)&&v>0;
const releaseSame=(a,b)=>a?.sourceId===b?.sourceId&&a?.sourceVersion===b?.sourceVersion;
function trustedGlobal(x){
 return x?.killSwitch===false&&x?.gatewayEnabled===true&&x?.uiEnabled===true;
}
function sameProof(a,b){
 const keys=['subject','scope','topic','locale','sourceId','sourceKey','sourceHash',
  'sourceVersion','feature','questionId','proofKind'];
 return keys.every(key=>a?.[key]===b?.[key]);
}
class CrossSubjectAdmission {
 constructor({resolver,registry,services}={}){
  if(typeof resolver?.resolve!=='function'||typeof registry?.evaluate!=='function')
   throw Error('missing verified context/QA registry');
  for(const name of ['getGlobalRuntime','getSubjectStatus','getTopicEvidence',
    'getSourceProof','getFeatureId','getLearnerKind','getLearnerCohort',
    'hasActiveProtectedAssessment']){
    if(typeof services?.[name]!=='function')throw Error('missing service '+name);
  }
  this.resolver=resolver;this.registry=registry;this.services=services;
 }
 async admit(req){
  const {principal,kind,resourceId,locale,nowMs}=req||{};
  if(principal?.authenticated!==true||typeof principal.userId!=='string')
   return FAIL('auth_required');
  if(!Number.isSafeInteger(nowMs)||nowMs<0)return FAIL('invalid_request');
  if(!VALID_LOCALE.has(locale))return FAIL('language_not_ready');
  // All other future areas have NOT yet been verified for exact source/learner
  // ownership; they stay gated while the same visual shell can exist.
  if(!['practice_result','tour_archive'].includes(kind))
   return FAIL('in_development');
  if(!/^[1-9][0-9]{0,18}$/.test(String(resourceId)))return FAIL('invalid_resource');
  if(kind==='practice_result'&&!integerId(req.questionId))
   return FAIL('exact_question_required');
  const S=this.services,uid=principal.userId;
  const blocked=async()=>{
   try{return (await S.hasActiveProtectedAssessment(uid))!==false;}
   catch{return true;}
  };
  const runtime=async()=>{
   try{return trustedGlobal(await S.getGlobalRuntime());}catch{return false;}
  };
  if(await blocked())return FAIL('protected_assessment');
  if(!await runtime())return FAIL('global_ai_disabled');
  const context=await this.resolver.resolve({principal,kind,resourceId,nowMs});
  if(context?.ok!==true)return FAIL(context?.reason||'context_unverified');
  const c=context.context;
  if(!c||c.sourceReady!==false||c.topic!==null||c.routeAuthority!=='unified_ai')
   return FAIL('context_unverified');
  if(!ACTIVE.has(c.subject))return FAIL('subject_not_released');
  if(c.subject==='mathematics')return FAIL('legacy_math_isolated');
  let record,evidence,proof,featureId,cohort,learnerKind;
  const scope=kind==='tour_archive'?'tour_archive':'practice';
  try{
   record=await S.getSubjectStatus(c.subject);
   if(!record||record.subjectKey!==c.subject||record.active!==true)
    return FAIL('subject_not_released');
   evidence=await S.getTopicEvidence({
      userId:uid,kind,resourceId,questionId:req.questionId??null,subject:c.subject
   });
   if(!evidence||evidence.userId!==uid||evidence.resourceId!==resourceId||
      evidence.kind!==kind||evidence.subject!==c.subject||
      typeof evidence.topic!=='string'||!evidence.topic||
      typeof evidence.evidenceId!=='string'||!evidence.evidenceId)
      return FAIL('topic_evidence_unverified');
   if(kind==='practice_result'&&
      (evidence.questionId!==req.questionId||evidence.verifiedAnswer!==true))
      return FAIL('exact_question_unverified');
   if(kind==='tour_archive'&&evidence.archiveUnlocked!==true)
      return FAIL('archive_locked');
   proof=await S.getSourceProof({
     userId:uid,subject:c.subject,scope,topic:evidence.topic,locale,
     questionId:kind==='practice_result'?evidence.questionId:null,
     evidenceId:evidence.evidenceId,resourceId
   });
   if(!proof||proof.allowed!==true||proof.subject!==c.subject||proof.scope!==scope||
      proof.topic!==evidence.topic||proof.locale!==locale||
      !proof.sourceId||!proof.sourceKey||!proof.sourceVersion||
      !/^[0-9a-f]{64}$/i.test(String(proof.sourceHash||''))||
      proof.approvalStatus!=='approved'||proof.rightsStatus!=='original_iclub'||
      proof.runtimeAllowed!==true)
      return FAIL('approved_source_not_ready');
   // Exact-question response MUST bind to a specific approved source: generic
   // topic-only Economics cards may not be substituted for a question answer.
   if(kind==='practice_result'&&
      (proof.proofKind!=='exact_question'||proof.questionId!==req.questionId))
      return FAIL('exact_question_source_missing');
   if(kind==='tour_archive'&&proof.proofKind!=='opened_archive')
      return FAIL('archive_source_not_ready');
   featureId=await S.getFeatureId(c.subject,scope,evidence.topic);
   cohort=await S.getLearnerCohort(uid);
   learnerKind=await S.getLearnerKind(uid);
  }catch{return FAIL('authoritative_source_unavailable')}
  const evaluate=()=>this.registry.evaluate({surface:scope,subject:c.subject,
   feature:proof.feature,topic:evidence.topic,locale,featureId,
   userKind:learnerKind,cohort});
  const ready=evaluate();
  if(!ready.allowed||!releaseSame(ready,proof))
   return FAIL(ready.allowed?'source_release_mismatch':ready.reason);

  // Recheck AFTER all asynchronous reads. This is an admission proof only;
  // the real Edge must repeat the entire check immediately before provider
  // and delivery, and must also atomically account for quota/idempotency.
  if(await blocked()||!await runtime())return FAIL('context_changed');
  let after,newEvidence,newSource,nowSubject;
  try{
   [after,newEvidence,newSource,nowSubject]=await Promise.all([
    this.resolver.resolve({principal,kind,resourceId,nowMs}),
    S.getTopicEvidence({userId:uid,kind,resourceId,
      questionId:req.questionId??null,subject:c.subject}),
    S.getSourceProof({userId:uid,subject:c.subject,scope,topic:evidence.topic,
      locale,questionId:kind==='practice_result'?req.questionId:null,
      evidenceId:evidence.evidenceId,resourceId}),
    S.getSubjectStatus(c.subject)
   ]);
  }catch{return FAIL('context_changed')}
  if(after?.ok!==true||after.context?.subject!==c.subject||
     after.context?.sessionRef!==c.sessionRef||
     newEvidence?.evidenceId!==evidence.evidenceId||
     newEvidence?.questionId!==evidence.questionId||
     newEvidence?.verifiedAnswer!==evidence.verifiedAnswer||
     newEvidence?.archiveUnlocked!==evidence.archiveUnlocked||
     !sameProof(newSource,proof)||newSource?.allowed!==true||
     newSource?.runtimeAllowed!==true||newSource?.approvalStatus!=='approved'||
     newSource?.rightsStatus!=='original_iclub'||
     nowSubject?.active!==true||!evaluate().allowed||
     await blocked()||!await runtime())return FAIL('context_changed');

  // An admission is not an AI answer or a billable operation.
  return {ok:true,charge:0,providerCallRequired:false,
   authority:'server_proof_only',scope,subject:c.subject,
   topic:evidence.topic,locale,sourceId:proof.sourceId,
   sourceVersion:proof.sourceVersion,sourceHash:proof.sourceHash};
 }
}
module.exports={CrossSubjectAdmission,ACTIVE};
