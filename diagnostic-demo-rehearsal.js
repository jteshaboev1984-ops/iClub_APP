(()=>{'use strict';
const P='iclub_demo_v12.';
const TECH_KEY=P+'technical';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,P+'state',{}).lang||'ru');
const C={
 ru:{title:'Полный прогон demo',sub:'Один прогон засчитывается только после прохождения всех 19 шагов.',progress:(n,total)=>`${n} из ${total} шагов`,open:'Открыть чек-лист прогона',reset:'Сбросить текущий прогон',finish:'Завершить и засчитать',close:'Закрыть',confirm:'Сбросить отметки текущего прогона?',done:'Полный прогон засчитан.',steps:[
  'Открыть demo и проверить Subject Hub Free.',
  'Открыть «Сценарий» и убедиться, что активный тур выключен.',
  'Открыть диагностику. При необходимости использовать «Демо-ответ», затем вручную нажимать «Ответить».',
  'Открыть Free result и обычный разбор ответов.',
  'Переключиться на Plus на том же экране результата.',
  'Открыть Plus-разбор текущей попытки.',
  'Вернуться в Subject Hub и открыть Plus AI-репетитор.',
  'Отправить проверенный вопрос и показать model_called=false.',
  'Отправить живой AI-вопрос и показать model_called=true.',
  'Повторить живой вопрос и показать ответ из кэша без второго model call.',
  'Переключиться на Pro и открыть траекторию Сардора.',
  'Показать исторический вывод и динамическое обновление по текущей попытке.',
  'Изменить один ответ диагностики и проверить изменение Pro-статуса.',
  'Включить активный Tour 5.',
  'Отправить защищённый запрос, затем разрешённый общий теоретический вопрос.',
  'Открыть техническую панель и показать решение защиты.',
  'Показать честный резервный ответ при отключённой генерации или недоступном провайдере.',
  'Сменить язык и проверить сохранение тарифа, попытки и текущего экрана.',
  'Выполнить reset и убедиться, что удалены только локальные demo-данные.'
 ]},
 uz:{title:'Demo to‘liq sinovi',sub:'Sinov faqat 19 qadamning barchasi bajarilgandan keyin hisoblanadi.',progress:(n,total)=>`${total} qadamdan ${n} tasi`,open:'Sinov chek-listini ochish',reset:'Joriy sinovni tiklash',finish:'Yakunlash va hisoblash',close:'Yopish',confirm:'Joriy sinov belgilarini tiklaysizmi?',done:'To‘liq sinov hisoblandi.',steps:[
  'Demo ni oching va Free Subject Hub ni tekshiring.',
  '«Ssenariy»ni oching va faol tur o‘chiq ekanini tekshiring.',
  'Diagnostikani oching. Kerak bo‘lsa «Demo javob»dan foydalaning, keyin «Javob berish»ni qo‘lda bosing.',
  'Free natija va oddiy javoblar tahlilini oching.',
  'Shu natija ekranida Plus ga o‘ting.',
  'Joriy urinishning Plus tahlilini oching.',
  'Subject Hub ga qayting va Plus AI-repetitorni oching.',
  'Tekshirilgan savolni yuboring va model_called=false ni ko‘rsating.',
  'Jonli AI savolini yuboring va model_called=true ni ko‘rsating.',
  'Jonli savolni takrorlang va ikkinchi model call siz kesh javobini ko‘rsating.',
  'Pro ga o‘ting va Sardorning o‘quv yo‘lini oching.',
  'Tarixiy xulosa va joriy urinish bo‘yicha dinamik yangilanishni ko‘rsating.',
  'Diagnostikadagi bitta javobni o‘zgartirib, Pro statusi o‘zgarishini tekshiring.',
  'Faol 5-turni yoqing.',
  'Himoyalangan so‘rovni, so‘ng ruxsat etilgan umumiy nazariy savolni yuboring.',
  'Texnik panelni ochib, himoya qarorini ko‘rsating.',
  'Generatsiya o‘chiq yoki provayder mavjud bo‘lmaganda halol zaxira javobini ko‘rsating.',
  'Tilni o‘zgartirib, tarif, urinish va joriy ekran saqlanishini tekshiring.',
  'Reset ni bajaring va faqat lokal demo ma’lumotlari o‘chirilganini tekshiring.'
 ]},
 en:{title:'Full demo rehearsal',sub:'A run counts only after all 19 steps are completed.',progress:(n,total)=>`${n} of ${total} steps`,open:'Open rehearsal checklist',reset:'Reset current rehearsal',finish:'Finish and count run',close:'Close',confirm:'Reset all marks in the current rehearsal?',done:'Full rehearsal counted.',steps:[
  'Open the demo and check the Free Subject Hub.',
  'Open Scenario and confirm that Active Tour is off.',
  'Open diagnosis. Use Demo answer when needed, then press Answer manually.',
  'Open the Free result and standard answer review.',
  'Switch to Plus on the same result screen.',
  'Open the Plus review of the current attempt.',
  'Return to Subject Hub and open the Plus AI tutor.',
  'Send a verified question and show model_called=false.',
  'Send a live AI question and show model_called=true.',
  'Repeat the live question and show cached without a second model call.',
  'Switch to Pro and open Sardor’s learning path.',
  'Show the historical conclusion and dynamic current-attempt update.',
  'Change one diagnostic answer and verify that the Pro status changes.',
  'Enable Active Tour 5.',
  'Send a protected request, then an allowed general-theory question.',
  'Open the technical panel and show the guard decision.',
  'Show an honest fallback when generation or the provider is unavailable.',
  'Change language and verify that plan, attempt, and current screen persist.',
  'Run reset and confirm that only local demo data is removed.'
 ]}
};
const t=()=>C[lang()]||C.ru;
let open=false;

function tech(){return read(sessionStorage,TECH_KEY,{})}
function current(){const value=tech().gate8_rehearsal_current;return{done:Array.isArray(value?.done)?value.done.filter(Number.isInteger):[]}}
function saveCurrent(value){write(sessionStorage,TECH_KEY,{...tech(),gate8_rehearsal_current:value})}
function toast(message){const node=$('toast');if(!node)return;node.textContent=message;node.classList.add('is-show');setTimeout(()=>node.classList.remove('is-show'),2200)}
function ensureStyle(){if(document.querySelector('link[data-rehearsal-style]'))return;const link=document.createElement('link');link.rel='stylesheet';link.href='diagnostic-demo-rehearsal.css?v=rehearsal-1';link.dataset.rehearsalStyle='1';document.head.appendChild(link)}
function ensureRoot(){
 let root=$('demo-rehearsal-root');if(root)return root;
 root=document.createElement('div');root.id='demo-rehearsal-root';root.className='demo-rehearsal-root';root.setAttribute('aria-hidden','true');
 const backdrop=document.createElement('button');backdrop.type='button';backdrop.className='demo-rehearsal-backdrop';backdrop.dataset.rehearsalClose='1';
 const sheet=document.createElement('section');sheet.className='demo-rehearsal-sheet';
 const handle=document.createElement('div');handle.className='demo-rehearsal-handle';
 const head=document.createElement('div');head.className='demo-rehearsal-head';const copy=document.createElement('div');const title=document.createElement('div');title.id='demo-rehearsal-title';title.className='demo-rehearsal-title';const sub=document.createElement('div');sub.id='demo-rehearsal-sub';sub.className='demo-rehearsal-sub';copy.append(title,sub);const close=document.createElement('button');close.type='button';close.className='icon-btn';close.dataset.rehearsalClose='1';close.textContent='×';head.append(copy,close);
 const summary=document.createElement('div');summary.className='demo-rehearsal-summary';summary.id='demo-rehearsal-summary';
 const list=document.createElement('div');list.className='demo-rehearsal-list';list.id='demo-rehearsal-list';
 const actions=document.createElement('div');actions.className='demo-rehearsal-actions';const reset=document.createElement('button');reset.type='button';reset.className='btn';reset.id='demo-rehearsal-reset';const finish=document.createElement('button');finish.type='button';finish.className='btn primary';finish.id='demo-rehearsal-finish';actions.append(reset,finish);
 sheet.append(handle,head,summary,list,actions);root.append(backdrop,sheet);document.body.appendChild(root);return root;
}
function patchOpenButton(){const button=$('demo-gate8-add-run');if(button)button.textContent=t().open}
function render(){
 const root=ensureRoot();const copy=t();const state=current();const done=new Set(state.done);$('demo-rehearsal-title').textContent=copy.title;$('demo-rehearsal-sub').textContent=copy.sub;
 const summary=$('demo-rehearsal-summary');summary.replaceChildren();const top=document.createElement('div');top.className='demo-rehearsal-summary-top';const b=document.createElement('b');b.textContent=copy.title;const span=document.createElement('span');span.textContent=copy.progress(done.size,copy.steps.length);top.append(b,span);const progress=document.createElement('div');progress.className='demo-rehearsal-progress';const fill=document.createElement('span');fill.style.width=`${Math.round(done.size/copy.steps.length*100)}%`;progress.appendChild(fill);summary.append(top,progress);
 const list=$('demo-rehearsal-list');list.replaceChildren();copy.steps.forEach((label,index)=>{const button=document.createElement('button');button.type='button';button.className=`demo-rehearsal-step ${done.has(index)?'is-done':''}`;button.dataset.rehearsalStep=String(index);const check=document.createElement('span');check.className='demo-rehearsal-check';check.textContent='✓';const text=document.createElement('span');text.className='demo-rehearsal-copy';text.textContent=`${index+1}. ${label}`;button.append(check,text);list.appendChild(button)});
 $('demo-rehearsal-reset').textContent=copy.reset;$('demo-rehearsal-finish').textContent=copy.finish;$('demo-rehearsal-finish').disabled=done.size!==copy.steps.length||Number(tech().gate8_runs||0)>=10;root.setAttribute('aria-hidden',open?'false':'true');patchOpenButton();
}
function openSheet(){open=true;render()}
function closeSheet(){open=false;ensureRoot().setAttribute('aria-hidden','true')}
function toggleStep(index){const state=current();const done=new Set(state.done);done.has(index)?done.delete(index):done.add(index);saveCurrent({done:[...done].sort((a,b)=>a-b)});render()}
function reset(){if(!window.confirm(t().confirm))return;saveCurrent({done:[]});render()}
function finish(){const state=current();if(new Set(state.done).size!==t().steps.length)return;const value=tech();const runs=Math.min(10,Number(value.gate8_runs||0)+1);write(sessionStorage,TECH_KEY,{...value,gate8_runs:runs,gate8_rehearsal_current:{done:[]},gate8_last_completed_run:{run:runs,completedAt:new Date().toISOString(),steps:t().steps.length,language:lang()}});closeSheet();window.ICLUB_DEMO_GATE8?.refresh?.();toast(t().done);setTimeout(patchOpenButton,180)}

document.addEventListener('click',event=>{
 if(event.target.closest('#demo-gate8-add-run')){event.preventDefault();event.stopImmediatePropagation();openSheet();return}
 if(event.target.closest('[data-rehearsal-close]')){closeSheet();return}
 const step=event.target.closest('[data-rehearsal-step]')?.dataset.rehearsalStep;if(step!==undefined){toggleStep(Number(step));return}
 if(event.target.closest('#demo-rehearsal-reset')){reset();return}
 if(event.target.closest('#demo-rehearsal-finish')){finish();return}
 if(event.target.closest('[data-lang],#demo-stage-readiness,#demo-gate8-refresh'))setTimeout(()=>{patchOpenButton();if(open)render()},100)
},true);

ensureStyle();ensureRoot();setTimeout(()=>{patchOpenButton();render()},300);
window.ICLUB_DEMO_REHEARSAL={open:openSheet,current,runCount:()=>Number(tech().gate8_runs||0)};
})();