"use strict";
// QA-only, SERVER-SIDE read-only knowledge-first gate.
// Not mounted by Preview, production app, Edge Function or Exam Prep Tutor.
// Never reads a browser-provided user ID or uses a paid model/financial RPC.
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const HASH64=/^[a-f0-9]{64}$/;
const HASH32=/^[a-f0-9]{32}$/;
const LANG=new Set(["ru","uz","en"]);
const KEY=/^[a-z][a-z0-9_]{2,79}$/;
// Actual canonical keys include colons, hyphens and uppercase skills.
const CARD_KEY=/^[A-Za-z0-9][A-Za-z0-9:_-]{7,119}$/;
const HELP=new Set(["support_help","ratings_help","practice_rules","tour_rules",
 "catalog_help","about_help","certificates_help","books_help",
 "notifications_help","community_help","recs_help","archive_help",
 "video_help","home_next","subject_study"]);
const PROTECTED=new Set(["practice-quiz","tour-quiz","exam-prep",
 "exam_prep_assessment","exam_prep_diagnostic","exam_prep_retest",
 "exam_prep_mixed","exam_prep_timed","exam_prep_paper"]);
const ROUTES=new Set(["app_help","home_next","math_card","practice_card"]);
const SERVICES=["authenticate","readCurrentScope","readProtected",
 "verifySubjectRights","readApprovedSource","nowMs"];
const denied=(reason="in_development")=>Object.freeze({ok:false,reason,
 releaseAllowed:false,providerCalled:false,academicStateChanged:false,
 billed:false});
const object=x=>x!==null&&typeof x==="object"&&!Array.isArray(x);
const fresh=(x,n)=>Number.isSafeInteger(x)&&x>n&&x-n<=90000;
const match=(a,b)=>JSON.stringify(a)===JSON.stringify(b);
const verifiedScreen=(s,uid,handle,lang,now)=>
 object(s)&&s.proof==="server_owner_current_screen_v1"&&
 s.ownerId===uid&&s.contextHandle===handle&&
 Number.isSafeInteger(s.revision)&&s.revision>0&&
 fresh(s.expiresAtMs,now)&&s.locale===lang&&
 typeof s.screenCode==="string"&&typeof s.scopeCode==="string"&&
 KEY.test(s.subjectKey||"")&&s.assessmentActive===false;
const verifiedProtection=(p,uid,rev)=>
 object(p)&&p.proof==="owner_bound_assessment_guard_v1"&&
 p.ownerId===uid&&p.contextRevision===rev&&p.protected===false;
const verifiedRights=(r,uid,s,intent)=>
 object(r)&&r.allowed===true&&r.proof==="server_entitlement_v1"&&
 r.ownerId===uid&&r.contextRevision===s.revision&&
 r.subjectKey===s.subjectKey&&r.feature===intent;
function locate(s,intent,promptKey){
 if(intent==="app_help"){
  if(!HELP.has(promptKey)||s.scopeCode!=="global"||
     s.screenCode==="exam_prep_skill")return null;
  if(promptKey==="subject_study"&&s.screenCode!=="subject-hub")return null;
  return{type:"app_help",key:promptKey,locale:s.locale,
   subjectKey:s.subjectKey};
 }
 if(intent==="home_next"){
  if(s.screenCode!=="home"||s.scopeCode!=="global"||
     s.subjectKey!=="general")return null;
  return{type:"home_next",key:"home_next",locale:s.locale,
   subjectKey:"general"};
 }
 if(intent==="math_card"){
  const c=s.componentCode,k=s.skillCode;
  if(s.screenCode!=="exam_prep_skill"||s.scopeCode!=="exam_prep"||
     s.subjectKey!=="mathematics"||!["P1","P5"].includes(c)||
     typeof k!=="string"||!new RegExp("^"+c+"-[A-Z0-9]+(?:-[A-Z0-9]+)*$").test(k))
    return null;
  if(!["main","simple","alternative","focus"].includes(promptKey))
    return null;
  return{type:"math_card",key:promptKey,locale:s.locale,
   subjectKey:"mathematics",componentCode:c,skillCode:k};
 }
 if(intent==="practice_card"){
  if(s.screenCode!=="practice-review"||s.scopeCode!=="global"||
     s.subjectKey==="general"||s.finalized!==true||
     s.ownsAnsweredQuestion!==true||
     !Number.isSafeInteger(s.questionId)||s.questionId<1||
     promptKey!=="explain_error")return null;
  return{type:"practice_card",key:"explain_error",locale:s.locale,
   subjectKey:s.subjectKey,questionId:s.questionId};
 }
 return null;
}
const validCard=(route,card)=>{
 if(!object(card)||card.locale!==route.locale)return false;
 if(route.type==="app_help")
  return card.help_key===route.key&&
   card.subject_key==="general"&&
   typeof card.message==="string"&&card.message.length>10&&
   card.message.length<=1800&&HASH64.test(card.content_hash||"")&&
   typeof card.source_version==="string"&&card.source_version.length>0;
 if(route.type==="math_card")
  return card.component_code===route.componentCode&&
   card.skill_code===route.skillCode&&
   CARD_KEY.test(card.tutor_card_key||"")&&CARD_KEY.test(card.source_card_key||"")&&
   HASH32.test(card.content_hash||"")&&
   typeof card.content_version==="string"&&card.content_version.length>0&&
   ["main_explanation","simple_explanation","alternative_explanation",
    "focus_explanation"].every(k=>typeof card[k]==="string"&&
     card[k].length>10&&card[k].length<=8000);
 if(route.type==="practice_card")
  return card.subject_key===route.subjectKey&&
   card.question_id===route.questionId&&
   card.card_type==="answer_explanation"&&
   CARD_KEY.test(card.source_card_key||"")&&
   HASH64.test(card.content_hash||"")&&
   typeof card.source_version==="string"&&card.source_version.length>0&&
   typeof card.body_text==="string"&&card.body_text.length>10&&
   card.body_text.length<=8000;
 return false;
};
const meta=(route,card)=>{
 const isMath=route.type==="math_card";
 return{sourceKey:card.source_card_key||card.help_key,
   cardHash:card.content_hash,
   contentVersion:isMath?card.content_version:card.source_version};
};
const publicationOk=(p,route,card)=>
 object(p)&&p.approved===true&&p.rightsApproved===true&&
 p.runtimeAllowed===true&&p.contentApproved===true&&
 p.conflict===false&&p.qaPassed===true&&
 p.locale===route.locale&&p.subjectKey===route.subjectKey&&
 p.sourceKey===meta(route,card).sourceKey&&
 p.cardHash===meta(route,card).cardHash&&
 p.contentVersion===meta(route,card).contentVersion;
function createKnowledgeFirstReadOnlyGate(services){
 if(!object(services)||SERVICES.some(k=>typeof services[k]!=="function"))
  throw Error("missing_trusted_server_service");
 return Object.freeze({
  async resolve({authorization,contextHandle,locale,intent,promptKey}={}){
   if(typeof authorization!=="string"||
      !/^Bearer [A-Za-z0-9._-]{16,2048}$/.test(authorization)||
      !UUID.test(contextHandle||"")||!LANG.has(locale)||
      !ROUTES.has(intent)||typeof promptKey!=="string"||
      promptKey.length>80)return denied();
   try{
    // Auth is looked up from the JWT by a TRUSTED server callback.
    // Caller-supplied userId, subject, screen, grades or key are never read.
    const auth=await services.authenticate(authorization);
    if(auth?.authenticated!==true||auth.proof!=="verified_supabase_auth_v1"||
       !UUID.test(auth.userId||""))return denied();
    const userId=auth.userId,now=services.nowMs();
    if(!Number.isSafeInteger(now))return denied();
    const screen=await services.readCurrentScope(userId,contextHandle,locale);
    if(!verifiedScreen(screen,userId,contextHandle,locale,now))return denied();
    if(PROTECTED.has(screen.screenCode))return denied("active_assessment");
    const protection=await services.readProtected(userId);
    if(!verifiedProtection(protection,userId,screen.revision))
      return denied("active_assessment");
    const route=locate(screen,intent,promptKey);
    if(!route)return denied();
    const rights=await services.verifySubjectRights(userId,screen,intent);
    if(!verifiedRights(rights,userId,screen,intent))return denied();
    if(intent==="home_next"){
     // Signed Home priority engine currently returns releaseAllowed=false.
     // Do NOT invent a personalized student recommendation in the meantime.
     if(typeof services.chooseApprovedHome!=="function")return denied();
     const selection=await services.chooseApprovedHome({userId,contextHandle,locale});
     if(selection?.ready!==true||selection.releaseAllowed!==false||
        !["candidate_only","selection_required"].includes(selection.status))
      return denied();
     const last=await services.readCurrentScope(userId,contextHandle);
     const safe=await services.readProtected(userId);
     if(!match(last,screen)||!match(safe,protection)||
       services.nowMs()>=screen.expiresAtMs)return denied();
     return Object.freeze({ok:true,reason:"qa_home_candidate_only",
      candidateStatus:selection.status,releaseAllowed:false,
      personalizedAnswerDelivered:false,providerCalled:false,
      billed:false,academicStateChanged:false});
    }
    const method={app_help:"readPreparedHelp",math_card:"readMathTutorCard",
     practice_card:"readPracticeSourceCard"}[intent];
    if(typeof services[method]!=="function")return denied();
    const card=await services[method](route,userId);
    // A list or generic topic fallback is NOT valid for explaining a
    // learner's exact finalized Practice mistake.
    if(!validCard(route,card))return denied();
    const published=await services.readApprovedSource(route,card);
    if(!publicationOk(published,route,card))return denied();
    // Owner, entitlement, source publication and protected state can change
    // across asynchronous reads. Recheck them all before a QA-only handoff.
    const latestRights=await services.verifySubjectRights(userId,screen,intent);
    const latestSource=await services.readApprovedSource(route,card);
    const latestProtected=await services.readProtected(userId);
    const latestScreen=await services.readCurrentScope(userId,contextHandle,locale);
    const finished=services.nowMs();
    if(!verifiedRights(latestRights,userId,screen,intent)||
       !match(latestRights,rights)||
       !publicationOk(latestSource,route,card)||
       !match(latestSource,published)||
       !match(latestProtected,protection)||
       !match(latestScreen,screen)||
       !Number.isSafeInteger(finished)||finished<now||
       finished>=screen.expiresAtMs)return denied();
    // NO content or personal evidence in this result: it is a server-side
    // integration PROOF only. A separate current-context delivery release
    // is required before any learner-visible card/text can be returned.
    return Object.freeze({ok:true,reason:"qa_source_verified",
     route:intent,sourceKey:meta(route,card).sourceKey,
     releaseAllowed:false,learnerVisibleText:null,
     providerCalled:false,billed:false,academicStateChanged:false,
     existingExamPrepTutorPreserved:intent==="math_card"});
   }catch{return denied();}
  }
 });
}
module.exports={createKnowledgeFirstReadOnlyGate,locate,validCard,publicationOk};
