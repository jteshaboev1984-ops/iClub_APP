'use strict';
// Content-free synthetic regression. Real held-out diagnosis is never stored in source.
const assert = require('node:assert/strict');
const ENGLISH_EXPLANATORY_TERMS = /\b(?:normal approximation|continuity correction|mean|variance|upper tail|lower tail)\b/i;
const BINOMIAL_THREE_PARAMETER = /\b(?:Bin|B)\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)/i;
function auditDiagnosticLanguage(rule) {
  const findings = [];
  if (!rule || typeof rule !== 'object') return ['rule: object required'];
  for (const locale of ['ru', 'uz']) {
    for (const field of ['feedback', 'next_action']) {
      const value = rule[`${field}_${locale}`];
      if (typeof value !== 'string' || !value.trim()) {
        findings.push(`${locale}.${field}: nonempty localized text required`);
        continue;
      }
      if (ENGLISH_EXPLANATORY_TERMS.test(value)) findings.push(`${locale}.${field}: untranslated English explanation`);
      if (BINOMIAL_THREE_PARAMETER.test(value)) findings.push(`${locale}.${field}: ambiguous binomial notation`);
    }
  }
  return findings;
}
if (require.main === module) {
  const flawed = {
    feedback_ru: 'Дисперсия отличается от variance 24.',
    next_action_ru: 'Различайте mean=np и стандартное отклонение.',
    feedback_uz: 'Ikkinchi parametr variance 24.',
    next_action_uz: 'mean=np va variance=np(1-p) ni farqlang.'
  };
  assert.deepEqual(auditDiagnosticLanguage(flawed), [
    'ru.feedback: untranslated English explanation',
    'ru.next_action: untranslated English explanation',
    'uz.feedback: untranslated English explanation',
    'uz.next_action: untranslated English explanation'
  ]);
  const fixed = {
    feedback_ru: 'Второй параметр обозначает дисперсию, а не стандартное отклонение.',
    next_action_ru: 'Различайте математическое ожидание np и дисперсию np(1−p).',
    feedback_uz: 'Ikkinchi parametr dispersiya, standart og‘ish emas.',
    next_action_uz: 'Matematik kutilma np va dispersiya np(1−p) ni farqlang.'
  };
  assert.deepEqual(auditDiagnosticLanguage(fixed), []);
  assert.deepEqual(auditDiagnosticLanguage({...fixed,feedback_ru:'Bin(100,0,4)'}),
    ['ru.feedback: ambiguous binomial notation']);
  assert.deepEqual(auditDiagnosticLanguage({...fixed,next_action_uz:''}),
    ['uz.next_action: nonempty localized text required']);
  console.log('PASS: protected P5 diagnostic feedback RU/UZ checks, no real items, approval not inferred');
}
module.exports = {auditDiagnosticLanguage};