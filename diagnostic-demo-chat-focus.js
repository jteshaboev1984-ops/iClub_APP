(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const CHAT_KEY=PREFIX+'chat';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key)||'')??fallback}catch{return fallback}};
const writeSession=(key,value)=>{try{sessionStorage.setItem(key,JSON.stringify(value))}catch{}};
const writeLocal=(key,value)=>{try{localStorage.setItem(key,JSON.stringify(value))}catch{}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(PREFIX+'state',{}).lang||'ru');
const text={ru:{theory:'Только теория',source:'iClub Economics · Только теория'},uz:{theory:'Faqat nazariya',source:'iClub Economics · Faqat nazariya'},en:{theory:'Theory only',source:'iClub Economics · Theory only'}};
const normalize=value=>String(value||'').toLowerCase().replace(/ё/g,'е').replace(/[’‘`]/g,"'").replace(/[^a-zа-я0-9қғўҳ\s]+/gi,' ').replace(/\s+/g,' ').trim();
let timer=null;

function patchClientGuard(){
 const api=window.ICLUB_DEMO_GATE7;if(!api||api.__theoryPatch)return;
 const originalGuard=api.guard.bind(api);
 const originalHandle=api.handleBlocked.bind(api);
 const theoryPhrases=['what is','how does','explain the theory','in general','что такое','как в целом','объясни теорию','в общем','nima','qanday ta’sir','umuman','nazariyani tushuntir'];
 const solutionPhrases=['solve','calculate','answer','which option','am i right','remove two','реши','посчитай','ответ','какой вариант','правильно ли','убери два','yech','hisobla','javob','qaysi variant','to‘g‘rimi'];
 api.guard=question=>{
  const decision=originalGuard(question);if(!decision.blocked)return decision;
  const value=normalize(question);const hasDigits=/\d/.test(value);const theory=theoryPhrases.some(phrase=>value.includes(normalize(phrase)));const solution=solutionPhrases.some(phrase=>value.includes(normalize(phrase)));
  if(!hasDigits&&theory&&!solution)return{...decision,blocked:false,theoryAllowed:api.isActive(),reason:api.isActive()?'theory_only':'allowed_general',matchedQuestionId:null};
  return decision;
 };
 api.handleBlocked=(question,decision)=>{
  const chat=read(CHAT_KEY,{messages:[]});chat.messages=Array.isArray(chat.messages)?chat.messages:[];
  const last=chat.messages[chat.messages.length-1];
  if(last?.role==='user'&&normalize(last.text)===normalize(question)){chat.messages.pop();writeLocal(CHAT_KEY,chat)}
  return originalHandle(question,decision);
 };
 api.__theoryPatch=true;
 const data=window.ICLUB_DEMO_GATE7_DATA;
 if(data){
  const localize=value=>value?.[lang()]??value?.ru??value?.en??value?.uz??value??'';
  const cases={exact:localize(data.questions[0].stem),noOptions:localize(data.tests.noOptions),paraphrase:localize(data.tests.paraphrase),confirmation:localize(data.tests.confirmation),injection:localize(data.tests.injection),theory:localize(data.tests.theory)};
  const results=Object.fromEntries(Object.entries(cases).map(([key,value])=>[key,api.guard(value)]));
  const pass=results.exact.blocked&&results.noOptions.blocked&&results.paraphrase.blocked&&results.confirmation.blocked&&results.injection.blocked&&!results.theory.blocked;
  const tech=read(TECH_KEY,{});writeSession(TECH_KEY,{...tech,guard_tests:{pass,cases:Object.fromEntries(Object.entries(results).map(([key,value])=>[key,{blocked:value.blocked,reason:value.reason}]))}});
 }
}

function routeActiveTourSend(event,question){
 const guard=window.ICLUB_DEMO_GATE7;
 if(!guard?.isActive?.()||!String(question||'').trim())return false;
 event.preventDefault();event.stopImmediatePropagation();
 window.ICLUB_DEMO_GATE6?.sendGenerated?.(String(question).trim());
 return true;
}

document.addEventListener('click',event=>{if(!event.target.closest('#demo-ai-send'))return;routeActiveTourSend(event,$('demo-ai-input')?.value||'')},true);
document.addEventListener('keydown',event=>{if(event.target.id!=='demo-ai-input'||event.key!=='Enter'||event.shiftKey)return;routeActiveTourSend(event,event.target.value||'')},true);

function scrollLatest(smooth=true){
 clearTimeout(timer);timer=setTimeout(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>{
  const visible=[...document.querySelectorAll('#demo-ai-chat-body .demo-ai-message:not([hidden])')];
  const latest=visible[visible.length-1];if(!latest)return;
  const composer=$('demo-ai-composer');const rect=latest.getBoundingClientRect();const topOffset=112;const bottomLimit=window.innerHeight-(composer?.offsetHeight||96)-12;
  if(rect.top<topOffset||rect.bottom>bottomLimit){const top=Math.max(0,window.scrollY+rect.top-topOffset);window.scrollTo({top,behavior:smooth?'smooth':'auto'})}
 })),20)
}
function decorateTheory(){
 const state=read(CHAT_KEY,{messages:[]});const messages=(state.messages||[]).filter(message=>message.role==='assistant');const nodes=[...document.querySelectorAll('#demo-ai-chat-body .demo-ai-message.is-assistant')];
 nodes.forEach((node,index)=>{const message=messages[index];if(message?.mode!=='theory_only')return;node.classList.add('is-theory-only-answer');const badge=node.querySelector('.demo-ai-verified span');if(badge)badge.textContent=(text[lang()]||text.ru).theory;const source=node.querySelector('.demo-ai-source span');if(source&&!source.textContent.includes((text[lang()]||text.ru).theory))source.textContent=`${(text[lang()]||text.ru).source} · ${message.source?.section||message.source?.topic||'Economics'}`})
}
function loadScript(src,version){
 if(document.querySelector(`script[data-demo-src="${src}"]`))return Promise.resolve();
 return new Promise((resolve,reject)=>{const script=document.createElement('script');script.src=`${src}?v=${version}`;script.dataset.demoSrc=src;script.onload=resolve;script.onerror=reject;document.body.appendChild(script)});
}
function loadStyle(src,version,key){
 if(document.querySelector(`link[data-demo-style="${key||src}"]`))return;
 const link=document.createElement('link');link.rel='stylesheet';link.href=`${src}?v=${version}`;link.dataset.demoStyle=key||src;document.head.appendChild(link);
}
function loadPremiumAssets(){
 loadStyle('diagnostic-demo-stitch-premium.css','stitch-premium-1','stitch-premium');
 loadStyle('diagnostic-demo-premium-hotfix.css','premium-hotfix-1','premium-hotfix');
 loadStyle('diagnostic-demo-premium-fixes.css','premium-fixes-1','premium-fixes');
 return loadScript('diagnostic-demo-stitch-result.js','stitch-result-1')
  .then(()=>loadScript('diagnostic-demo-stitch-premium-core.js','stitch-premium-2'))
  .then(()=>loadScript('diagnostic-demo-premium-fixes.js','premium-fixes-2'))
  .then(()=>loadScript('diagnostic-demo-premium-runtime.js','premium-runtime-1'));
}
function loadFinalAssets(){
 if(!document.querySelector('link[data-gate8-style]')){const link=document.createElement('link');link.rel='stylesheet';link.href='diagnostic-demo-gate8.css?v=gate8-3';link.dataset.gate8Style='1';document.head.appendChild(link)}
 loadScript('diagnostic-demo-gate8.js','gate8-3')
  .then(()=>loadScript('diagnostic-demo-router.js','router-1'))
  .then(()=>loadScript('diagnostic-demo-context.js','context-1'))
  .then(()=>loadScript('diagnostic-demo-gate8-final.js','gate8-final-1'))
  .then(()=>loadPremiumAssets())
  .catch(()=>{});
}
const body=$('demo-ai-chat-body');if(body)new MutationObserver(mutations=>{if(!mutations.some(item=>item.addedNodes.length||item.removedNodes.length))return;decorateTheory();scrollLatest(true)}).observe(body,{childList:true});
document.addEventListener('click',event=>{if(event.target.closest('[data-lang],[data-chat-tab],#demo-ai-hub-card'))setTimeout(()=>{patchClientGuard();decorateTheory();scrollLatest(false)},90)});
setTimeout(()=>{patchClientGuard();decorateTheory();scrollLatest(false);loadFinalAssets()},220);
window.ICLUB_DEMO_CHAT_FOCUS={scrollLatest,decorateTheory,patchClientGuard};
})();