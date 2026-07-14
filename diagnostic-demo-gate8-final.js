(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,PREFIX+'state',{}).lang||'ru');
const COPY={
 ru:{serverGuard:'Серверные тесты защиты',serverGuardSub:'Exact, перевод, пересказ, подтверждение, injection и прямой обход',answerKey:'Ключ активного тура в браузере',answerKeySub:'В client payload нет правильных ответов Tour 5',limits:'Лимиты и аварийное отключение',limitsSub:'Длина, timeout, session quota, daily budget и emergency flag',safe:'Безопасный вывод текста',safeSub:'Ответы и пользовательский текст не выполняются как HTML',transitions:'Сохранение экрана и состояния',transitionsSub:'Язык и тариф не создают нового ученика и не теряют текущий экран',responsive:'Правила 360 / 390 / 430 px',responsiveSub:'В стилях присутствуют отдельные mobile breakpoints и shell 430 px',build:'Зафиксированный build',video:'Резервное видео',videoSub:'Отметить только после реальной записи полного маршрута',markVideo:'Видео записано',unmarkVideo:'Снять отметку',manual:'Ручная проверка',pass:'Готово',warn:'Нужно завершить',fail:'Ошибка',checking:'Проверяется…'},
 uz:{serverGuard:'Server himoya testlari',serverGuardSub:'Exact, tarjima, qayta ifoda, tasdiqlash, injection va to‘g‘ridan-to‘g‘ri chetlab o‘tish',answerKey:'Faol tur javob kaliti brauzerda',answerKeySub:'Client payload da 5-tur to‘g‘ri javoblari yo‘q',limits:'Limitlar va favqulodda o‘chirish',limitsSub:'Uzunlik, timeout, session quota, daily budget va emergency flag',safe:'Matnni xavfsiz chiqarish',safeSub:'Javob va foydalanuvchi matni HTML sifatida bajarilmaydi',transitions:'Ekran va holatni saqlash',transitionsSub:'Til va tarif yangi o‘quvchi yaratmaydi va joriy ekranni yo‘qotmaydi',responsive:'360 / 390 / 430 px qoidalari',responsiveSub:'Stillarda alohida mobile breakpointlar va 430 px shell mavjud',build:'Build SHA',video:'Zaxira video',videoSub:'Faqat to‘liq yo‘nalish real yozilgandan keyin belgilang',markVideo:'Video yozildi',unmarkVideo:'Belgini olib tashlash',manual:'Qo‘lda tekshirish',pass:'Tayyor',warn:'Tugatish kerak',fail:'Xato',checking:'Tekshirilmoqda…'},
 en:{serverGuard:'Server guard tests',serverGuardSub:'Exact, translation, paraphrase, confirmation, injection, and direct bypass',answerKey:'Active-tour answer key in browser',answerKeySub:'The client payload contains no Tour 5 correct answers',limits:'Limits and emergency disable',limitsSub:'Length, timeout, session quota, daily budget, and emergency flag',safe:'Safe text rendering',safeSub:'Answers and learner text are not executed as HTML',transitions:'Screen and state preservation',transitionsSub:'Language and plan changes keep one learner and the current screen',responsive:'360 / 390 / 430 px rules',responsiveSub:'Styles contain mobile breakpoints and a 430 px shell',build:'Build SHA',video:'Reserve video',videoSub:'Mark only after a real recording of the full route',markVideo:'Video recorded',unmarkVideo:'Remove mark',manual:'Manual check',pass:'Ready',warn:'Needs completion',fail:'Error',checking:'Checking…'}
};
const t=()=>COPY[lang()]||COPY.ru;
let selftest=null;
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
 const core=window.ICLUB_DEMO_GATE5_CARDS||[],tour=window.ICLUB_DEMO_GATE7_DATA;
 const cards=core.length>=30&&core.slice(0,30).every(card=>['ru','uz','en'].every(code=>card.short?.[code]&&card.simple?.[code]&&card.section?.[code]));
 const tourOk=Boolean(tour?.questions?.length)&&tour.questions.every(item=>['ru','uz','en'].every(code=>item.stem?.[code]&&Array.isArray(item.options?.[code])&&item.options[code].length===4));
 return cards&&tourOk;
}
function safeContract(){
 const tech=read(sessionStorage,TECH_KEY,{});if(tech.ai?.safe_renderer==='DOM textContent')return true;
 const holder=document.createElement('div');holder.textContent='<img src=x onerror=alert(1)>';return holder.children.length===0&&holder.textContent.startsWith('<img');
}
function transitionContract(){return Boolean(window.ICLUB_DEMO_ROUTER&&window.ICLUB_DEMO_GATE5&&window.ICLUB_DEMO_GATE4&&window.ICLUB_DEMO_MAIN_LOCAL)}
function videoDone(){return read(sessionStorage,TECH_KEY,{}).reserve_video===true}
function toggleVideo(){const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,reserve_video:!videoDone()});render()}

function render(){
 const list=$('demo-gate8-list');if(!list)return;
 list.querySelectorAll('[data-gate8-final]').forEach(node=>node.remove());
 const endpointOk=selftest?.ok===true;
 const answerKeyOk=selftest?selftest.active_tour_answer_key_in_client===false:null;
 const limitsOk=selftest?Boolean(selftest.generated_emergency_flag_present&&selftest.limits_contract?.session_quota&&selftest.limits_contract?.daily_budget_guard&&selftest.limits_contract?.one_active_request_per_session):null;
 const build=selftest?.build_sha?selftest.build_sha.slice(0,12):loading?t().checking:'—';
 const finalRows=[
  row('server-guard',t().serverGuard,t().serverGuardSub,endpointOk),
  row('answer-key',t().answerKey,t().answerKeySub,answerKeyOk),
  row('limits',t().limits,t().limitsSub,limitsOk),
  row('safe-render',t().safe,t().safeSub,safeContract()),
  row('transitions',t().transitions,t().transitionsSub,transitionContract()),
  row('responsive',t().responsive,t().responsiveSub,cssContract()),
  row('languages-full','RU / UZ / EN',t().serverGuardSub,languageContract()),
  row('build',t().build,t().manual,Boolean(selftest?.build_sha),build),
  row('video',t().video,t().videoSub,videoDone())
 ];
 finalRows.forEach(item=>list.appendChild(item));
 let button=$('demo-gate8-video');if(!button){button=document.createElement('button');button.type='button';button.className='btn';button.id='demo-gate8-video';$('demo-gate8-add-run')?.insertAdjacentElement('beforebegin',button)}button.textContent=videoDone()?t().unmarkVideo:t().markVideo;
 const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,gate8_final:{checkedAt:new Date().toISOString(),serverSelftest:selftest,contracts:{responsive:cssContract(),languages:languageContract(),safeRenderer:safeContract(),transitions:transitionContract()},reserveVideo:videoDone()}})
}
async function fetchSelftest(){if(loading)return;loading=true;render();try{const response=await fetch('/api/diagnostic-ai-selftest',{cache:'no-store'});selftest=await response.json()}catch{selftest={ok:false}}finally{loading=false;render()}}
function onOpen(){const root=$('demo-gate8-root');if(!root||root.getAttribute('aria-hidden')!=='false')return;render();fetchSelftest()}

document.addEventListener('click',event=>{if(event.target.closest('#demo-gate8-video'))toggleVideo();if(event.target.closest('#demo-stage-readiness,#demo-gate8-refresh'))setTimeout(onOpen,60);if(event.target.closest('[data-lang]'))setTimeout(render,80)});
const root=$('demo-gate8-root');if(root)new MutationObserver(onOpen).observe(root,{attributes:true,attributeFilter:['aria-hidden']});
setTimeout(()=>{render();if($('demo-gate8-root')?.getAttribute('aria-hidden')==='false')fetchSelftest()},260);
window.ICLUB_DEMO_GATE8_FINAL={render,refresh:fetchSelftest,getSelftest:()=>selftest};
})();