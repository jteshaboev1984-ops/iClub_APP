// Core P3-01 release boundary fail-closed regression; offline, no DB connections.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const file = 'supabase/migrations/20261027235900_exam_prep_mass_core_qa_open_boundary_guard_v1.sql';
const sql = fs.readFileSync(file,'utf8');
for (const token of [
  'create or replace function private.exam_prep_p3_01_mass_core_rollout_gate_v1(',
  'private.exam_prep_beta_expansion_gate_v1',
  "milestone_key='product_content_complete'",
  'v_qa_access_closed :=',
  'coalesce(v_cfg.qa_open_all_core,false)=false',
  'coalesce(v_cfg.qa_open_all_weekly,false)=false',
  'and v_qa_access_closed;',
  "'temporary_qa_access_closed',v_qa_access_closed",
  "'temporary_qa_access_still_open'",
  "'automatic_rollout_permitted',false",
  "'learner_state_mutated',false",
  "'legacy_state_mutated',false",
  "'ai_scale_independent',true",
  "'mentor_scale_independent',true",
  "'decision',case when v_ready then 'ELIGIBLE_FOR_EXPLICIT_MASS_CORE_DECISION' else 'NO_GO' end"
]) assert(sql.includes(token),'missing Core safety token: '+token);
for (const mutation of [
  /\b(?:insert\s+into|update|delete\s+from|truncate)\s+private\.exam_prep_(?:feature_config|sessions|responses|evidence_events|weekly_plans|beta_members|beta_weekly_reviews|feature_entitlements|written_learning_config_v1)/i,
  /\b(?:insert\s+into|update|delete\s+from|truncate)\s+public\.(?:users|practice_answers|tour_answers|certificates)/i,
  /\b(?:drop\s+table|drop\s+schema)\b/i
]) assert(!mutation.test(sql),'illegal data change: '+mutation);
assert(!/\bgrant\s+execute\b[\s\S]*\bto\s+authenticated\b/i.test(sql),'Private mass gate leaked to student role');
assert.match(sql,/grant\s+execute\s+on\s+function\s+private\.exam_prep_p3_01_mass_core_rollout_gate_v1\(text\)\s+to\s+service_role/i);
console.log('Core mass-release QA-open boundary static safety: GREEN');
