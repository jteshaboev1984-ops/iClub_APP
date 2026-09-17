'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const sql = fs.readFileSync(path.resolve(__dirname, '../supabase/migrations/20260917080000_exam_prep_progress_ux_v1.sql'), 'utf8');
const contains = needle => assert.ok(sql.includes(needle), `Missing required safety contract: ${needle}`);
contains('create table if not exists private.exam_prep_weekly_goal_snapshots');
contains('unique (user_id,program_version_id,component_code,active_week_no,priority_order)');
contains('enable row level security');
contains('revoke all on table private.exam_prep_weekly_goal_snapshots from public,anon,authenticated');
contains('public.ensure_exam_prep_weekly_goals_safe_v1(p_component_code text)');
contains('public.get_exam_prep_weekly_progress_safe_v1(p_component_code text)');
contains('private.exam_prep_require_core_access_v1()');
contains('pg_advisory_xact_lock');
contains('on conflict (user_id,program_version_id,component_code,active_week_no,priority_order)');
contains("and ses.user_id=v_uid and ses.component_code=p_component_code and ses.status='finalized'");
contains("ca.action_type='remediation_completed'");
contains("when item_type='correction' then remediation_done");
contains('count(distinct ses.id)');
contains("'weekly_commitment_complete',weekly_complete");
contains("'correction_open',coalesce(");
contains("'completed_goals',coalesce(v_done,0)");
contains("'contract_version','progress_ux_v1'");
assert.equal((sql.match(/security definer set search_path=''/g) || []).length, 2,
  'Both exported functions must use explicit safe search_path');
assert.doesNotMatch(sql, /(?:update|delete\s+from|truncate|drop\s+table)\s+(?:public|private)\.exam_prep_(?!weekly_goal_snapshots)/i,
  'Progress UX must not mutate legacy or existing Exam Prep academic tables');
assert.doesNotMatch(sql, /(?:correct_answer|private_rubric|learner_access_token)/i,
  'No answer keys or private rubric may leave the server');
assert.doesNotMatch(sql, /\b(create|replace)\s+(?:table|function)\s+public\.users\b/i,
  'User data structures must remain untouched');
console.log('Progress UX migration: PASS static safety contract (not a SQL execution/DDL/RLS runtime test)');
