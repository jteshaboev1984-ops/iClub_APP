// iClub AI Layer v2.1 — QA-ONLY candidate Edge request orchestration.
// Isolated; NOT imported or deployed in supabase/functions/global-ai.
// All services are mocked in tests. No credentials, DB, provider or content.
// In production every injected service requires JWT-bound trusted backend access.
'use strict';
const {createHash}=require('node:crypto');
const {detectLanguage}=require('./ai-layer-v21-authority-gate.cjs');
const {ContentHandoffGate,localized}=require('./ai-layer-v21-content-handoff-gate.cjs');
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const POLICIES=new Set(['free_qa_v2','plus_qa_v2','pro_qa_v2']);
const SOURCE_HASH=/^[a-f0-9]{64}$/i;
const KEYS=new Set(['intent','requestId','contextHandle','promptKey','question','appLocale']);
const LIMIT_BYTES=4096;
const reason=(code,locale,details={})=>({ok:false,reason:code,...details});
const hash=v=>createHash('sha256').update(JSON.stringify(v)).digest('hex');
const clean=x=>typeof x==='string'?x.trim():'';
const UNSAFE_HTML_TAG=/<\s*\/?\s*[a-z][^>]*>/i;
const UNSAFE_TEXT_CONTROL=/[\x00-\x08\x0b\x0c\x0e-\x1f\x7f\u202a-\u202e\u2066-\u2069]/;
const validateText=reply=>typeof reply==='string'&&reply.trim().length>0&&
 reply.length<=3000&&!UNSAFE_HTML_TAG.test(reply)&&
 !UNSAFE_TEXT_CONTROL.test(reply)&&
 !/javascript\s*:/i.test(reply);
const same=(a,b)=>a?.state==='available'&&b?.state==='available'&&
 ['sourceId','sourceVersion','sourceHash','revision','contextRevision',
   'route','surface','subject','proofRevision','proofHash'].every(k=>a[k]===b[k]);
function parseBody(input){
 if(typeof input!=='string'||Buffer.byteLength(input,'utf8')>LIMIT_BYTES)return null;
 let body;try{body=JSON.parse(input)}catch{return null;}
 if(!body||typeof body!=='object'||Array.isArray(body))return null;
 if(Object.keys(body).some(k=>!KEYS.has(k)))return null;
 if(typeof body.contextHandle!=='string'||body.contextHandle.length<8||
  body.contextHandle.length>160)return null;
 if(!['ru','uz','en'].includes(body.appLocale))return null;
 if(!['status','answer'].includes(body.intent))return null;
 if(body.intent==='answer'&&!UUID.test(body.requestId||''))return null;
 if(body.intent==='status'&&(body.promptKey!==undefined||body.question!==undefined))return null;
 return body;
}
function fail(reasonCode,detail){
 return {ok:false,reason:reasonCode,...(detail?{detail}:{}),charge:0};
}
function response(status,body){return{status,body:{...body}};}
class CandidateEdgeRequest {
 constructor({services,allowedOrigins=[],admission=null}={}){
  const must=['authenticate','getPolicy','getSourceBundle','providerBudgetAllows',
   'generateSynthetic','reserveUsage','claimDelivery','finishDelivery',
   'reserveProviderSpend','dispatchProviderSpend','finishProviderSpend'];
  for(const k of must)if(typeof services?.[k]!=='function')
   throw Error('Missing trusted backend '+k);
  this.services=services;
  this.gate=admission&&typeof admission.check==='function'?
    admission:new ContentHandoffGate(services);
  this.allowedOrigins=new Set(allowedOrigins);
 }
 async serve({method,origin,authorization,bodyText}={}){
  if(method!=='POST')return response(405,fail('method_not_allowed'));
  if(origin!==undefined&&(!this.allowedOrigins.has(origin)))
   return response(403,fail('origin_not_authorized'));
  if(typeof authorization!=='string'||!/^Bearer [A-Za-z0-9._-]{8,2048}$/.test(authorization))
   return response(401,fail('authentication_required'));
  const body=parseBody(bodyText);
  if(!body)return response(400,fail('invalid_request'));
  let principal;
  try{principal=await this.services.authenticate(authorization);}
  catch{return response(401,fail('authentication_required'));}
  if(principal?.authenticated!==true||!UUID.test(principal.userId||''))
   return response(401,fail('authentication_required'));
  const {contextHandle,appLocale}=body;
  const status=()=>this.gate.check({principal,contextHandle,locale:appLocale});
  let readiness=await status();
  if(body.intent==='status')return response(200,this.publicStatus(readiness));
  let route,locale,question='',promptKey='';
  if(body.promptKey!==undefined){
   if(typeof body.promptKey!=='string'||!/^[a-z0-9_]{3,60}$/.test(body.promptKey)||
      (body.question!==undefined&&clean(body.question)))return response(400,fail('invalid_prompt'));
   route='prepared';promptKey=body.promptKey;locale=appLocale;
  }else{
   if(typeof body.question!=='string'||!clean(body.question)||body.question.length>2000)
     return response(400,fail('invalid_question'));
   question=clean(body.question);
   const lang=detectLanguage(question);
   if(!lang.ok)return response(400,fail(lang.reason));
   route='generated';locale=lang.locale;
   // Never silently use a different UI-selected source locale.
   if(locale!==appLocale)return response(409,fail('language_mismatch'));
  }
  if(readiness.state!=='available')return response(readiness.state==='hidden'?403:200,
    this.publicStatus(readiness));
  // The release is language-specific. Another language requires a NEW ready source.
  let policy,bundle;
  try{
   policy=await this.services.getPolicy({userId:principal.userId});
   if(!POLICIES.has(policy))return response(403,fail('plan_not_authorized'));
   if(policy==='free_qa_v2'&&route==='generated')
    return response(403,fail('generation_not_entitled'));
   bundle=await this.services.getSourceBundle({
     userId:principal.userId,contextHandle,locale,
     sourceId:readiness.sourceId,sourceVersion:readiness.sourceVersion,
     sourceHash:readiness.sourceHash,revision:readiness.revision,route,promptKey
   });
  }catch{return response(503,fail('source_unavailable'))}
  if(!bundle||bundle.approved!==true||bundle.rightsApproved!==true||
     bundle.integrityVerified!==true||bundle.qaPassed!==true||
     bundle.runtimeAllowed!==true||bundle.conflict===true||
     bundle.sourceId!==readiness.sourceId||
     bundle.sourceVersion!==readiness.sourceVersion||
     bundle.sourceHash!==readiness.sourceHash||
     bundle.revision!==readiness.revision||
     !SOURCE_HASH.test(String(bundle.sourceHash||'')))
    return response(200,this.publicStatus(localized(appLocale,'in_development')));
  let output='';
  if(route==='prepared'){
   output=bundle.variants?.[promptKey];
   if(!validateText(output))return response(200,this.publicStatus(localized(appLocale,'in_development')));
  }else{
   if(bundle.generationAllowed!==true||typeof bundle.sourceText!=='string'||
      bundle.sourceText.trim().length<8||bundle.sourceText.length>16000)
     return response(200,this.publicStatus(localized(appLocale,'in_development')));
   let affordable=false;
   try{affordable=await this.services.providerBudgetAllows({
     userId:principal.userId,sourceId:readiness.sourceId,route});
   }catch{return response(503,fail('provider_budget_unavailable'))}
   if(affordable!==true)return response(503,fail('provider_budget_unavailable'));
  }
  // Hash only immutable, server-derived context and provider-source binding.
  const fp=hash([principal.userId,contextHandle,locale,readiness.sourceId,
   readiness.sourceVersion,readiness.sourceHash,readiness.revision,route,promptKey,question]);
  const sessionFP=hash([principal.userId,contextHandle]);
  const usage={requestId:body.requestId,userId:principal.userId,policy,route,
   requestFingerprint:fp};
  let reserved;
  try{reserved=await this.services.reserveUsage(usage);}
  catch{return response(503,fail('reservation_unavailable'))}
  if(reserved?.allowed!==true)return response(409,fail(reserved?.reason||'reservation_denied'));
  let claimed;
  try{claimed=await this.services.claimDelivery({
    requestId:body.requestId,userId:principal.userId,sessionFingerprint:sessionFP,
    requestFingerprint:fp,route});
  }catch{return response(503,fail('delivery_claim_unavailable'))}
  if(claimed?.allowed!==true)return response(409,fail(claimed?.reason||'delivery_claim_denied'));
  let settled=false;
  const settle=async(outcome)=>{
   try{
    const x=await this.services.finishDelivery({
     requestId:body.requestId,userId:principal.userId,
     sessionFingerprint:sessionFP,requestFingerprint:fp,route,outcome
    });
    if(x?.ok===true)settled=true;
    return x?.ok===true;
   }catch{return false;}
  };
  const again=async()=>{
   // Every await may outlive the original bearer or entitlement. Re-authenticate
   // rather than treating an old principal or a browser plan as a live grant.
   const live=await this.services.authenticate(authorization);
   if(live?.authenticated!==true||live.userId!==principal.userId)return false;
   const livePolicy=await this.services.getPolicy({userId:principal.userId});
   if(livePolicy!==policy)return false;
   if(route==='generated'&&await this.services.providerBudgetAllows({
     userId:principal.userId,sourceId:readiness.sourceId,route
   })!==true)return false;
   const current=await this.gate.check({principal,contextHandle,locale});
   return same(readiness,current);
  };
  try{
   if(!await again())return await this.refuseSettled(settle,'context_changed');
   if(route==='generated'){
    // Preflight providerBudgetAllows() is NOT a spend permit. In particular
    // another Edge worker may exhaust the budget before we reach the model.
    // Bind all three money-RPC steps to the ONE durable learner claim.
    const money={requestId:body.requestId,userId:principal.userId,
     sessionFingerprint:sessionFP,requestFingerprint:fp};
    let held;
    try{held=await this.services.reserveProviderSpend(money);}
    catch{held={allowed:false};}
    if(held?.allowed!==true)
     return await this.refuseSettled(settle,'provider_budget_unavailable');
    if(!await again()){
     // Provider was definitely NOT contacted; only then no_charge is legal.
     try{await this.services.finishProviderSpend({...money,outcome:'no_charge'});}
     catch{/* Keep ledger held; never silently dispatch or reuse the ID. */}
     return await this.refuseSettled(settle,'context_changed');
    }
    let dispatched;
    try{dispatched=await this.services.dispatchProviderSpend(money);}
    catch{dispatched={allowed:false};}
    if(dispatched?.allowed!==true){
     // Dispatch ACK could be lost *after* database commit. Do NOT mark
     // no_charge, and do NOT send a second paid call. Held exposure remains.
     return await this.refuseSettled(settle,'provider_dispatch_unavailable');
    }
    // A gate can close while the dispatch RPC is in flight. Once dispatched,
    // the financial hold cannot be refunded without independent reconciliation.
    let modelFailed=false;
    try{
     if(!await again())modelFailed=true;
     else output=await this.services.generateSynthetic({
      userId:principal.userId,locale,question,sourceText:bundle.sourceText,
      sourceHash:bundle.sourceHash,sourceId:readiness.sourceId
     });
    }catch{modelFailed=true;}
    // An external timeout does not prove zero provider cost. Until trusted
    // provider usage/invoice verification exists, retain the FULL ceiling.
    let moneyFinished=false;
    try{
     const final=await this.services.finishProviderSpend({...money,outcome:'unknown'});
     moneyFinished=final?.ok===true;
    }catch{/* Fail CLOSED. */}
    if(!moneyFinished)return await this.refuseSettled(settle,'provider_accounting_unknown');
    if(modelFailed)return await this.refuseSettled(settle,'processing_unavailable');
   }
   if(!validateText(output))return await this.refuseSettled(settle,'output_rejected');
   if(!await again())return await this.refuseSettled(settle,'context_changed');
   const done=await settle('completed');
   if(!done)return response(503,fail('delivery_confirmation_unknown'));
   return response(200,{ok:true,reply:output});
  }catch{
   if(!settled)return await this.refuseSettled(settle,'processing_unavailable');
   return response(503,fail('delivery_confirmation_unknown'));
  }
 }
 async refuseSettled(settle,why){
  const released=await settle('released');
  return response(released?409:503,fail(released?why:'delivery_confirmation_unknown'));
 }
 publicStatus(state){
  if(state.state==='available')return{ok:true,state:'available',canAsk:true};
  if(state.state==='hidden')return{ok:false,state:'hidden',visible:false,canAsk:false,charge:0};
  return{ok:false,state:state.state,visible:true,canAsk:false,
   title:state.title,message:state.message,alternatives:state.alternatives||[],charge:0};
 }
}
module.exports={CandidateEdgeRequest,parseBody};
