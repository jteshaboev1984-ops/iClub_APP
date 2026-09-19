'use strict';
// Review-only source patcher. NEVER contacts Supabase or writes a GitHub branch.
// --apply edits three files in a disposable checkout after exact Git blob SHA checks.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const files = [
  { path: 'exam-prep/exam-prep-api.js', sha: 'bb641ae821d7ac2ff0cc314b6d4340687a7434a5' },
  { path: 'exam-prep/exam-prep-recovery.js', sha: '42692818bbfa9eaf7c74b8a4505e50c7cd07c979' },
  { path: 'exam-prep/exam-prep-exam-map.js', sha: '055cbdcc6bd4f5784fdfdee70210b8fba87d6748' }
];
function blobSha(value) {
  return crypto.createHash('sha1').update(`blob ${Buffer.byteLength(value)}\0${value}`).digest('hex');
}
function replaceOne(source, oldText, newText, label) {
  assert(source.includes(oldText), `Missing audited anchor: ${label}`);
  assert.strictEqual(source.split(oldText).length, 2, `Expected exactly one anchor: ${label}`);
  return source.replace(oldText, newText);
}
const sources = Object.fromEntries(files.map(({path, sha}) => {
  const content = fs.readFileSync(path, 'utf8');
  assert.strictEqual(blobSha(content), sha, `Unexpected changed source ${path}: re-review before patching`);
  return [path, content];
}));
const api = files[0].path, recovery = files[1].path, examMap = files[2].path;
sources[api] = replaceOne(sources[api],
  '    // Profile changes replan both components independently. Failures here never roll back the saved profile;\n    // opening a component plan can safely retry its governed generator later.\n    if (result.data?.plan_rebuild_required === true) {',
  '    // Existing route only. The guarded route retains unfinished sessions and the\n    // current weekly plan. A new plan is created later by the governed server route.\n    if (result.data?.plan_rebuild_required === true && window.iClubExamPrepWeeklyFlowEnabled !== true) {',
  'profile old generator');
sources[recovery] = replaceOne(sources[recovery],
  '      await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);',
  '      // Store the recovery record but never silently overwrite a guarded weekly plan.\n      // The governed plan entry will create the next plan when there is no current plan.\n      if (window.iClubExamPrepWeeklyFlowEnabled !== true) {\n        await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);\n      }',
  'recovery old generator');
// Make guarded recovery UI truthful: recording a break is not replanning.
const locales = [
  {id:'uz', after:'done: "Reja moslashtirildi",', keys:'      recorded: "Tanaffus saqlandi", recordBreak: "Tanaffusni qayd etish", saveBreak: "Tanaffusni saqlash", recordNotice: "Tanaffus saqlandi. Shu haftadagi vazifalar va tugallanmagan mashg‘ulotlar almashtirilmadi. Yangilangan jadval keyingi haftalik reja yaratilganda hisobga olinadi.",'},
  {id:'en', after:'      error: "The action could not be completed. Try again.", done: "Plan adjusted",', keys:'      recorded: "Study break saved", recordBreak: "Record study break", saveBreak: "Save study break", recordNotice: "Your study break is recorded. This week’s tasks and unfinished sessions were not replaced. The updated schedule will be considered when a new weekly plan is created.",'},
  {id:'ru', after:'      error: "Не удалось выполнить действие. Попробуйте ещё раз.", done: "План адаптирован",', keys:'      recorded: "Перерыв сохранён", recordBreak: "Указать перерыв", saveBreak: "Сохранить перерыв", recordNotice: "Перерыв учтён. Задания этой недели и незавершённые занятия не заменены. Обновлённый график будет учтён при создании нового недельного плана.",'}
];
for (const x of locales) sources[recovery] = replaceOne(sources[recovery], x.after, `${x.after}\n${x.keys}`, `recovery ${x.id} strings`);
sources[recovery] = replaceOne(sources[recovery],
  '${esc(modeMessage(activeRows[0]))}',
  '${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordNotice : modeMessage(activeRows[0]))}',
  'recovery dashboard message');
sources[recovery] = replaceOne(sources[recovery],
  '${esc(c.active)}${days ?',
  '${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recorded : c.active)}${days ?',
  'recovery dashboard title');
sources[recovery] = replaceOne(sources[recovery],
  'data-ep-recovery-open>${esc(c.adjust)}</button>',
  'data-ep-recovery-open>${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordBreak : c.adjust)}</button>',
  'recovery dashboard button');
sources[recovery] = replaceOne(sources[recovery],
  'type="submit">${esc(c.save)}</button>',
  'type="submit">${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.saveBreak : c.save)}</button>',
  'recovery form button');
sources[recovery] = replaceOne(sources[recovery],
  '<strong>${esc(c.done)}</strong><div class="ep-live-notice" role="status" aria-live="polite">${esc(modeMessage(data || {}))}</div>',
  '<strong>${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recorded : c.done)}</strong><div class="ep-live-notice" role="status" aria-live="polite">${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordNotice : modeMessage(data || {}))}</div>',
  'recovery honest success');
// The exam-profile UI must not say a weekly plan was rebuilt when it was not.
const mapLocales = [
  {anchor:'      unchanged: "O‘zgarish yo‘q. Joriy reja saqlandi."',value:'      savedWithoutReplan: "O‘zgarishlar saqlandi. Joriy haftaning vazifalari va tugallanmagan mashg‘ulotlar almashtirilmadi. Yangi sozlamalar navbatdagi haftalik reja yaratilganda hisobga olinadi.",'},
  {anchor:'      unchanged: "Nothing changed. Your current plan has been kept."',value:'      savedWithoutReplan: "Your changes were saved. This week’s tasks and unfinished sessions were not replaced. The new settings will be considered when the next weekly plan is created.",'},
  {anchor:'      unchanged: "Изменений нет. Текущий план сохранён."',value:'      savedWithoutReplan: "Изменения сохранены. Задания текущей недели и незавершённые занятия не заменены. Новые настройки будут учтены при создании следующего недельного плана.",'}
];
for (const x of mapLocales) sources[examMap] = replaceOne(sources[examMap], x.anchor, `${x.value}\n${x.anchor}`, 'profile localized notice');
sources[examMap] = replaceOne(sources[examMap],
  '      pendingNotice = data.series_changed === true\n        ? copy().seriesChanged',
  '      pendingNotice = window.iClubExamPrepWeeklyFlowEnabled === true && data.plan_rebuild_required === true\n        ? copy().savedWithoutReplan\n        : data.series_changed === true\n        ? copy().seriesChanged',
  'profile saved notice');
for (const {path} of files) {
  assert(!sources[path].includes('localStorage.setItem') && !sources[path].includes('sessionStorage.setItem'), 'Do not add browser storage writes');
  if (process.argv.includes('--apply')) fs.writeFileSync(path, sources[path]);
}
console.log(process.argv.includes('--apply') ? 'Applied three reviewed guarded entrypoint changes to disposable checkout.' : 'Verified three exact source blobs and unique cutover anchors; no writes.');
