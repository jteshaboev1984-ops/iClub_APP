(()=>{'use strict';
const $=id=>document.getElementById(id);
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:'ru';
const COPY={
 ru:{profile:'Единый демонстрационный профиль во всех тарифах'},
 uz:{profile:'Barcha tariflarda yagona namoyish profili'},
 en:{profile:'One demonstration profile across every plan'}
};
let timer=null;

function hideLearnerIdentity(){
 document.querySelectorAll('.demo-student-context').forEach(row=>{
  row.hidden=true;
  row.setAttribute('aria-hidden','true');
  row.style.display='none';
 });
}

function replaceTutorIcons(){
 document.querySelectorAll('.demo-ai-hub-mark img,.demo-ai-chat-mark img,.demo-ai-welcome-mark img').forEach(img=>{
  if(!String(img.getAttribute('src')||'').includes('iclub-ai-tutor.svg'))img.setAttribute('src','iclub-ai-tutor.svg');
  img.setAttribute('alt','');
 });
}

function patchReadinessCopy(){
 const row=document.querySelector('[data-gate8-final="profile"]');
 const sub=row?.querySelector('small');
 if(sub)sub.textContent=(COPY[lang()]||COPY.ru).profile;
}

function polish(){
 hideLearnerIdentity();
 replaceTutorIcons();
 patchReadinessCopy();
}

function schedule(delay=0){
 clearTimeout(timer);
 timer=setTimeout(polish,delay);
}

document.addEventListener('click',event=>{
 if(event.target.closest('#demo-ai-hub-card,[data-lang],.demo-open-trajectory,[data-trajectory-tab],#demo-stage-readiness,#demo-gate8-refresh'))schedule(70);
});

const stack=$('courses-stack');
if(stack)new MutationObserver(mutations=>{
 if(mutations.some(item=>item.addedNodes.length||item.removedNodes.length))schedule(20);
}).observe(stack,{childList:true,subtree:true});

const readiness=$('demo-gate8-list');
if(readiness)new MutationObserver(mutations=>{
 if(mutations.some(item=>item.addedNodes.length||item.removedNodes.length))schedule(20);
}).observe(readiness,{childList:true,subtree:true});

schedule(80);
window.ICLUB_DEMO_TUTOR_POLISH={render:polish};
})();
