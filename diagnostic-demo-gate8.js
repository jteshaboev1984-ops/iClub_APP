(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const TECH_KEY=PREFIX+'technical';
const STAGE_KEY=PREFIX+'stage';
const STATE_KEY=PREFIX+'state';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);
const qa=selector=>[...document.querySelectorAll(selector)];
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,STATE_KEY,{}).lang||'ru');
const currentPlan=()=>q('[data-plan].is-active')?.dataset.plan||read(localStorage,STATE_KEY,{}).plan||'free';

const COPY={
 ru:{live:'Живой AI-ответ',cache:'Повторный запрос',fallback:'Резервный ответ',active:'Активный тур 5',activeOn:'Активный тур 5 включён',task:'Задание тура',paraphrase:'Перефразированное задание',theory:'Общая теория',ready:'Готовность показа',title:'Проверка готовности demo',sub:'Технические и сценические условия перед показом',shell:'Оболочка приложения',shellSub:'Demo использует компактную оболочку iClub',mobile:'Экраны 360 / 390 / 430 px',mobileSub:'Контент и поле ответа не выходят за границы',languages:'RU / UZ / EN',languagesSub:'Основные AI-карточки заполнены на трёх языках',guard:'Защита активного тура',guardSub:'Клиентские тесты exact, paraphrase и theory',database:'Изоляция от production',databaseSub:'В demo не подключены Supabase-скрипты',server:'Server endpoint',serverSub:'Endpoint отвечает и сообщает отсутствие production DB',runs:'Полные сценические прогоны',count:n=>`${n} из 10`,addRun:'Открыть чек-лист прогона',refresh:'Проверить снова',close:'Закрыть',pass:'Готово',warn:'Нужна проверка',fail:'Ошибка'},
 uz:{live:'Jonli AI javobi',cache:'Takroriy so‘rov',fallback:'Zaxira javob',active:'Faol 5-tur',activeOn:'Faol 5-tur yoqilgan',task:'Tur topshirig‘i',paraphrase:'Qayta ifodalangan topshiriq',theory:'Umumiy nazariya',ready:'Namoyishga tayyorlik',title:'Demo tayyorligini tekshirish',sub:'Namoyishdan oldingi texnik va sahna shartlari',shell:'Ilova qobig‘i',shellSub:'Demo iClub ixcham qobig‘idan foydalanadi',mobile:'360 / 390 / 430 px ekranlar',mobileSub:'Kontent va javob maydoni chegaradan chiqmaydi',languages:'RU / UZ / EN',languagesSub:'Asosiy AI kartalari uch tilda to‘ldirilgan',guard:'Faol tur himoyasi',guardSub:'Exact, paraphrase va theory klient testlari',database:'Production dan izolyatsiya',databaseSub:'Demo Supabase skriptlarini yuklamaydi',server:'Server endpoint',serverSub:'Endpoint ishlaydi va production DB yo‘qligini bildiradi',runs:'To‘liq sahna sinovlari',count:n=>`10 tadan ${n}`,addRun:'Sinov chek-listini ochish',refresh:'Qayta tekshirish',close:'Yopish',pass:'Tayyor',warn:'Tekshirish kerak',fail:'Xato'},
 en:{live:'Live AI answer',cache:'Repeat request',fallback:'Fallback answer',active:'Active Tour 5',activeOn:'Active Tour 5 enabled',task:'Tour task',paraphrase:'Paraphrased task',theory:'General theory',ready:'Presentation readiness',title:'Demo readiness check',sub:'Technical and stage conditions before the presentation',shell:'Application shell',shellSub:'The demo uses the compact iClub shell',mobile:'360 / 390 / 430 px screens',mobileSub:'Content and composer remain within the viewport',languages:'RU / UZ / EN',languagesSub:'Core AI cards contain all three languages',guard:'Active-tour protection',guardSub:'Client exact, paraphrase, and theory tests',database:'Production isolation',databaseSub:'The demo does not load Supabase scripts',server:'Server endpoint',serverSub:'The endpoint responds and reports no production DB access',runs:'Full presentation runs',count:n=>`${n} of 10`,addRun:'Open rehearsal checklist',refresh:'Check again',close:'Close',pass:'Ready',warn:'Needs check',fail:'Error'}
};
const t=()=>COPY[language()]||COPY.ru;
let sheetOpen=false;
let endpointStatus='pending';
let endpointMeta=null;
let decorateTimer=null;

function stage(){const value=read(sessionStorage,STAGE_KEY,{});return{runs:Math.max(0,Math.min(10,Number(value.runs||0))),current:value.current||{done:[]},video:!!value.video,lastCompleted:value.lastCompleted||null}}
function saveStage(value){write(sessionStorage,STAGE_KEY,{...stage(),...value})}
function naturalize(){
 const map=[['[data-gate6-demo="live"]',t().live],['[data-gate6-demo="cache"]',t().cache],['[data-gate6-demo="fallback"]',t().fallback],['[data-gate7-fill="exact"]',t().task],['[data-gate7-fill="paraphrase"]',t().paraphrase],['[data-gate7-fill="theory"]',t().theory]];
 map.forEach(([selector,label])=>qa(selector).forEach(node=>{if(node.textContent!==label)node.textContent=label}));
 const active=$('demo-active-tour-button');if(active)active.textContent=window.ICLUB_DEMO_GATE7?.isActive?.()?t().activeOn:t().active;
 const ready=$('demo-stage-readiness');if(ready)ready.textContent=t().ready;
}
function ensureMenuButton(){
 const actions=q('.demo-menu-actions');if(!actions)return null;
 let button=$('demo-stage-readiness');
 if(!button){button=document.createElement('button');button.id='demo-stage-readiness';button.type='button';button.className='btn';button.dataset.demoMenuAction='stage-readiness';const technical=$('demo-technical');technical?.insertAdjacentElement('afterend',button)}
 button.textContent=t().ready;return button;
}
function ensureSheet(){
 let root=$('demo-gate8-root');if(root)return root;
 root=document.createElement('div');root.id='demo-gate8-root';root.className='demo-gate8-root';root.setAttribute('aria-hidden','true');
 const backdrop=document.createElement('button');backdrop.type='button';backdrop.className='demo-gate8-backdrop';backdrop.dataset.gate8Close='1';
 const sheet=document.createElement('section');sheet.className='demo-gate8-sheet';
 const handle=document.createElement('div');handle.className='demo-gate8-handle';
 const head=document.createElement('div');head.className='demo-gate8-head';
 const copy=document.createElement('div');const title=document.createElement('div');title.className='demo-gate8-title';title.id='demo-gate8-title';const sub=document.createElement('div');sub.className='demo-gate8-sub';sub.id='demo-gate8-sub';copy.append(title,sub);
 const close=document.createElement('button');close.type='button';close.className='icon-btn demo-gate8-close';close.dataset.gate8Close='1';close.textContent='×';head.append(copy,close);
 const list=document.createElement('div');list.className='demo-gate8-list';list.id='demo-gate8-list';
 const runs=document.createElement('div');runs.className='demo-gate8-runs';runs.id='demo-gate8-runs';
 const actions=document.createElement('div');actions.className='demo-gate8-actions';
 const add=document.createElement('button');add.type='button';add.className='btn';add.id='demo-gate8-add-run';
 const refresh=document.createElement('button');refresh.type='button';refresh.className='btn primary';refresh.id='demo-gate8-refresh';actions.append(add,refresh);
 sheet.append(handle,head,list,runs,actions);root.append(backdrop,sheet);document.body.appendChild(root);return root;
}
function runCount(){return stage().runs}
function setRunCount(value){saveStage({runs:Math.max(0,Math.min(10,value))})}
function languageReady(){
 const cards=window.ICLUB_DEMO_GATE5_CARDS||[];if(cards.length<30)return false;
 return cards.slice(0,30).every(card=>['ru','uz','en'].every(code=>card.short?.[code]&&card.simple?.[code]&&card.section?.[code]));
}
function guardReady(){const tech=read(sessionStorage,TECH_KEY,{});return tech.guard_tests?.pass===true}
function shellReady(){const app=$('app'),hub=$('courses-subject-hub'),mark=q('img[src="iclub-ai-mark.svg"]');return Boolean(app&&hub&&mark)}
function mobileReady(){const app=$('app');if(!app)return false;const width=app.getBoundingClientRect().width;const composer=$('demo-ai-composer');return width<=431&&(!composer||composer.getBoundingClientRect().width<=431)}
function databaseReady(){return qa('script[src],link[href]').every(node=>!String(node.src||node.href||'').toLowerCase().includes('supabase'))}
function checks(){return[
 {key:'shell',title:t().shell,sub:t().shellSub,status:shellReady()?'pass':'fail'},
 {key:'mobile',title:t().mobile,sub:t().mobileSub,status:mobileReady()?'pass':'fail'},
 {key:'languages',title:t().languages,sub:t().languagesSub,status:languageReady()?'pass':'fail'},
 {key:'guard',title:t().guard,sub:t().guardSub,status:guardReady()?'pass':'warn'},
 {key:'database',title:t().database,sub:t().databaseSub,status:databaseReady()?'pass':'fail'},
 {key:'server',title:t().server,sub:t().serverSub,status:endpointStatus==='pass'?'pass':endpointStatus==='fail'?'fail':'warn'}
]}
function statusText(status){return status==='pass'?t().pass:status==='fail'?t().fail:t().warn}
function renderSheet(){
 const root=ensureSheet();$('demo-gate8-title').textContent=t().title;$('demo-gate8-sub').textContent=t().sub;
 const list=$('demo-gate8-list');list.replaceChildren();
 checks().forEach(item=>{const row=document.createElement('div');row.className='demo-gate8-row';const copy=document.createElement('div');copy.className='demo-gate8-row-copy';const b=document.createElement('b');b.textContent=item.title;const small=document.createElement('small');small.textContent=item.sub;copy.append(b,small);const status=document.createElement('span');status.className=`demo-gate8-status is-${item.status}`;status.textContent=item.status==='pass'?'✓':item.status==='fail'?'!':'•';status.title=statusText(item.status);row.append(copy,status);list.appendChild(row)});
 const runs=$('demo-gate8-runs');const count=runCount();runs.replaceChildren();const top=document.createElement('div');top.className='demo-gate8-runs-top';const b=document.createElement('b');b.textContent=t().runs;const span=document.createElement('span');span.textContent=t().count(count);top.append(b,span);const progress=document.createElement('div');progress.className='demo-gate8-progress';const fill=document.createElement('span');fill.style.width=`${count*10}%`;progress.appendChild(fill);runs.append(top,progress);
 $('demo-gate8-add-run').textContent=t().addRun;$('demo-gate8-add-run').disabled=count>=10;$('demo-gate8-refresh').textContent=t().refresh;
 const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,gate8_runs:count,gate8:{version:'gate8-v2',checkedAt:new Date().toISOString(),checks:checks(),endpoint:endpointMeta,currentPlan:currentPlan(),language:language(),appWidth:Math.round($('app')?.getBoundingClientRect().width||0)}});
 root.setAttribute('aria-hidden',sheetOpen?'false':'true');
}
async function checkEndpoint(){endpointStatus='pending';renderSheet();try{const response=await fetch('/api/diagnostic-ai',{cache:'no-store'});const data=await response.json();endpointMeta=data;endpointStatus=response.ok&&data?.production_database_access===false?'pass':'fail'}catch{endpointStatus='fail';endpointMeta=null}renderSheet()}
function openSheet(){sheetOpen=true;closeScenario();renderSheet();checkEndpoint()}
function closeSheet(){sheetOpen=false;ensureSheet().setAttribute('aria-hidden','true')}
function closeScenario(){$('modal-root')?.setAttribute('aria-hidden','true');document.body.classList.remove('modal-open')}
function decorate(){ensureMenuButton();ensureSheet();naturalize();if(sheetOpen)renderSheet()}
function schedule(delay=0){clearTimeout(decorateTimer);decorateTimer=setTimeout(decorate,delay)}

document.addEventListener('click',event=>{
 if(event.target.closest('#demo-stage-readiness')){event.preventDefault();openSheet();return}
 if(event.target.closest('[data-gate8-close]')){closeSheet();return}
 if(event.target.closest('#demo-gate8-add-run')){setRunCount(runCount()+1);renderSheet();return}
 if(event.target.closest('#demo-gate8-refresh')){checkEndpoint();return}
 if(event.target.closest('[data-lang],[data-plan],#demo-scenario-button,#demo-active-tour-button,[data-gate6-demo],[data-gate7-fill]'))schedule(70)
});
window.addEventListener('resize',()=>schedule(120));
schedule(160);
window.ICLUB_DEMO_GATE8={open:openSheet,checks,refresh:checkEndpoint,runCount,stage};
})();