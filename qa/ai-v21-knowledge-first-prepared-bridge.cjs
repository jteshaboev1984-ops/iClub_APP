"use strict";
/**
 * Synthetic CI integration ONLY: exact Knowledge First finalized Practice
 * source admission -> EXISTING v21 prepared reply, quota and delivery claim.
 * No production import, no Supabase credentials, no deployment and no
 * independent academic authority. Does not include the existing Math Tutor.
 */
const {CandidateEdgeRequest,parseBody}=require("./ai-layer-v21-edge-request.cjs");
const {localized}=require("./ai-layer-v21-content-handoff-gate.cjs");
const hasOwn=(o,k)=>Object.prototype.hasOwnProperty.call(o,k);
function createPreparedKnowledgeFirstQaBridge({knowledge,services,allowedOrigins=[]}={}){
 if(process.env.CI!=="true"||
    process.env.ICLUB_AI_QA_BOUND_PREPARED!=="synthetic-only"||
    process.env.SUPABASE_URL||process.env.SUPABASE_SERVICE_ROLE_KEY||
    process.env.OPENAI_API_KEY||process.env.ANTHROPIC_API_KEY)
  throw Error("synthetic_ci_only");
 if(knowledge?.__syntheticQaOnly!==true||
    services?.__syntheticQaOnly!==true||
    typeof knowledge.resolve!=="function"||
    !Array.isArray(allowedOrigins)||allowedOrigins.length===0||
    allowedOrigins.some(x=>typeof x!=="string"||
      !/^https:\/\/[a-z0-9.-]+\.invalid$/.test(x)))
  throw Error("trusted_synthetic_dependencies_required");
 const origins=new Set(allowedOrigins);
 const denied=(locale,reason="in_development")=>({
  status:200,body:{ok:false,...localized(locale,reason),charge:0}
 });
 return Object.freeze({
  async serve(request={}){
   if(request.method!=="POST")return{status:405,body:{ok:false,reason:"method_not_allowed",charge:0}};
   if(!origins.has(request.origin))
    return{status:403,body:{ok:false,reason:"origin_not_authorized",charge:0}};
   const body=parseBody(request.bodyText);
   if(!body||body.intent!=="answer"||
      body.promptKey!=="explain_error"||
      hasOwn(body,"question"))
    return{status:400,body:{ok:false,reason:"invalid_prepared_route",charge:0}};
   let proof;
   try{
    proof=await knowledge.resolve({
     authorization:request.authorization,
     contextHandle:body.contextHandle,
     locale:body.appLocale,intent:"practice_card",promptKey:"explain_error"
    });
   }catch{return denied(body.appLocale);}
   // An active protected assessment must remain fully hidden, not advertise help.
   if(proof?.reason==="active_assessment")return denied(body.appLocale,"hidden");
   // The metadata proof cannot itself release content or grant a new plan.
   if(proof?.ok!==true||proof.reason!=="qa_source_verified"||
      proof.route!=="practice_card"||proof.releaseAllowed!==false||
      proof.providerCalled!==false||proof.billed!==false||
      typeof proof.sourceKey!=="string"||
      !/^[A-Za-z0-9][A-Za-z0-9:_-]{7,119}$/.test(proof.sourceKey))
    return denied(body.appLocale);
   const pinnedSource=proof.sourceKey;
   const pinned={
    ...services,
    getPublishedRelease:async ref=>{
     const row=await services.getPublishedRelease(ref);
     return row?.source_id===pinnedSource?row:null;
    },
    getLiveSourceProof:async ref=>{
     const result=await services.getLiveSourceProof(ref);
     return result?.source_id===pinnedSource?result:null;
    },
    getSourceBundle:async args=>{
     if(args.sourceId!==pinnedSource)return null;
     const bundle=await services.getSourceBundle(args);
     return bundle?.sourceId===pinnedSource?bundle:null;
    }
   };
   // CandidateEdgeRequest independently reauthenticates and rechecks current
   // exam, rollout, release and rights both before and after atomic metering.
   const edge=new CandidateEdgeRequest({services:pinned,
    allowedOrigins:[...origins]});
   return edge.serve(request);
  }
 });
}
module.exports={createPreparedKnowledgeFirstQaBridge};
