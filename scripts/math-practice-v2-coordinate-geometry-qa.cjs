#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const CONTENT_DIR = path.join(ROOT, 'content', 'math', 'practice_v2', 'p3_coordinate_geometry');
const CATALOG_PATH = path.join(CONTENT_DIR, 'diagnostic_catalog.json');

const EXPECTED = {
  total: 68,
  qtype: { mcq: 36, input: 32 },
  skills: {
    'P1-COO-01': 11,
    'P1-COO-02': 11,
    'P1-COO-03': 9,
    'P1-COO-04': 12,
    'P1-COO-05': 13,
    'P1-COO-06': 12,
  },
  difficultyBand: {
    easy: [12, 18],
    medium: [30, 36],
    hard: [18, 24],
  },
  correctLetterExact: 9,
  maxSameCorrectRun: 2,
};

const LANGS = ['en', 'ru', 'uz'];
const MCQ_KEYS = ['A', 'B', 'C', 'D'];
const errors = [];
const warnings = [];

function fail(message) { errors.push(message); }
function warn(message) { warnings.push(message); }
function normText(value) {
  return String(value ?? '')
    .normalize('NFKC')
    .replace(/[−–—]/g, '-')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}
function normAnswer(value) {
  return normText(value).replace(/,/g, '.');
}
function mustText(obj, field, key) {
  for (const lang of LANGS) {
    if (!obj || typeof obj[lang] !== 'string' || !obj[lang].trim()) {
      fail(`${key}: missing ${field}.${lang}`);
    }
  }
}
function isObject(value) {
  return value && typeof value === 'object' && !Array.isArray(value);
}

if (!fs.existsSync(CONTENT_DIR)) {
  console.error(`Missing content directory: ${CONTENT_DIR}`);
  process.exit(2);
}
if (!fs.existsSync(CATALOG_PATH)) {
  console.error(`Missing diagnostic catalog: ${CATALOG_PATH}`);
  process.exit(2);
}

const catalog = JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf8'));
const catalogCodes = new Set();
const catalogSkill = new Map();

for (const d of catalog.diagnostics || []) {
  if (!d.code) fail('diagnostic_catalog: diagnostic without code');
  if (catalogCodes.has(d.code)) fail(`diagnostic_catalog: duplicate code ${d.code}`);
  catalogCodes.add(d.code);
  catalogSkill.set(d.code, d.skill);
  if (!/^P1-COO-0[1-6]$/.test(d.skill || '')) {
    fail(`diagnostic_catalog: ${d.code} invalid skill ${d.skill}`);
  }
  if (!['specific', 'broad', 'unmapped'].includes(d.inference_strength)) {
    fail(`diagnostic_catalog: ${d.code} invalid inference_strength`);
  }
  mustText(d.feedback, 'feedback', `diagnostic_catalog:${d.code}`);
  mustText(d.next_action, 'next_action', `diagnostic_catalog:${d.code}`);
}

const questionFiles = fs.readdirSync(CONTENT_DIR)
  .filter((name) => /^P1-COO-\d\d\.json$/.test(name))
  .sort();

const questions = [];
for (const name of questionFiles) {
  const parsed = JSON.parse(fs.readFileSync(path.join(CONTENT_DIR, name), 'utf8'));
  if (!Array.isArray(parsed.questions)) {
    fail(`${name}: questions must be an array`);
    continue;
  }
  for (const q of parsed.questions) questions.push({ ...q, __file: name });
}

const keys = new Set();
const stems = new Map();
const skillCounts = {};
const qtypeCounts = {};
const difficultyCounts = {};
const correctLetters = { A: 0, B: 0, C: 0, D: 0 };
const perSkillLetters = {};
let correctSequence = '';

for (const q of questions) {
  const key = q.key || '<missing-key>';
  if (!q.key) fail(`${q.__file}: question without key`);
  if (keys.has(q.key)) fail(`${key}: duplicate question key`);
  keys.add(q.key);

  const keyMatch = /^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key || '');
  if (!keyMatch || Number(keyMatch[1]) < 149 || Number(keyMatch[1]) > 216) {
    fail(`${key}: invalid Coordinate Geometry key/range`);
  }
  if (!/^P1-COO-0[1-6]$/.test(q.primary_skill || '')) {
    fail(`${key}: invalid/missing primary_skill ${q.primary_skill}`);
  }
  if (q.ai_source_skill !== q.primary_skill) {
    fail(`${key}: ai_source_skill must equal primary_skill`);
  }
  if (!['easy', 'medium', 'hard'].includes(q.difficulty)) {
    fail(`${key}: invalid difficulty ${q.difficulty}`);
  }
  if (!['mcq', 'input'].includes(q.qtype)) {
    fail(`${key}: unsupported qtype ${q.qtype}`);
  }
  if (!q.source_ref || !/Ch3 Coordinate geometry/i.test(q.source_ref)) {
    fail(`${key}: missing/incorrect Coordinate Geometry source_ref`);
  }

  mustText(q.question, 'question', key);
  mustText(q.explanation, 'explanation', key);

  const stem = normText(q.question?.en);
  if (stems.has(stem)) fail(`${key}: duplicate English stem with ${stems.get(stem)}`);
  else stems.set(stem, key);

  skillCounts[q.primary_skill] = (skillCounts[q.primary_skill] || 0) + 1;
  qtypeCounts[q.qtype] = (qtypeCounts[q.qtype] || 0) + 1;
  difficultyCounts[q.difficulty] = (difficultyCounts[q.difficulty] || 0) + 1;

  if (q.qtype === 'mcq') {
    if (q.answer_contract != null) fail(`${key}: MCQ must not carry answer_contract`);
    if (!Array.isArray(q.options) || q.options.length !== 4) {
      fail(`${key}: MCQ must have exactly four options`);
      continue;
    }

    const optionKeys = q.options.map((o) => o.key);
    if (new Set(optionKeys).size !== 4 || !MCQ_KEYS.every((x) => optionKeys.includes(x))) {
      fail(`${key}: option keys must be exactly A/B/C/D`);
    }
    if (!MCQ_KEYS.includes(q.correct_answer)) {
      fail(`${key}: correct_answer must be A/B/C/D`);
    }

    const seenByLang = { en: new Set(), ru: new Set(), uz: new Set() };
    for (const option of q.options) {
      mustText(option.text, `option_${option.key}`, key);
      for (const lang of LANGS) {
        const n = normText(option.text?.[lang]);
        if (seenByLang[lang].has(n)) fail(`${key}: duplicate ${lang} option text`);
        seenByLang[lang].add(n);
      }

      const isCorrect = option.key === q.correct_answer;
      if (isCorrect && option.diagnostic_code) {
        fail(`${key}: correct option ${option.key} must not carry diagnostic_code`);
      }
      if (!isCorrect && !option.diagnostic_code) {
        fail(`${key}: wrong option ${option.key} missing deterministic diagnostic mapping`);
      }
      if (option.diagnostic_code && !catalogCodes.has(option.diagnostic_code)) {
        fail(`${key}: unknown diagnostic code ${option.diagnostic_code}`);
      }
      if (option.diagnostic_code && catalogSkill.get(option.diagnostic_code) !== q.primary_skill) {
        fail(`${key}: diagnostic ${option.diagnostic_code} belongs to ${catalogSkill.get(option.diagnostic_code)}`);
      }
    }

    correctLetters[q.correct_answer] += 1;
    correctSequence += q.correct_answer;
    perSkillLetters[q.primary_skill] ||= { A: 0, B: 0, C: 0, D: 0, n: 0 };
    perSkillLetters[q.primary_skill][q.correct_answer] += 1;
    perSkillLetters[q.primary_skill].n += 1;
  }

  if (q.qtype === 'input') {
    if (q.correct_answer != null) fail(`${key}: input must use answer_contract, not MCQ correct_answer`);
    if (!isObject(q.answer_contract)) {
      fail(`${key}: input missing answer_contract`);
      continue;
    }

    const ac = q.answer_contract;
    if (!['integer_exact', 'numeric_exact'].includes(ac.kind)) {
      fail(`${key}: input contract ${ac.kind} is not release-approved here`);
    }
    if (typeof ac.canonical_answer !== 'string' || !ac.canonical_answer.trim()) {
      fail(`${key}: missing canonical_answer`);
    }
    if (ac.number_only !== true) fail(`${key}: Coordinate Geometry input must be number_only=true`);
    if (!Array.isArray(ac.accepted_examples) || ac.accepted_examples.length < 2) {
      fail(`${key}: accepted_examples must contain at least two cases`);
    }
    if (!Array.isArray(ac.rejected_examples) || ac.rejected_examples.length < 2) {
      fail(`${key}: rejected_examples must contain at least two cases`);
    }

    const accepted = new Set((ac.accepted_examples || []).map(normAnswer));
    const rejected = new Set((ac.rejected_examples || []).map(normAnswer));
    if (!accepted.has(normAnswer(ac.canonical_answer))) {
      fail(`${key}: canonical_answer is not represented by accepted_examples after normalization`);
    }
    for (const value of accepted) {
      if (rejected.has(value)) fail(`${key}: accepted/rejected answer overlap: ${value}`);
    }

    for (const rule of q.diagnostic_rules || []) {
      if (!rule.answer_match || !rule.diagnostic_code) {
        fail(`${key}: malformed diagnostic rule`);
        continue;
      }
      if (!catalogCodes.has(rule.diagnostic_code)) {
        fail(`${key}: unknown input diagnostic code ${rule.diagnostic_code}`);
      }
      if (catalogSkill.get(rule.diagnostic_code) !== q.primary_skill) {
        fail(`${key}: input diagnostic ${rule.diagnostic_code} belongs to ${catalogSkill.get(rule.diagnostic_code)}`);
      }
      if (normAnswer(rule.answer_match) === normAnswer(ac.canonical_answer)) {
        fail(`${key}: diagnostic rule matches the correct answer`);
      }
    }
  }
}

if (questions.length !== EXPECTED.total) {
  fail(`Practice 3 total expected ${EXPECTED.total}, got ${questions.length}`);
}
for (const [skill, expected] of Object.entries(EXPECTED.skills)) {
  if ((skillCounts[skill] || 0) !== expected) {
    fail(`${skill}: expected ${expected} questions, got ${skillCounts[skill] || 0}`);
  }
}
for (const [qtype, expected] of Object.entries(EXPECTED.qtype)) {
  if ((qtypeCounts[qtype] || 0) !== expected) {
    fail(`${qtype}: expected ${expected}, got ${qtypeCounts[qtype] || 0}`);
  }
}
for (const [difficulty, band] of Object.entries(EXPECTED.difficultyBand)) {
  const actual = difficultyCounts[difficulty] || 0;
  if (actual < band[0] || actual > band[1]) {
    fail(`${difficulty}: count ${actual} outside approved band ${band[0]}-${band[1]}`);
  }
}
for (const letter of MCQ_KEYS) {
  if (correctLetters[letter] !== EXPECTED.correctLetterExact) {
    fail(`Correct-option distribution: ${letter}=${correctLetters[letter]}, expected ${EXPECTED.correctLetterExact}`);
  }
}

let maxRun = 0;
let run = 0;
let previous = '';
for (const letter of correctSequence) {
  if (letter === previous) run += 1;
  else { previous = letter; run = 1; }
  maxRun = Math.max(maxRun, run);
}
if (maxRun > EXPECTED.maxSameCorrectRun) {
  fail(`Correct-option sequence has run length ${maxRun} > ${EXPECTED.maxSameCorrectRun}`);
}

for (const [skill, dist] of Object.entries(perSkillLetters)) {
  if (dist.n >= 5) {
    for (const letter of MCQ_KEYS) {
      const share = dist[letter] / dist.n;
      if (share > 0.4 + 1e-9) {
        fail(`${skill}: correct letter ${letter} dominates ${dist[letter]}/${dist.n} (>40%)`);
      }
    }
  }
}

for (const pattern of ['ABCDABCD', 'BCDABCDA', 'CDABCDAB', 'DABCDABC']) {
  if (correctSequence.includes(pattern)) fail(`Correct-option sequence contains obvious cycle ${pattern}`);
}

const summary = {
  questions: questions.length,
  skillCounts,
  qtypeCounts,
  difficultyCounts,
  correctLetters,
  maxSameCorrectRun: maxRun,
  diagnosticCodesInCatalog: catalogCodes.size,
  errors: errors.length,
  warnings: warnings.length,
};

console.log(JSON.stringify(summary, null, 2));
for (const message of warnings) console.warn(`WARN: ${message}`);
for (const message of errors) console.error(`ERROR: ${message}`);
if (errors.length) process.exit(1);
