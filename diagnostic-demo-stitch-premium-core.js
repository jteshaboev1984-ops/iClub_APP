(()=>{'use strict';
const PREFIX='iclub_demo_v12.';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const q=selector=>document.querySelector(selector);
const qa=selector=>[...document.querySelectorAll(selector)];
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const language=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,PREFIX+'state',{}).lang||'ru');
const plan=()=>q('[data-plan].is-active')?.dataset.plan||read(localStorage,PREFIX+'state',{}).plan||'free';
const el=(tag,cls,text)=>{const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined&&text!==null)node.textContent=text;return node};
let timer=null;
const COPY={
 ru:{eyebrow:'iClub AI',proStatus:'2 навыка требуют повторной проверки',verified:'Проверенный ответ iClub',generated:'AI-ответ по материалам iClub',repeated:'Повторный ответ',fallback:'Сохранённый проверенный ответ',theory:'Только теория'},
 uz:{eyebrow:'iClub AI',proStatus:'2 ta ko‘nikmani qayta tekshirish kerak',verified:'iClub tekshirgan javob',generated:'iClub materiallari bo‘yicha AI javobi',repeated:'Takroriy javob',fallback:'Saqlangan tekshirilgan javob',theory:'Faqat nazariya'},
 en:{eyebrow:'iClub AI',proStatus:'2 skills need another check',verified:'Verified iClub answer',generated:'AI answer from iClub materials',repeated:'Repeated answer',fallback:'Saved verified answer',theory:'Theory only'}
};
const t=()=>COPY[language()]||COPY.ru;
function iconize(){qa('.demo-ai-hub-mark img,.demo-ai-chat-mark img,.demo-ai-welcome-mark img,.demo-compact-mark img,.demo-trajectory-mark img,.demo-ai-before-mark img,.demo-ai-verified img').forEach(img=>{img.src='iclub-ai-tutor-premium.svg';img.alt=''})}
function enhanceHub(){const card=$('demo-ai-hub-card');if(!card)return;const current=plan();card.dataset.premiumPlan=current;card.classList.toggle('is-available',current!=='free');let status=card.querySelector('.premium-hub-status');if(current==='pro'){if(!status){status=el('div','premium-hub-status');card.appendChild(status)}status.textContent=t().proStatus;status.hidden=false}else if(status)status.hidden=true}
function enhanceHeader(){const copy=q('.demo-ai-chat-title-copy');if(!copy)return;let eyebrow=copy.querySelector('.premium-tutor-eyebrow');if(!eyebrow){eyebrow=el('div','premium-tutor-eyebrow');copy.insertBefore(eyebrow,copy.firstChild)}eyebrow.textContent=t().eyebrow;qa('.demo-student-context').forEach(node=>{node.hidden=true;node.setAttribute('aria-hidden','true');node.style.display='none'})}
function decorateReview(){qa('.demo-review-card').forEach(card=>{const boxes=card.querySelectorAll('.demo-review-box');if(boxes[0])boxes[0].classList.add('is-user-answer');if(boxes[1])boxes[1].classList.add('is-correct-answer')})}
function semanticMessages(){qa('#demo-ai-chat-body .demo-ai-message.is-assistant').forEach(message=>{const badge=message.querySelector('.demo-ai-verified span');if(!badge)return;if(message.classList.contains('is-live-generated'))badge.textContent=t().generated;else if(message.classList.contains('is-live-cached'))badge.textContent=t().repeated;else if(message.classList.contains('is-live-fallback'))badge.textContent=t().fallback;else if(message.classList.contains('is-theory-only-answer'))badge.textContent=t().theory;else if(!message.classList.contains('is-active-tour-blocked'))badge.textContent=t().verified})}
function audit(){const visibleStudent=qa('.demo-student-context').some(node=>{const style=getComputedStyle(node);return !node.hidden&&style.display!=='none'&&style.visibility!=='hidden'});const overflow=Math.max(0,Math.round(document.documentElement.scrollWidth-document.documentElement.clientWidth));const actionRows=qa('.demo-ai-actions');const actionsGrid=actionRows.every(row=>getComputedStyle(row).display==='grid');const icons=qa('.demo-ai-chat-mark img,.demo-ai-hub-mark img');const iconReady=icons.length>0&&icons.every(img=>String(img.src).includes('iclub-ai-tutor-premium.svg'));const report={version:'stitch-premium-v1',checkedAt:new Date().toISOString(),visibleStudent,overflowPx:overflow,actionsGrid,iconReady,plan:plan(),language:language(),pass:!visibleStudent&&overflow<=2&&actionsGrid&&iconReady};const tech=read(sessionStorage,TECH_KEY,{});write(sessionStorage,TECH_KEY,{...tech,premium_audit:report});return report}
function decorate(){document.documentElement.dataset.stitchPremium='1';iconize();enhanceHub();enhanceHeader();decorateReview();semanticMessages();window.ICLUB_DEMO_STITCH_RESULT?.render?.();requestAnimationFrame(audit)}
function schedule(delay=0){clearTimeout(timer);timer=setTimeout(decorate,delay)}
document.addEventListener('click',event=>{if(event.target.closest('[data-plan],[data-lang],#demo-ai-hub-card,[data-chat-tab],#practice-submit-btn,#practice-again-btn,#practice-review-open,.demo-result-ai-action,.demo-open-trajectory,[data-trajectory-tab],[data-ai-action]'))schedule(70)});
const stack=$('courses-stack');if(stack)new MutationObserver(mutations=>{if(mutations.some(item=>item.addedNodes.length||item.removedNodes.length))schedule(25)}).observe(stack,{childList:true,subtree:true});
window.addEventListener('resize',()=>schedule(100));schedule(160);window.ICLUB_DEMO_STITCH_PREMIUM={render:decorate,audit};
})();
