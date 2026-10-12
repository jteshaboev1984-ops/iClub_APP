// iClub AI Layer v2.1 — COMPLETE MOCK integration, intentionally outside runtime.
// Not deployed: no SQL/Edge, payment, student writes or legacy exam-prep-ai imports.
// A real service MUST replace all services with authenticated read-only RPCs,
// atomically persist request IDs/usage, and independently review provider output.
'use strict';
const {createHash}=require('node:crypto');
const {detectLanguage}=require('./ai-layer-v21-authority-gate.cjs');
const {PreviewLedger}=require('./ai-layer-v21-preview-gateway.cjs');
const {SyntheticRequestDelivery}=require('./ai-layer-v21-request-delivery.cjs');
const catalog=require('./ai-layer-v21-math-source-catalog.snapshot.json');
const mathKeys=new Map(catalog.rows.map(r=>[r.component+'|'+r.skill+'|'+r.locale,r.source_key]));
const okLocale=new Set(['ru','uz','en']);
const plans=new Set(['free','plus','pro']);
const fail=reason=>({ok:false,reason});
const sha=s=>createHash('sha256').update(s).digest('hex');
const same=(a,b)=>a.fingerprint===b.fingerprint && a.route===b.route;
const requiredServices=['getTopicEvidence','getReviewedSource','getFeatureId',
 'getLearnerKind','getLearnerCohort','getPlan','providerBudgetAllows','generateMock'];
class SyntheticUnifiedAI {
 constructor({resolver,registry,services}={}){
  if(typeof resolver?.resolve!=='function'||typeof registry?.evaluate!=='function')
   throw Error('missing authoritative mocks');
  for(const name of requiredServices)if(typeof services?.[name]!=='function')
   throw Error('missing trusted service: '+name);
  this.resolver=resolver;this.registry=registry;this.services=services;
  this.ledger=new PreviewLedger();this.identities=new Map();this.modelCalls=0;
  this.delivery=new SyntheticRequestDelivery({
   authorize:async({request})=>{
    const now=await this.prepare(request);
    if(!now.ok)return false;
    const initial=this.identities.get(request.requestId);
    if(initial && !same(initial,now))return false;
    if(!initial)this.identities.set(request.requestId,{
      fingerprint:now.fingerprint,route:now.route
    });
    return true;
   },
   resolveIdentity:async({request})=>this.identities.get(request.requestId)||null,
   execute:async({request})=>this.execute(request)
  });
 }
 async prepare(request){
  if(!request||request.principal?.authenticated!==true)return fail('auth_required');
  if(typeof request.promptKey!=='string'&&request.promptKey!==undefined)return fail('invalid_request');
  const text=typeof request.question==='string'?request.question.trim():'';
  const quick=typeof request.promptKey==='string'&&request.promptKey.length>0;
  if(quick && text)return fail('conflicting_prompt_and_text');
  if(!quick && (!text || text.length>2000))return fail('invalid_question');
  const lang=quick?{ok:okLocale.has(request.appLocale),locale:request.appLocale}:detectLanguage(text);
  if(!lang.ok)return fail('language_ambiguous');
  const ctx=await this.resolver.resolve({principal:request.principal,kind:request.kind,
    resourceId:request.resourceId,nowMs:request.nowMs});
  if(!ctx.ok)return ctx;
  if(ctx.context.routeAuthority!=='unified_ai'||ctx.context.sourceReady!==false||
     ctx.context.topic!==null)return fail('context_not_authoritative');
  const uid=request.principal.userId;
  // The DB resolver calls the archive category 'tour'; the governed AI
  // surface is 'tour_archive'. No live Tour screen receives this permission.
  const surface=ctx.context.scope==='tour'?'tour_archive':ctx.context.scope;
  let evidence,source,plan,featureId,cohort,userKind;
  try{
   evidence=await this.services.getTopicEvidence({
     userId:uid,kind:request.kind,resourceId:request.resourceId,context:ctx.context
   });
   if(!evidence||evidence.ownerId!==uid||evidence.resourceId!==request.resourceId||
      evidence.kind!==request.kind||evidence.subject!==ctx.context.subject||
      evidence.component!==ctx.context.component||!evidence.evidenceId||
      !evidence.topic||!evidence.feature)return fail('topic_evidence_unverified');
   source=await this.services.getReviewedSource({
     subject:ctx.context.subject,surface,
     feature:evidence.feature,topic:evidence.topic,locale:lang.locale
   });
   if(!source||source.approved!==true||source.rightsApproved!==true||
      source.qaPassed!==true||source.conflict===true||!source.sourceId||
      !source.sourceVersion||!source.sourceKey||
      source.topic!==evidence.topic||source.feature!==evidence.feature||
      source.subject!==ctx.context.subject||source.locale!==lang.locale)
      return fail('source_not_ready');
   if(ctx.context.subject==='mathematics'){
     const actual=mathKeys.get(ctx.context.component+'|'+evidence.topic+'|'+lang.locale);
     if(!actual||actual!==source.sourceKey)return fail('math_source_mismatch');
   }
   featureId=await this.services.getFeatureId(ctx.context.subject,evidence.feature);
   cohort=await this.services.getLearnerCohort(uid);
   userKind=await this.services.getLearnerKind(uid);
   plan=await this.services.getPlan(uid);
  }catch{return fail('authoritative_lookup_unavailable')}
  const release=this.registry.evaluate({surface,subject:ctx.context.subject,
   feature:evidence.feature,topic:evidence.topic,locale:lang.locale,
   featureId,userKind,cohort});
  if(!release.allowed)return fail(release.reason);
  if(release.sourceId!==source.sourceId||release.sourceVersion!==source.sourceVersion)
   return fail('source_version_mismatch');
  if(!plans.has(plan))return fail('plan_not_authorized');
  let route;
  if(quick){
   if(!/^[a-z0-9_]{3,60}$/.test(request.promptKey)||
      !Object.hasOwn(source.variants||{},request.promptKey)||
      typeof source.variants[request.promptKey]!=='string'||
      !source.variants[request.promptKey].trim())
    return fail('prepared_variant_unavailable');
   route='prepared';
  }else{
   if(source.generationAllowed!==true||plan==='free')
    return fail(plan==='free'?'generation_not_entitled':'generation_not_ready');
   route='generated';
   try{if(await this.services.providerBudgetAllows(uid,evidence.feature)!==true)
     return fail('provider_budget_unavailable');}
   catch{return fail('provider_budget_unavailable')}
  }
  const sealed=[uid,request.sessionId,ctx.context.kind,request.resourceId,ctx.context.subject,
    ctx.context.component,evidence.evidenceId,evidence.feature,evidence.topic,lang.locale,
    source.sourceId,source.sourceVersion,source.sourceKey,route,request.promptKey||'',text];
  return {ok:true,fingerprint:sha(JSON.stringify(sealed)),route,source,evidence,ctx,plan,locale:lang.locale,text};
 }
 async execute(request){
  const approved=await this.prepare(request);
  if(!approved.ok)return approved;
  if(!same(this.identities.get(request.requestId)||{},approved))
   return fail('request_identity_mismatch');
  const {plan,route,source,fingerprint}=approved;
  const userId=request.principal.userId;
  const reserved=this.ledger.reserve({
    userId,plan,route,requestId:request.requestId,
    requestFingerprint:fingerprint,nowMs:request.nowMs
  });
  if(!reserved.ok)return reserved;
  if(reserved.alreadyCompleted)return fail('already_processed');
  try {
   let verified=await this.prepare(request);
   if(!verified.ok||!same(approved,verified))return fail('context_changed');
   let reply;
   if(route==='prepared')reply=source.variants[request.promptKey];
   else{
    this.modelCalls++;
    reply=await this.services.generateMock({
      userId,topic:approved.evidence.topic,sourceId:source.sourceId,
      sourceVersion:source.sourceVersion,locale:approved.locale,question:approved.text
    });
   }
   if(typeof reply!=='string'||!reply.trim()||reply.length>3000||
      /<\s*script\b|javascript\s*:/i.test(reply))return fail('output_validation_failed');
   verified=await this.prepare(request);
   if(!verified.ok||!same(approved,verified))return fail('context_changed');
   const finalized=this.ledger.finalize(request.requestId,reply,request.nowMs);
   return finalized.ok?{ok:true,reply}:fail(finalized.reason||'finalize_failed');
  }catch{return fail('provider_unavailable')}
  finally{
   const r=this.ledger.reservations.get(request.requestId);
   if(r?.status==='reserved')this.ledger.release(request.requestId);
  }
 }
 async submit(request){
  const r=await this.delivery.submit(request);
  return r.ok?{ok:true,reply:r.reply,duplicate:r.alreadyProcessed===true}
    :fail(r.reason);
 }
}
module.exports={SyntheticUnifiedAI};
