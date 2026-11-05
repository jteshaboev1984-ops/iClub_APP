// Issue #450 P0-16B source-only negative guard; never connects to production.
'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const file = p => fs.readFileSync(path.join(root, p), 'utf8');
const inventory = file('supabase/tests/p1p5_v2_package0_trigger_writer_inventory_readonly.sql');
const transitive = file('supabase/tests/p1p5_v2_package0_trigger_transitive_write_routes_readonly.sql');
const decision = file('docs/math-p1p5-p0-16b-trigger-write-reachability-20261105.md');
function checkReadOnly(source) {
  // Strip SQL comments and single-quoted values, including regexp pattern strings.
  const stripped = source.replace(/--[^\n]*/g, '').replace(/'(?:''|[^'])*'/g, "''");
  assert(/\bSELECT\b/i.test(stripped), 'must contain read-only SELECT');
  assert(!/\b(?:INSERT|UPDATE|DELETE|TRUNCATE|DROP|ALTER|CREATE|GRANT|REVOKE|CALL|DO|EXECUTE|COPY|VACUUM)\b/i.test(stripped),
    'metadata audit must never execute SQL writes/DDL');
  assert(!/\b(?:FROM|JOIN)\s+(?:public|private|auth)\./i.test(stripped),
    'metadata audit must not read learner/account/application rows');
  assert(!/\b(?:pg_read_file|pg_ls_dir|dblink|http_post)\s*\(/i.test(stripped),
    'no server files, external connections or side-effect functions');
  for (const marker of ['READ ONLY', 'pg_trigger', 'pg_class', 'pg_proc', 'pg_namespace',
      'NOT t.tgisinternal', "n.nspname = 'private'".replace(/\s+/g,'')]) {
    if (marker.includes("n.nspname")) {
      assert(/n\.nspname\s*=\s*'private'/.test(source), 'restrict to private exam-prep metadata');
    } else {
      assert(source.includes(marker), 'missing catalog safety marker: ' + marker);
    }
  }
  assert(source.includes('NO_GO'), 'catalog proof must never claim release GO');
}
checkReadOnly(inventory);
checkReadOnly(transitive);
assert(transitive.includes('w.depth < 12'), 'bounded qualified-call transitive scan must be reviewed');
assert(transitive.includes('NOT e.target_oid=ANY(w.visited)'), 'qualified-call cycle guard required');
assert(transitive.includes('root_direct_dml_text') &&
       transitive.includes('reaches_dml_text'), 'nested-only writers must be distinguished');
for (const x of ['129', '83', '52', '66', '70', '4', 'NO_GO',
                 'nested-only', 'not proof', 'No claim']) {
  assert(decision.toLowerCase().includes(x.toLowerCase()),
    'status document must retain observed bounds / limitations: ' + x);
}
assert.throws(() => checkReadOnly(inventory + '\nDELETE FROM private.exam_prep_sessions;'),
  /writes\/DDL/, 'malicious DML mutation must be caught');
assert.throws(() => checkReadOnly(transitive + '\nUPDATE private.exam_prep_responses SET id=id;'),
  /writes\/DDL/, 'second mutable SQL text must be caught');
assert.throws(() => checkReadOnly(inventory + '\nSELECT * FROM private.exam_prep_sessions;'),
  /learner\/account/, 'application-row read mutation must be caught');
console.log('PASS P0-16B both metadata-only audits: SQL source guard plus 3 negative mutation tests; no release GO');
