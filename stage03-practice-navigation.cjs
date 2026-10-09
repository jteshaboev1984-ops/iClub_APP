'use strict';
// iClub Stage 03 QA: navigation and terminology only, after signed Stage09 build.
// No writes to browser storage at build time. Runtime uses existing safe pause.
const fs=require('node:fs');
const path=require('node:path');
const base=__dirname;
const appFile=path.join(base,'dist','app.js');
const tabFile=path.join(base,'dist','practice-results-tabs.js');
const htmlFile=path.join(base,'dist','index.html');
let app=fs.readFileSync(appFile,'utf8');
let tabs=fs.readFileSync(tabFile,'utf8');
let html=fs.readFileSync(htmlFile,'utf8');
const edits=[{"label":"pause_busy_guard","before":"    if (!quiz || quiz.mode !== \"practice\") return;\n\n    stopPracticeQuestionTimer();","after":"    if (!quiz || quiz.mode !== \"practice\") return;\n    if (quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight) {\n      showToast(tr3(\n        \"Подождите, ответ сохраняется.\",\n        \"Kuting, javob saqlanmoqda.\",\n        \"Please wait while your answer is saved.\"\n      ));\n      return;\n    }\n\n    stopPracticeQuestionTimer();"},{"label":"pause_return_to_practice","before":"    showToast(t(\"practice_paused\"));\n    replaceCourses(\"subject-hub\");\n    renderSubjectHub();","after":"    showToast(t(\"practice_paused\"));\n    // Return to Practice (not the subject hub), leaving the current draft intact.\n    // The topic/tour tab selection stays owned by the Practice tabs component.\n    const resumeBtn = $(\"#practice-resume-btn\");\n    if (resumeBtn) resumeBtn.style.display = \"block\";\n    replaceCourses(\"practice-start\");\n    renderPracticeStart();"},{"label":"resume_error_ru","before":"Не удалось восстановить попытку. Черновик сохранён — попробуйте ещё раз.","after":"Не удалось восстановить попытку. Незавершённая попытка сохранена — попробуйте ещё раз."},{"label":"resume_error_uz","before":"Urinishni tiklab bo‘lmadi. Qoralama saqlandi — qayta urinib ko‘ring.","after":"Urinishni tiklab bo‘lmadi. Tugallanmagan urinish saqlanib qoldi — qayta urinib ko‘ring."},{"label":"resume_error_en","before":"Could not resume the attempt. Your draft is safe — please try again.","after":"Could not resume your attempt. Your unfinished attempt is still saved — please retry."}];
function replaceOnce(content,before,after,label) {
 const at=content.indexOf(before);
 if(at<0 || content.indexOf(before,at+before.length)>=0)
   throw Error('Practice navigation: unexpected source '+label);
 return content.slice(0,at)+after+content.slice(at+before.length);
}
for(const edit of edits)app=replaceOnce(app,edit.before,edit.after,edit.label);
const tabCopy=[
 ['Продолжить сохранённую тренировку','Продолжить попытку'],
 ['Saqlangan mashg‘ulotni davom ettirish','Urinishni davom ettirish'],
 ['Resume saved practice','Resume attempt']
];
for(const [oldCopy,newCopy] of tabCopy)
 tabs=replaceOnce(tabs,oldCopy,newCopy,'resume wording');
html=replaceOnce(html,'practice-results-tabs.js?v=stage03tabs1',
  'practice-results-tabs.js?v=stage03tabs2','tabs cache pin');
new Function(app);new Function(tabs);
fs.writeFileSync(appFile,app,'utf8');
fs.writeFileSync(tabFile,tabs,'utf8');
fs.writeFileSync(htmlFile,html,'utf8');
console.log('STAGE03_PRACTICE_NAV_OK pause_destination=practice-start resume_visible=1 busy_guard=1 ru_uz_en_attempts=1');
