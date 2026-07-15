(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const CHAT_KEY=PREFIX+'chat';
const HISTORY_KEY=PREFIX+'history';
const STATE_KEY=PREFIX+'state';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);
const qa=selector=>[...document.querySelectorAll(selector)];
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,STATE_KEY,{}).lang||'ru');
const plan=()=>q('[data-plan].is-active')?.dataset.plan||read(localStorage,STATE_KEY,{}).plan||'free';
const node=(tag,cls,text)=>{const el=document.createElement(tag);if(cls)el.className=cls;if(text!==undefined&&text!==null)el.textContent=text;return el};
const normalize=value=>String(value||'').trim();

const COPY={
 ru:{current:'Текущий запрос',fromHistory:'Запрос из истории',all:'Все диалоги',backCurrent:'К текущему запросу',latest:'Последний',dialogs:n=>`${n} ${n===1?'диалог':n>1&&n<5?'диалога':'диалогов'}`,firstPoint:'Первая точка',same:'Без изменений',attempt:n=>`П${n}`,skill:'Навык',why:'Почему система так считает',check:n=>`${n} ${n===1?'проверка':n>1&&n<5?'проверки':'проверок'}`},
 uz:{current:'Joriy savol',fromHistory:'Tarixdagi savol',all:'Barcha dialoglar',backCurrent:'Joriy savolga qaytish',latest:'Oxirgi',dialogs:n=>`${n} ta dialog`,firstPoint:'Birinchi nuqta',same:'O‘zgarish yo‘q',attempt:n=>`U${n}`,skill:'Ko‘nikma',why:'Tizim nega shunday xulosa qildi',check:n=>`${n} ta tekshiruv`},
 en:{current:'Current question',fromHistory:'From history',all:'All conversations',backCurrent:'Back to current',latest:'Latest',dialogs:n=>`${n} ${n===1?'conversation':'conversations'}`,firstPoint:'First data point',same:'No change',attempt:n=>`A${n}`,skill:'Skill',why:'Why the system reached this conclusion',check:n=>`${n} ${n===1?'check':'checks'}`}
};
const t=()=>COPY[language()]||COPY.ru;

let selectedTurnId=null;
let customHistoryOpen=false;
let decorateTimer=null;
let resultTimer=null;
let sheetTimer=null;
let applyingDialog=false;

function chatState(){const raw=read(localStorage,CHAT_KEY,{});return{messages:Array.isArray(raw.messages)?raw.messages:[]}}
function turns(){
 const result=[];let current=null;
 chatState().messages.forEach((message,index)=>{
  if(message.role==='user'){
   current={id:message.id||`turn-${index}`,user:message,indexes:[index],messages:[message]};
   result.push(current);
  }else if(current){current.indexes.push(index);current.messages.push(message)}
 });
 return result;
}
function dateText(value){
 const date=value?new Date(value):new Date();
 if(Number.isNaN(date.getTime()))return '';
 try{return new Intl.DateTimeFormat(language()==='ru'?'ru-RU':language()==='uz'?'uz-UZ':'en-GB',{day:'numeric',month:'short',hour:'2-digit',minute:'2-digit'}).format(date)}catch{return ''}
}
function mapMessagesToDom(){
 const state=chatState().messages;
 const dom=qa('#demo-ai-chat-body > .demo-ai-message');
 dom.forEach((element,index)=>{
  const message=state[index];
  if(message?.id)element.dataset.premiumMessageId=message.id;
  element.dataset.premiumMessageIndex=String(index);
 });
 return{state,dom};
}
function contextBar(turn,isHistory){
 const bar=node('div','premium-dialog-context');
 bar.dataset.premiumDialogContext='1';
 const copy=node('span','premium-dialog-context-copy');
 copy.append(node('b','',isHistory?t().fromHistory:t().current),node('small','',dateText(turn?.user?.createdAt)));
 const button=node('button','premium-dialog-history-link',t().all);button.type='button';button.dataset.premiumOpenHistory='1';
 bar.append(copy,button);return bar;
}
function renderCustomHistory(){
 const body=$('demo-ai-chat-body');if(!body)return;
 customHistoryOpen=true;
 const rows=turns().slice().reverse();
 body.replaceChildren();
 const head=node('div','demo-ai-history-head premium-custom-history-head');
 head.append(node('div','h2',t().all),node('div','muted small',t().dialogs(rows.length)));
 body.appendChild(head);
 if(!rows.length)return;
 const list=node('div','demo-ai-history-list');
 rows.forEach((turn,index)=>{
  const button=node('button',`demo-ai-history-row ${index===0?'is-latest':''}`);button.type='button';button.dataset.premiumHistoryTurn=turn.id;
  const copy=node('span','demo-ai-history-copy');copy.append(node('b','',turn.user.text||'—'),node('small','',dateText(turn.user.createdAt)));
  button.append(copy);
  if(index===0)button.append(node('span','premium-history-latest',t().latest));
  button.append(node('span','settings-nav-arrow','›'));list.appendChild(button);
 });
 body.appendChild(list);
 const composer=$('demo-ai-composer');if(composer)composer.hidden=true;
}
function decorateHistory(){
 const body=$('demo-ai-chat-body');if(!body||!body.querySelector('.demo-ai-history-head'))return;
 const rows=qa('#demo-ai-chat-body [data-history-message]');
 const sub=body.querySelector('.demo-ai-history-head .muted');if(sub)sub.textContent=t().dialogs(rows.length);
 rows.forEach((row,index)=>{
  row.classList.toggle('is-latest',index===0);
  row.querySelector('.premium-history-latest')?.remove();
  if(index===0){const badge=node('span','premium-history-latest',t().latest);const arrow=row.querySelector('.settings-nav-arrow');arrow?row.insertBefore(badge,arrow):row.appendChild(badge)}
 });
}
function decorateDialog(){
 if(applyingDialog)return;
 const body=$('demo-ai-chat-body');if(!body||$('courses-ai-chat')?.hidden)return;
 if(customHistoryOpen){renderCustomHistory();return}
 if(body.querySelector('.demo-ai-history-head')){decorateHistory();return}
 const list=turns();
 if(!list.length)return;
 applyingDialog=true;
 try{
  body.querySelector('[data-premium-dialog-context]')?.remove();
  const{dom}=mapMessagesToDom();
  const ids=new Set(list.map(turn=>turn.id));
  if(!selectedTurnId||!ids.has(selectedTurnId))selectedTurnId=list[list.length-1].id;
  const selected=list.find(turn=>turn.id===selectedTurnId)||list[list.length-1];
  const visibleIndexes=new Set(selected.indexes);
  dom.forEach((element,index)=>{
   const visible=visibleIndexes.has(index);
   element.hidden=!visible;
   element.classList.toggle('is-premium-current-turn',visible);
  });
  const first=dom.find((element,index)=>visibleIndexes.has(index));
  if(first)body.insertBefore(contextBar(selected,selected.id!==list[list.length-1].id),first);
 }finally{applyingDialog=false}
}
function scheduleDialog(delay=20){clearTimeout(decorateTimer);decorateTimer=setTimeout(()=>{decorateDialog();decorateHistory()},delay)}

function renderTrend(){
 const trend=$('practice-trend'),bars=$('practice-micro-bars'),delta=$('practice-micro-delta');
 if(!trend||!bars||!delta)return;
 const history=read(localStorage,HISTORY_KEY,{diagnostics:[]});
 const rows=(Array.isArray(history.diagnostics)?history.diagnostics:[]).slice(-4);
 trend.hidden=rows.length===0;
 if(!rows.length){bars.replaceChildren();delta.textContent='';return}
 bars.className='practice-micro-bars premium-trend-bars';bars.replaceChildren();
 rows.forEach((item,index)=>{
  const total=Math.max(1,Number(item.total||7));const percent=Math.max(0,Math.min(100,Math.round(Number(item.score||0)/total*100)));
  const wrap=node('div','premium-trend-item');
  const value=node('span','premium-trend-value',`${percent}%`);
  const track=node('span','premium-trend-track');
  const fill=node('span',`premium-trend-fill ${percent===0?'is-zero':''}`);fill.style.height=`${percent===0?3:percent}%`;
  track.appendChild(fill);wrap.append(value,track,node('span','premium-trend-label',t().attempt(Math.max(1,rows.length-index))));bars.appendChild(wrap);
 });
 if(rows.length===1)delta.textContent=t().firstPoint;
 else{
  const prev=rows[rows.length-2],last=rows[rows.length-1];
  const p1=Math.round(Number(prev.score||0)/Math.max(1,Number(prev.total||7))*100);
  const p2=Math.round(Number(last.score||0)/Math.max(1,Number(last.total||7))*100);
  const diff=p2-p1;delta.textContent=diff===0?t().same:`${diff>0?'+':''}${diff}%`;
 }
}

function decorateResult(){
 clearTimeout(resultTimer);resultTimer=setTimeout(()=>{
  const screen=$('courses-practice-result');if(!screen||screen.hidden)return;
  window.ICLUB_DEMO_STITCH_RESULT?.render?.();
  const card=$('demo-plan-result');if(!card)return;
  const current=plan();
  card.classList.toggle('premium-hide-free-result',current==='free');
  if(current!=='pro')return;
  card.querySelector('.demo-plan-result-badge')?.remove();
  const reliability=card.querySelector('.demo-compact-reliability');
  const summary=card.querySelector('.demo-compact-summary');
  if(reliability&&summary){reliability.classList.add('premium-inline-reliability');if(summary.nextElementSibling!==reliability)summary.insertAdjacentElement('afterend',reliability)}
  const footer=card.querySelector('.demo-compact-footer');if(footer)footer.classList.add('is-action-only');
 },60)
}

function pluralChecks(text){
 const match=String(text||'').match(/\d+/);return match?t().check(Number(match[0])):text;
}
function decorateSheet(){
 clearTimeout(sheetTimer);sheetTimer=setTimeout(()=>{
  const root=$('demo-insight-sheet-root'),sheet=root?.querySelector('.demo-insight-sheet');if(!root||!sheet||root.getAttribute('aria-hidden')==='true')return;
  const statusRow=sheet.querySelector('.demo-sheet-status');const headCopy=sheet.querySelector('.demo-insight-sheet-head>div:first-child');
  sheet.querySelectorAll('.premium-sheet-eyebrow,.premium-sheet-status').forEach(item=>item.remove());
  const isSkill=Boolean(statusRow);
  sheet.classList.toggle('is-skill-detail',isSkill);
  if(isSkill&&headCopy){
   headCopy.insertBefore(node('div','premium-sheet-eyebrow',t().skill),headCopy.firstChild);
   const source=statusRow.querySelector('b');if(source){const badge=node('span',`premium-sheet-status ${source.className||''}`,source.textContent);headCopy.appendChild(badge)}
   const reasonLabel=sheet.querySelector('.demo-sheet-reason>b');if(reasonLabel)reasonLabel.textContent=t().why;
   sheet.querySelectorAll('.demo-sheet-history-row span').forEach(span=>{span.textContent=pluralChecks(span.textContent)});
  }
 },20)
}

function audit(){
 const tech=read(sessionStorage,TECH_KEY,{});
 const freeHidden=plan()!=='free'||!q('#demo-plan-result:not(.premium-hide-free-result)');
 const proBadge=Boolean(q('.demo-engine-compact .demo-plan-result-badge'));
 const button=q('.demo-engine-compact .demo-open-trajectory');const card=q('.demo-engine-compact');
 const buttonFull=!button||!card||Math.abs(button.getBoundingClientRect().width-(button.parentElement?.getBoundingClientRect().width||0))<=3;
 const trendExpected=(read(localStorage,HISTORY_KEY,{diagnostics:[]}).diagnostics||[]).length>0;
 const trendVisible=!trendExpected||!$('practice-trend')?.hidden;
 const overflow=Math.max(0,Math.round(document.documentElement.scrollWidth-document.documentElement.clientWidth));
 const report={version:'premium-fixes-v1',checkedAt:new Date().toISOString(),freeResultCardRemoved:freeHidden,duplicateProBadge:proBadge,trajectoryButtonFullWidth:buttonFull,trendVisible,overflowPx:overflow,pass:freeHidden&&!proBadge&&buttonFull&&trendVisible&&overflow<=2};
 write(sessionStorage,TECH_KEY,{...tech,premium_fixes_audit:report});return report;
}
function decorateAll(){renderTrend();decorateResult();scheduleDialog();decorateSheet();setTimeout(audit,120)}

// Capture the selected history request before the base handler returns to the dialogue.
document.addEventListener('click',event=>{
 const history=event.target.closest('[data-history-message]');if(history){selectedTurnId=history.dataset.historyMessage;customHistoryOpen=false;setTimeout(scheduleDialog,45);return}
 const custom=event.target.closest('[data-premium-history-turn]');if(custom){selectedTurnId=custom.dataset.premiumHistoryTurn;customHistoryOpen=false;const tab=q('[data-chat-tab="dialog"]');tab?.click();setTimeout(scheduleDialog,50);return}
 if(event.target.closest('[data-premium-open-history]')){
  event.preventDefault();event.stopImmediatePropagation();
  const historyTab=q('[data-chat-tab="history"]');if(historyTab){customHistoryOpen=false;historyTab.click()}else renderCustomHistory();
  return;
 }
 if(event.target.closest('#demo-ai-send')){selectedTurnId=null;customHistoryOpen=false;setTimeout(scheduleDialog,80)}
 const tab=event.target.closest('[data-chat-tab]');if(tab){customHistoryOpen=false;if(tab.dataset.chatTab==='dialog')selectedTurnId=null;setTimeout(scheduleDialog,60)}
 if(event.target.closest('[data-plan],[data-lang],#practice-submit-btn,#practice-again-btn,#practice-restart-btn,.demo-open-trajectory,[data-skill-id],[data-open-method]'))setTimeout(decorateAll,90);
},true);

document.addEventListener('keydown',event=>{if(event.target.id==='demo-ai-input'&&event.key==='Enter'&&!event.shiftKey){selectedTurnId=null;customHistoryOpen=false;setTimeout(scheduleDialog,90)}},true);

const chatBody=$('demo-ai-chat-body');if(chatBody)new MutationObserver(mutations=>{if(mutations.some(item=>item.addedNodes.length||item.removedNodes.length))scheduleDialog(35)}).observe(chatBody,{childList:true});
const result=$('courses-practice-result');if(result)new MutationObserver(()=>decorateResult()).observe(result,{attributes:true,attributeFilter:['hidden','class']});
const resultCard=$('demo-plan-result');if(resultCard)new MutationObserver(()=>decorateResult()).observe(resultCard,{childList:true,attributes:true,attributeFilter:['class','hidden','data-gate4-view']});
const sheetRoot=$('demo-insight-sheet-root');if(sheetRoot)new MutationObserver(()=>decorateSheet()).observe(sheetRoot,{childList:true,subtree:true,attributes:true,attributeFilter:['aria-hidden']});

setTimeout(decorateAll,260);
window.ICLUB_DEMO_PREMIUM_FIXES={decorate:decorateAll,audit,renderTrend,showCurrent:()=>{selectedTurnId=null;customHistoryOpen=false;scheduleDialog(0)}};
})();