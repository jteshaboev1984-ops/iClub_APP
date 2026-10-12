// iClub AI Layer v2.1 — existing DB schema-aware server context adapter.
// QA ONLY: no DB credentials, SQL calls, learner mutations, or active app imports.
// Every lookup is a server-authenticated mock service. Do not expose this to
// the browser or treat a client-provided subject/status as authority.
'use strict';
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const BIGINT=/^[1-9][0-9]{0,18}$/;
const DENY=(reason)=>({ok:false,reason});
const isValidTime=(v)=>typeof v==='string'&&Number.isFinite(Date.parse(v));
const same=(a,b,kind)=>{
 if(!a||!b||a.user_id!==b.user_id)return false;
 if(kind==='exam_prep_result')return a.status===b.status&&a.finalized_at===b.finalized_at&&
  a.component_code===b.component_code&&a.content_version_id===b.content_version_id;
 if(kind==='practice_result')return a.status===b.status&&a.finalized_at===b.finalized_at&&a.subject_id===b.subject_id;
 return a.status===b.status&&a.tour_id===b.tour_id;
};
class MockServerContextResolver {
 constructor(services={}) {
  for(const name of ['hasProtectedAssessment','getExamPrepSession',
   'getPracticeSession','getTourAttempt','getTourRuntime','getTourArchiveAccess','getSubjectById',
   'getTourById','subjectAccessAllowed']){
   if(typeof services[name]!=='function')throw Error('missing server service '+name);
  }
  this.services=services;
 }
 async resolve({principal,kind,resourceId,nowMs}={}){
  if(principal?.authenticated!==true||!UUID.test(principal?.userId||''))
   return DENY('auth_required');
  if(!Number.isSafeInteger(nowMs)||nowMs<0)return DENY('invalid_request');
  if(!['exam_prep_result','practice_result','tour_archive'].includes(kind))
   return DENY('surface_not_supported');
  if(kind==='exam_prep_result'&&!UUID.test(resourceId||''))return DENY('invalid_resource_id');
  if(kind!=='exam_prep_result'&&!BIGINT.test(String(resourceId||'')))return DENY('invalid_resource_id');
  const userId=principal.userId, S=this.services;
  const blocked=async()=>{try{return(await S.hasProtectedAssessment(userId))!==false}catch{return true}};
  if(await blocked())return DENY('protected_assessment');
  const fetch=kind==='exam_prep_result'?()=>S.getExamPrepSession(resourceId):
              kind==='practice_result'?()=>S.getPracticeSession(resourceId):
              ()=>S.getTourAttempt(resourceId);
  let row,originalTourRuntime=null;
  try{row=await fetch()}catch{return DENY('context_unavailable')}
  if(!row||row.user_id!==userId)return DENY('context_not_authorized');
  // All requirements derive from actual production schema. No client status.
  if(kind==='exam_prep_result') {
   if(row.status!=='finalized'||!isValidTime(row.finalized_at))
    return DENY('exam_prep_not_finalized');
   if(!['P1','P5'].includes(row.component_code))return DENY('component_unverified');
  } else if(kind==='practice_result') {
   if(row.status!=='finalized'||!isValidTime(row.finalized_at))
    return DENY('practice_not_finished');
  } else {
   if(!['submitted','time_expired'].includes(row.status))
     return DENY('tour_not_finished');
   // Tour attempt lacks finalized_at. Confirm separate runtime row.
   let runtime;
   try{runtime=await S.getTourRuntime(row.id)}catch{return DENY('tour_runtime_unavailable')}
   if(!runtime||runtime.attempt_id!==row.id||runtime.user_id!==userId||
       runtime.tour_id!==row.tour_id||!isValidTime(runtime.finalized_at))
     return DENY('tour_not_finished');
   originalTourRuntime=runtime;
  }
  let subjectKey='mathematics',category=kind==='exam_prep_result'?'exam_prep':kind==='practice_result'?'practice':'tour';
  try {
   if(kind==='practice_result') {
     const subject=await S.getSubjectById(row.subject_id);
     if(!subject||subject.id!==row.subject_id||subject.is_active!==true||
        typeof subject.subject_key!=='string')return DENY('subject_unverified');
     subjectKey=subject.subject_key;
   } else if(kind==='tour_archive') {
     // tour_attempts -> tours -> subjects; finalized_at alone does not unlock archive.
     const tour=await S.getTourById(row.tour_id);
     if(!tour||tour.id!==row.tour_id)return DENY('tour_unverified');
     const subject=await S.getSubjectById(tour.subject_id);
     if(!subject||subject.id!==tour.subject_id||subject.is_active!==true||
        typeof subject.subject_key!=='string')return DENY('subject_unverified');
     subjectKey=subject.subject_key;
     const archive=await S.getTourArchiveAccess({userId,tourId:row.tour_id,attemptId:row.id});
     if(archive?.unlocked!==true||archive?.ownerVerified!==true)
       return DENY('archive_locked');
   }
   const subjectApproved=await S.subjectAccessAllowed(userId,subjectKey);
   if(subjectApproved!==true)return DENY('subject_not_entitled');
  }catch{return DENY('context_unavailable')}
  // After awaits, re-read the session and global exam status; no stale success.
  let latest;
  try{latest=await fetch()}catch{return DENY('context_changed')}
  if(!same(row,latest,kind)||await blocked())return DENY('context_changed');
  try {
    if(await S.subjectAccessAllowed(userId,subjectKey)!==true)
      return DENY('context_changed');
  }catch{return DENY('context_changed')}
  if(kind==='tour_archive') {
    let latestRuntime, latestArchive;
    try {
      latestRuntime=await S.getTourRuntime(row.id);
      latestArchive=await S.getTourArchiveAccess({userId,tourId:row.tour_id,attemptId:row.id});
    }catch{return DENY('context_changed')}
    if(!latestRuntime||latestRuntime.user_id!==userId||
       latestRuntime.attempt_id!==row.id||latestRuntime.tour_id!==row.tour_id||
       !isValidTime(latestRuntime.finalized_at)||
       latestRuntime.finalized_at!==originalTourRuntime.finalized_at||
       latestArchive?.unlocked!==true||latestArchive?.ownerVerified!==true)
       return DENY('context_changed');
  }
  // Fail closed on missing real topic evidence: this is only an eligibility
  // snapshot, NOT approval to ask the model or bill the learner.
  return {ok:true,verifiedBy:'server_owned_existing_db',
   context:{kind,subject:subjectKey,scope:category,component:
    kind==='exam_prep_result'?row.component_code:null,
    sessionRef:resourceId,finalizedAt:kind==='tour_archive'?null:row.finalized_at,
    topic:null,sourceReady:false,routeAuthority:'unified_ai'}};
 }
}
module.exports={MockServerContextResolver};
