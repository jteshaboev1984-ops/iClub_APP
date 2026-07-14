(()=>{'use strict';
const D=window.ICLUB_DEMO_V12_DATA;if(!D?.profile)return;
const P='iclub_demo_v12.';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,P+'state',{}).lang||'ru');
const loc=value=>value?.[lang()]??value?.ru??value?.en??value?.uz??value??'';
let timer=null;
document.documentElement.dataset.demoProfile=D.profile.id;
function makeContext(){const row=document.createElement('div');row.className='demo-student-context';row.dataset.profileId=D.profile.id;const avatar=document.createElement('span');avatar.className='demo-student-context-avatar';avatar.textContent=D.profile.initials||'СК';const copy=document.createElement('span');copy.className='demo-student-context-copy';const name=document.createElement('b');name.textContent=loc(D.profile.name);const status=document.createElement('small');status.textContent=loc(D.profile.status);copy.append(name,status);row.append(avatar,copy);return row}
function render(){document.documentElement.dataset.demoProfile=D.profile.id;const chatCopy=document.querySelector('.demo-ai-chat-title-copy');if(chatCopy){let row=chatCopy.querySelector('.demo-student-context');if(!row){row=makeContext();chatCopy.appendChild(row)}else{row.querySelector('b').textContent=loc(D.profile.name);row.querySelector('small').textContent=loc(D.profile.status)}}const trajectory=$('courses-pro-trajectory');if(trajectory&&!trajectory.querySelector('.demo-student-context')){const head=trajectory.querySelector('.demo-trajectory-head');if(head)head.insertAdjacentElement('afterend',makeContext())}}
function patchTechnical(){setTimeout(()=>{const panel=$('demo-technical-card');if(!panel)return;const rows=[...panel.querySelectorAll('.demo-technical-row')];const guardRow=rows.find(row=>/сетевая защита|tarmoq himoyasi|network guard/i.test(row.querySelector('span')?.textContent||''));if(guardRow)guardRow.querySelector('b').textContent='same-origin endpoint • production DB 0';if(!panel.querySelector('[data-profile-tech]')){const row=document.createElement('div');row.className='demo-technical-row';row.dataset.profileTech='1';const label=document.createElement('span');label.textContent=lang()==='ru'?'Профиль':lang()==='uz'?'Profil':'Profile';const value=document.createElement('b');value.textContent=`${D.profile.id} · ${loc(D.profile.status)}`;row.append(label,value);panel.appendChild(row)}},110)}
function loadScript(src,version){if(document.querySelector(`script[data-demo-src="${src}"]`))return;const script=document.createElement('script');script.src=`${src}?v=${version}`;script.dataset.demoSrc=src;document.body.appendChild(script)}
function loadStageHelpers(){loadScript('diagnostic-demo-copy-final.js','copy-final-1');loadScript('diagnostic-demo-rehearsal.js','rehearsal-2');loadScript('diagnostic-demo-stage-persist.js','stage-persist-1')}
function schedule(delay=0){clearTimeout(timer);timer=setTimeout(render,delay)}
document.addEventListener('click',event=>{if(event.target.closest('[data-lang],#demo-ai-hub-card,.demo-open-trajectory,[data-trajectory-tab]'))schedule(80);if(event.target.closest('[data-demo-menu-action="technical"]'))patchTechnical()});
const stack=$('courses-stack');if(stack)new MutationObserver(mutations=>{if(mutations.some(item=>item.addedNodes.length))schedule(30)}).observe(stack,{childList:true,subtree:true});
schedule(220);loadStageHelpers();
window.ICLUB_DEMO_CONTEXT={render,profileId:D.profile.id};
})();