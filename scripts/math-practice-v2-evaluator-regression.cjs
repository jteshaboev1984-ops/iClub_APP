#!/usr/bin/env node
'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const PRACTICE_ROOT = path.join(ROOT, 'content', 'math', 'practice_v2');
const MODULES = [
  'p1_quadratics',
  'p2_functions',
  'p3_coordinate_geometry',
  'p4_circular_trigonometry',
  'p5_binomial_series',
  'p6_differentiation',
  'p7_integration',
];

const errors = [];
const inputs = [];
const fail = (message) => errors.push(message);

function normalizeServer(value) {
  return String(value ?? '')
    .replace(/[−–—]/g, '-')
    .replace(/,/g, '.')
    .trim()
    .replace(/[\s]+/g, ' ')
    .toLowerCase();
}

function isServerNumeric(value) {
  const normalizedMinus = String(value ?? '')
    .replace(/[−–—]/g, '-')
    .trim();
  return /^-?[0-9]+([\.,][0-9]+)?$/.test(normalizedMinus);
}

function evaluateServer(userAnswer, canonicalAnswer) {
  const selected = String(userAnswer ?? '').trim();
  if (normalizeServer(selected) === normalizeServer(canonicalAnswer)) return true;

  if (isServerNumeric(selected) && isServerNumeric(canonicalAnswer)) {
    const a = Number(selected.replace(/[−–—]/g, '-').replace(',', '.'));
    const b = Number(String(canonicalAnswer).replace(/[−–—]/g, '-').replace(',', '.'));
    return Number.isFinite(a) && Number.isFinite(b) && a === b;
  }
  return false;
}

function normalizeClientNumeric(value) {
  const raw = String(value ?? '');
  if (!/[−–—]/.test(raw)) return raw;
  const normalized = raw.replace(/[−–—]/g, '-');
  const numeric = /^\s*[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)(?:[eE][+-]?\d+)?\s*$/;
  return numeric.test(normalized) ? normalized : raw;
}

function clientLooksValid(value) {
  const raw = normalizeClientNumeric(value).trim();
  return /^[+-]?(?:\d+(?:[.,]\d+)?|[.,]\d+)(?:[eE][+-]?\d+)?$/.test(raw);
}

for (const dirName of MODULES) {
  const dir = path.join(PRACTICE_ROOT, dirName);
  for (const name of fs.readdirSync(dir).sort()) {
    if (!/^P1-(?:QUA|FUN|COO|CIR|TRI|SER|DIF|INT)-\d\d\.json$/.test(name)) continue;
    const parsed = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
    for (const q of parsed.questions || []) {
      if (q.qtype === 'input') inputs.push(q);
    }
  }
}

if (inputs.length !== 218) {
  fail(`expected 218 Practice v2 input questions, got ${inputs.length}`);
}

let acceptedCases = 0;
let rejectedCases = 0;
let unicodeMinusCases = 0;

for (const q of inputs) {
  const ac = q.answer_contract || {};
  const canonical = ac.canonical_answer;

  if (!clientLooksValid(canonical)) {
    fail(`${q.key}: canonical answer fails target client numeric validation: ${canonical}`);
  }
  if (!evaluateServer(canonical, canonical)) {
    fail(`${q.key}: canonical answer fails target server evaluation`);
  }

  for (const example of ac.accepted_examples || []) {
    acceptedCases += 1;
    if (/[−–—]/.test(String(example))) unicodeMinusCases += 1;

    if (!clientLooksValid(example)) {
      fail(`${q.key}: accepted example fails target client numeric validation: ${JSON.stringify(example)}`);
    }
    if (!evaluateServer(example, canonical)) {
      fail(`${q.key}: accepted example fails target server evaluation: ${JSON.stringify(example)} -> ${canonical}`);
    }
  }

  for (const example of ac.rejected_examples || []) {
    rejectedCases += 1;
    if (evaluateServer(example, canonical)) {
      fail(`${q.key}: rejected example becomes correct under target evaluator: ${JSON.stringify(example)} -> ${canonical}`);
    }
  }
}

if (unicodeMinusCases !== 25) {
  fail(`expected 25 authored Unicode-minus accepted examples from global QA, got ${unicodeMinusCases}`);
}

const explicit = [
  ['−4', '-4', true],
  ['–4', '-4', true],
  ['—4', '-4', true],
  ['−1,6', '-1.6', true],
  [' -2.25 ', '-2.25', true],
  ['2', '-2', false],
  ['−3', '3', false],
];

for (const [actual, expected, shouldPass] of explicit) {
  const result = clientLooksValid(actual) && evaluateServer(actual, expected);
  if (result !== shouldPass) {
    fail(`explicit evaluator case failed: ${actual} vs ${expected}; expected ${shouldPass}, got ${result}`);
  }
}

console.log(JSON.stringify({
  inputQuestions: inputs.length,
  acceptedCases,
  rejectedCases,
  unicodeMinusAcceptedCases: unicodeMinusCases,
  errors: errors.length,
}, null, 2));

for (const message of errors) console.error(`ERROR: ${message}`);
if (errors.length) process.exit(1);
