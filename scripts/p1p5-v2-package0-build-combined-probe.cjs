// Issue #450 P0-10: isolated PostgreSQL 17 full-schema test assembler ONLY.
// This is NOT a production cleanup generator or migration tool.
// The original independently verified 32-table SQL remains byte-for-byte intact.
// We add synthetic future-state checks only inside its BEGIN...ROLLBACK.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname,'..');
const original = fs.readFileSync(path.join(root,
  'supabase/tests/p1p5_v2_package0_32table_disposable_rollback_only.sql'),'utf8');
const overlay = fs.readFileSync(path.join(root,
  'supabase/tests/p1p5_v2_package0_future_state_overlay_disposable.sql'),'utf8');
const target = process.argv[2];

assert(target && path.resolve(target).startsWith('/tmp/p0-10-') && target.endsWith('.sql'),
  'P0-10 output MUST be a temporary disposable CI SQL file');
assert(process.env.P1P5_E2E_ISOLATED === 'true',
  'P0-10 assembler MUST run only under isolated E2E env');
assert(process.env.PGDATABASE === 'postgres',
  'P0-10 assembler refuses non-disposable PG database');
assert(original.includes("current_setting('iclub.e2e_isolated',true)"),
  'original full schema fake-two-learner runtime guard missing');
assert(original.includes("(SELECT count(*) FROM public.users)<>2"),
  'original fake two-user runtime guard missing');
assert(original.startsWith('-- ONLY disposable PostgreSQL 17'));
assert(original.trimEnd().endsWith('ROLLBACK;'));
assert(overlay.includes('NOT a standalone executable SQL migration'));

const found = [...original.matchAll(/DELETE FROM private\.(exam_prep_\w+)/g)].map(x=>x[1]);
assert.equal(found.length,65,'expected 64 scoped historical deletes plus 1 negative probe');
const markers = [
  ['SETUP','CREATE TEMP TABLE p0_protected_before AS SELECT jsonb_build_object('],
  ['FIRST_DELETE','DO $$\nBEGIN\n IF EXISTS (SELECT 1 FROM private.exam_prep_component_access_gates'],
  ['SECOND_DELETE','DO $$\nBEGIN\n IF (SELECT jsonb_build_object('],
  ['POST_ROLLBACK','DO $$\nBEGIN\n IF (SELECT count(*) FROM private.exam_prep_component_access_gates']
];
const parts = overlay.split(/^-- P0-10 SECTION (SETUP|FIRST_DELETE|SECOND_DELETE|POST_ROLLBACK)\s*$/m);
assert.equal(parts.length,9,'P0-10 overlay must have exactly four named sections');
const sections = {};
for(let i=1;i<parts.length;i+=2) {
  assert(!sections[parts[i]],'duplicate section '+parts[i]);
  sections[parts[i]]=parts[i+1];
}
assert.deepEqual(Object.keys(sections).sort(),
  ['FIRST_DELETE','POST_ROLLBACK','SECOND_DELETE','SETUP']);
let result=original;
for (const [section,marker] of markers) {
  const occurrences=result.split(marker).length-1;
  assert.equal(occurrences,1,'expected exactly one safe insertion marker for '+section);
  result=result.replace(marker,sections[section]+'\n'+marker);
}
assert(result.indexOf('P0-10 SECTION')<0,'section marker unexpectedly stitched');
assert(result.trimEnd().endsWith('ROLLBACK;'));
assert(!/\b(?:DISABLE\s+TRIGGER|session_replication_role|TRUNCATE\s+public|DROP\s+TABLE\s+public\.users)\b/i.test(result));
fs.writeFileSync(target,result,{encoding:'utf8',mode:0o600,flag:'wx'});
console.log('PASS P0-10: isolated exact 32-table script combined with future-date and receipt HOLD overlay; no production API/code mutation');
