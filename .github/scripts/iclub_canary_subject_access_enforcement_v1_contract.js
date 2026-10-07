const fs = require('fs');

const migration = fs.readFileSync('supabase/migrations/20261007100000_iclub_canary_subject_access_enforcement_v1.sql','utf8');
const rollback = fs.readFileSync('supabase/reversions/20261007100000_iclub_canary_subject_access_enforcement_v1_revert.sql','utf8');
const bridge = fs.readFileSync('commercial-access-ui.js','utf8');
const selector = fs.readFileSync('subject-access-ui.js','utf8');
const app = fs.readFileSync('app.js','utf8');
const html = fs.readFileSync('index.html','utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

assert(migration.includes('canary_subject_access_enforced boolean not null default false'),
  'canary subject enforcement must default OFF');
assert(migration.includes("v_runtime.plans_rollout_mode<>'canary'"),
  'canary enforcement must require canary rollout mode');
assert(migration.includes('private.iclub_is_product_canary_v1(v_uid)'),
  'canary enforcement must verify server canary membership');
assert(migration.includes("'reason','not_canary'"),
  'non-canary fail-open boundary missing');
assert(migration.includes("'reason','manage_in_plan_subjects'"),
  'legacy toggle redirect boundary missing');
assert(migration.includes("'reason','subject_selection_required'"),
  'empty subject-selection boundary missing');
assert(migration.includes("'reason','subject_not_in_plan'"),
  'unselected study subject boundary missing');
assert(migration.includes("'reason','competitive_not_in_plan'"),
  'Competitive access boundary missing');
assert(migration.includes("'reason','plan_all_subjects'"),
  'Pro all-subject study access missing');

for (const forbidden of [
  'update public.user_subjects',
  'delete from public.user_subjects',
  'insert into public.user_subjects',
  'update public.practice_attempts',
  'delete from public.practice_attempts',
  'update public.tour_attempts',
  'delete from public.tour_attempts',
  'update public.certificates',
  'delete from public.certificates',
  'update public.recommendations',
  'delete from public.recommendations'
]) {
  assert(!migration.toLowerCase().includes(forbidden),
    'canary enforcement migration mutates legacy learner data: ' + forbidden);
}

assert(html.includes('commercial-access-ui.js?v=canaryaccess1'),
  'commercial access browser bridge not loaded');
assert(app.includes('iClubCommercialAccessUI?.guardStudy?.(s.key)'),
  'catalog subject open is not guarded');
assert(app.includes('iClubCommercialAccessUI?.guardLegacyToggle?.(s.key)'),
  'legacy subject toggle is not guarded');
assert(app.includes('iClubCommercialAccessUI?.guardStudy?.(subjectKey)'),
  'subject hub stale/deep-link guard missing');
assert(app.includes('iClubCommercialAccessUI?.guardCompetitive?.(state.courses.subjectKey)'),
  'Tours Competitive guard missing');

for (const forbidden of ['localStorage','sessionStorage','.from("user_subjects")',".from('user_subjects')"]) {
  assert(!bridge.includes(forbidden),
    'commercial access bridge contains forbidden persistence/legacy write token: '+forbidden);
}

assert(bridge.includes('guard_unavailable'),
  'browser access bridge must fail open on preview guard unavailability');
assert(bridge.includes('iclub:subject-selection-changed'),
  'access cache invalidation event missing');
assert(selector.includes('new CustomEvent("iclub:subject-selection-changed"'),
  'subject selector does not invalidate access cache after save');

assert(rollback.includes('drop function if exists public.get_iclub_my_subject_access_v1(text,text)'),
  'rollback function cleanup missing');
assert(rollback.includes('drop column if exists canary_subject_access_enforced'),
  'rollback flag cleanup missing');
assert(rollback.includes('rollback refused'),
  'rollback must refuse while canary enforcement is active');

console.log('iClub canary subject access enforcement static contract: GREEN');
