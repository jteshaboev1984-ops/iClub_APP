#!/usr/bin/env node
'use strict';
// #574: source-only, five independently checked decimal-answer instructions.
// Deliberately compares all 495 source questions to immutable main. No keys,
// learner answers, or question texts are printed to logs or persisted.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { execFileSync } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const bank = path.join(root, 'content/math/practice_v2');
const baseline = '40e36b778e3e799b647718eab8675df99c765f8e';
const expected = new Map([
  [22, 'p1_quadratics/P1-QUA-02.json'],
  [270, 'p4_circular_trigonometry/P1-TRI-03.json'],
  [277, 'p4_circular_trigonometry/P1-TRI-04.json'],
  [325, 'p5_binomial_series/P1-SER-03.json'],
  [351, 'p5_binomial_series/P1-SER-05.json'],
]);
const locales = ['en', 'ru', 'uz'];
const formatEnding = {
  en: 'Give your answer as a decimal number.',
  ru: 'Ответ запишите десятичным числом.',
  uz: 'Javobni o‘nli son ko‘rinishida kiriting.'
};
function stable(v) {
  return Array.isArray(v) ? v.map(stable) : v && typeof v === 'object'
    ? Object.fromEntries(Object.keys(v).sort().map(k => [k, stable(v[k])])) : v;
}
function equal(a, b) { return JSON.stringify(stable(a)) === JSON.stringify(stable(b)); }
function original(relative) {
  return JSON.parse(execFileSync('git', ['show', baseline + ':' + relative],
    { cwd: root, encoding: 'utf8', maxBuffer: 7 * 1024 * 1024 }));
}
// Recompute numeric answers from source question hypotheses. Never use a
// stored answer key as the expected value or dump it into CI output.
const independent = {
  22: () => {
    const roots = [-2, 5];
    const p = -(roots[0] + roots[1]);
    const q = roots[0] * roots[1];
    return (p * p - 4 * q) / 4;
  },
  270: () => Math.sin(Math.PI / 6),
  277: () => (3 / 5) / (4 / 5),
  325: () => (6 + 3) / 2, // 2(k+3)=(k-2)+(3k-1) implies 2k=9
  351: () => 1 - 5 / (20 / 3),
};
const seen = new Set();
let questions = 0, mcq = 0, input = 0, files = 0, changed = 0;
for (const folder of fs.readdirSync(bank, { withFileTypes: true }).filter(x => x.isDirectory())) {
  for (const name of fs.readdirSync(path.join(bank, folder.name))
    .filter(x => /^P1-(?:QUA|FUN|COO|CIR|TRI|SER|DIF|INT)-\d{2}\.json$/.test(x))) {
    files++;
    const rel = 'content/math/practice_v2/' + folder.name + '/' + name;
    const before = original(rel);
    const after = JSON.parse(fs.readFileSync(path.join(root, rel), 'utf8'));
    assert.equal(before.questions.length, after.questions.length);
    assert.ok(equal({ ...before, questions: [] }, { ...after, questions: [] }), 'file metadata changed');
    for (let i = 0; i < after.questions.length; i++) {
      const old = before.questions[i], now = after.questions[i];
      assert.equal(now.key, old.key, 'question key or order mutated');
      const match = /^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(now.key);
      assert.ok(match, 'unexpected question key shape');
      const qn = Number(match[1]);
      questions++;
      if (now.qtype === 'mcq') mcq++;
      else { assert.equal(now.qtype, 'input'); input++; }
      if (!expected.has(qn)) {
        assert.ok(equal(old, now), 'unrelated source question changed');
        continue;
      }
      assert.ok(!seen.has(qn), 'duplicate corrected ID');
      seen.add(qn); changed++;
      assert.equal(expected.get(qn), folder.name + '/' + name, 'changed ID in wrong file');
      const fields = Object.keys(now).filter(k => !equal(old[k], now[k]));
      assert.deepEqual(fields, ['question'], 'unsanctioned changed field');
      assert.equal(now.qtype, 'input', 'numeric question changed type');
      assert.equal(now.answer_contract.kind, 'numeric_exact', 'numeric contract changed');
      assert.equal(now.answer_contract.number_only, true);
      assert.ok(equal(now.answer_contract, old.answer_contract), 'published answer contract changed');
      assert.ok(equal(now.explanation, old.explanation), 'solution changed');
      assert.ok(equal(now.diagnostic_rules, old.diagnostic_rules), 'diagnosis changed');
      assert.equal(now.difficulty, old.difficulty, 'difficulty changed');
      assert.equal(now.primary_skill, old.primary_skill, 'skill changed');
      const computed = independent[qn]();
      assert.ok(Math.abs(computed - Number(now.answer_contract.canonical_answer)) < 1e-10,
        'independently computed mathematical answer does not match existing contract');
      const accepted = now.answer_contract.accepted_examples;
      assert.ok(accepted.some(v => Math.abs(Number(String(v).trim().replace(',', '.')) - computed) < 1e-10),
        'derived numeric value not accepted');
      for (const l of locales) {
        assert.ok(now.question[l].startsWith(old.question[l] + ' '),
          'original learner question changed beyond appended instruction');
        assert.equal(now.question[l].slice(old.question[l].length + 1),
          qn === 22 && l === 'en'
            ? 'Enter the answer as a decimal number.'
            : formatEnding[l],
          'decimal instruction wording changed');
        assert.ok(now.explanation[l], 'missing localized explanation');
      }
    }
  }
}
assert.equal(files, 45, 'skill files missing');
assert.equal(questions, 495, 'bank question total changed');
assert.equal(mcq, 277);
assert.equal(input, 218);
assert.equal(changed, 5);
assert.equal(seen.size, expected.size);
console.log(JSON.stringify({
  status: 'PASS', authored: questions, skill_files: files,
  mcq, numeric_input: input, changed_decimal_instructions: changed,
  unchanged_source_questions: questions - changed,
  math_results_independently_checked: changed,
  locales_checked: locales.length, correct_answers_logged: false,
  published_questions_changed: false
}));
