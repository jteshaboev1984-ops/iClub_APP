(() => {
  "use strict";
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const state = {root:null,shell:null,lang:"ru",id:null,paper:null,data:null,index:0,timer:null,busy:false,closed:true,onBack:null,token:0,view:"home",history:[],planData:null,selectedLesson:0,historyReturn:null,writtenPlan:null,writtenView:null,betaInvite:false,betaJoined:false,betaBusy:false};
  const dictionary={
    ru:{writtenPractice:"Письменная практика",betaTitle:"Попробуйте письменные задания",betaIntro:"Приглашаем вас испытать задания Paper 2 и Paper 4. Участие добровольное. Вы будете выполнять работы самостоятельно; приложение не выставляет оценки за письменные ответы. Можно отказаться в любой момент без потери уже выполненной работы.",betaJoin:"Согласен, начать",betaLeave:"Завершить участие",betaUnavailable:"Сейчас не удалось подключить письменную практику. Попробуйте позже.",baselineIntro:"Сначала проверьте базовые знания Cambridge Economics (AS): 12 вопросов, 20 минут. После результата выберите Paper 1 или Paper 3. Темы A Level проверяются отдельно.",selectPaper:"Выберите Paper",continuePreparation:"Продолжить подготовку",entryResult:"Входная диагностика завершена",topicOverview:"Темы для подготовки",chooseLevel:"Выберите уровень",openLevel:"Открыть",overview:"Главная",noAttempts:"Пока нет попыток",afterCheck:"Диагностика завершена — изучите слабые темы",startHere:"Начните с входной диагностики",resumeExam:"Продолжить работу",levelIntro:"Диагностика определит темы для подготовки. Полный экзамен доступен отдельно.",openLesson:"Изучить тему",viewUnits:"Результаты по разделам",nextLesson:"Следующая тема",showMore:"Показать ещё",viewHistory:"История попыток",noHistory:"Завершённые экзамены и диагностики появятся здесь",backToPlan:"К учебному плану",recommended:"Рекомендуемое действие",title:"Cambridge Economics · Exam Prep",intro:"Выберите уровень и начните с короткой диагностики. После результата откроется учебный план.",minuteShort:"мин",profile:"Настройка подготовки",editProfile:"Изменить",series:"Экзаменационная сессия",grade:"Целевая оценка",hours:"Всего часов на учёбу в неделю",econHours:"Часов на экономику в неделю",saveProfile:"Сохранить настройки",profileInvalid:"Проверьте экзаменационную сессию и количество часов: время на экономику не должно превышать общее время.",profileSaved:"Настройки сохранены",optional:"Настройте цель и время подготовки. Уже сохранённые попытки не изменятся.",startDiagnostic:"Начать диагностику",fullPaper:"Полный экзамен",entryCheck:"Входная диагностика",completedCheck:"Диагностика завершена",repeatCheck:"Повторить диагностику",history:"Мои попытки",viewResult:"Посмотреть результат",continueAttempt:"Продолжить",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Начать или продолжить",back:"Назад", beforePlan:"Учебный план появится после первого завершённого экзамена. Позже его можно открыть из истории попыток.", autoAnswer:"Выберите вариант: он сохранится автоматически. До завершения экзамена ответ можно изменить.",saving:"Сохраняем ответ…",
      papers:"К экзаменам",question:"Вопрос",time:"Осталось времени",save:"Сохранить ответ",
      saved:"Ответ сохранён",next:"Следующий",previous:"Предыдущий",finish:"Завершить экзамен",
      confirm:"Завершить экзамен? Пропущенные вопросы получат 0 баллов.",result:"Результат",
      review:"Разбор ответов",right:"Правильный ответ",your:"Ваш ответ",empty:"Не отвечено",
      loading:"Загрузка…",error:"Не удалось выполнить действие. Проверьте соединение.",retry:"Повторить",
      plan:"Мой учебный план",planIntro:"Начните с этих тем и проверьте себя после повторения.",
      unit:"Раздел",correct:"Верно",mistakes:"Тем для повторения",studied:"Изучено",verified:"Подтверждено повторной проверкой",
      study:"Объяснение темы",trap:"На что обратить внимание",check:"Проверьте себя",showCheck:"Показать ответ",
      hideCheck:"Скрыть ответ",markStudied:"Отметить как изученное",studiedDone:"Тема изучена",
      backReview:"К разбору экзамена",retest:"Пройти Paper ещё раз",day:"День",
      allCorrect:"Все вопросы решены правильно. Ошибок для разбора нет.",studyNote:"Отметка «изучено» не означает, что навык освоен. Это подтвердит правильный ответ в следующем экзамене."},
    uz:{writtenPractice:"Yozma mashqlar",betaTitle:"Yozma topshiriqlarni sinab ko‘ring",betaIntro:"Sizni Paper 2 va Paper 4 yozma mashqlarini sinab ko‘rishga taklif qilamiz. Ishtirok ixtiyoriy. Javoblarni mustaqil bajarasiz; ilova yozma ishlaringizga baho qo‘ymaydi. Istalgan vaqtda qatnashishni to‘xtatishingiz mumkin, bajarilgan ishlar saqlanadi.",betaJoin:"Roziman, boshlash",betaLeave:"Ishtirokni to‘xtatish",betaUnavailable:"Hozir yozma mashqlarga ulanishning imkoni bo‘lmadi. Keyinroq urinib ko‘ring.",baselineIntro:"Avval Cambridge Economics (AS) bo‘yicha asosiy bilimlaringizni tekshiring: 12 savol, 20 daqiqa. Natijadan so‘ng Paper 1 yoki Paper 3 ni tanlang. A Level mavzulari alohida tekshiriladi.",selectPaper:"Paperni tanlang",continuePreparation:"Tayyorgarlikni davom ettirish",entryResult:"Kirish diagnostikasi yakunlandi",topicOverview:"O‘rganiladigan mavzular",chooseLevel:"Darajani tanlang",openLevel:"Ochish",overview:"Bosh sahifa",noAttempts:"Hozircha urinishlar yo‘q",afterCheck:"Diagnostika tugadi — qiyin mavzularni o‘rganing",startHere:"Avval kirish diagnostikasidan boshlang",resumeExam:"Ishni davom ettirish",levelIntro:"Diagnostika o‘rganiladigan mavzularni aniqlaydi. To‘liq imtihon alohida mavjud.",openLesson:"Mavzuni o‘rganish",viewUnits:"Bo‘limlar bo‘yicha natijalar",nextLesson:"Keyingi mavzu",showMore:"Ko‘proq ko‘rsatish",viewHistory:"Urinishlar tarixi",noHistory:"Yakunlangan imtihonlar va diagnostikalar shu yerda chiqadi",backToPlan:"O‘quv rejasiga",recommended:"Tavsiya etilgan qadam",title:"Cambridge Economics · Exam Prep",intro:"Darajani tanlang va qisqa diagnostikadan boshlang. Natijadan keyin o‘quv reja ochiladi.",minuteShort:"daq.",profile:"Tayyorgarlik sozlamalari",editProfile:"O‘zgartirish",series:"Imtihon sessiyasi",grade:"Maqsadli baho",hours:"Haftalik umumiy o‘qish soati",econHours:"Haftalik iqtisodiyot soati",saveProfile:"Sozlamalarni saqlash",profileInvalid:"Imtihon davri va soatlarni tekshiring: iqtisodiyot soati umumiy vaqtdan oshmasin.",profileSaved:"Sozlamalar saqlandi",optional:"Tayyorgarlik maqsadi va vaqtini belgilang. Avvalgi urinishlar o‘zgarmaydi.",startDiagnostic:"Diagnostikani boshlash",fullPaper:"To‘liq imtihon",entryCheck:"Kirish diagnostikasi",completedCheck:"Diagnostika yakunlandi",repeatCheck:"Diagnostikani takrorlash",history:"Mening urinishlarim",viewResult:"Natijani ko‘rish",continueAttempt:"Davom ettirish",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Boshlash yoki davom ettirish",back:"Orqaga", beforePlan:"O‘quv rejangiz birinchi yakunlangan imtihondan so‘ng paydo bo‘ladi. Keyin uni urinishlar tarixidan ochishingiz mumkin.", autoAnswer:"Variantni tanlang: javob avtomatik saqlanadi. Imtihonni yakunlashdan oldin uni o‘zgartirish mumkin.",saving:"Javob saqlanmoqda…",
      papers:"Imtihonlarga qaytish",question:"Savol",time:"Qolgan vaqt",save:"Javobni saqlash",
      saved:"Javob saqlandi",next:"Keyingi",previous:"Oldingi",finish:"Imtihonni yakunlash",
      confirm:"Imtihonni yakunlaysizmi? Javobsiz savollar 0 ball bo‘ladi.",result:"Natija",
      review:"Javoblarni tahlil qilish",right:"To‘g‘ri javob",your:"Sizning javobingiz",empty:"Javob berilmagan",
      loading:"Yuklanmoqda…",error:"Amal bajarilmadi. Internetni tekshiring.",retry:"Qayta urinish",
      plan:"Mening o‘quv rejam",planIntro:"Avval shu mavzularni o‘rganing, so‘ng qayta tekshiring.",
      unit:"Bo‘lim",correct:"To‘g‘ri",mistakes:"Takrorlanadigan mavzular",studied:"O‘rganildi",verified:"Qayta tekshiruvda tasdiqlangan",
      study:"Mavzu izohi",trap:"E'tibor bering",check:"O‘zingizni tekshiring",showCheck:"Javobni ko‘rsatish",
      hideCheck:"Javobni yashirish",markStudied:"O‘rganilgan deb belgilash",studiedDone:"Mavzu o‘rganildi",
      backReview:"Imtihon tahliliga",retest:"Paperni qayta ishlash",day:"Kun",
      allCorrect:"Hamma savollarga to‘g‘ri javob berildi. Tahlil qilinadigan xato yo‘q.",studyNote:"«O‘rganildi» belgisi bilim o‘zlashtirilganini isbotlamaydi. Keyingi imtihondagi to‘g‘ri javob tasdiqlaydi."},
    en:{writtenPractice:"Written practice",betaTitle:"Try written practice",betaIntro:"You are invited to try Paper 2 and Paper 4 written tasks. Participation is voluntary. You work independently; the app does not grade unreviewed written answers. You can stop participating at any time without losing completed work.",betaJoin:"I agree, start",betaLeave:"Stop participating",betaUnavailable:"Written practice could not be enabled right now. Please try again later.",baselineIntro:"First check your Cambridge Economics AS foundations: 12 questions, 20 minutes. After your result, choose Paper 1 or Paper 3. Advanced A Level topics are checked separately.",selectPaper:"Choose your paper",continuePreparation:"Continue preparation",entryResult:"Entry check completed",topicOverview:"Topics to study",chooseLevel:"Choose your level",openLevel:"Open",overview:"Overview",noAttempts:"No attempts yet",afterCheck:"Entry check completed — focus on weaker topics",startHere:"Begin with the entry check",resumeExam:"Resume your work",levelIntro:"The entry check identifies study topics. The full exam is available separately.",openLesson:"Study this topic",viewUnits:"Results by unit",nextLesson:"Next topic",showMore:"Show more",viewHistory:"Attempt history",noHistory:"Completed exams and entry checks will appear here",backToPlan:"Back to study plan",recommended:"Recommended next step",title:"Cambridge Economics · Exam Prep",intro:"Select a level and begin with a short entry check. Your study plan follows the result.",minuteShort:"min",profile:"Preparation settings",editProfile:"Edit",series:"Exam series",grade:"Target grade",hours:"Total weekly study hours",econHours:"Weekly Economics hours",saveProfile:"Save settings",profileInvalid:"Check exam series and weekly hours: Economics time cannot exceed your total study time.",profileSaved:"Settings saved",optional:"Set a preparation goal and study time. Existing attempts will not change.",startDiagnostic:"Start entry check",fullPaper:"Full exam",entryCheck:"Entry check",completedCheck:"Entry check completed",repeatCheck:"Repeat entry check",history:"My attempts",viewResult:"View result",continueAttempt:"Continue",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Start or resume",back:"Back", beforePlan:"Your study plan appears after your first completed paper. You can reopen it from your attempt history.", autoAnswer:"Choose an option to save automatically. You can change it until you finish the paper.",saving:"Saving answer…",
      papers:"Back to papers",question:"Question",time:"Time remaining",save:"Save answer",
      saved:"Answer saved",next:"Next",previous:"Previous",finish:"Finish exam",
      confirm:"Finish this exam? Unanswered questions score zero.",result:"Result",
      review:"Review answers",right:"Correct answer",your:"Your answer",empty:"Unanswered",
      loading:"Loading…",error:"The action failed. Check your connection.",retry:"Try again",
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
    const header=e("div","ep-live-head");
    const title=e("div");
    title.append(e("div","ep-host-kicker","Cambridge 9708"),
      e("h2","ep-host-title",t().title));
    header.append(title);
    if(state.view!=="home")header.append(btn("← "+t().back,goBack,true));
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
    state.id=null;state.paper=null;state.data=null;state.profile=null;state.history=[];state.planData=null;state.view="home";state.historyReturn=null;state.busy=false;state.onBack=null;
  }
  async function rpc(name,args={}){
    try {
      if(!window.sb||typeof window.sb.rpc!=="function")return {ok:false};
      const response=await window.sb.rpc(name,args);
      if(response.error||response.data?.ok!==true)return {ok:false,code:response.data?.code||"rpc_failed"};
      return response.data;
    }catch(_){return {ok:false,code:"network_error"};}
  }
  function error(retry){
    const view=shell();if(!view)return;
    view.append(e("p","ep-host-note",t().error));
    const actions=e("div","ep-host-actions");
    actions.append(btn(t().retry,retry),btn(t().papers,lobby,true));view.append(actions);
  }

  // Same navigation hierarchy as Mathematics: overview → paper home → focused action.
  function goBack(){
    if(state.busy||state.closed)return;
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
    if(state.view==="level"||state.view==="settings"){lobby();return;}
    state.onBack?.();
  }

  function lobby(){
    state.writtenView?.dispose?.();state.writtenView=null;state.writtenPlan=null;
    state.betaInvite=false;state.betaJoined=false;state.betaBusy=false;
    ++state.token;stop();state.view="home";state.id=null;state.paper=null;
    state.data=null;state.planData=null;state.index=0;
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
    state.betaInvite=beta.ok&&beta.eligible===true;
    state.betaJoined=beta.ok&&beta.joined===true;
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
      view.append(block);
      // Existing pre-release Paper attempts remain accessible independently.
      if(state.history.length)view.append(btn(t().viewHistory,()=>openHistoryList(),true));
      return;
    }
    const grid=e("div","ep-live-grid");
    for(const [code,title] of [["P1",t().p1],["P3",t().p3]]){
      if(!state.shell?.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq"))continue;
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
    if(state.betaInvite&&!state.writtenPlan&&window.iClubWrittenCoreViewV1){
      const invite=e("section","ep-live-card");
      invite.append(e("h3","",t().betaTitle),
        e("p","ep-host-note",t().betaIntro));
      const actions=e("div","ep-live-actions");
      const join=btn(t().betaJoin,async()=>{
        if(state.closed||state.view!=="home"||state.betaBusy)return;
        state.betaBusy=true;join.disabled=true;
        const result=await rpc("iclub_econ_written_beta_join_v1",{p_confirm:true});
        if(state.closed||state.view!=="home")return;
        if(result.ok&&result.joined===true){lobby();return;}
        note.textContent=t().betaUnavailable;
        state.betaBusy=false;join.disabled=false;
      });
      const note=e("p","ep-host-note","");
      actions.append(join);invite.append(actions,note);view.append(invite);
    }
    const tools=e("div","ep-live-actions");
    tools.append(btn(t().profile,openSettings,true),
      btn(t().viewHistory,()=>openHistoryList(),true));
    if(state.writtenPlan&&window.iClubWrittenCoreViewV1)
      tools.append(btn(t().writtenPractice,openWritten,true));
    if(state.betaJoined&&state.writtenPlan){
      tools.append(btn(t().betaLeave,async()=>{
        if(state.closed||state.view!=="home"||state.betaBusy)return;
        state.betaBusy=true;
        const result=await rpc("iclub_econ_written_beta_leave_v1",{});
        state.betaBusy=false;
        if(state.closed||state.view!=="home")return;
        if(result.ok&&result.left===true)lobby();
        else error(lobby);
      },true));
    }
    view.append(tools);
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
    actions.append(btn(t().selectPaper,lobby));
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
    state.id=entry.session_id;state.paper=entry.paper_code;state.index=0;
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
    state.id=v.session_id;state.paper=code;state.index=0;
    await load();
  }
  async function load(){
    if(state.closed||!state.id)return;
    const token=++state.token;state.busy=true;
    const v=await rpc("iclub_exam_native_mcq_get_v1",{p_session_id:state.id,p_language:state.lang});
    if(state.closed||token!==state.token)return;
    state.busy=false;
    if(!v.ok||!Array.isArray(v.items)||!((v.items.length===30&&v.session_kind==="paper")||(v.items.length===12&&v.session_kind==="diagnostic"))){error(load);return;}
    state.data=v;draw();
    return true;
  }
  function clock(label){
    stop();
    const paint=()=>{
      if(state.closed||state.data?.status!=="active")return;
      const seconds=Math.max(0,Math.ceil((new Date(state.data.deadline_at).getTime()-Date.now())/1000));
      label.textContent=t().time+": "+String(Math.floor(seconds/60)).padStart(2,"0")+":"+String(seconds%60).padStart(2,"0");
      if(seconds===0){stop();finish(true);}
    };
    paint();if(state.data?.status==="active")state.timer=setInterval(paint,1000);
  }
  function draw(){
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
    row.options.forEach((option,idx)=>{
      const line=e("label","ep-live-option");
      const radio=e("input");radio.type="radio";radio.name="ep-native-choice";radio.value=String(idx);
      radio.checked=row.selected_index===idx;radio.disabled=finished||state.busy;
      if(!finished)radio.addEventListener("change",()=>saveChoice(idx));
      line.append(radio,e("span","","ABCD"[idx]+". "+option));
      if(finished&&row.correct_index===idx)line.classList.add("is-right");
      if(finished&&row.selected_index===idx&&idx!==row.correct_index)line.classList.add("is-wrong");
      options.append(line);
    });
    card.append(options);
    if(!finished)card.append(e("p","ep-native-guidance",t().autoAnswer));
    if(row.answered&&!finished)card.append(e("p","ep-native-saved",t().saved));
    if(finished){
      card.append(e("p","ep-host-note",t().your+": "+(row.selected_index===null?t().empty:"ABCD"[row.selected_index])+
        " · "+t().right+": "+"ABCD"[row.correct_index]));
      if(row.explanation)card.append(e("p","ep-live-answer",row.explanation));
    }
    view.append(card);
    const actions=e("div","ep-live-actions");
    if(state.index>0)actions.append(btn(t().previous,()=>{if(!state.busy){state.index--;draw();}},true));
    if(state.index<total-1)actions.append(btn(t().next,()=>{if(!state.busy){state.index++;draw();}},true));
    if(!finished)actions.append(btn(t().finish,()=>finish(false),true));
    if(finished)actions.append(btn(data.session_kind==="diagnostic"?t().repeatCheck:t().retest,()=>begin(state.paper,data.session_kind),true));
    actions.append(btn(t().papers,lobby,true));view.append(actions);
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
    const stats=e("div","ep-live-stats");
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
  async function saveChoice(choice){
    if(state.busy||state.closed||state.data?.status!=="active"||
       !Number.isInteger(choice)||choice<0||choice>3)return;
    const sessionId=state.id,order=state.index,token=state.token;
    const row=state.data.items[order];
    if(!row||row.selected_index===choice&&row.answered)return;
    state.busy=true;
    for(const input of state.root?.querySelectorAll('input[name="ep-native-choice"]')||[])
      input.disabled=true;
    const note=e("p","ep-native-saving",t().saving);
    note.setAttribute("role","status");
    state.root?.querySelector(".ep-native-question")?.append(note);
    const r=await rpc("iclub_exam_native_mcq_answer_v1",{
      p_session_id:sessionId,p_item_order:order+1,p_choice:choice
    });
    state.busy=false;
    if(state.closed||state.id!==sessionId||state.token!==token)return;
    if(!r.ok){error(load);return;}
    // Server confirmed: update only the chosen item and navigate onward.
    // No extra 30-question GET after each saved answer is necessary.
    row.selected_index=choice;row.answered=true;
    const nextUnanswered=state.data.items.findIndex((item,i)=>i>order&&!item.answered);
    state.index=nextUnanswered>=0?nextUnanswered:
      (order<state.data.items.length-1?order+1:order);
    draw();
  }
  async function finish(auto){
    if(state.busy||state.closed||state.data?.status!=="active")return;
    if(!auto&&!window.confirm(t().confirm))return;
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