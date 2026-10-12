// iClub AI Layer v2.1 — QA ONLY, read-only Math Tutor RPC contract.
// Does NOT import, invoke, replace or modify the existing exam-prep-ai endpoint.
// Dependencies are synthetic server adapters; no network or DB calls here.
"use strict";
const {resolveMathPrepared}=require("./ai-layer-v21-math-tutor-bridge.cjs");
const EXPECTED_CONTENT_VERSION="tutor_v3_learner_first";
const FAIL=(reason)=>({ok:false,reason});
const same=(a,b)=>a.ownerId===b.ownerId&&a.subject===b.subject&&
 a.componentCode===b.componentCode&&a.skillCode===b.skillCode&&
 a.locale===b.locale&&a.contextVersion===b.contextVersion;
class MockMathTutorRpcBridge {
 constructor({getScopedContext,canUseUnifiedAI,rpc}={}) {
   if(typeof getScopedContext!=="function"||
      typeof canUseUnifiedAI!=="function"||
      typeof rpc!=="function")throw Error("missing server-only services");
   this.getScopedContext=getScopedContext;
   this.canUseUnifiedAI=canUseUnifiedAI;
   this.rpc=rpc;
 }
 async prepare({principal,contextHandle,mode,nowMs}={}){
   if(!principal?.authenticated||!principal.userId||typeof contextHandle!=="string"
      ||contextHandle.length<8||!Number.isSafeInteger(nowMs))return FAIL("authentication_required");
   // Entry route is fixed by this adapter: legacy Tutor never uses it.
   let context;
   try {context=await this.getScopedContext(principal.userId,contextHandle);}
   catch {return FAIL("context_unverified");}
   if(!context||context.ownerId!==principal.userId||context.expiresAt<=nowMs||
      context.active!==true)return FAIL("context_unverified");
   if(context.protectedAssessment===true)return FAIL("protected_assessment");
   if(context.subject!=="mathematics")return FAIL("subject_mismatch");
   if(!["P1","P5"].includes(context.componentCode))return FAIL("component_invalid");
   if(!["ru","uz","en"].includes(context.locale))return FAIL("language_unverified");
   let approved=false;
   try {approved=(await this.canUseUnifiedAI({userId:principal.userId,context}))===true;}
   catch {return FAIL("feature_not_ready");}
   if(!approved)return FAIL("feature_not_ready");
   // Existing, governed, source-backed read APIs. Never query/write student progress.
   let cards,card;
   try {
     cards=await this.rpc("get_exam_prep_ai_source_cards_service_v1",{
       p_component_code:context.componentCode,p_locale:context.locale,
       p_card_type:"theory",p_skill_code:context.skillCode,p_limit:8
     });
     card=await this.rpc("get_exam_prep_ai_tutor_card_service_v1",{
       p_component_code:context.componentCode,p_skill_code:context.skillCode,
       p_locale:context.locale
     });
   } catch {return FAIL("approved_source_unavailable");}
   if(!Array.isArray(cards))return FAIL("approved_source_unavailable");
   const approvedKeys=cards.map(x=>String(x?.source_card_key||"")).filter(Boolean);
   const adapted=resolveMathPrepared({
     entrypoint:"unified_ai",subject:context.subject,
     componentCode:context.componentCode,skillCode:context.skillCode,
     locale:context.locale,mode,card,approvedSourceKeys:approvedKeys,
     sourceVersion:EXPECTED_CONTENT_VERSION,expectedSourceVersion:EXPECTED_CONTENT_VERSION,
     contextVerified:true,topicApproved:true,protectedAssessment:false
   });
   if(!adapted.ok)return adapted;
   // Recheck after all awaits: subject navigation/assessment/content may change.
   let latest,stillApproved;
   try{
     latest=await this.getScopedContext(principal.userId,contextHandle);
     stillApproved=await this.canUseUnifiedAI({userId:principal.userId,context:latest});
   } catch {return FAIL("context_changed");}
   if(!latest||latest.active!==true||latest.expiresAt<=nowMs||latest.protectedAssessment===true||
       !same(context,latest)||stillApproved!==true)return FAIL("context_changed");
   // This prepared result will be charged by the NEW gateway once, never here.
   return {ok:true,route:"prepared",message:adapted.message,
     contentVersion:EXPECTED_CONTENT_VERSION,providerCallRequired:false,
     quotaHandled:false};
 }
}
module.exports={MockMathTutorRpcBridge,EXPECTED_CONTENT_VERSION};
