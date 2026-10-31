(() => {
 "use strict";
 // J10 independent RECHECK (unseen items). Entry, Paper 1 and mastery remain separate.
 const internal=window.iClubExamPrepHostInternal=window.iClubExamPrepHostInternal||{};
 const state={root:null,shell:null,lang:"ru",entryId:null,onBack:null,session:null,
 data:null,index:0,closed:true,busy:false,seq:0,timer:null,confirmed:false,localeQueued:false};
 const words={
 ru:{title:"Chemistry · Повторная проверка",intro:"22 новых вопроса · 30 минут. Сравним ответы со входной проверкой после повторения тем.",
 limit:"Один вопрос на тему не подтверждает её полного освоения и не меняет ваш учебный прогресс.",
 ack:"Я ознакомился с рекомендованными темами и готов к новой проверке.",
 start:"Перейти к проверке",history:"Мои повторные проверки",empty:"Повторных проверок пока нет.",
 resume:"Продолжить",see:"Посмотреть результат",single:"Один и тот же комплект после раскрытия ответов повторно не сдаётся.",
 unavailable:"Повторная проверка пока недоступна. Ваши предыдущие ответы сохранены.",
 back:"К входной проверке",retry:"Повторить",error:"Не удалось получить данные. Проверьте соединение.",
 loading:"Загрузка…",question:"Вопрос",answered:"Отвечено",time:"Осталось",
 navigate:"Номер вопроса",miss:"Пропущено",prev:"Назад",next:"Далее",finish:"Завершить",
 confirmFinish:"Завершить повторную проверку? Пропущено ответов: ",result:"Результат повторной проверки",
 selected:"Ваш ответ",correct:"Правильный ответ",skipped:"Нет ответа",
 review:"Сравнить результаты по темам",focus:"Темы, которые стоит повторить",
 all:"Все 22 темы",entry:"Входная проверка",recheck:"Повторная проверка",
 improved:"Здесь ответ стал верным",still:"Нужна дополнительная практика",
 stable:"Два отдельных верных ответа",note:"Это ориентировочное сравнение двух разных вопросов на тему, а не подтверждение освоения.",
 noFocus:"Ошибок в этой проверке нет. Продолжайте обучение; это не означает полного освоения тем."},
 uz:{title:"Chemistry · Qayta tekshiruv",intro:"22 ta yangi savol · 30 daqiqa. Mavzularni takrorlagandan so‘ng kirish tekshiruvi bilan taqqoslang.",
 limit:"Har bir mavzudagi bitta savol to‘liq o‘zlashtirishni tasdiqlamaydi va o‘quv natijalaringizni o‘zgartirmaydi.",
 ack:"Tavsiya qilingan mavzularni ko‘rib chiqdim va yangi tekshiruvga tayyorman.",
 start:"Tekshiruvga o‘tish",history:"Qayta tekshiruvlarim",empty:"Hali qayta tekshiruvlar yo‘q.",
 resume:"Davom ettirish",see:"Natijani ko‘rish",single:"Javoblar ochilgan bir xil savollar to‘plami qayta topshirilmaydi.",
 unavailable:"Qayta tekshiruv hozircha mavjud emas. Oldingi javoblaringiz saqlangan.",
 back:"Kirish tekshiruviga",retry:"Qayta urinish",error:"Ma’lumotlarni olishning imkoni bo‘lmadi. Internetni tekshiring.",
 loading:"Yuklanmoqda…",question:"Savol",answered:"Javob berilgan",time:"Qolgan vaqt",
 navigate:"Savol raqami",miss:"Javobsiz",prev:"Oldingi",next:"Keyingi",finish:"Yakunlash",
 confirmFinish:"Qayta tekshiruvni yakunlaysizmi? Javobsiz savollar: ",result:"Qayta tekshiruv natijasi",
 selected:"Javobingiz",correct:"To‘g‘ri javob",skipped:"Javobsiz",
 review:"Mavzular bo‘yicha taqqoslash",focus:"Takrorlash tavsiya qilingan mavzular",
 all:"Barcha 22 mavzu",entry:"Kirish tekshiruvi",recheck:"Qayta tekshiruv",
 improved:"Bu safar javob to‘g‘ri",still:"Qo‘shimcha mashq kerak",
 stable:"Ikkita alohida to‘g‘ri javob",note:"Bu har bir mavzu bo‘yicha ikkita turli savolni taxminiy taqqoslashdir, to‘liq o‘zlashtirish tasdig‘i emas.",
 noFocus:"Bu tekshiruvda xato yo‘q. O‘qishni davom ettiring; bu barcha mavzular o‘zlashtirilganini anglatmaydi."},
 en:{title:"Chemistry · Recheck",intro:"22 fresh questions · 30 minutes. Compare your answers with the entry check after reviewing topics.",
 limit:"One question per topic cannot establish mastery and will not change your learning progress.",
 ack:"I have reviewed my recommended topics and am ready for a fresh check.",
 start:"Open recheck",history:"My rechecks",empty:"No rechecks yet.",
 resume:"Continue",see:"View result",single:"The same form cannot be retaken after its answers are revealed.",
 unavailable:"Recheck is currently unavailable. Your previous answers are saved.",
 back:"Back to entry check",retry:"Try again",error:"Could not fetch the data. Check your connection.",
 loading:"Loading…",question:"Question",answered:"Answered",time:"Time remaining",
 navigate:"Question number",miss:"Unanswered",prev:"Previous",next:"Next",finish:"Finish",
 confirmFinish:"Finish this recheck? Unanswered questions: ",result:"Recheck result",
 selected:"Your answer",correct:"Correct answer",skipped:"Unanswered",
 review:"Compare topic results",focus:"Topics to review",
 all:"All 22 topics",entry:"Entry check",recheck:"Recheck",
 improved:"This answer is now correct",still:"More practice recommended",
 stable:"Two separate correct answers",note:"This is an indicative comparison of two different questions per topic, not confirmation of mastery.",
 noFocus:"No errors in this recheck. Keep learning; this does not prove full mastery."}
 };
 const t=()=>words[state.lang]||words.ru;
 const node=(tag,text,cls)=>{const x=document.createElement(tag);if(text!==undefined&&text!==null)x.textContent=String(text);if(cls)x.className=cls;return x;};
 const active=()=>!state.closed&&!!state.root;
 const button=(caption,fn,secondary=false)=>{
  const b=node("button",caption,"ep-host-btn "+(secondary?"ep-host-btn-secondary":"ep-host-btn-primary"));
  b.type="button";b.disabled=state.busy;b.addEventListener("click",fn);return b;
 };
 const clearClock=()=>{if(state.timer!==null)window.clearInterval(state.timer);state.timer=null;};
 function unmount(){clearClock();state.seq++;state.closed=true;state.root=null;state.shell=null;state.entryId=null;
 state.onBack=null;state.session=null;state.data=null;state.index=0;state.busy=false;state.confirmed=false;state.localeQueued=false;}
 function screen(){
  if(!active())return null;
  const p=node("section",null,"ep-host-shell ep-native-chemistry ep-chem-recheck");
  p.append(node("div","Cambridge AS · 9701","ep-host-kicker"),node("h2",t().title,"ep-host-title"));
  state.root.replaceChildren(p);return p;
 }
 const authorized=async(name,args={})=>{
  try{const r=await window.sb?.rpc?.(name,args);
   return !r?.error&&r?.data?.ok===true?r.data:{ok:false,code:r?.data?.code||"network_error"};
  }catch(_){return {ok:false,code:"network_error"};}
 };
 function errorScreen(retry){
  clearClock();const p=screen();if(!p)return;
  const note=node("p",t().error,"ep-host-note");note.setAttribute("role","alert");
  p.append(note,button(t().retry,retry),button(t().back,()=>state.onBack?.(),true));
 }
 async function lobby(){
  clearClock();const token=++state.seq;state.session=null;state.data=null;state.index=0;state.confirmed=false;state.localeQueued=false;
  const p=screen();if(!p)return;
  p.append(node("p",t().intro,"ep-host-note"),node("p",t().limit,"ep-host-note"));
  const form=node("div",null,"ep-chem-recheck-ready");
  const label=node("label",null,"ep-chem-recheck-ack");
  const check=node("input");check.type="checkbox";check.checked=false;
  check.addEventListener("change",()=>{state.confirmed=check.checked;startBtn.disabled=!check.checked||state.busy;});
  label.append(check,node("span",t().ack));
  const startBtn=button(t().start,start);startBtn.disabled=true;
  form.append(label,startBtn);p.append(form);
  const history=node("div",null,"ep-native-history");p.append(history);
  p.append(button(t().back,()=>state.onBack?.(),true));
  const r=await authorized("iclub_exam_chemistry_recheck_history_v1");
  if(!active()||state.seq!==token||state.root.firstElementChild!==p)return;
  if(!r.ok||!Array.isArray(r.sessions)){history.append(node("p",t().unavailable,"ep-host-note"));return;}
  if(r.sessions.length===0){history.append(node("p",t().empty,"ep-host-note"));return;}
  history.append(node("h3",t().history,"ep-native-section-title"));
  const list=node("div",null,"ep-native-history-list");
  r.sessions.forEach(x=>{
   if(!x.session_id)return;
   const row=node("div",null,"ep-native-history-item");
   const date=new Date(x.started_at);
   const localized=Number.isNaN(date.getTime())?"":new Intl.DateTimeFormat(
    state.lang==="ru"?"ru-RU":state.lang==="uz"?"uz-UZ":"en-GB",
    {day:"2-digit",month:"short",year:"numeric"}).format(date);
   row.append(node("span",localized+" · "+(x.status==="finalized"?x.score:x.answered)+" / 22","ep-native-history-info"));
   row.append(button(x.status==="finalized"?t().see:t().resume,()=>{
    state.session=x.session_id;state.index=0;load();
   },true));
   list.append(row);
  });
  history.append(list);
  if(r.sessions.some(x=>x.status==="finalized"))history.append(node("p",t().single,"ep-host-note"));
 }
 async function start(){
  if(!active()||state.busy||!state.confirmed)return;
  state.busy=true;const token=++state.seq;
  screen()?.append(node("p",t().loading,"ep-host-note"));
  const key=(window.crypto?.randomUUID?.()||String(Date.now())+"_"+Math.random().toString(36).slice(2))+"_j10";
  const r=await authorized("iclub_exam_chemistry_recheck_start_v1",{
   p_client_key:key,p_entry_id:state.entryId,p_study_confirmed:true});
  if(!active()||state.seq!==token)return;state.busy=false;
  if(!r.ok||!r.session_id){errorScreen(lobby);return;}
  state.session=r.session_id;await load();
 }
 async function load(){
  if(!active()||!state.session)return;
  const token=++state.seq;state.busy=true;
  const r=await authorized("iclub_exam_chemistry_recheck_get_v1",
   {p_session_id:state.session,p_language:state.lang});
  if(!active()||state.seq!==token)return;state.busy=false;
  if(state.localeQueued){state.localeQueued=false;await load();return;}
  const validItems=Array.isArray(r.items)&&r.items.length===22
   &&r.items.every((item,i)=>item&&item.order===i+1
     &&typeof item.question==="string"&&item.question.trim().length>0
     &&Array.isArray(item.options)&&item.options.length===4
     &&item.options.every(option=>typeof option==="string"&&option.trim().length>0)
     &&typeof item.answered==="boolean"
     &&(item.selected_index===null||(Number.isInteger(item.selected_index)
       &&item.selected_index>=0&&item.selected_index<4))
     &&(r.status!=="active"||(item.correct_index==null&&item.explanation==null)));
  if(!r.ok||!["active","finalized"].includes(r.status)||!validItems
    ||r.can_credit_mastery!==false||r.calibrated_diagnostic!==false){
    errorScreen(load);return;
  }
  state.data=r;draw();
 }
 function runClock(place){
  clearClock();const paint=()=>{
   if(!active()||state.data?.status!=="active")return;
   const remaining=Math.max(0,Math.ceil((new Date(state.data.deadline_at).getTime()-Date.now())/1000));
   place.textContent=t().time+": "+String(Math.floor(remaining/60)).padStart(2,"0")+":"+
     String(remaining%60).padStart(2,"0");
   if(remaining===0){clearClock();finish(true);}
  };
  paint();if(state.data?.status==="active")state.timer=window.setInterval(paint,1000);
 }
 function draw(){
  ++state.seq;const p=screen(),d=state.data;if(!p||!d)return;
  const finalized=d.status==="finalized";const top=node("div",null,"ep-native-header");
  top.append(node("strong","Cambridge AS · Chemistry"));
  const time=node("span",null,"ep-native-timer");top.append(time);p.append(top);
  if(finalized){
   clearClock();p.append(node("h3",t().result+": "+d.score+" / 22","ep-native-result"),
    node("p",t().limit,"ep-host-note"));
  }else runClock(time);
  const ans=d.items.filter(x=>x.answered).length;
  p.append(node("p",t().question+" "+(state.index+1)+" / 22 · "+t().answered+": "+ans+"/22","ep-native-progress"));
  const picker=node("details",null,"ep-chem-question-map");
  picker.append(node("summary",t().navigate));
  const grid=node("div",null,"ep-chem-question-grid");
  d.items.forEach((item,i)=>{
   const b=button(String(i+1),()=>{if(state.busy)return;state.index=i;draw();},true);
   b.classList.add("ep-chem-question-jump");if(item.answered)b.classList.add("is-answered");
   if(i===state.index){b.classList.add("is-current");b.setAttribute("aria-current","step");}
   b.setAttribute("aria-label",t().question+" "+(i+1));grid.append(b);
  });
  picker.append(grid);p.append(picker);
  const item=d.items[state.index],card=node("div",null,"ep-live-card ep-native-question");
  card.append(node("div",item.question,"ep-native-stem"));
  const options=node("div",null,"ep-native-options");
  item.options.forEach((value,i)=>{
   const b=button("ABCD"[i]+". "+value,()=>answer(i),true);
   b.classList.add("ep-native-option");b.disabled=finalized||state.busy;
   if(item.selected_index===i)b.classList.add("is-selected");
   b.setAttribute("aria-pressed",String(item.selected_index===i));options.append(b);
  });
  card.append(options);
  if(finalized){
   card.append(node("p",t().selected+": "+(Number.isInteger(item.selected_index)?"ABCD"[item.selected_index]:t().skipped),
    "ep-native-explanation"));
   card.append(node("p",t().correct+": "+(Number.isInteger(item.correct_index)?"ABCD"[item.correct_index]:"—"),
    "ep-native-explanation"));
   if(item.explanation)card.append(node("p",item.explanation,"ep-native-explanation"));
  }
  p.append(card);
  const actions=node("div",null,"ep-host-actions");
  if(state.index>0)actions.append(button(t().prev,()=>{if(state.busy)return;state.index--;draw();},true));
  if(state.index<21)actions.append(button(t().next,()=>{if(state.busy)return;state.index++;draw();},true));
  if(!finalized)actions.append(button(t().finish,()=>finish(false)));
  else actions.append(button(t().review,review));
  actions.append(button(t().back,()=>state.onBack?.(),true));p.append(actions);
 }
 async function answer(chosen){
  if(!active()||state.busy||state.data?.status!=="active")return;
  state.busy=true;const seq=state.seq,id=state.session,index=state.index;
  const r=await authorized("iclub_exam_chemistry_recheck_answer_v1",
    {p_session_id:id,p_item_order:index+1,p_choice:chosen});
  if(!active()||seq!==state.seq||id!==state.session)return;
  state.busy=false;
  if(!r.ok){if(r.code==="attempt_closed_or_expired"){finish(true);return;}errorScreen(load);return;}
  state.data.items[index].selected_index=chosen;state.data.items[index].answered=true;
  let next=state.data.items.findIndex((x,i)=>i>index&&!x.answered);
  if(next<0)next=state.data.items.findIndex(x=>!x.answered);
  state.index=next<0?index:next;
  if(state.localeQueued){state.localeQueued=false;await load();return;}
  draw();
 }
 async function finish(auto){
  if(!active()||state.busy||state.data?.status!=="active")return;
  const unanswered=state.data.items.filter(x=>!x.answered).length;
  if(!auto&&!window.confirm(t().confirmFinish+unanswered))return;
  clearClock();state.busy=true;const seq=state.seq,id=state.session;
  const r=await authorized("iclub_exam_chemistry_recheck_finish_v1",{p_session_id:id});
  if(!active()||seq!==state.seq||id!==state.session)return;
  state.busy=false;
  if(!r.ok){errorScreen(load);return;}await load();
 }
 async function review(){
  if(!active()||state.busy||state.data?.status!=="finalized")return;
  state.busy=true;const seq=++state.seq,id=state.session;
  screen()?.append(node("p",t().loading,"ep-host-note"));
  const r=await authorized("iclub_exam_chemistry_recheck_review_v1",
   {p_session_id:id,p_language:state.lang});
  if(!active()||seq!==state.seq||id!==state.session)return;
  state.busy=false;
  if(state.localeQueued){state.localeQueued=false;await review();return;}
  if(!r.ok||!Array.isArray(r.topics)||r.topics.length!==22||
   r.can_credit_mastery!==false||r.calibrated_diagnostic!==false||
   r.recheck_means_improvement_not_mastery!==true){errorScreen(review);return;}
  const p=screen();p.append(node("h3",t().review,"ep-native-result"),
   node("p",t().note,"ep-host-note"));
  const render=(parent,x)=>{
   const row=node("div",null,"ep-chem-review-row");
   row.append(node("strong",x.unit+". "+x.title));
   const st=x.recheck_correct?
     (!x.entry_correct?t().improved:t().stable):t().still;
   row.append(node("span",st,"ep-chem-review-counts"));
   const line=node("div",null,"ep-chem-recheck-comparison");
   line.append(node("span",t().entry+": "+(x.entry_correct?"✓":x.entry_answered?"×":"—")),
    node("span",t().recheck+": "+(x.recheck_correct?"✓":x.recheck_answered?"×":"—")));
   row.append(line);parent.append(row);
  };
  const focus=node("div",null,"ep-chem-review-focus");
  focus.append(node("h4",t().focus,"ep-chem-review-title"));
  const bad=r.topics.filter(x=>x.study_recommended===true);
  if(!bad.length)focus.append(node("p",t().noFocus,"ep-host-note"));
  else bad.forEach(x=>render(focus,x));p.append(focus);
  const rest=node("details",null,"ep-chem-review-all");
  rest.append(node("summary",t().all));
  const grid=node("div",null,"ep-chem-review-list");
  r.topics.forEach(x=>render(grid,x));rest.append(grid);p.append(rest);
  p.append(button(t().back,()=>state.onBack?.(),true));
 }
 function mount({root,shell,language,onBack}={}){
  unmount();
  if(!root||shell?.enabled!==true||shell.program_key!=="chemistry_9701"||
   shell.assessment_code!=="RECHECK"||shell.item_count!==22||
   shell.duration_seconds!==1800||shell.can_credit_mastery!==false||
   shell.learning_ack_kind!=="self_report"||!shell.entry_session_id)return false;
  state.root=root;state.shell=shell;state.entryId=shell.entry_session_id;
  state.lang=["ru","uz","en"].includes(language)?language:"ru";
  state.onBack=onBack;state.closed=false;lobby();return true;
 }
 function setLanguage(locale){
  if(!["ru","uz","en"].includes(locale)||locale===state.lang)return;
  state.lang=locale;if(!active())return;
  if(state.busy){state.localeQueued=true;return;}
  if(state.session)load();else lobby();
 }
 internal.chemistryRecheckNative=Object.freeze({mount,unmount,setLanguage,getLanguage:()=>state.lang,isMounted:()=>active()});
})();