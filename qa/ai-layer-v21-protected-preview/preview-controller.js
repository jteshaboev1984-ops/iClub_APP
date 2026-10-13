// The ONLY application state in this Preview is ephemeral memory.
// NO Supabase SDK, accounts, network fetch, localStorage, provider or writes.
"use strict";
window.__ICLUB_AI_V21_SYNTHETIC_ONLY__=true;
window.module={exports:{}};
const IClubSyntheticPreview=(()=>{
 const COPY={
 ru:{qaBanner:"Защищённый просмотр · учебный пример",mock:"Демонстрация",language:"Язык",miniTitle:"Твой учебный помощник",heroTitle:"Учись с ясным планом.",heroDesc:"Пройди короткую учебную практику, посмотри результат и проверь, как iClub AI объясняет ошибки только после завершения.",start:"Начать практику",onlyAfter:"Объяснение после проверки",stepOne:"Практика",stepOneDesc:"Сначала отвечай самостоятельно.",stepTwo:"Результат",stepTwoDesc:"Посмотри, какие ответы требуют внимания.",stepThree:"Объяснение",stepThreeDesc:"Выбери ошибку и попроси короткое объяснение.",demoSubjectLabel:"Учебный пример",subject:"Экономика",coursePill:"Practice · пример",practiceTitle:"Проверка понимания",practiceIntro:"Два коротких задания. Это пример интерфейса, не настоящий экзамен Cambridge.",twoQuestions:"2 вопроса",noGrade:"Без оценки и сохранения",begin:"Начать",noRealData:"Всё происходит только в этой вкладке. Реальные результаты и данные учеников не используются.",practiceInProgress:"Практика",chooseAnswer:"Выбери ответ",endDemo:"Завершить пример",nextQuestion:"Далее",finish:"Завершить",aiHidden:"Во время задания AI скрыт. Разбор станет доступен после завершения.",completed:"Практика завершена",results:"Твой результат",answeredCorrectly:"верно",resultCopy:"Теперь можно разобрать задания. AI не меняет результат, а только помогает понять объяснение.",openReview:"Разобрать ответы",again:"Повторить пример",reviewLabel:"После завершения",reviewTitle:"Разбор заданий",toResults:"К результату",selectTip:"Нажми «Объяснить» рядом с заданием. Откроется общая панель iClub AI.",videoTitle:"Видео-уроки",videoNote:"Объяснение конкретного видео пока недоступно: для него нужны подтверждённые материалы.",profileLabel:"Профиль",profileTitle:"Личный прогресс",profileNote:"В этой демонстрации нет настоящего профиля и сохранённых результатов.",navHome:"Главная",navCourses:"Обучение",navProfile:"Профиль",correct:"Верно",incorrect:"Нужно повторить",explain:"Объяснить",answerExpected:"Верный ответ",answerChosen:"Твой ответ",selectOption:"Выбери вариант ответа.",previewOnly:"Этот ответ показан на искусственном примере; AI не подключён к реальным учебным источникам.",unknown:"В разработке. Этот материал ещё не утверждён.",howPractice:"Сначала реши вопросы самостоятельно. После завершения появится разбор; результат AI не меняет.",howResults:"Результат виден после завершения. Здесь используются только искусственные данные.",q1:"Если цена товара растёт, что при прочих равных происходит с величиной спроса?",q1a:["Обычно снижается","Обычно растёт","Всегда остаётся прежней"],q2:"Зачем полезно разбирать ошибку после практики?",q2a:["Чтобы случайно угадать ответ","Чтобы понять причину и следующий шаг","Чтобы изменить уже сохранённую оценку"],a1:"Обычно снижается",a2:"Чтобы понять причину и следующий шаг",ex1:"При прочих равных более высокая цена обычно означает меньшую величину спроса. Это движение вдоль кривой спроса, а не обязательный сдвиг всей кривой.",ex2:"Разбор помогает определить, какое рассуждение привело к ошибке. Затем можно повторить конкретную идею и проверить её заново."},
 uz:{qaBanner:"Himoyalangan ko‘rish · o‘quv namunasi",mock:"Namoyish",language:"Til",miniTitle:"O‘quv yordamchingiz",heroTitle:"Aniq reja bilan o‘rganing.",heroDesc:"Qisqa mashqni bajaring, natijani ko‘ring va iClub AI xatolarni faqat yakunlangandan keyin qanday tushuntirishini sinang.",start:"Mashqni boshlash",onlyAfter:"Tekshiruvdan keyingi tushuntirish",stepOne:"Mashq",stepOneDesc:"Avval mustaqil javob bering.",stepTwo:"Natija",stepTwoDesc:"Qaysi javoblarni qayta ko‘rish kerakligini biling.",stepThree:"Tushuntirish",stepThreeDesc:"Xatoni tanlang va qisqa izoh oling.",demoSubjectLabel:"O‘quv namunasi",subject:"Iqtisodiyot",coursePill:"Practice · namuna",practiceTitle:"Tushunishni tekshirish",practiceIntro:"Ikkita qisqa savol. Bu Cambridge imtihoni emas, interfeys namunasi.",twoQuestions:"2 ta savol",noGrade:"Bahosiz va saqlashsiz",begin:"Boshlash",noRealData:"Hamma jarayon shu oynada ishlaydi. Haqiqiy o‘quvchi ma’lumotlari ishlatilmaydi.",practiceInProgress:"Mashq",chooseAnswer:"Javobni tanlang",endDemo:"Namunani tugatish",nextQuestion:"Keyingisi",finish:"Yakunlash",aiHidden:"Vazifa davomida AI yashiriladi. Tahlil yakunlangandan so‘ng ochiladi.",completed:"Mashq yakunlandi",results:"Natijangiz",answeredCorrectly:"to‘g‘ri",resultCopy:"Endi javoblarni tahlil qilishingiz mumkin. AI natijani o‘zgartirmaydi, faqat tushunishga yordam beradi.",openReview:"Javoblarni tahlil qilish",again:"Qayta boshlash",reviewLabel:"Yakunlangandan keyin",reviewTitle:"Savollar tahlili",toResults:"Natijaga",selectTip:"Savol yonidagi «Tushuntirish» tugmasini bosing. Umumiy iClub AI paneli ochiladi.",videoTitle:"Video darslar",videoNote:"Aniq video mazmuni bo‘yicha izoh hozircha mavjud emas: tasdiqlangan materiallar zarur.",profileLabel:"Profil",profileTitle:"Shaxsiy natijalar",profileNote:"Ushbu namunada haqiqiy profil yoki saqlangan natijalar yo‘q.",navHome:"Bosh sahifa",navCourses:"O‘qish",navProfile:"Profil",correct:"To‘g‘ri",incorrect:"Takrorlash kerak",explain:"Tushuntirish",answerExpected:"To‘g‘ri javob",answerChosen:"Javobingiz",selectOption:"Javob variantini tanlang.",previewOnly:"Bu sun’iy o‘quv namunasi. AI haqiqiy o‘quv manbalariga ulanmagan.",unknown:"Tayyorlanmoqda. Ushbu material hali tasdiqlanmagan.",howPractice:"Avval savollarni mustaqil bajaring. Yakunlangandan keyin tahlil chiqadi; AI natijani o‘zgartirmaydi.",howResults:"Natija yakunda ko‘rsatiladi. Bu yerda faqat sun’iy ma’lumotlar bor.",q1:"Tovar narxi oshsa, boshqa sharoitlar o‘zgarmaganda talab miqdori qanday o‘zgaradi?",q1a:["Odatda kamayadi","Odatda ko‘payadi","Doim o‘zgarmaydi"],q2:"Mashqdan keyin xatoni tahlil qilish nega foydali?",q2a:["Javobni tasodifan topish uchun","Sababini va keyingi qadamni tushunish uchun","Saqlangan bahoni o‘zgartirish uchun"],a1:"Odatda kamayadi",a2:"Sababini va keyingi qadamni tushunish uchun",ex1:"Boshqa sharoitlar o‘zgarmasa, narxning oshishi odatda talab miqdorini kamaytiradi. Bu talab egri chizig‘i bo‘ylab harakatlanishdir.",ex2:"Tahlil xato fikrlashning sababini topishga yordam beradi. Keyin tegishli mavzuni takrorlab, qayta tekshirish mumkin."},
 en:{qaBanner:"Protected Preview · Learning example",mock:"Demonstration",language:"Language",miniTitle:"Your learning companion",heroTitle:"Learn with a clear plan.",heroDesc:"Try a short practice, review the result, and see how iClub AI explains mistakes only after you finish.",start:"Start practice",onlyAfter:"Explanation after assessment",stepOne:"Practice",stepOneDesc:"Answer independently first.",stepTwo:"Result",stepTwoDesc:"See which answers need attention.",stepThree:"Explanation",stepThreeDesc:"Choose a mistake for a short explanation.",demoSubjectLabel:"Learning example",subject:"Economics",coursePill:"Practice · example",practiceTitle:"Check your understanding",practiceIntro:"Two short tasks. This is an interface example, not a Cambridge exam.",twoQuestions:"2 questions",noGrade:"No grading or saved progress",begin:"Start",noRealData:"Everything stays in this browser tab. No real student records are used.",practiceInProgress:"Practice",chooseAnswer:"Choose an answer",endDemo:"Exit example",nextQuestion:"Next",finish:"Finish",aiHidden:"AI is hidden during the task. Review is available after completion.",completed:"Practice completed",results:"Your result",answeredCorrectly:"correct",resultCopy:"You can now review the questions. AI only explains; it does not alter your result.",openReview:"Review answers",again:"Restart example",reviewLabel:"After completion",reviewTitle:"Question review",toResults:"Back to result",selectTip:"Choose “Explain” next to a question to open the shared iClub AI panel.",videoTitle:"Video lessons",videoNote:"AI cannot explain a particular video without approved source material.",profileLabel:"Profile",profileTitle:"Your progress",profileNote:"This example contains no real profile or saved results.",navHome:"Home",navCourses:"Learning",navProfile:"Profile",correct:"Correct",incorrect:"Review needed",explain:"Explain",answerExpected:"Correct answer",answerChosen:"Your answer",selectOption:"Choose an answer option.",previewOnly:"This is a synthetic example. AI is not connected to actual academic sources.",unknown:"In development. This material has not been approved yet.",howPractice:"First answer independently. After completion you can review the questions; AI never changes the result.",howResults:"The result appears after completion. Only synthetic data is used.",q1:"If a product's price rises, what usually happens to quantity demanded, all else equal?",q1a:["It usually decreases","It usually increases","It must stay the same"],q2:"Why is it useful to review an error after practice?",q2a:["To guess a result randomly","To understand the cause and next step","To change an already saved grade"],a1:"It usually decreases",a2:"To understand the cause and next step",ex1:"All else equal, a higher price usually reduces quantity demanded. This is a movement along the demand curve, not necessarily a shift of the entire curve.",ex2:"Review helps identify the reasoning that caused a mistake. You can then revisit the specific idea and check your understanding again."}
 };
 let language="ru",view="home",screen="subject-hub",quizIndex=0,answers=[null,null];
 let initialized=false,finishReady=false,bridge=null,binder=null,client=null,toastHandle=null,authCb=null;
 const HANDLE="11111111-1111-4111-8111-111111111111",SYNTHETIC_JWT="demo.temporary.client",SYNTHETIC_SESSION=101,SYNTHETIC_ATTEMPT=567;
 const questions=[{id:202,correct:0},{id:203,correct:1}];
 const rows=[{question_id:202},{question_id:203}];
 const tr=()=>COPY[language];
 const $=id=>document.getElementById(id);
 const key=i=>"q"+String(i+1);
 const text=(el,value)=>{if(el)el.textContent=value;};
 function message(k){clearTimeout(toastHandle);const el=$("toast");text(el,k);el.style.display="block";toastHandle=setTimeout(()=>el.style.display="none",2600);}
 function translate(){
  document.documentElement.lang=language;
  document.querySelectorAll("[data-i18n]").forEach(el=>text(el,tr()[el.dataset.i18n]||""));
  $("language").value=language;
  if(screen==="practice-quiz")renderQuestion();
  if(screen==="practice-result")renderResult();
  if(screen==="practice-review")renderReview(false);
  window.iClubGlobalAiShell?.close();
  void window.iClubGlobalAiShell?.refresh();
 }
 function activeView(next){
  if(next!==view){
   void binder?.leave();
   if(view==="courses"){bridge?.clear();finishReady=false;screen="subject-hub";}
  }
  view=next;
  document.querySelectorAll(".view[data-view]").forEach(el=>el.classList.toggle("is-active",el.dataset.view===next));
  document.querySelectorAll("[data-view-target]").forEach(el=>el.classList.toggle("is-selected",el.dataset.viewTarget===next));
  if(next==="courses")screenChange(screen);
  window.iClubGlobalAiShell?.close();
 }
 function screenChange(next){
  if(next==="practice-quiz"||next==="subject-hub"||next==="video")finishReady=false;
  if(next!=="practice-review")void binder?.leave();
  bridge?.screenChanged(next);
  screen=next;
  document.querySelectorAll("#view-courses .stack-screen").forEach(el=>el.classList.toggle("is-active",el.id==="courses-"+next));
  window.iClubGlobalAiShell?.close();
  if(next==="practice-quiz")renderQuestion();
  if(next==="practice-result")renderResult();
  if(next==="practice-review")renderReview(true);
 }
 const safeQuiz=()=>({mode:"practice",safeSessionId:SYNTHETIC_SESSION,_safeFinalizeComplete:true,
  drillType:null,questions:questions.map(q=>({id:q.id}))});
 async function simulatedPost({path,body,authorization}){
  if(authorization!=="Bearer "+SYNTHETIC_JWT)return{ok:false,reason:"authentication_required"};
  if(path==="/context"){
   if(body.action==="revoke")return{ok:true};
   if(body.action!=="mint"||body.sessionId!==SYNTHETIC_SESSION||
     !questions.some(q=>q.id===body.questionId)||!finishReady||
     view!=="courses"||screen!=="practice-review"||
     !bridge?.proof||$("courses-practice-quiz").classList.contains("is-active"))
     return{ok:false,reason:"screen_not_verified"};
   return{ok:true,contextHandle:HANDLE};
  }
  if(path==="/answer"){
   if(!finishReady||screen!=="practice-review"||!client?.handle||
     body.contextHandle!==HANDLE||!bridge?.proof)
     return{ok:false,reason:"context_changed"};
   if(body.intent==="status")return{ok:true,state:"available"};
   if(body.intent!=="answer"||!body.promptKey||body.promptKey!=="topic_main")
    return{ok:false,reason:"in_development"};
   const selected=document.querySelector('#courses-practice-review [data-iclub-ai-v21-selected="true"]');
   const questionId=Number(selected?.getAttribute("data-iclub-ai-v21-question-id"));
   const result=questionId===202?tr().ex1:questionId===203?tr().ex2:null;
   return result?{ok:true,reply:result+"\n\n"+tr().previewOnly}:
    {ok:false,reason:"screen_not_verified"};
  }
  return{ok:false,reason:"unavailable"};
 }
 async function mockGlobalAi(name,body){
  if(name!=="global-ai")return{data:{ok:false,reason:"unavailable",academic_state_changed:false}};
  if(view==="courses"&&screen==="practice-review"){
   if(!binder||!finishReady)return{data:{ok:false,reason:"in_development",academic_state_changed:false}};
   const check=await binder.sync();
   if(!check.ok)return{data:{ok:false,reason:"in_development",academic_state_changed:false}};
   const answer=body?.prompt_key==="topic_main"?
    await binder.askPrepared("topic_main",language):
    {ok:false,reason:"in_development"};
   return{data:{ok:answer.ok===true,reason:answer.reason||"",message:answer.reply||"",
     academic_state_changed:false}};
  }
  if(view==="courses"&&screen==="practice-quiz")
   return{data:{ok:false,reason:"active_assessment",academic_state_changed:false}};
  if(view==="home"||view==="profile"||view==="courses"){
   const prompt=body?.prompt_key||"";
   const msg=prompt==="app_practice"?tr().howPractice:
    prompt==="app_results"?tr().howResults:
    prompt==="app_here"?tr().howPractice:tr().unknown;
   return{data:{ok:true,message:msg,academic_state_changed:false}};
  }
  return{data:{ok:false,reason:"in_development",academic_state_changed:false}};
 }
 window.i18n={getLang:()=>language};
 window.sb={auth:{onAuthStateChange:cb=>{authCb=cb;return{data:{subscription:{unsubscribe(){}}}}}},
  rpc:async name=>name==="get_iclub_ai_ui_bootstrap_v1"?
    {data:{visible:true,locale:language,usage_exhausted:false,assessment_blocked:false},error:null}:
    {data:null,error:{message:"synthetic_unsupported"}},functions:{invoke:async(name,request)=>
      mockGlobalAi(name,request?.body||{})}};
 function renderQuestion(){
  const i=quizIndex,q=questions[i];
  text($("quiz-index"),(i+1)+" / "+questions.length);
  $("progress-fill").style.width=((i+1)/questions.length*100)+"%";
  text($("question-title"),tr()[key(i)]);
  const wrap=$("answer-options");wrap.replaceChildren();
  tr()[key(i)+"a"].forEach((str,choice)=>{
   const label=document.createElement("label");label.className="answer-option";
   const input=document.createElement("input");input.type="radio";input.name="choice";
   input.value=String(choice);input.checked=answers[i]===choice;
   const span=document.createElement("span");text(span,str);
   label.append(input,span);wrap.appendChild(label);
  });
  text($("submit-answer"),quizIndex===questions.length-1?tr().finish:tr().nextQuestion);
 }
 function renderResult(){
  const score=answers.filter((ans,i)=>ans===questions[i].correct).length;
  text($("score-count"),score+" / "+questions.length);
 }
 function renderReview(shouldVerify){
  const wrap=$("review-questions");wrap.replaceChildren();
  questions.forEach((q,i)=>{
   const card=document.createElement("article");card.className="review-item";
   card.setAttribute("data-practice-ai-question-id",String(q.id));
   const main=document.createElement("div");
   const status=document.createElement("span");status.className="result-status"+
     (answers[i]===q.correct?" correct":"");text(status,answers[i]===q.correct?tr().correct:tr().incorrect);
   const title=document.createElement("h3");text(title,(i+1)+". "+tr()[key(i)]);
   const userAnswer=document.createElement("p");text(userAnswer,tr().answerChosen+": "+
     (answers[i]===null?"—":tr()[key(i)+"a"][answers[i]]));
   const right=document.createElement("p");text(right,tr().answerExpected+": "+
     tr()[key(i)+"a"][q.correct]);
   main.append(status,title,userAnswer,right);
   const button=document.createElement("button");button.type="button";button.className="ghost";
   text(button,tr().explain);button.addEventListener("click",async()=>{
    if(!bridge?.proof||!bridge.selectQuestion(q.id).ok){message(tr().unknown);return;}
    const result=await binder.sync();
    if(result.ok!==true){message(tr().unknown);return;}
    const mark=$("iclub-global-ai-mark");if(mark?.hidden){message(tr().unknown);return;}
    window.iClubGlobalAiShell?.close();mark?.click();
   });
   card.append(main,button);wrap.appendChild(card);
  });
  if(shouldVerify&&bridge?.proof) {
   const rv=bridge.reviewRendered({attemptId:SYNTHETIC_ATTEMPT,reviewRows:rows,screen:$("courses-practice-review")});
   finishReady=rv.ok===true;
  }
 }
 async function finish(){
  $("submit-answer").disabled=true;
  // Fake server finalization/review, synchronous in-memory fixture only.
  const finalized=bridge.finalized({quiz:safeQuiz(),finalResult:{attempt_id:SYNTHETIC_ATTEMPT},
   reviewRows:rows});
  finishReady=finalized.ok===true;
  screenChange("practice-result");
  $("submit-answer").disabled=false;
 }
 function start(){
  bridge.clear();void binder.leave();
  answers=[null,null];quizIndex=0;finishReady=false;
  activeView("courses");screenChange("practice-quiz");
 }
 function setup(){
  if(initialized)return;initialized=true;
  const C=window.module?.exports?.QaV21ScreenClient;
  delete window.module;
  if(typeof C!=="function"||typeof window.iClubQaV21ScreenBinder!=="function"||
   typeof window.iClubQaV21EvidencePublisher!=="function"||
   !window.__iclubQaV21Bridge){
   throw Error("Synthetic Preview components not loaded");
  }
  bridge=window.__iclubQaV21Bridge;
  client=new C({post:simulatedPost,readJwt:async()=>SYNTHETIC_JWT,
   newRequestId:()=>crypto.randomUUID()});
  binder=new window.iClubQaV21ScreenBinder({client,document});
  window.__iclubPreviewInspect=()=>({view,screen,language,finishReady,
   ready:binder.ready,handle:client.handle,stored:false,realNetwork:false});
  document.querySelectorAll("[data-view-target]").forEach(el=>el.addEventListener("click",()=>{
   const target=el.dataset.viewTarget;activeView(target);
   if(target==="courses"&&!finishReady)screenChange("subject-hub");
  }));
  $("language").addEventListener("change",e=>{language=e.target.value;translate();});
  $("home-start").addEventListener("click",start);
  $("course-start").addEventListener("click",start);
  $("restart-demo").addEventListener("click",start);
  $("exit-quiz").addEventListener("click",()=>{bridge.clear();void binder.leave();screenChange("subject-hub");});
  $("submit-answer").addEventListener("click",async()=>{
   const checked=document.querySelector('input[name="choice"]:checked');
   if(!checked){message(tr().selectOption);return;}
   answers[quizIndex]=Number(checked.value);
   if(quizIndex<questions.length-1){quizIndex+=1;renderQuestion();return;}
   await finish();
  });
  $("open-review").addEventListener("click",()=>screenChange("practice-review"));
  $("back-to-results").addEventListener("click",()=>screenChange("practice-result"));
  translate();
 }
 document.addEventListener("DOMContentLoaded",setup,{once:true});
 return Object.freeze({version:"v21-static-synthetic-preview"});
})();
