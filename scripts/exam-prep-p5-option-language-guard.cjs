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
  const tokens = String(s || '').match(/[A-Za-z]+/g) || [];
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
  assert.deepEqual(auditMcqOptions({qtype:'input', options:{en:[],ru:[],uz:[]}}), []);
  console.log('PASS P5 option language synthetic audit: prose-copy flagged; RU/UZ localization, numeric, symbolic, incomplete arrays and input exclusions validated. No protected item payloads or production access.');
}
module.exports = { auditMcqOptions, isLexicalEnglish };
