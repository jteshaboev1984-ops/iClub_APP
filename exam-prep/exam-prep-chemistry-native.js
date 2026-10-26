(() => {
  "use strict";
  const internal = window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {};
  const state = {root:null,lang:"ru",shell:null,session:null,data:null,index:0,closed:true,
    busy:false,timer:null,seq:0,onBack:null};
  const copy = {
    ru:{title:"Cambridge AS Chemistry · Exam Prep",paper:"Paper 1 · Выбор ответа",
      intro:"40 вопросов · 75 минут. Результаты сохраняются на сервере.",
      begin:"Начать или продолжить",history:"Мои попытки",resume:"Продолжить",
      resultView:"Посмотреть результат",back:"Назад",loading:"Загрузка…",
      error:"Не удалось выполнить действие. Проверьте соединение.",retry:"Повторить",
      question:"Вопрос",answered:"Отвечено",time:"Осталось времени",
      prev:"Предыдущий",next:"Следующий",finish:"Завершить работу",
      confirm:"Завершить работу? Неотвеченные вопросы принесут 0 баллов.",
      result:"Результат",your:"Ваш ответ",right:"Правильный ответ",missing:"Без ответа",
      return:"К выбору экзамена",again:"Новая попытка",empty:"Пока нет попыток.",
      note:"Результат относится только к вопросам с выбором ответа."},
    uz:{title:"Cambridge AS Chemistry · Exam Prep",paper:"Paper 1 · Test savollari",
      intro:"40 ta savol · 75 daqiqa. Natijalar serverda saqlanadi.",
      begin:"Boshlash yoki davom ettirish",history:"Urinishlarim",resume:"Davom ettirish",
      resultView:"Natijani ko‘rish",back:"Orqaga",loading:"Yuklanmoqda…",
      error:"Amal bajarilmadi. Internetni tekshiring.",retry:"Qayta urinish",
      question:"Savol",answered:"Javob berildi",time:"Qolgan vaqt",
      prev:"Oldingi",next:"Keyingi",finish:"Ishni yakunlash",
      confirm:"Ishni yakunlaysizmi? Javobsiz savollar uchun 0 ball beriladi.",
      result:"Natija",your:"Javobingiz",right:"To‘g‘ri javob",missing:"Javobsiz",
      return:"Imtihon tanlashga",again:"Yangi urinish",empty:"Hali urinishlar yo‘q.",
      note:"Natija faqat test savollariga tegishli."},
    en:{title:"Cambridge AS Chemistry · Exam Prep",paper:"Paper 1 · Multiple choice",
      intro:"40 questions · 75 minutes. Results are saved on the server.",
      begin:"Start or resume",history:"My attempts",resume:"Continue",
      resultView:"View result",back:"Back",loading:"Loading…",
      error:"The action failed. Check your connection.",retry:"Try again",
      question:"Question",answered:"Answered",time:"Time remaining",
      prev:"Previous",next:"Next",finish:"Finish paper",
      confirm:"Finish the paper? Unanswered questions score zero.",
      result:"Result",your:"Your answer",right:"Correct answer",missing:"Unanswered",
      return:"Back to papers",again:"New attempt",empty:"No attempts yet.",
      note:"This result covers multiple-choice questions only."}
  };
  const t = () => copy[state.lang] || copy.ru;
  const el = (tag,text,cls) => {
    const n=document.createElement(tag);
    if(cls)n.className=cls;
    if(text!==undefined&&text!==null)n.textContent=String(text);
    return n;
  };
  const button = (text,fn,secondary) => {
    const b=el("button",text,secondary?"ep-host-btn ep-host-btn-secondary":"ep-host-btn ep-host-btn-primary");
    b.type="button";b.disabled=state.busy;b.addEventListener("click",fn);return b;
  };
  function stopTimer() {if(state.timer!==null)clearInterval(state.timer);state.timer=null;}
  function unmount() {
    stopTimer();state.seq+=1;state.closed=true;state.root=null;state.shell=null;
    state.session=null;state.data=null;state.busy=false;state.index=0;state.onBack=null;
  }
  function panel() {
    if(state.closed||!state.root)return null;
    const s=el("section",undefined,"ep-host-shell ep-native-economics ep-native-chemistry");
    s.append(el("div","Cambridge 9701","ep-host-kicker"),el("h2",t().title,"ep-host-title"));
    state.root.replaceChildren(s);return s;
  }
  async function rpc(name,args={}) {
    try {
      if(typeof window.sb?.rpc!=="function")return {ok:false};
      const r=await window.sb.rpc(name,args);
      return !r.error&&r.data?.ok===true?r.data:{ok:false};
    }catch(_){return {ok:false};}
  }
  function showError(retry) {
    stopTimer();
    const p=panel();if(!p)return;
    const n=el("p",t().error,"ep-host-note");n.setAttribute("role","alert");
    const actions=el("div",undefined,"ep-host-actions");
    actions.append(button(t().retry,retry),button(t().return,lobby,true));
    p.append(n,actions);
  }
  async function lobby() {
    state.seq+=1;stopTimer();state.session=null;state.data=null;state.index=0;
    const p=panel();if(!p)return;
    p.append(el("p",t().intro,"ep-host-note"));
    const card=el("div",undefined,"ep-host-component-card ep-native-paper");
    card.append(el("strong",t().paper),el("span","40 MCQ · 75 min"),
      button(t().begin,begin));
    const grid=el("div",undefined,"ep-host-component-grid");
    grid.append(card);p.append(grid);
    const history=el("div",undefined,"ep-native-history");p.append(history);
    const actions=el("div",undefined,"ep-host-actions");
    actions.append(button(t().back,()=>state.onBack?.(),true));p.append(actions);
    const n=state.seq, r=await rpc("iclub_exam_chemistry_p1_history_v1");
    if(state.closed||n!==state.seq||p!==state.root?.firstElementChild)return;
    if(!r.ok||!Array.isArray(r.sessions)||!r.sessions.length){
      history.append(el("p",t().empty,"ep-host-note"));return;
    }
    history.append(el("h3",t().history,"ep-native-section-title"));
    const list=el("div",undefined,"ep-native-history-list");
    r.sessions.forEach(item=>{
      if(item.paper_code!=="P1"||!item.session_id)return;
      const row=el("div",undefined,"ep-native-history-item");
      const date=new Date(item.started_at);
      const dt=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
        state.lang==="uz"?"uz-UZ":state.lang==="en"?"en-GB":"ru-RU",
        {day:"2-digit",month:"short",year:"numeric"}).format(date);
      row.append(el("span",t().paper+" · "+dt+" · "+
        (item.status==="finalized"?item.score:item.answered)+" / 40",
        "ep-native-history-info"));
      row.append(button(item.status==="finalized"?t().resultView:t().resume,()=>{
        state.session=item.session_id;state.index=0;load();
      },true));
      list.append(row);
    });
    history.append(list);
  }
  async function begin() {
    if(state.closed||state.busy)return;
    state.busy=true;const n=++state.seq;panel()?.append(el("p",t().loading,"ep-host-note"));
    const nonce=(window.crypto?.randomUUID?.()||
      String(Date.now())+"_"+Math.random().toString(36).slice(2))+"_chem";
    const r=await rpc("iclub_exam_chemistry_p1_start_v1",{p_client_key:nonce});
    if(state.closed||n!==state.seq)return;
    state.busy=false;if(!r.ok||!r.session_id){showError(begin);return;}
    state.session=r.session_id;state.index=0;await load();
  }
  async function load() {
    if(state.closed||!state.session)return;
    state.busy=true;const n=++state.seq;
    const r=await rpc("iclub_exam_chemistry_p1_get_v1",
      {p_session_id:state.session,p_language:state.lang});
    if(state.closed||n!==state.seq)return;
    state.busy=false;
    if(!r.ok||!Array.isArray(r.items)||r.items.length!==40){showError(load);return;}
    state.data=r;draw();
  }
  function timer(label) {
    stopTimer();
    function paint() {
      if(state.closed||state.data?.status!=="active")return;
      const n=Math.max(0,Math.ceil((new Date(state.data.deadline_at).getTime()-Date.now())/1000));
      label.textContent=t().time+": "+String(Math.floor(n/60)).padStart(2,"0")+":"+
        String(n%60).padStart(2,"0");
      if(n===0){stopTimer();finish(true);}
    }
    paint();if(state.data?.status==="active")state.timer=setInterval(paint,1000);
  }
  function draw() {
    state.seq+=1;
    const p=panel(),data=state.data;if(!p||!data)return;
    const done=data.status==="finalized";
    const header=el("div",undefined,"ep-native-header");
    header.append(el("strong",t().paper));
    const clock=el("span",undefined,"ep-native-timer");
    header.append(clock);p.append(header);
    if(done){
      p.append(el("h3",t().result+": "+data.score+" / 40","ep-native-result"));
      p.append(el("p",t().note,"ep-host-note"));
    }else timer(clock);
    const row=data.items[state.index];if(!row)return;
    p.append(el("div",t().question+" "+(state.index+1)+" / 40 · "+t().answered+
      ": "+data.items.filter(item=>item.answered).length+" / 40","ep-native-progress"));
    const card=el("div",undefined,"ep-live-card ep-native-question");
    card.append(el("div",row.question,"ep-native-stem"));
    const options=el("div",undefined,"ep-native-options");
    row.options.forEach((option,i)=>{
      const b=button("ABCD"[i]+". "+option,()=>save(i),true);
      b.classList.add("ep-native-option");
      b.setAttribute("aria-pressed",String(i===row.selected_index));
      if(i===row.selected_index)b.classList.add("is-selected");
      b.disabled=done||state.busy;options.append(b);
    });
    card.append(options);
    if(done){
      card.append(el("p",t().your+": "+(Number.isInteger(row.selected_index)?
        "ABCD"[row.selected_index]:t().missing),"ep-native-explanation"));
      card.append(el("p",t().right+": "+(Number.isInteger(row.correct_index)?
        "ABCD"[row.correct_index]:"—"),"ep-native-explanation"));
      if(row.explanation)card.append(el("p",row.explanation,"ep-native-explanation"));
    }
    p.append(card);
    const actions=el("div",undefined,"ep-host-actions");
    if(state.index>0)actions.append(button(t().prev,()=>{state.index-=1;draw();},true));
    if(state.index<39)actions.append(button(t().next,()=>{state.index+=1;draw();},true));
    if(!done)actions.append(button(t().finish,()=>finish(false)));
    else actions.append(button(t().again,lobby));
    actions.append(button(t().return,lobby,true));
    p.append(actions);
  }
  async function save(choice) {
    if(state.closed||state.busy||state.data?.status!=="active")return;
    const n=state.seq,s=state.session,i=state.index;state.busy=true;
    const r=await rpc("iclub_exam_chemistry_p1_answer_v1",
      {p_session_id:s,p_item_order:i+1,p_choice:choice});
    if(state.closed||n!==state.seq||state.session!==s)return;
    state.busy=false;if(!r.ok){showError(load);return;}
    state.data.items[i].selected_index=choice;state.data.items[i].answered=true;
    const next=state.data.items.findIndex((row,j)=>j>i&&!row.answered);
    state.index=next>=0?next:Math.min(i+1,39);draw();
  }
  async function finish(auto) {
    if(state.closed||state.busy||state.data?.status!=="active")return;
    if(!auto&&!window.confirm(t().confirm))return;
    stopTimer();state.busy=true;const n=state.seq,s=state.session;
    const r=await rpc("iclub_exam_chemistry_p1_finish_v1",{p_session_id:s});
    if(state.closed||n!==state.seq||state.session!==s)return;
    state.busy=false;if(!r.ok){showError(load);return;}
    await load();
  }
  function mount({root,shell,language,onBack}={}) {
    unmount();
    if(!root||shell?.enabled!==true||shell.program_key!=="chemistry_9701"||
      !shell.papers?.some(p=>p.code==="P1"&&p.mcq_count===40&&p.assessment_kind==="mcq"))
      return false;
    state.root=root;state.shell=shell;state.lang=["ru","uz","en"].includes(language)?language:"ru";
    state.onBack=onBack;state.closed=false;lobby();return true;
  }
  function setLanguage(lang) {
    if(!["ru","uz","en"].includes(lang)||lang===state.lang)return;
    state.lang=lang;
    if(!state.closed){if(state.session)load();else lobby();}
  }
  internal.chemistryNative=Object.freeze({mount,unmount,setLanguage});
})();