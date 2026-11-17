#!/usr/bin/env node
/* UX531 post-release tiny patch firewall. Original holistic #540 guard is unchanged.
   This is a stricter allowlist for one source-only branch from the released main.
   No database, browser accounts, deployment or network calls. */
'use strict';
const fs=require('node:fs');
const cp=require('node:child_process');
const assert=require('node:assert/strict');
const RELEASE='464551650ae925ca3404feff4a5c4c506c49cd70';
const base=String(process.env.UX531_BASE_SHA||'');
const head=String(process.env.UX531_EXPECTED_SHA||'');
const hex=/^[a-f0-9]{40}$/;
assert(hex.test(base)&&hex.test(head),'Base and head full SHAs required');
assert.equal(base,RELEASE,'Use original integrated firewall for any other base');
const git=(...args)=>cp.execFileSync('git',args,{encoding:'utf8',maxBuffer:10000000}).trimEnd();
assert.equal(git('rev-parse','HEAD'),head,'The exact reviewed commit must be checked out');
assert.equal(git('merge-base',base,head),base,'Release SHA must be an ancestor');
const changed=git('diff','--name-only',base,head).split('\n').filter(Boolean);
const allowed=new Set([
  '.github/workflows/exam-prep-weekly-answer-recovery.yml',
  '.github/workflows/exam-prep-weekly-profile-recovery.yml',
  '.github/workflows/ux531-previewless-release-firewall.yml',
  'docs/ui-redesign/27-ux531-math-post-mobile-six-point-polish-20261116.md',
  'exam-prep/exam-prep-api.js','exam-prep/exam-prep-live.js','index.html',
  'qa/ux531-math-p1p5-plan-runtime.cjs','qa/ux531-registered-navigation-e2e.cjs',
  'qa/ux531-postrelease-source-guard.cjs',
  'visual/iclub-academy-ux531-b02b03.css','visual/iclub-academy-ux531-b04b08.css'
]);
assert(changed.length>=8,'Expected substantive scoped follow-up, not an empty patch');
for(const p of changed)assert(allowed.has(p),'Forbidden release-scope change: '+p);
for(const p of [
  'exam-prep/exam-prep-live.js','exam-prep/exam-prep-api.js','index.html',
  'visual/iclub-academy-ux531-b02b03.css','visual/iclub-academy-ux531-b04b08.css',
  'qa/ux531-math-p1p5-plan-runtime.cjs'
])assert(changed.includes(p),'Required revised source/test absent: '+p);
const html=fs.readFileSync('index.html','utf8');
const api=fs.readFileSync('exam-prep/exam-prep-api.js','utf8');
const live=fs.readFileSync('exam-prep/exam-prep-live.js','utf8');
const pinned=fs.readFileSync('.github/workflows/exam-prep-weekly-answer-recovery.yml','utf8');
assert(html.includes('visual/iclub-academy-ux531-b02b03.css?v=ux531-b02b03-mobile-soft-v2') &&
  html.includes('visual/iclub-academy-ux531-b04b08.css?v=ux531-b04b08-mobile-touch-v2'),
  'Changed assets must have versioned client URLs');
assert(api.includes('exam-prep-live.js?v=p304aitutor1') &&
  api.includes('ux531-mobile-polish-20261116'),
  'Original centralized runtime identity and new cache version both required');
const pinnedMatch=pinned.match(/git hash-object exam-prep\/exam-prep-live\.js\)" = '([a-f0-9]{40})'/);
assert(pinnedMatch,'Existing audit pin removed');
assert.equal(git('hash-object','exam-prep/exam-prep-live.js'),pinnedMatch[1],
  'New pinned Math runtime must exactly match the audited source bytes');
const profileWorkflow=fs.readFileSync('.github/workflows/exam-prep-weekly-profile-recovery.yml','utf8');
const profilePin=profileWorkflow.match(/git hash-object exam-prep\/exam-prep-api\.js\)" = '([a-f0-9]{40})'/);
assert(profilePin,'Existing reviewed profile-recovery API pin removed');
assert.equal(git('hash-object','exam-prep/exam-prep-api.js'),profilePin[1],
  'Reviewed API source must exactly match profile recovery pin');
for(const token of [
  'async function reconcilePendingAnswer(pending)',
  'pending.idempotencyKey',
  "['learning','mixed','retest'].includes(state.session.session_type)",
  'data-ep-result-item-order=',
  'data-ep-result-session-type=',
  'localization_status === "unavailable"',
  'data-ep-history-paper-session',
  'data-ep-history-legacy-section',
  'epComponentTabs(component',
  'renderLoading("route")','renderLoading("paper", component)',
  'renderLoading("answer")'
])assert(live.includes(token),'Critical recovery/route invariant missing: '+token);
const indexDiff=git('diff','--unified=0',base,head,'--','index.html')
  .split('\n').filter(l=>l.startsWith('+')&&!l.startsWith('+++')&&!l.startsWith('@@'));
assert(indexDiff.length===3 &&
  indexDiff.every(l=>/^\+\s*<(?:link|script)\s/.test(l)),
  'Index changes must be only 3 cache-versioned CSS/script source tags');
const apiDiff=git('diff','--unified=0',base,head,'--','exam-prep/exam-prep-api.js')
  .split('\n').filter(l=>l.startsWith('+')&&!l.startsWith('+++')&&!l.startsWith('@@'));
assert(apiDiff.length===1 && apiDiff[0].includes('load(\'script[data-exam-prep-live]\''),
  'Exam Prep API must change only its dynamic live-script URL');
const runtimeDiff=git('diff','--unified=0',base,head,'--','exam-prep/exam-prep-live.js');
for(const line of runtimeDiff.split('\n')){
  if(!line.startsWith('+')||line.startsWith('+++')||/^\+\s*\/\//.test(line))continue;
  assert(!/localStorage\.(?:clear|removeItem)|\b(?:truncate|drop)\s+(?:table|schema)\b|\b(?:qa_open_all_core|rollout_state|ai_enabled|mentor_enabled|stage_gates_enabled)\s*[:=]/i.test(line),
    'Forbidden state/entitlement mutation: '+line.slice(0,150));
}
// The registered-navigation browser QA changes ONLY its 2-line pinned-colour
// expectation; no learner flow/auth/request checks may be softened in this PR.
const navDiff=git('diff','--unified=0',base,head,'--','qa/ux531-registered-navigation-e2e.cjs');
const navAdded=navDiff.split('\\n').filter(x=>x.startsWith('+')&&!x.startsWith('+++'));
const navRemoved=navDiff.split('\\n').filter(x=>x.startsWith('-')&&!x.startsWith('---'));
assert(navAdded.length===4 && navRemoved.length===2 &&
  navAdded.join(' ').includes('117, 165, 235') &&
  navAdded.join(' ').includes('193, 218, 250') &&
  navRemoved.join(' ').includes('242, 247, 255'),
  'Only the architect-updated blue pinned-card browser colour checks may change');
assert(!changed.some(p=>/^supabase\/|^api\/|^security\/|^content\/|^package|^vercel\.json|\.env/.test(p)),
  'No backend, question, dependency or secret edits permitted');
console.log('UX531 postrelease exact-SHA SOURCE-ONLY GUARD: PASS');
console.log('base='+base+' head='+head+' changed='+changed.length+' migrations=0 stateWrites=0');
