#!/usr/bin/env node
'use strict';
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const root=path.resolve(__dirname,'..'),read=p=>fs.readFileSync(path.join(root,p),'utf8');
const app=read('app.js'),host=read('exam-prep/exam-prep-host.js');
const tabs=read('practice-results-tabs.js'),css=read('practice-results-tabs.css'),html=read('index.html');
assert(app.includes('hubIdentityRoot.dataset.subjectKey'),'Subject hub must bind visible subject');
assert(app.includes('requestedSubject !== visibleSubject'),'Exam Prep must reject cross-subject click');
assert(app.includes('await host.syncSubjectHub({ subjectKey: requestedSubject'),'Host must resync before open');
assert(host.includes('requestedSubject !== visibleSubject'),'Host must fail closed on stale subject');
assert(host.includes('renderComingSoonShell()'),'Non-Mathematics must be informational only');
assert(app.includes('window.iClubPracticePremiumResult?.render?.'),'Result must mount premium view');
for(const token of ['iclub-result-hero','iclub-result-metrics','iclub-result-score-value',
  'iclub-result-ring','iclub-topic-history-metrics']) {
  assert(tabs.includes(token)||css.includes(token),'Missing premium UI '+token);
}
assert(app.includes('get_practice_topic_history_safe_v1'),'Topic history must use existing RPC');
assert(!app.includes('data-my-practice-mode="topics"'),'No nested Practice mode tabs');
assert(app.includes('get_current_practice_recommendations_safe_v1'),'Practice recommendations must be bank-scoped');
assert(!app.includes('update public.recommendations'),'No retroactive recommendation writes');
assert(html.includes('practice-results-tabs.js?v=stage03tabs2-premium2'));
assert(html.includes('practice-results-tabs.css?v=stage03tabs1-premium2'));
console.log('ICLUB_RELEASE_UX_FEEDBACK_OK subjects_guarded=1 result_premium=1 histories_unified=1 writes=0');
