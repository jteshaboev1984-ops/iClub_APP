// iClub AI Layer v2.1 — proposed server-side decision contract, OFFLINE QA ONLY.
// This module must not be shipped as an authenticated API or be fed untrusted snapshots.
// Production will need actual signed session, DB/RPC ownership, and atomic quota controls.
'use strict';

const LOCALES=Object.freeze(['ru','uz','en']);
const HOUR=60*60*1000;
const contexts=new Set(['general','home','profile','lesson','exam_prep','practice','tour_archive']);
const normalize=s=>String(s||'').trim().toLowerCase();
const reject=(reason)=>({allowed:false,reason});
const LANGUAGE_SIGNALS={
  en: /\b(the|what|why|how|please|explain|because|another|example|could|would|should|topic|learn|solve|question)\b/i,
  uz: /\b(nima|nega|qanday|iltimos|tushuntir|mavzu|misol|uchun|yana|kerak|bilan|bo‘yicha|bo'yicha|boshqa|natija|xato)\b/i
};

/** Strict: do not guess EN/UZ from neutral or mixed text. Locale is not trust from UI. */
function detectLanguage(text) {
 const s=normalize(text);
 if(!s) return {ok:false,reason:'empty_question'};
 const latin=(s.match(/[a-z\u00c0-\u024f]/gi)||[]).length;
 const cyr=(s.match(/[а-яё]/gi)||[]).length;
 if(cyr && latin && cyr>=3 && latin>=3) return {ok:false,reason:'mixed_language'};
 if(cyr>=3 && cyr>latin*2) return {ok:true,locale:'ru'};
 if(latin<3) return {ok:false,reason:'language_ambiguous'};
 const en=LANGUAGE_SIGNALS.en.test(s),uz=LANGUAGE_SIGNALS.uz.test(s);
 if(en===uz) return {ok:false,reason:'language_ambiguous'};
 return {ok:true,locale:en?'en':'uz'};
}

/**
 * Args trusted from auth-bound backend ONLY:
 * principal {userId, authenticated}
 * getContext(handle,userId): context owned by this learner, including
 *   expiresAt, surface, subject, topic, feature, protectedAssessment,
 *   practiceCompleted, tourArchiveUnlocked, validity, activeForUser
 * getRelease(subject,feature,topic,locale,surface): reviewed readiness/source-set.
 * UI provides only a handle, short prompt key, and learner question.
 */
function approveRequest({principal,handle,question,promptKey='',appLocale='ru',now=0},services){
 if(!principal?.authenticated||!principal.userId) return reject('authentication_required');
 if(typeof handle!=='string'||handle.length<8||handle.length>160) return reject('invalid_context_handle');
 const ctx=services?.getContext?.(handle,principal.userId);
 if(!ctx||ctx.ownerId!==principal.userId||ctx.activeForUser!==true||ctx.expiresAt<=now) return reject('context_not_authorized');
 if(services?.runtime?.killSwitch!==false||services?.runtime?.gatewayEnabled!==true) return reject('ai_disabled');
 if(ctx.protectedAssessment===true||ctx.protectedTour===true) return reject('protected_assessment');
 if(!contexts.has(ctx.surface)) return reject('surface_not_supported');
 if(ctx.surface==='practice'&&ctx.practiceCompleted!==true) return reject('practice_not_finished');
 if(ctx.surface==='tour_archive'&&ctx.tourArchiveUnlocked!==true) return reject('archive_locked');
 if(services?.getUserEntitlement?.(principal.userId,ctx.subject,ctx.feature)!==true) return reject('not_entitled');
 let locale;
 if(promptKey) {
   if(typeof promptKey!=='string'||!/^([a-z0-9_]{3,60})$/.test(promptKey))return reject('invalid_prompt');
   if(typeof question==='string'&&question.trim()) return reject('conflicting_prompt_and_text');
   if(!LOCALES.includes(appLocale))return reject('language_ambiguous');
   locale=appLocale; // Quick prompt is localized, vetted and bound to its locale.
 } else {
   if(typeof question!=='string'||question.length>2000) return reject('invalid_question');
   const lang=detectLanguage(question);if(!lang.ok) return reject(lang.reason);
   locale=lang.locale;
 }
 const readiness=services?.getRelease?.({surface:ctx.surface,subject:ctx.subject,feature:ctx.feature,topic:ctx.topic,locale});
 if(!readiness||readiness.approved!==true||readiness.qaPassed!==true||!readiness.sourceVersion||!readiness.sourceId||readiness.locale!==locale) return reject('in_development');
 if(readiness.conflicting===true) return reject('source_conflict');
 if(promptKey && !readiness.promptKeys?.includes(promptKey))return reject('prepared_variant_unavailable');
 // Everything returned is from AUTH-BOUND context and verified source.
 return {allowed:true,
   trusted:{userId:principal.userId,contextId:ctx.id,subject:ctx.subject,surface:ctx.surface,feature:ctx.feature,topic:ctx.topic,
     locale,sourceId:readiness.sourceId,sourceVersion:readiness.sourceVersion,sourceSetHash:readiness.sourceSetHash||null,
     variant:promptKey||null},verification:'authoritative_context_v21'};
}
module.exports={approveRequest,detectLanguage,LOCALES,HOUR};
