#!/usr/bin/env node
/* UX531 source-only previewless firewall: no network, auth, DB, staging or deploy. */
'use strict';
const fs=require('node:fs');
const cp=require('node:child_process');
const assert=require('node:assert/strict');
const hex=/^[a-f0-9]{40}$/;
const base=String(process.env.UX531_BASE_SHA||'');
const expected=String(process.env.UX531_EXPECTED_SHA||'');
assert(hex.test(base)&&hex.test(expected),'Full base/head Git SHA required');
const git=(...args)=>cp.execFileSync('git',args,{encoding:'utf8',maxBuffer:8000000}).trimEnd();
const head=git('rev-parse','HEAD');
assert.equal(head,expected,'Checkout mismatch');
assert.equal(git('merge-base',base,head),base,'Expected main base is not ancestor');
const files=git('diff','--name-only',base,head).split('\n').filter(Boolean);
assert(files.length>0 && ['app.js','index.html','registration-b00-ui.js',
'exam-prep/exam-prep-live.js'].every(p=>files.includes(p)),
'Unexpected or empty Academy OS integrated candidate');
const core=new Set(['app.js','index.html','i18n.js','registration-b00-ui.js',
'exam-prep/exam-prep-live.js','exam-prep/exam-prep-overview-placement.js']);
for(const file of files){
  const allowed=core.has(file)||/^(visual\/|qa\/|scripts\/|docs\/|\.github\/scripts\/|\.github\/workflows\/)/.test(file)||
    file==='supabase/tests/p2_02_stage3_syllabus_closure_matrix.sql';
  assert(allowed,'Unreviewed path in UX source-only release: '+file);
  assert(!/^supabase\/(migrations|functions|seeds)\//.test(file),
    'Forbidden DB migration/function/seed in UX release: '+file);
  assert(!/(^|\/)\.env(?:\.|$)|(^|\/)(?:vercel\.json|package(?:-lock)?\.json|supabase\/config\.toml)$/.test(file),
    'Forbidden deployment/dependency/secret file: '+file);
}
const app=fs.readFileSync('app.js','utf8');
const index=fs.readFileSync('index.html','utf8');
const reg=fs.readFileSync('registration-b00-ui.js','utf8');
const exam=fs.readFileSync('exam-prep/exam-prep-live.js','utf8');
const sql=fs.readFileSync('supabase/tests/p2_02_stage3_syllabus_closure_matrix.sql','utf8');
for(const [label,src,token] of [
['B00 original field DOM',reg,'originalChildren'],
['B00 form submit guarded',reg,'form.addEventListener("submit"'],
['architect non-school Study requirement',app,'if (!isSchoolStudent && !main1)'],
['owner-bound Home Continue',app,'identity.currentUid() !== uid'],
['existing Practice resume handler',app,'await openPracticeStart()'],
['P1/P5 view tabs',exam,'epComponentTabs(component'],
['ungraded S4 Paper history',exam,'data-ep-history-paper-session'],
['legacy Core history',exam,'data-ep-history-legacy-section'],
['D03 revoked self-mark RPC',sql,'P2-02 D03 written self-mark RPC access firewall drift'],
['D03 non-comparability',sql,'P2-02 D03 violation: legacy self-marks made Paper comparable']
]) assert(src.includes(token),label+' invariant missing');
assert(index.includes('registration-b00-ui.js') &&
  index.includes('visual/iclub-academy-ux531-b04b08.css'),
  'Full Academy/B00 assets must remain present');
assert(/^\s*BEGIN\s*;/im.test(sql)&&/^\s*ROLLBACK\s*;/im.test(sql),
  'D03 negative fixture must be rollback-only');
const patch=git('diff','--unified=0',base,head,'--','app.js','index.html',
  'registration-b00-ui.js','exam-prep/exam-prep-live.js',
  'visual/iclub-academy-ux531-interactions.js');
for(const line of patch.split('\n')){
 if(!line.startsWith('+')||line.startsWith('+++')||
    /^\+\s*(?:\/\/|\/\*|\*|<!--)/.test(line))continue;
 assert(!/localStorage\.(?:clear|removeItem)\s*\(|(?:truncate|drop)\s+(?:table|schema)\b/i.test(line),
    'Destructive code added to learner UI: '+line.slice(0,160));
 assert(!/\b(?:ai_enabled|mentor_enabled|qa_open_all_core|rollout_state)\s*[:=]\s*(?:true|false|'mass'|"mass")/i.test(line),
    'Unexpected flag activation in UI: '+line.slice(0,160));
}
console.log('UX531 PREVIEWLESS RELEASE SOURCE FIREWALL: PASS');
console.log('candidate='+head+' base='+base+' changes='+files.length);
console.log('UI only; migrations=0; production_writes=0; no paid staging');
console.log('human Math acceptance and independently verified Paper grading still UNPROVEN');
