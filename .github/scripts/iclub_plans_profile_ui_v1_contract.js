const fs = require('fs');

const html = fs.readFileSync('index.html','utf8');
const app = fs.readFileSync('app.js','utf8');
const ui = fs.readFileSync('plans-ui.js','utf8');
const css = fs.readFileSync('plans-ui.css','utf8');
const migration = fs.readFileSync('supabase/migrations/20261006143000_iclub_plans_profile_ui_v1.sql','utf8');
const audit = fs.readFileSync('docs/iclub-free-plus-pro-capability-audit-v1.md','utf8');

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

// Pricing and dormant flags.
assert(migration.includes('plans_ui_enabled boolean not null default false'), 'plans UI must default OFF');
assert(migration.includes('checkout_enabled boolean not null default false'), 'checkout must default OFF');
assert(migration.includes('monthly_price_uzs'), 'plan bootstrap must expose public monthly price');
assert(!migration.includes('allowance_units'), 'plan presentation migration must not expose hidden usage units');
assert(!migration.includes("'priority_support'"), 'unimplemented priority-support capability leaked into plan bootstrap');
assert(!migration.includes("'early_access_entitled'"), 'unimplemented early-access capability leaked into plan bootstrap');

// Existing foundation prices remain the only source of truth.
const tariff = fs.readFileSync('supabase/migrations/20261006102000_iclub_global_ai_tariff_foundation_v1.sql','utf8');
assert(tariff.includes("('plus','global_ai_tariffs_v1',35000,3,2,true,'plus_v1'"), 'Plus must remain 35,000 UZS');
assert(tariff.includes("('pro','global_ai_tariffs_v1',50000,null,2,true,'pro_v1'"), 'Pro must remain 50,000 UZS');

// Profile integration must use the existing stack, not a fifth bottom tab.
assert(html.includes('id="profile-plan-entry"'), 'Profile plan entry missing');
assert(html.includes('id="profile-plan"'), 'Profile plan screen missing');
assert(html.includes('plans-ui.css?v=plans1'), 'plan CSS asset missing');
assert(html.includes('plans-ui.js?v=plans1'), 'plan JS asset missing');
assert(app.includes('const PROFILE_SCREENS = ["main", "settings", "plan", "subject-access"]'), 'Integrated Profile plan/subject-access stack registration missing');
assert(app.includes('function openProfilePlan()'), 'Profile plan open helper missing');
assert(app.includes('action === "profile-plan"'), 'Profile plan action binding missing');
assert(app.includes('#view-profile .profile-screen.is-active:not(#profile-main)'), 'Profile inner-screen back hardening missing');
assert(app.includes('function canShowProfilePlan()'), 'plan kill-switch navigation guard missing');
assert(app.includes('raw === "plan" && !canShowProfilePlan()'), 'stale plan stack fail-closed guard missing');

const tabbarStart = html.indexOf('<nav id="tabbar"');
const tabbarEnd = html.indexOf('</nav>',tabbarStart);
assert(tabbarStart >= 0 && tabbarEnd > tabbarStart, 'bottom navigation not found');
const tabs = [...html.slice(tabbarStart,tabbarEnd).matchAll(/data-tab="([^"]+)"/g)].map(m=>m[1]);
assert(JSON.stringify(tabs) === JSON.stringify(['home','courses','ratings','profile']), 'plan work changed the four-tab navigation');

// Learner-facing plan copy must not promise features that are not implemented yet.
for (const forbidden of [
  'расширенная история',
  'глубокий анализ',
  'ранний доступ',
  'приоритетная +',
  'extended history',
  'deeper analysis',
  'early access',
  'priority +',
  'kengaytirilgan tarix',
  'chuqur tahlil',
  'erta kirish'
]) {
  assert(!ui.toLowerCase().includes(forbidden.toLowerCase()), `unimplemented plan promise leaked into UI: ${forbidden}`);
}

assert(ui.includes('examIntro: "Не входит"'), 'Free must not promise unimplemented Exam Prep preview');
assert(ui.includes('examFull: "Mathematics P1 + P5"'), 'Plus Exam Prep copy must name current supported module');
assert(ui.includes('examPro: "Mathematics P1 + P5"'), 'Pro Exam Prep copy must name current supported module');
assert(ui.includes('aiFree: "3 готовых ответа / 5 ч"'), 'Free AI 5-hour copy missing');
assert(ui.includes('aiPlus: "Повышенный лимит / 5 ч"'), 'Plus AI copy missing');
assert(ui.includes('aiPro: "Самый высокий лимит / 5 ч"'), 'Pro AI copy missing');

// Real app capabilities referenced in the comparison must exist in current app code.
for (const token of [
  'function renderBooks()',
  'practice-review',
  'my-recs',
  'profile-certificates',
  'courses-tour',
  'video_events',
  'recommendations'
]) {
  assert(app.includes(token) || html.includes(token), `commercial matrix references capability not found in app: ${token}`);
}
assert(app.includes('window.iClubExamPrep') || html.includes('exam-prep-host-root'), 'Mathematics Exam Prep host missing');

// No fake checkout or browser-owned subscription mutations.
assert(!ui.includes('.from("iclub_subscription_entitlements")'), 'browser UI must not mutate subscription entitlements');
assert(!ui.includes('.from("subscriptions")'), 'browser UI must not write subscriptions directly');
assert(!ui.includes('window.location') || !ui.includes('checkout='), 'plan UI contains an invented checkout redirect');
assert(ui.includes('checkout_enabled'), 'checkout gate missing');
assert(ui.includes('iclub:plan-checkout-request'), 'future checkout boundary event missing');

// Responsive and premium plan emphasis.
assert(css.includes('.iclub-plan-card.is-pro'), 'Pro visual emphasis missing');
assert(css.includes('@media (max-width: 760px)'), 'mobile plan card stack missing');
assert(css.includes('@media (max-width: 340px)'), '320px plan layout guard missing');
assert(css.includes('@media (prefers-reduced-motion: reduce)'), 'reduced motion guard missing');

// Audit must explicitly block activation until commercial enforcement is ready.
for (const token of [
  'grandfather/cutover',
  'subject-slot enforcement',
  'subscription lifecycle',
  'payment/checkout provider',
  'downgrade never deletes'
]) {
  assert(audit.toLowerCase().includes(token.toLowerCase()), `capability audit missing blocker: ${token}`);
}

console.log('iClub Free Plus Pro plan/profile static contract: GREEN');