#!/usr/bin/env node
'use strict';
const assert=require('node:assert/strict');
const {REQUIRED,evaluate,markdown}=require('./p1p5-stage-d-release-gate.cjs');
const sha='a'.repeat(40),other='b'.repeat(40);
const goodRuns=Object.keys(REQUIRED).map((name,i)=>({
 name,id:110+i,event:'pull_request',head_sha:sha,status:'completed',
 conclusion:'success',created_at:'2026-11-02T14:00:0'+i+'Z',
 run_attempt:1,html_url:'https://github.com/example/repo/actions/runs/'+(110+i)
}));
const jobs=Object.fromEntries(goodRuns.map(r=>[String(r.id),[{
 status:'completed',conclusion:'success',
 steps:REQUIRED[r.name].map(name=>({name,status:'completed',conclusion:'success'}))
}]]));
const check=(runs,details=jobs)=>evaluate(sha,runs,details);
const all=check(goodRuns);
assert.equal(all.engine_verdict,'PASS');
assert.equal(all.accepted_workflows,3);
assert.equal(all.required_steps_total,18);
assert.equal(all.verdicts.mass_release.status,'NO_GO');
assert.equal(all.verdicts.real_user_beta.status,'UNVERIFIED');
assert.equal(all.approval_granted,false);
assert(markdown(all).includes('Mass rollout | **NO_GO**'));
assert.equal(check(goodRuns.slice(0,2)).engine_verdict,'PENDING',
 'Missing disaster workflow must fail closed');
assert.equal(check(goodRuns.map((x,i)=>i===0?{...x,head_sha:other}:x)).engine_verdict,'PENDING',
 'Wrong SHA must never inherit successful E2E');
assert.equal(check(goodRuns.map((x,i)=>i===1?{...x,conclusion:'failure'}:x)).engine_verdict,'FAIL',
 'Red load test cannot be accepted');
assert.equal(check(goodRuns.map((x,i)=>i===1?{...x,status:'in_progress',conclusion:null}:x)).engine_verdict,'PENDING');
const noCritical=structuredClone(jobs);
noCritical['110'][0].steps.shift();
const missing=check(goodRuns,noCritical);
assert.equal(missing.engine_verdict,'FAIL');
assert(missing.findings[0].missing_steps.length===1,
 'Missing true-browser step was not detected');
const skipped=structuredClone(jobs);
skipped['110'][0].steps[0].conclusion='skipped';
assert.equal(check(goodRuns,skipped).engine_verdict,'FAIL');
const oldGreen={...goodRuns[0],id:999,created_at:'2026-11-01T12:00:00Z'};
const currentRed={...goodRuns[0],id:1000,conclusion:'failure',
 created_at:'2026-11-02T17:00:00Z'};
assert.equal(check([oldGreen,currentRed,...goodRuns.slice(1)]).engine_verdict,'FAIL',
 'Old successful run must not mask newer failed attempt');
const oldRed={...goodRuns[0],id:999,conclusion:'failure',
 created_at:'2026-11-01T12:00:00Z'};
assert.equal(check([oldRed,...goodRuns]).engine_verdict,'PASS',
 'Latest successful rerun should govern same exact SHA');
const sameNamePush={...goodRuns[0],id:1002,event:'push',created_at:'2026-11-03T17:00:00Z'};
assert.equal(check([sameNamePush,...goodRuns]).engine_verdict,'PASS',
 'Push build cannot replace required PR evidence');
assert.throws(()=>evaluate('bad',goodRuns,jobs),/Invalid/);
assert.equal(check(goodRuns,{}).engine_verdict,'PENDING');
console.log('STAGE D EXACT SHA FAILURE/COVERAGE/NO_GO CONTRACT 13 GROUPS PASS');
