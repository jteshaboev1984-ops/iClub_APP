(()=>{'use strict';
const P='iclub_demo_v12.';
const $=id=>document.getElementById(id);
const q=s=>document.querySelector(s);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,P+'state',{}).lang||'ru');
const copy={ru:'Перейти к практике',uz:'Mashqqa o‘tish',en:'Go to practice'};
let timer=null;
function decorateTrend(){
 const bars=$('practice-micro-bars');
 if(!bars||!bars.classList.contains('premium-trend-bars'))return;
 const fills=[...bars.querySelectorAll('.premium-trend-fill')];
 const allZero=fills.length>0&&fills.every(fill=>fill.classList.contains('is-zero'));
 bars.classList.toggle('is-flat-zero',allZero);
 fills.forEach(fill=>fill.closest('.premium-trend-item')?.classList.toggle('is-zero-point',fill.classList.contains('is-zero')))
}
function decoratePlan(){
 const screen=$('courses-pro-trajectory');
 if(!screen||screen.hidden)return;
 const active=screen.querySelector('[data-trajectory-tab="plan"].is-active');
 const actions=screen.querySelector('.demo-plan-actions');
 let button=$('premium-plan-practice-btn');
 if(!active||!actions){button?.remove();return}
 if(!button){button=document.createElement('button');button.id='premium-plan-practice-btn';button.type='button';button.className='btn primary premium-plan-practice-btn';actions.appendChild(button)}
 button.textContent=copy[lang()]||copy.ru
}
function decorate(){decorateTrend();decoratePlan();audit()}
function schedule(delay=70){clearTimeout(timer);timer=setTimeout(decorate,delay)}
function goToPractice(){
 window.ICLUB_DEMO_GATE4?.closeTrajectory?.();
 setTimeout(()=>{$('practice-to-subject-btn')?.click();setTimeout(()=>q('[data-hub-tab="practice"]')?.click(),45)},45)
}
function audit(){
 const rows=read(localStorage,P+'history',{diagnostics:[]}).diagnostics||[];
 const last=rows.slice(-4);const allZero=last.length>0&&last.every(item=>Number(item.score||0)===0);
 const zeroVisible=!allZero||Boolean($('practice-micro-bars')?.classList.contains('is-flat-zero')&&$('practice-micro-bars')?.querySelectorAll('.is-zero-point').length===last.length);
 const screen=$('courses-pro-trajectory');const planVisible=Boolean(screen&&!screen.hidden&&screen.querySelector('[data-trajectory-tab="plan"].is-active'));
 const planExit=!planVisible||Boolean($('premium-plan-practice-btn'));
 const tech=read(sessionStorage,P+'technical',{});try{sessionStorage.setItem(P+'technical',JSON.stringify({...tech,flow_precision:{version:'v1',zeroVisible,planExit,pass:zeroVisible&&planExit}}))}catch{}
}
document.addEventListener('click',event=>{
 if(event.target.closest('#premium-plan-practice-btn')){event.preventDefault();event.stopImmediatePropagation();goToPractice();return}
 if(event.target.closest('[data-plan],[data-lang],#practice-submit-btn,#practice-again-btn,.demo-open-trajectory,[data-trajectory-tab],.demo-toggle-targeted,[data-chat-tab]'))schedule(100)
},true);
['courses-practice-start','courses-pro-trajectory'].forEach(id=>{const screen=$(id);if(screen)new MutationObserver(()=>schedule(45)).observe(screen,{attributes:true,attributeFilter:['hidden','class']})});
setTimeout(decorate,420);
window.ICLUB_DEMO_FLOW_PRECISION={render:decorate,audit};
})();