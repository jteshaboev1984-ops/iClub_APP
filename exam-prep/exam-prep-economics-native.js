(() => {
  "use strict";
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const state = {root:null,shell:null,lang:"ru",id:null,paper:null,data:null,index:0,timer:null,busy:false,closed:true,onBack:null,token:0,view:"home",history:[],planData:null,selectedLesson:0};
  const dictionary={
    ru:{topicOverview:"Темы для подготовки",chooseLevel:"Выберите уровень",openLevel:"Открыть",overview:"Главная",noAttempts:"Пока нет попыток",afterCheck:"Диагностика завершена — изучите слабые темы",startHere:"Начните с входной диагностики",resumeExam:"Продолжить работу",levelIntro:"Диагностика определит темы для подготовки. Полный экзамен доступен отдельно.",openLesson:"Изучить тему",viewUnits:"Результаты по разделам",nextLesson:"Следующая тема",showMore:"Показать ещё",viewHistory:"История попыток",noHistory:"Завершённые экзамены и диагностики появятся здесь",backToPlan:"К учебному плану",recommended:"Рекомендуемое действие",title:"Cambridge Economics · Exam Prep",intro:"Выберите уровень и начните с короткой диагностики. После результата откроется учебный план.",minuteShort:"мин",profile:"Настройка подготовки",editProfile:"Изменить",series:"Экзаменационная сессия",grade:"Целевая оценка",hours:"Всего часов на учёбу в неделю",econHours:"Часов на экономику в неделю",saveProfile:"Сохранить настройки",profileInvalid:"Проверьте экзаменационную сессию и количество часов: время на экономику не должно превышать общее время.",profileSaved:"Настройки сохранены",optional:"Настройте цель и время подготовки. Уже сохранённые попытки не изменятся.",startDiagnostic:"Начать диагностику",fullPaper:"Полный экзамен",entryCheck:"Входная диагностика",completedCheck:"Диагностика завершена",repeatCheck:"Повторить диагностику",history:"Мои попытки",viewResult:"Посмотреть результат",continueAttempt:"Продолжить",
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
    uz:{topicOverview:"O‘rganiladigan mavzular",chooseLevel:"Darajani tanlang",openLevel:"Ochish",overview:"Bosh sahifa",noAttempts:"Hozircha urinishlar yo‘q",afterCheck:"Diagnostika tugadi — qiyin mavzularni o‘rganing",startHere:"Avval kirish diagnostikasidan boshlang",resumeExam:"Ishni davom ettirish",levelIntro:"Diagnostika o‘rganiladigan mavzularni aniqlaydi. To‘liq imtihon alohida mavjud.",openLesson:"Mavzuni o‘rganish",viewUnits:"Bo‘limlar bo‘yicha natijalar",nextLesson:"Keyingi mavzu",showMore:"Ko‘proq ko‘rsatish",viewHistory:"Urinishlar tarixi",noHistory:"Yakunlangan imtihonlar va diagnostikalar shu yerda chiqadi",backToPlan:"O‘quv rejasiga",recommended:"Tavsiya etilgan qadam",title:"Cambridge Economics · Exam Prep",intro:"Darajani tanlang va qisqa diagnostikadan boshlang. Natijadan keyin o‘quv reja ochiladi.",minuteShort:"daq.",profile:"Tayyorgarlik sozlamalari",editProfile:"O‘zgartirish",series:"Imtihon sessiyasi",grade:"Maqsadli baho",hours:"Haftalik umumiy o‘qish soati",econHours:"Haftalik iqtisodiyot soati",saveProfile:"Sozlamalarni saqlash",profileInvalid:"Imtihon davri va soatlarni tekshiring: iqtisodiyot soati umumiy vaqtdan oshmasin.",profileSaved:"Sozlamalar saqlandi",optional:"Tayyorgarlik maqsadi va vaqtini belgilang. Avvalgi urinishlar o‘zgarmaydi.",startDiagnostic:"Diagnostikani boshlash",fullPaper:"To‘liq imtihon",entryCheck:"Kirish diagnostikasi",completedCheck:"Diagnostika yakunlandi",repeatCheck:"Diagnostikani takrorlash",history:"Mening urinishlarim",viewResult:"Natijani ko‘rish",continueAttempt:"Davom ettirish",
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
    en:{topicOverview:"Topics to study",chooseLevel:"Choose your level",openLevel:"Open",overview:"Overview",noAttempts:"No attempts yet",afterCheck:"Entry check completed — focus on weaker topics",startHere:"Begin with the entry check",resumeExam:"Resume your work",levelIntro:"The entry check identifies study topics. The full exam is available separately.",openLesson:"Study this topic",viewUnits:"Results by unit",nextLesson:"Next topic",showMore:"Show more",viewHistory:"Attempt history",noHistory:"Completed exams and entry checks will appear here",backToPlan:"Back to study plan",recommended:"Recommended next step",title:"Cambridge Economics · Exam Prep",intro:"Select a level and begin with a short entry check. Your study plan follows the result.",minuteShort:"min",profile:"Preparation settings",editProfile:"Edit",series:"Exam series",grade:"Target grade",hours:"Total weekly study hours",econHours:"Weekly Economics hours",saveProfile:"Save settings",profileInvalid:"Check exam series and weekly hours: Economics time cannot exceed your total study time.",profileSaved:"Settings saved",optional:"Set a preparation goal and study time. Existing attempts will not change.",startDiagnostic:"Start entry check",fullPaper:"Full exam",entryCheck:"Entry check",completedCheck:"Entry check completed",repeatCheck:"Repeat entry check",history:"My attempts",viewResult:"View result",continueAttempt:"Continue",
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
    const b=e("button",secondary?"ep-host-btn ep-host-btn-secondary":"ep-host-btn",text);
    b.type="button";b.disabled=state.busy;b.addEventListener("click",fn);return b;
  };
  const shell=()=>{
    if(state.closed||!state.root)return null;
    const root=e("section","ep-host-shell ep-native-economics");
    const top=e("div","ep-native-topbar");
    top.append(e("span","ep-host-kicker","CAMBRIDGE 9708"));
    if(state.view!=="home")top.append(btn("← "+t().back,goBack,true));
    root.append(top,e("h2","ep-host-title",t().title));
    state.root.replaceChildren(root);return root;
  };
  const stop=()=>{if(state.timer!==null){clearInterval(state.timer);state.timer=null;}};
  function unmount(){
    stop();state.token++;state.closed=true;state.root=null;state.shell=null;
    state.id=null;state.paper=null;state.data=null;state.profile=null;state.history=[];state.planData=null;state.view="home";state.busy=false;state.onBack=null;
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
    if(state.view==="plan"||state.view==="exam"){openLevel(state.paper);return;}
    if(["level","settings","history"].includes(state.view)){lobby();return;}
    state.onBack?.();
  }
  function lobby(){
    ++state.token;stop();state.view="home";state.id=null;state.paper=null;
    state.data=null;state.planData=null;state.index=0;
    const view=shell();if(!view)return;
    const hero=e("section","ep-live-dashboard-intro ep-native-dashboard-hero");
    hero.append(e("div","ep-live-dashboard-eyebrow","Cambridge Economics 9708"),
      e("h3","ep-live-dashboard-title",t().chooseLevel),
      e("p","ep-live-dashboard-text",t().intro));
    view.append(hero);
    const grid=e("div","ep-live-grid ep-native-level-grid");
    for(const [code,title,level] of [["P1",t().p1,"AS"],["P3",t().p3,"A"]]){
      if(!state.shell?.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq"))continue;
      const card=e("section","ep-live-card ep-native-level-card");
      card.append(e("div","ep-native-level-eyebrow",level+" Level"),e("h3","",title));
      const status=e("p","ep-native-level-status",t().startHere);
      card.append(status,btn(t().openLevel,()=>openLevel(code)));card.datasetPaper=code;
      grid.append(card);
    }
    view.append(grid);
    const tools=e("div","ep-native-dashboard-tools");
    tools.append(btn(t().profile,openSettings,true),
      btn(t().viewHistory,()=>openHistoryList(),true));
    view.append(tools);
    const meta=e("p","ep-native-dashboard-meta",t().optional);
    view.append(meta);
    loadDashboard(view,grid,meta);
    view.append(btn(t().back,()=>state.onBack?.(),true));
  }
  async function loadDashboard(view,grid,meta){
    const token=state.token;
    const [history,profile]=await Promise.all([
      rpc("iclub_exam_native_mcq_history_v1",{p_paper_code:null}),
      rpc("iclub_exam_native_economics_profile_v1",{})
    ]);
    if(state.closed||state.view!=="home"||state.token!==token||
       state.root?.firstElementChild!==view)return;
    if(history.ok&&Array.isArray(history.sessions))state.history=history.sessions;
    if(profile.ok){state.profile=profile.profile||null;
      if(state.profile)meta.textContent=[
        state.profile.exam_series,t().grade+": "+state.profile.target_grade,
        t().econHours+": "+state.profile.economics_hours_budget
      ].join(" · ");
    }
    for(const card of grid.children){
      const code=card.datasetPaper;
      const recent=state.history.filter(x=>x.paper_code===code);
      const active=recent.find(x=>x.status==="active");
      const diag=recent.find(x=>x.session_kind==="diagnostic"&&x.status==="finalized");
      const label=active?t().resumeExam+" · "+String(active.answered||0)+"/"+String(active.total_items||30)
        :diag?t().completedCheck+" · "+diag.score+"/12":t().startHere;
      const status=card.querySelector?.(".ep-native-level-status");
      if(status)status.textContent=label;
    }
  }
  function openLevel(code){
    if(state.closed||state.busy||!["P1","P3"].includes(code))return;
    ++state.token;stop();state.view="level";state.paper=code;
    const view=shell();if(!view)return;
    view.append(e("h3","ep-native-page-heading",code==="P1"?t().p1:t().p3));
    view.append(e("p","ep-host-note",t().levelIntro));
    const entries=state.history.filter(x=>x.paper_code===code);
    const active=entries.find(x=>x.status==="active");
    const completed=entries.find(x=>x.session_kind==="diagnostic"&&x.status==="finalized");
    const latestPaper=entries.find(x=>x.session_kind==="paper"&&x.status==="finalized");
    const block=e("section","ep-live-card ep-native-next-card");
    block.append(e("div","ep-native-level-eyebrow",t().recommended));
    const title=active?t().resumeExam:completed?t().afterCheck:t().startHere;
    block.append(e("h3","",title));
    const extra=active?(active.session_kind==="diagnostic"?t().entryCheck:t().fullPaper)+
      " · "+active.answered+"/"+(active.total_items||30)
      :completed?t().entryCheck+" · "+completed.score+"/12":
      t().entryCheck+" · 12 MCQ · 20 "+t().minuteShort;
    block.append(e("p","ep-host-note",extra));
    if(active)block.append(btn(t().continueAttempt,()=>openHistory(active,false)));
    else if(completed)block.append(btn(t().plan,()=>openHistory(completed,true)));
    else block.append(btn(t().startDiagnostic,()=>begin(code,"diagnostic")));
    view.append(block);
    const other=e("div","ep-native-level-actions");
    if(completed)other.append(btn(t().repeatCheck,()=>begin(code,"diagnostic"),true));
    other.append(btn(t().fullPaper,()=>begin(code,"paper"),true));
    if(latestPaper)other.append(btn(t().viewResult,()=>openHistory(latestPaper,false),true));
    other.append(btn(t().viewHistory,()=>openHistoryList(code),true));
    view.append(other);
  }
  function openHistoryList(code=null,limit=8){
    if(state.closed||state.busy)return;
    ++state.token;stop();state.view="history";
    const view=shell();if(!view)return;
    view.append(e("h3","ep-native-page-heading",t().viewHistory));
    const entries=state.history.filter(x=>!code||x.paper_code===code);
    if(!entries.length){view.append(e("p","ep-host-note",t().noHistory));return;}
    const list=e("div","ep-native-history-list");
    for(const entry of entries.slice(0,limit)){
      if(!["P1","P3"].includes(entry.paper_code)||!entry.session_id)continue;
      const card=e("section","ep-native-history-item");
      const date=new Date(entry.started_at);
      const dateText=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
        state.lang==="uz"?"uz-UZ":state.lang==="en"?"en-GB":"ru-RU",
        {day:"2-digit",month:"2-digit",year:"numeric"}).format(date);
      const title=(entry.paper_code==="P1"?t().p1:t().p3)+" · "+
        (entry.session_kind==="diagnostic"?t().entryCheck:t().fullPaper);
      const total=Number(entry.total_items||30);
      card.append(e("div","ep-native-history-info",title+" · "+dateText+" · "+
        (entry.status==="finalized"?entry.score:entry.answered)+"/"+total));
      const actions=e("div","ep-native-history-controls");
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
    const panel=e("section","ep-live-card ep-native-profile");
    view.append(panel);editProfile(panel,view);
  }

  function editProfile(target,view){
    if(state.closed||state.root?.firstElementChild!==view)return;
    target.replaceChildren(e("strong","",t().profile));
    const fields={};
    const addField=(key,label,value,type="text")=>{
      const line=e("label","ep-native-profile-field");
      line.append(e("span","",label));
      let input=e("input");input.type=type;input.value=value??"";input.name=key;
      if(type==="number"){input.min="0.5";input.max="168";input.step="0.5";}
      if(type==="text"){input.maxLength=80;input.placeholder="Oct/Nov 2027";}
      if(key==="target"){input=e("select");input.name=key;
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
    if(!v.ok||!v.session_id){error(()=>begin(code));return;}
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
    header.append(e("strong","",(state.paper==="P1"?t().p1:t().p3)+(data.session_kind==="diagnostic"?" · "+t().entryCheck:"")));
    const remaining=e("span","ep-native-timer");
    header.append(remaining);view.append(header);
    if(finished){
      const resultActions=e("div","ep-native-result-actions");
      resultActions.append(e("h3","ep-native-result",t().result+": "+data.score+" / "+total));
      resultActions.append(btn(t().plan,showStudyPlan));
      view.append(resultActions);
    }else clock(remaining);
    const row=data.items[state.index];if(!row)return;
    view.append(e("div","ep-native-progress",t().question+" "+(state.index+1)+" / "+total+" · "+data.items.filter(x=>x.answered).length+" / "+total));
    const card=e("div","ep-live-card ep-native-question");
    card.append(e("div","ep-native-stem",row.question));
    const options=e("div","ep-native-options");
    row.options.forEach((option,idx)=>{
      const line=e("label","ep-native-option");
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
      if(row.explanation)card.append(e("p","ep-native-explanation",row.explanation));
    }
    view.append(card);
    const actions=e("div","ep-host-actions ep-native-actions");
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
    const stats=e("div","ep-native-plan-stats");
    for(const [amount,label] of [
      [String(data.score)+"/"+String(data.out_of||30),t().result],
      [Math.max(0,Number(data.weak_count||0)-Number(data.retested_correct_count||0)),t().mistakes],
      [data.studied_count,t().studied],
      [data.retested_correct_count,t().verified]
    ]){
      const box=e("div","ep-native-plan-stat");
      box.append(e("strong","",amount),e("span","",label));stats.append(box);
    }
    view.append(stats);
    const topics=Array.isArray(data.priorities)?data.priorities:[];
    if(Number(data.weak_count||0)===0)view.append(e("p","ep-host-note",t().allCorrect));
    else if(!topics.length)view.append(e("p","ep-host-note",t().verified));
    else {
      const focus=e("section","ep-live-card ep-native-plan-focus");
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
          const item=e("div","ep-native-plan-topic");
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
    const actions=e("div","ep-host-actions ep-native-actions");
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
    const body=e("section","ep-live-card ep-native-single-lesson");
    if(task.lesson){
      body.append(e("h4","ep-native-study-label",t().study));
      body.append(e("p","ep-native-study-text",task.lesson));
    }
    if(task.common_trap){
      body.append(e("h4","ep-native-study-label",t().trap));
      body.append(e("p","ep-native-study-trap",task.common_trap));
    }
    if(task.check_question){
      body.append(e("h4","ep-native-study-label",t().check));
      body.append(e("p","ep-native-study-text",task.check_question));
      if(task.check_answer){
        const answer=e("p","ep-native-check-answer",task.check_answer);
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
    const actions=e("div","ep-host-actions ep-native-actions");
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
    if(!state.closed&&state.id===sessionId&&state.data?.status==="finalized")
      await showStudyPlan();
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