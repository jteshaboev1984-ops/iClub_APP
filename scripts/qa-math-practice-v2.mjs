#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";

const dir = process.argv[2] || "content/math/practice_v2/p1_quadratics";
const files = fs.readdirSync(dir)
  .filter((name) => /^P1-[A-Z]+-\d+\.json$/.test(name))
  .sort();

if (!files.length) {
  console.error(`No Practice question files found in ${dir}`);
  process.exit(1);
}

const rows = [];
for (const name of files) {
  const payload = JSON.parse(fs.readFileSync(path.join(dir, name), "utf8"));
  if (!Array.isArray(payload.questions)) {
    throw new Error(`${name}: questions must be an array`);
  }
  rows.push(...payload.questions);
}

const diagnosticPath = path.join(dir, "diagnostic_catalog.json");
const catalog = fs.existsSync(diagnosticPath)
  ? JSON.parse(fs.readFileSync(diagnosticPath, "utf8"))
  : { diagnostics: [] };
const catalogCodes = new Set((catalog.diagnostics || []).map((d) => d.code));

const errors = [];
const warnings = [];
const keys = new Set();
const englishStems = new Map();
const templates = new Map();
const usedCodes = new Set();
const letters = { A: 0, B: 0, C: 0, D: 0 };
const types = {};
const difficulty = {};
let sequence = "";

const norm = (value) => String(value ?? "").toLowerCase().replace(/\s+/g, " ").trim();
const templateOf = (value) => norm(value)
  .replace(/[−–—-]?\d+(?:[./]\d+)?/g, "#")
  .replace(/\s+/g, " ")
  .trim();

for (const q of rows) {
  if (!q.key) errors.push("Question without key");
  if (keys.has(q.key)) errors.push(`${q.key}: duplicate key`);
  keys.add(q.key);

  types[q.qtype] = (types[q.qtype] || 0) + 1;
  difficulty[q.difficulty] = (difficulty[q.difficulty] || 0) + 1;

  for (const locale of ["en", "ru", "uz"]) {
    if (!norm(q.question?.[locale])) errors.push(`${q.key}: missing question.${locale}`);
    if (!norm(q.explanation?.[locale])) errors.push(`${q.key}: missing explanation.${locale}`);
  }

  const stem = norm(q.question?.en);
  if (englishStems.has(stem)) {
    errors.push(`${q.key}: duplicate English stem with ${englishStems.get(stem)}`);
  } else {
    englishStems.set(stem, q.key);
  }

  const template = templateOf(q.question?.en);
  if (!templates.has(template)) templates.set(template, []);
  templates.get(template).push(q.key);

  if (q.ai_source_skill !== q.primary_skill) {
    errors.push(`${q.key}: ai_source_skill must equal primary_skill`);
  }

  if (q.qtype === "mcq") {
    if (!Array.isArray(q.options) || q.options.length !== 4) {
      errors.push(`${q.key}: MCQ must have exactly four options`);
      continue;
    }

    const optionKeys = q.options.map((o) => o.key);
    for (const expected of ["A", "B", "C", "D"]) {
      if (!optionKeys.includes(expected)) errors.push(`${q.key}: missing option ${expected}`);
    }
    if (new Set(optionKeys).size !== 4) errors.push(`${q.key}: duplicate option key`);

    const optionText = q.options.map((o) => norm(o.text?.en));
    if (new Set(optionText).size !== 4) errors.push(`${q.key}: duplicate normalized option text`);

    if (!["A", "B", "C", "D"].includes(q.correct_answer)) {
      errors.push(`${q.key}: invalid correct_answer ${q.correct_answer}`);
    } else {
      letters[q.correct_answer] += 1;
      sequence += q.correct_answer;
    }

    for (const option of q.options) {
      for (const locale of ["en", "ru", "uz"]) {
        if (!norm(option.text?.[locale])) errors.push(`${q.key}/${option.key}: missing option.${locale}`);
      }
      if (option.diagnostic_code) {
        usedCodes.add(option.diagnostic_code);
        if (!catalogCodes.has(option.diagnostic_code)) {
          errors.push(`${q.key}: diagnostic code missing from catalog: ${option.diagnostic_code}`);
        }
      }
    }
  } else if (q.qtype === "input") {
    const contract = q.answer_contract;
    if (!contract?.canonical_answer) errors.push(`${q.key}: missing canonical_answer`);
    if (!Array.isArray(contract?.accepted_examples) || !contract.accepted_examples.length) {
      errors.push(`${q.key}: missing accepted_examples`);
    }
    if (!Array.isArray(contract?.rejected_examples) || !contract.rejected_examples.length) {
      errors.push(`${q.key}: missing rejected_examples`);
    }

    const accepted = new Set((contract?.accepted_examples || []).map(norm));
    for (const example of contract?.rejected_examples || []) {
      if (accepted.has(norm(example))) errors.push(`${q.key}: same normalized example accepted and rejected: ${example}`);
    }

    for (const rule of q.diagnostic_rules || []) {
      if (rule.diagnostic_code) {
        usedCodes.add(rule.diagnostic_code);
        if (!catalogCodes.has(rule.diagnostic_code)) {
          errors.push(`${q.key}: diagnostic code missing from catalog: ${rule.diagnostic_code}`);
        }
      }
    }
  } else {
    errors.push(`${q.key}: unsupported qtype ${q.qtype}`);
  }
}

let maxRun = 0;
let run = 0;
let last = "";
for (const letter of sequence) {
  if (letter === last) run += 1;
  else {
    last = letter;
    run = 1;
  }
  maxRun = Math.max(maxRun, run);
}
if (maxRun > 3) errors.push(`Correct-option run too long: ${maxRun}`);

const mcqCount = Object.values(letters).reduce((a, b) => a + b, 0);
if (mcqCount >= 20) {
  for (const [letter, count] of Object.entries(letters)) {
    const share = count / mcqCount;
    if (share < 0.20 || share > 0.30) {
      errors.push(`Correct-option distribution outside 20-30%: ${letter}=${count}/${mcqCount}`);
    }
  }
}

for (const cycle of ["ABCD", "BCDA", "CDAB", "DABC"]) {
  if (sequence.includes(cycle.repeat(2))) {
    errors.push(`Obvious correct-answer cycle detected: ${cycle}`);
  }
}

for (const [template, questionKeys] of templates) {
  if (questionKeys.length > 1) {
    warnings.push(`Potential near-template duplicate: ${questionKeys.join(", ")} :: ${template}`);
  }
}

for (const code of catalogCodes) {
  if (!usedCodes.has(code)) warnings.push(`Unused diagnostic catalog code: ${code}`);
}

const result = {
  directory: dir,
  question_count: rows.length,
  qtype_counts: types,
  difficulty_counts: difficulty,
  correct_option_counts: letters,
  correct_option_sequence: sequence,
  max_correct_option_run: maxRun,
  diagnostic_catalog_count: catalogCodes.size,
  diagnostic_used_count: usedCodes.size,
  errors,
  warnings
};

console.log(JSON.stringify(result, null, 2));
process.exit(errors.length ? 1 : 0);
