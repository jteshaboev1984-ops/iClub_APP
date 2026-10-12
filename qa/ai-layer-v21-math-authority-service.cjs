// iClub AI Layer v2.1 — server-only QA contract for the new Math authority RPC.
// No Supabase credentials, no live queries. A trusted server Edge supplies:
//   - a JWT-authenticated learner principal
//   - its own scope resolver, including routeAuthority='unified_ai'
//   - the existing Global AI guard, entitlement and QA release services
//   - a service-role-only read RPC returning APPROVED metadata without content.
// This is not imported by either deployed Edge or existing Exam Prep.
'use strict';
const UUID=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const denied=reason=>({ok:false,reason});
const validSkill=(component,skill)=>['P1','P5'].includes(component)&&
 typeof skill==='string'&&new RegExp('^'+component+'-[A-Z0-9]+-[0-9]{2}$').test(skill);
const sameSnapshot=(a,b)=>[
 'subject','scope','component','skill_code','locale','source_card_key',
 'source_version','source_hash','tutor_content_version','tutor_content_hash'
].every(key=>a?.[key]===b?.[key]);
class MathAuthorityV21 {
 constructor({verifyContext,globalGuard,readAuthorityRpc,releaseGate}={}){
  for(const [name,fn]of Object.entries({verifyContext,globalGuard,readAuthorityRpc,releaseGate}))
   if(typeof fn!=='function')throw Error('missing server dependency '+name);
  Object.assign(this,{verifyContext,globalGuard,readAuthorityRpc,releaseGate});
 }
 async evaluate({principal,handle,locale,stage='admission'}={}){
  if(principal?.authenticated!==true||!UUID.test(principal.userId||''))
   return denied('auth_required');
  if(typeof handle!=='string'||handle.length<8||handle.length>160)
   return denied('invalid_context_handle');
  if(!['ru','uz','en'].includes(locale))return denied('locale_unverified');
  if(!['admission','before_provider','before_delivery','replay'].includes(stage))
   return denied('invalid_stage');
  let context;
  try{context=await this.verifyContext({userId:principal.userId,handle});}
  catch{return denied('context_unverified');}
  if(!context||context.ownerId!==principal.userId
      ||context.routeAuthority!=='unified_ai'
      ||context.subject!=='mathematics'
      ||context.kind!=='exam_prep_result'
      ||context.protectedAssessment===true
      ||context.active!==true
      ||!UUID.test(context.sessionId||'')
      ||!validSkill(context.component,context.skill))
    return denied('context_unverified');
  // Caller does not supply subject/skill/user/tariff/route as academic authority.
  let guard,proof,ready;
  try{
    guard=await this.globalGuard({userId:principal.userId,
      subject:'mathematics',scope:'exam_prep',locale,stage});
    if(guard?.allowed!==true)return denied(guard?.reason||'global_ai_disabled');
    proof=await this.readAuthorityRpc('get_iclub_ai_math_skill_context_service_v2',{
      p_user_id:principal.userId,p_session_id:context.sessionId,
      p_skill_code:context.skill,p_locale:locale
    });
    if(proof?.allowed!==true)return denied(proof?.reason||'source_unverified');
    if(proof.subject!=='mathematics'||proof.scope!=='exam_prep'||
      proof.component!==context.component||proof.skill_code!==context.skill||
      proof.locale!==locale||proof.tutor_content_version!=='tutor_v3_learner_first'||
      !/^.{8,220}$/.test(String(proof.source_card_key||''))||
      !/^[0-9a-f]{64}$/i.test(String(proof.source_hash||''))||
      !/^[0-9a-f]{32}$/i.test(String(proof.tutor_content_hash||'')))
      return denied('source_contract_mismatch');
    ready=await this.releaseGate({
      userId:principal.userId,sourceKey:proof.source_card_key,
      sourceHash:proof.source_hash,skill:context.skill,component:context.component,
      locale,sourceVersion:proof.source_version
    });
    if(ready?.allowed!==true)return denied(ready?.reason||'topic_not_released');
  }catch{return denied('authority_backend_unavailable');}
  // Repeat auth, assessment and release checks after async read. This still
  // needs another invocation immediately before provider/response in real Edge.
  let newest,again;
  try{
    newest=await this.verifyContext({userId:principal.userId,handle});
    again=await this.globalGuard({userId:principal.userId,
      subject:'mathematics',scope:'exam_prep',locale,stage});
  }catch{return denied('context_changed');}
  if(!newest||newest.ownerId!==principal.userId||newest.active!==true||
     newest.routeAuthority!=='unified_ai'||newest.protectedAssessment===true||
     newest.sessionId!==context.sessionId||newest.skill!==context.skill||
     newest.component!==context.component||again?.allowed!==true)
     return denied('context_changed');
  // Return admission ONLY. No provider text, no progress, no quota charged.
  return {ok:true,authority:'server_verified',
    proof:{component:context.component,skill:context.skill,locale,
      sourceKey:proof.source_card_key,sourceHash:proof.source_hash,
      sourceVersion:proof.source_version,tutorHash:proof.tutor_content_hash}};
 }
 async stillValid(args,originalProof){
  const result=await this.evaluate({...args,stage:'before_delivery'});
  if(!result.ok)return result;
  const props=['component','skill','locale','sourceKey','sourceHash','sourceVersion','tutorHash'];
  if(!originalProof||props.some(k=>result.proof[k]!==originalProof[k]))
    return denied('source_changed');
  return result;
 }
}
module.exports={MathAuthorityV21};
