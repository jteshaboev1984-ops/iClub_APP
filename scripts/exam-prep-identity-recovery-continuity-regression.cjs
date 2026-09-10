#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const migrationPath = path.join(process.cwd(), 'supabase/migrations/20260910070000_exam_prep_identity_recovery_continuity_v1.sql');
const guardGrantPath = path.join(process.cwd(), 'supabase/migrations/20260910070100_exam_prep_identity_rekey_guard_access_v1.sql');

const sql = fs.readFileSync(migrationPath, 'utf8');
const grantSql = fs.readFileSync(guardGrantPath, 'utf8');

function mustContain(haystack, needle, label) {
  if (!haystack.includes(needle)) throw new Error(`Missing ${label}: ${needle}`);
}

function mustNotContain(haystack, needle, label) {
  if (haystack.toLowerCase().includes(needle.toLowerCase())) throw new Error(`Forbidden ${label}: ${needle}`);
}

mustContain(sql, 'private.exam_prep_user_has_identity_refs_v1', 'dynamic destination-clean helper');
mustContain(sql, "c.confrelid = 'public.users'::regclass", 'public.users FK discovery');
mustContain(sql, "n.nspname = 'private'", 'private schema boundary');
mustContain(sql, "t.relname like 'exam_prep\\_%' escape '\\'", 'Exam Prep table boundary');
mustContain(sql, 'private.exam_prep_rekey_user_identity_v1', 'identity re-key helper');
mustContain(sql, "set_config('iclub.exam_prep_identity_rekey', 'v1', true)", 'transaction-local trusted context');
mustContain(sql, 'v_old_payload = v_new_payload', 'immutable non-identity equality guard');
mustContain(sql, "raise exception 'immutable_exam_prep_fact'", 'immutable fact protection');
mustContain(sql, 'when (not private.exam_prep_identity_rekey_active_v1())', 'stage projection re-key guard');
mustContain(sql, 'or private.exam_prep_user_has_identity_refs_v1(p_current_uid)', 'destination merge refusal');
mustContain(sql, 'v_exam_prep := private.exam_prep_rekey_user_identity_v1(v_old.id, p_current_uid);', 're-key before legacy user deletion');
mustContain(sql, "raise exception 'exam_prep_identity_rekey_incomplete'", 'post-rekey old-reference assertion');

const rekeyPos = sql.indexOf('v_exam_prep := private.exam_prep_rekey_user_identity_v1(v_old.id, p_current_uid);');
const deletePos = sql.indexOf('delete from public.users');
if (rekeyPos < 0 || deletePos < 0 || rekeyPos >= deletePos) {
  throw new Error('Exam Prep re-key must happen before deleting old public.users row');
}

for (const legacyTable of [
  'public.app_events',
  'public.certificates',
  'public.practice_attempts',
  'public.ratings_cache',
  'public.recommendations',
  'public.tour_attempts',
  'public.user_credentials',
  'public.user_notifications',
  'public.user_subjects',
  'public.video_events',
  'public.user_subjects_history'
]) {
  mustContain(sql, legacyTable, `preserved legacy recovery move ${legacyTable}`);
}

for (const forbidden of [
  'truncate ',
  'drop table',
  'session_replication_role',
  'delete from private.exam_prep_',
  'alter table private.exam_prep_',
  'on update cascade'
]) {
  mustNotContain(sql, forbidden, 'destructive or trigger-bypass mechanism');
}

mustContain(sql, 'revoke execute on function private.exam_prep_rekey_user_identity_v1(uuid,uuid) from anon, authenticated, service_role;', 'private re-key access lock');
mustContain(grantSql, 'grant execute on function private.exam_prep_identity_rekey_active_v1() to public;', 'safe trigger guard runtime access');

console.log('Exam Prep identity recovery continuity static regression: GREEN');
