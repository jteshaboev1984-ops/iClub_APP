'use strict';

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.resolve('exam-prep/exam-prep-api.js'), 'utf8');
const projectionNames = new Set([
  'get_exam_prep_diagnostic_progress_safe_v1',
  'get_exam_prep_placement_safe_v1',
  'get_exam_prep_state_safe_v1'
]);

let activeProjection = 0;
let maxProjection = 0;
let failNextDiagnostic = false;
const starts = [];

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

const sb = {
  async rpc(name, args) {
    const projection = projectionNames.has(name);
    if (projection) {
      activeProjection += 1;
      maxProjection = Math.max(maxProjection, activeProjection);
      starts.push({ name, component: args?.p_component_code ?? null });
    }

    await sleep(name === 'get_exam_prep_state_safe_v1' ? 18 : 10);

    if (projection) activeProjection -= 1;
    if (name === 'get_exam_prep_diagnostic_progress_safe_v1' && failNextDiagnostic) {
      failNextDiagnostic = false;
      return { data: null, error: { code: '40P01', message: 'synthetic deadlock' } };
    }
    return { data: { rpc: name, component: args?.p_component_code ?? null }, error: null };
  }
};

const context = vm.createContext({
  window: { sb },
  console,
  Promise,
  Object,
  String,
  Number,
  Array,
  Boolean,
  Math,
  Date,
  RegExp,
  setTimeout,
  clearTimeout
});
vm.runInContext(source, context, { filename: 'exam-prep-api.js' });

const api = context.window.iClubExamPrepHostInternal?.api;
assert.ok(api, 'Exam Prep API facade must initialize');

(async () => {
  const results = await Promise.all([
    api.diagnosticProgress('P1'),
    api.getState('P1'),
    api.getPlacement('P1'),
    api.diagnosticProgress('P5'),
    api.getState('P5')
  ]);

  assert.equal(maxProjection, 1, 'projection-rebuilding RPCs must never overlap in one browser context');
  assert.deepEqual(
    starts.map(x => [x.name, x.component]),
    [
      ['get_exam_prep_diagnostic_progress_safe_v1', 'P1'],
      ['get_exam_prep_state_safe_v1', 'P1'],
      ['get_exam_prep_placement_safe_v1', 'P1'],
      ['get_exam_prep_diagnostic_progress_safe_v1', 'P5'],
      ['get_exam_prep_state_safe_v1', 'P5']
    ],
    'projection queue must preserve invocation order'
  );
  assert.ok(results.every(x => x?.ok === true), 'serialized projection reads must preserve successful results');

  failNextDiagnostic = true;
  const failed = api.diagnosticProgress('P1');
  const afterFailure = api.getState('P1');
  const [failureResult, recoveryResult] = await Promise.all([failed, afterFailure]);

  assert.equal(failureResult?.ok, false, 'RPC error must remain fail-closed');
  assert.equal(failureResult?.reason, 'rpc_error', 'RPC error reason must be preserved');
  assert.equal(recoveryResult?.ok, true, 'one failed projection read must not poison the serialization queue');
  assert.equal(maxProjection, 1, 'queue must remain serialized after a failed RPC');

  console.log('Exam Prep projection RPC serialization regression: PASS');
})().catch(error => {
  console.error(error);
  process.exit(1);
});
