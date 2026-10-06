const fs = require('fs');

const lifecycle = fs.readFileSync(
  'supabase/migrations/20261006153000_iclub_subscription_access_lifecycle_v1.sql',
  'utf8'
);
const access = fs.readFileSync(
  'supabase/migrations/20261006153100_iclub_grandfather_subject_access_v1.sql',
  'utf8'
);
const revert = fs.readFileSync(
  'supabase/reversions/20261006153000_iclub_subscription_access_lifecycle_v1_revert.sql',
  'utf8'
);
const app = fs.readFileSync('app.js','utf8');
const doc = fs.readFileSync('docs/iclub-commercial-access-migration-model-v1.md','utf8');
const impact = fs.readFileSync('docs/iclub-commercial-cutover-impact-snapshot-v1.md','utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(lifecycle.includes("lifecycle_enabled boolean not null default false"), 'lifecycle must default OFF');
assert(lifecycle.includes("subject_limits_mode text not null default 'off'"), 'subject limits must default OFF');
assert(lifecycle.includes("subject_limits_mode <> 'enforced'"), 'enforcement snapshot constraint missing');
assert(lifecycle.includes("grandfather_strategy text not null default 'preserve_legacy_until_choice'"), 'grandfather strategy missing');

for (const table of [
  'iclub_subscription_events',
  'iclub_commercial_migration_state',
  'iclub_legacy_subject_snapshot',
  'iclub_subject_slot_selections',
  'iclub_subject_slot_events'
]) {
  assert(lifecycle.includes('private.' + table), 'commercial private table missing: ' + table);
}

assert(lifecycle.includes('event_id uuid primary key'), 'subscription event idempotency key missing');
assert(lifecycle.includes('future_event_requires_schedule'), 'future direct transition guard missing');
assert(lifecycle.includes('schedule_downgrade'), 'scheduled downgrade lifecycle missing');
assert(lifecycle.includes('schedule_cancel'), 'scheduled cancel lifecycle missing');
assert(lifecycle.includes('get_iclub_my_subscription_status_v1'), 'safe own-subscription read RPC missing');

for (const fn of [
  'apply_iclub_subscription_event_service_v1',
  'capture_iclub_legacy_access_baseline_service_v1',
  'get_iclub_subject_access_guard_service_v1',
  'set_iclub_subject_slot_service_v1',
  'finalize_iclub_subject_selection_service_v1'
]) {
  const combined = lifecycle + '\n' + access;
  assert(combined.includes(fn), 'service contract missing: ' + fn);
}

assert(access.includes("'mode','legacy_passthrough'"), 'legacy pass-through safety path missing');
assert(access.includes("'reason','legacy_access_preserved'"), 'grandfather open-access path missing');
assert(access.includes("migration_state='legacy_preserved'"), 'legacy-preserved state check missing');
assert(access.includes("migration_state='migrated'"), 'explicit selection finalization missing');
assert(access.includes("'reason','plan_all_subjects'"), 'Pro all-subject path missing');
assert(access.includes("'reason','study_subject_limit_reached'"), 'study limit guard missing');
assert(access.includes("'reason','competitive_subject_limit_reached'"), 'competitive limit guard missing');

for (const source of [lifecycle, access]) {
  assert(
    !/\b(update|delete\s+from|insert\s+into|truncate(?:\s+table)?)\s+public\.user_subjects\b/i.test(source),
    'commercial migration mutates legacy public.user_subjects'
  );

  for (const table of [
    'practice_attempts','practice_answers','tour_attempts','tour_answers',
    'ratings_cache','certificates','recommendations'
  ]) {
    const re = new RegExp('\\b(update|delete\\s+from|insert\\s+into|truncate(?:\\s+table)?)\\s+public\\.' + table + '\\b','i');
    assert(!re.test(source), 'commercial migration mutates protected legacy table: ' + table);
  }
}

for (const signature of [
  'public.apply_iclub_subscription_event_service_v1',
  'public.capture_iclub_legacy_access_baseline_service_v1',
  'public.get_iclub_subject_access_guard_service_v1',
  'public.set_iclub_subject_slot_service_v1',
  'public.finalize_iclub_subject_selection_service_v1'
]) {
  const combined = lifecycle + '\n' + access;
  assert(combined.includes('revoke all on function ' + signature), 'browser revoke missing for ' + signature);
}

assert(
  lifecycle.includes("grant execute on function public.get_iclub_my_subscription_status_v1()\n  to authenticated,service_role"),
  'browser-safe own subscription read grant missing'
);

assert(
  app.includes('// Non-school users: no subjects during registration.') &&
  app.includes('They can study/practice all subjects without tours and manage subjects later in Profile.'),
  'legacy app behavior changed or undocumented; user_subjects cannot safely become tariff authority'
);

for (const token of [
  'preserve_legacy_until_choice',
  'must **not** be implemented by deleting, rewriting or reinterpreting legacy user_subjects rows',
  'subject_limits_mode',
  'no existing user is assigned Free/Plus/Pro',
  'historical evidence remains intact'
]) {
  assert(doc.includes(token), 'migration model doc missing safety statement: ' + token);
}

assert(revert.includes('commercial access config is not dormant'), 'rollback active-state refusal missing');
assert(revert.includes('commercial lifecycle rows exist'), 'rollback data-state refusal missing');
assert(revert.includes('drop function if exists public.get_iclub_my_subscription_status_v1()'), 'rollback subscription status cleanup missing');

for (const token of [
  'Total users: 1,443',
  '0 rows: 128 users',
  'legacy_preserved',
  'never auto-enforce finite subject limits on legacy_preserved users',
  'contains no learner-identifying data'
]) {
  assert(impact.includes(token), 'commercial cutover impact snapshot missing safety evidence: ' + token);
}

console.log('iClub subscription lifecycle + commercial access static contract: GREEN');