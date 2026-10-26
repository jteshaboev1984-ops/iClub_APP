(() => {
  "use strict";
  const internal = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const state = {root:null,shell:null,lang:"ru",id:null,paper:null,data:null,index:0,timer:null,busy:false,closed:true,onBack:null,token:0};
  const dictionary={
    ru:{title:"Cambridge Economics · Exam Prep",intro:"Выберите экзаменационную работу. Ответы и результаты сохраняются на сервере.",history:"Мои попытки",viewResult:"Посмотреть результат",continueAttempt:"Продолжить",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Начать или продолжить",back:"Назад",
      papers:"К экзаменам",question:"Вопрос",time:"Осталось времени",save:"Сохранить ответ",
      saved:"Ответ сохранён",next:"Следующий",previous:"Предыдущий",finish:"Завершить экзамен",
      confirm:"Завершить экзамен? Пропущенные вопросы получат 0 баллов.",result:"Результат",
      review:"Разбор ответов",right:"Правильный ответ",your:"Ваш ответ",empty:"Не отвечено",
      loading:"Загрузка…",error:"Не удалось выполнить действие. Проверьте соединение.",retry:"Повторить"},
    uz:{title:"Cambridge Economics · Exam Prep",intro:"Imtihon ishini tanlang. Javoblar va natijalar serverda saqlanadi.",history:"Mening urinishlarim",viewResult:"Natijani ko‘rish",continueAttempt:"Davom ettirish",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Boshlash yoki davom ettirish",back:"Orqaga",
      papers:"Imtihonlarga qaytish",question:"Savol",time:"Qolgan vaqt",save:"Javobni saqlash",
      saved:"Javob saqlandi",next:"Keyingi",previous:"Oldingi",finish:"Imtihonni yakunlash",
      confirm:"Imtihonni yakunlaysizmi? Javobsiz savollar 0 ball bo‘ladi.",result:"Natija",
      review:"Javoblarni tahlil qilish",right:"To‘g‘ri javob",your:"Sizning javobingiz",empty:"Javob berilmagan",
      loading:"Yuklanmoqda…",error:"Amal bajarilmadi. Internetni tekshiring.",retry:"Qayta urinish"},
    en:{title:"Cambridge Economics · Exam Prep",intro:"Select an exam paper. Answers and results are saved on the server.",history:"My attempts",viewResult:"View result",continueAttempt:"Continue",
      p1:"Paper 1 · AS Level",p3:"Paper 3 · A Level",start:"Start or resume",back:"Back",
      papers:"Back to papers",question:"Question",time:"Time remaining",save:"Save answer",
      saved:"Answer saved",next:"Next",previous:"Previous",finish:"Finish exam",
      confirm:"Finish this exam? Unanswered questions score zero.",result:"Result",
      review:"Review answers",right:"Correct answer",your:"Your answer",empty:"Unanswered",
      loading:"Loading…",error:"The action failed. Check your connection.",retry:"Try again"}
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
    state.id=null;state.paper=null;state.data=null;state.busy=false;state.onBack=null;
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
    const grid=e("div","ep-host-component-grid");
    for(const [code,label,mins] of [["P1",t().p1,60],["P3",t().p3,75]]){
      if(!state.shell?.papers?.some(p=>p.code===code&&p.assessment_kind==="mcq"))continue;
      const card=e("div","ep-host-component-card ep-native-paper");
      card.append(e("strong","",label),e("span","","30 MCQ · "+mins+" min"));
      card.append(btn(t().start,()=>begin(code)));grid.append(card);
    }
    view.append(grid);
    const historyBox=e("div","ep-native-history");
    view.append(historyBox);
    loadHistory(historyBox,view);
    const actions=e("div","ep-host-actions");
    actions.append(btn(t().back,()=>state.onBack?.(),true));view.append(actions);
  }
  async function loadHistory(target,view){
    const response=await rpc("iclub_exam_native_mcq_history_v1",{p_paper_code:null});
    if(state.closed||state.root?.firstElementChild!==view||!response.ok||
       !Array.isArray(response.sessions)||response.sessions.length===0)return;
    target.replaceChildren(e("h3","ep-native-section-title",t().history));
    const list=e("div","ep-native-history-list");
    response.sessions.forEach(entry=>{
      if(!["P1","P3"].includes(entry.paper_code)||!entry.session_id)return;
      const card=e("div","ep-native-history-item");
      const title=entry.paper_code==="P1"?t().p1:t().p3;
      const date=new Date(entry.started_at);
      const dateText=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
        state.lang==="uz"?"uz-UZ":state.lang==="en"?"en-GB":"ru-RU",
        {day:"2-digit",month:"2-digit",year:"numeric"}).format(date);
      const result=entry.status==="finalized"?
        (String(entry.score)+" / 30"):(String(entry.answered)+" / 30");
      card.append(e("div","ep-native-history-info",title+" · "+dateText+" · "+result));
      card.append(btn(entry.status==="finalized"?t().viewResult:t().continueAttempt,()=>{
        state.id=entry.session_id;state.paper=entry.paper_code;state.index=0;load();
      },true));
      list.append(card);
    });
    target.append(list);
  }
  async function begin(code){
    if(state.busy||state.closed)return;
    const token=++state.token;state.busy=true;
    shell()?.append(e("p","ep-host-note",t().loading));
    const nonce=(window.crypto?.randomUUID?.()||(String(Date.now())+"-"+String(Math.random())))+"-econ";
    const v=await rpc("iclub_exam_native_mcq_start_v1",{p_paper_code:code,p_client_key:nonce});
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
    if(!v.ok||!Array.isArray(v.items)||v.items.length!==30){error(load);return;}
    state.data=v;draw();
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
    const data=state.data,view=shell();if(!view||!data)return;
    const finished=data.status==="finalized";
    const header=e("div","ep-native-header");
    header.append(e("strong","",state.paper==="P1"?t().p1:t().p3));
    const remaining=e("span","ep-native-timer");
    header.append(remaining);view.append(header);
    if(finished)view.append(e("h3","ep-native-result",t().result+": "+data.score+" / 30"));
    else clock(remaining);
    const row=data.items[state.index];if(!row)return;
    view.append(e("div","ep-native-progress",t().question+" "+(state.index+1)+" / 30 · "+data.items.filter(x=>x.answered).length+" / 30"));
    const card=e("div","ep-live-card ep-native-question");
    card.append(e("div","ep-native-stem",row.question));
    const options=e("div","ep-native-options");
    row.options.forEach((option,idx)=>{
      const line=e("label","ep-native-option");
      const radio=e("input");radio.type="radio";radio.name="ep-native-choice";radio.value=String(idx);
      radio.checked=row.selected_index===idx;radio.disabled=row.answered||finished||state.busy;
      line.append(radio,e("span","","ABCD"[idx]+". "+option));
      if(finished&&row.correct_index===idx)line.classList.add("is-right");
      if(finished&&row.selected_index===idx&&idx!==row.correct_index)line.classList.add("is-wrong");
      options.append(line);
    });
    card.append(options);
    if(row.answered&&!finished)card.append(e("p","ep-host-note",t().saved));
    if(finished){
      card.append(e("p","ep-host-note",t().your+": "+(row.selected_index===null?t().empty:"ABCD"[row.selected_index])+
        " · "+t().right+": "+"ABCD"[row.correct_index]));
      if(row.explanation)card.append(e("p","ep-native-explanation",row.explanation));
    }
    view.append(card);
    const actions=e("div","ep-host-actions ep-native-actions");
    if(!finished&&!row.answered)actions.append(btn(t().save,save));
    if(state.index>0)actions.append(btn(t().previous,()=>{state.index--;draw();},true));
    if(state.index<29)actions.append(btn(t().next,()=>{state.index++;draw();},true));
    if(!finished)actions.append(btn(t().finish,()=>finish(false),true));
    actions.append(btn(t().papers,lobby,true));view.append(actions);
  }
  async function save(){
    if(state.busy||state.closed||state.data?.status!=="active")return;
    const choice=state.root?.querySelector('input[name="ep-native-choice"]:checked');
    if(!choice)return;
    state.busy=true;
    const sessionId=state.id,token=state.token;
    const r=await rpc("iclub_exam_native_mcq_answer_v1",{
      p_session_id:sessionId,p_item_order:state.index+1,p_choice:Number(choice.value)});
    state.busy=false;
    if(state.closed||state.id!==sessionId||state.token!==token)return;
    if(!r.ok){error(load);return;}await load();
  }
  async function finish(auto){
    if(state.busy||state.closed||state.data?.status!=="active")return;
    if(!auto&&!window.confirm(t().confirm))return;
    stop();state.busy=true;
    const sessionId=state.id,token=state.token;
    const r=await rpc("iclub_exam_native_mcq_finish_v1",{p_session_id:sessionId});
    state.busy=false;
    if(state.closed||state.id!==sessionId||state.token!==token)return;
    if(!r.ok){error(load);return;}await load();
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