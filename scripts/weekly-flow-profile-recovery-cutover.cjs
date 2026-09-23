'use strict';
// Exact-source cutover. --apply changes ONLY a disposable checkout, never production.
const fs=require('node:fs'),crypto=require('node:crypto'),assert=require('node:assert/strict');
const files=[
  {path:'exam-prep/exam-prep-api.js',sha:'bb641ae821d7ac2ff0cc314b6d4340687a7434a5'},
  {path:'exam-prep/exam-prep-recovery.js',sha:'42692818bbfa9eaf7c74b8a4505e50c7cd07c979'},
  {path:'exam-prep/exam-prep-exam-map.js',sha:'055cbdcc6bd4f5784fdfdee70210b8fba87d6748'}
];
function replaceOnce(s,oldText,newText,label){
  assert.strictEqual(s.split(oldText).length,2,`Missing or repeated audited anchor: ${label}`);
  return s.replace(oldText,newText);
}
const data=Object.fromEntries(files.map(({path,sha})=>{
  const s=fs.readFileSync(path,'utf8');
  assert.strictEqual(crypto.createHash('sha1').update(`blob ${Buffer.byteLength(s)}\0${s}`).digest('hex'),sha,`Source changed: ${path}`);
  return [path,s];
}));
const [api,recovery,map]=files.map(x=>x.path);
data[api]=replaceOnce(data[api],
  '    // Profile changes replan both components independently. Failures here never roll back the saved profile;\n    // opening a component plan can safely retry its governed generator later.\n    if (result.data?.plan_rebuild_required === true) {',
  '    // Legacy only. Guarded weeks keep their active plan and unanswered sessions.\n    // The next plan is generated through the governed entry, never as a save side effect.\n    if (result.data?.plan_rebuild_required === true && window.iClubExamPrepWeeklyFlowEnabled !== true) {',
  'profile generator');
data[recovery]=replaceOnce(data[recovery],
  '      await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);',
  '      // Record recovery without replacing active guarded tasks or pending answers.\n      if (window.iClubExamPrepWeeklyFlowEnabled !== true) {\n        await Promise.allSettled([internal.api.generateWeeklyPlan("P1"), internal.api.generateWeeklyPlan("P5")]);\n      }',
  'recovery generator');
const recoverLocales=[
  {anchor:'done: "Reja moslashtirildi",',entry:'      recorded: "Tanaffus saqlandi", recordBreak: "Tanaffusni qayd etish", saveBreak: "Tanaffusni saqlash", recordNotice: "Tanaffus saqlandi. Shu haftadagi vazifalar va tugallanmagan mashg‘ulotlar almashtirilmadi. Yangilangan jadval keyingi haftalik reja yaratilganda hisobga olinadi.",' },
  {anchor:'      error: "The action could not be completed. Try again.", done: "Plan adjusted",',entry:'      recorded: "Study break saved", recordBreak: "Record study break", saveBreak: "Save study break", recordNotice: "Your study break is recorded. This week’s tasks and unfinished sessions were not replaced. The updated schedule will be considered when a new weekly plan is created.",' },
  {anchor:'      error: "Не удалось выполнить действие. Попробуйте ещё раз.", done: "План адаптирован",',entry:'      recorded: "Перерыв сохранён", recordBreak: "Указать перерыв", saveBreak: "Сохранить перерыв", recordNotice: "Перерыв учтён. Задания этой недели и незавершённые занятия не заменены. Обновлённый график будет учтён при создании нового недельного плана.",' }
];
for(const x of recoverLocales) data[recovery]=replaceOnce(data[recovery],x.anchor,x.anchor+'\n'+x.entry,'recovery locale');
data[recovery]=replaceOnce(data[recovery],
  '${esc(modeMessage(activeRows[0]))}',
  '${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordNotice : modeMessage(activeRows[0]))}',
  'recovery dashboard');
data[recovery]=replaceOnce(data[recovery],
  '${esc(c.active)}${days ?',
  '${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recorded : c.active)}${days ?',
  'recovery active title');
data[recovery]=replaceOnce(data[recovery],
  'data-ep-recovery-open>${esc(c.adjust)}</button>',
  'data-ep-recovery-open>${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordBreak : c.adjust)}</button>',
  'recovery open button');
data[recovery]=replaceOnce(data[recovery],
  'type="submit">${esc(c.save)}</button>',
  'type="submit">${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.saveBreak : c.save)}</button>',
  'recovery save button');
data[recovery]=replaceOnce(data[recovery],
  '<strong>${esc(c.done)}</strong><div class="ep-live-notice" role="status" aria-live="polite">${esc(modeMessage(data || {}))}</div>',
  '<strong>${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recorded : c.done)}</strong><div class="ep-live-notice" role="status" aria-live="polite">${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.recordNotice : modeMessage(data || {}))}</div>',
  'recovery success');
const mapLocales=[
  {save:'      save: "Saqlash va rejani yangilash",',stable:'      saveStable: "O‘zgarishlarni saqlash",',unchanged:'      unchanged: "O‘zgarish yo‘q. Joriy reja saqlandi."',notice:'      savedWithoutReplan: "O‘zgarishlar saqlandi. Joriy haftaning vazifalari va tugallanmagan mashg‘ulotlar almashtirilmadi. Yangi sozlamalar navbatdagi haftalik reja yaratilganda hisobga olinadi.",' },
  {save:'      save: "Save and update plan",',stable:'      saveStable: "Save changes",',unchanged:'      unchanged: "Nothing changed. Your current plan has been kept."',notice:'      savedWithoutReplan: "Your changes were saved. This week’s tasks and unfinished sessions were not replaced. The new settings will be considered when the next weekly plan is created.",' },
  {save:'      save: "Сохранить и обновить план",',stable:'      saveStable: "Сохранить изменения",',unchanged:'      unchanged: "Изменений нет. Текущий план сохранён."',notice:'      savedWithoutReplan: "Изменения сохранены. Задания текущей недели и незавершённые занятия не заменены. Новые настройки будут учтены при создании следующего недельного плана.",' }
];
for(const x of mapLocales){
  data[map]=replaceOnce(data[map],x.save,x.save+'\n'+x.stable,'map save label');
  data[map]=replaceOnce(data[map],x.unchanged,x.notice+'\n'+x.unchanged,'map truthful notice');
}
data[map]=replaceOnce(data[map],
  'type="submit">${esc(c.save)}</button>',
  'type="submit">${esc(window.iClubExamPrepWeeklyFlowEnabled === true ? c.saveStable : c.save)}</button>',
  'map submit');
data[map]=replaceOnce(data[map],
  '      pendingNotice = data.series_changed === true\n        ? copy().seriesChanged',
  '      pendingNotice = window.iClubExamPrepWeeklyFlowEnabled === true && data.plan_rebuild_required === true\n        ? (data.series_changed === true ? copy().seriesChanged + " " : "") + copy().savedWithoutReplan\n        : data.series_changed === true\n        ? copy().seriesChanged',
  'series change must remain visible');
for(const {path} of files){
  assert(!/localStorage\.setItem|sessionStorage\.setItem/.test(data[path]),'No new browser storage writes');
  if(process.argv.includes('--apply'))fs.writeFileSync(path,data[path]);
}
console.log(process.argv.includes('--apply')?'Applied three isolated source changes.':'Three exact source blobs and all unique anchors verified without writes.');
