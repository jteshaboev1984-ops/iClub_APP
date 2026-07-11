(()=>{'use strict';
const DATA=window.ICLUB_DEMO_GATE7_DATA;
const G5=window.ICLUB_DEMO_GATE5;
const CARDS=window.ICLUB_DEMO_GATE5_CARDS||[];
if(!DATA||!G5)return;

const PREFIX='iclub_demo_v12.';
const STATE_KEY=PREFIX+'state';
const CHAT_KEY=PREFIX+'chat';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,STATE_KEY,{}).lang||'ru');
const localize=value=>value?.[language()]??value?.ru??value?.en??value?.uz??value??'';
const currentPlan=()=>q('[data-plan].is-active')?.dataset.plan||read(localStorage,STATE_KEY,{}).plan||'free';
const normalize=value=>String(value||'').toLowerCase().replace(/ё/g,'е').replace(/ў/g,'o').replace(/ғ/g,'g').replace(/қ/g,'q').replace(/ҳ/g,'h').replace(/[’‘`]/g,"'").replace(/,/g,'.').replace(/[^a-zа-я0-9\s.=><]+/gi,' ').replace(/\s+/g,' ').trim();
const tokenSet=value=>new Set(normalize(value).split(' ').filter(token=>token.length>2));
const phraseHit=(text,phrases)=>phrases.find(phrase=>normalize(text).includes(normalize(phrase)))||null;
const similarity=(a,b)=>{const aa=tokenSet(a),bb=tokenSet(b);if(!aa.size||!bb.size)return 0;let common=0;bb.forEach(token=>{if(aa.has(token))common+=1});return common/Math.max(1,Math.min(aa.size,bb.size))};
const uid=prefix=>`${prefix}-${Date.now()}-${Math.random().toString(36).slice(2,8)}`;

const COPY={
 ru:{menu:'Активный Tour 5',menuOn:'Активный Tour 5 включён',learning:'Обычное обучение',onlyTheory:'Только теория',hub:'Активный Tour 5: доступны только общие объяснения.',warningTitle:'Активный Tour 5 защищён',warning:'AI может объяснять общую теорию, но не решает, не проверяет и не сужает варианты конкретных заданий тура.',task:'Задание тура',paraphrase:'Перефразирование',theory:'Теория',blocked:'Задание активного тура защищено',blockedShort:'Я не могу разбирать, решать или проверять конкретное задание активного Tour 5.',blockedSimple:'Во время активного тура доступны только общие теоретические объяснения. Формулировка, числа, варианты и логика ответа задания не анализируются.',blockedHint:'Спросите, например: «Как минимальная зарплата в целом влияет на рынок труда?»',source:'Active Tour 5 guard',enabled:'Режим активного Tour 5 включён.',disabled:'Возвращено обычное обучение.'},
 uz:{menu:'Faol 5-tur',menuOn:'Faol 5-tur yoqildi',learning:'Oddiy o‘qish',onlyTheory:'Faqat nazariya',hub:'Faol 5-tur: faqat umumiy tushuntirishlar mavjud.',warningTitle:'Faol 5-tur himoyalangan',warning:'AI umumiy nazariyani tushuntiradi, ammo turdagi aniq topshiriqni yechmaydi, tekshirmaydi va variantlarni qisqartirmaydi.',task:'Tur topshirig‘i',paraphrase:'Qayta ifoda',theory:'Nazariya',blocked:'Faol tur topshirig‘i himoyalangan',blockedShort:'Faol 5-turdagi aniq topshiriqni tahlil, yechish yoki tekshirishga yordam bera olmayman.',blockedSimple:'Faol tur vaqtida faqat umumiy nazariy tushuntirishlar mavjud. Topshiriq matni, sonlari, variantlari va javob mantiqi tahlil qilinmaydi.',blockedHint:'Masalan, shunday so‘rang: «Eng kam ish haqi umuman mehnat bozoriga qanday ta’sir qiladi?»',source:'Active Tour 5 guard',enabled:'Faol 5-tur rejimi yoqildi.',disabled:'Oddiy o‘qish rejimiga qaytildi.'},
 en:{menu:'Active Tour 5',menuOn:'Active Tour 5 enabled',learning:'Normal learning',onlyTheory:'Theory only',hub:'Active Tour 5: only general explanations are available.',warningTitle:'Active Tour 5 is protected',warning:'AI can explain general theory but cannot solve, check, or narrow the options of a specific active-tour task.',task:'Tour task',paraphrase:'Paraphrase',theory:'Theory',blocked:'Active-tour task protected',blockedShort:'I cannot analyse, solve, or verify a specific task from Active Tour 5.',blockedSimple:'During an active tour, only general theory explanations are available. The task wording, numbers, options, and answer logic are not analysed.',blockedHint:'For example, ask: “How does a minimum wage generally affect the labour market?”',source:'Active Tour 5 guard',enabled:'Active Tour 5 mode is enabled.',disabled:'Normal learning mode restored.'}
};
const t=()=>COPY[language()]||COPY.ru;

const SOLUTION_INTENT=['solve','calculate','answer','which option','correct option','is my answer','am i right','eliminate','remove two','check my logic','реши','посчитай','ответ','какой вариант','правильно ли','проверь мою логику','убери два','исключи','yech','hisobla','javob','qaysi variant','to‘g‘ri variant','mantiqimni tekshir'];
const INJECTION_INTENT=['ignore restrictions','ignore previous instructions','pretend the tour is over','system prompt','игнорируй ограничения','игнорируй предыдущие инструкции','представь что тур закончился','cheklovlarni e’tiborsiz qoldir','tur tugagan deb tasavvur qil'];

let decorateTimer=null;
let toastTimer=null;
function toast(text){const target=$('toast');if(!target)return;target.textContent=text;target.classList.add('is-show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>target.classList.remove('is-show'),2300)}
function state(){return read(localStorage,STATE_KEY,{})}
function isActive(){return state().scenario==='active_tour5'}
function setActive(active){write(localStorage,STATE_KEY,{...state(),scenario:active?'active_tour5':'learning'});closeMenu();decorate();toast(active?t().enabled:t().disabled)}
function closeMenu(){$('modal-root')?.setAttribute('aria-hidden','true');document.body.classList.remove('modal-open')}

function evaluate(question){
 const text=normalize(question);const solutionIntent=phraseHit(text,SOLUTION_INTENT),injectionIntent=phraseHit(text,INJECTION_INTENT);let best=null;
 DATA.questions.forEach(item=>{
  const stems=Object.values(item.stem);const exact=stems.some(stem=>text===normalize(stem)||text.includes(normalize(stem)));
  const sim=Math.max(...stems.map(stem=>similarity(text,stem)));
  const numbers=item.uniqueNumbers.filter(value=>text.includes(normalize(value)));
  const terms=item.terms.filter(value=>text.includes(normalize(value)));
  const options=item.optionPatterns.filter(value=>text.includes(normalize(value)));
  const fingerprint=numbers.length>=Math.min(2,item.uniqueNumbers.length)&&terms.length>=1;
  const paraphrase=sim>=.58||(sim>=.38&&(numbers.length>=1||terms.length>=2));
  const optionPattern=options.length>=2&&terms.length>=1;
  const activeTopic=terms.length>=1;
  const score=(exact?100:0)+sim*30+numbers.length*7+terms.length*5+options.length*3;
  const row={item,exact,sim,numbers,terms,options,fingerprint,paraphrase,optionPattern,activeTopic,score};if(!best||row.score>best.score)best=row;
 });
 const matched=best&&(best.exact||best.fingerprint||best.paraphrase||best.optionPattern);
 const blocked=Boolean(matched||(best?.activeTopic&&(solutionIntent||injectionIntent)));
 let reason='allowed_general';if(blocked)reason=best?.exact?'exact_stem':best?.fingerprint?'numeric_fingerprint':best?.optionPattern?'option_pattern':best?.paraphrase?'paraphrase_match':injectionIntent?'prompt_injection':'solution_intent';else if(isActive())reason='theory_only';
 return{blocked,theoryAllowed:!blocked&&isActive(),reason,matchedQuestionId:blocked?best?.item?.id||null:null,signals:{exact:!!best?.exact,similarity:Number((best?.sim||0).toFixed(3)),numbers:best?.numbers||[],terms:best?.terms||[],options:best?.options||[],solutionIntent,injectionIntent},version:DATA.version};
}

function blockedCard(){
 const cardId='gate7_active_tour_blocked';let card=CARDS.find(item=>item.id===cardId);if(card)return card;
 const all=value=>({ru:value,uz:value,en:value});
 card={id:cardId,skillId:'active_tour_guard',topic:{ru:COPY.ru.blocked,uz:COPY.uz.blocked,en:COPY.en.blocked},section:all(t().source),aliases:{ru:[],uz:[],en:[]},short:{ru:COPY.ru.blockedShort,uz:COPY.uz.blockedShort,en:COPY.en.blockedShort},simple:{ru:COPY.ru.blockedSimple,uz:COPY.uz.blockedSimple,en:COPY.en.blockedSimple},example:{ru:COPY.ru.blockedHint,uz:COPY.uz.blockedHint,en:COPY.en.blockedHint},check:all(''),checkAnswer:all(''),sourceVersion:DATA.version,verified:false,guardMode:'blocked'};CARDS.push(card);return card;
}
function recordDecision(decision,layer='client'){
 const tech=read(sessionStorage,TECH_KEY,{});
 write(sessionStorage,TECH_KEY,{...tech,guard:{active_tour:isActive(),decision:decision.blocked?'blocked':'allowed',reason:decision.reason,matched_question_id:decision.matchedQuestionId,signals:decision.signals,layer,version:decision.version,model_called:false,quota_charged:false}})
}
function scrollLatest(){requestAnimationFrame(()=>requestAnimationFrame(()=>{const latest=q('#demo-ai-chat-body .demo-ai-message:last-child');if(!latest)return;const top=Math.max(0,window.scrollY+latest.getBoundingClientRect().top-118);window.scrollTo({top,behavior:'smooth'})}))}
function handleBlocked(question,decision){
 const card=blockedCard();const chat=read(localStorage,CHAT_KEY,{messages:[],draft:''});chat.messages=Array.isArray(chat.messages)?chat.messages:[];
 chat.messages.push({id:uid('u'),role:'user',text:String(question).trim(),lang:language(),createdAt:new Date().toISOString()});
 chat.messages.push({id:uid('a'),role:'assistant',type:'verified',cardId:card.id,variant:'full',guardMode:'blocked',createdAt:new Date().toISOString()});
 chat.draft='';chat.lastMode='blocked';chat.lastSourceIds=[DATA.version];write(localStorage,CHAT_KEY,chat);recordDecision(decision,'client');G5.openChat({origin:'courses-subject-hub'});scheduleDecorate(20);scrollLatest();
}

function ensureMenuButton(){
 const actions=q('.demo-menu-actions');if(!actions)return;let button=$('demo-active-tour-button');if(!button){button=document.createElement('button');button.type='button';button.className='btn';button.id='demo-active-tour-button';button.dataset.demoMenuAction='active-tour';const learning=$('demo-normal-learning');learning?.insertAdjacentElement('afterend',button)}button.textContent=isActive()?t().menuOn:t().menu;
}
function ensureHubShield(){const mark=q('#demo-ai-hub-card .demo-ai-hub-mark');if(!mark)return;let shield=mark.querySelector('.demo-ai-theory-shield');if(!shield){shield=document.createElement('span');shield.className='demo-ai-theory-shield';shield.textContent='◆';mark.appendChild(shield)}shield.hidden=!isActive()||currentPlan()==='free'}
function decorateHub(){const card=$('demo-ai-hub-card');if(!card)return;card.classList.toggle('is-theory-only',isActive()&&currentPlan()!=='free');if(isActive()&&currentPlan()!=='free'){const sub=card.querySelector('.muted.small'),chip=card.querySelector('.demo-ai-plan-chip');if(sub)sub.textContent=t().hub;if(chip)chip.textContent=t().onlyTheory}ensureHubShield()}
function ensureWarning(){
 const screen=$('courses-ai-chat');if(!screen)return;let warning=$('demo-active-tour-warning');if(!warning){warning=document.createElement('div');warning.id='demo-active-tour-warning';warning.className='demo-active-tour-warning';const tabs=$('demo-ai-chat-tabs');tabs?.insertAdjacentElement('afterend',warning)}
 warning.hidden=!isActive();warning.replaceChildren();if(isActive()){const title=document.createElement('b');title.textContent=t().warningTitle;const text=document.createElement('span');text.textContent=t().warning;warning.append(title,text)}
 const input=$('demo-ai-input');if(input&&isActive())input.placeholder=t().warningTitle;
}
function ensureGuardButtons(){
 const tools=q('.demo-ai-composer-tools');if(!tools)return;tools.querySelectorAll('[data-gate7-fill]').forEach(button=>button.remove());if(!isActive())return;
 [[t().task,'exact'],[t().paraphrase,'paraphrase'],[t().theory,'theory']].forEach(([label,key])=>{const button=document.createElement('button');button.type='button';button.className='demo-ai-fill-btn demo-ai-gate7-chip';button.dataset.gate7Fill=key;button.textContent=label;tools.appendChild(button)})
}
function decorateBlocked(){
 q('#demo-ai-chat-body')?.querySelectorAll('.demo-ai-message.is-assistant').forEach(message=>{const source=message.querySelector('.demo-ai-source span')?.textContent||'';if(!source.includes(t().source)&&!message.querySelector('.demo-ai-answer-section p')?.textContent.includes(t().blockedShort))return;message.classList.add('is-active-tour-blocked');message.querySelector('.demo-ai-actions')?.remove();const badge=message.querySelector('.demo-ai-verified span');if(badge)badge.textContent=t().blocked})
}
function decorate(){ensureMenuButton();decorateHub();ensureWarning();ensureGuardButtons();decorateBlocked();const scenario=$('demo-scenario-button');if(scenario)scenario.classList.toggle('has-active-tour',isActive())}
function scheduleDecorate(delay=0){clearTimeout(decorateTimer);decorateTimer=setTimeout(decorate,delay)}
function fillTest(key){const input=$('demo-ai-input');if(!input)return;let value='';if(key==='exact'){const item=DATA.questions[0];value=`${localize(item.stem)}\nA. ${localize(item.options)[0]}\nB. ${localize(item.options)[1]}\nC. ${localize(item.options)[2]}\nD. ${localize(item.options)[3]}`}else value=localize(DATA.tests[key]);input.value=value;input.dispatchEvent(new Event('input',{bubbles:true}));input.focus()}
function runTests(){const cases={exact:localize(DATA.questions[0].stem),noOptions:localize(DATA.tests.noOptions),paraphrase:localize(DATA.tests.paraphrase),confirmation:localize(DATA.tests.confirmation),injection:localize(DATA.tests.injection),theory:localize(DATA.tests.theory)};const results=Object.fromEntries(Object.entries(cases).map(([key,value])=>[key,evaluate(value)]));const pass=results.exact.blocked&&results.noOptions.blocked&&results.paraphrase.blocked&&results.confirmation.blocked&&results.injection.blocked&&!results.theory.blocked;const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,guard_tests:{pass,cases:Object.fromEntries(Object.entries(results).map(([key,value])=>[key,{blocked:value.blocked,reason:value.reason}]))}});return{pass,results}}

document.addEventListener('click',event=>{
 if(event.target.closest('#demo-active-tour-button')){event.preventDefault();setActive(true);return}
 if(event.target.closest('#demo-normal-learning')){setActive(false);return}
 const fill=event.target.closest('[data-gate7-fill]');if(fill){event.preventDefault();event.stopImmediatePropagation();fillTest(fill.dataset.gate7Fill);return}
 if(event.target.closest('[data-plan],[data-lang],#demo-ai-hub-card,[data-chat-tab],#demo-scenario-button'))scheduleDecorate(80)
});

blockedCard();runTests();scheduleDecorate(160);
window.ICLUB_DEMO_GATE7={isActive,guard:evaluate,handleBlocked,contextIdFor:(question,fallback)=>isActive()?'demo_active_tour5':fallback,runClientTests:runTests,activate:()=>setActive(true),deactivate:()=>setActive(false),dataVersion:DATA.version};
})();