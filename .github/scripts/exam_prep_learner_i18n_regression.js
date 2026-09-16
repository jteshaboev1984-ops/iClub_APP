'use strict';

const fs = require('fs');
const vm = require('vm');

const path = 'exam-prep/exam-prep-i18n.js';
const source = fs.readFileSync(path, 'utf8');
const sandbox = { window: {} };
vm.runInNewContext(source, sandbox, { filename: path });

const i18n = sandbox.window.iClubExamPrepPreview?.i18n;
if (!i18n) throw new Error('Exam Prep i18n object was not created');

const ru = i18n.get('ru');
const en = i18n.get('en');
const uz = i18n.get('uz');

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function sortedKeys(value) {
  return Object.keys(value || {}).sort().join('|');
}

assert(sortedKeys(ru) === sortedKeys(en), 'RU/EN top-level translation keys differ');
assert(sortedKeys(ru) === sortedKeys(uz), 'RU/UZ top-level translation keys differ');
assert(sortedKeys(ru.routes) === sortedKeys(en.routes) && sortedKeys(ru.routes) === sortedKeys(uz.routes), 'Route translation keys differ');
assert(sortedKeys(ru.services) === sortedKeys(en.services) && sortedKeys(ru.services) === sortedKeys(uz.services), 'Service translation keys differ');
assert(sortedKeys(ru.readinessStates) === sortedKeys(en.readinessStates) && sortedKeys(ru.readinessStates) === sortedKeys(uz.readinessStates), 'Readiness translation keys differ');
assert(Array.isArray(ru.stages) && ru.stages.length === 7, 'RU stages must contain exactly seven learner stages');
assert(Array.isArray(en.stages) && en.stages.length === 7, 'EN stages must contain exactly seven learner stages');
assert(Array.isArray(uz.stages) && uz.stages.length === 7, 'UZ stages must contain exactly seven learner stages');

assert(ru.weeklyBudget === 'Время на математику', 'RU Mathematics-time copy regressed');
assert(ru.timedTitle === 'Работа на время и полные экзаменационные работы', 'RU timed-work copy regressed');
assert(ru.fullPaper === 'Полная экзаменационная работа', 'RU full-paper copy regressed');
assert(ru.stages[1] === 'Основы' && ru.stages[3] === 'Завершение программы' && ru.stages[6] === 'Финальная подготовка', 'RU learner stage wording regressed');

assert(uz.targetWindow === 'Tavsiya etilgan muddat', 'UZ target-window copy regressed');
assert(uz.weeklyBudget === 'Matematikaga ajratilgan vaqt', 'UZ Mathematics-time copy regressed');
assert(uz.selfReviewed === 'Mustaqil tekshirilgan · mentor tasdig‘isiz', 'UZ self-review copy regressed');
assert(uz.aiUnavailable === 'AI hozir ishlamayapti. Reja va barcha zarur o‘quv ishlari usiz ham davom etadi.', 'UZ AI fallback copy regressed');
assert(uz.offlineNoUplift === 'Server natijani tasdiqlamaguncha u tasdiqlangan natijaga qo‘shilmaydi.', 'UZ server-verification copy regressed');
assert(uz.timedTitle === 'Vaqtli mashqlar va to‘liq imtihon ishlari', 'UZ timed-work copy regressed');
assert(uz.fullPaper === 'To‘liq imtihon ishi', 'UZ full-paper copy regressed');
assert(uz.actualTime === 'Sarflangan vaqt', 'UZ actual-time copy regressed');
assert(uz.inTime === 'Belgilangan vaqtda olingan ball', 'UZ in-time copy regressed');
assert(uz.noMentorQueue === 'Sizga faol mentor biriktirilmagan. Kurs mentor tekshiruvini kutmasdan davom etadi.', 'UZ no-mentor copy regressed');
assert(uz.stages[1] === 'Asoslarni mustahkamlash' && uz.stages[3] === 'Dastur mavzularini yakunlash' && uz.stages[6] === 'Yakuniy tayyorgarlik', 'UZ learner stage wording regressed');

const forbiddenExact = [
  'Время на Mathematics',
  'Работа на время и полные papers',
  'Yo‘naltiruvchi muddat',
  'Mathematics uchun vaqt',
  'O‘zini tekshirgan · mentor tasdig‘isiz',
  'AI hozir mavjud emas. Reja va barcha zarur o‘quv ishlari AI siz ham davom etadi.',
  'Server tasdiqlamaguncha progress oshmaydi.',
  'Vaqtli ish va to‘liq papers',
  'To‘liq paper',
  'Sizga faol mentor biriktirilmagan. Kurs tekshiruv navbatisiz davom etadi.'
];
for (const phrase of forbiddenExact) {
  assert(!source.includes(phrase), `Old learner-facing phrase returned: ${phrase}`);
}

assert(en.weeklyBudget === 'Mathematics time', 'EN baseline unexpectedly changed');
assert(en.timedTitle === 'Timed work and full papers', 'EN baseline unexpectedly changed');

console.log('EXAM_PREP_LEARNER_I18N_GREEN');
