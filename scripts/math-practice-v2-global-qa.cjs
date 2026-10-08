#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT = path.resolve(__dirname, '..');
const PRACTICE_ROOT = path.join(ROOT, 'content', 'math', 'practice_v2');

const MODULES = [
  { dir: 'p1_quadratics', guard: 'math-practice-v2-content-qa.cjs', expected: 68 },
  { dir: 'p2_functions', guard: 'math-practice-v2-functions-qa.cjs', expected: 80 },
  { dir: 'p3_coordinate_geometry', guard: 'math-practice-v2-coordinate-geometry-qa.cjs', expected: 68 },
  { dir: 'p4_circular_trigonometry', guard: 'math-practice-v2-circular-trig-qa.cjs', expected: 77 },
  { dir: 'p5_binomial_series', guard: 'math-practice-v2-binomial-series-qa.cjs', expected: 66 },
  { dir: 'p6_differentiation', guard: 'math-practice-v2-differentiation-qa.cjs', expected: 70 },
  { dir: 'p7_integration', guard: 'math-practice-v2-integration-qa.cjs', expected: 66 },
];

const CANONICAL_SKILLS = [
  'P1-QUA-01','P1-QUA-02','P1-QUA-03','P1-QUA-04','P1-QUA-05','P1-QUA-06',
  'P1-FUN-01','P1-FUN-02','P1-FUN-03','P1-FUN-04','P1-FUN-05','P1-FUN-06','P1-FUN-07','P1-FUN-08',
  'P1-COO-01','P1-COO-02','P1-COO-03','P1-COO-04','P1-COO-05','P1-COO-06',
  'P1-CIR-01','P1-CIR-02','P1-CIR-03',
  'P1-TRI-01','P1-TRI-02','P1-TRI-03','P1-TRI-04','P1-TRI-05',
  'P1-SER-01','P1-SER-02','P1-SER-03','P1-SER-04','P1-SER-05',
  'P1-DIF-01','P1-DIF-02','P1-DIF-03','P1-DIF-04','P1-DIF-05','P1-DIF-06','P1-DIF-07',
  'P1-INT-01','P1-INT-02','P1-INT-03','P1-INT-04','P1-INT-05',
];

const LANGS = ['en','ru','uz'];
const MCQ_KEYS = ['A','B','C','D'];
const errors = [];
const warnings = [];

const fail = (m) => errors.push(m);
const warn = (m) => warnings.push(m);
const normText = (v) => String(v ?? '')
  .normalize('NFKC')
  .replace(/[−–—]/g, '-')
  .replace(/\s+/g, ' ')
  .trim()
  .toLowerCase();
const normAnswer = (v) => normText(v).replace(/,/g, '.');

function requireText(obj, label, key) {
  for (const lang of LANGS) {
    if (!obj || typeof obj[lang] !== 'string' || !obj[lang].trim()) {
      fail(`${key}: missing ${label}.${lang}`);
    }
  }
}

function runModuleGuards() {
  for (const mod of MODULES) {
    const guardPath = path.join(ROOT, 'scripts', mod.guard);
    if (!fs.existsSync(guardPath)) {
      fail(`missing module guard ${mod.guard}`);
      continue;
    }
    const result = spawnSync(process.execPath, [guardPath], {
      cwd: ROOT,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    if (result.status !== 0) {
      fail(`module guard failed: ${mod.guard}\n${result.stdout || ''}\n${result.stderr || ''}`);
    }
  }
}

runModuleGuards();

const diagnostics = new Map();
const questions = [];
const moduleCounts = {};

for (const mod of MODULES) {
  const dir = path.join(PRACTICE_ROOT, mod.dir);
  if (!fs.existsSync(dir)) {
    fail(`missing module directory ${mod.dir}`);
    continue;
  }
  moduleCounts[mod.dir] = 0;

  const catalogPath = path.join(dir, 'diagnostic_catalog.json');
  if (!fs.existsSync(catalogPath)) {
    fail(`${mod.dir}: missing diagnostic_catalog.json`);
  } else {
    const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
    for (const d of catalog.diagnostics || []) {
      if (!d.code) {
        fail(`${mod.dir}: diagnostic without code`);
        continue;
      }
      if (diagnostics.has(d.code)) {
        fail(`duplicate diagnostic code across bank: ${d.code}`);
      } else {
        diagnostics.set(d.code, d);
      }
      if (!CANONICAL_SKILLS.includes(d.skill)) {
        fail(`${d.code}: diagnostic skill is not canonical P1 skill: ${d.skill}`);
      }
      requireText(d.feedback, 'feedback', `diagnostic:${d.code}`);
      requireText(d.next_action, 'next_action', `diagnostic:${d.code}`);
    }
  }

  const files = fs.readdirSync(dir)
    .filter((name) => /^P1-(?:QUA|FUN|COO|CIR|TRI|SER|DIF|INT)-\d\d\.json$/.test(name))
    .sort();

  for (const name of files) {
    const parsed = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
    if (!Array.isArray(parsed.questions)) {
      fail(`${mod.dir}/${name}: questions must be an array`);
      continue;
    }
    for (const q of parsed.questions) {
      questions.push({ ...q, __module: mod.dir, __file: name });
      moduleCounts[mod.dir] += 1;
    }
  }

  if (moduleCounts[mod.dir] !== mod.expected) {
    fail(`${mod.dir}: expected ${mod.expected} questions, got ${moduleCounts[mod.dir]}`);
  }
}

if (questions.length !== 495) {
  fail(`global total expected 495, got ${questions.length}`);
}

const keys = new Map();
const stems = new Map();
const skills = new Set();
const qtypes = { mcq: 0, input: 0 };
const difficulty = { easy: 0, medium: 0, hard: 0 };
const letters = { A: 0, B: 0, C: 0, D: 0 };
const unicodeMinusAccepted = [];
const diagnosticUsage = new Map();

for (const q of questions) {
  const key = q.key || '<missing-key>';
  if (!q.key) fail(`${q.__module}/${q.__file}: question without key`);

  const m = /^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(q.key || '');
  if (!m) {
    fail(`${key}: invalid global key format`);
  }

  if (keys.has(q.key)) {
    fail(`${key}: duplicate key in ${q.__module}/${q.__file} and ${keys.get(q.key)}`);
  } else {
    keys.set(q.key, `${q.__module}/${q.__file}`);
  }

  if (!CANONICAL_SKILLS.includes(q.primary_skill)) {
    fail(`${key}: primary_skill is not one of the 45 canonical P1 skills: ${q.primary_skill}`);
  } else {
    skills.add(q.primary_skill);
  }

  if (q.ai_source_skill !== q.primary_skill) {
    fail(`${key}: ai_source_skill mismatch`);
  }
  if (!q.role || typeof q.role !== 'string') {
    fail(`${key}: missing role`);
  }
  if (!q.source_ref || typeof q.source_ref !== 'string') {
    fail(`${key}: missing source_ref`);
  }
  if (!['draft','approved'].includes(q.status)) {
    fail(`${key}: unsupported status ${q.status}`);
  }
  if (!['mcq','input'].includes(q.qtype)) {
    fail(`${key}: unsupported qtype ${q.qtype}`);
  } else {
    qtypes[q.qtype] += 1;
  }
  if (!['easy','medium','hard'].includes(q.difficulty)) {
    fail(`${key}: unsupported difficulty ${q.difficulty}`);
  } else {
    difficulty[q.difficulty] += 1;
  }

  requireText(q.question, 'question', key);
  requireText(q.explanation, 'explanation', key);

  const stem = normText(q.question?.en);
  if (stems.has(stem)) {
    fail(`${key}: duplicate English stem with ${stems.get(stem)}`);
  } else {
    stems.set(stem, key);
  }

  if (q.qtype === 'mcq') {
    if (q.answer_contract != null) {
      fail(`${key}: MCQ must not carry answer_contract`);
    }
    if (!Array.isArray(q.options) || q.options.length !== 4) {
      fail(`${key}: MCQ must have exactly four options`);
      continue;
    }

    const optionKeys = q.options.map((o) => o.key);
    if (new Set(optionKeys).size !== 4 || !MCQ_KEYS.every((x) => optionKeys.includes(x))) {
      fail(`${key}: option keys must be A/B/C/D`);
    }
    if (!MCQ_KEYS.includes(q.correct_answer)) {
      fail(`${key}: invalid correct_answer ${q.correct_answer}`);
    } else {
      letters[q.correct_answer] += 1;
    }

    const seenByLang = Object.fromEntries(LANGS.map((l) => [l, new Set()]));
    for (const option of q.options) {
      requireText(option.text, `option_${option.key}`, key);
      for (const lang of LANGS) {
        const n = normText(option.text?.[lang]);
        if (seenByLang[lang].has(n)) {
          fail(`${key}: duplicate ${lang} option text`);
        }
        seenByLang[lang].add(n);
      }

      const isCorrect = option.key === q.correct_answer;
      if (isCorrect && option.diagnostic_code) {
        fail(`${key}: correct option carries diagnostic_code ${option.diagnostic_code}`);
      }
      if (!isCorrect && !option.diagnostic_code) {
        fail(`${key}: wrong option ${option.key} missing diagnostic_code`);
      }
      if (option.diagnostic_code) {
        const d = diagnostics.get(option.diagnostic_code);
        if (!d) {
          fail(`${key}: unknown diagnostic_code ${option.diagnostic_code}`);
        } else if (d.skill !== q.primary_skill) {
          fail(`${key}: diagnostic ${option.diagnostic_code} belongs to ${d.skill}, not ${q.primary_skill}`);
        }
        diagnosticUsage.set(option.diagnostic_code, (diagnosticUsage.get(option.diagnostic_code) || 0) + 1);
      }
    }
  }

  if (q.qtype === 'input') {
    if (q.correct_answer != null) {
      fail(`${key}: input must not carry MCQ correct_answer`);
    }
    const ac = q.answer_contract;
    if (!ac || typeof ac !== 'object' || Array.isArray(ac)) {
      fail(`${key}: input missing answer_contract`);
      continue;
    }
    if (!['integer_exact','numeric_exact'].includes(ac.kind)) {
      fail(`${key}: unsupported global input contract ${ac.kind}`);
    }
    if (typeof ac.canonical_answer !== 'string' || !ac.canonical_answer.trim()) {
      fail(`${key}: missing canonical_answer`);
    }
    if (ac.number_only !== true) {
      fail(`${key}: global v2 scalar input must remain number_only=true until evaluator expansion is released`);
    }
    if (!Array.isArray(ac.accepted_examples) || ac.accepted_examples.length < 2) {
      fail(`${key}: accepted_examples must contain at least two cases`);
    }
    if (!Array.isArray(ac.rejected_examples) || ac.rejected_examples.length < 2) {
      fail(`${key}: rejected_examples must contain at least two cases`);
    }

    const accepted = new Set((ac.accepted_examples || []).map(normAnswer));
    const rejected = new Set((ac.rejected_examples || []).map(normAnswer));
    if (!accepted.has(normAnswer(ac.canonical_answer))) {
      fail(`${key}: canonical answer is not represented by accepted examples`);
    }
    for (const value of accepted) {
      if (rejected.has(value)) fail(`${key}: accepted/rejected overlap ${value}`);
    }
    for (const raw of ac.accepted_examples || []) {
      if (/[−–—]/.test(String(raw))) {
        unicodeMinusAccepted.push({ key, example: raw });
      }
    }

    for (const rule of q.diagnostic_rules || []) {
      if (!rule.answer_match || !rule.diagnostic_code) {
        fail(`${key}: malformed input diagnostic rule`);
        continue;
      }
      const d = diagnostics.get(rule.diagnostic_code);
      if (!d) {
        fail(`${key}: unknown input diagnostic_code ${rule.diagnostic_code}`);
      } else if (d.skill !== q.primary_skill) {
        fail(`${key}: input diagnostic ${rule.diagnostic_code} belongs to ${d.skill}, not ${q.primary_skill}`);
      }
      if (normAnswer(rule.answer_match) === normAnswer(ac.canonical_answer)) {
        fail(`${key}: diagnostic rule matches the correct answer`);
      }
      diagnosticUsage.set(rule.diagnostic_code, (diagnosticUsage.get(rule.diagnostic_code) || 0) + 1);
    }
  }
}

const keyNumbers = [...keys.keys()]
  .map((k) => Number((/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(k) || [])[1]))
  .filter(Number.isFinite)
  .sort((a,b) => a-b);

if (keyNumbers.length === 495) {
  for (let n = 1; n <= 495; n += 1) {
    if (keyNumbers[n - 1] !== n) {
      fail(`global key sequence is not contiguous at expected Q${String(n).padStart(3,'0')}`);
      break;
    }
  }
}

if (skills.size !== 45) {
  fail(`expected all 45 canonical P1 skills, got ${skills.size}`);
}
for (const skill of CANONICAL_SKILLS) {
  if (!skills.has(skill)) fail(`missing canonical skill ${skill}`);
}

const mcqTotal = qtypes.mcq;
if (mcqTotal > 0) {
  for (const letter of MCQ_KEYS) {
    const share = letters[letter] / mcqTotal;
    if (share < 0.20 || share > 0.30) {
      fail(`global correct-option share ${letter}=${letters[letter]}/${mcqTotal} (${(share*100).toFixed(1)}%) outside 20–30%`);
    }
  }
}

const orderedMcq = questions
  .filter((q) => q.qtype === 'mcq')
  .sort((a,b) => {
    const na = Number((/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(a.key) || [])[1]);
    const nb = Number((/^MATH-P1-PRACTICE2-Q(\d{3})$/.exec(b.key) || [])[1]);
    return na - nb;
  });
const sequence = orderedMcq.map((q) => q.correct_answer).join('');
let maxRun = 0, run = 0, prev = '';
for (const letter of sequence) {
  if (letter === prev) run += 1;
  else { prev = letter; run = 1; }
  maxRun = Math.max(maxRun, run);
}
if (maxRun > 3) {
  fail(`global correct-option sequence has same-letter run ${maxRun} > 3`);
}
for (const pattern of ['ABCDABCD','BCDABCDA','CDABCDAB','DABCDABC']) {
  if (sequence.includes(pattern)) fail(`global correct-option sequence contains obvious cycle ${pattern}`);
}

if (unicodeMinusAccepted.length) {
  warn(`known evaluator blocker: ${unicodeMinusAccepted.length} accepted examples use Unicode minus and require server normalisation before release`);
}

const unusedDiagnostics = [...diagnostics.keys()].filter((code) => !diagnosticUsage.has(code));

const summary = {
  questions: questions.length,
  moduleCounts,
  canonicalSkills: skills.size,
  qtypes,
  difficulty,
  correctLetters: letters,
  maxSameCorrectRun: maxRun,
  diagnosticCodes: diagnostics.size,
  diagnosticsUsed: diagnosticUsage.size,
  unusedDiagnostics,
  unicodeMinusAccepted,
  errors: errors.length,
  warnings: warnings.length,
};

console.log(JSON.stringify(summary, null, 2));
for (const message of warnings) console.warn(`WARN: ${message}`);
for (const message of errors) console.error(`ERROR: ${message}`);

if (errors.length) process.exit(1);
