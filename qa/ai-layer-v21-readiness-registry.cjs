// iClub AI Layer v2.1 — isolated feature readiness and rollout contract.
// Synthetics only; not a deployed registry, no database nor real cohort writes.
'use strict';
const LOCALES=new Set(['ru','uz','en']);
const BOOL=(v)=>v===true;
const key=x=>[x.surface,x.subject,x.feature,x.topic,x.locale].map(y=>String(y||'').trim().toLowerCase()).join('|');
const fail=(reason)=>({allowed:false,reason});
const gates=['contentApproved','rightsApproved','sourceVersionVerified','correctnessPassed',
             'negativeTestsPassed','examSecurityPassed','localeVerified','accessibilityPassed'];

class PreviewFeatureRegistry {
 constructor({mode='preview',ownerApprovedBeta=false,authorizedCohorts=[],syntheticOnly=true}={}) {
  if(!['preview','beta'].includes(mode))throw Error('invalid mode');
  this.mode=mode;this.ownerApprovedBeta=ownerApprovedBeta;this.syntheticOnly=syntheticOnly;
  this.authorizedCohorts=new Set(authorizedCohorts);this.rows=new Map();this.flags=new Map();this.stopAll=false;
 }
 register(row) {
  if(!row||!LOCALES.has(row.locale)||!row.topic||!row.feature||!row.surface||!row.subject||!row.sourceId||!row.sourceVersion) throw Error('incomplete governed row');
  const k=key(row); if(this.rows.has(k))throw Error('duplicate or ambiguous readiness row');
  this.rows.set(k,Object.freeze({...row,gates:Object.freeze({...row.gates})}));
 }
 setFeatureEnabled(featureId,enabled) { if(typeof featureId!=='string'||!featureId)throw Error('invalid feature');this.flags.set(featureId,BOOL(enabled));}
 emergencyStopFeature(featureId){this.setFeatureEnabled(featureId,false);}
 emergencyStopAll(){this.stopAll=true;}
 canAutoEnable(rowId){
   const r=this.rows.get(rowId);if(!r)return fail('readiness_missing');
   if(!gates.every(g=>r.gates?.[g]===true))return fail('qa_not_green');
   if(r.sourceConflict===true)return fail('source_conflict');
   if(this.mode==='beta'&&!this.ownerApprovedBeta)return fail('beta_not_approved');
   return {allowed:true};
 }
 enableAfterGates(rowId){
   const gate=this.canAutoEnable(rowId);if(!gate.allowed)return gate;
   const r=this.rows.get(rowId);this.setFeatureEnabled(r.featureId,true);
   return {allowed:true};
 }
 evaluate({surface,subject,feature,topic,locale,featureId,userKind,cohort}) {
   if(this.stopAll)return fail('emergency_off');
   if(!LOCALES.has(locale))return fail('locale_not_supported');
   if(this.mode==='preview') {
     if(userKind!=='synthetic'||this.syntheticOnly!==true)return fail('preview_requires_synthetic');
   } else if(!this.ownerApprovedBeta||!this.authorizedCohorts.has(cohort)||userKind!=='authorized_beta')return fail('cohort_not_authorized');
   const r=this.rows.get(key({surface,subject,feature,topic,locale}));
   if(!r||r.featureId!==featureId)return fail('in_development');
   if(this.flags.get(r.featureId)!==true)return fail('feature_disabled');
   const gate=this.canAutoEnable(key(r));if(!gate.allowed)return gate;
   return {allowed:true,sourceId:r.sourceId,sourceVersion:r.sourceVersion};
 }
}
module.exports={PreviewFeatureRegistry,key,gates};
