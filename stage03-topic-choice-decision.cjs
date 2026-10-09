'use strict';
// QA-only Stage 03 user-flow alignment; applied after the original Stage 09 checksum gate.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const filename = path.join(__dirname, 'dist', 'app.js');
const original = fs.readFileSync(filename, 'utf8');
let next = original;
function replaceOnce(oldText, newText, description) {
  const first = next.indexOf(oldText);
  if (first === -1 || next.indexOf(oldText, first + 1) !== -1) {
    throw new Error('Stage03 topic decision anchor mismatch: ' + description);
  }
  next = next.slice(0,first) + newText + next.slice(first+oldText.length);
}
const replacements = [
  [
    'const title = tr3("Сменить тему?", "Mavzuni almashtirasizmi?", "Change topic?");',
    'const title = tr3("Продолжить сохранённую тренировку?", "Saqlangan mashg‘ulotni davom ettirasizmi?", "Resume your saved practice?");'
  ],
  [
    '"Текущая тренировка не завершена. Уже отправленные ответы сохранятся, но продолжить прежнюю тренировку после смены темы будет нельзя.",',
    '"У вас есть незавершённая тренировка. Продолжите её или выберите другую тему. При смене темы эта попытка не сохранится. Завершённые результаты останутся.",'
  ],
  [
    '"Joriy mashg‘ulot tugallanmagan. Yuborilgan javoblar saqlanadi, ammo mavzu almashtirilgach avvalgi mashg‘ulotni davom ettirib bo‘lmaydi.",',
    '"Tugallanmagan mashg‘ulotingiz bor. Uni davom ettiring yoki boshqa mavzuni tanlang. Boshqa mavzu tanlansa, bu urinish saqlanmaydi. Yakunlangan natijalar saqlanadi.",'
  ],
  [
    '"Your current session is unfinished. Submitted answers will be kept, but you cannot resume the old session after changing topics."',
    '"You have an unfinished session. Resume it or choose another topic. If you change topics, this attempt will not be saved. Completed results remain available."'
  ],
  [
    'const cancel = tr3("Отмена", "Bekor qilish", "Cancel");',
    'const resumeText = tr3("Продолжить", "Davom ettirish", "Resume");'
  ],
  [
    'const approve = tr3("Сменить тему", "Mavzuni almashtirish", "Change topic");',
    'const discardText = tr3("Не сохранять и сменить тему", "Saqlamasdan mavzuni almashtirish", "Discard and change topic");'
  ],
  [
    'try { return !!window.confirm(title + "\\n\\n" + detail); }\n    catch { return false; }',
    'return "cancel"; // Never silently discard when the dialog cannot be displayed.'
  ],
  [
    'const actions = document.createElement("div");\n    actions.className = "modal-actions";',
    'const actions = document.createElement("div");\n    actions.className = "modal-actions";\n    actions.style.display = "grid";\n    actions.style.gridTemplateColumns = "minmax(0, 1fr)";\n    actions.style.gap = "8px";'
  ],
  ['cancelBtn.className="btn";','cancelBtn.className="btn primary";'],
  ['cancelBtn.textContent=cancel;','cancelBtn.textContent=resumeText;'],
  ['yesBtn.className="btn primary";','yesBtn.className="btn";'],
  ['yesBtn.textContent=approve;','yesBtn.textContent=discardText;'],
  ['actions.append(cancelBtn,yesBtn);','actions.append(cancelBtn,yesBtn);'],
  ['if (event.key === "Escape") { event.preventDefault(); finish(false); }','if (event.key === "Escape") { event.preventDefault(); finish("cancel"); }'],
  ['function finish(approved) {','function finish(choice) {'],
  ['resolve(!!approved);','resolve(choice);'],
  ['if (event.target === backdrop) finish(false);','if (event.target === backdrop) finish("cancel");'],
  ['cancelBtn.addEventListener("click",()=>finish(false),{once:true});','cancelBtn.addEventListener("click",()=>finish("resume"),{once:true});'],
  ['yesBtn.addEventListener("click",()=>finish(true),{once:true});','yesBtn.addEventListener("click",()=>finish("replace"),{once:true});'],
  ['yesBtn.focus();','cancelBtn.focus();'],
  [
    'if (!await confirmPracticeTopicReplacement()) return;',
    'const decision = await confirmPracticeTopicReplacement();\n        if (decision === "resume") {\n          const resumeButton = document.getElementById("practice-resume-btn");\n          if (!resumeButton) { showToast(t("not_available")); return; }\n          resumeButton.click(); // Use the existing validated resume path.\n          return;\n        }\n        if (decision !== "replace") return;'
  ]
];
const start = next.indexOf('async function confirmPracticeTopicReplacement() {');
const end = next.indexOf('\nasync function resumePendingPracticeTopicChoice(draft)', start);
if (start < 0 || end < start || next.indexOf('async function confirmPracticeTopicReplacement() {',start+1)!==-1) {
  throw new Error('Missing or duplicate confirmation function');
}
for (let i=0;i<replacements.length;i++) {
  const [a,b]=replacements[i];
  replaceOnce(a,b,'flow-'+i);
}
if (!next.includes('if (decision !== "replace") return;') || !next.includes('pending = {\n          userId: uid')) {
  throw new Error('Decision branch did not preserve atomic-pending flow');
}
new Function(next); // syntax only; never execute the student application during build
fs.writeFileSync(filename,next,'utf8');
console.log('STAGE03_TOPIC_DECISION_READY continue=existing_resume discard=atomic_replace cancel=preserve');
