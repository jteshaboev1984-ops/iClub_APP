'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { main, parseConfig, assertTargetPr, isStaleQueuedRun, loadQueued } = require('./ci-queued-pr-cleanup.cjs');

const oldSha = 'a'.repeat(40);
const headSha = 'b'.repeat(40);
const branch = 'ux531/math-plan-history-compact-blue-20261117';
const repo = { full_name: 'jteshaboev1984-ops/iClub_APP' };
const pr = { number: 558, state: 'open', head: { sha: headSha, ref: branch, repo },
  base: { ref: 'main', repo } };
const env = { GITHUB_REPOSITORY: repo.full_name, GITHUB_REF: 'refs/heads/main',
  GITHUB_TOKEN: 'synthetic-in-memory-token', PR_NUMBER: '558', MODE: 'preview',
  CONFIRMATION: '', MAX_CANCEL: '20', GITHUB_RUN_ID: '888' };
const run = { id: 123, head_sha: oldSha, head_branch: branch, event: 'pull_request',
  status: 'queued', pull_requests: [{ number: 558 }] };

test('safe preview default with positive strict limits', () => {
  assert.equal(parseConfig(env).mode, 'preview');
  assert.equal(parseConfig(env).maxCancel, 20);
  assert.throws(() => parseConfig({ ...env, MAX_CANCEL: '26' }));
  assert.throws(() => parseConfig({ ...env, GITHUB_REF: 'refs/heads/a-PR' }));
  assert.throws(() => parseConfig({ ...env, PR_NUMBER: '558; bad' }));
  assert.throws(() => parseConfig({ ...env, GITHUB_REPOSITORY: 'other/repo' }));
  assert.throws(() => parseConfig({ ...env, MODE: 'cancel' }), /confirmation/);
  assert.equal(parseConfig({ ...env, MODE: 'cancel', CONFIRMATION: 'CANCEL PR 558' }).mode, 'cancel');
});

test('reject closed PR, forks, wrong base and malformed sha', () => {
  assert.equal(assertTargetPr(pr, 558).headSha, headSha);
  assert.throws(() => assertTargetPr({ ...pr, state: 'closed' }, 558));
  assert.throws(() => assertTargetPr({ ...pr, head: { ...pr.head, repo: { full_name: 'fork/repo' } } }, 558));
  assert.throws(() => assertTargetPr({ ...pr, base: { ref: 'not-main', repo } }, 558));
  assert.throws(() => assertTargetPr({ ...pr, head: { ...pr.head, sha: 'invalid' } }, 558));
});

test('only old SHA, same PR, same branch, queued pull_request', () => {
  assert.ok(isStaleQueuedRun(run, 558, headSha, branch, '888'));
  const invalid = [
    { head_sha: headSha },
    { head_branch: 'other' },
    { pull_requests: [{ number: 557 }] },
    { pull_requests: [] },
    { pull_requests: undefined },
    { status: 'in_progress' },
    { status: 'waiting' },
    { status: 'pending' },
    { status: 'requested' },
    { status: 'completed' },
    { event: 'workflow_dispatch' },
    { event: 'push' },
    { id: 888 },
    { id: 'malformed-id' },
  ];
  for (const partial of invalid) {
    assert.ok(!isStaleQueuedRun({ ...run, ...partial }, 558, headSha, branch, '888'), JSON.stringify(partial));
  }
});

test('limit scan to ten pages and disclose incomplete scan', async () => {
  const api = async path => {
    const page = Number(new URL('https://api.github.com' + path).searchParams.get('page'));
    return { data: { total_count: 1240,
      workflow_runs: Array.from({ length: 100 }, (_, i) => ({ id: page * 100 + i })) } };
  };
  const result = await loadQueued(api, branch);
  assert.equal(result.listed.length, 1000);
  assert.equal(result.totalReported, 1240);
  assert.equal(result.truncated, true);
});

test('stop when queue ends', async () => {
  const result = await loadQueued(async () => ({ data: { total_count: 1, workflow_runs: [run] } }), branch);
  assert.equal(result.listed.length, 1);
  assert.equal(result.truncated, false);
});

test('preview performs GETs only; explicit cancel stops at queued stale SHA', async () => {
  const originalFetch = global.fetch;
  const calls = [];
  const latestRun = { ...run, id: 124, head_sha: headSha };
  const otherPrRun = { ...run, id: 125, pull_requests: [{ number: 557 }] };
  const dispatchRun = { ...run, id: 126, event: 'workflow_dispatch' };
  const completedRun = { ...run, id: 127, status: 'completed' };
  const candidate = { ...run, id: 123 };
  const responds = object => ({ ok: true, status: 200, text: async () => JSON.stringify(object) });
  try {
    global.fetch = async (url, options) => {
      const path = new URL(url).pathname;
      calls.push(`${options.method} ${path}`);
      if (path.endsWith('/pulls/558')) return responds(pr);
      if (path.endsWith('/actions/runs')) return responds({ total_count: 5, workflow_runs: [candidate, latestRun, otherPrRun, dispatchRun, completedRun] });
      if (path.endsWith('/runs/123')) return responds(candidate);
      if (path.endsWith('/runs/123/cancel')) return { ok: true, status: 202, text: async () => '' };
      throw new Error(`Unexpected mock request ${path}`);
    };
    await main(env);
    assert.equal(calls.filter(x => x.startsWith('POST')).length, 0);
    calls.length = 0;
    await main({ ...env, MODE: 'cancel', CONFIRMATION: 'CANCEL PR 558' });
    assert.deepEqual(calls.filter(x => x.startsWith('POST')), [
      'POST /repos/jteshaboev1984-ops/iClub_APP/actions/runs/123/cancel',
    ]);
  } finally { global.fetch = originalFetch; }
});

test('queued run changed to executing must not be cancelled', async () => {
  const originalFetch = global.fetch;
  const posts = [];
  const responds = object => ({ ok: true, status: 200, text: async () => JSON.stringify(object) });
  try {
    global.fetch = async (url, options) => {
      const path = new URL(url).pathname;
      if (path.endsWith('/pulls/558')) return responds(pr);
      if (path.endsWith('/actions/runs')) return responds({ total_count: 1, workflow_runs: [run] });
      if (path.endsWith('/runs/123')) return responds({ ...run, status: 'in_progress' });
      if (options.method === 'POST') posts.push(path);
      throw new Error(`Unexpected mock request ${path}`);
    };
    await main({ ...env, MODE: 'cancel', CONFIRMATION: 'CANCEL PR 558' });
    assert.equal(posts.length, 0);
  } finally { global.fetch = originalFetch; }
});

test('changed PR HEAD aborts without cancelling a run', async () => {
  const originalFetch = global.fetch;
  let readCount = 0;
  const posts = [];
  const responds = object => ({ ok: true, status: 200, text: async () => JSON.stringify(object) });
  try {
    global.fetch = async (url, options) => {
      const path = new URL(url).pathname;
      if (path.endsWith('/pulls/558')) {
        readCount++;
        return responds(readCount === 1 ? pr : { ...pr, head: { ...pr.head, sha: 'c'.repeat(40) } });
      }
      if (path.endsWith('/actions/runs')) return responds({ total_count: 1, workflow_runs: [run] });
      if (options.method === 'POST') posts.push(path);
      throw new Error(`Unexpected mock request ${path}`);
    };
    await assert.rejects(main({ ...env, MODE: 'cancel', CONFIRMATION: 'CANCEL PR 558' }), /changed during cleanup/);
    assert.equal(posts.length, 0);
  } finally { global.fetch = originalFetch; }
});
