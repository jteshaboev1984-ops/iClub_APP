'use strict';
// D3-HOURS isolated source gate. Fail-closed, exact reviewed Git blob pins.
// Does NOT authorize merge, production migration, activation or publication.
const assert=require('node:assert/strict');
const fs=require('node:fs');
const cp=require('node:child_process');
const BASE="31f22796545c58382e7ac41c785000e736f8472b";
const BRANCH="feature/math-d3-hours-optional-20261118";
const PINNED=Object.freeze({
  ".github/scripts/exam_prep_persistence_continuity_regression.js": "e9555db96d191d3bee4fc7c6da117ec0112d705d",
  ".github/scripts/p0_17_live_diagnostic_regression.js": "b098f037cf1ecc8b1077aa74b2dad550417950ba",
  ".github/scripts/p2_52_auxiliary_status_accessibility_regression.js": "727d12449991926cdac94051a80acf814b5dc540",
  ".github/scripts/p2_55_full_learner_journey_regression.js": "446b5a1e8754b7d8510ef8ad3360736da0919a2e",
  ".github/workflows/exam-prep-p1p5-isolated-http-e2e.yml": "d8dbc7d028dd16b9cb39c4340081afcc75e6ff9b",
  ".github/workflows/exam-prep-weekly-answer-recovery.yml": "cd0ffaba1dfa22a0cb1a652dc4db8c99869701d7",
  ".github/workflows/exam-prep-weekly-goal-card-cutover.yml": "70d8d1e7da933f292a48fbdc5a8347926fa5519b",
  ".github/workflows/exam-prep-weekly-profile-recovery.yml": "b58145d137f3e61fd16b1257f0610f285f19a12c",
  ".github/workflows/math-p1p5-d3-protected-recovery-review.yml": "35dacd35a7af6cb94a0412e344132f7042e65d73",
  ".github/workflows/math-p1p5-s4-hybrid-psql-jwt.yml": "aa6be1f1d55f303ef4dc854ab37807a9fd7fdb4e",
  ".github/workflows/p2-05-profile-completeness.yml": "f81773a229858830041afe97b88434c0b0373fef",
  ".github/workflows/p2-52-auxiliary-status-accessibility.yml": "9ab23814e3e68a9e38a0eca3bde42b90b0120746",
  ".github/workflows/p2-78-concurrency-service-transitions.yml": "efa7a6b2be99bee5bf1118e4a647c340775dc37b",
  ".github/workflows/ux531-previewless-release-firewall.yml": "862262097cae1fa261eb28ebd5b1ccf069b46985",
  "docs/math-p1p5-d3-hours-product-contract-20261118.md": "d9fef67a48ac88a4b8abe2a0e141ab54b1ad50e6",
  "exam-prep/exam-prep-api.js": "61924125bbb0fd781c7897bc063fd61e22e22a57",
  "exam-prep/exam-prep-exam-map.js": "bffe985ba1eb86d3d47b7d7e0e58bb24db25ad6c",
  "exam-prep/exam-prep-live.js": "e875085e55b4580df9659b27e7f32c8490fcd06a",
  "exam-prep/exam-prep-profile-completeness.js": "d42deac0f0c66457caa784e191fb6c8a1758b66d",
  "scripts/p1p5-d3-hours-chromium-multilang.cjs": "b90d94941a357d42a5ff072197b54730f9b34eb6",
  "scripts/p1p5-d3-hours-signed-real-scenarios.cjs": "b2a29c52eae1dfd9da7c135f81ff43449b434828",
  "scripts/p1p5-isolated-http-auth-e2e.cjs": "437ff1d4d78162ae1ff37783104b66681689f10b",
  "scripts/p2-05-profile-completeness-regression.cjs": "6b6abc7d1bf94ac3bed80b9606f2e3546b61627e",
  "supabase/candidates/math_p1p5_d3_optional_hours_v1_dormant.sql": "b1e8faacc18289c7e599a44271e2f9eee192f508"
});
const SELF="qa/math-d3-hours-source-firewall.cjs";
const git=(...args)=>cp.execFileSync('git',args,{encoding:'utf8',maxBuffer:8*1024*1024}).trimEnd();
const head=String(process.env.D3_HEAD_SHA||'');
assert.equal(process.env.D3_BASE_SHA,BASE,'D3 base must be exact approved main source');
assert.match(head,/^[a-f0-9]{40}$/,'Candidate requires full SHA');
assert.equal(git('rev-parse','HEAD'),head,'Checkout must be exact PR HEAD');
assert.equal(git('merge-base',BASE,head),BASE,'Main baseline must be ancestor');
assert(fs.existsSync(SELF),'D3 strict gate script missing');
const actual=git('diff','--name-only',BASE,head).split('\n').filter(Boolean).sort();
const allowed=[...Object.keys(PINNED),SELF].sort();
assert.deepEqual(actual,allowed,'Unexpected D3 source file-list drift');
for(const [path,hash] of Object.entries(PINNED)){
  assert.equal(git('hash-object',path),hash,'Reviewed source SHA changed: '+path);
}
for(const [path,blob] of [
  [".github/workflows/ux531-previewless-release-firewall.yml",'500d3fa0ce61aea4f2f5e1508b922f5bb4d08b91'],
  [".github/workflows/exam-prep-weekly-answer-recovery.yml",'c7d9ae1893a578c0d07940d0c29ba8cdf407c790'],
  [".github/workflows/exam-prep-weekly-profile-recovery.yml",'2db90d6569f2c6643fcc06a50604809015237e76']
])assert.equal(git('rev-parse',BASE+':'+path),blob,'Legacy source guard baseline drift: '+path);
assert.equal(git('hash-object','exam-prep/exam-prep-recovery.js'),
  '5ba398241b2e2055c72362c9fa660b9f0c8f34c5','Core recovery module changed');
const ux=fs.readFileSync(".github/workflows/ux531-previewless-release-firewall.yml",'utf8');
const answer=fs.readFileSync(".github/workflows/exam-prep-weekly-answer-recovery.yml",'utf8');
const profile=fs.readFileSync(".github/workflows/exam-prep-weekly-profile-recovery.yml",'utf8');
assert(ux.includes(BRANCH)&&ux.includes('D3_BASE_SHA="$UX531_BASE_SHA"'),
  'UX D3 route must call this strict source guard');
for(const s of [answer,profile])assert(s.includes(BRANCH)&&s.includes('GITHUB_BASE_REF'),
  'Guarded recovery pin must remain D3 branch-only');
assert(!actual.some(p=>/^supabase\/(migrations|functions|seeds)\//.test(p)),
  'D3 scope cannot change installed Supabase migrations or functions');
const patch=git('diff','--unified=0',BASE,head,'--','exam-prep/exam-prep-live.js',
  'exam-prep/exam-prep-api.js','exam-prep/exam-prep-exam-map.js',
  'exam-prep/exam-prep-profile-completeness.js');
for(const line of patch.split('\n')){
  if(!line.startsWith('+')||line.startsWith('+++'))continue;
  assert(!/localStorage\.(?:clear|removeItem)\s*\(|\b(?:DROP|TRUNCATE)\s+(?:TABLE|SCHEMA)\b/i.test(line),
    'D3 adds destructive learner-data operation: '+line.slice(0,180));
}
console.log('D3 STRICT EXACT SOURCE PASS candidate='+head+' pinned='+Object.keys(PINNED).length);
console.log('No live Supabase or production deployment, no beta/mass release authorization.');
