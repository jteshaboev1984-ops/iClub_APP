'use strict';

const assert = require('assert');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const text = file => fs.readFileSync(path.join(root, file), 'utf8');

const rehearsal = text('diagnostic-demo-rehearsal.js');
const ruStart = rehearsal.indexOf("ru:{title:'Полный прогон demo'");
const uzStart = rehearsal.indexOf("uz:{title:'Demo to‘liq sinovi'");
assert(ruStart >= 0 && uzStart > ruStart, 'RU and UZ rehearsal sections must exist');
const ruSection = rehearsal.slice(ruStart, uzStart);
const ruSteps = (ruSection.match(/^\s{2}'/gm) || []).length;
assert.strictEqual(ruSteps, 19, `The approved end-to-end rehearsal must contain 19 steps, found ${ruSteps}`);
assert(rehearsal.includes('done.size!==copy.steps.length'), 'A rehearsal must not count before all steps are marked');
assert(rehearsal.includes("const STAGE_KEY=P+'stage'"), 'Rehearsal progress must use a persistent demo stage key');

const stagePersist = text('diagnostic-demo-stage-persist.js');
assert(stagePersist.includes("const STAGE_KEY=P+'stage'"), 'Stage persistence helper must use the demo namespace');
assert(stagePersist.includes('setTimeout(mirror,120)'), 'Stage state must be restored after plan/language transitions');

const finalCopy = text('diagnostic-demo-copy-final.js');
for (const approved of [
  'AI-репетитор доступен в Plus.',
  'Задайте вопрос по экономике.',
  'Следующий шаг с учётом вашего прогресса.',
  'В материалах iClub пока недостаточно данных для надёжного ответа.',
  'Тур активен. AI-репетитор объясняет только общую теорию.',
  'Я не могу решать или проверять задание активного тура.',
  'Это первый положительный сигнал. Навык ещё нужно подтвердить на другой формулировке.',
  'Та же путаница повторилась в новой практике.'
]) assert(finalCopy.includes(approved), `Missing approved visible copy: ${approved}`);

const readiness = text('diagnostic-demo-gate8-final.js');
assert(readiness.includes("fetchJson('/api/diagnostic-ai-selftest')"), 'Readiness panel must run the deployed server self-test');
assert(readiness.includes("fetchJson('/api/diagnostic-ai')"), 'Readiness panel must check whether live generation is actually enabled');
assert(readiness.includes("providerHealth.generated_enabled===true"), 'Fallback-only infrastructure must not be marked as live-AI ready');

const context = text('diagnostic-demo-context.js');
assert(context.includes('diagnostic-demo-rehearsal.js'), 'Rehearsal helper must be loaded');
assert(context.includes('diagnostic-demo-stage-persist.js'), 'Stage persistence helper must be loaded');

console.log('Gate 8 stage and copy checks passed.');
