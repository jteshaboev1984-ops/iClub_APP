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
      proof.route!=="practice_card"||
      proof.confirmedIncorrectAnswer!==true||proof.releaseAllowed!==false||
      proof.providerCalled!==false||proof.billed!==false||
      typeof proof.sourceKey!=="string"||
      !/^[A-Za-z0-9][A-Za-z0-9:_-]{7,119}$/.test(proof.sourceKey)||
      typeof proof.sourceVersion!=="string"||
      !/^[A-Za-z0-9][A-Za-z0-9._:-]{0,119}$/.test(proof.sourceVersion)||
      typeof proof.sourceHash!=="string"||
      !/^[a-f0-9]{64}$/.test(proof.sourceHash)||
      !Number.isSafeInteger(proof.publicationRevision)||
      proof.publicationRevision<1)
    return denied(body.appLocale);
   const pinnedSource=Object.freeze({
    id:proof.sourceKey,version:proof.sourceVersion,
    hash:proof.sourceHash,revision:proof.publicationRevision
   });
   // Same identifier with a changed payload, locale version or republished
   // editorial revision cannot cross the knowledge-to-delivery handoff.
   const matchesRelease=row=>row?.source_id===pinnedSource.id&&
    row.source_version===pinnedSource.version&&
    row.source_hash===pinnedSource.hash&&
    row.revision===pinnedSource.revision;
   const matchesProof=row=>row?.source_id===pinnedSource.id&&
    row.source_version===pinnedSource.version&&
    row.source_hash===pinnedSource.hash;
   const matchesBundle=bundle=>bundle?.sourceId===pinnedSource.id&&
    bundle.sourceVersion===pinnedSource.version&&
    bundle.sourceHash===pinnedSource.hash&&
    bundle.revision===pinnedSource.revision;
   const pinned={
    ...services,
    getPublishedRelease:async ref=>{
     const row=await services.getPublishedRelease(ref);
     return matchesRelease(row)?row:null;
    },
    getLiveSourceProof:async ref=>{
     const result=await services.getLiveSourceProof(ref);
     return matchesProof(result)?result:null;
    },
    getSourceBundle:async args=>{
     if(args.sourceId!==pinnedSource.id||
        args.sourceVersion!==pinnedSource.version||
        args.sourceHash!==pinnedSource.hash||
        args.revision!==pinnedSource.revision)return null;
     const bundle=await services.getSourceBundle(args);
     return matchesBundle(bundle)?bundle:null;
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
