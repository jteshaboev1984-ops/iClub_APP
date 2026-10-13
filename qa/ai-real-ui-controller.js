// Existing original iClub DOM & CSS, intentionally WITHOUT original app.js.
// Pure in-memory QA, no production Supabase, Auth, browser storage or paid AI.
"use strict";
(()=>{
 const $=id=>document.getElementById(id),one=s=>document.querySelector(s);
 const loc={
 ru:{safe:"Настоящие экраны iClub · учебные данные · без доступа к базе",protect:"Проверить защиту AI",unprotect:"Закрыть проверку",subject:"Экономика",home:"Главная",study:"Обучение",profile:"Профиль",practice:"Практика",start:"Начать практику",next:"Следующий вопрос",finish:"Завершить",result:"Результат практики",review:"Разбор ошибок",explain:"Объяснить",explainMistake:"Объяснить ошибку",explainSolution:"Объяснить решение",askAi:"Спросить AI",explainPromptWrong:"Объясни мою ошибку в задании №{n}.",explainPromptCorrect:"Объясни решение задания №{n}.",note:"Тестовый пример. Ответы не сохраняются и не влияют на прогресс.",notReady:"В разработке. Для этого раздела пока нет утверждённых объяснений.",q1:"Что происходит с величиной спроса при росте цены товара, при прочих равных?",q2:"Зачем разбирать ошибки после практики?",a1:["Обычно снижается","Обычно растёт","Остаётся неизменной"],a2:["Чтобы угадать ответ","Чтобы понять причину ошибки","Чтобы изменить оценку"],exp1:"При прочих равных рост цены обычно уменьшает величину спроса. Это движение вдоль кривой спроса.",exp2:"Разбор ошибки показывает, какое рассуждение было неверным и какую тему следует повторить.",help:"Сначала выполняй задания самостоятельно. После завершения открой результат и разбор ошибок."},
 uz:{safe:"Haqiqiy iClub ekranlari · sun’iy ma’lumot · bazaga kirish yo‘q",protect:"AI himoyasini tekshirish",unprotect:"Tekshiruvni tugatish",subject:"Iqtisodiyot",home:"Bosh sahifa",study:"O‘qish",profile:"Profil",practice:"Mashq",start:"Mashqni boshlash",next:"Keyingi savol",finish:"Yakunlash",result:"Mashq natijasi",review:"Xatolar tahlili",explain:"Tushuntirish",explainMistake:"Xatoni tushuntir",explainSolution:"Yechimni tushuntir",askAi:"AIdan so‘rash",explainPromptWrong:"{n}-savoldagi xatomni tushuntirib ber.",explainPromptCorrect:"{n}-savolning to‘g‘ri yechimini tushuntir.",note:"Sinov namunasi. Javoblar saqlanmaydi va natijalarga ta’sir qilmaydi.",notReady:"Tayyorlanmoqda. Ushbu bo‘lim uchun tasdiqlangan izohlar mavjud emas.",q1:"Narx oshganda, boshqa sharoitlar o‘zgarmasa, talab miqdori qanday o‘zgaradi?",q2:"Mashqdan so‘ng xatoni tahlil qilish nega foydali?",a1:["Odatda kamayadi","Odatda oshadi","O‘zgarmaydi"],a2:["Javobni taxmin qilish uchun","Sababini tushunish uchun","Bahoni o‘zgartirish uchun"],exp1:"Boshqa sharoitlar o‘zgarmasa, narx oshishi odatda talab miqdorini kamaytiradi. Bu talab chizig‘i bo‘ylab harakatdir.",exp2:"Xatoni tahlil qilish noto‘g‘ri fikrlash sababini aniqlash va mavzuni takrorlashga yordam beradi.",help:"Avval savollarga mustaqil javob bering. Tugatgach natija va xatolarni ko‘ring."},
 en:{safe:"Real iClub screens · synthetic data · no database connection",protect:"Check AI protection",unprotect:"End protection test",subject:"Economics",home:"Home",study:"Study",profile:"Profile",practice:"Practice",start:"Start practice",next:"Next question",finish:"Finish",result:"Practice result",review:"Mistake review",explain:"Explain",explainMistake:"Explain mistake",explainSolution:"Explain solution",askAi:"Ask AI",explainPromptWrong:"Explain my mistake in question {n}.",explainPromptCorrect:"Explain the solution to question {n}.",note:"Synthetic example. Answers are not saved or included in progress.",notReady:"In development. No approved explanation is available for this section.",q1:"What usually happens to quantity demanded when price rises, all else equal?",q2:"Why review a mistake after practice?",a1:["It falls","It rises","It remains unchanged"],a2:["To guess answers","To understand the cause","To change a grade"],exp1:"All else equal, a price increase usually reduces quantity demanded. This is a movement along the demand curve.",exp2:"Reviewing an error helps identify faulty reasoning and the topic that needs further practice.",help:"Answer independently first. After finishing, check the result and review your mistakes."}
 };
 // Synthetic answer-specific copy: correct, wrong option 1, wrong option 2.
 // Real source-backed explanations remain blocked until server publication.
 const explanation={
  ru:[
   ["Верно: рост цены обычно уменьшает величину спроса, при прочих равных. Это движение вдоль кривой спроса.",
    "Ты выбрал «обычно растёт», но рост цены обычно уменьшает величину спроса при прочих равных. Покупателям становится менее выгодно приобретать товар по новой цене.",
    "Ты выбрал «остаётся неизменной», но при прочих равных рост цены обычно сокращает величину спроса. Не путай величину спроса и сам спрос."],
   ["Ты выбрал «чтобы угадать ответ». Разбор нужен не для угадывания, а чтобы выяснить причину ошибки и повторить конкретную тему.",
    "Верно: разбор ошибки помогает понять неверный шаг рассуждения и выбрать, что повторить перед новой проверкой.",
    "Ты выбрал «чтобы изменить оценку», но разбор не меняет оценку. Он помогает понять ошибку и подготовиться к повторной проверке."]
  ],
  uz:[
   ["To‘g‘ri: boshqa sharoitlar o‘zgarmasa, narx oshishi odatda talab miqdorini kamaytiradi. Bu talab chizig‘i bo‘ylab harakatdir.",
    "Siz «odatda oshadi» deb javob berdingiz. Ammo boshqa sharoitlar o‘zgarmasa, narx oshishi odatda talab miqdorini kamaytiradi.",
    "Siz «o‘zgarmaydi» deb javob berdingiz. Boshqa sharoitlar o‘zgarmasa, narx oshishi odatda talab miqdorini kamaytiradi."],
   ["Siz «javobni taxmin qilish uchun» deb tanladingiz. Tahlil taxmin qilish emas, xato sababini aniqlash uchun kerak.",
    "To‘g‘ri: xatoni tahlil qilish noto‘g‘ri fikrlash sababini aniqlash va mavzuni takrorlashga yordam beradi.",
    "Siz «bahoni o‘zgartirish uchun» deb tanladingiz. Tahlil bahoni o‘zgartirmaydi; u sababini tushunishga yordam beradi."]
  ],
  en:[
   ["Correct: a price increase usually reduces quantity demanded, all else equal. This is a movement along the demand curve.",
    "You chose «it rises», but a price increase usually reduces quantity demanded, all else equal. Buyers tend to purchase less at a higher price.",
    "You chose «it remains unchanged», but a price increase usually reduces quantity demanded, all else equal. Distinguish quantity demanded from demand."],
   ["You chose «to guess answers». Review is for understanding the cause of an error, not improving guesses.",
    "Correct: reviewing mistakes helps locate faulty reasoning and choose what to practise before the next assessment.",
    "You chose «to change a grade», but reviewing cannot change the submitted result. It supports understanding and future improvement."]
  ]
 };
 const items=[{id:202,correct:0},{id:203,correct:1}],HANDLE="11111111-1111-4111-8111-111111111111";
 let language="ru",tab="home",screen="all-subjects",subject="economics",step=0,
  chosen=[null,null],finished=false,locked=false,binder=null,bridge=null,client=null;
 const t=()=>loc[language],q=i=>"q"+String(i+1),a=i=>"a"+String(i+1);
 window.i18n={getLang:()=>language};
 async function localTransport({path,body,authorization}){
  if(authorization!=="Bearer synthetic.preview.account.jwt")return{ok:false,reason:"authentication_required"};
  if(path==="/context"){
   if(body.action==="revoke")return{ok:true};
   if(!finished||locked||tab!=="courses"||screen!=="practice-review"||
      body.action!=="mint"||body.sessionId!==101||
      !items.some(x=>x.id===body.questionId)||!bridge?.proof)
     return{ok:false,reason:"screen_not_verified"};
   return{ok:true,contextHandle:HANDLE};
  }
  if(path==="/answer"){
   if(!finished||locked||screen!=="practice-review"||!client?.handle||
      body.contextHandle!==HANDLE||!bridge?.proof)return{ok:false,reason:"context_changed"};
   if(body.intent==="status")return{ok:true,state:"available"};
   if(body.intent!=="answer"||body.promptKey!=="topic_main")
    return{ok:false,reason:"in_development"};
   const question=Number(one('#courses-practice-review [data-iclub-ai-v21-selected="true"]')?.getAttribute("data-iclub-ai-v21-question-id"));
   const idx=items.findIndex(x=>x.id===question);
   const answer=idx>=0?chosen[idx]:null;
   const text=idx>=0&&Number.isInteger(answer)?explanation[language][idx]?.[answer]:null;
   return text?{ok:true,reply:text}:{ok:false,reason:"screen_not_verified"};
  }
  return{ok:false,reason:"unavailable"};
 }
 window.sb={
  auth:{onAuthStateChange:()=>({data:{subscription:{unsubscribe(){}}}})},
  rpc:async name=>name==="get_iclub_ai_ui_bootstrap_v1"?
   {data:{visible:true,locale:language,assessment_blocked:locked,usage_exhausted:false},error:null}:
   {data:null,error:{message:"not_available"}},
  functions:{invoke:async(name,request)=>{
   if(name!=="global-ai")return{data:null,error:{message:"not_available"}};
   if(locked||screen==="practice-quiz")
    return{data:{ok:false,reason:"active_assessment",academic_state_changed:false}};
   if(tab==="courses"&&screen==="practice-review"){
    const status=await binder.sync();
    const reply=status?.ok===true&&request?.body?.prompt_key==="topic_main"?
     await binder.askPrepared("topic_main",language):
     {ok:false,reason:"in_development"};
    return{data:{ok:reply?.ok===true,message:reply?.reply||"",
      reason:reply?.reason||"",academic_state_changed:false}};
   }
   const prompt=String(request?.body?.prompt_key||"");
   return{data:{ok:true,message:/app_help_(here|practice|results)/.test(prompt)?
    t().help:t().notReady,academic_state_changed:false}};
  }}
 };
 function feedback(){const node=document.createElement("div");node.className="iclub-qa-note";node.textContent=t().note;return node;}
 function activeTab(name){
  if(name!==tab){bridge?.clear();void binder?.leave();window.iClubGlobalAiShell?.previewResetPractice();finished=false;}
  tab=name;
  document.querySelectorAll(".view[data-view]").forEach(v=>v.classList.toggle("is-active",v.dataset.view===name));
  document.querySelectorAll("#tabbar [data-tab]").forEach(v=>v.classList.toggle("is-active",v.dataset.tab===name));
  $("topbar").style.display=name==="home"?"none":"flex";
  if(name==="courses")activateScreen("all-subjects");
  window.iClubGlobalAiShell?.close();
 }
 function activateScreen(name){
  if(!["practice-result","practice-review"].includes(name)){
   bridge?.clear();finished=false;
  }
  if(name!=="practice-review")void binder?.leave();
  bridge?.screenChanged(name);
  screen=name;
  document.querySelectorAll('#view-courses .stack-screen[data-stack="courses"]').forEach(el=>{
   const show=el.dataset.screen===name;
   el.classList.toggle("is-active",show);
   el.hidden=!show;el.setAttribute("aria-hidden",String(!show));
  });
  window.iClubGlobalAiShell?.close();
  if(name==="practice-quiz")renderQuiz();
  if(name==="practice-result")renderResult();
  if(name==="practice-review")renderReview();
 }
 function chooseSubject(name){
  subject=name;
  $("subject-hub-title").textContent=name==="economics"?t().subject:
   ({mathematics:"Mathematics",biology:"Biology",chemistry:"Chemistry",informatics:"Informatics"}[name]||t().subject);
  $("subject-hub-meta").textContent=t().study;
  activateScreen("subject-hub");
 }
 function card(label,action){
  const button=document.createElement("button");button.className="card-btn";button.type="button";
  const heading=document.createElement("span");heading.className="card-title";heading.textContent=label;
  button.appendChild(heading);button.addEventListener("click",action);return button;
 }
 function homeAndSubjects(){
  for(const id of ["home-competitive-list","home-study-list"]){
   const node=$(id);node.replaceChildren(card(t().subject,()=>{activeTab("courses");chooseSubject("economics");}));
  }
  const subjects=$("subjects-grid");subjects.replaceChildren();
  [["economics",t().subject],["mathematics","Mathematics"],["biology","Biology"],
   ["chemistry","Chemistry"],["informatics","Informatics"]].forEach(([k,label])=>
   subjects.appendChild(card(label,()=>chooseSubject(k))));
 }
 function renderQuiz(){
  $("practice-qno").textContent=(step+1)+"/2";
  $("practice-timer").textContent="00:00";
  $("practice-question").textContent=t()[q(step)];
  const box=$("practice-options");box.replaceChildren();
  t()[a(step)].forEach((str,i)=>{
   const btn=document.createElement("button");btn.type="button";btn.className="iclub-qa-choice";
   btn.textContent=str;btn.setAttribute("aria-pressed",String(chosen[step]===i));
   btn.addEventListener("click",()=>{
    chosen[step]=i;
    box.querySelectorAll("button").forEach((v,j)=>v.setAttribute("aria-pressed",String(i===j)));
    $("practice-submit-btn").disabled=false;
   });box.appendChild(btn);
  });
  $("practice-submit-btn").disabled=chosen[step]===null;
  $("practice-submit-btn").textContent=step===1?t().finish:t().next;
  if(!$("qa-quiz-note")){const n=feedback();n.id="qa-quiz-note";$("courses-practice-quiz").append(n);}
 }
 function start(){
  if(subject!=="economics"){showNotice(t().notReady);return;}
  bridge.clear();void binder.leave();window.iClubGlobalAiShell?.previewResetPractice();step=0;chosen=[null,null];finished=false;activateScreen("practice-quiz");
 }
 function sendAnswer(){
  if(chosen[step]===null)return;
  if(step===0){step=1;renderQuiz();return;}
  const quiz={mode:"practice",safeSessionId:101,_safeFinalizeComplete:true,
   drillType:null,questions:items.map(x=>({id:x.id}))};
  finished=bridge.finalized({quiz,finalResult:{attempt_id:567},
   reviewRows:items.map(x=>({question_id:x.id}))}).ok===true;
  activateScreen("practice-result");
 }
 function renderResult(){
  const score=chosen.filter((v,i)=>v===items[i].correct).length;
  $("practice-result-meta").textContent=t().result+" · "+score+"/2 · "+t().note;
  $("practice-review-count").textContent=String(2-score);
 }
 function renderReview(){
  const list=$("practice-review-list");list.replaceChildren();
  items.forEach((item,i)=>{
   const box=document.createElement("div");box.className="iclub-qa-review";
   box.setAttribute("data-practice-ai-question-id",String(item.id));
   box.setAttribute("data-qa-question-number",String(i+1));
   const title=document.createElement("div");title.className="card-title";
   title.textContent=(i+1)+". "+t()[q(i)];
   const body=document.createElement("p");body.className="muted small";
   body.textContent=t()[a(i)][chosen[i]]+" · "+t().note;
   const actions=document.createElement("div");actions.className="iclub-qa-review-actions";
   const icon=()=>{const img=document.createElement("img");img.className="ep-ai-mark ep-ai-mark-inline";
    img.src="assets/iclub-ai-mark-temp.jpg?v=1";img.alt="";img.setAttribute("aria-hidden","true");return img;};
   const prompt=template=>template.replace("{n}",String(i+1));
   const explain=document.createElement("button");explain.className="btn primary";
   explain.type="button";explain.dataset.qaAiAction="explain";
   explain.append(icon(),document.createTextNode(chosen[i]===item.correct?t().explainSolution:t().explainMistake));
   const ask=document.createElement("button");ask.className="btn ghost";
   ask.type="button";ask.dataset.qaAiAction="chat";
   ask.append(icon(),document.createTextNode(t().askAi));
   let handling=false;
   async function admitAndOpen(mode){
    if(handling||!finished||locked||screen!=="practice-review"||
       !$("courses-practice-review").classList.contains("is-active"))return;
    handling=true;explain.disabled=true;ask.disabled=true;
    try{
      if(!bridge.selectQuestion(item.id).ok)return;
      if(!window.iClubGlobalAiShell?.previewSelectQuestion(item.id))return;
      const result=await binder.sync();
      if(!result.ok||!finished||locked||screen!=="practice-review")return;
      if(mode==="explain"){
        await window.iClubGlobalAiShell?.previewExplain({
          questionId:item.id,displayText:prompt(chosen[i]===item.correct?
            t().explainPromptCorrect:t().explainPromptWrong),practiceSessionId:101
        });
      }else{
        window.iClubGlobalAiShell?.previewAskInChat({
          questionId:item.id
        });
      }
    }finally{handling=false;explain.disabled=false;ask.disabled=false;}
   }
   explain.addEventListener("click",()=>{void admitAndOpen("explain");});
   ask.addEventListener("click",()=>{void admitAndOpen("chat");});
   actions.append(explain,ask);box.append(title,body,actions);list.append(box);
  });
  const verified=bridge.reviewRendered({
   attemptId:567,reviewRows:items.map(x=>({question_id:x.id})),
   screen:$("courses-practice-review")
  });
  if(!verified.ok)finished=false;
 }
 function showNotice(message){
  const note=$("qa-safe-feedback")||document.createElement("div");
  note.id="qa-safe-feedback";note.className="iclub-qa-note";note.textContent=message;
  $("subject-hub-title").parentElement.append(note);
 }
 function toggleProtection(){
  locked=!locked;
  $("qa-protected").setAttribute("aria-pressed",String(locked));
  $("qa-protected").textContent=locked?t().unprotect:t().protect;
  if(locked){
   bridge.clear();void binder.leave();window.iClubGlobalAiShell?.previewResetPractice();finished=false;
   window.dispatchEvent(new CustomEvent("iclub:exam-prep-session",{
    detail:{session:{session_type:"diagnostic",status:"active"}}
   }));
  }else window.dispatchEvent(new Event("iclub:exam-prep-session-ended"));
  window.iClubGlobalAiShell?.close();
  void window.iClubGlobalAiShell?.refresh();
 }
 function relabel(){
  document.documentElement.lang=language;
  $("qa-banner-copy").textContent=t().safe;
  $("qa-protected").textContent=locked?t().unprotect:t().protect;
  $("practice-restart-label").textContent=t().start;
  const texts={home:t().home,courses:t().study,profile:t().profile};
  Object.entries(texts).forEach(([key,str])=>{
   const el=one('#tabbar [data-tab="'+key+'"] .tab-txt');
   if(el)el.textContent=str;
  });
  homeAndSubjects();
  if(screen==="practice-quiz")renderQuiz();
  if(screen==="practice-result")renderResult();
  if(screen==="practice-review")renderReview();
  window.iClubGlobalAiShell?.close();
  void window.iClubGlobalAiShell?.refresh();
 }
 function init(){
  if(!window.iClubQaV21ScreenClient||!window.iClubQaV21ScreenBinder||
   !window.iClubQaV21EvidencePublisher||!window.__iclubQaV21Bridge)
   throw Error("QA browser adapters missing");
  bridge=window.__iclubQaV21Bridge;
  client=new window.iClubQaV21ScreenClient({post:localTransport,
   readJwt:async()=> "synthetic.preview.account.jwt",
   newRequestId:()=>crypto.randomUUID()});
  binder=new window.iClubQaV21ScreenBinder({client,document});
  document.querySelectorAll("#tabbar [data-tab]").forEach(btn=>btn.addEventListener("click",()=>{
   const name=btn.dataset.tab;activeTab(["home","courses","profile"].includes(name)?name:"home");
  }));
  $("qa-lang").addEventListener("change",e=>{
   language=loc[e.target.value]?e.target.value:"ru";relabel();
  });
  $("qa-protected").addEventListener("click",toggleProtection);
  document.addEventListener("click",e=>{
   const action=e.target.closest("[data-action]")?.dataset.action;
   if(!action)return;
   const nav={
    "open-practice":()=>activateScreen("practice-start"),
    "practice-start":start,"practice-again":start,
    "practice-submit":sendAnswer,
    "practice-review":()=>activateScreen("practice-review"),
    "practice-back-to-result":()=>activateScreen("practice-result"),
    "practice-exit":()=>activateScreen("subject-hub"),
    "open-all-subjects":()=>activateScreen("all-subjects"),
    "practice-pause":()=>activateScreen("practice-start")
   };
   if(nav[action]){e.preventDefault();nav[action]();}
  });
  document.addEventListener("submit",e=>e.preventDefault(),true);
  document.addEventListener("click",e=>{
   if(e.target.closest("a[href]"))e.preventDefault();
  },true);
  const n=feedback();n.id="qa-start-note";$("courses-practice-start").append(n);
  window.__iclubQaRealUiStatus=()=>({view:tab,screen,language,finished,locked,
   binderReady:!!binder.ready,productionWrites:0,externalRequests:0});
  activeTab("home");relabel();
 }
 document.addEventListener("DOMContentLoaded",init,{once:true});
})();
