#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const migration=fs.readFileSync(path.join(root,'supabase/migrations/20261008150000_practice_topic_switch_atomic_v1.sql'),'utf8');
const api=fs.readFileSync(path.join(root,'security/legacy-assessment-safe-api.js'),'utf8');
for(const term of [
  'auth.uid()','pg_advisory_xact_lock','for update',
  's.user_id=v_uid','s.subject_id=v_subject_id',
  "s.drill_type='rec_topic'","s.status='in_progress'",
  "v_old.status='abandoned'",
  'public.start_practice_topic_drill_choice_safe_v1(',
  "set status='abandoned'",
  "'old_session_abandoned',true",
  'revoke all on function public.replace_practice_topic_drill_choice_safe_v1',
  'to authenticated'
]) assert(migration.toLowerCase().includes(term.toLowerCase()),'Missing switch guard: '+term);
assert(!/\bdelete\s+from\s+public\.practice_drill_(?:sessions|answers)_v4/i.test(migration),
  'Topic switch must not delete existing session or answer history');
assert(api.includes('async replaceTopicChoice('),'Practice API must expose gated switch');
assert(api.includes('missing_stable_client_session_id'),'Switch requires a reused idempotency key');
assert(api.includes('p_expected_old_client_session_id'),'Switch must verify old draft key');
const app=fs.readFileSync(path.join(root,'app.js'),'utf8');
for(const term of [
  'confirmPracticeTopicReplacement',
  'resumePendingPracticeTopicChoice',
  'pendingTopicSwitch',
  'oldSessionId:p.oldSessionId',
  'clientSessionId:p.clientSessionId',
  'if (draft.pendingTopicSwitch)',
  'savePracticeDraft({ ...draft, pendingTopicSwitch: pending })'
]) assert(app.includes(term),'UI recovery guard missing: '+term);

console.log('PASS: atomic topic replacement SQL/API contract (static, not database execution)');
