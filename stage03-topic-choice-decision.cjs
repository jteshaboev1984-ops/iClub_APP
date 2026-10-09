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
    'const title = tr3("Продолжить незавершённую попытку?", "Tugallanmagan urinishni davom ettirasizmi?", "Resume your unfinished attempt?");'
  ],
  [
    '"Текущая тренировка не завершена. Уже отправленные ответы сохранятся, но продолжить прежнюю тренировку после смены темы будет нельзя.",',
    '"У вас есть незавершённая попытка по теме. Продолжите её или выберите другую тему. При смене темы попытка не сохранится. Результаты завершённых попыток останутся.",'
  ],
  [
    '"Joriy mashg‘ulot tugallanmagan. Yuborilgan javoblar saqlanadi, ammo mavzu almashtirilgach avvalgi mashg‘ulotni davom ettirib bo‘lmaydi.",',
    '"Sizda mavzu bo‘yicha tugallanmagan urinish bor. Uni davom ettiring yoki boshqa mavzuni tanlang. Mavzu almashtirilsa, bu urinish saqlanmaydi. Yakunlangan urinishlar natijalari saqlanadi.",'
  ],
  [
    '"Your current session is unfinished. Submitted answers will be kept, but you cannot resume the old session after changing topics."',
    '"You have an unfinished attempt for this topic. Resume it or choose another topic. If you change topics, this attempt will not be saved. Completed attempt results will remain available."'
  ],
  [
    'const cancel = tr3("Отмена", "Bekor qilish", "Cancel");',
    'const resumeText = tr3("Продолжить попытку", "Urinishni davom ettirish", "Resume attempt");'
  ],
  [
    'const approve = tr3("Сменить тему", "Mavzuni almashtirish", "Change topic");',
    'const discardText = tr3("Не сохранять и сменить тему", "Saqlamasdan mavzuni almashtirish", "Discard attempt and change topic");'
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
const practiceMessages = [["Не удалось проверить смену темы. Сохранённая тренировка не удалена.","Не удалось проверить смену темы. Незавершённая попытка сохранена."],["Mavzu almashishini tekshirib bo‘lmadi. Saqlangan mashg‘ulot o‘chirilmagan.","Mavzu almashishini tekshirib bo‘lmadi. Tugallanmagan urinish saqlanib qoldi."],["Could not verify the topic change. Your saved session has not been deleted.","Could not verify the topic change. Your unfinished attempt is still available."],["Не удалось сменить тему. Тренировка сохранена — нажмите «Продолжить», чтобы повторить.","Не удалось сменить тему. Незавершённая попытка сохранена. Нажмите «Продолжить», чтобы повторить."],["Mavzuni almashtirib bo‘lmadi. Mashg‘ulot saqlandi — «Davom ettirish» orqali qayta urinib ko‘ring.","Mavzuni almashtirib bo‘lmadi. Tugallanmagan urinish saqlanib qoldi. Qayta urinish uchun «Davom ettirish»ni bosing."],["Could not change topic. Your session is saved — use Resume to retry.","Could not change the topic. Your unfinished attempt is still available. Select Resume to retry."],["Эта тема уже сохранена. Продолжите тренировку.","У вас уже есть незавершённая попытка по этой теме. Продолжите её."],["Bu mavzu saqlangan. Mashg‘ulotni davom ettiring.","Bu mavzu bo‘yicha tugallanmagan urinish bor. Uni davom ettiring."],["This topic is already saved. Resume the session.","You already have an unfinished attempt for this topic. Resume it."]];
practiceMessages.push(
  ["Не удалось восстановить практику. Сохранённая тренировка не удалена — попробуйте ещё раз.",
   "Не удалось восстановить попытку. Черновик сохранён — попробуйте ещё раз."],
  ["Amaliyotni tiklab bo‘lmadi. Saqlangan mashg‘ulot o‘chirilmagan — qayta urinib ko‘ring.",
   "Urinishni tiklab bo‘lmadi. Qoralama saqlandi — qayta urinib ko‘ring."],
  ["Could not restore Practice. Your saved session is still here — please retry.",
   "Could not resume the attempt. Your draft is safe — please try again."]
);
for (let i=0;i<practiceMessages.length;i++) {
  const [before,after] = practiceMessages[i];
  replaceOnce(before,after,'practice copy '+i);
}
if (!next.includes('if (decision !== "replace") return;') || !next.includes('pending = {\n          userId: uid')) {
  throw new Error('Decision branch did not preserve atomic-pending flow');
}
new Function(next); // syntax only; never execute the student application during build
fs.writeFileSync(filename,next,'utf8');
console.log('STAGE03_TOPIC_DECISION_READY continue=existing_resume discard=atomic_replace cancel=preserve');

const topicFile = path.join(__dirname, 'dist', 'practice-topic-choice.js');
let topicCode = fs.readFileSync(topicFile,'utf8');
const topicReplacements = [["desc:\"Тренируйте конкретную тему отдельно от практики тура.\"","desc:\"Выберите тему для отдельной практики.\""],["empty:\"Сейчас нет доступных тематических тренировок.\"","empty:\"Пока нет доступных тем для практики.\""],["historyRecent:\"Последние тренировки\", historyCount:\"тренировок\"","historyRecent:\"Последние попытки\", historyCount:\"попыток\""],["historyFoot:\"Здесь показаны ответы тематических тренировок. Результаты туров учитываются отдельно.\"","historyFoot:\"Здесь показаны результаты попыток по темам. Результаты практики по турам учитываются отдельно.\""],["historyUnavailable:\"История тематических тренировок сейчас недоступна.\"","historyUnavailable:\"История попыток по темам сейчас недоступна.\""],["desc:\"Tur amaliyotidan alohida bir mavzu bo‘yicha mashq qiling.\"","desc:\"Tur amaliyotidan alohida mavzu bo‘yicha amaliyot qiling.\""],["empty:\"Hozircha mavjud mavzuli mashqlar yo‘q.\"","empty:\"Hozircha mavzular bo‘yicha amaliyot mavjud emas.\""],["historyRecent:\"So‘nggi mashg‘ulotlar\", historyCount:\"mashg‘ulot\"","historyRecent:\"So‘nggi urinishlar\", historyCount:\"urinish\""],["historyFoot:\"Bu yerda mavzuli mashqlar natijalari ko‘rsatiladi. Tur natijalari alohida hisoblanadi.\"","historyFoot:\"Bu yerda mavzular bo‘yicha urinishlar natijalari ko‘rsatiladi. Tur amaliyoti natijalari alohida hisoblanadi.\""],["historyUnavailable:\"Mavzuli mashqlar tarixini hozir yuklab bo‘lmadi.\"","historyUnavailable:\"Mavzular bo‘yicha urinishlar tarixini hozir yuklab bo‘lmadi.\""],["historyRecent:\"Recent topic sessions\", historyCount:\"sessions\"","historyRecent:\"Recent attempts\", historyCount:\"attempts\""],["if(lang===\"en\") return n+\" \"+(n===1?\"session\":\"sessions\");","if(lang===\"en\") return n+\" \"+(n===1?\"attempt\":\"attempts\");"],["return n+\" \"+(last===1&&hundred!==11?\"тренировка\":","return n+\" \"+(last===1&&hundred!==11?\"попытка\":"],["last>=2&&last<=4&&(hundred<12||hundred>14)?\"тренировки\":\"тренировок\");","last>=2&&last<=4&&(hundred<12||hundred>14)?\"попытки\":\"попыток\");"]];
for (let i=0; i<topicReplacements.length; i++) {
  const [before, after] = topicReplacements[i];
  const pos = topicCode.indexOf(before);
  if (pos<0 || topicCode.indexOf(before,pos+1)!==-1) throw new Error('Topic language anchor '+i);
  topicCode = topicCode.slice(0,pos) + after + topicCode.slice(pos+before.length);
}
new Function(topicCode);
fs.writeFileSync(topicFile,topicCode,'utf8');
console.log('STAGE03_PRACTICE_WORDING_OK ru=1 uz=1 en=1');
