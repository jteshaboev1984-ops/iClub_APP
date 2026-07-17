(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const HISTORY_KEY=PREFIX+'history';
const STATE_KEY=PREFIX+'state';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,STATE_KEY,{}).lang||'ru');
const plan=()=>document.querySelector('[data-plan].is-active')?.dataset.plan||read(localStorage,STATE_KEY,{}).plan||'free';
const COPY={
 ru:{first:'Сначала',then:'Затем',reviewBack:'Назад к результату',openRecs:'Открыть рекомендации',retry:'Пройти снова',subject:'К предмету'},
 uz:{first:'Avval',then:'Keyin',reviewBack:'Natijaga qaytish',openRecs:'Tavsiyalarni ochish',retry:'Qayta ishlash',subject:'Fanga qaytish'},
 en:{first:'First',then:'Then',reviewBack:'Back to result',openRecs:'Open recommendations',retry:'Try again',subject:'To subject'}
};
const t=()=>COPY[language()]||COPY.ru;
let internalNavigation=false;
let timer=null;

function latestAttempt(){const rows=read(localStorage,HISTORY_KEY,{diagnostics:[]}).diagnostics||[];return rows[rows.length-1]||null}
function wrongCount(){return(latestAttempt()?.answers||[]).filter(item=>!item.correct).length}
function orderLabel(card,text){let label=card?.querySelector('.premium-flow-order');if(!card)return null;if(!label){label=document.createElement('span');label.className='premium-flow-order';card.insertBefore(label,card.firstChild)}label.textContent=text;return label}
function resetResultCards(){
 const review=$('practice-review-open'),recs=$('practice-recs-open');
 [review,recs].forEach(card=>{card?.classList.remove('premium-flow-first');card?.querySelector('.premium-flow-order')?.remove()})
}
function decorateResult(){
 resetResultCards();
 if(plan()!=='free'||wrongCount()===0)return;
 const review=$('practice-review-open'),recs=$('practice-recs-open');
 if(review){review.classList.add('premium-flow-first');orderLabel(review,t().first)}
 if(recs)orderLabel(recs,t().then)
}
function restoreButton(button,label,primary){if(!button)return;button.textContent=label;button.classList.toggle('primary',primary)}
function decorateReviewAndRecommendations(){
 const hasErrors=wrongCount()>0;
 restoreButton($('practice-review-back-btn'),hasErrors?t().openRecs:t().reviewBack,hasErrors);
 restoreButton($('practice-review-to-subject-btn'),t().subject,!hasErrors);
 restoreButton($('practice-recs-back-btn'),hasErrors?t().retry:t().reviewBack,hasErrors);
 restoreButton($('practice-recs-to-subject-btn'),t().subject,!hasErrors)
}
function decorate(){decorateResult();decorateReviewAndRecommendations();audit()}
function schedule(delay=50){clearTimeout(timer);timer=setTimeout(decorate,delay)}
function replayBaseClick(button,next){
 internalNavigation=true;
 button.click();
 internalNavigation=false;
 setTimeout(next,35)
}
function audit(){
 const hasErrors=wrongCount()>0;
 const freeFlow=plan()!=='free'||!hasErrors||Boolean($('practice-review-open')?.classList.contains('premium-flow-first')&&$('practice-review-open')?.querySelector('.premium-flow-order')&&$('practice-recs-open')?.querySelector('.premium-flow-order'));
 const reviewFlow=!hasErrors||$('practice-review-back-btn')?.textContent===t().openRecs;
 const recsFlow=!hasErrors||$('practice-recs-back-btn')?.textContent===t().retry;
 const stray=Boolean(document.querySelector('#courses-subject-hub .premium-flow-order,#courses-ai-chat .premium-flow-order,#courses-pro-trajectory .premium-flow-order'));
 const tech=read(sessionStorage,TECH_KEY,{});
 write(sessionStorage,TECH_KEY,{...tech,flow_refinement:{version:'post-practice-v1',scope:['free result order','review to recommendations','recommendations to retry'],personal_report_added:false,subject_hub_extra_cta:false,checks:{freeFlow,reviewFlow,recsFlow,noStrayGuidance:!stray},pass:freeFlow&&reviewFlow&&recsFlow&&!stray}})
}

document.addEventListener('click',event=>{
 if(internalNavigation)return;
 if(wrongCount()>0&&event.target.closest('#practice-review-back-btn')){
  event.preventDefault();event.stopImmediatePropagation();
  replayBaseClick($('practice-review-back-btn'),()=>$('practice-recs-open')?.click());
  return
 }
 if(wrongCount()>0&&event.target.closest('#practice-recs-back-btn')){
  event.preventDefault();event.stopImmediatePropagation();
  replayBaseClick($('practice-recs-back-btn'),()=>$('practice-again-btn')?.click());
  return
 }
 if(event.target.closest('[data-plan],[data-lang],#practice-submit-btn,#practice-again-btn,#practice-review-open,#practice-recs-open,#practice-review-to-subject-btn,#practice-recs-to-subject-btn'))schedule(70)
},true);

['courses-practice-result','courses-practice-review','courses-practice-recs'].forEach(id=>{const screen=$(id);if(screen)new MutationObserver(()=>schedule(35)).observe(screen,{attributes:true,attributeFilter:['hidden','class']})});
setTimeout(decorate,320);
window.ICLUB_DEMO_FLOW_REFINEMENT={render:decorate,audit};
})();