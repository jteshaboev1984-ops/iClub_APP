(() => {
  "use strict";
  // Separate 9701 ENTRY screen inside the same native Exam Prep host.
  // Learner endpoints must all return ok=true; no client-side marking or saved keys.
  const internal = window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {};
  const state={root:null,shell:null,lang:"ru",session:null,data:null,index:0,closed:true,
    busy:false,seq:0,timer:null,navOpen:false,onBack:null,onPaper:null,localeQueued:false};
  const copy={
    ru:{title:"Chemistry · Входная проверка",intro:"22 вопроса · 30 минут. Это первая ориентировочная проверка, а не экзамен Paper 1.",
      limitation:"Один вопрос по теме не позволяет достоверно определить её освоение.",
      start:"Начать или продолжить",history:"Мои проверки",empty:"Проверок пока нет.",
      resume:"Продолжить",see:"Посмотреть результат",completedNote:"Повторная проверка на этих же вопросах не проводится. Новый набор появится после обновления заданий.",paper:"Перейти к Paper 1",
      back:"К предмету",loading:"Загрузка…",error:"Данные недоступны. Проверьте соединение.",
      retry:"Повторить",question:"Вопрос",answered:"Ответов",time:"Осталось",
      map:"Выбрать вопрос",unanswered:"Без ответа",prev:"Назад",next:"Далее",
      finish:"Завершить проверку",confirm:"Завершить проверку? Пропущенных вопросов: ",
      result:"Результат",correct:"Правильный ответ",your:"Ваш ответ",
      noanswer:"Не отвечено",review:"Что изучить дальше",
      focus:"Темы для повторения",all:"Результат по всем 22 темам",
      openSubject:"К учебным материалам предмета",
      topicSkipped:"Пропущено",topicWrong:"Есть ошибка",topicOK:"Верный ответ",
      route:"Вернитесь к учебным материалам Chemistry, чтобы повторить эти темы, затем проверьте себя на новых заданиях.",
      noErrors:"Ошибок в этой проверке нет. Это ещё не подтверждает полное освоение тем.",
      reviewError:"Не удалось загрузить учебный маршрут.",notCalibrated:"Результат ориентировочный: подготовленное задание на тему не является полноценной диагностикой.",
      viewPaper:"Paper 1 — экзамен",backResult:"К результату",studyLesson:"Изучить тему",startRecheck:"Повторная проверка · новые задания",backTopics:"К списку тем",lessonUnavailable:"Урок пока недоступен. Он откроется после публикации материалов.",lessonNotMastery:"Изучение этой темы не начисляет освоение автоматически."},
    uz:{title:"Chemistry · Kirish tekshiruvi",intro:"22 ta savol · 30 daqiqa. Bu dastlabki yo‘naltiruvchi tekshiruv, Paper 1 imtihoni emas.",
      limitation:"Har bir mavzudagi bitta savol mavzuni o‘zlashtirishni ishonchli baholay olmaydi.",
      start:"Boshlash yoki davom ettirish",history:"Tekshiruvlarim",empty:"Hali tekshiruvlar yo‘q.",
      resume:"Davom ettirish",see:"Natijani ko‘rish",completedNote:"Ayni savollar bilan qayta tekshiruv o‘tkazilmaydi. Yangi savollar tayyorlanganda yangi tekshiruv ochiladi.",paper:"Paper 1 ga o‘tish",
      back:"Fanga qaytish",loading:"Yuklanmoqda…",error:"Ma’lumotni yuklab bo‘lmadi. Internetni tekshiring.",
      retry:"Qayta urinish",question:"Savol",answered:"Javoblar",time:"Qolgan vaqt",
      map:"Savolni tanlash",unanswered:"Javobsiz",prev:"Oldingi",next:"Keyingi",
      finish:"Tekshiruvni yakunlash",confirm:"Tekshiruvni yakunlaysizmi? Javobsiz savollar: ",
      result:"Natija",correct:"To‘g‘ri javob",your:"Javobingiz",
      noanswer:"Javobsiz",review:"Keyin nimani o‘rganish kerak",
      focus:"Takrorlash kerak bo‘lgan mavzular",all:"22 ta mavzu bo‘yicha natija",
      openSubject:"Fanning o‘quv materiallariga",
      topicSkipped:"Javobsiz",topicWrong:"Xato bor",topicOK:"To‘g‘ri javob",
      route:"Mavzularni takrorlash uchun Chemistry o‘quv materiallariga qayting. Keyin yangi savollar bilan bilimingizni tekshiring.",
      noErrors:"Bu tekshiruvda xato yo‘q. Ammo bu barcha mavzular o‘zlashtirilganini isbotlamaydi.",
      reviewError:"O‘quv yo‘nalishini yuklab bo‘lmadi.",notCalibrated:"Natija taxminiy: har bir mavzudagi bitta savol to‘liq diagnostika hisoblanmaydi.",
      viewPaper:"Paper 1 — imtihon",backResult:"Natijaga qaytish",studyLesson:"Mavzuni o‘rganish",startRecheck:"Qayta tekshiruv · yangi savollar",backTopics:"Mavzular ro‘yxatiga",lessonUnavailable:"Dars hali ochilmagan. Materiallar e’lon qilingach foydalanish mumkin.",lessonNotMastery:"Bu mavzuni o‘qish avtomatik o‘zlashtirish belgisini bermaydi."},
    en:{title:"Chemistry · Entry check",intro:"22 questions · 30 minutes. This is an orientation check, not the Paper 1 exam.",
      limitation:"One question per topic cannot reliably establish mastery.",
      start:"Start or resume",history:"My checks",empty:"No checks yet.",
      resume:"Continue",see:"View result",completedNote:"This set cannot be retaken after answers are revealed. A new check will require fresh questions.",paper:"Go to Paper 1",
      back:"Back to subject",loading:"Loading…",error:"Could not load the data. Check your connection.",
      retry:"Try again",question:"Question",answered:"Answered",time:"Time remaining",
      map:"Choose a question",unanswered:"Unanswered",prev:"Previous",next:"Next",
      finish:"Finish entry check",confirm:"Finish this check? Unanswered questions: ",
      result:"Result",correct:"Correct answer",your:"Your answer",
      noanswer:"Unanswered",review:"What to study next",
      focus:"Topics to review",all:"All 22 topic results",
      openSubject:"Back to subject learning materials",
      topicSkipped:"Unanswered",topicWrong:"Incorrect",topicOK:"Correct",
      route:"Return to Chemistry learning materials to review these topics, then test yourself with fresh questions.",
      noErrors:"No errors in this check. It does not establish full understanding.",
      reviewError:"Could not load the study route.",notCalibrated:"This result is only a guide: one question per topic is not a full diagnosis.",
      viewPaper:"Paper 1 exam",backResult:"Back to result",studyLesson:"Study topic",startRecheck:"Recheck · fresh questions",backTopics:"Back to topics",lessonUnavailable:"This lesson is not yet released. It opens only when the learning material is published.",lessonNotMastery:"Reading this topic does not automatically credit mastery."}
  };
  const t=()=>copy[state.lang]||copy.ru;
  const el=(tag,value,cls)=>{
    const n=document.createElement(tag);
    if(value!==undefined&&value!==null)n.textContent=String(value);
    if(cls)n.className=cls;
    return n;
  };
  function button(text,action,secondary=false){
    const b=el("button",text,secondary?"ep-host-btn ep-host-btn-secondary":"ep-host-btn ep-host-btn-primary");
    b.type="button";b.disabled=state.busy;b.addEventListener("click",action);return b;
  }
  const stopTimer=()=>{if(state.timer!==null)clearInterval(state.timer);state.timer=null;};
  const active=()=>!state.closed&&state.root!==null;
  function unmount(){
    stopTimer();++state.seq;state.closed=true;state.root=null;state.shell=null;state.session=null;
    state.data=null;state.index=0;state.busy=false;state.navOpen=false;state.localeQueued=false;
    state.onBack=null;state.onPaper=null;
  }
  function panel(){
    if(!active())return null;
    const p=el("section",undefined,"ep-host-shell ep-native-economics ep-native-chemistry ep-chem-entry");
    p.append(el("div","Cambridge AS · 9701","ep-host-kicker"),el("h2",t().title,"ep-host-title"));
    state.root.replaceChildren(p);return p;
  }
  async function rpc(name,args={}){
    try{
      if(typeof window.sb?.rpc!=="function")return {ok:false};
      const x=await window.sb.rpc(name,args);
      return !x.error&&x.data?.ok===true?x.data:{ok:false,code:x.data?.code||"network_error"};
    }catch(_){return {ok:false,code:"network_error"};}
  }
  function errorScreen(retry){
    stopTimer();const p=panel();if(!p)return;
    const note=el("p",t().error,"ep-host-note");
    note.setAttribute("role","alert");p.append(note);
    p.append(button(t().retry,retry),button(t().back,()=>state.onBack?.(),true));
  }
  async function lobby(){
    ++state.seq;stopTimer();state.session=null;state.data=null;state.index=0;
    state.navOpen=false;state.localeQueued=false;
    const p=panel();if(!p)return;
    p.append(el("p",t().intro,"ep-host-note"),el("p",t().limitation,"ep-host-note"));
    const card=el("div",undefined,"ep-host-component-card ep-native-paper");
    card.append(el("strong","Entry · 22 / 30 min"),button(t().start,start));
    p.append(card);
    const listing=el("div",undefined,"ep-native-history");p.append(listing);
    const actions=el("div",undefined,"ep-host-actions");
    if(typeof state.onPaper==="function")actions.append(button(t().viewPaper,()=>state.onPaper(),true));
    actions.append(button(t().back,()=>state.onBack?.(),true));p.append(actions);
    const token=state.seq;
    const r=await rpc("iclub_exam_chemistry_entry_history_v1");
    if(!active()||token!==state.seq||p!==state.root?.firstElementChild)return;
    if(!Array.isArray(r.sessions)||!r.sessions.length){
      listing.append(el("p",t().empty,"ep-host-note"));return;
    }
    listing.append(el("h3",t().history,"ep-native-section-title"));
    const list=el("div",undefined,"ep-native-history-list");
    r.sessions.forEach(item=>{
      if(!item.session_id)return;
      const row=el("div",undefined,"ep-native-history-item");
      const d=new Date(item.started_at);
      const label=Number.isNaN(d.getTime())?"":new Intl.DateTimeFormat(state.lang==="uz"?"uz-UZ":state.lang==="ru"?"ru-RU":"en-GB",{day:"2-digit",month:"short",year:"numeric"}).format(d);
      row.append(el("span",label+" · "+(item.status==="finalized"?item.score:item.answered)+" / 22","ep-native-history-info"));
      row.append(button(item.status==="finalized"?t().see:t().resume,()=>{
        state.session=item.session_id;state.index=0;load();
      },true));
      list.append(row);
    });
    listing.append(list);
    if(r.sessions.some(item=>item.status==="finalized")){
      listing.append(el("p",t().completedNote,"ep-host-note"));
      offerRecheck(p,listing);
    }
  }
  function openRecheck(recheckShell){
    if(!active()||recheckShell?.enabled!==true ||
      recheckShell?.program_key!=="chemistry_9701" ||
      recheckShell?.assessment_code!=="RECHECK" ||
      recheckShell?.item_count!==22||recheckShell?.duration_seconds!==1800 ||
      recheckShell?.learning_ack_kind!=="self_report" ||
      recheckShell?.can_credit_mastery!==false ||
      !recheckShell?.entry_session_id ||
      (state.session && recheckShell.entry_session_id!==state.session))return;
    const ctx={root:state.root,shell:state.shell,language:state.lang,
      onBack:state.onBack,onPaper:state.onPaper};
    const adapter=internal.chemistryRecheckNative;
    if(typeof adapter?.mount!=="function")return;
    unmount();
    const ok=adapter.mount({...ctx,shell:recheckShell,
      onBack:()=>{
        const language=adapter.getLanguage?.()||ctx.language;
        adapter.unmount?.();
        internal.chemistryEntryNative?.mount?.({...ctx,language});
      }});
    if(ok!==true)internal.chemistryEntryNative?.mount?.(ctx);
  }
  async function offerRecheck(p,target){
    if(!active()||!p||!target)return;
    const token=state.seq,session=state.session;
    try{
      const response=await window.sb?.rpc?.("get_my_exam_prep_chemistry_recheck_shell_v1",
        {p_language:state.lang});
      if(!active()||token!==state.seq||p!==state.root?.firstElementChild)return;
      const shell=!response?.error?response?.data:null;
      if(shell?.enabled!==true||shell?.assessment_code!=="RECHECK"||
        shell.program_key!=="chemistry_9701"||
        (session&&shell.entry_session_id!==session))return;
      target.append(button(t().startRecheck,()=>openRecheck(shell),true));
    }catch(_){/* Recheck is strictly hidden until server authorises it. */}
  }
  async function start(){
    if(!active()||state.busy)return;
    state.busy=true;const token=++state.seq;
    panel()?.append(el("p",t().loading,"ep-host-note"));
    const nonce=(window.crypto?.randomUUID?.()||
      String(Date.now())+"_"+Math.random().toString(36).slice(2))+"_entry";
    const r=await rpc("iclub_exam_chemistry_entry_start_v1",{p_client_key:nonce});
    if(!active()||token!==state.seq)return;
    state.busy=false;
    if(!r.ok||!r.session_id){errorScreen(start);return;}
    state.session=r.session_id;await load();
  }
  async function load(){
    if(!active()||!state.session)return;
    state.busy=true;const token=++state.seq;
    const r=await rpc("iclub_exam_chemistry_entry_get_v1",{
      p_session_id:state.session,p_language:state.lang});
    if(!active()||token!==state.seq)return;
    state.busy=false;
    if(state.localeQueued){state.localeQueued=false;await load();return;}
    if(!r.ok||!Array.isArray(r.items)||r.items.length!==22){errorScreen(load);return;}
    state.data=r;draw();
  }
  function clock(label){
    stopTimer();
    const paint=()=>{
      if(!active()||state.data?.status!=="active")return;
      const left=Math.max(0,Math.ceil((new Date(state.data.deadline_at).getTime()-Date.now())/1000));
      label.textContent=t().time+": "+String(Math.floor(left/60)).padStart(2,"0")+":"+
        String(left%60).padStart(2,"0");
      if(left===0){stopTimer();finish(true);}
    };
    paint();if(state.data?.status==="active")state.timer=setInterval(paint,1000);
  }
  function draw(){
    ++state.seq;const p=panel(),data=state.data;if(!p||!data)return;
    const done=data.status==="finalized";
    const header=el("div",undefined,"ep-native-header");
    header.append(el("strong","Entry · AS"));
    const timelabel=el("span",undefined,"ep-native-timer");header.append(timelabel);p.append(header);
    if(done){
      p.append(el("h3",t().result+": "+data.score+" / 22","ep-native-result"));
      p.append(el("p",t().notCalibrated,"ep-host-note"));
    }else clock(timelabel);
    const row=data.items[state.index];if(!row)return;
    const nAnswered=data.items.filter(x=>x.answered).length;
    p.append(el("p",t().question+" "+(state.index+1)+" / 22 · "+
      t().answered+": "+nAnswered+" / 22","ep-native-progress"));
    const picker=el("details",undefined,"ep-chem-question-map");
    picker.open=state.navOpen;picker.addEventListener("toggle",()=>{state.navOpen=picker.open;});
    picker.append(el("summary",t().map+" · "+(22-nAnswered)+" "+t().unanswered));
    const grid=el("div",undefined,"ep-chem-question-grid");
    data.items.forEach((item,i)=>{
      const b=button(String(i+1),()=>{if(state.busy)return;state.index=i;draw();},true);
      b.classList.add("ep-chem-question-jump");
      if(item.answered)b.classList.add("is-answered");
      if(i===state.index){b.classList.add("is-current");b.setAttribute("aria-current","step");}
      b.setAttribute("aria-label",t().question+" "+(i+1));
      grid.append(b);
    });
    picker.append(grid);p.append(picker);
    const card=el("div",undefined,"ep-live-card ep-native-question");
    card.append(el("div",row.question,"ep-native-stem"));
    const opts=el("div",undefined,"ep-native-options");
    row.options.forEach((value,i)=>{
      const b=button("ABCD"[i]+". "+value,()=>answer(i),true);
      b.classList.add("ep-native-option");
      b.setAttribute("aria-pressed",String(row.selected_index===i));
      if(row.selected_index===i)b.classList.add("is-selected");
      b.disabled=done||state.busy;opts.append(b);
    });
    card.append(opts);
    if(done){
      card.append(el("p",t().your+": "+
        (Number.isInteger(row.selected_index)?"ABCD"[row.selected_index]:t().noanswer),"ep-native-explanation"));
      card.append(el("p",t().correct+": "+
        (Number.isInteger(row.correct_index)?"ABCD"[row.correct_index]:"—"),"ep-native-explanation"));
      if(row.explanation)card.append(el("p",row.explanation,"ep-native-explanation"));
    }
    p.append(card);
    const actions=el("div",undefined,"ep-host-actions");
    if(state.index>0)actions.append(button(t().prev,()=>{if(state.busy)return;state.index--;draw();},true));
    if(state.index<21)actions.append(button(t().next,()=>{if(state.busy)return;state.index++;draw();},true));
    if(!done)actions.append(button(t().finish,()=>finish(false)));
    else actions.append(button(t().review,review));
    actions.append(button(t().back,()=>state.onBack?.(),true));p.append(actions);
  }
  async function answer(choice){
    if(!active()||state.busy||state.data?.status!=="active")return;
    state.busy=true;const token=state.seq,index=state.index,id=state.session;
    const r=await rpc("iclub_exam_chemistry_entry_answer_v1",{
      p_session_id:id,p_item_order:index+1,p_choice:choice});
    if(!active()||token!==state.seq||id!==state.session)return;
    state.busy=false;
    if(!r.ok){
      state.localeQueued=false;
      if(r.code==="attempt_closed_or_expired"){await finish(true);return;}
      errorScreen(load);return;
    }
    state.data.items[index].selected_index=choice;state.data.items[index].answered=true;
    let next=state.data.items.findIndex((x,i)=>i>index&&!x.answered);
    if(next<0)next=state.data.items.findIndex(x=>!x.answered);
    state.index=next<0?index:next;
    if(state.localeQueued){state.localeQueued=false;await load();return;}
    draw();
  }
  async function finish(auto){
    if(!active()||state.busy||state.data?.status!=="active")return;
    const misses=state.data.items.filter(x=>!x.answered).length;
    if(!auto&&!window.confirm(t().confirm+misses))return;
    stopTimer();state.busy=true;const token=state.seq,id=state.session;
    const r=await rpc("iclub_exam_chemistry_entry_finish_v1",{p_session_id:id});
    if(!active()||token!==state.seq||id!==state.session)return;
    state.busy=false;if(!r.ok){errorScreen(load);return;}
    state.localeQueued=false;await load();
  }
  async function review(){
    if(!active()||state.busy||state.data?.status!=="finalized")return;
    state.busy=true;const token=++state.seq,id=state.session;
    panel()?.append(el("p",t().loading,"ep-host-note"));
    const r=await rpc("iclub_exam_chemistry_entry_review_v1",
      {p_session_id:id,p_language:state.lang});
    if(!active()||token!==state.seq||id!==state.session)return;
    state.busy=false;
    if(!r.ok||r.calibrated_diagnostic!==false||r.can_credit_mastery!==false
      ||!Array.isArray(r.topics)||r.topics.length!==22){
      const p=panel();if(!p)return;
      const err=el("p",t().reviewError,"ep-host-note");
      err.setAttribute("role","alert");p.append(err);
      p.append(button(t().backResult,draw,true),button(t().retry,review));return;
    }
    const p=panel();if(!p)return;
    p.append(el("h3",t().review,"ep-native-result"),
      el("p",t().limitation,"ep-host-note"));
    const focus=el("section",undefined,"ep-chem-review-focus");
    focus.append(el("h4",t().focus,"ep-chem-review-title"));
    const need=r.topics.filter(item=>item.review_needed===true);
    if(!need.length)focus.append(el("p",t().noErrors,"ep-host-note"));
    else need.forEach(item=>{
      const card=el("div",undefined,"ep-chem-review-row");
      card.append(el("strong",item.unit+". "+item.title));
      card.append(el("span",item.answered?t().topicWrong:t().topicSkipped,"ep-chem-review-counts"));
      if(item.lesson_available===true && item.skill_key)
        card.append(button(t().studyLesson,()=>showLesson(item.skill_key),true));
      focus.append(card);
    });
    p.append(focus);
    const other=el("details",undefined,"ep-chem-review-all");
    other.append(el("summary",t().all));
    const all=el("div",undefined,"ep-chem-review-list");
    r.topics.forEach(item=>{
      const block=el("div",undefined,"ep-chem-review-row");
      block.append(el("strong",item.unit+". "+item.title));
      block.append(el("span",item.review_needed?(item.answered?t().topicWrong:t().topicSkipped):t().topicOK,
        "ep-chem-review-counts"));
      if(item.lesson_available===true && item.skill_key)
        block.append(button(t().studyLesson,()=>showLesson(item.skill_key),true));
      all.append(block);
    });
    other.append(all);p.append(other);
    p.append(el("p",t().route,"ep-host-note"));
    const actions=el("div",undefined,"ep-host-actions");
    actions.append(button(t().openSubject,()=>state.onBack?.()),
      button(t().backResult,draw,true));
    if(typeof state.onPaper==="function")
      actions.append(button(t().viewPaper,()=>state.onPaper(),true));
    p.append(actions);
    offerRecheck(p,actions);
  }
  async function showLesson(skillKey){
    if(!active()||state.busy||state.data?.status!=="finalized"||!state.session
      ||typeof skillKey!=="string"||!/^CHEM9701-[0-9]{2}-[0-9]{2}$/.test(skillKey))return;
    state.busy=true;
    const token=++state.seq,session=state.session;
    const p=panel();if(!p)return;
    p.append(el("p",t().loading,"ep-host-note"));
    const result=await rpc("iclub_exam_chemistry_entry_lesson_v1",{
      p_session_id:session,p_skill_key:skillKey,p_language:state.lang
    });
    if(!active()||token!==state.seq||session!==state.session)return;
    state.busy=false;
    const view=panel();if(!view)return;
    if(!result.ok||result.skill_key!==skillKey
      ||result.ai_tutor_content_included!==false
      ||result.can_credit_mastery!==false
      ||typeof result.explanation!=="string"
      ||result.explanation.length<30){
      const note=el("p",t().lessonUnavailable,"ep-host-note");
      note.setAttribute("role","alert");
      view.append(note,button(t().backTopics,review,true));
      return;
    }
    view.append(el("h3",result.title,"ep-native-result"),
      el("p",result.explanation,"ep-chem-entry-theory"),
      el("p",t().lessonNotMastery,"ep-host-note"));
    const actions=el("div",undefined,"ep-host-actions");
    actions.append(button(t().backTopics,review,true),
      button(t().openSubject,()=>state.onBack?.(),true));
    view.append(actions);
  }
  function mount({root,shell,language,onBack,onPaper}={}){
    unmount();
    if(!root||shell?.enabled!==true||shell.program_key!=="chemistry_9701"
      ||shell.assessment_code!=="ENTRY"||shell.item_count!==22
      ||shell.duration_seconds!==1800)return false;
    state.root=root;state.shell=shell;
    state.lang=["ru","uz","en"].includes(language)?language:"ru";
    state.onBack=onBack;state.onPaper=onPaper;state.closed=false;
    lobby();return true;
  }
  function setLanguage(lang){
    if(!["ru","uz","en"].includes(lang)||lang===state.lang)return;
    state.lang=lang;if(!active())return;
    if(state.busy){state.localeQueued=true;return;}
    if(state.session)load();else lobby();
  }
  internal.chemistryEntryNative=Object.freeze({mount,unmount,setLanguage,
    isMounted:()=>active()});
})();