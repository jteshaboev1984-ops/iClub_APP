(()=>{'use strict';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);

function routeQuestion(event,question){
 const text=String(question||'').trim();
 if(!text)return false;
 const gate5=window.ICLUB_DEMO_GATE5;
 const gate6=window.ICLUB_DEMO_GATE6;
 const gate7=window.ICLUB_DEMO_GATE7;
 if(!gate6?.sendGenerated)return false;
 const activeTour=gate7?.isActive?.()===true;
 const verified=!activeTour&&Boolean(gate5?.findCard?.(text));
 if(verified)return false;
 event.preventDefault();
 event.stopImmediatePropagation();
 gate6.sendGenerated(text);
 return true;
}

let pendingRestore=null;
function rememberCustomScreen(event){
 if(!event.target.closest('[data-lang]'))return;
 const active=q('#courses-stack > .stack-screen.is-active:not([hidden])');
 if(!active||!['courses-ai-chat','courses-pro-trajectory'].includes(active.id))return;
 pendingRestore={
  screen:active.id,
  chatTab:q('.demo-ai-chat-tab.is-active')?.dataset.chatTab||'dialog',
  trajectoryTab:q('.demo-trajectory-tab.is-active')?.dataset.trajectoryTab||'summary'
 };
 setTimeout(restoreCustomScreen,90);
}
function restoreCustomScreen(){
 const saved=pendingRestore;pendingRestore=null;if(!saved)return;
 if(saved.screen==='courses-ai-chat'){
  window.ICLUB_DEMO_GATE5?.openChat?.({origin:'courses-subject-hub'});
  if(saved.chatTab&&saved.chatTab!=='dialog')setTimeout(()=>q(`[data-chat-tab="${saved.chatTab}"]`)?.click(),30);
  return;
 }
 if(saved.screen==='courses-pro-trajectory'){
  window.ICLUB_DEMO_GATE4?.openTrajectory?.();
  if(saved.trajectoryTab&&saved.trajectoryTab!=='summary')setTimeout(()=>q(`[data-trajectory-tab="${saved.trajectoryTab}"]`)?.click(),30);
 }
}

window.addEventListener('click',event=>{
 rememberCustomScreen(event);
 if(event.target.closest('#demo-ai-send'))routeQuestion(event,$('demo-ai-input')?.value||'');
},true);
window.addEventListener('keydown',event=>{
 if(event.target.id!=='demo-ai-input'||event.key!=='Enter'||event.shiftKey)return;
 routeQuestion(event,event.target.value||'');
},true);

window.ICLUB_DEMO_ROUTER={routeQuestion,restoreCustomScreen};
})();