(()=>{'use strict';
const G5=window.ICLUB_DEMO_GATE5;
const CARDS=window.ICLUB_DEMO_GATE5_CARDS||[];
if(!G5||!Array.isArray(CARDS))return;

const PREFIX='iclub_demo_v12.';
const CHAT_KEY=PREFIX+'chat';
const CACHE_KEY=PREFIX+'cache';
const SESSION_KEY=PREFIX+'ai_session';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,PREFIX+'state',{}).lang||'ru');
const normalize=value=>String(value||'').toLowerCase().replace(/ё/g,'е').replace(/[’‘`]/g,"'").replace(/[^a-zа-я0-9қғўҳ\s=><]+/gi,' ').replace(/\s+/g,' ').trim();
const uid=prefix=>`${prefix}-${Date.now()}-${Math.random().toString(36).slice(2,8)}`;

const COPY={
 ru:{live:'Live AI пример',cache:'Повтор для cache',fallback:'Резервный ответ',liveQuestion:'Почему фирма может быть производственно эффективной, но аллокативно неэффективной?',filled:'Вопрос вставлен. Отправьте его самостоятельно.',thinking:'iClub AI готовит ответ…',generated:'Сгенерированный ответ',cached:'Ответ из кэша',fallbackMode:'Сохранённый проверенный ответ',networkFallback:'Live AI сейчас недоступен. Показан сохранённый проверенный ответ.',retry:'Повторите вопрос для проверки cache.'},
 uz:{live:'Live AI misoli',cache:'Cache uchun takrorlash',fallback:'Zaxira javob',liveQuestion:'Nega firma ishlab chiqarish jihatidan samarali, ammo allokativ jihatdan samarasiz bo‘lishi mumkin?',filled:'Savol kiritildi. Uni o‘zingiz yuboring.',thinking:'iClub AI javob tayyorlamoqda…',generated:'Yaratilgan javob',cached:'Keshdagi javob',fallbackMode:'Saqlangan tekshirilgan javob',networkFallback:'Live AI hozir mavjud emas. Saqlangan tekshirilgan javob ko‘rsatildi.',retry:'Cache ni tekshirish uchun savolni takrorlang.'},
 en:{live:'Live AI example',cache:'Repeat for cache',fallback:'Fallback answer',liveQuestion:'Why can a firm be productively efficient but allocatively inefficient?',filled:'The question is inserted. Send it yourself.',thinking:'iClub AI is preparing an answer…',generated:'Generated answer',cached:'Cached answer',fallbackMode:'Saved verified answer',networkFallback:'Live AI is unavailable. A saved verified answer is shown.',retry:'Repeat the question to verify cache.'}
};
const t=()=>COPY[language()]||COPY.ru;

let nextContextId='demo_subject_chat';
let lastOrigin='courses-subject-hub';
let busy=false;
let toastTimer=null;
let decorateTimer=null;

function toast(text){
 const target=$('toast');if(!target)return;
 target.textContent=text;target.classList.add('is-show');
 clearTimeout(toastTimer);toastTimer=setTimeout(()=>target.classList.remove('is-show'),2400);
}
function chatState(){const raw=read(localStorage,CHAT_KEY,{});return{...raw,messages:Array.isArray(raw.messages)?raw.messages:[],draft:String(raw.draft||'')}}
function saveChat(state){write(localStorage,CHAT_KEY,{...state,version:'gate6-v2'})}
function cacheState(){const raw=read(sessionStorage,CACHE_KEY,{});return{...raw,ai_cache:raw.ai_cache&&typeof raw.ai_cache==='object'?raw.ai_cache:{}}}
function saveCache(state){write(sessionStorage,CACHE_KEY,state)}
function cacheKey(question,contextId){return `${language()}|subject_chat|${contextId}|${normalize(question)}`}

function setTechnical(payload){
 const current=read(sessionStorage,TECH_KEY,{});
 write(sessionStorage,TECH_KEY,{...current,ai:{
  mode:payload.mode,
  model_call:!!payload.usage?.model_called,
  source_ids:payload.technical?.source_ids||[payload.source?.id].filter(Boolean),
  source_version:payload.source?.version||'demo-v12-gate6',
  latency_ms:Number(payload.technical?.latency_ms||0),
  quota_charged:!!payload.usage?.charged,
  quota_remaining:payload.usage?.demo_limit_remaining,
  cache_hit:!!payload.technical?.cache_hit,
  safe_renderer:'DOM textContent',
  endpoint:'/api/diagnostic-ai',
  guard_decision:payload.safety?.guard_decision||'allowed'
 }})
}

function modeLabel(mode){return mode==='generated'?t().generated:mode==='cached'?t().cached:t().fallbackMode}
function pushCardFromMessage(message){
 if(!message?.cardId||!message.answer||CARDS.some(card=>card.id===message.cardId))return;
 const all=value=>({ru:value||'',uz:value||'',en:value||''});
 CARDS.push({
  id:message.cardId,
  skillId:`gate6_${message.cardId}`,
  topic:all(modeLabel(message.mode)),
  section:all(message.source?.section||message.source?.topic||'Economics'),
  aliases:{ru:[],uz:[],en:[]},
  short:all(message.answer.short),
  simple:all(message.answer.simple),
  example:all(message.answer.example),
  check:all(message.answer.check),
  checkAnswer:all(message.answer.check_answer),
  sourceVersion:message.source?.version||'demo-v12-gate6',
  verified:false,
  liveMode:message.mode
 });
}
function hydrateCards(){chatState().messages.filter(message=>message.role==='assistant'&&message.answer).forEach(pushCardFromMessage)}

function appendUser(question){
 const state=chatState();
 state.messages.push({id:uid('u'),role:'user',text:question,lang:language(),createdAt:new Date().toISOString()});
 state.draft='';saveChat(state);
}
function appendAssistant(payload,question,contextId){
 const state=chatState();
 if(payload.mode==='no_source'){
  state.messages.push({id:uid('a'),role:'assistant',type:'no_source',createdAt:new Date().toISOString(),gate6Mode:'no_source'});
 }else{
  const hash=btoa(unescape(encodeURIComponent(cacheKey(question,contextId)))).replace(/[^a-z0-9]/gi,'').slice(0,24);
  const cardId=`gate6_${payload.mode}_${hash}`;
  const message={id:uid('a'),role:'assistant',type:'verified',cardId,variant:'full',mode:payload.mode,answer:payload.answer,source:payload.source,createdAt:new Date().toISOString()};
  state.messages.push(message);pushCardFromMessage(message);
 }
 state.lastMode=payload.mode;
 state.lastSourceIds=payload.technical?.source_ids||[payload.source?.id].filter(Boolean);
 saveChat(state);setTechnical(payload);
}

function refreshChat(){G5.openChat({origin:lastOrigin});scheduleDecorate()}
function showLoading(){
 refreshChat();
 const body=$('demo-ai-chat-body');if(!body)return;
 const wrap=document.createElement('article');wrap.className='demo-ai-message is-assistant demo-ai-live-loading';
 const bubble=document.createElement('div');bubble.className='demo-ai-bubble';
 const dots=document.createElement('span');dots.className='demo-ai-loading-dots';dots.textContent='•••';
 const text=document.createElement('span');text.textContent=t().thinking;
 bubble.append(dots,text);wrap.appendChild(bubble);body.appendChild(wrap);body.scrollTop=body.scrollHeight;
}

function localFallback(question,reason){
 const normalized=normalize(question);
 const card=CARDS.find(item=>{
  const words=[...(item.aliases?.[language()]||[]),item.section?.[language()],item.topic?.[language()]]
   .filter(Boolean).flatMap(value=>normalize(value).split(' ')).filter(word=>word.length>4);
  return words.some(word=>normalized.includes(word));
 })||CARDS.find(item=>item.id==='allocative_vs_productive');
 if(!card)return{mode:'no_source',answer:null,source:null,usage:{model_called:false,charged:false,demo_limit_remaining:null},safety:{active_tour:false,guard_decision:'allowed'},technical:{latency_ms:0,cache_hit:false,source_ids:[]},reason};
 const get=value=>value?.[language()]||value?.ru||value?.en||'';
 return{mode:'fallback',answer:{short:get(card.short),simple:get(card.simple),example:get(card.example),check:get(card.check),check_answer:get(card.checkAnswer)},source:{id:card.id,title:'iClub Economics',topic:get(card.topic),section:get(card.section),version:card.sourceVersion||'economics-v1.0'},usage:{model_called:false,charged:false,demo_limit_remaining:null},safety:{active_tour:false,guard_decision:'allowed'},technical:{latency_ms:0,cache_hit:false,source_ids:[card.id]},fallback_reason:reason};
}

async function sessionToken(force=false){
 if(!force){const stored=read(sessionStorage,SESSION_KEY,null);if(stored?.token)return stored.token}
 const response=await fetch('/api/diagnostic-ai',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action:'session'})});
 if(!response.ok)throw new Error('session_failed');
 const data=await response.json();write(sessionStorage,SESSION_KEY,{token:data.session_token,version:data.version});return data.session_token;
}
async function callEndpoint(question,contextId,retry=true){
 const token=await sessionToken(false);
 const controller=new AbortController();const timer=setTimeout(()=>controller.abort(),8500);
 try{
  const response=await fetch('/api/diagnostic-ai',{method:'POST',headers:{'Content-Type':'application/json'},signal:controller.signal,body:JSON.stringify({session_token:token,question,language:language(),context_type:'subject_chat',context_id:contextId})});
  if(response.status===401&&retry){await sessionToken(true);return callEndpoint(question,contextId,false)}
  if(!response.ok)throw new Error(`endpoint_${response.status}`);
  const data=await response.json();
  if(data.session_token)write(sessionStorage,SESSION_KEY,{token:data.session_token,version:data.technical?.version||'gate6'});
  return data;
 }finally{clearTimeout(timer)}
}

async function generatedSend(question){
 if(busy||!question.trim())return;
 busy=true;
 const send=$('demo-ai-send');if(send)send.disabled=true;
 const contextId=nextContextId;nextContextId='demo_subject_chat';
 appendUser(question);showLoading();
 const key=cacheKey(question,contextId);const cache=cacheState();
 try{
  let payload;
  if(contextId!=='demo_force_fallback'&&cache.ai_cache[key]){
   payload={...cache.ai_cache[key],mode:'cached',usage:{...cache.ai_cache[key].usage,model_called:false,charged:false},technical:{...cache.ai_cache[key].technical,cache_hit:true,latency_ms:0}};
  }else{
   payload=await callEndpoint(question,contextId);
   if(payload.mode==='generated'){
    cache.ai_cache[key]={...payload,session_token:undefined,mode:'generated'};saveCache(cache);
   }
  }
  appendAssistant(payload,question,contextId);refreshChat();
  if(payload.mode==='generated')toast(t().retry);
 }catch(error){
  const payload=localFallback(question,error?.name==='AbortError'?'client_timeout':'network_error');
  appendAssistant(payload,question,contextId);refreshChat();toast(t().networkFallback);
 }finally{
  busy=false;
  const activeSend=$('demo-ai-send');if(activeSend)activeSend.disabled=false;
  const input=$('demo-ai-input');if(input)input.value='';
 }
}

function injectDemoControls(){
 const tools=q('.demo-ai-composer-tools');if(!tools)return;
 const definitions=[[t().live,'live'],[t().cache,'cache'],[t().fallback,'fallback']];
 definitions.forEach(([label,mode])=>{
  let button=tools.querySelector(`[data-gate6-demo="${mode}"]`);
  if(!button){button=document.createElement('button');button.type='button';button.className='demo-ai-fill-btn demo-ai-gate6-chip';button.dataset.gate6Demo=mode;tools.appendChild(button)}
  if(button.textContent!==label)button.textContent=label;
 });
}
function fillDemo(mode){
 const input=$('demo-ai-input');if(!input)return;
 input.value=t().liveQuestion;input.dispatchEvent(new Event('input',{bubbles:true}));
 nextContextId=mode==='fallback'?'demo_force_fallback':'demo_subject_chat';input.focus();toast(t().filled);
}

function relabelMessages(){
 q('.demo-ai-chat-body')?.querySelectorAll('.demo-ai-message.is-assistant').forEach(message=>{
  const source=message.querySelector('.demo-ai-source span')?.textContent||'';
  const badge=message.querySelector('.demo-ai-verified span');if(!badge)return;
  let label=null,cls=null;
  if(source.includes(t().generated)){label=t().generated;cls='is-live-generated'}
  else if(source.includes(t().cached)){label=t().cached;cls='is-live-cached'}
  else if(source.includes(t().fallbackMode)){label=t().fallbackMode;cls='is-live-fallback'}
  if(!label)return;
  if(badge.textContent!==label)badge.textContent=label;
  if(!message.classList.contains(cls))message.classList.add(cls);
 });
}
function decorate(){injectDemoControls();relabelMessages()}
function scheduleDecorate(delay=0){clearTimeout(decorateTimer);decorateTimer=setTimeout(decorate,delay)}

function rememberOrigin(event){
 if(event.target.closest('#demo-ai-hub-card'))lastOrigin='courses-subject-hub';
 if(event.target.closest('.demo-result-ai-action'))lastOrigin='courses-practice-result';
 if(event.target.closest('[data-review-question]'))lastOrigin='courses-practice-review';
}

document.addEventListener('click',event=>{
 rememberOrigin(event);
 const demo=event.target.closest('[data-gate6-demo]');
 if(demo){event.preventDefault();event.stopImmediatePropagation();fillDemo(demo.dataset.gate6Demo);return}
 if(event.target.closest('#demo-ai-send')){
  const question=$('demo-ai-input')?.value||'';
  if(!question.trim()||G5.findCard(question))return;
  event.preventDefault();event.stopImmediatePropagation();generatedSend(question);
 }
},true);

document.addEventListener('keydown',event=>{
 if(event.target.id!=='demo-ai-input'||event.key!=='Enter'||event.shiftKey)return;
 const question=event.target.value||'';
 if(!question.trim()||G5.findCard(question))return;
 event.preventDefault();event.stopImmediatePropagation();generatedSend(question);
},true);

document.addEventListener('click',event=>{
 if(event.target.closest('[data-plan],[data-lang],#demo-ai-hub-card,[data-chat-tab],[data-history-message],[data-ai-action],.demo-ai-show-check'))scheduleDecorate(80);
});

hydrateCards();scheduleDecorate(180);
window.ICLUB_DEMO_GATE6={sendGenerated:generatedSend,cache:()=>cacheState().ai_cache,clearCache:()=>saveCache({...cacheState(),ai_cache:{}}),health:()=>fetch('/api/diagnostic-ai').then(response=>response.json())};
})();