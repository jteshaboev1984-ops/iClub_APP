// iClub AI v2.1 — ONE trusted screen-evidence adapter for all iClub surfaces.
// QA only. No database connection, writes, provider, learner storage or deployment.
// The injected readers MUST be JWT-bound, service-role protected and read-only.
// A missing authoritative server screen/record fails closed; client DOM is never proof.
"use strict";
const {createHash}=require("node:crypto");
const {QAAppWideFeatureAdmission}=require("./ai-layer-v21-app-wide-admission.cjs");
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const pos=v=>typeof v==="number"&&Number.isSafeInteger(v)&&v>0;
const nonempty=v=>typeof v==="string"&&v.length>0;
const validTime=v=>typeof v==="string"&&Number.isFinite(Date.parse(v));
const own=(x,u)=>x&&x.user_id===u;
const digest=x=>createHash("sha256").update(JSON.stringify(x)).digest("hex");
// This set is NOT a readiness grant; editorial release is checked independently.
const READERS=Object.freeze([
 "getCurrentScreen","readNavigationSource","readSubjectOverview",
 "readHomeNextActions","readProfileAggregate","readLesson",
 "readPracticeSessionV4","readPracticeAnswerV4",
 "readTourAttempt","readTourRuntime","readTourArchiveAccess"
]);
class TrustedAppWideServerAdapter {
 constructor(services){
  if(!services||READERS.some(name=>typeof services[name]!=="function"))
   throw Error("missing authenticated read-only screen evidence service");
  this.services=services;
  this.admission=new QAAppWideFeatureAdmission({
   ...services,
   getVerifiedScreenEvidence:(uid,handle)=>this.getVerifiedScreenEvidence(uid,handle)
  });
 }
 async check(args){return this.admission.check(args);}
 async getVerifiedScreenEvidence(uid,handle){
  if(!UUID.test(uid||"")||!nonempty(handle))return null;
  const S=this.services;
  try{
   // An authoritative screen record is essential for stale navigation/logout.
   // Proposed QA scoped-context SQL currently covers only Practice/Lessons.
   // Home/Profile/Tours/general MUST remain closed until their server proof exists.
   const [c,s]=await Promise.all([
    S.getScopedContext(uid,handle),S.getCurrentScreen(uid)
   ]);
   if(!c||c.ownerId!==uid||c.active!==true||
      c.routeAuthority!=="unified_ai"||!nonempty(c.contextRevision)||
      !s||!own(s,uid)||s.context_handle!==handle||
      s.context_revision!==c.contextRevision||
      s.current_view!==c.currentView||!nonempty(c.currentView)||
      !pos(s.revision)||s.active!==true||
      c.protectedAssessment===true)return null;
   // Do NOT accept proofId, verified, question answer, progress or source
   // metadata from the browser. Construct a minimal proof from server rows.
   let kind,revision=s.revision,resource=null,extra={};
   if(c.surface==="global"&&c.subject==="general"){
    const r=await S.readNavigationSource({userId:uid,view:c.currentView});
    if(r?.approved!==true||r?.current!==true||
       r.view!==c.currentView||!nonempty(r.version))return null;
    kind="app_navigation";
    resource=["navigation",r.view,r.version];
    extra.verified=true;
   }else if(c.surface==="global"&&c.feature==="subject_overview"){
    if(c.currentView!=="courses"||c.topic!=="overview"||
       c.subject==="general")return null;
    const r=await S.readSubjectOverview({userId:uid,subject:c.subject});
    if(r?.subject_key!==c.subject||r?.approved!==true||
       r?.current!==true||!nonempty(r.version))return null;
    kind="governed_subject_overview";
    resource=["overview",r.subject_key,r.version];
    extra.verified=true;
   }else if(c.surface==="home"&&c.subject==="general"){
    if(c.currentView!=="home"||c.topic!=="next_actions")return null;
    const r=await S.readHomeNextActions({userId:uid});
    if(!own(r,uid)||r.verified!==true||!pos(r.aggregate_revision)||
       !Array.isArray(r.next_actions))return null;
    kind="signed_next_actions";
    revision=r.aggregate_revision;
    resource=["home",r.aggregate_revision,r.next_actions];
    extra={verified:true,aggregateRevision:r.aggregate_revision};
   }else if(c.surface==="profile"&&c.subject==="general"){
    if(c.currentView!=="profile"||c.topic!=="progress")return null;
    const r=await S.readProfileAggregate({userId:uid});
    if(!own(r,uid)||r.verified!==true||!pos(r.aggregate_revision)||
       !Array.isArray(r.metrics))return null;
    kind="signed_progress_aggregate";
    revision=r.aggregate_revision;
    resource=["profile",r.aggregate_revision,r.metrics];
    extra={verified:true,aggregateRevision:r.aggregate_revision};
   }else if(c.surface==="lesson"&&c.subject!=="general"){
    if(c.currentView!=="courses"||!pos(c.lessonId))return null;
    const r=await S.readLesson({userId:uid,lessonId:c.lessonId});
    if(!r||r.id!==c.lessonId||r.subject_key!==c.subject||
       r.topic_key!==c.topic||r.is_active!==true||
       r.lesson_specific!==true||r.is_video!==false||
       r.access_authorized!==true||!pos(r.source_revision))return null;
    kind="approved_lesson_source";
    revision=r.source_revision;
    resource=["lesson",r.id,r.subject_key,r.topic_key,r.source_revision];
    extra={lessonSpecific:true,isVideo:false,lessonId:r.id};
   }else if(c.surface==="practice"&&c.subject!=="general"){
    if(c.currentView!=="courses"||!pos(c.practiceSessionId)||
       !pos(c.questionId))return null;
    const [r,a]=await Promise.all([
     S.readPracticeSessionV4({userId:uid,sessionId:c.practiceSessionId}),
     S.readPracticeAnswerV4({userId:uid,sessionId:c.practiceSessionId,questionId:c.questionId})
    ]);
    if(!own(r,uid)||r.id!==c.practiceSessionId||
       r.subject_key!==c.subject||r.status!=="finalized"||
       !validTime(r.finalized_at)||!Array.isArray(r.question_ids)||
       !r.question_ids.includes(c.questionId)||
       !own(a,uid)||a.session_id!==r.id||a.question_id!==c.questionId||
       a.server_checked!==true||a.is_final!==true||
       a.topic_key!==c.topic||!pos(a.revision))return null;
    kind="finalized_practice_answer";
    revision=a.revision;
    resource=["practice",r.id,c.questionId,r.finalized_at,a.revision,a.topic_key];
    extra={finalized:true,answerVerified:true,practiceSessionId:r.id,questionId:c.questionId};
   }else if(c.surface==="tour_archive"&&c.subject!=="general"){
    if(c.currentView!=="courses"||!pos(c.tourAttemptId))return null;
    const [r,t,a]=await Promise.all([
     S.readTourAttempt({userId:uid,attemptId:c.tourAttemptId}),
     S.readTourRuntime({userId:uid,attemptId:c.tourAttemptId}),
     S.readTourArchiveAccess({userId:uid,attemptId:c.tourAttemptId})
    ]);
    if(!own(r,uid)||r.id!==c.tourAttemptId||
       r.subject_key!==c.subject||
       !["submitted","time_expired"].includes(r.status)||
       !pos(r.tour_id)||!own(t,uid)||t.attempt_id!==r.id||
       t.tour_id!==r.tour_id||!validTime(t.finalized_at)||
       !own(a,uid)||a.attempt_id!==r.id||a.tour_id!==r.tour_id||
       a.owner_verified!==true||a.unlocked!==true||
       !pos(a.unlock_revision)||a.topic_key!==c.topic)return null;
    kind="opened_tour_archive";
    revision=a.unlock_revision;
    resource=["tour",r.id,r.tour_id,r.status,t.finalized_at,a.unlock_revision];
    extra={finalized:true,archiveUnlocked:true,tourAttemptId:r.id,
     archiveUnlockRevision:a.unlock_revision};
   }else return null;
   // Re-read screen after every domain query: a screen may change mid-await.
   const live=await S.getCurrentScreen(uid);
   if(!live||!own(live,uid)||live.active!==true||
      live.context_handle!==handle||live.context_revision!==c.contextRevision||
      live.current_view!==c.currentView||live.revision!==s.revision)return null;
   const base={ownerId:uid,contextRevision:c.contextRevision,
    surface:c.surface,subject:c.subject,feature:c.feature,topic:c.topic,
    currentView:c.currentView,kind,proofRevision:revision,
    proofId:kind+":"+String(resource[1]),
    proofHash:digest([uid,handle,c.contextRevision,s.revision,kind,resource])};
   return{...base,...extra};
  }catch{return null;}
 }
}
module.exports={TrustedAppWideServerAdapter,READERS};
