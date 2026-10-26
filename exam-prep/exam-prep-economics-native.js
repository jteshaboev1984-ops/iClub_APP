(() => {
  "use strict";
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const state = {root:null,shell:null,lang:"ru",id:null,paper:null,data:null,index:0,timer:null,busy:false,closed:true,onBack:null,token:0};
  const dictionary={
    ru:{title:"Cambridge Economics · Exam Prep",intro:"Выберите уровень и начните с короткой диагностики. После результата откроется учебный план.",minuteShort:"мин",profile:"Настройка подготовки",editProfile:"Изменить",series:"Экзаменационная сессия",grade:"Целевая оценка",hours:"Всего часов на учёбу в неделю",econHours:"Часов на экономику в неделю",saveProfile:"Сохранить настройки",profileInvalid:"Проверьте экзаменационную сессию и количество часов: время на экономику не должно превышать общее время.",profileSaved:"Настройки сохранены",optional:"Настройте цель и время подготовки. Уже сохранённые попытки не изменятся.",startDiagnostic:"Начать диагностику",fullPaper:"Полный экзамен",entryCheck:"Входная диагностика",completedCheck:"Диагностика завершена",repeatCheck:"Повторить диагностику",history:"Мои попытки",viewResult:"Посмотреть результат",continueAttempt:"Продолжить",
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
    uz:{title:"Cambridge Economics · Exam Prep",intro:"Darajani tanlang va qisqa diagnostikadan boshlang. Natijadan keyin o‘quv reja ochiladi.",minuteShort:"daq.",profile:"Tayyorgarlik sozlamalari",editProfile:"O‘zgartirish",series:"Imtihon sessiyasi",grade:"Maqsadli baho",hours:"Haftalik umumiy o‘qish soati",econHours:"Haftalik iqtisodiyot soati",saveProfile:"Sozlamalarni saqlash",profileInvalid:"Imtihon davri va soatlarni tekshiring: iqtisodiyot soati umumiy vaqtdan oshmasin.",profileSaved:"Sozlamalar saqlandi",optional:"Tayyorgarlik maqsadi va vaqtini belgilang. Avvalgi urinishlar o‘zgarmaydi.",startDiagnostic:"Diagnostikani boshlash",fullPaper:"To‘liq imtihon",entryCheck:"Kirish diagnostikasi",completedCheck:"Diagnostika yakunlandi",repeatCheck:"Diagnostikani takrorlash",history:"Mening urinishlarim",viewResult:"Natijani ko‘rish",continueAttempt:"Davom ettirish",
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
    en:{title:"Cambridge Economics · Exam Prep",intro:"Select a level and begin with a short entry check. Your study plan follows the result.",minuteShort:"min",profile:"Preparation settings",editProfile:"Edit",series:"Exam series",grade:"Target grade",hours:"Total weekly study hours",econHours:"Weekly Economics hours",saveProfile:"Save settings",profileInvalid:"Check exam series and weekly hours: Economics time cannot exceed your total study time.",profileSaved:"Settings saved",optional:"Set a preparation goal and study time. Existing attempts will not change.",startDiagnostic:"Start entry check",fullPaper:"Full paper",entryCheck:"Entry check",completedCheck:"Entry check completed",repeatCheck:"Repeat entry check",history:"My attempts",viewResult:"View result",continueAttempt:"Continue",
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
    root.append(e("div","ep-host-kicker","Cambridge 9708"),e("h2","ep-host-title",t().title));
    state.root.replaceChildren(root);return root;
  };
  const stop=()=>{if(state.timer!==null){clearInterval(state.timer);state.timer=null;}};
  function unmount(){
    stop();state.token++;state.closed=true;state.root=null;state.shell=null;
    state.id=null;state.paper=null;state.data=null;state.profile=null;state.busy=false;state.onBack=null;
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
  function lobby(){
    ++state.token;
    stop();state.id=null;state.paper=null;state.data=null;state.index=0;
    const view=shell();if(!view)return;
    view.append(e("p","ep-host-note",t().intro));
    view.append(e("p","ep-native-guidance",t().p1+" · "+t().p3));
    const profileTarget=e("section","ep-native-profile");
    view.append(profileTarget);loadProfile(profileTarget,view);
    const grid=e("div","ep-host-component-grid ep-native-guided-grid"),cards=new Map();
    for(const [code,label] of [["P1",t().p1],["P3",t().p3]]){
      if(!state.shell?.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq"))continue;
      const card=e("div","ep-host-component-card ep-native-paper");
      card.append(e("strong","",label));
      const summary=e("p","ep-native-guidance",t().entryCheck+" · 12 MCQ · 20 min");
      const actions=e("div","ep-native-paper-actions");
      actions.append(btn(t().startDiagnostic,()=>begin(code,"diagnostic")));
      actions.append(btn(t().fullPaper,()=>begin(code),true));
      card.append(summary,actions);cards.set(code,{actions,summary});grid.append(card);
    }
    view.append(grid);
    const historyBox=e("div","ep-native-history");
    view.append(historyBox);
    loadHistory(historyBox,view,cards);
    const actions=e("div","ep-host-actions");
    actions.append(btn(t().back,()=>state.onBack?.(),true));view.append(actions);
  }
  async function loadHistory(target,view,cards){
    const response=await rpc("iclub_exam_native_mcq_history_v1",{p_paper_code:null});
    if(state.closed||state.root?.firstElementChild!==view||!response.ok||
       !Array.isArray(response.sessions)||response.sessions.length===0)return;
    for(const [code,parts] of (cards||new Map())){
      const latest=response.sessions.find(x=>x.paper_code===code&&x.session_kind==="diagnostic");
      if(!latest)continue;
      parts.actions.replaceChildren();
      if(latest.status==="active"){
        parts.summary.textContent=t().entryCheck+" · "+latest.answered+" / 12";
        parts.actions.append(btn(t().continueAttempt,()=>openHistory(latest,false)));
      }else{
        parts.summary.textContent=t().completedCheck+" · "+latest.score+" / 12";
        parts.actions.append(btn(t().plan,()=>openHistory(latest,true)));
        parts.actions.append(btn(t().repeatCheck,()=>begin(code,"diagnostic"),true));
      }
      parts.actions.append(btn(t().fullPaper,()=>begin(code),true));
    }
    target.replaceChildren(e("h3","ep-native-section-title",t().history));
    const list=e("div","ep-native-history-list");
    response.sessions.forEach(entry=>{
      if(!["P1","P3"].includes(entry.paper_code)||!entry.session_id)return;
      const card=e("div","ep-native-history-item");
      const title=(entry.paper_code==="P1"?t().p1:t().p3)+(entry.session_kind==="diagnostic"?" · "+t().entryCheck:"");
      const date=new Date(entry.started_at);
      const dateText=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
        state.lang==="uz"?"uz-UZ":state.lang==="en"?"en-GB":"ru-RU",
        {day:"2-digit",month:"2-digit",year:"numeric"}).format(date);
      const total=Number(entry.total_items||30);
      const result=entry.status==="finalized"?
        (String(entry.score)+" / "+total):(String(entry.answered)+" / "+total);
      card.append(e("div","ep-native-history-info",title+" · "+dateText+" · "+result));
      const controls=e("div","ep-native-history-controls");
      controls.append(btn(entry.status==="finalized"?t().viewResult:t().continueAttempt,
        ()=>openHistory(entry,false),true));
      if(entry.status==="finalized")controls.append(btn(t().plan,
        ()=>openHistory(entry,true)));
      card.append(controls);
      list.append(card);
    });
    target.append(list);
  }
  async function loadProfile(target,view){
    const result=await rpc("iclub_exam_native_economics_profile_v1",{});
    if(state.closed||state.root?.firstElementChild!==view||!result.ok)return;
    state.profile=result.profile||null;
    renderProfile(target,view);
  }
  function renderProfile(target,view){
    if(state.closed||state.root?.firstElementChild!==view)return;
    target.replaceChildren();
    const head=e("div","ep-native-profile-head");
    head.append(e("strong","",t().profile));
    if(state.profile)head.append(btn(t().editProfile,()=>editProfile(target,view),true));
    target.append(head);
    const profile=state.profile;
    if(!profile){
      target.append(e("p","ep-native-guidance",t().optional));
      target.append(btn(t().profile,()=>editProfile(target,view),true));
    }else{
      const summary=e("div","ep-native-profile-summary");
      summary.append(e("span","",t().series+": "+profile.exam_series));
      summary.append(e("span","",t().grade+": "+profile.target_grade));
      summary.append(e("span","",t().econHours+": "+profile.economics_hours_budget));
      target.append(summary);
    }
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
      renderProfile(target,view);
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
    const token=++state.token;state.busy=true;
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
    ++state.token;
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
    const view=shell();if(!view)return;
    view.append(e("h3","ep-native-result",t().plan));
    view.append(e("p","ep-host-note",t().planIntro));
    if(data.weekly_economics_hours)view.append(e("p","ep-native-guidance",t().econHours+": "+data.weekly_economics_hours));
    const stats=e("div","ep-native-plan-stats");
    for(const [amount,label] of [
      [String(data.score)+"/"+String(data.out_of||30),t().result],
      [Math.max(0,Number(data.weak_count||0)-Number(data.retested_correct_count||0)),t().mistakes],
      [data.studied_count,t().studied],
      [data.retested_correct_count,t().verified]
    ]){
      const stat=e("div","ep-native-plan-stat");
      stat.append(e("strong","",amount),e("span","",label));stats.append(stat);
    }
    view.append(stats);
    const unitTitle=e("h4","ep-native-section-title",t().unit);
    view.append(unitTitle);
    const summary=e("div","ep-native-plan-units");
    (data.unit_results||[]).forEach(unit=>{
      const block=e("div","ep-native-plan-unit");
      block.append(e("span","",t().unit+" "+unit.unit),
        e("strong","",String(unit.correct)+" / "+String(unit.total)));
      summary.append(block);
    });
    view.append(summary);
    if(data.weak_count===0)view.append(e("p","ep-host-note",t().allCorrect));
    else if((data.priorities||[]).length===0)view.append(e("p","ep-host-note",t().verified));
    else {
      const tasks=e("div","ep-native-study-tasks");
      data.priorities.forEach(task=>{
        const card=e("section","ep-native-study-task");
        const head=e("div","ep-native-study-head");
        head.append(e("span","ep-native-study-day",t().day+" "+task.suggested_day));
        head.append(e("span","ep-native-study-day",String(data.suggested_minutes_per_topic||20)+" "+t().minuteShort));
        head.append(e("strong","",task.title));
        card.append(head);
        if(task.lesson){
          card.append(e("div","ep-native-study-label",t().study));
          card.append(e("p","ep-native-study-text",task.lesson));
        }
        if(task.common_trap){
          card.append(e("div","ep-native-study-label",t().trap));
          card.append(e("p","ep-native-study-trap",task.common_trap));
        }
        if(task.check_question){
          card.append(e("div","ep-native-study-label",t().check));
          card.append(e("p","ep-native-study-text",task.check_question));
          if(task.check_answer){
            const answer=e("p","ep-native-check-answer",task.check_answer);
            answer.hidden=true;
            const toggle=btn(t().showCheck,()=>{
              answer.hidden=!answer.hidden;
              toggle.textContent=answer.hidden?t().showCheck:t().hideCheck;
            },true);
            card.append(toggle,answer);
          }
        }
        if(task.studied)card.append(e("div","ep-native-study-done",t().studiedDone));
        else card.append(btn(t().markStudied,()=>markStudied(task.skill_key)));
        tasks.append(card);
      });
      view.append(tasks);
    }
    view.append(e("p","ep-host-note",t().studyNote));
    const actions=e("div","ep-host-actions ep-native-actions");
    actions.append(btn(t().backReview,draw,true));
    actions.append(btn(data.session_kind==="diagnostic"?t().repeatCheck:t().retest,
      ()=>begin(state.paper,data.session_kind||"paper")));
    if(data.session_kind==="diagnostic")
      actions.append(btn(t().fullPaper,()=>begin(state.paper),true));
    actions.append(btn(t().papers,lobby,true));
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