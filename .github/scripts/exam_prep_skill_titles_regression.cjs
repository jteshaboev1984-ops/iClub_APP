'use strict';
const fs = require('fs');
const assert = require('node:assert/strict');

const src = fs.readFileSync('exam-prep/exam-prep-learner-views.js','utf8');
const titleStart = src.indexOf('const LEARNER_SKILL_TITLES');
const ruStart = src.indexOf('const LEARNER_SKILL_RU', titleStart);
const foundationStart = src.indexOf('const LEARNER_FOUNDATION_RU', ruStart);
assert(titleStart >= 0 && ruStart > titleStart && foundationStart > ruStart);

const titleBlock = src.slice(titleStart, ruStart);
const ruBlock = src.slice(ruStart, foundationStart);
const keyPattern = /"(P[15]-[A-Z]{3}-\d{2})"\s*:/g;
const titles = [...titleBlock.matchAll(keyPattern)].map(m => m[1]);
const canonical = [...ruBlock.matchAll(keyPattern)].map(m => m[1]);

assert.equal(titles.length, 81, 'exactly 81 learner skill titles required');
assert.equal(new Set(titles).size, 81, 'learner skill titles must be unique');
assert.deepEqual([...titles].sort(), [...canonical].sort(), 'title keys must match the 81 source-grounded skill keys');
for (const key of titles) {
  const row = titleBlock.match(new RegExp('"' + key + '"\\s*:\\s*\\{([^}]+)\\}'))?.[1] || '';
  assert(/\bru\s*:/.test(row) && /\buz\s*:/.test(row) && /\ben\s*:/.test(row), key + ' must contain RU UZ EN titles');
}
console.log('Exam Prep 81-skill learner-title contract: PASS');
