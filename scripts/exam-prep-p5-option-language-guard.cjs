'use strict';
/*
 * Synthetic, content-free regression helper for Exam Prep multilingual MCQ QA.
 * No production access; do not copy assessment stems, answers or reserve options here.
 * This flags English prose copied into RU/UZ option positions; symbolic-only options
 * are deliberately excluded. Human language/mathematical review remains necessary.
 */
const assert = require('node:assert/strict');
const SYMBOL_TOKENS = new Set([
  'a', 'b', 'c', 'd', 'e', 'f', 'h', 'i', 'j', 'k', 'm', 'n', 'p', 'q', 'r', 's',
  't', 'u', 'v', 'w', 'x', 'y', 'z', 'mu', 'sigma', 'iqr', 'sd', 'sqrt', 'sin',
  'cos', 'tan', 'ln', 'log', 'pi', 'hh', 'ht', 'th', 'tt', 'na'
]);
function normalize(s) {
  return String(s || '').normalize('NFKC').replace(/\s+/g, ' ').trim().toLowerCase();
}
function isLexicalEnglish(s) {
  // Conventional distribution names followed by arguments are notation, not prose.
  const withoutNotation = String(s || '').replace(/\b(?:Bin|Geom|Geometric|Normal|N)\s*\([^)]*\)/gi, '');
  const tokens = withoutNotation.match(/[A-Za-z]+/g) || [];
  return tokens.some(token => !SYMBOL_TOKENS.has(token.toLowerCase()));
}
function auditMcqOptions(question) {
  const issues = [];
  if (question.qtype !== 'mcq') return issues;
  const locales = ['en', 'ru', 'uz'];
  for (const locale of locales) {
    const choices = question.options?.[locale];
    if (!Array.isArray(choices) || choices.length !== 4 || choices.some(s => typeof s !== 'string' || !s.trim())) {
      issues.push(`${locale}: four nonempty choice strings required`);
    }
  }
  if (issues.length) return issues;
  for (let index = 0; index < 4; index++) {
    const en = question.options.en[index];
    if (!isLexicalEnglish(en)) continue;
    for (const locale of ['ru', 'uz']) {
      if (normalize(question.options[locale][index]) === normalize(en)) {
        issues.push(`${locale}: choice ${index + 1} still equals English prose`);
      }
    }
  }
  return issues;
}
function auditNotationAndTerminology(question) {
  const issues = [];
  for (const locale of ['ru', 'uz']) {
    const stem = String(question.stems?.[locale] || '');
    if (/\bnormal approximation\b/i.test(stem)) issues.push(`${locale}: English term normal approximation remains in stem`);
    if (/\bcontinuity correction\b/i.test(stem)) issues.push(`${locale}: English term continuity correction remains in stem`);
    const values = [stem, ...(question.qtype === 'mcq' ? (question.options?.[locale] || []) : [])];
    for (const [index, value] of values.entries()) {
      if (/\b(?:Bin|B)\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)/i.test(value)) {
        issues.push(`${locale}: ambiguous three-comma binomial notation in ${index === 0 ? 'stem' : `choice ${index}`}`);
      }
    }
  }
  return issues;
}
if (require.main === module) {
  const clonedProse = {
    qtype: 'mcq', options: {
      en: ['Line graph', 'Pie chart', 'Scatter plot', 'Box plot'],
      ru: ['Линейный график', 'Pie chart', 'Диаграмма рассеяния', 'Диаграмма «ящик с усами»'],
      uz: ['Chiziqli grafik', 'Doiraviy diagramma', 'Nuqtali diagramma', 'Box plot']
    }
  };
  assert.deepEqual(auditMcqOptions(clonedProse), [
    'ru: choice 2 still equals English prose', 'uz: choice 4 still equals English prose'
  ]);
  const localized = {
    qtype: 'mcq', options: {
      en: ['Line graph', 'Pie chart', 'Scatter plot', 'Box plot'],
      ru: ['Линейный график', 'Круговая диаграмма', 'Диаграмма рассеяния', 'Диаграмма «ящик с усами»'],
      uz: ['Chiziqli grafik', 'Doiraviy diagramma', 'Nuqtali diagramma', 'Quti-mo‘ylov diagrammasi']
    }
  };
  assert.deepEqual(auditMcqOptions(localized), []);
  for (const choices of [
    ['2', '4', '6', 'sqrt(20)'],
    ['n=8, p=1/6', 'n=6, p=1/8', 'n=8, p=5/6', 'n=1/6, p=8'],
    ['IQR 5, SD 3', 'IQR 10, SD 6', 'IQR 17, SD 13', 'IQR 10, SD 13'],
    ['{HH,HT,TH,TT}', '{HH,HT,TT}', '{H,T}', '{HH,TT}']
  ]) {
    assert.deepEqual(auditMcqOptions({qtype:'mcq', options:{en:choices, ru:choices, uz:choices}}), []);
  }
  assert.equal(auditMcqOptions({qtype:'mcq', options:{en:['A'],ru:['Б'],uz:['B']}}).length, 3);
  assert.equal(isLexicalEnglish('Geometric(p)'), false, 'distribution notation is not English prose');
  assert.equal(isLexicalEnglish('Bin(50,0.5)'), false, 'binomial notation is not English prose');
  assert.deepEqual(auditNotationAndTerminology({
    qtype: 'mcq', stems: {ru:'X~Bin(100,0,4). Найдите normal approximation с continuity correction.',uz:'X~Bin(100,0.4).'},
    options: {ru:['Bin(20,0,5)','Bin(20,0.5)','4','6'],uz:['Bin(20,0.5)','Bin(20,0.5)','4','6']}
  }), [
    'ru: English term normal approximation remains in stem',
    'ru: English term continuity correction remains in stem',
    'ru: ambiguous three-comma binomial notation in stem',
    'ru: ambiguous three-comma binomial notation in choice 1'
  ]);
  assert.deepEqual(auditNotationAndTerminology({qtype:'input',stems:{ru:'X~Bin(20,0.4)',uz:'X~Bin(20,0.4)'}}), []);
  assert.deepEqual(auditMcqOptions({qtype:'input', options:{en:[],ru:[],uz:[]}}), []);
  console.log('PASS P5 synthetic localization audit: prose-copy, mathematical distribution notation, extra-comma Bin(n,p), leftover English terminology, symbolic controls and input exclusions validated. No protected items or production access.');
}
module.exports = { auditMcqOptions, auditNotationAndTerminology, isLexicalEnglish };
