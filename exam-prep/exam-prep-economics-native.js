(() => {
  "use strict";
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const state = {root:null,shell:null,lang:"ru",id:null,paper:null,data:null,index:0,timer:null,busy:false,closed:true,onBack:null,token:0,view:"home",history:[],planData:null,selectedLesson:0,historyReturn:null,writtenPlan:null,writtenView:null,writtenStartEligible:false,writtenStarted:false,writtenStartBusy:false,pendingChoice:null,choiceFeedback:null};
  const dictionary={
    ru:{p2:"Paper 2 · AS Level",p4:"Paper 4 · A Level",writtenPaperInfo:"Письменная практика",writtenPaperReady:"Открыть письменный план",writtenPaperInvite:"Можно начать",writtenPaperLimited:"Пока недоступно",writtenPaperDone:"Новых заданий пока нет",writtenPaperSequence:"Задания выполняются по общему плану: сначала Paper 2, затем Paper 4. Выбор Paper 4 не пропускает предыдущие задания.",writtenPaperNoAccess:"Письменные задания пока доступны ограниченной группе учеников после входной диагностики Economics.",writtenPaperWaiting:"По вашему плану сейчас нет нового письменного задания. Уже выполненные шаги сохранены.",writtenPractice:"Письменная практика",betaTitle:"Письменные задания",betaIntro:"Задания Paper 2 и Paper 4 выполняются самостоятельно, без автоматической оценки эссе.",betaJoin:"Начать письменную практику",betaLeave:"Отключить письменную практику",betaLeaveConfirm:"Подтвердить отключение",betaLeaveWarning:"Выполненные задания сохранятся. Повторное подключение пока недоступно.",betaUnavailable:"Сейчас не удалось подключить письменную практику. Попробуйте позже.",baselineIntro:"Сначала проверьте базовые знания Cambridge Economics (AS): 12 вопросов, 20 минут. После результата выберите Paper 1 или Paper 3. Темы A Level проверяются отдельно.",selectPaper:"Выберите Paper",continuePreparation:"Продолжить подготовку",entryResult:"Входная диагностика завершена",topicOverview:"Темы для подготовки",chooseLevel:"Выберите уровень",openLevel:"Открыть",overview:"Главная",noAttempts:"Пока нет попыток",afterCheck:"Диагностика завершена — изучите слабые темы",startHere:"Начните с входной диагностики",resumeExam:"Продолжить работу",levelIntro:"Диагностика определит темы для подготовки. Полный экзамен доступен отдельно.",openLesson:"Изучить тему",viewUnits:"Результаты по разделам",nextLesson:"Следующая тема",showMore:"Показать ещё",viewHistory:"История попыток",noHistory:"Завершённые экзамены и диагностики появятся здесь",backToPlan:"К учебному плану",recommended:"Рекомендуемое действие",title:"Cambridge Economics · Exam Prep",intro:"Выберите уровень и начните с короткой диагностики. После результата откроется учебный план.",minuteShort:"мин",profile:"Настройка подготовки",editProfile:"Изменить",series:"Экзаменационная сессия",grade:"Целевая оценка",hours:"Всего часов на учёбу в неделю",econHours:"Часов на экономику в неделю",saveProfile:"Сохранить настройки",profileInvalid:"Проверьте экзаменационную сессию и количество часов: время на экономику не должно превышать общее время.",profileSaved:"Настройки сохранены",optional:"Настройте цель и время подготовки. Уже сохранённые попытки не изменятся.",startDiagnostic:"Начать диагностику",fullPaper:"Полный экзамен",entryCheck:"Входная диагностика",completedCheck:"Диагностика завершена",repeatCheck:"Повторить диагностику",history:"Мои попытки",viewResult:"Посмотреть результат",continueAttempt:"Продолжить",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Начать или продолжить",back:"Назад", beforePlan:"Учебный план появится после первого завершённого экзамена. Позже его можно открыть из истории попыток.", autoAnswer:"Выберите вариант и нажмите «Ответить». Сохранение подтверждается сервером.",saving:"Сохраняем ответ…",
      papers:"К экзаменам",question:"Вопрос",time:"Осталось времени",save:"Ответить",
      saved:"Ответ сохранён",next:"Следующий",previous:"Предыдущий",finish:"Завершить экзамен",
      confirm:"Завершить экзамен? Пропущенные вопросы получат 0 баллов.",result:"Результат",
      review:"Разбор ответов",right:"Правильный ответ",your:"Ваш ответ",empty:"Не отвечено",
      loading:"Загрузка…",error:"Не удалось выполнить действие. Проверьте соединение.",retry:"Повторить", uncertain:"Сохранение не подтверждено. Ответ остался на экране. Сначала проверьте сервер.", checkSaved:"Проверить сохранение", retrySame:"Отправить тот же ответ", selectionPending:"Ответ пока не отправлен.", finishNeedSubmit:"Сначала отправьте выбранный вариант кнопкой «Ответить».", serverDifferent:"На сервере уже сохранён другой вариант. Здесь показан сохранённый ответ. Чтобы изменить его, выберите новый вариант и нажмите «Ответить».", leavePending:"Выйти, сохранив выбор в этой вкладке",
      plan:"Мой учебный план",planIntro:"Начните с этих тем и проверьте себя после повторения.",
      unit:"Раздел",correct:"Верно",mistakes:"Тем для повторения",studied:"Изучено",verified:"Подтверждено повторной проверкой",
      study:"Объяснение темы",trap:"На что обратить внимание",check:"Проверьте себя",showCheck:"Показать ответ",
      hideCheck:"Скрыть ответ",markStudied:"Отметить как изученное",studiedDone:"Тема изучена",
      backReview:"К разбору экзамена",retest:"Пройти Paper ещё раз",day:"День",
      allCorrect:"Все вопросы решены правильно. Ошибок для разбора нет.",studyNote:"Отметка «изучено» не означает, что навык освоен. Это подтвердит правильный ответ в следующем экзамене."},
    uz:{p2:"Paper 2 · AS Level",p4:"Paper 4 · A Level",writtenPaperInfo:"Yozma mashqlar",writtenPaperReady:"Yozma rejamni ochish",writtenPaperInvite:"Boshlash mumkin",writtenPaperLimited:"Hozircha mavjud emas",writtenPaperDone:"Hozircha yangi topshiriq yo‘q",writtenPaperSequence:"Yozma topshiriqlar bitta reja bo‘yicha ketma-ket bajariladi: avval Paper 2, keyin Paper 4. Paper 4 ni tanlash oldingi topshiriqlarni o‘tkazib yubormaydi.",writtenPaperNoAccess:"Yozma topshiriqlar hozir Economics kirish diagnostikasini yakunlagan cheklangan guruh o‘quvchilariga ochiq.",writtenPaperWaiting:"Hozir rejangizda yangi yozma topshiriq yo‘q. Oldingi bajarilgan ishlar saqlangan.",writtenPractice:"Yozma mashqlar",betaTitle:"Yozma topshiriqlar",betaIntro:"Paper 2 va Paper 4 yozma topshiriqlari mustaqil bajariladi; essega avtomatik baho qo‘yilmaydi.",betaJoin:"Yozma mashqlarni boshlash",betaLeave:"Yozma mashqlarni o‘chirish",betaLeaveConfirm:"O‘chirishni tasdiqlash",betaLeaveWarning:"Bajarilgan topshiriqlar saqlanadi. Qayta ulanish hozircha mumkin emas.",betaUnavailable:"Hozir yozma mashqlarga ulanishning imkoni bo‘lmadi. Keyinroq urinib ko‘ring.",baselineIntro:"Avval Cambridge Economics (AS) bo‘yicha asosiy bilimlaringizni tekshiring: 12 savol, 20 daqiqa. Natijadan so‘ng Paper 1 yoki Paper 3 ni tanlang. A Level mavzulari alohida tekshiriladi.",selectPaper:"Paperni tanlang",continuePreparation:"Tayyorgarlikni davom ettirish",entryResult:"Kirish diagnostikasi yakunlandi",topicOverview:"O‘rganiladigan mavzular",chooseLevel:"Darajani tanlang",openLevel:"Ochish",overview:"Bosh sahifa",noAttempts:"Hozircha urinishlar yo‘q",afterCheck:"Diagnostika tugadi — qiyin mavzularni o‘rganing",startHere:"Avval kirish diagnostikasidan boshlang",resumeExam:"Ishni davom ettirish",levelIntro:"Diagnostika o‘rganiladigan mavzularni aniqlaydi. To‘liq imtihon alohida mavjud.",openLesson:"Mavzuni o‘rganish",viewUnits:"Bo‘limlar bo‘yicha natijalar",nextLesson:"Keyingi mavzu",showMore:"Ko‘proq ko‘rsatish",viewHistory:"Urinishlar tarixi",noHistory:"Yakunlangan imtihonlar va diagnostikalar shu yerda chiqadi",backToPlan:"O‘quv rejasiga",recommended:"Tavsiya etilgan qadam",title:"Cambridge Economics · Exam Prep",intro:"Darajani tanlang va qisqa diagnostikadan boshlang. Natijadan keyin o‘quv reja ochiladi.",minuteShort:"daq.",profile:"Tayyorgarlik sozlamalari",editProfile:"O‘zgartirish",series:"Imtihon sessiyasi",grade:"Maqsadli baho",hours:"Haftalik umumiy o‘qish soati",econHours:"Haftalik iqtisodiyot soati",saveProfile:"Sozlamalarni saqlash",profileInvalid:"Imtihon davri va soatlarni tekshiring: iqtisodiyot soati umumiy vaqtdan oshmasin.",profileSaved:"Sozlamalar saqlandi",optional:"Tayyorgarlik maqsadi va vaqtini belgilang. Avvalgi urinishlar o‘zgarmaydi.",startDiagnostic:"Diagnostikani boshlash",fullPaper:"To‘liq imtihon",entryCheck:"Kirish diagnostikasi",completedCheck:"Diagnostika yakunlandi",repeatCheck:"Diagnostikani takrorlash",history:"Mening urinishlarim",viewResult:"Natijani ko‘rish",continueAttempt:"Davom ettirish",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Boshlash yoki davom ettirish",back:"Orqaga", beforePlan:"O‘quv rejangiz birinchi yakunlangan imtihondan so‘ng paydo bo‘ladi. Keyin uni urinishlar tarixidan ochishingiz mumkin.", autoAnswer:"Variantni tanlang va «Javob berish» tugmasini bosing. Javob saqlangani server tomonidan tasdiqlanadi.",saving:"Javob saqlanmoqda…",
      papers:"Imtihonlarga qaytish",question:"Savol",time:"Qolgan vaqt",save:"Javob berish",
      saved:"Javob saqlandi",next:"Keyingi",previous:"Oldingi",finish:"Imtihonni yakunlash",
      confirm:"Imtihonni yakunlaysizmi? Javobsiz savollar 0 ball bo‘ladi.",result:"Natija",
      review:"Javoblarni tahlil qilish",right:"To‘g‘ri javob",your:"Sizning javobingiz",empty:"Javob berilmagan",
      loading:"Yuklanmoqda…",error:"Amal bajarilmadi. Internetni tekshiring.",retry:"Qayta urinish", uncertain:"Saqlanganini tasdiqlab bo‘lmadi. Javob ekranda qoldi. Avval server holatini tekshiring.", checkSaved:"Saqlanganini tekshirish", retrySame:"Shu javobni qayta yuborish", selectionPending:"Javob hali yuborilmadi.", finishNeedSubmit:"Avval tanlangan javobni «Javob berish» tugmasi orqali yuboring.", serverDifferent:"Serverda boshqa javob saqlangan. Hozir saqlangan javob ko‘rsatilmoqda. O‘zgartirish uchun yangi variantni tanlab, «Javob berish»ni bosing.", leavePending:"Javob tanlovini shu oynada qoldirib chiqish",
      plan:"Mening o‘quv rejam",planIntro:"Avval shu mavzularni o‘rganing, so‘ng qayta tekshiring.",
      unit:"Bo‘lim",correct:"To‘g‘ri",mistakes:"Takrorlanadigan mavzular",studied:"O‘rganildi",verified:"Qayta tekshiruvda tasdiqlangan",
      study:"Mavzu izohi",trap:"E'tibor bering",check:"O‘zingizni tekshiring",showCheck:"Javobni ko‘rsatish",
      hideCheck:"Javobni yashirish",markStudied:"O‘rganilgan deb belgilash",studiedDone:"Mavzu o‘rganildi",
      backReview:"Imtihon tahliliga",retest:"Paperni qayta ishlash",day:"Kun",
      allCorrect:"Hamma savollarga to‘g‘ri javob berildi. Tahlil qilinadigan xato yo‘q.",studyNote:"«O‘rganildi» belgisi bilim o‘zlashtirilganini isbotlamaydi. Keyingi imtihondagi to‘g‘ri javob tasdiqlaydi."},
    en:{p2:"Paper 2 · AS Level",p4:"Paper 4 · A Level",writtenPaperInfo:"Written practice",writtenPaperReady:"Open written study plan",writtenPaperInvite:"Ready to start",writtenPaperLimited:"Not yet available",writtenPaperDone:"No new task right now",writtenPaperSequence:"Written tasks follow one plan: Paper 2 first, then Paper 4. Choosing Paper 4 does not skip earlier tasks.",writtenPaperNoAccess:"Written tasks are currently available to a limited group after the Economics entry check.",writtenPaperWaiting:"No new written task is available in your plan right now. Completed steps are preserved.",writtenPractice:"Written practice",betaTitle:"Written practice",betaIntro:"Complete Paper 2 and Paper 4 writing tasks independently; essays are not automatically marked.",betaJoin:"Start written practice",betaLeave:"Turn off written practice",betaLeaveConfirm:"Confirm turning off",betaLeaveWarning:"Completed tasks will be preserved. Rejoining is not currently available.",betaUnavailable:"Written practice could not be enabled right now. Please try again later.",baselineIntro:"First check your Cambridge Economics AS foundations: 12 questions, 20 minutes. After your result, choose Paper 1 or Paper 3. Advanced A Level topics are checked separately.",selectPaper:"Choose your paper",continuePreparation:"Continue preparation",entryResult:"Entry check completed",topicOverview:"Topics to study",chooseLevel:"Choose your level",openLevel:"Open",overview:"Overview",noAttempts:"No attempts yet",afterCheck:"Entry check completed — focus on weaker topics",startHere:"Begin with the entry check",resumeExam:"Resume your work",levelIntro:"The entry check identifies study topics. The full exam is available separately.",openLesson:"Study this topic",viewUnits:"Results by unit",nextLesson:"Next topic",showMore:"Show more",viewHistory:"Attempt history",noHistory:"Completed exams and entry checks will appear here",backToPlan:"Back to study plan",recommended:"Recommended next step",title:"Cambridge Economics · Exam Prep",intro:"Select a level and begin with a short entry check. Your study plan follows the result.",minuteShort:"min",profile:"Preparation settings",editProfile:"Edit",series:"Exam series",grade:"Target grade",hours:"Total weekly study hours",econHours:"Weekly Economics hours",saveProfile:"Save settings",profileInvalid:"Check exam series and weekly hours: Economics time cannot exceed your total study time.",profileSaved:"Settings saved",optional:"Set a preparation goal and study time. Existing attempts will not change.",startDiagnostic:"Start entry check",fullPaper:"Full exam",entryCheck:"Entry check",completedCheck:"Entry check completed",repeatCheck:"Repeat entry check",history:"My attempts",viewResult:"View result",continueAttempt:"Continue",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Start or resume",back:"Back", beforePlan:"Your study plan appears after your first completed paper. You can reopen it from your attempt history.", autoAnswer:"Choose an option and select “Submit answer”. The server confirms when it is saved.",saving:"Saving answer…",
      papers:"Back to papers",question:"Question",time:"Time remaining",save:"Submit answer",
      saved:"Answer saved",next:"Next",previous:"Previous",finish:"Finish exam",
      confirm:"Finish this exam? Unanswered questions score zero.",result:"Result",
      review:"Review answers",right:"Correct answer",your:"Your answer",empty:"Unanswered",
      loading:"Loading…",error:"The action failed. Check your connection.",retry:"Try again", uncertain:"Saving has not been confirmed. Your choice remains here. Check the server first.", checkSaved:"Check saved answer", retrySame:"Resend the same answer", selectionPending:"This choice has not been submitted.", finishNeedSubmit:"Submit your selected answer before finishing the exam.", serverDifferent:"A different answer is already saved on the server. The saved choice is shown. To change it, select and submit a new answer.", leavePending:"Leave, keeping your choice in this tab",
      plan:"My study plan",planIntro:"Review these topics first, then test your understanding again.",
      unit:"Unit",correct:"Correct",mistakes:"Topics to review",studied:"Studied",verified:"Confirmed in a later test",
      study:"Topic explanation",trap:"Watch out for",check:"Check your understanding",showCheck:"Show answer",
      hideCheck:"Hide answer",markStudied:"Mark as studied",studiedDone:"Studied",
      backReview:"Back to exam review",retest:"Take this paper again",day:"Day",
      allCorrect:"You answered every question correctly. No errors to review.",studyNote:"Marking a topic as studied does not prove mastery. Only a later correct exam answer can confirm improvement."}
  };
  const t=()=>dictionary[state.lang]||dictionary.ru;
  const e=(tag,cls,value)=>{
    const item=document.createElement(tag);
    if(cls)item.className=cls;
    if(value!==undefined&&value!==null)item.textContent=String(value);
    return item;
  };
  const btn=(text,fn,secondary=false)=>{
    const b=e("button",secondary?"ep-live-btn secondary":"ep-live-btn",text);
    b.type="button";b.disabled=state.busy;b.addEventListener("click",fn);return b;
  };
  // The same shell/header/button templates used by Mathematics Exam Prep.
  const shell=()=>{
    if(state.closed||!state.root)return null;
    const root=e("section","ep-host-shell ep-live");
    const header=e("div","ep-live-head ep-native-screen-head");
    const title=e("div","ep-native-screen-title");
    title.append(e("div","ep-host-kicker","Cambridge 9708"),
      e("h2","ep-host-title",t().title));
    if(state.view!=="home"){
      const back=btn("‹",goBack,true);
      back.className+=" ep-native-screen-back";
      back.setAttribute("aria-label",t().back);
      back.setAttribute("title",t().back);
      header.append(back);
    }
    header.append(title);
    root.append(header);
    const previous=state.root.firstElementChild;
    state.root.replaceChildren(root);
    if(previous&&state.root.isConnected&&typeof state.root.scrollIntoView==="function")
      state.root.scrollIntoView({block:"start",behavior:"auto"});
    return root;
  };
  const stop=()=>{if(state.timer!==null){clearInterval(state.timer);state.timer=null;}};
  function unmount(){
    state.writtenView?.dispose?.();state.writtenView=null;state.writtenPlan=null;
    stop();state.token++;state.closed=true;state.root=null;state.shell=null;
    state.id=null;state.paper=null;state.data=null;state.profile=null;state.history=[];state.planData=null;state.view="home";state.historyReturn=null;state.busy=false;state.onBack=null;state.pendingChoice=null;state.choiceFeedback=null;
  }
  async function rpc(name,args={}){
    try {
      if(!window.sb||typeof window.sb.rpc!=="function")return {ok:false};
      const response=await window.sb.rpc(name,args);
      if(response.error||response.data?.ok!==true)return {ok:false,code:response.data?.code||"rpc_failed"};
      return response.data;
    }catch(_){return {ok:false,code:"network_error"};}
  }
  // A tab-local draft is never evidence. The owned server session is always
  // loaded first; nothing is written to legacy iClub localStorage or progress.
  function choiceKey(sessionId,order){
    return "iclub_ep_economics_choice_v1:"+sessionId+":"+(order+1);
  }
  function readChoiceDraft(sessionId,order){
    try{
      const v=JSON.parse(window.sessionStorage?.getItem(choiceKey(sessionId,order))||"null");
      return v && Number.isInteger(v.choice) && v.choice>=0 && v.choice<=3
        ? {choice:v.choice,pending:v.pending===true} : null;
    }catch(_){return null;}
  }
  function writeChoiceDraft(sessionId,order,choice,pending=false){
    try{window.sessionStorage?.setItem(choiceKey(sessionId,order),
      JSON.stringify({choice,pending}));}catch(_){}
  }
  function clearChoiceDraft(sessionId,order){
    try{window.sessionStorage?.removeItem(choiceKey(sessionId,order));}catch(_){}
  }
  function pendingChoiceFor(sessionId,order){
    const v=state.pendingChoice;
    return v?.sessionId===sessionId&&v.order===order?v:null;
  }
  async function boundedRpc(name,args,timeoutMs=15000){
    let timer;
    try {
      return await Promise.race([
        rpc(name,args),
        new Promise(resolve=>{
          timer=setTimeout(()=>resolve({ok:false,code:"unknown_response"}),timeoutMs);
        })
      ]);
    } finally { if(timer!==undefined)clearTimeout(timer); }
  }
  function error(retry){
    const view=shell();if(!view)return;
    view.append(e("p","ep-host-note",t().error));
    const actions=e("div","ep-host-actions");
    actions.append(btn(t().retry,retry),btn(t().papers,lobby,true));view.append(actions);
  }

  // Same navigation hierarchy as Mathematics: overview → paper home → focused action.
  function goBack(){
    if(state.busy||state.pendingChoice||state.closed)return;
    if(state.view==="lesson"){renderStudyPlan(state.planData);return;}
    if(state.view==="written"){state.writtenView?.dispose?.();state.writtenView=null;lobby();return;}
    if(state.view==="entry_result"){lobby();return;}
    if(state.view==="plan"||state.view==="exam"){
      if(!initialCheckStatus().complete){lobby();return;}
      openLevel(state.paper);return;
    }
    if(state.view==="history"){
      const code=state.historyReturn;
      state.historyReturn=null;
      if(code){openLevel(code);return;}
      lobby();return;
    }
    if(state.view==="level"||state.view==="settings"||state.view==="written_info"){lobby();return;}
    state.onBack?.();
  }

  function lobby(){
    state.writtenView?.dispose?.();state.writtenView=null;state.writtenPlan=null;
    state.writtenStartEligible=false;state.writtenStarted=false;state.writtenStartBusy=false;
    ++state.token;stop();state.view="home";state.id=null;state.paper=null;
    state.data=null;state.planData=null;state.index=0;state.pendingChoice=null;state.choiceFeedback=null;
    const view=shell();if(!view)return;
    view.append(e("div","ep-live-card",t().loading));
    loadDashboard(state.token);
  }
  async function loadDashboard(token){
    const [history,profile,written,beta]=await Promise.all([
      rpc("iclub_exam_native_mcq_history_v1",{p_paper_code:null}),
      rpc("iclub_exam_native_economics_profile_v1",{}),
      rpc("iclub_exam_written_available_v1",{
        p_program_key:"economics_9708",p_version_key:"economics_2026_2028_v1"
      }),
      rpc("iclub_econ_written_beta_status_v1",{})
    ]);
    if(state.closed||state.token!==token||state.view!=="home")return;
    if(!history.ok||!Array.isArray(history.sessions)){error(lobby);return;}
    state.history=history.sessions;
    if(profile.ok)state.profile=profile.profile||null;
    // Fail-closed: no released and assigned written plan => no learner UI.
    state.writtenPlan=written.ok&&written.available===true?written.plan_id:null;
    state.writtenStartEligible=beta.ok&&beta.eligible===true;
    state.writtenStarted=beta.ok&&beta.joined===true;
    renderHome();
  }
  function initialCheckStatus(){
    // AS economics fundamentals are prerequisite knowledge for A Level.
    // This baseline check does not claim to measure advanced P3 readiness.
    const records=state.history.filter(x=>x.paper_code==="P1"&&x.session_kind==="diagnostic");
    return {
      complete:records.find(x=>x.status==="finalized")||null,
      active:records.find(x=>x.status==="active")||null
    };
  }
  function renderHome(){
    if(state.closed)return;
    const view=shell();if(!view)return;
    const stage=initialCheckStatus();
    const intro=e("section","ep-live-dashboard-intro");
    const introCopy=e("div");
    introCopy.append(e("div","ep-live-dashboard-eyebrow","Cambridge Economics 9708"),
      e("h3","ep-live-dashboard-title",stage.complete?t().selectPaper:t().entryCheck),
      e("p","ep-live-dashboard-text",stage.complete?t().intro:t().baselineIntro));
    intro.append(introCopy);
    if(state.profile){
      const badge=e("div","ep-live-dashboard-profile");
      badge.append(e("strong","",t().profileSaved),
        e("span","",[
          state.profile.exam_series,
          t().grade+": "+state.profile.target_grade,
          t().econHours+": "+state.profile.economics_hours_budget
        ].join(" · ")));
      intro.append(badge);
    }
    view.append(intro);
    if(!stage.complete){
      const block=e("section","ep-component-home");
      const next=e("section","ep-component-next");
      next.append(e("div","ep-component-section-label",t().recommended));
      next.append(e("strong","ep-component-next-title",
        stage.active?t().resumeExam:t().startDiagnostic));
      const progress=stage.active?
        String(stage.active.answered||0)+" / 12":
        "12 "+t().question+" · 20 "+t().minuteShort;
      next.append(e("div","ep-live-meta",progress));
      next.append(btn(stage.active?t().continueAttempt:t().startDiagnostic,
        stage.active?()=>openHistory(stage.active,false):()=>begin("P1","diagnostic")));
      block.append(next);
      // Preparation settings are optional but accessible before the first check.
      // Opening them does not start or change any owned exam attempt.
      const setupActions=e("div","ep-live-actions");
      setupActions.append(btn(t().profile,openSettings,true));
      block.append(setupActions);
      view.append(block);
      // Existing pre-release Paper attempts remain accessible independently.
      if(state.history.length)view.append(btn(t().viewHistory,()=>openHistoryList(),true));
      return;
    }
    const grid=e("div","ep-live-grid");
    for(const code of ["P1","P2","P3","P4"]){
      if(code==="P2"||code==="P4"){
        // Discoverability is not an entitlement. Every learner sees the Paper;
        // only an owned, server-approved plan can expose its written questions.
        const slot=e("div","ep-live-component-slot");
        const card=btn("",()=>openWrittenPaperInfo(code));
        card.className="ep-live-card ep-live-component-card ep-live-component-entry ep-live-written-entry";
        card.replaceChildren();
        const head=e("div","ep-live-component-head");
        head.append(e("span","ep-live-component-code",code));
        const copy=e("div","ep-live-component-copy");
        copy.append(e("strong","",code==="P2"?t().p2:t().p4),
          e("span","",t().writtenPaperInfo));
        head.append(copy,e("span","ep-live-component-arrow","›"));
        card.append(head);
        const status=state.writtenPlan?t().writtenPaperReady:
          state.writtenStartEligible?t().writtenPaperInvite:
          state.writtenStarted?t().writtenPaperDone:t().writtenPaperLimited;
        const statusBox=e("div","ep-live-component-status");
        statusBox.append(e("div","ep-live-meta ep-written-paper-status",status));
        card.append(statusBox,e("div","ep-live-component-open",t().openLevel+" →"));
        slot.append(card);grid.append(slot);
        continue;
      }
      if(!state.shell?.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq"))continue;
      const title=code==="P1"?t().p1:t().p3;
      const recent=state.history.filter(x=>x.paper_code===code);
      const active=recent.find(x=>x.status==="active");
      const completed=recent.find(x=>x.session_kind==="diagnostic"&&x.status==="finalized");
      const latest=recent.find(x=>x.status==="finalized"&&x.session_kind==="paper");
      const slot=e("div","ep-live-component-slot");
      const card=btn("",()=>openLevel(code));
      card.className="ep-live-card ep-live-component-card ep-live-component-entry";
      card.replaceChildren();
      const head=e("div","ep-live-component-head");
      head.append(e("span","ep-live-component-code",code));
      const copy=e("div","ep-live-component-copy");
      copy.append(e("strong","",title),
        e("span","",code==="P1"?"AS Level":"A Level"));
      head.append(copy,e("span","ep-live-component-arrow","›"));
      card.append(head);
      const status=e("div","ep-live-component-status");
      const label=active?t().resumeExam+" · "+(active.answered||0)+"/"+(active.total_items||30)
        :completed?t().completedCheck+" · "+completed.score+"/12"
        :latest?t().result+" · "+latest.score+"/30":t().startHere;
      status.append(e("div","ep-live-meta",label));
      card.append(status,e("div","ep-live-component-open",t().openLevel+" →"));
      slot.append(card);grid.append(slot);
    }
    view.append(grid);
    const tools=e("div","ep-live-actions");
    tools.append(btn(t().profile,openSettings,true),
      btn(t().viewHistory,()=>openHistoryList(),true));
    if(state.writtenPlan&&window.iClubWrittenCoreViewV1)
      tools.append(btn(t().writtenPractice,openWritten,true));
    view.append(tools);
  }
  // P2/P4 are visible like P1/P3, but do not pretend that a single Paper
  // can bypass the server's ordered written study plan.
  function openWrittenPaperInfo(code){
    if(state.closed||state.busy||!initialCheckStatus().complete||
       !["P2","P4"].includes(code))return;
    ++state.token;stop();state.view="written_info";state.paper=code;
    const view=shell();if(!view)return;
    const detail=e("section","ep-component-home");
    const head=e("header","ep-component-hero");
    const title=e("div","ep-live-component-head");
    title.append(e("span","ep-live-component-code",code),
      e("strong","ep-live-component-copy",code==="P2"?t().p2:t().p4));
    head.append(title);detail.append(head);
    const description=e("section","ep-component-next");
    description.append(e("div","ep-component-section-label",t().writtenPaperInfo),
      e("p","ep-live-meta",t().writtenPaperSequence));
    const actions=e("div","ep-live-actions");
    if(state.writtenPlan&&window.iClubWrittenCoreViewV1){
      actions.append(btn(t().writtenPaperReady,openWritten));
    }else if(state.writtenStartEligible&&window.iClubWrittenCoreViewV1){
      // A single Start action grants access; no separate consent screen.
      const note=e("p","ep-host-note","");
      const join=btn(t().betaJoin,()=>startWrittenPractice(join,note));
      actions.append(join);description.append(note);
    }else{
      description.append(e("p","ep-host-note",
        state.writtenStarted?t().writtenPaperWaiting:t().writtenPaperNoAccess));
    }
    if(actions.children.length)description.append(actions);
    detail.append(description);view.append(detail);
  }
  async function startWrittenPractice(button,note){
    if(state.closed||state.writtenStartBusy||!state.writtenStartEligible||
       !["home","written_info"].includes(state.view))return;
    const viewName=state.view,requestToken=state.token;
    state.writtenStartBusy=true;button.disabled=true;
    const result=await rpc("iclub_econ_written_start_v2",{});
    if(state.closed||state.view!==viewName||state.token!==requestToken)return;
    state.writtenStartBusy=false;
    if(result.ok&&result.joined===true){lobby();return;}
    note.textContent=t().betaUnavailable;
    button.disabled=false;
  }

  function renderEntryResult(){
    if(state.closed||state.data?.status!=="finalized"||
       state.data?.session_kind!=="diagnostic"||state.paper!=="P1")return;
    state.view="entry_result";
    const view=shell();if(!view)return;
    const result=e("section","ep-live-card");
    result.append(e("h3","",t().entryResult),
      e("div","ep-live-meta",t().result+": "+state.data.score+" / 12"));
    const actions=e("div","ep-live-actions");
    // A completed entry check should lead straight to the owned study plan.
    // The existing Paper-selection route stays available as a secondary action.
    actions.append(btn(t().plan,showStudyPlan),
      btn(t().selectPaper,lobby,true));
    result.append(actions);view.append(result);
  }


  function openWritten(){
    if(state.closed||state.busy||!initialCheckStatus().complete||
       !state.writtenPlan||!window.iClubWrittenCoreViewV1)return;
    ++state.token;stop();state.view="written";
    const api={};
    for(const [key,name] of Object.entries({
      available:"iclub_exam_written_available_v1",
      next:"iclub_exam_written_next_v1",
      open:"iclub_exam_written_open_v1",
      criteria:"iclub_exam_written_criteria_v1",
      advance:"iclub_exam_written_advance_v1",
      status:"iclub_exam_written_status_v1"
    }))api[key]=async args=>{
      // Written Core v1.3 has a different validated response envelope
      // (status/task_kind/available), not the Economics MCQ 'ok:true' envelope.
      let response;
      try{response=await window.sb.rpc(name,args);}
      catch(_){throw Error("written_network_error");}
      const result=response?.data;
      if(response?.error||!result||typeof result!=="object"||result.ok===false)
        throw Error("written_service_unavailable");
      return result;
    };
    state.writtenView=window.iClubWrittenCoreViewV1.mount({
      root:state.root,planId:state.writtenPlan,language:state.lang,api,
      onBack:()=>{state.writtenView=null;lobby();}
    });
    if(!state.writtenView)lobby();
  }
  function openLevel(code,shouldRefresh=true){
    if(state.closed||state.busy||!["P1","P3"].includes(code)||
       !initialCheckStatus().complete)return;
    ++state.token;stop();state.view="level";state.paper=code;
    const view=shell();if(!view)return;
    const entries=state.history.filter(x=>x.paper_code===code);
    const active=entries.find(x=>x.status==="active");
    const completed=entries.find(x=>x.session_kind==="diagnostic"&&x.status==="finalized");
    const latestPaper=entries.find(x=>x.session_kind==="paper"&&x.status==="finalized");
    const learning=completed||(code==="P1"?initialCheckStatus().complete:null);
    const component=e("section","ep-component-home");
    const top=e("header","ep-component-hero");
    const head=e("div","ep-live-component-head");
    head.append(e("span","ep-live-component-code",code));
    const label=e("div","ep-live-component-copy");
    label.append(e("strong","",code==="P1"?t().p1:t().p3),
      e("span","",code==="P1"?"AS Level":"A Level"));
    head.append(label);top.append(head);component.append(top);
    const next=e("section","ep-component-next");
    next.append(e("div","ep-component-section-label",t().recommended),
      e("strong","ep-component-next-title",
        active?t().resumeExam:learning?t().afterCheck:latestPaper?t().viewResult:t().fullPaper));
    const detail=active?(active.session_kind==="diagnostic"?t().entryCheck:t().fullPaper)+
      " · "+active.answered+"/"+(active.total_items||30)
      :learning?t().entryCheck+" · "+learning.score+"/12":t().availablePaper;
    next.append(e("div","ep-live-meta",detail));
    const primary=active?btn(t().continueAttempt,()=>openHistory(active,false))
      :learning?btn(t().plan,()=>openHistory(learning,true))
      :latestPaper?btn(t().viewResult,()=>openHistory(latestPaper,false))
      :btn(t().fullPaper,()=>begin(code,"paper"));
    primary.classList?.add("ep-component-primary");
    next.append(primary);component.append(next);
    const links=e("section","ep-component-links");
    const link=(label,fn)=>{
      const b=btn(label,fn,true);b.className="ep-component-link";links.append(b);
    };
    if(completed)link(t().repeatCheck,()=>begin(code,"diagnostic"));
    if(code==="P3"&&!completed)link(t().entryCheck+" · A Level",()=>begin(code,"diagnostic"));
    if(learning||latestPaper)link(t().fullPaper,()=>begin(code,"paper"));
    if(latestPaper)link(t().viewResult,()=>openHistory(latestPaper,false));
    link(t().viewHistory,()=>openHistoryList(code));
    component.append(links);view.append(component);
    if(shouldRefresh)refreshLevelHistory(code,state.token);
  }
  async function refreshLevelHistory(code,token){
    const result=await rpc("iclub_exam_native_mcq_history_v1",{p_paper_code:null});
    if(state.closed||state.view!=="level"||state.paper!==code||
       state.token!==token||!result.ok||!Array.isArray(result.sessions))return;
    const before=JSON.stringify(state.history.filter(x=>x.paper_code===code));
    const after=JSON.stringify(result.sessions.filter(x=>x.paper_code===code));
    state.history=result.sessions;
    if(before!==after)openLevel(code,false);
  }
  function openHistoryList(code=null,limit=8){
    if(state.closed||state.busy)return;
    ++state.token;stop();state.view="history";state.historyReturn=code;
    const view=shell();if(!view)return;
    view.append(e("h3","ep-live-card",t().viewHistory));
    const entries=state.history.filter(x=>!code||x.paper_code===code);
    if(!entries.length){view.append(e("p","ep-host-note",t().noHistory));return;}
    const list=e("div","ep-native-history-list");
    for(const entry of entries.slice(0,limit)){
      if(!["P1","P3"].includes(entry.paper_code)||!entry.session_id)continue;
      const card=e("section","ep-live-timed-row");
      const date=new Date(entry.started_at);
      const dateText=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
        state.lang==="uz"?"uz-UZ":state.lang==="en"?"en-GB":"ru-RU",
        {day:"2-digit",month:"2-digit",year:"numeric"}).format(date);
      const title=(entry.paper_code==="P1"?t().p1:t().p3)+" · "+
        (entry.session_kind==="diagnostic"?t().entryCheck:t().fullPaper);
      const total=Number(entry.total_items||30);
      card.append(e("div","ep-native-history-info",title+" · "+dateText+" · "+
        (entry.status==="finalized"?entry.score:entry.answered)+"/"+total));
      const actions=e("div","ep-live-actions");
      actions.append(btn(entry.status==="finalized"?t().viewResult:t().continueAttempt,
        ()=>openHistory(entry,false),true));
      if(entry.status==="finalized")actions.append(btn(t().plan,
        ()=>openHistory(entry,true)));
      card.append(actions);list.append(card);
    }
    view.append(list);
    if(entries.length>limit)view.append(btn(t().showMore,
      ()=>openHistoryList(code,Math.min(limit+8,entries.length)),true));
  }
  function openSettings(){
    if(state.closed||state.busy)return;
    ++state.token;stop();state.view="settings";
    const view=shell();if(!view)return;
    view.append(e("h3","ep-native-page-heading",t().profile));
    const panel=e("section","ep-live-card");
    view.append(panel);editProfile(panel,view);
  }

  function editProfile(target,view){
    if(state.closed||state.root?.firstElementChild!==view)return;
    target.replaceChildren(e("strong","",t().profile));
    const fields={};
    const addField=(key,label,value,type="text")=>{
      const line=e("label","ep-live-field");
      line.append(e("span","",label));
      let input=e("input","ep-live-input");input.type=type;input.value=value??"";input.name=key;
      if(type==="number"){input.min="0.5";input.max="168";input.step="0.5";}
      if(type==="text"){input.maxLength=80;input.placeholder="Oct/Nov 2027";}
      if(key==="target"){input=e("select","ep-live-input");input.name=key;
        for(const g of ["A*","A","B","C","D","E"]){const opt=e("option","",g);opt.value=g;
          opt.selected=g===(value||"A");input.append(opt);}
        input.value=value||"A";
      }
      fields[key]=input;line.append(input);target.append(line);
    };
    const p=state.profile||{};
    addField("series",t().series,p.exam_series);
    addField("target",t().grade,p.target_grade||"A");
    addField("total",t().hours,p.total_student_hours_available||8,"number");
    addField("economics",t().econHours,p.economics_hours_budget||3,"number");
    const feedback=e("p","ep-native-profile-feedback");feedback.setAttribute("role","alert");target.append(feedback);
    target.append(btn(t().saveProfile,async()=>{
      if(state.busy||state.closed)return;
      const exam=String(fields.series.value||"").trim();
      const total=Number(fields.total.value),econ=Number(fields.economics.value);
      if(exam.length<3||exam.length>80||!["A*","A","B","C","D","E"].includes(fields.target.value)||
        !Number.isFinite(total)||!Number.isFinite(econ)||total<0.5||total>168||econ<0.5||econ>total){
        feedback.textContent=t().profileInvalid;return;
      }
      state.busy=true;feedback.textContent=t().loading;
      const result=await rpc("iclub_exam_native_economics_save_profile_v1",{
        p_exam_series:exam,p_target_grade:fields.target.value,
        p_total_hours:total,p_economics_hours:econ
      });
      state.busy=false;
      if(state.closed||state.root?.firstElementChild!==view)return;
      if(!result.ok){feedback.textContent=t().error;return;}
      state.profile={exam_series:exam,target_grade:fields.target.value,
        total_student_hours_available:total,economics_hours_budget:econ};
      lobby();
    }));
  }
  async function openHistory(entry,openPlan){
    if(state.closed||state.busy)return;
    state.id=entry.session_id;state.paper=entry.paper_code;state.index=0;state.pendingChoice=null;
    await load();
    if(openPlan&&!state.closed&&state.id===entry.session_id&&
       state.data?.status==="finalized")await showStudyPlan();
  }
  async function begin(code,kind="paper"){
    if(state.busy||state.closed)return;
    const token=++state.token;state.busy=true;state.view="exam";
    shell()?.append(e("p","ep-host-note",t().loading));
    const nonce=(window.crypto?.randomUUID?.()||(String(Date.now())+"-"+String(Math.random())))+"-econ";
    const v=await rpc(kind==="diagnostic"?"iclub_exam_native_mcq_start_diagnostic_v1":"iclub_exam_native_mcq_start_v1",{p_paper_code:code,p_client_key:nonce});
    if(state.closed||token!==state.token)return;
    state.busy=false;
    if(!v.ok||!v.session_id){error(()=>begin(code,kind));return;}
    state.id=v.session_id;state.paper=code;state.index=0;state.pendingChoice=null;
    await load();
  }
  async function load(){
    if(state.closed||!state.id)return;
    const token=++state.token;state.busy=true;
    const v=await rpc("iclub_exam_native_mcq_get_v1",{p_session_id:state.id,p_language:state.lang});
    if(state.closed||token!==state.token)return;
    state.busy=false;
    if(!v.ok||!Array.isArray(v.items)||!((v.items.length===30&&v.session_kind==="paper")||(v.items.length===12&&v.session_kind==="diagnostic"))){error(load);return;}
    if(v.status==="finalized" && state.pendingChoice?.sessionId===state.id){
      clearChoiceDraft(state.id,state.pendingChoice.order);
      state.pendingChoice=null;
    }
    state.data=v;
    // After refresh, focus the unanswered write instead of silently
    // returning to question 1. No automatic network resend.
    if(v.status==="active"&&!state.pendingChoice){
      const unansweredWrite=v.items.findIndex((_,order)=>readChoiceDraft(v.session_id,order)?.pending===true);
      if(unansweredWrite>=0)state.index=unansweredWrite;
    }
    draw();
    return true;
  }
  function clock(label){
    stop();
    const paint=()=>{
      if(state.closed||state.data?.status!=="active")return;
      const seconds=Math.max(0,Math.ceil((new Date(state.data.deadline_at).getTime()-Date.now())/1000));
      label.textContent=t().time+": "+String(Math.floor(seconds/60)).padStart(2,"0")+":"+String(seconds%60).padStart(2,"0");
      if(seconds===0){
        stop();
        // A timed-out screen must not finalize while an earlier response
        // still has an unknown server outcome, including after a tab reload.
        if(state.pendingChoice||state.data?.items?.some((_,order)=>
           readChoiceDraft(state.id,order)?.pending===true))return;
        finish(true);
      }
    };
    paint();if(state.data?.status==="active")state.timer=setInterval(paint,1000);
  }
  function draw(){
    // An uncertain write is resolved on its original question before any
    // other answer can be submitted. The server, never navigation, decides.
    if(state.pendingChoice?.sessionId===state.id)
      state.index=state.pendingChoice.order;
    ++state.token;state.view="exam";
    const data=state.data,view=shell();if(!view||!data)return;
    const finished=data.status==="finalized",total=data.items.length;
    const header=e("div","ep-native-header");
    const initial=data.session_kind==="diagnostic"&&state.paper==="P1"&&
      !initialCheckStatus().complete;
    header.append(e("strong","",initial?t().entryCheck:
      (state.paper==="P1"?t().p1:t().p3)+
      (data.session_kind==="diagnostic"?" · "+t().entryCheck:"")));
    const remaining=e("span","ep-live-timer");
    header.append(remaining);view.append(header);
    if(finished){
      const resultActions=e("div","ep-native-result-actions");
      resultActions.append(e("h3","ep-native-result",t().result+": "+data.score+" / "+total));
      resultActions.append(btn(t().plan,showStudyPlan));
      view.append(resultActions);
    }else clock(remaining);
    const row=data.items[state.index];if(!row)return;
    view.append(e("div","ep-live-meta",t().question+" "+(state.index+1)+" / "+total+" · "+data.items.filter(x=>x.answered).length+" / "+total));
    const card=e("div","ep-live-card ep-native-question");
    card.append(e("div","ep-live-qtext",row.question));
    const options=e("div","ep-live-options");
    let draft=finished?null:readChoiceDraft(state.id,state.index);
    if(draft && row.answered && row.selected_index===draft.choice){
      clearChoiceDraft(state.id,state.index);draft=null;
      if(pendingChoiceFor(state.id,state.index))state.pendingChoice=null;
    }
    let pending=pendingChoiceFor(state.id,state.index);
    if(!finished && !pending && draft?.pending){
      pending={sessionId:state.id,order:state.index,choice:draft.choice,retryAllowed:false};
      state.pendingChoice=pending;
    }
    const choice=draft?.choice??row.selected_index;
    row.options.forEach((option,idx)=>{
      const line=e("label","ep-live-option");
      const radio=e("input");radio.type="radio";radio.name="ep-native-choice";radio.value=String(idx);
      radio.checked=choice===idx;radio.disabled=finished||state.busy||!!pending;
      if(!finished)radio.addEventListener("change",()=>{
        if(state.busy||state.pendingChoice)return;
        state.choiceFeedback=null;
        state.root?.querySelector(".ep-native-choice-feedback")?.remove();
        writeChoiceDraft(state.id,state.index,idx,false);
        const submit=state.root?.querySelector("[data-ep-native-submit]");
        if(submit)submit.disabled=false;
        state.root?.querySelector(".ep-native-unsubmitted")?.remove();
        state.root?.querySelector(".ep-native-saved")?.remove();
      });
      line.append(radio,e("span","","ABCD"[idx]+". "+option));
      if(finished&&row.correct_index===idx)line.classList.add("is-right");
      if(finished&&row.selected_index===idx&&idx!==row.correct_index)line.classList.add("is-wrong");
      options.append(line);
    });
    card.append(options);
    if(!finished)card.append(e("p","ep-native-guidance",t().autoAnswer));
    if(row.answered&&!finished&&(!draft||draft.choice===row.selected_index))
      card.append(e("p","ep-native-saved",t().saved));
    else if(draft&&!draft.pending)card.append(e("p","ep-native-unsubmitted",t().selectionPending));
    if(!finished&&state.choiceFeedback){
      const feedback=e("p","ep-native-choice-feedback",state.choiceFeedback);
      feedback.setAttribute("role","status");card.append(feedback);
    }
    if(pending&&!finished){
      const warning=e("div","ep-live-card ep-native-save-recovery");
      warning.setAttribute("role","alert");
      warning.append(e("p","",t().uncertain));
      const controls=e("div","ep-live-actions");
      controls.append(btn(t().checkSaved,()=>reconcileChoice(pending),true));
      if(pending.retryAllowed && data.status==="active" &&
         new Date(data.deadline_at).getTime()>Date.now())
        controls.append(btn(t().retrySame,()=>sendChoice(pending)));
      // Leaving never deletes a server answer or the tab-local unsent choice.
      // The learner can return and explicitly check the server again.
      controls.append(btn(t().leavePending,()=>{
        if(state.busy||state.pendingChoice!==pending)return;
        state.pendingChoice=null;state.choiceFeedback=null;lobby();
      },true));
      warning.append(controls);card.append(warning);
    }
    if(finished){
      card.append(e("p","ep-host-note",t().your+": "+(row.selected_index===null?t().empty:"ABCD"[row.selected_index])+
        " · "+t().right+": "+"ABCD"[row.correct_index]));
      if(row.explanation)card.append(e("p","ep-live-answer",row.explanation));
    }
    view.append(card);
    const actions=e("div","ep-live-actions");
    if(!finished&&!pending){
      const submit=btn(t().save,()=>saveChoice());
      submit.dataset.epNativeSubmit="true";
      submit.disabled=state.busy||choice===null||choice===undefined;
      actions.append(submit);
    }
    if(state.index>0&&!pending)actions.append(btn(t().previous,()=>{if(!state.busy){state.choiceFeedback=null;state.index--;draw();}},true));
    if(state.index<total-1&&!pending)actions.append(btn(t().next,()=>{if(!state.busy){state.choiceFeedback=null;state.index++;draw();}},true));
    if(!finished&&!pending)actions.append(btn(t().finish,()=>finish(false),true));
    if(finished)actions.append(btn(data.session_kind==="diagnostic"?t().repeatCheck:t().retest,()=>begin(state.paper,data.session_kind),true));
    if(!pending)actions.append(btn(t().papers,lobby,true));
    view.append(actions);
  }

  async function showStudyPlan(){
    if(state.closed||state.busy||state.data?.status!=="finalized"||!state.id)return;
    const sessionId=state.id,token=++state.token;
    state.busy=true;
    shell()?.append(e("p","ep-host-note",t().loading));
    const result=await rpc("iclub_exam_native_mcq_study_plan_v1",{
      p_session_id:sessionId,p_language:state.lang
    });
    state.busy=false;
    if(state.closed||state.token!==token||state.id!==sessionId)return;
    if(!result.ok||!Array.isArray(result.priorities)){error(showStudyPlan);return;}
    renderStudyPlan(result);
  }

  function renderStudyPlan(data){
    if(!data||state.closed)return;
    state.planData=data;state.view="plan";stop();
    const view=shell();if(!view)return;
    const header=e("section","ep-native-plan-intro");
    header.append(e("h3","ep-native-page-heading",t().plan));
    if(data.weekly_economics_hours)
      header.append(e("p","ep-native-guidance",t().econHours+": "+data.weekly_economics_hours));
    view.append(header);
    // Keep the outcome visible without converting the plan into an endless report.
    const stats=e("div","ep-live-stats ep-native-plan-stats-compact");
    for(const [amount,label] of [
      [String(data.score)+"/"+String(data.out_of||30),t().result],
      [Math.max(0,Number(data.weak_count||0)-Number(data.retested_correct_count||0)),t().mistakes],
      [data.studied_count,t().studied],
      [data.retested_correct_count,t().verified]
    ]){
      const box=e("div","ep-live-stat");
      box.append(e("strong","",amount),e("span","",label));stats.append(box);
    }
    view.append(stats);
    const topics=Array.isArray(data.priorities)?data.priorities:[];
    if(Number(data.weak_count||0)===0)view.append(e("p","ep-host-note",t().allCorrect));
    else if(!topics.length)view.append(e("p","ep-host-note",t().verified));
    else {
      const focus=e("section","ep-live-card");
      focus.append(e("div","ep-native-level-eyebrow",t().recommended),
        e("h3","",topics[0].title));
      focus.append(e("p","ep-host-note",t().day+" "+topics[0].suggested_day+
        " · "+String(data.suggested_minutes_per_topic||20)+" "+t().minuteShort));
      focus.append(btn(t().openLesson,()=>renderLesson(0)));
      view.append(focus);
      if(topics.length>1){
        const list=e("section","ep-native-plan-topic-list");
        list.append(e("h4","ep-native-section-title",t().topicOverview||t().plan));
        topics.slice(1).forEach((task,i)=>{
          const item=e("div","ep-live-plan-item");
          item.append(e("span","",task.title));
          item.append(btn(t().openLesson,()=>renderLesson(i+1),true));
          list.append(item);
        });
        view.append(list);
      }
    }
    const units=e("details","ep-native-units-details");
    units.append(e("summary","",t().viewUnits));
    const rows=e("div","ep-native-plan-units");
    (data.unit_results||[]).forEach(unit=>{
      const item=e("div","ep-native-plan-unit");
      item.append(e("span","",t().unit+" "+unit.unit),
        e("strong","",String(unit.correct)+" / "+String(unit.total)));
      rows.append(item);
    });
    units.append(rows);view.append(units);
    const actions=e("div","ep-live-actions");
    actions.append(btn(t().backReview,draw,true));
    actions.append(btn(data.session_kind==="diagnostic"?t().repeatCheck:t().retest,
      ()=>begin(state.paper,data.session_kind||"paper"),true));
    if(data.session_kind==="diagnostic")
      actions.append(btn(t().fullPaper,()=>begin(state.paper),true));
    view.append(actions);
    view.append(e("p","ep-native-guidance",t().studyNote));
  }
  function renderLesson(index){
    if(state.closed||state.busy||!state.planData)return;
    const data=state.planData,tasks=Array.isArray(data.priorities)?data.priorities:[];
    if(!Number.isInteger(index)||index<0||index>=tasks.length)return;
    state.selectedLesson=index;state.view="lesson";
    const task=tasks[index],view=shell();if(!view)return;
    const heading=e("div","ep-native-lesson-heading");
    heading.append(e("div","ep-native-level-eyebrow",
      t().day+" "+task.suggested_day+" · "+
      String(data.suggested_minutes_per_topic||20)+" "+t().minuteShort),
      e("h3","ep-native-page-heading",task.title));
    view.append(heading);
    const body=e("section","ep-live-card");
    if(task.lesson){
      body.append(e("h4","ep-native-study-label",t().study));
      body.append(e("p","ep-live-qtext",task.lesson));
    }
    if(task.common_trap){
      body.append(e("h4","ep-native-study-label",t().trap));
      body.append(e("p","ep-live-answer",task.common_trap));
    }
    if(task.check_question){
      body.append(e("h4","ep-native-study-label",t().check));
      body.append(e("p","ep-live-qtext",task.check_question));
      if(task.check_answer){
        const answer=e("p","ep-live-answer",task.check_answer);
        answer.hidden=true;
        const toggle=btn(t().showCheck,()=>{
          answer.hidden=!answer.hidden;
          toggle.textContent=answer.hidden?t().showCheck:t().hideCheck;
        },true);
        body.append(toggle,answer);
      }
    }
    if(task.studied)body.append(e("div","ep-native-study-done",t().studiedDone));
    else body.append(btn(t().markStudied,()=>markStudied(task.skill_key)));
    view.append(body);
    const actions=e("div","ep-live-actions");
    if(index+1<tasks.length)actions.append(btn(t().nextLesson,()=>renderLesson(index+1),true));
    actions.append(btn(t().backToPlan,()=>renderStudyPlan(state.planData),true));
    view.append(actions);
  }

  async function markStudied(skillKey){
    if(state.closed||state.busy||!state.id||!skillKey)return;
    const sessionId=state.id,token=++state.token;
    state.busy=true;
    const result=await rpc("iclub_exam_native_mcq_mark_studied_v1",{
      p_session_id:sessionId,p_skill_key:skillKey,p_studied:true
    });
    state.busy=false;
    if(state.closed||state.token!==token||state.id!==sessionId)return;
    if(!result.ok){error(showStudyPlan);return;}
    await showStudyPlan();
  }
  function commitChoice(pending){
    const row=state.data?.items?.[pending.order];
    if(!row||state.id!==pending.sessionId)return;
    row.selected_index=pending.choice;row.answered=true;
    clearChoiceDraft(pending.sessionId,pending.order);
    if(state.pendingChoice===pending)state.pendingChoice=null;
    const next=state.data.items.findIndex((item,i)=>i>pending.order&&!item.answered);
    state.index=next>=0?next:(pending.order<state.data.items.length-1?pending.order+1:pending.order);
    draw();
  }
  async function reconcileChoice(pending){
    if(state.closed||state.busy||state.pendingChoice!==pending)return;
    const token=state.token;state.busy=true;
    const result=await boundedRpc("iclub_exam_native_mcq_get_v1",{
      p_session_id:pending.sessionId,p_language:state.lang
    },12000);
    state.busy=false;
    if(state.closed||state.token!==token||state.pendingChoice!==pending)return;
    if(result.ok&&Array.isArray(result.items)){
      state.data=result;
      const item=result.items[pending.order];
      if(item?.answered&&item.selected_index===pending.choice){
        commitChoice(pending);return;
      }
      if(item?.answered&&item.selected_index!==pending.choice){
        // A concurrent browser may have submitted another answer. Never
        // automatically overwrite the newer, server-confirmed choice.
        clearChoiceDraft(pending.sessionId,pending.order);
        state.pendingChoice=null;state.index=pending.order;
        state.choiceFeedback=t().serverDifferent;
        draw();return;
      }
      if(result.status==="finalized"){
        // The attempt is closed; a draft cannot become score evidence.
        clearChoiceDraft(pending.sessionId,pending.order);
        state.pendingChoice=null;
        draw();return;
      }
      // A definite server read enables only an explicit same-choice retry.
      pending.retryAllowed=result.status==="active"&&
        new Date(result.deadline_at).getTime()>Date.now();
    }else pending.retryAllowed=false;
    draw();
  }
  async function sendChoice(pending){
    if(state.closed||state.busy||state.pendingChoice!==pending||
       state.data?.status!=="active")return;
    if(new Date(state.data.deadline_at).getTime()<=Date.now()){
      await load();return;
    }
    const token=state.token;state.busy=true;pending.retryAllowed=false;
    const submit=state.root?.querySelector("[data-ep-native-submit]");
    if(submit){submit.disabled=true;submit.textContent=t().saving;}
    const result=await boundedRpc("iclub_exam_native_mcq_answer_v1",{
      p_session_id:pending.sessionId,p_item_order:pending.order+1,p_choice:pending.choice
    },15000);
    state.busy=false;
    if(state.closed||state.token!==token||state.pendingChoice!==pending)return;
    if(result.ok&&result.saved===true&&result.selected_index===pending.choice){
      commitChoice(pending);return;
    }
    // An RPC can commit and lose its ACK. Never blindly send twice.
    await reconcileChoice(pending);
  }
  async function saveChoice(){
    if(state.busy||state.closed||state.pendingChoice||
       state.data?.status!=="active"||!state.id)return;
    const selected=state.root?.querySelector('input[name="ep-native-choice"]:checked');
    const choice=selected?Number(selected.value):NaN,order=state.index;
    if(!Number.isInteger(choice)||choice<0||choice>3)return;
    const row=state.data.items[order];
    if(!row)return;
    if(row.answered&&row.selected_index===choice){
      clearChoiceDraft(state.id,order);
      const next=state.data.items.findIndex((item,i)=>i>order&&!item.answered);
      if(next>=0){state.index=next;draw();}return;
    }
    const pending={sessionId:state.id,order,choice,retryAllowed:false};
    state.choiceFeedback=null;
    state.pendingChoice=pending;writeChoiceDraft(state.id,order,choice,true);
    await sendChoice(pending);
  }
  async function finish(auto){
    // Do not finalize while the server outcome of a write is unknown.
    if(state.busy||state.closed||state.pendingChoice||state.data?.status!=="active")return;
    if(auto && state.data.items.some((_,order)=>
       readChoiceDraft(state.id,order)?.pending===true))return;
    if(!auto){
      const unsubmitted=state.data.items.findIndex((item,order)=>{
        const draft=readChoiceDraft(state.id,order);
        return draft && (item.answered!==true||item.selected_index!==draft.choice);
      });
      if(unsubmitted>=0){
        state.index=unsubmitted;draw();
        const note=e("p","ep-native-unsubmitted",t().finishNeedSubmit);
        note.setAttribute("role","alert");
        state.root?.querySelector(".ep-native-question")?.append(note);
        return;
      }
      if(!window.confirm(t().confirm))return;
    }
    stop();state.busy=true;
    const sessionId=state.id,token=state.token;
    const r=await rpc("iclub_exam_native_mcq_finish_v1",{p_session_id:sessionId});
    state.busy=false;
    if(state.closed||state.id!==sessionId||state.token!==token)return;
    if(!r.ok){error(load);return;}
    await load();
    // The diagnostic result leads directly to the personal study plan.
    // The user can return to question-by-question review from that screen.
    if(!state.closed&&state.id===sessionId&&state.data?.status==="finalized"){
      if(state.data.session_kind==="diagnostic"&&state.paper==="P1"){
        // Update local history only after the server confirms finalization.
        // A refresh still reads the authoritative session from Supabase.
        state.history.unshift({
          session_id:sessionId,paper_code:"P1",session_kind:"diagnostic",
          status:"finalized",score:state.data.score,total_items:12,
          answered:state.data.items.filter(x=>x.answered).length,
          started_at:new Date().toISOString()
        });
        renderEntryResult();
      }else await showStudyPlan();
    }
  }
  function mount({root,shell:config,language,onBack}={}){
    unmount();
    if(!root||config?.program_key!=="economics_9708"||config.enabled!==true||
      !["P1","P3"].every(code=>config.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq")))return false;
    state.root=root;state.shell=config;state.lang=["ru","uz","en"].includes(language)?language:"ru";
    state.onBack=onBack;state.closed=false;lobby();return true;
  }
  internal.economicsNative=Object.freeze({mount,unmount});
})();