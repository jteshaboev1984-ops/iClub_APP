'use strict';
// Stage03 Practice Navigation QA — read-only on the signed candidate.
const fs=require('node:fs'),path=require('node:path');
const root=__dirname;
const app=fs.readFileSync(path.join(root,'dist','app.js'),'utf8');
const tabs=fs.readFileSync(path.join(root,'dist','practice-results-tabs.js'),'utf8');
const html=fs.readFileSync(path.join(root,'dist','index.html'),'utf8');
let assertions=0;
function ok(test,name){assertions++;if(!test)throw Error('Practice navigation failed: '+name);}
const part=(a,b)=>{
 const i=app.indexOf(a),j=app.indexOf(b,i);
 if(i<0||j<=i)throw Error('Practice nav source boundary '+a);
 return app.slice(i,j);
};
const paused=part('function handlePracticePause() {','async function handlePracticeDrillSubmitSafe');
ok(paused.includes('stopPracticeQuestionTimer()'),'pause stops question timer');
ok(paused.includes('savePracticeDraft({')&&paused.includes('status: "paused"'),'pause stores safe draft');
ok(paused.includes('stripPracticeQuizSecrets(quiz)'),'draft strips answer secrets');
ok(paused.includes('if (quiz._submitInFlight || quiz._finishing || quiz._safeFinalizeInFlight)'),'pause blocked while answer is saving');
ok(paused.indexOf('savePracticeDraft({')<paused.indexOf('state.quizLock = null'),'only unlock after saving');
ok(paused.includes('replaceCourses("practice-start")')&&!paused.includes('replaceCourses("subject-hub")'),'pause returns to Practice');
ok(paused.includes('renderPracticeStart()'),'paused Practice rerendered');
ok(paused.includes('resumeBtn.style.display = "block"'),'resume action made available immediately');
const topbar=part('backBtn.addEventListener("click", async (event) => {','// ✅ Registration:');
ok(topbar.includes('getCoursesTopScreen() === "practice-quiz"')&&topbar.includes('handlePracticePause()'),'topbar Back pauses Practice');
ok(topbar.includes('quiz?._submitInFlight || quiz?._finishing || quiz?._safeFinalizeInFlight'),'topbar blocks unfinished saves');
const action=part('if (action === "practice-resume")','if (action === "open-tours")');
for(const verb of ['practice-resume','practice-pause','practice-review','practice-recommendations','practice-exit','practice-back-to-result','practice-again'])ok(action.includes('action === "'+verb+'"'),'missing action '+verb);
ok(action.includes('if (ctx === "topic")')&&action.includes('replaceCourses("practice-start")'),'topic result exit returns Practice');
ok(action.includes('getCoursesTopScreen() !== "practice-result"'),'review back returns result');
ok(action.includes('replaceCourses("practice-quiz")')&&action.includes('renderPracticeQuiz()'),'resume displays original attempt');
const pop=part('function popCourses() {','function canCoursesBack()');
const scenarios=[
 [['practice-start'],'subject-hub'],
 [['practice-result'],'practice-start'],
 [['practice-review'],'practice-result'],
 [['practice-recs'],'practice-result'],
 [['subject-hub','practice-start','practice-result'],'practice-start'],
 [['subject-hub','practice-start','practice-result','practice-review'],'practice-result'],
 [['subject-hub','practice-start','practice-result','practice-recs'],'practice-result'],
 [['subject-hub','practice-start'],'subject-hub']
];
for(const [stack,expected] of scenarios){
 const state={quizLock:null,courses:{stack:stack.slice()}}, events=[];
 const fn=new Function('state','window','getCoursesTopScreen','replaceCourses',
   'renderPracticeStart','renderSubjectHub','saveState','showCoursesScreen','setTab',
   'renderToursStart','renderBooks','renderMyRecs','renderMyRecDetail',
   'ytPlayer','document',pop+'return popCourses;')(
    state,{iClubExamPrep:{isOpen:()=>false}},()=>state.courses.stack.at(-1),
    next=>{state.courses.stack=[next];events.push('replace:'+next);},
    ()=>events.push('render:practice'),()=>events.push('render:subject'),
    ()=>{},next=>events.push('show:'+next),()=>{},()=>{},()=>{},()=>{},()=>{},
    null,{getElementById:()=>null}
   );
 fn();
 ok(state.courses.stack.at(-1)===expected,'Back from '+stack.join('/')+' should reach '+expected);
 if(expected==='practice-start')
   ok(events.includes('render:practice'),'Back should render Practice');
}
const copies=[
 ['Продолжить попытку','Продолжить попытку'],
 ['Urinishni davom ettirish','Urinishni davom ettirish'],
 ['Resume attempt','Resume attempt']
];
for(const [caption,marker] of copies)ok(tabs.includes(marker),'missing resume text '+caption);
ok(!/сохранённую тренировку|Saqlangan mashg‘ulotni|Resume saved practice/.test(tabs),'obsolete resume labels');
ok(html.includes('practice-results-tabs.js?v=stage03tabs2'),'new translated tabs asset loaded');
ok(app.includes('Черновик сохранён') &&
   app.includes('Qoralama saqlandi') &&
   app.includes('Your draft is safe'),'failed resume preserves drafts in RU/UZ/EN');
new Function(app);new Function(tabs);
console.log('STAGE03_PRACTICE_NAV_CONTRACT_OK assertions='+assertions+
 ' back_scenarios='+scenarios.length+' user_data_writes=0');
