'use strict';

// iClub #559. Manually dispatched only: never modify source, workflows, or learner data.
const API = 'https://api.github.com';
const REPO = 'jteshaboev1984-ops/iClub_APP';
const MAX_CANCEL = 25;
const MAX_PAGES = 10; // GitHub Actions filtered listings may cap at 1,000 runs.
const PER_PAGE = 100;

function requirePositiveInt(value, label, max) {
  const raw = String(value ?? '');
  if (!/^[1-9][0-9]*$/.test(raw) || Number(raw) > max) {
    throw new Error(`${label} must be a positive integer <= ${max}`);
  }
  return Number(raw);
}

function parseConfig(env) {
  if (env.GITHUB_REPOSITORY !== REPO || env.GITHUB_REF !== 'refs/heads/main') {
    throw new Error('Refusing to run outside iClub_APP default branch main');
  }
  if (!env.GITHUB_TOKEN) throw new Error('Missing GITHUB_TOKEN');
  const prNumber = requirePositiveInt(env.PR_NUMBER, 'PR_NUMBER', 999999999);
  const maxCancel = requirePositiveInt(env.MAX_CANCEL || '20', 'MAX_CANCEL', MAX_CANCEL);
  const mode = env.MODE;
  if (mode !== 'preview' && mode !== 'cancel') throw new Error('MODE must be preview or cancel');
  if (mode === 'cancel' && env.CONFIRMATION !== `CANCEL PR ${prNumber}`) {
    throw new Error(`Cancellation requires exact confirmation: CANCEL PR ${prNumber}`);
  }
  return { prNumber, maxCancel, mode, runId: String(env.GITHUB_RUN_ID || '') };
}

function assertTargetPr(pr, prNumber) {
  if (!pr || pr.number !== prNumber || pr.state !== 'open' || pr.base?.ref !== 'main' ||
      pr.base?.repo?.full_name !== REPO || pr.head?.repo?.full_name !== REPO ||
      !pr.head?.ref || !/^[0-9a-f]{40}$/.test(pr.head?.sha ?? '')) {
    throw new Error('Target must be an open, same-repo PR into main with a valid head SHA');
  }
  return { headSha: pr.head.sha, headBranch: pr.head.ref };
}

function isStaleQueuedRun(run, prNumber, headSha, headBranch, ownRunId) {
  return Boolean(run && run.status === 'queued' && run.event === 'pull_request' &&
    run.head_sha && run.head_sha !== headSha && run.head_branch === headBranch &&
    Number.isSafeInteger(run.id) && String(run.id) !== ownRunId &&
    Array.isArray(run.pull_requests) &&
    run.pull_requests.some(pr => pr.number === prNumber));
}

function makeApi(token) {
  return async function api(path, method = 'GET') {
    const response = await fetch(`${API}${path}`, {
      method,
      headers: {
        Accept: 'application/vnd.github+json',
        Authorization: `Bearer ${token}`,
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'iClub-queued-PR-cleanup',
      },
    });
    const body = await response.text();
    if (!response.ok && !(method === 'POST' && response.status === 409)) {
      throw new Error(`GitHub API ${method} ${path} failed (${response.status}): ${body.slice(0,240)}`);
    }
    // 202 means accepted, 409 means already past cancellation; neither needs a JSON body.
    const data = method === 'POST' ? null : (body ? JSON.parse(body) : null);
    return { status: response.status, data };
  };
}

async function loadQueued(api, branch) {
  const listed = [];
  let totalReported = 0;
  let truncated = false;
  for (let page = 1; page <= MAX_PAGES; page++) {
    const query = new URLSearchParams({ branch, event: 'pull_request', status: 'queued',
      per_page: String(PER_PAGE), page: String(page) });
    const { data } = await api(`/repos/${REPO}/actions/runs?${query}`);
    if (!Array.isArray(data?.workflow_runs)) throw new Error('Malformed Actions run list');
    if (page === 1) totalReported = data.total_count;
    listed.push(...data.workflow_runs);
    if (data.workflow_runs.length < PER_PAGE) return { listed, totalReported, truncated };
  }
  truncated = true;
  return { listed, totalReported, truncated };
}

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function main(env = process.env) {
  const cfg = parseConfig(env);
  const api = makeApi(env.GITHUB_TOKEN);
  const pr = (await api(`/repos/${REPO}/pulls/${cfg.prNumber}`)).data;
  const { headSha, headBranch } = assertTargetPr(pr, cfg.prNumber);
  const { listed, totalReported, truncated } = await loadQueued(api, headBranch);
  const candidates = listed.filter(run => isStaleQueuedRun(run, cfg.prNumber, headSha,
    headBranch, cfg.runId)).sort((a, b) => (a.created_at || '').localeCompare(b.created_at || ''));

  console.log(`PR #${cfg.prNumber} branch=${headBranch} HEAD=${headSha}`);
  console.log(`Current filtered queue: ${totalReported}, scanned=${listed.length}, stale candidates=${candidates.length}${truncated ? ' (partial scan, additional runs may exist)' : ''}`);
  const counts = new Map();
  for (const run of candidates) counts.set(run.name || 'unnamed', (counts.get(run.name || 'unnamed') || 0) + 1);
  for (const [name, n] of [...counts].sort((a, b) => b[1] - a[1]).slice(0, 10)) {
    console.log(`  ${n} × ${name}`);
  }
  console.log(`Selected batch (max ${cfg.maxCancel}): ${candidates.slice(0, cfg.maxCancel).map(r => r.id).join(', ') || '(empty)'}`);
  if (cfg.mode === 'preview') {
    console.log('PREVIEW ONLY: no cancel requests sent.');
    return;
  }

  let accepted = 0;
  let skipped = 0;
  let failed = 0;
  for (const candidate of candidates.slice(0, cfg.maxCancel)) {
    // A different HEAD means the selected candidate list is stale. Stop safely.
    const currentPr = (await api(`/repos/${REPO}/pulls/${cfg.prNumber}`)).data;
    const now = assertTargetPr(currentPr, cfg.prNumber);
    if (now.headSha !== headSha || now.headBranch !== headBranch) {
      throw new Error(`PR #${cfg.prNumber} changed during cleanup: stopping after ${accepted} accepted cancellation(s)`);
    }
    const currentRun = (await api(`/repos/${REPO}/actions/runs/${candidate.id}`)).data;
    if (!isStaleQueuedRun(currentRun, cfg.prNumber, headSha, headBranch, cfg.runId)) {
      skipped++;
      continue;
    }
    try {
      const response = await api(`/repos/${REPO}/actions/runs/${candidate.id}/cancel`, 'POST');
      if (response.status === 202) accepted++;
      else if (response.status === 409) skipped++; // Completed between recheck and request.
      else throw new Error(`Unexpected cancel status ${response.status}`);
    } catch (error) {
      failed++;
      // Do not keep requesting after possible quota/rate-limit/permission errors.
      console.error(`Cancel failed for run ${candidate.id}: ${error.message}`);
      break;
    }
    await sleep(650); // Lower API pressure on an already busy repository.
  }
  console.log(`Cancellation requests accepted=${accepted}, skipped=${skipped}, failed=${failed}. API acceptance is not proof of terminal cancelled state.`);
  if (failed) process.exitCode = 1;
}

if (require.main === module) {
  main().catch(err => { console.error(`SAFE STOP: ${err.message}`); process.exitCode = 1; });
}

module.exports = { main, parseConfig, assertTargetPr, isStaleQueuedRun, loadQueued, requirePositiveInt };
