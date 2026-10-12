// iClub AI Layer v2.1 — synthetic integration of server-owned context,
// feature readiness and shared 1:3 tariff ledger across distinct subject routes.
// STRICT QA ONLY: no real network, DB, auth, users, payments or AI calls.
'use strict';
const {approveRequest}=require('./ai-layer-v21-authority-gate.cjs');
const {PreviewGateway}=require('./ai-layer-v21-preview-gateway.cjs');
class SyntheticAIPipeline {
 constructor({services,registry,sources}) {
  if(!services||!registry||!Array.isArray(sources))throw Error('missing synthetic dependencies');
  this.services=services;
  this.registry=registry;
  this.gateway=new PreviewGateway({sources});
 }
 submit({requestId,principal,handle,question='',promptKey='',appLocale='ru',nowMs=0,provider='success'}) {
  const d=approveRequest({principal,handle,question,promptKey,appLocale,now:nowMs},this.services);
  if(!d.allowed)return {ok:false,reason:d.reason};
  const c=d.trusted;
  const cohort=this.services.getLearnerCohort?.(c.userId);
  const userKind=this.services.getLearnerKind?.(c.userId);
  const ready=this.registry.evaluate({
   surface:c.surface,subject:c.subject,feature:c.feature,topic:c.topic,locale:c.locale,
   featureId:this.services.getFeatureId?.(c.surface,c.subject,c.feature,c.topic),cohort,userKind
  });
  if(!ready.allowed)return {ok:false,reason:ready.reason};
  if(ready.sourceId!==c.sourceId||ready.sourceVersion!==c.sourceVersion)return {ok:false,reason:'governance_version_mismatch'};
  const plan=this.services.getLearnerPlan?.(c.userId);
  if(!['free','plus','pro'].includes(plan))return {ok:false,reason:'plan_not_authorized'};
  // Runtime provider spend permission is a SERVER decision, never a learner flag.
  const budgetAllowed=this.services.providerBudgetAllows?.(c.userId,c.subject,c.feature)===true;
  // Recheck trusted context/QA/entitlement before provider and BEFORE reply delivery.
  // A front-end claim cannot satisfy these checks; the callbacks live only on
  // the synthetic server service. Replace them with real server RPCs for release.
  const recheck=(stage,route)=>{
    const latest=approveRequest({principal,handle,question,promptKey,appLocale,now:nowMs},this.services);
    if(!latest.allowed)return false;
    const t=latest.trusted;
    if(t.userId!==c.userId || t.contextId!==c.contextId ||
       t.subject!==c.subject || t.surface!==c.surface ||
       t.feature!==c.feature || t.topic!==c.topic ||
       t.sourceId!==c.sourceId || t.sourceVersion!==c.sourceVersion ||
       t.locale!==c.locale)return false;
    const rr=this.registry.evaluate({
      surface:t.surface,subject:t.subject,feature:t.feature,topic:t.topic,locale:t.locale,
      featureId:this.services.getFeatureId?.(t.surface,t.subject,t.feature,t.topic),
      cohort:this.services.getLearnerCohort?.(t.userId),
      userKind:this.services.getLearnerKind?.(t.userId)
    });
    if(!rr.allowed || rr.sourceId!==t.sourceId || rr.sourceVersion!==t.sourceVersion) return false;
    if(this.services.getLearnerPlan?.(t.userId)!==plan)return false;
    if(route==='generated' && stage==='before_provider' &&
       this.services.providerBudgetAllows?.(t.userId,t.subject,t.feature)!==true) return false;
    return true;
  };
  const context={surface:c.surface,subject:c.subject,feature:c.feature,topic:c.topic,capabilityEnabled:true,
    // These capabilities were checked against the trusted context by approveRequest.
    protectedAssessment:false,activeTour:false,practiceCompleted:true,archiveUnlocked:true,
    serverRecheck:recheck};
  const result=this.gateway.request({requestId,user:{userId:c.userId,plan},context,
    question:{text:question,promptKey,resolvedLocale:c.locale},provider,budgetAllowed,nowMs});
  // Never return raw evidence, source key/versions, weights or internal scope to learner.
  if(result.ok)return {ok:true,reply:result.reply,duplicate:result.duplicate===true};
  return {ok:false,reason:result.reason};
 }
}
module.exports={SyntheticAIPipeline};
