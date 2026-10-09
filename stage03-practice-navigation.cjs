'use strict';
const fs=require('node:fs'),path=require('node:path');
const appFile=path.join(__dirname,'dist','app.js'),tabsFile=path.join(__dirname,'dist','practice-results-tabs.js'),htmlFile=path.join(__dirname,'dist','index.html');
const source=fs.readFileSync(appFile,'utf8');
let tabs=fs.readFileSync(tabsFile,'utf8'),html=fs.readFileSync(htmlFile,'utf8');
const marker='function handlePracticePause() {',start=source.indexOf(marker),end=start>=0?source.indexOf('async function handlePracticeDrillSubmitSafe',start):-1;
if(start<0||end<=start||source.indexOf(marker,start+1)>=0)throw Error('Practice pause boundary drift');
let pause=source.slice(start,end);
const guard='if (!quiz || quiz.mode !== "practice") return;';
if(!pause.includes(guard)||!pause.includes('savePracticeDraft({')||!pause.includes('stripPracticeQuizSecrets(quiz)')||!pause.includes('state.quizLock = null;')||!pause.includes('state.quiz = null;'))throw Error('Practice pause save invariants changed');
if(!pause.includes('quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight')){
 const block=[
 '    if (quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight) {',
 '      showToast(tr3(',
 '        "Подождите, ответ сохраняется.",',
 '        "Kuting, javob saqlanmoqda.",',
 '        "Please wait while your answer is saved."',
 '      ));',
 '      return;',
 '    }'
 ].join('\n');
 pause=pause.replace(guard,guard+'\n'+block);
}
const previous=/replaceCourses\(\s*["']subject-hub["']\s*\)\s*;\s*renderSubjectHub\(\s*\)\s*;/g;
const routes=[...pause.matchAll(previous)];
if(routes.length!==1)throw Error('Expected one pause-to-subject route; got '+routes.length);
pause=pause.replace(previous,[
 '    // Keep paused attempt and return to the Practice screen.',
 '    const resumeBtn = $("#practice-resume-btn");',
 '    if (resumeBtn) resumeBtn.style.display = "block";',
 '    replaceCourses("practice-start");',
 '    renderPracticeStart();'
].join('\n'));
if(!pause.includes('replaceCourses("practice-start")')||!pause.includes('renderPracticeStart()')||pause.includes('replaceCourses("subject-hub")'))throw Error('Pause destination not repaired');
const app=source.slice(0,start)+pause+source.slice(end);
const copies=[
 ['Продолжить сохранённую тренировку','Продолжить попытку'],
 ['Saqlangan mashg‘ulotni davom ettirish','Urinishni davom ettirish'],
 ['Resume saved practice','Resume attempt']
];
for(const [before,after] of copies){
 if(tabs.includes(before)){if(tabs.split(before).length!==2)throw Error('Duplicate resume caption');tabs=tabs.replace(before,after);}
 else if(!tabs.includes(after))throw Error('Unknown resume caption: '+before);
}
const oldPin='practice-results-tabs.js?v=stage03tabs1';
if(html.split(oldPin).length!==2)throw Error('Practice tab pin changed');
html=html.replace(oldPin,'practice-results-tabs.js?v=stage03tabs2');
new Function(app);new Function(tabs);
fs.writeFileSync(appFile,app,'utf8');
fs.writeFileSync(tabsFile,tabs,'utf8');
fs.writeFileSync(htmlFile,html,'utf8');
console.log('STAGE03_PRACTICE_NAV_OK pause_destination=practice-start resume_visible=1 busy_guard=1 ru_uz_en_attempts=1');
