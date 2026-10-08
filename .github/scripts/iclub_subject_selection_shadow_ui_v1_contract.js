const fs = require('fs');

const html = fs.readFileSync('index.html','utf8');
const app = fs.readFileSync('app.js','utf8');
const ui = fs.readFileSync('subject-access-ui.js','utf8');
const css = fs.readFileSync('subject-access-ui.css','utf8');
const migration = fs.readFileSync('supabase/migrations/20261006164000_iclub_subject_selection_shadow_ui_v1.sql','utf8');
const revert = fs.readFileSync('supabase/reversions/20261006164000_iclub_subject_selection_shadow_ui_v1_revert.sql','utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(migration.includes('subject_selection_ui_enabled boolean not null default false'), 'subject selection UI must default OFF');
assert(migration.includes("v_cfg.subject_limits_mode<>'shadow'"), 'browser selector must be shadow-only in beta');
assert(migration.includes('private.iclub_rollout_allows_user_v1(v_uid,v_runtime.plans_rollout_mode)'), 'server canary rollout gate missing');
assert(migration.includes("'access_unchanged',true"), 'shadow preservation marker missing');
assert(migration.includes('public.set_iclub_subject_slot_service_v1('), 'browser wrapper is not delegated to governed slot service');
assert(migration.includes("v_cfg.subject_limits_mode<>'shadow'"), 'beta browser write path is not shadow-only');
assert(migration.includes("pg_advisory_xact_lock(hashtextextended('iclub-subject-slot:'||v_uid::text,0))"), 'subject slot writes are not serialized');
assert(migration.includes("'subject_unavailable'"), 'inactive/unknown subject rejection missing');
assert(migration.includes("'competitive_requires_main_subject'"), 'non-main Competitive rejection missing');
assert(migration.includes("'study_subject_limit_reached'"), 'atomic study limit rejection missing');
assert(migration.includes("'competitive_subject_limit_reached'"), 'atomic Competitive limit rejection missing');
assert(!migration.includes('finalize_iclub_subject_selection_service_v1('), 'beta UI must not finalize grandfather migration');

for (const forbidden of [
  'update public.user_subjects',
  'delete from public.user_subjects',
  'insert into public.user_subjects',
  'reset_subject_progress',
  'practice_attempts',
  'tour_attempts',
  'certificates',
  'recommendations'
]) {
  assert(!migration.toLowerCase().includes(forbidden.toLowerCase()), 'subject-selection migration touches legacy learner data: ' + forbidden);
}

assert(html.includes('subject-access-ui.css?v=subjectshadow1'), 'subject-selection CSS not loaded');
assert(html.includes('subject-access-ui.js?v=subjectshadow1'), 'subject-selection JS not loaded');
assert(html.includes('id="profile-subject-access-entry"'), 'plan subject entry missing');
assert(html.includes('id="profile-subject-access"'), 'subject-selection Profile screen missing');
assert(html.includes('data-action="profile-subject-access"'), 'subject-selection navigation action missing');

assert(app.includes('const PROFILE_SCREENS = ["main", "settings", "plan", "subject-access"]'), 'Profile stack missing subject-access screen');
assert(app.includes('function canShowProfileSubjectAccess()'), 'subject-access stale-state guard missing');
assert(app.includes('raw === "subject-access" && !canShowProfileSubjectAccess()'), 'stale subject-access stack does not fail closed');
assert(app.includes('function openProfileSubjectAccess()'), 'subject-access open helper missing');
assert(app.includes('action === "profile-subject-access"'), 'subject-access action binding missing');
assert(app.includes('raw === "subject-access" && !canShowProfileSubjectAccess()'), 'stale subject-access screen does not fail closed when beta UI is disabled');

for (const token of [
  'get_iclub_subject_selection_bootstrap_v1',
  'set_iclub_my_subject_slot_v1',
  'state.busy.size > 0',
  'study_subject_limit_reached',
  'competitive_subject_limit_reached',
  'all_available_subjects',
  'access or progress yet',
  'текущий доступ и прогресс',
  'mavjud imkoniyatlar va o‘qish natijalariga'
]) {
  assert(ui.includes(token), 'subject-selection UI missing required behavior/copy: ' + token);
}

for (const forbidden of [
  'localStorage',
  'sessionStorage',
  '.from("user_subjects")',
  ".from('user_subjects')",
  'reset_subject_progress',
  'allowance_units',
  'generation_weight',
  'prepared_weight'
]) {
  assert(!ui.includes(forbidden), 'subject-selection UI contains forbidden authority/storage token: ' + forbidden);
}

assert(ui.includes('choose_iclub_my_free_subject_v2'), 'Free subject must be selected atomically');
assert(ui.includes('renderFreeCompetitive(competitive)'), 'Free screen must not duplicate the Competitive selector');
assert(css.includes('@media (max-width: 340px)'), '320px subject-selection layout guard missing');
assert(css.includes('@media (prefers-reduced-motion: reduce)'), 'reduced-motion subject-selection guard missing');
assert(css.includes('.iclub-subject-access-row.is-selected'), 'selected subject visual state missing');
assert(css.includes('.iclub-subject-access-switch input:checked'), 'subject selection switch state missing');

assert(revert.includes('subject_selection_ui_enabled'), 'rollback does not remove subject-selection flag');
assert(revert.includes('drop function if exists public.set_iclub_my_subject_slot_v1'), 'rollback browser write wrapper cleanup missing');
assert(revert.includes('drop function if exists public.get_iclub_subject_selection_bootstrap_v1'), 'rollback browser bootstrap cleanup missing');

console.log('iClub beta subject-selection static contract: GREEN');