// iClub AI Layer v2.1 — Mathematics Tutor read-only compatibility bridge.
// QA-only / pure function. NOT imported by legacy Exam Prep or deployed Edge.
// The entrypoint MUST be established by authenticated server routing, never UI.
'use strict';
const VARIANTS=Object.freeze({
 main:'main_explanation',
 simplify:'simple_explanation',
 rephrase:'alternative_explanation',
 focus:'focus_explanation'
});
const LOCALES=new Set(['ru','uz','en']);
const catalog=require('./ai-layer-v21-math-source-catalog.snapshot.json');
const INDEX=new Map(catalog.rows.map(r=>[`${r.component}|${r.skill}|${r.locale}`,r]));
const fail=reason=>({ok:false,reason});
function resolveMathPrepared({entrypoint,subject='mathematics',componentCode,skillCode,locale,
  mode,card,approvedSourceKeys=[],sourceVersion,expectedSourceVersion,
  contextVerified=false,topicApproved=false,protectedAssessment=false}={}) {
 // Maintain existing Math Tutor route: never impose a second unified quota.
 if(entrypoint==='legacy_exam_prep') return {ok:true,action:'legacy_passthrough',unifiedQuotaUnits:0};
 if(entrypoint!=='unified_ai') return fail('unknown_entrypoint');
 if(protectedAssessment===true) return fail('protected_assessment');
 if(contextVerified!==true||topicApproved!==true) return fail('context_unverified');
 if(subject!=='mathematics') return fail('subject_mismatch');
 if(!['P1','P5'].includes(componentCode))return fail('component_invalid');
 if(typeof skillCode!=='string'
    || !/^P[15]-[A-Z0-9]+-[0-9]{2}$/.test(skillCode)
    || !skillCode.startsWith(componentCode+'-'))return fail('skill_invalid');
 if(!LOCALES.has(locale))return fail('language_unverified');
 const approvedEntry=INDEX.get(`${componentCode}|${skillCode}|${locale}`);
 if(!approvedEntry)return fail('skill_not_in_verified_catalog');
 if(!Object.hasOwn(VARIANTS,mode))return fail('requires_separate_governed_route');
 if(!card||typeof card!=='object'||card.component_code!==componentCode
    ||card.skill_code!==skillCode||card.locale!==locale)return fail('tutor_card_mismatch');
 if(typeof sourceVersion!=='string'||!sourceVersion||sourceVersion!==expectedSourceVersion
    ||card.content_version!==sourceVersion) return fail('source_version_mismatch');
 const key=String(card.source_card_key||'').trim();
 if(key!==approvedEntry.source_key)return fail('source_catalog_mismatch');
 if(!key||!approvedSourceKeys.includes(key))return fail('source_not_approved');
 const message=String(card[VARIANTS[mode]]||'').trim();
 if(!message||message.length>8000||/<\s*script\b|javascript\s*:/i.test(message))return fail('prepared_variant_unavailable');
 // Do NOT fetch legacy Edge, grade/mark learner work or alter progress.
 // Unified tariff reservation happens exactly once in the separate new gateway.
 return {ok:true,action:'unified_prepared',route:'prepared',unifiedQuotaUnits:1,
    message,sourceVersion,variant:mode,providerCallRequired:false};
}
module.exports={resolveMathPrepared,VARIANTS};
