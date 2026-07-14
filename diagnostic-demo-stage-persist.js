(()=>{'use strict';
const P='iclub_demo_v12.';
const TECH_KEY=P+'technical';
const STAGE_KEY=P+'stage';
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const stage=()=>{const value=read(sessionStorage,STAGE_KEY,{});return{runs:Math.max(0,Math.min(10,Number(value.runs||0))),current:value.current||{done:[]},video:!!value.video,lastCompleted:value.lastCompleted||null}};
function saveStage(patch){write(sessionStorage,STAGE_KEY,{...stage(),...patch})}
function migrate(){
 if(sessionStorage.getItem(STAGE_KEY))return;
 const tech=read(sessionStorage,TECH_KEY,{});
 saveStage({runs:Number(tech.gate8_runs||0),current:tech.gate8_rehearsal_current||{done:[]},video:!!tech.reserve_video,lastCompleted:tech.gate8_last_completed_run||null});
}
function mirror(){
 const value=stage(),tech=read(sessionStorage,TECH_KEY,{});
 write(sessionStorage,TECH_KEY,{...tech,gate8_runs:value.runs,gate8_rehearsal_current:value.current,gate8_last_completed_run:value.lastCompleted,reserve_video:value.video});
 const button=document.getElementById('demo-gate8-video');
 if(button){const code=['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:'ru';button.textContent=value.video?(code==='ru'?'Снять отметку':code==='uz'?'Belgini olib tashlash':'Remove mark'):(code==='ru'?'Видео записано':code==='uz'?'Video yozildi':'Video recorded')}
}
function toggleVideo(event){
 const button=event.target.closest('#demo-gate8-video');if(!button)return false;
 event.preventDefault();event.stopImmediatePropagation();saveStage({video:!stage().video});mirror();window.ICLUB_DEMO_GATE8_FINAL?.render?.();return true;
}
document.addEventListener('click',event=>{
 if(toggleVideo(event))return;
 if(event.target.closest('[data-plan],[data-lang],#demo-stage-readiness,#demo-gate8-refresh,#demo-gate8-add-run,[data-demo-menu-action]')){mirror();setTimeout(mirror,120)}
},true);
migrate();mirror();setTimeout(mirror,300);
window.ICLUB_DEMO_STAGE={get:stage,save:saveStage,mirror};
})();