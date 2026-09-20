'use strict';
// Release blocker test, NOT a migration. Never contacts Supabase and never
// reads real learner data. Fails until every audited direct route is protected.
const fs = require('node:fs');
const path = require('node:path');
const read = name => fs.readFileSync(path.resolve(__dirname, '..', name), 'utf8');
const backup = read('docs/patch-proposals/20260920_weekly_flow_preinstall_rpc_backup_v1.sql');
const install = read('docs/patch-proposals/20260919_exam_prep_atomic_legacy_rpc_dispatch_v1.sql');
const attest = read('docs/patch-proposals/20260920_weekly_flow_postinstall_attestation_v1.sql');
const rollback = read('docs/patch-proposals/20260920_weekly_flow_exact_rpc_rollback_v1.sql');
const must = [
  'generate_exam_prep_weekly_plan_safe_v1',
  'generate_exam_prep_weekly_plan_safe_v2',
  'generate_exam_prep_weekly_plan_safe_v3',
  'authorize_exam_prep_plan_item_safe_v1',
  'authorize_exam_prep_correction_safe_v1',
  'authorize_exam_prep_mixed_safe_v1',
  'authorize_exam_prep_retest_safe_v1',
  'start_exam_prep_session_safe_v1'
];
const signatures = [
  'public.generate_exam_prep_weekly_plan_safe_v1(text,text)',
  'public.generate_exam_prep_weekly_plan_safe_v2(text)',
  'public.generate_exam_prep_weekly_plan_safe_v3(text)',
  'public.authorize_exam_prep_plan_item_safe_v1(uuid,integer)',
  'public.authorize_exam_prep_correction_safe_v1(uuid)',
  'public.authorize_exam_prep_mixed_safe_v1(text)',
  'public.authorize_exam_prep_retest_safe_v1(uuid)',
  'public.start_exam_prep_session_safe_v1(uuid,text)',
  'public.ensure_exam_prep_stable_weekly_plan_safe_v1(text)',
  'public.authorize_exam_prep_goal_once_safe_v1(text,uuid,uuid)',
  'public.start_exam_prep_plan_session_once_safe_v1(uuid,text)'
];
const errors = [];
for (const signature of signatures) {
  if (!backup.includes(`'${signature}'`)) errors.push(`PREINSTALL BACKUP missing exact original ${signature}`);
  if (!attest.includes(`'${signature}'`)) errors.push(`POSTINSTALL ATTESTATION missing ${signature}`);
}
for (const name of must) {
  const match = new RegExp(`CREATE\\s+OR\\s+REPLACE\\s+FUNCTION\\s+public\\.${name}\\s*\\([\\s\\S]*?\\$body\\$;`, 'i').exec(install);
  if (!match) { errors.push(`ATOMIC DISPATCH missing public wrapper ${name}`); continue; }
  if (!match[0].includes('private.exam_prep_weekly_flow_enrolled_v1')) {
    errors.push(`ATOMIC DISPATCH wrapper lacks server enrollment guard ${name}`);
  }
}
// A direct nonplan correction/mixed/retest authorization with academic credit
// must not go to an unprotected legacy starter for enrolled users.
const starter = /CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.start_exam_prep_session_safe_v1\s*\([\s\S]*?\$body\$;/i.exec(install)?.[0] || '';
if (!starter.includes('academic_credit')) {
  errors.push('ATOMIC STARTER lacks academic_credit check for non-plan authorizations');
}
if (starter.includes('IF v_plan_id IS NOT NULL THEN') && !starter.includes('academic_credit')) {
  errors.push('ATOMIC STARTER explicitly bypasses guard when plan_id IS NULL');
}
for (const [name,body] of [['backup',backup],['attestation',attest],['rollback',rollback]]) {
  if (/(?:<>|!=)\s*7\b|\bseven\b|\b7\s+exact/i.test(body)) {
    errors.push(`${name} still contains narrow seven-function-only completeness/rollback contract`);
  }
}
if (!rollback.includes('original_definition') || !rollback.includes('installed_md5') ||
    !rollback.includes('original_acl') || !rollback.includes('original_owner')) {
  errors.push('ROLLBACK lacks exact original definition/owner/grant/drift contract');
}
if (errors.length) {
  console.error(`RELEASE BLOCKED: ${errors.length} full-surface weekly-flow failures:`);
  for (const error of errors) console.error(` - ${error}`);
  console.error('Prior seven-function PG17/browser GREEN does not cover this surface. DO NOT INSTALL, MERGE OR ENABLE.');
  process.exitCode = 1;
} else {
  console.log('STATIC FULL-SURFACE INVENTORY PASS ONLY. Separate isolated PG17 direct-bypass and rollback tests, real-user safety review and owner approval remain mandatory.');
}
