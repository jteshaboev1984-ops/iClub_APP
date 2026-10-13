// iClub AI v2.1 — universal TECHNICAL content handoff, QA-only.
// No cards, questions, drafts, grading, DB updates, tariff or provider access.
// The content team publishes a GOVERNED release row separately. This resolver
// reads authoritative server state each request; it never relies on an old
// content inventory or a browser-provided subject/skill/locale-ready flag.
'use strict';
const VALID_LOCALE=new Set(['ru','uz','en']);
const GATES=['content_approved','rights_approved','source_version_verified',
  'correctness_passed','negative_tests_passed','exam_security_passed',
  'locale_verified','accessibility_passed'];
const TEXT={
 ru:{
  developingTitle:'В разработке',
  unavailableTitle:'Временно недоступно',
  developing:'AI-помощь по этой теме пока в разработке.',
  unavailable:'iClub AI временно недоступен. Попробуйте позже.',
  general:'Общая помощь iClub AI'
 },
 uz:{
  developingTitle:'Ishlab chiqilmoqda',
  unavailableTitle:'Vaqtincha mavjud emas',
  developing:'Bu mavzu bo‘yicha AI yordami hali tayyorlanmoqda.',
  unavailable:'iClub AI vaqtincha ishlamayapti. Keyinroq urinib ko‘ring.',
  general:'iClub AI umumiy yordami'
 },
 en:{
  developingTitle:'In development',
  unavailableTitle:'Temporarily unavailable',
  developing:'AI help for this topic is in development.',
  unavailable:'iClub AI is temporarily unavailable. Please try later.',
  general:'General iClub AI help'
 }
};
const SAME_KEYS=['surface','subject','feature','topic','locale',
 'source_id','source_version','source_hash','revision'];
function sameKeys(a,b,keys){return a&&b&&keys.every(k=>a[k]===b[k]);}
function published(row,ref){
 return row?.ready===true&&row.surface===ref.surface&&row.subject===ref.subject&&
  row.feature===ref.feature&&row.topic===ref.topic&&row.locale===ref.locale&&
  typeof row.source_id==='string'&&row.source_id.length>0&&
  typeof row.source_version==='string'&&row.source_version.length>0&&
  /^[0-9a-f]{64}$/i.test(String(row.source_hash||''))&&
  Number.isSafeInteger(row.revision)&&row.revision>0;
}
function approvedProof(p,row,ref){
 return p?.approved===true&&p?.rightsApproved===true&&p?.runtimeAllowed===true&&
   p?.sourceConflict!==true&&
   p?.surface===ref.surface&&p?.subject===ref.subject&&
   p?.feature===ref.feature&&p?.topic===ref.topic&&p?.locale===ref.locale&&
   p?.source_id===row.source_id&&p?.source_version===row.source_version&&
   p?.source_hash===row.source_hash;
}
function localized(locale,state,alternatives=[]){
 if(state==='hidden')return {state,visible:false,charge:0,providerCallRequired:false};
 const safeLocale=VALID_LOCALE.has(locale)?locale:'en';
 const out={state,visible:true,charge:0,providerCallRequired:false};
 if(state==='available')return {...out,canAsk:true};
 const developing=state==='in_development';
 return {...out,canAsk:false,
   title:TEXT[safeLocale][developing?'developingTitle':'unavailableTitle'],
   message:TEXT[safeLocale][developing?'developing':'unavailable'],
   alternatives};
}
class ContentHandoffGate {
 constructor(services){
  const req=['getGlobalState','isProtected','getScopedContext',
   'getSubjectActive','isRolloutAuthorized','getPublishedRelease','getLiveSourceProof',
   'getServerTimeMs'];
  for(const name of req)if(typeof services?.[name]!=='function')
   throw Error('missing server-only service '+name);
  this.services=services;
 }
 async check({principal,contextHandle,locale}={}){
  if(principal?.authenticated!==true||typeof principal.userId!=='string'||
    typeof contextHandle!=='string'||contextHandle.length<8)
    return localized(locale,'unavailable');
  const lang=VALID_LOCALE.has(locale)?locale:'en',S=this.services,uid=principal.userId;
  const serverNow=async()=>{try{
    const n=await S.getServerTimeMs();
    return Number.isSafeInteger(n)&&n>=0?n:null;
   }catch{return null;}};
  const nowMs=await serverNow();
  if(nowMs===null)return localized(lang,'unavailable');
  const protectedNow=async()=>{try{return(await S.isProtected(uid))!==false;}catch{return true;}};
  if(await protectedNow())return localized(lang,'hidden');
  const runtime=async()=>{try{
    const r=await S.getGlobalState();
    return r?.uiEnabled===true&&r?.gatewayEnabled===true&&
      r?.killSwitch===false&&r?.releaseApproved===true;
   }catch{return false;}};
  if(!await runtime())return localized(lang,'unavailable');
  let context;
  try{context=await S.getScopedContext(uid,contextHandle);}
  catch{return localized(lang,'unavailable');}
  if(context?.ownerId!==uid||context?.routeAuthority!=='unified_ai'||
     context?.active!==true||context?.protectedAssessment===true||
     !Number.isSafeInteger(context.expiresAtMs)||context.expiresAtMs<=nowMs||
     !context?.contextRevision||typeof context.contextRevision!=='string'||
     !context.surface||!context.subject||!context.feature||!context.topic)
    return localized(lang,'unavailable');
  const ref={surface:context.surface,subject:context.subject,
    feature:context.feature,topic:context.topic,locale:lang};
  const alive=async()=>{try{return(await S.getSubjectActive(context.subject))===true&&
    (await S.isRolloutAuthorized({userId:uid,context}))===true;}
    catch{return false;}};
  if(!await alive())return localized(lang,'in_development');
  const verified=async()=>{try{
    const row=await S.getPublishedRelease(ref);
    if(!published(row,ref))return null;
    const proof=await S.getLiveSourceProof(ref);
    if(!approvedProof(proof,row,ref))return null;
    return row;
   }catch{return null;}};
  let source=await verified();
  if(!source){
    // General Help is offered only when its own release/source/cohort check passes.
    // Never suggest unsafe shortcuts to a locked exam or unpublished content.
    let alternatives=[];
    if(!(ref.surface==='global'&&ref.subject==='general'&&ref.feature==='app_help')){
      const general={surface:'global',subject:'general',feature:'app_help',
        topic:'navigation',locale:lang};
      try{
        const authorized=await S.getSubjectActive('general')===true&&
          await S.isRolloutAuthorized({userId:uid,context:{...context,...general}})===true;
        if(authorized&&await verifiedGeneral(S,general))
         alternatives=[{id:'general_ai',label:TEXT[lang].general}];
      }catch{/* General Help must fail closed, never guessed from old docs. */}
    }
    if(await protectedNow())return localized(lang,'hidden');
    if(!await runtime())return localized(lang,'unavailable');
    return localized(lang,'in_development',alternatives);
  }
  // Never deliver a ready flag based only on a snapshot taken before awaits.
  let latest;
  try{latest=await S.getScopedContext(uid,contextHandle);}
  catch{return localized(lang,'unavailable');}
  const finalNow=await serverNow();
  if(!latest||latest.ownerId!==uid||latest.active!==true||
     latest.protectedAssessment===true||finalNow===null||latest.expiresAtMs<=finalNow||
     latest.contextRevision!==context.contextRevision||
     !sameKeys(latest,context,['surface','subject','feature','topic'])||
     !await alive()||await protectedNow()||!await runtime())
    return localized(lang,await protectedNow()?'hidden':'unavailable');
  const second=await verified();
  if(!second||!sameKeys(source,second,SAME_KEYS))
    return localized(lang,'in_development');
  // The final publication query is asynchronous: assess exam, revision and
  // authenticated screen AGAIN after it completes, not only before it began.
  if(await protectedNow())return localized(lang,'hidden');
  if(!await runtime()||!await alive())return localized(lang,'unavailable');
  let finalContext;
  try{finalContext=await S.getScopedContext(uid,contextHandle);}
  catch{return localized(lang,'unavailable');}
  const finalClock=await serverNow();
  if(finalClock===null||!finalContext||
     finalContext.ownerId!==uid||finalContext.active!==true||
     finalContext.protectedAssessment===true||
     finalContext.expiresAtMs<=finalClock||
     finalContext.contextRevision!==context.contextRevision||
     !sameKeys(finalContext,context,['surface','subject','feature','topic']))
    return localized(lang,'unavailable');
  // This is only an eligibility result, NOT authorization to debit/generate.
  // The Edge must still verify specific request/question/evidence and call
  // this again immediately before model use and before returning its answer.
  return {...localized(lang,'available'),sourceId:source.source_id,
    sourceVersion:source.source_version,sourceHash:source.source_hash,
    revision:source.revision,contextRevision:context.contextRevision};
 }
}
async function verifiedGeneral(S,ref){
 const row=await S.getPublishedRelease(ref);
 if(!published(row,ref))return false;
 const proof=await S.getLiveSourceProof(ref);
 return approvedProof(proof,row,ref);
}
module.exports={ContentHandoffGate,TEXT,GATES,localized};
