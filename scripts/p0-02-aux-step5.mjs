import fs from 'node:fs';
import { assert, range, replaceNamed } from './p0-02-aux-patcher.mjs';

let app = fs.readFileSync('app.js', 'utf8');
let html = fs.readFileSync('index.html', 'utf8');

const before = range(app, 'buildPracticeSetByQuestionIds').text;
assert(before.includes('.from("questions")'), 'buildPracticeSetByQuestionIds no longer contains expected legacy direct questions read');
assert(before.includes('correct_answer'), 'buildPracticeSetByQuestionIds expected answer-key projection missing');

app = replaceNamed(app, 'buildPracticeSetByQuestionIds', `async function buildPracticeSetByQuestionIds(subjectKey, questionIds) {
  void subjectKey;
  void questionIds;
  return [];
}`);

const after = range(app, 'buildPracticeSetByQuestionIds').text;
assert(!after.includes('.from("questions")'), 'buildPracticeSetByQuestionIds still reads questions directly');
assert(!after.includes('correct_answer'), 'buildPracticeSetByQuestionIds still contains answer key');

const oldAppKey = 'app.js?v=support4-p002v4aux1';
assert(html.includes(oldAppKey), 'expected app cache key missing');
html = html.replace(oldAppKey, 'app.js?v=support4-p002v4aux2');

fs.writeFileSync('app.js', app);
fs.writeFileSync('index.html', html);
