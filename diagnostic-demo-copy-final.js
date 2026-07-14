(()=>{'use strict';
const P='iclub_demo_v12.';
const $=id=>document.getElementById(id);
const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key)||'')??fallback}catch{return fallback}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(P+'state',{}).lang||'ru');
const plan=()=>document.querySelector('[data-plan].is-active')?.dataset.plan||read(P+'state',{}).plan||'free';
const C={
 ru:{free:'AI-репетитор доступен в Plus.',plus:'Задайте вопрос по экономике.',pro:'Следующий шаг с учётом вашего прогресса.',noSource:'В материалах iClub пока недостаточно данных для надёжного ответа.',noSourceSub:'Попробуйте спросить определение, формулу или сравнение двух понятий.',activeTitle:'Только общая теория',active:'Тур активен. AI-репетитор объясняет только общую теорию.',blocked:'Я не могу решать или проверять задание активного тура.',blockedSub:'Во время активного тура доступны только общие объяснения без разбора формулировки, чисел, вариантов и логики ответа.',blockedHint:'Спросите общий принцип темы без текста конкретного задания.',positive:'Это первый положительный сигнал. Навык ещё нужно подтвердить на другой формулировке.',repeated:'Та же путаница повторилась в новой практике.'},
 uz:{free:'AI-repetitor Plus tarifida mavjud.',plus:'Iqtisodiyot bo‘yicha savol bering.',pro:'Progressingizni hisobga olgan keyingi qadam.',noSource:'Ishonchli javob uchun iClub materiallarida hozircha yetarli ma’lumot yo‘q.',noSourceSub:'Ta’rif, formula yoki ikki tushunchani solishtirishni so‘rang.',activeTitle:'Faqat umumiy nazariya',active:'Tur faol. AI-repetitor faqat umumiy nazariyani tushuntiradi.',blocked:'Faol tur topshirig‘ini yecha yoki tekshira olmayman.',blockedSub:'Faol tur vaqtida topshiriq matni, sonlari, variantlari va javob mantiqisiz faqat umumiy tushuntirishlar mavjud.',blockedHint:'Aniq topshiriq matnisiz mavzuning umumiy prinsipini so‘rang.',positive:'Bu birinchi ijobiy signal. Ko‘nikmani boshqa ifodada yana tasdiqlash kerak.',repeated:'Ayni chalkashlik yangi mashqda takrorlandi.'},
 en:{free:'The AI tutor is available in Plus.',plus:'Ask an Economics question.',pro:'Your next step based on your progress.',noSource:'The iClub materials do not yet contain enough evidence for a reliable answer.',noSourceSub:'Ask for a definition, formula, or comparison of two concepts.',activeTitle:'General theory only',active:'The tour is active. The AI tutor explains general theory only.',blocked:'I cannot solve or check an active-tour task.',blockedSub:'During an active tour, only general explanations are available without analysing the task wording, numbers, options, or answer logic.',blockedHint:'Ask about the general principle without pasting the specific task.',positive:'This is the first positive signal. The skill still needs confirmation on another formulation.',repeated:'The same confusion repeated in the new practice.'}
};
const t=()=>C[lang()]||C.ru;
let timer=null;
function patchHub(){const card=$('demo-ai-hub-card');if(!card)return;const sub=card.querySelector('.muted.small');if(sub)sub.textContent=plan()==='free'?t().free:plan()==='plus'?t().plus:t().pro}
function patchChat(){
 document.querySelectorAll('.demo-ai-bubble.is-no-source').forEach(bubble=>{const b=bubble.querySelector('b'),p=bubble.querySelector('p');if(b)b.textContent=t().noSource;if(p)p.textContent=t().noSourceSub});
 const warning=$('demo-active-tour-warning');if(warning&&!warning.hidden){const b=warning.querySelector('b'),span=warning.querySelector('span');if(b)b.textContent=t().activeTitle;if(span)span.textContent=t().active}
 document.querySelectorAll('.demo-ai-message.is-active-tour-blocked').forEach(message=>{const sections=[...message.querySelectorAll('.demo-ai-answer-section p')];if(sections[0])sections[0].textContent=t().blocked;if(sections[1])sections[1].textContent=t().blockedSub;if(sections[2])sections[2].textContent=t().blockedHint});
}
function patchPro(){document.querySelectorAll('.demo-insight-card.is-positive small').forEach(node=>node.textContent=t().positive);document.querySelectorAll('.demo-insight-card.is-error small').forEach(node=>node.textContent=t().repeated)}
function render(){patchHub();patchChat();patchPro()}
function schedule(delay=0){clearTimeout(timer);timer=setTimeout(render,delay)}
document.addEventListener('click',event=>{if(event.target.closest('[data-plan],[data-lang],#demo-ai-hub-card,[data-chat-tab],.demo-open-trajectory,[data-trajectory-tab],#demo-ai-send,[data-gate7-fill]'))schedule(100)});
const stack=$('courses-stack');if(stack)new MutationObserver(mutations=>{if(mutations.some(item=>item.addedNodes.length||item.removedNodes.length))schedule(20)}).observe(stack,{childList:true,subtree:true});
schedule(260);
window.ICLUB_DEMO_FINAL_COPY={render};
})();