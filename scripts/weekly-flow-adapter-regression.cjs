'use strict';
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const src = fs.readFileSync('exam-prep/exam-prep-weekly-flow-adapter.js', 'utf8');
const ID = '11111111-1111-4111-8111-111111111111';
const GOAL = '22222222-2222-4222-8222-222222222222';
const AUTH = '33333333-3333-4333-8333-333333333333';
const SESSION = '44444444-4444-4444-8444-444444444444';
const goodCaps = { coreAccess: true, killSwitch: false, rolloutState: 'controlled_beta' };
let count = 0;
function fixture(responses = [], enabled = true, caps = goodCaps) {
  const calls = [];
  const window = {
    iClubExamPrepWeeklyFlowEnabled: enabled,
    iClubExamPrepHostInternal: { lastCapabilities: caps },
    sb: { async rpc(name, args) {
      calls.push({ name, args });
      if (!responses.length) throw new Error('Unplanned RPC: ' + name);
      const next = responses.shift();
      if (next === 'throw') throw new Error('network down');
      return typeof next === 'function' ? next(name, args) : next;
    } }
  };
  vm.runInNewContext(src, { window }, { filename: 'exam-prep-weekly-flow-adapter.js' });
  return { api: window.iClubExamPrepHostInternal.weeklyFlowApi, window, calls, responses };
}
const reply = data => ({ data, error: null });
async function test(name, callback) { await callback(); count++; console.log('PASS ' + name); }
(async () => {
  await test('disabled gate has no network operations and no global API interception', async () => {
    const f = fixture([], false);
    assert.equal((await f.api.plan('P1')).reason, 'weekly_flow_disabled');
    assert.equal((await f.api.start('P1', AUTH, 'idempotent-key-0001')).reason, 'weekly_flow_disabled');
    assert.equal(f.calls.length, 0);
    assert.equal(f.window.iClubExamPrepHostInternal.api, undefined);
  });
  await test('component and entitlement fail closed before any RPC', async () => {
    const f = fixture([]);
    assert.equal((await f.api.plan('INVALID')).reason, 'invalid_component');
    f.window.iClubExamPrepHostInternal.lastCapabilities = { ...goodCaps, killSwitch: true };
    assert.equal((await f.api.plan('P1')).reason, 'core_access_unavailable');
    assert.equal(f.calls.length, 0);
  });
  await test('same-week plan uses server recovery then one stable-plan request only', async () => {
    const f = fixture([reply({ status: 'none' }), reply({ status: 'existing', contract_version: 'stable_weekly_plan_v1', plan_id: ID, component_code: 'P1' })]);
    const result = await f.api.plan('P1');
    assert.equal(result.ok, true);
    assert.equal(result.data.plan_id, ID);
    assert.deepEqual(f.calls.map(c => c.name), ['get_exam_prep_active_plan_session_safe_v1', 'ensure_exam_prep_stable_weekly_plan_safe_v1']);
    assert.equal(f.calls[0].args.p_component_code, 'P1');
  });
  await test('existing unfinished session wins; no plan generation', async () => {
    const f = fixture([reply({ status: 'resume', session_id: SESSION })]);
    const result = await f.api.plan('P5');
    assert.equal(result.data.status, 'resume_first');
    assert.equal(result.data.recovery.session_id, SESSION);
    assert.equal(f.calls.length, 1);
  });
  await test('server malformed plan is not trusted', async () => {
    const f = fixture([reply({ status: 'none' }), reply({ status: 'created', plan_id: 'not-a-uuid', contract_version: 'stable_weekly_plan_v1' })]);
    assert.equal((await f.api.plan('P1')).reason, 'invalid_plan_contract');
  });
  await test('goal requires two exact UUIDs, never a priority number', async () => {
    const f = fixture([reply({ status: 'ready', priority_order: 2, component_code: 'P1' })]);
    assert.equal((await f.api.goal('P1', 1, ID)).reason, 'invalid_goal_identity');
    const result = await f.api.goal('P1', GOAL, ID);
    assert.equal(result.data.priority_order, 2);
    assert.equal(f.calls[0].args.p_goal_id, GOAL);
    assert.equal(f.calls[0].args.p_plan_id, ID);
  });
  await test('stale plan response never authorizes a guessed action', async () => {
    const f = fixture([reply({ status: 'none' }), reply({ status: 'stale', reason: 'plan_changed' })]);
    const result = await f.api.authorize('P1', GOAL, ID);
    assert.equal(result.data.status, 'stale');
    assert.equal(f.calls[1].name, 'authorize_exam_prep_goal_once_safe_v1');
    assert.equal(f.calls.length, 2);
  });
  await test('authorized session requires server-provided valid ID', async () => {
    const f = fixture([reply({ status: 'none' }), reply({ status: 'authorized', authorization_id: AUTH })]);
    assert.equal((await f.api.authorize('P1', GOAL, ID)).data.authorization_id, AUTH);
    const malformed = fixture([reply({ status: 'none' }), reply({ status: 'authorized', authorization_id: 'invalid' })]);
    assert.equal((await malformed.api.authorize('P1', GOAL, ID)).reason, 'invalid_authorization_identity');
  });
  await test('unfinished session suppresses authorization and new write', async () => {
    const f = fixture([reply({ status: 'ready_to_finalize', session_id: SESSION })]);
    const result = await f.api.authorize('P1', GOAL, ID);
    assert.equal(result.data.status, 'resume_existing_session_first');
    assert.equal(f.calls.length, 1);
  });
  await test('start unknown outcome reconciles by read; never retries write', async () => {
    const f = fixture(['throw', reply({ status: 'resume', session_id: SESSION })]);
    const result = await f.api.start('P1', AUTH, 'idempotent-key-0001');
    assert.equal(result.reason, 'start_outcome_unknown');
    assert.equal(result.recovery.session_id, SESSION);
    assert.deepEqual(f.calls.map(c => c.name), ['start_exam_prep_plan_session_once_safe_v1', 'get_exam_prep_active_plan_session_safe_v1']);
  });
  await test('unknown outcome without observed session remains blocked', async () => {
    const f = fixture([{ error: { message: 'timeout' }, data: null }, reply({ status: 'none' })]);
    const result = await f.api.start('P1', AUTH, 'idempotent-key-0001');
    assert.equal(result.reason, 'start_outcome_unknown');
    assert.equal(result.recovery.status, 'none');
    assert.equal(f.calls.length, 2);
  });
  await test('finalized authorization does not return a session id', async () => {
    const f = fixture([reply({ status: 'attempt_already_saved' })]);
    const result = await f.api.start('P1', AUTH, 'idempotent-key-0001');
    assert.equal(result.data.status, 'attempt_already_saved');
    assert.equal('session_id' in result.data, false);
  });
  await test('revocation during RPC does not expose returned session', async () => {
    const f = fixture([() => { f.window.iClubExamPrepHostInternal.lastCapabilities = { ...goodCaps, coreAccess: false }; return reply({ status: 'started', session_id: SESSION }); }]);
    assert.equal((await f.api.start('P1', AUTH, 'idempotent-key-0001')).reason, 'access_revoked');
    assert.equal(f.calls.length, 1);
  });
  await test('wrong component and malformed server recovery are rejected', async () => {
    const f = fixture([reply({ status: 'resume', session_id: SESSION, component_code: 'P5' })]);
    assert.equal((await f.api.recover('P1')).reason, 'component_mismatch');
    const bad = fixture([reply({ status: 'resume', session_id: 'bad' })]);
    assert.equal((await bad.api.recover('P1')).reason, 'invalid_session_identity');
  });
  console.log('WEEKLY FLOW ADAPTER GREEN: ' + count + ' isolated regression scenarios');
})().catch(e => { console.error(e); process.exitCode = 1; });
