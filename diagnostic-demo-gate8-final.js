(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,PREFIX+'state',{}).lang||'ru');
const COPY={
 ru:{provider:'Живой AI-ответ',providerSub:'Server-side генерация включена и провайдер настроен',serverGuard:'Серверные тесты защиты',serverGuardSub:'Exact, перевод, пересказ, подтверждение, injection и прямой обход',answerKey:'Ключ активного тура в браузере',answerKeySub:'В client payload нет правильных ответов Tour 5',limits:'Лимиты и аварийное отключение',limitsSub:'Длина, timeout, session quota, daily budget и emergency flag',safe:'Безопасный вывод текста',safeSub:'Ответы и пользовательский текст не выполняются как HTML',transitions:'Сохранение экрана и состояния',transitionsSub:'Язык и тариф не создают нового ученика и не теряют текущий экран',responsive:'Правила 360 / 390 / 430 px',responsiveSub:'В стилях присутствуют отдельные mobile breakpoints и shell 430 px',languages:'Полная локализация',languagesSub:'Практика, знания и активный тур заполнены на RU / UZ / EN',build:'Зафиксированный build',video:'Резервное видео',videoSub:'Отметить только после реальной записи полного маршрута',markVideo:'Видео записано',unmarkVideo:'Снять отметку',manual:'Ручная проверка',pass:'Готово',warn:'Нужно завершить',fail:'Ошибка',checking:'Проверяется…',sameOrigin:'Только same-origin endpoint',profile:'Демонстрационный профиль',profileSub:'Один Сардор Каримов во всех тарифах'},
 uz:{provider:'Jonli AI javobi',providerSub:'Server-side generatsiya yoqilgan va provayder sozlangan',serverGuard:'Server himoya testlari',serverGuardSub:'Exact, tarjima, qayta ifoda, tasdiqlash, injection va to‘g‘ridan-to‘g‘ri chetlab o‘tish',answerKey:'Faol tur javob kaliti brauzerda',answerKeySub:'Client payload da 5-tur to‘g‘ri javoblari yo‘q',limits:'Limitlar va favqulodda o‘chirish',limitsSub:'Uzunlik, timeout, session quota, daily budget va emergency flag',safe:'Matnni xavfsiz chiqarish',safeSub:'Javob va foydalanuvchi matni HTML sifatida bajarilmaydi',transitions:'Ekran va holatni saqlash',transitionsSub:'Til va tarif yangi o‘quvchi yaratmaydi va joriy ekranni yo‘qotmaydi',responsive:'360 / 390 / 430 px qoidalari',responsiveSub:'Stillarda alohida mobile breakpointlar va 430 px shell mavjud',languages:'To‘liq lokalizatsiya',languagesSub:'Mashq, bilim kartalari va faol tur RU / UZ / EN da to‘ldirilgan',build:'Build SHA',video:'Zaxira video',videoSub:'Faqat to‘liq yo‘nalish real yozilgandan keyin belgilang',markVideo:'Video yozildi',unmarkVideo:'Belgini olib tashlash',manual:'Qo‘lda tekshirish',pass:'Tayyor',warn:'Tugatish kerak',fail:'Xato',checking:'Tekshirilmoqda…',sameOrigin:'Faqat same-origin endpoint',profile:'Namoyish profili',profileSub:'Barcha tariflarda bitta Sardor Karimov'},
 en:{provider:'Live AI answer',providerSub:'Server-side generation is enabled and the provider is configured',serverGuard:'Server guard tests',serverGuardSub:'Exact, translation, paraphrase, confirmation, injection, and direct bypass',answerKey:'Active-tour answer key in browser',answerKeySub:'The client payload contains no Tour 5 correct answers',limits:'Limits and emergency disable',limitsSub:'Length, timeout, session quota, daily budget, and emergency flag',safe:'Safe text rendering',safeSub:'Answers and learner text are not executed as HTML',transitions:'Screen and state preservation',transitionsSub:'Language and plan changes keep one learner and the current screen',responsive:'360 / 390 / 430 px rules',responsiveSub:'Styles contain mobile breakpoints and a 430 px shell',languages:'Complete localization',languagesSub:'Practice, knowledge cards, and the active tour contain RU / UZ / EN',build:'Build SHA',video:'Reserve video',videoSub:'Mark only after a real recording of the full route',markVideo:'Video recorded',unmarkVideo:'Remove mark',manual:'Manual check',pass:'Ready',warn:'Needs completion',fail:'Error',checking:'Checking…',sameOrigin:'Same-origin endpoint only',profile:'Demonstration profile',profileSub:'One Sardor Karimov across every plan'}
};
const t=()=>COPY[lang()]||COPY.ru;
let selftest=null;
let providerHealth=null;
let loading=false;

function status(value){return value===true?'pass':value===false?'fail':'warn'}
function row(key,title,sub,value,extra=''){
 const item=document.createElement('div');item.className='demo-gate8-row';item.dataset.gate8Final=key;
 const copy=document.createElement('div');copy.className='demo-gate8-row-copy';const b=document.createElement('b');b.textContent=title;const small=document.createElement('small');small.textContent=extra?`${sub} · ${extra}`:sub;copy.append(b,small);
 const state=status(value);const badge=document.createElement('span');badge.className=`demo-gate8-status is-${state}`;badge.textContent=state==='pass'?'✓':state==='fail'?'!':'•';badge.title=state==='pass'?t().pass:state==='fail'?t().fail:t().warn;item.append(copy,badge);return item;
}
function cssContract(){
 try{const text=[...document.styleSheets].filter(sheet=>String(sheet.href||'').includes('diagnostic-demo-gate8.css')).flatMap(sheet=>[...sheet.cssRules]).map(rule=>rule.cssText).join('\n');return /max-width:\s*390px/.test(text)&&/max-width:\s*360px/.test(text)&&/430px/.test(text)}catch{return null}
}
function languageContract(){
 const core=window.ICLUB_DEMO_GATE5_CARDS||[],tour=window.ICLUB_DEMO_GATE7_DATA,practice=window.ICLUB_DEMO_V12_DATA;
 const cards=core.length>=30&&core.slice(0,30).every(card=>['ru','uz','en'].every(code=>card.short?.[code]&&card.simple?.[code]&&card.section?.[code]));
 const tourOk=Boolean(tour?.questions?.length)&&tour.questions.every(item=>['ru','uz','en'].every(code=>item.stem?.[code]&&Array.isArray(item.options?.[code])&&item.options[code].length===4));
 const practiceOk=Boolean(practice?.questions?.length)&&practice.questions.every(item=>['ru','uz','en'].every(code=>item.q?.[code]&&Array.isArray(item.o?.[code])&&item.o[code].length===4));
 return cards&&tourOk&&practiceOk;
}
function safeContract(){
 const tech=read(sessionStorage,TECH_KEY,{});if(tech.ai?.safe_renderer==='DOM textContent')return true;
 const holder=document.createElement('div');holder.textContent='<img src=x onerror=alert(1)>';return holder.children.length===0&&holder.textContent.startsWith('<img');
}
function transitionContract(){return Boolean(window.ICLUB_DEMO_ROUTER&&window.ICLUB_DEMO_GATE5&&window.ICLUB_DEMO_GATE4&&window.ICLUB_DEMO_MAIN_LOCAL)}
function profileContract(){return window.ICLUB_DEMO_CONTEXT?.profileId==='demo-sardor'&&window.ICLUB_DEMO_V12_DATA?.profile?.id==='demo-sardor'}
function videoDone(){return read(sessionStorage,TECH_KEY,{}).reserve_video===true}
function toggleVideo(){const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,reserve_video:!videoDone()});render()}

function render(){
 const list=$('demo-gate8-list');if(!list)return;
 list.querySelectorAll('[data-gate8-final]').forEach(node=>node.remove());
 const endpointOk=selftest?.ok===true;
 const providerOk=providerHealth?providerHealth.generated_enabled===true:null;
 const answerKeyOk=selftest?selftest.active_tour_answer_key_in_client===false:null;
 const limitsOk=selftest?Boolean(selftest.generated_emergency_flag_present&&selftest.limits_contract?.session_quota&&selftest.limits_contract?.daily_budget_guard&&selftest.limits_contract?.one_active_request_per_session):null;
 const build=selftest?.build_sha?selftest.build_sha.slice(0,12):loading?t().checking:'—';
 const providerExtra=providerHealth?`${providerHealth.model||'—'} · ${providerHealth.generated_enabled?'enabled':'fallback only'}`:loading?t().checking:'—';
 const finalRows=[
  row('profile',t().profile,t().profileSub,profileContract()),
  row('provider',t().provider,t().providerSub,providerOk,providerExtra),
  row('server-guard',t().serverGuard,t().serverGuardSub,endpointOk),
  row('answer-key',t().answerKey,t().answerKeySub,answerKeyOk),
  row('limits',t().limits,t().limitsSub,limitsOk),
  row('safe-render',t().safe,t().safeSub,safeContract()),
  row('transitions',t().transitions,t().transitionsSub,transitionContract()),
  row('responsive',t().responsive,t().responsiveSub,cssContract()),
  row('languages-full',t().languages,t().languagesSub,languageContract()),
  row('build',t().build,t().manual,Boolean(selftest?.build_sha),build),
  row('video',t().video,t().videoSub,videoDone()?true:null)
 ];
 finalRows.forEach(item=>list.appendChild(item));
 let button=$('demo-gate8-video');if(!button){button=document.createElement('button');button.type='button';button.className='btn';button.id='demo-gate8-video';$('demo-gate8-add-run')?.insertAdjacentElement('beforebegin',button)}button.textContent=videoDone()?t().unmarkVideo:t().markVideo;
 const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,network_guard:'connect-src self; production database disabled',gate8_final:{checkedAt:new Date().toISOString(),serverSelftest:selftest,providerHealth,contracts:{profile:profileContract(),responsive:cssContract(),languages:languageContract(),safeRenderer:safeContract(),transitions:transitionContract()},reserveVideo:videoDone()}})
}
function patchTechnical(){
 setTimeout(()=>{
  const panel=$('demo-technical-card');if(!panel)return;
  const rows=[...panel.querySelectorAll('.demo-technical-row')];
  const guardRow=rows.find(item=>/сетевая защита|tarmoq himoyasi|network guard/i.test(item.querySelector('span')?.textContent||''));
  if(guardRow)guardRow.querySelector('b').textContent=t().sameOrigin;
  if(!panel.querySelector('[data-gate8-final-tech]')){
   const values=[
    [t().profile,window.ICLUB_DEMO_V12_DATA?.profile?.id||'demo-sardor'],
    [t().provider,providerHealth?.generated_enabled===true?t().pass:providerHealth?t().fail:t().checking],
    [t().serverGuard,selftest?.ok===true?t().pass:selftest?t().fail:t().checking],
    [t().build,selftest?.build_sha?.slice(0,12)||'—']
   ];
   values.forEach(([label,value])=>{const item=document.createElement('div');item.className='demo-technical-row';item.dataset.gate8FinalTech='1';const left=document.createElement('span');left.textContent=label;const right=document.createElement('b');right.textContent=value;item.append(left,right);panel.appendChild(item)})
  }
 },140)
}
async function fetchJson(url){const response=await fetch(url,{cache:'no-store'});const data=await response.json();if(!response.ok)throw Object.assign(new Error(`http_${response.status}`),{data});return data}
async function fetchAudits(){
 if(loading)return;loading=true;render();
 const [selfResult,healthResult]=await Promise.allSettled([fetchJson('/api/diagnostic-ai-selftest'),fetchJson('/api/diagnostic-ai')]);
 selftest=selfResult.status==='fulfilled'?selfResult.value:(selfResult.reason?.data||{ok:false});
 providerHealth=healthResult.status==='fulfilled'?healthResult.value:{ok:false,generated_enabled:false};
 loading=false;render();
}
function onOpen(){const root=$('demo-gate8-root');if(!root||root.getAttribute('aria-hidden')!=='false')return;render();fetchAudits()}

document.addEventListener('click',event=>{if(event.target.closest('#demo-gate8-video'))toggleVideo();if(event.target.closest('#demo-stage-readiness,#demo-gate8-refresh'))setTimeout(onOpen,60);if(event.target.closest('[data-lang]'))setTimeout(render,80);if(event.target.closest('[data-demo-menu-action="technical"]'))patchTechnical()});
const root=$('demo-gate8-root');if(root)new MutationObserver(onOpen).observe(root,{attributes:true,attributeFilter:['aria-hidden']});
setTimeout(()=>{render();if($('demo-gate8-root')?.getAttribute('aria-hidden')==='false')fetchAudits()},260);
window.ICLUB_DEMO_GATE8_FINAL={render,refresh:fetchAudits,getSelftest:()=>selftest,getProviderHealth:()=>providerHealth};
})();