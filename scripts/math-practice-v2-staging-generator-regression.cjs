#!/usr/bin/env node
'use strict';

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const GENERATOR = path.join(ROOT, 'scripts', 'math-practice-v2-build-staging-sql.cjs');
const SAMPLE = path.join(ROOT, 'content', 'math', 'practice_v2', 'p1_quadratics', 'P1-QUA-01.json');

const errors = [];
const fail = (message) => errors.push(message);

function runGenerator(extraArgs = []) {
  return spawnSync(process.execPath, [GENERATOR, '--check', ...extraArgs], {
    cwd: ROOT,
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
  });
}

const tmpSql = path.join(os.tmpdir(), 'math-practice-v2-staging-generator-regression.sql');
const baseline = runGenerator(['--out', tmpSql]);

if (baseline.status !== 0) {
  fail(`baseline generator failed:\n${baseline.stdout || ''}\n${baseline.stderr || ''}`);
} else {
  let summary = null;
  try {
    summary = JSON.parse(baseline.stdout);
  } catch (error) {
    fail(`baseline summary is not valid JSON: ${error.message}`);
  }

  if (summary) {
    const expectedOrders = { 1: 68, 2: 80, 3: 68, 4: 77, 5: 66, 6: 70, 7: 66 };
    if (summary.questions !== 495) fail(`expected 495 questions, got ${summary.questions}`);
    if (summary.catalogs !== 201) fail(`expected 201 diagnostic catalog rows, got ${summary.catalogs}`);
    if (summary.diagnosticMappings !== 868) fail(`expected 868 diagnostic mappings, got ${summary.diagnosticMappings}`);
    if (summary.memberships !== 495) fail(`expected 495 memberships, got ${summary.memberships}`);
    if (summary.mcq !== 277 || summary.input !== 218) {
      fail(`expected 277 MCQ / 218 input, got ${summary.mcq} / ${summary.input}`);
    }
    if (JSON.stringify(summary.practiceOrders) !== JSON.stringify(expectedOrders)) {
      fail(`unexpected Practice counts: ${JSON.stringify(summary.practiceOrders)}`);
    }
  }
}

if (!fs.existsSync(tmpSql) || fs.statSync(tmpSql).size === 0) {
  fail('generated staging SQL is missing or empty');
} else {
  const sql = fs.readFileSync(tmpSql, 'utf8');
  for (const token of [
    'expected_exactly_one_active_math_practice_pool_per_tour',
    'expected_one_active_practice_pool_',
    'existing_staged_question_payload_drift_',
    'existing_staged_question_meta_drift_',
    'existing_staged_question_membership_drift_',
    'existing_staged_question_diagnostic_drift_',
    'staged_membership_wrong_practice_pool',
    'staging_must_not_publish_runtime_content',
  ]) {
    if (!sql.includes(token)) fail(`generated SQL missing fail-closed guard: ${token}`);
  }
}

const generatorSource = fs.readFileSync(GENERATOR, 'utf8');
for (const token of [
  "time_limit_sec:row.time_limit_sec",
  "Number(q.practice_no) !== expectedPracticeNo",
  "q.primary_skill !== skill",
  "CANONICAL_SKILLS.has(secondarySkill)",
  "v_question_exists:=found",
]) {
  if (!generatorSource.includes(token)) fail(`generator source missing regression invariant: ${token}`);
}

const original = fs.readFileSync(SAMPLE, 'utf8');
try {
  const sample = JSON.parse(original);
  sample.questions[0].practice_no = 2;
  fs.writeFileSync(SAMPLE, JSON.stringify(sample, null, 2) + '\n', 'utf8');

  const badPractice = runGenerator();
  if (badPractice.status === 0 || !/\bpractice_no\b/.test((badPractice.stderr || '') + (badPractice.stdout || ''))) {
    fail('generator did not reject a question authored into the wrong Practice');
  }

  fs.writeFileSync(SAMPLE, original, 'utf8');

  const sampleSkill = JSON.parse(original);
  sampleSkill.questions[0].primary_skill = 'P1-QUA-02';
  fs.writeFileSync(SAMPLE, JSON.stringify(sampleSkill, null, 2) + '\n', 'utf8');

  const badSkill = runGenerator();
  if (badSkill.status === 0 || !/\bprimary_skill\b/.test((badSkill.stderr || '') + (badSkill.stdout || ''))) {
    fail('generator did not reject a question whose primary skill disagrees with its skill file');
  }
} finally {
  fs.writeFileSync(SAMPLE, original, 'utf8');
  try { fs.unlinkSync(tmpSql); } catch (_) {}
}

console.log(JSON.stringify({
  ok: errors.length === 0,
  baselineQuestions: 495,
  baselineDiagnostics: 201,
  baselineMappings: 868,
  exactPracticeMappingGuard: true,
  exactSkillMappingGuard: true,
  activePoolGuard: true,
  idempotencyDriftGuard: true,
  timingInContentHash: true,
  errors,
}, null, 2));

for (const error of errors) console.error('ERROR:', error);
if (errors.length) process.exit(1);
