(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const CHAT_KEY=PREFIX+'chat';
const $=id=>document.getElementById(id);
const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key)||'')??fallback}catch{return fallback}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(PREFIX+'state',{}).lang||'ru');
const text={ru:{theory:'Только теория',source:'iClub Economics · Только теория'},uz:{theory:'Faqat nazariya',source:'iClub Economics · Faqat nazariya'},en:{theory:'Theory only',source:'iClub Economics · Theory only'}};
let timer=null;
function scrollLatest(smooth=true){
 clearTimeout(timer);timer=setTimeout(()=>requestAnimationFrame(()=>requestAnimationFrame(()=>{
  const latest=document.querySelector('#demo-ai-chat-body .demo-ai-message:last-child');if(!latest)return;
  const composer=$('demo-ai-composer');const rect=latest.getBoundingClientRect();const topOffset=112;const bottomLimit=window.innerHeight-(composer?.offsetHeight||96)-12;
  if(rect.top<topOffset||rect.bottom>bottomLimit){const top=Math.max(0,window.scrollY+rect.top-topOffset);window.scrollTo({top,behavior:smooth?'smooth':'auto'})}
 })),20)
}
function decorateTheory(){
 const state=read(CHAT_KEY,{messages:[]});const messages=(state.messages||[]).filter(message=>message.role==='assistant');const nodes=[...document.querySelectorAll('#demo-ai-chat-body .demo-ai-message.is-assistant')];
 nodes.forEach((node,index)=>{const message=messages[index];if(message?.mode!=='theory_only')return;node.classList.add('is-theory-only-answer');const badge=node.querySelector('.demo-ai-verified span');if(badge)badge.textContent=(text[lang()]||text.ru).theory;const source=node.querySelector('.demo-ai-source span');if(source&&!source.textContent.includes((text[lang()]||text.ru).theory))source.textContent=`${(text[lang()]||text.ru).source} · ${message.source?.section||message.source?.topic||'Economics'}`})
}
const body=$('demo-ai-chat-body');if(body)new MutationObserver(mutations=>{if(!mutations.some(item=>item.addedNodes.length||item.removedNodes.length))return;decorateTheory();scrollLatest(true)}).observe(body,{childList:true});
document.addEventListener('click',event=>{if(event.target.closest('[data-lang],[data-chat-tab],#demo-ai-hub-card'))setTimeout(()=>{decorateTheory();scrollLatest(false)},90)});
setTimeout(()=>{decorateTheory();scrollLatest(false)},220);
window.ICLUB_DEMO_CHAT_FOCUS={scrollLatest,decorateTheory};
})();