(() => {
"use strict";
if(!/\.vercel\.app$/i.test(location.hostname) ||
 new URLSearchParams(location.search).get("iclub-ai-review")!=="1")return;
// VISUAL ONLY: no SDK, network calls, storage, identities, academic reads or writes.
const LANG={
ru:{banner:"Визуальный просмотр iClub AI",sub:"Пример интерфейса · без личных данных",welcome:"Чем помочь на этом экране?",intro:"iClub AI помогает понять материал и следующий шаг. Во время оценивания он недоступен. Здесь ответы только демонстрационные.",question:"Спросить iClub AI…",foot:"Просмотр интерфейса · AI не меняет оценки",help:"Как работает iClub?",next:"Что делать дальше?",study:"Объяснить тему",progress:"Объяснить прогресс",errors:"Помочь понять ошибку",tour:"Разобрать тур",video:"Помощь по видео",math:"P1 и P5",general:"Помощь по приложению",unavailable:"Это просмотр интерфейса. Настоящий AI не подключён, результаты ученика не читаются.",rHome:"Если практика завершена, сначала стоит разобрать подтверждённые ошибки. Затем можно открыть разрешённый архив тура или продолжить предмет. Личный шаг определяет сервер.",rStudy:"Выберите предмет и тему. iClub AI объяснит её только если утверждённый источник доступен на языке задания.",rProfile:"AI может объяснить подтверждённый прогресс, но не изменяет оценки, рейтинг или сертификаты.",rPractice:"После завершения всей Practice AI объяснит конкретную подтверждённую ошибку и поможет выбрать тему для повторения.",rTour:"Во время тура AI скрыт. Объяснение доступно только после официального открытия архива результатов.",rVideo:"Без проверенной расшифровки AI не должен притворяться, будто видел видео.",rMath:"Maths P1 и P5 имеют отдельные результаты. Работающий Exam Prep Tutor сохраняется без дополнительного списания.",rGeneral:"Я могу помочь с навигацией по iClub. Для персональной рекомендации нужны подтверждённые учебные данные."},
uz:{banner:"iClub AI ko‘rinishi",sub:"Interfeys namunasi · shaxsiy ma’lumotlarsiz",welcome:"Bu sahifada qanday yordam beray?",intro:"iClub AI mavzu va keyingi qadamni tushuntiradi. Baholash davomida ishlamaydi. Bu yerda haqiqiy AI ulanmagan.",question:"iClub AI’dan so‘rash…",foot:"Interfeys ko‘rinishi · AI bahoni o‘zgartirmaydi",help:"iClub qanday ishlaydi?",next:"Keyin nima qilaman?",study:"Mavzuni tushuntir",progress:"Natijamni tushuntir",errors:"Xatoni tushuntir",tour:"Turni tahlil qil",video:"Video bo‘yicha yordam",math:"P1 va P5",general:"Ilova bo‘yicha yordam",unavailable:"Bu faqat interfeys namunasi. Haqiqiy AI ulanmagan va o‘quvchi natijalari olinmaydi.",rHome:"Mashq tugasa, avval tasdiqlangan xatolar, keyin ochiq tur arxivi yoki fan tavsiya qilinadi. Shaxsiy qadamni server aniqlaydi.",rStudy:"Fan va mavzuni tanlang. iClub AI faqat tasdiqlangan manbalar mavjud bo‘lsa tushuntiradi.",rProfile:"AI tasdiqlangan natijani tushuntiradi, lekin baho yoki sertifikatlarni o‘zgartirmaydi.",rPractice:"Practice to‘liq yakunlangach AI tasdiqlangan xatoni tushuntiradi.",rTour:"Tur vaqtida AI yashiriladi. Arxiv rasman ochilgachgina sharhlash mumkin.",rVideo:"Tasdiqlangan transkriptsiz AI videoni ko‘rgandek izoh bermaydi.",rMath:"P1 va P5 natijalari alohida. Amaldagi Exam Prep Tutor o‘zgarmaydi.",rGeneral:"iClub bo‘limlarini tushuntiraman. Shaxsiy maslahat uchun server tasdiqlagan dalil kerak."},
en:{banner:"iClub AI visual review",sub:"Interface example · no personal records",welcome:"How can I help on this screen?",intro:"iClub AI explains learning concepts and next steps. It disappears during assessments. Live AI is not connected here.",question:"Ask iClub AI…",foot:"Interface preview · AI cannot change marks",help:"How does iClub work?",next:"What should I do next?",study:"Explain this topic",progress:"Explain my progress",errors:"Explain a mistake",tour:"Review the Tour",video:"Help with the video",math:"P1 and P5",general:"Help with the app",unavailable:"This is an interface preview. Live AI is not connected, and no student records are read.",rHome:"After completed Practice, review verified mistakes first, then an opened Tour archive or enrolled subject. A personalized step requires server proof.",rStudy:"Select the subject and topic. AI explains only when an approved source exists in the question language.",rProfile:"AI may explain confirmed progress but never changes marks, ranking or certificates.",rPractice:"After the whole Practice is finalized, AI can explain a verified mistake and suggest a topic to review.",rTour:"AI is hidden during Tours. Archive explanations only follow official release.",rVideo:"Without an approved transcript, AI must not claim to have watched the video.",rMath:"P1 and P5 remain separate. The existing Exam Prep Tutor remains unchanged.",rGeneral:"I can help navigate iClub. Personalized advice requires verified server evidence."}
};
const el=(tag,cl,label)=>{const x=document.createElement(tag);x.className=cl||"";if(label)x.textContent=label;return x;};
const c=()=>LANG[["ru","uz","en"].includes(String(window.i18n?.getLang?.()||document.documentElement.lang).toLowerCase())?String(window.i18n?.getLang?.()||document.documentElement.lang).toLowerCase():"ru"];
function context(){
 const view=document.querySelector("main .view.is-active")?.dataset?.view||"splash";
 if(["splash","registration","certificate-verify"].includes(view))return{blocked:true,key:"hidden"};
 if(view!=="courses")return{blocked:false,key:view==="home"?"home":view==="profile"?"profile":"general"};
 const ep=document.getElementById("exam-prep-host-root");
 if(ep&&!ep.hidden&&ep.getAttribute("aria-hidden")!=="true")return{blocked:true,key:"math"};
 const s=document.querySelector("#courses-stack > .stack-screen.is-active")?.dataset?.screen||"";
 if(/quiz|diagnostic|retest|timed|paper|exam/.test(s))return{blocked:true,key:"protected"};
 if(s==="practice-result"||s==="practice-review")return{blocked:false,key:"practice"};
 if(s==="tour-review")return{blocked:false,key:"tour"};
 if(s==="video")return{blocked:false,key:"video"};
 return{blocked:false,key:"study"};
}
document.body.dataset.qaAiReview="true";
const banner=el("div","qa-ai-banner");banner.setAttribute("role","status");
const root=el("div");root.id="qa-ai-root";
const mark=el("button","qa-ai-mark");mark.type="button";mark.setAttribute("aria-label","iClub AI");
const logo=el("img");logo.src="logo.png";logo.alt="iClub";mark.append(logo);
const sheet=el("section","qa-ai-sheet");sheet.hidden=true;sheet.setAttribute("role","dialog");sheet.setAttribute("aria-label","iClub AI");
const head=el("div","qa-ai-head"),titles=el("div"),title=el("strong","", "iClub AI"),sub=el("small");
titles.append(title,sub);const buttons=el("div"),expand=el("button","qa-ai-action","⤢"),close=el("button","qa-ai-action","×");
expand.type=close.type="button";buttons.append(expand,close);head.append(titles,buttons);
const scroll=el("div","qa-ai-scroll"),hello=el("h2"),intro=el("p"),thread=el("div","qa-ai-thread");
scroll.append(hello,intro,thread);
const prompts=el("div","qa-ai-suggestions"),composer=el("div","qa-ai-compose");
const input=el("textarea");input.rows=1;input.maxLength=280;
const send=el("button","qa-ai-send","➤");send.type="button";composer.append(input,send);
const footer=el("div","qa-ai-foot");sheet.append(head,scroll,prompts,composer,footer);root.append(mark,sheet);document.body.append(banner,root);
const st={open:false,expanded:false,wasOpen:false,key:"",threads:new Map()};
const pick=(key)=>key==="home"?["next","help"]:key==="study"?["study","help"]:key==="practice"?["errors","study"]:key==="tour"?["tour","next"]:key==="profile"?["progress","next"]:key==="video"?["video","help"]:["general","help"];
const reply=(key)=>({home:"rHome",study:"rStudy",practice:"rPractice",tour:"rTour",profile:"rProfile",video:"rVideo",math:"rMath",general:"rGeneral"})[key]||"rGeneral";
function showMessages(){
 thread.replaceChildren();(st.threads.get(st.key)||[]).forEach(m=>{
  const b=el("div","qa-ai-bubble"+(m.user?" user":""),m.text);thread.append(b);
 });scroll.scrollTop=scroll.scrollHeight;
}
function render(){
 const ctx=context();st.key=ctx.key;
 if(ctx.blocked){st.open=false;sheet.hidden=true;mark.hidden=true;return;}
 banner.textContent=c().banner;mark.hidden=st.open;sheet.hidden=!st.open;
 sub.textContent=c().sub;hello.textContent=c().welcome;intro.textContent=c().intro;
 footer.textContent=c().foot;input.placeholder=c().question;
 close.setAttribute("aria-label","Close");expand.setAttribute("aria-label","Expand");
 prompts.replaceChildren();pick(ctx.key).forEach(k=>{
  const b=el("button","qa-ai-chip",c()[k]);b.type="button";b.onclick=()=>answer(c()[k]);prompts.append(b);
 });showMessages();
}
function answer(q){
 if(context().blocked)return;
 let a=st.threads.get(st.key);if(!a){a=[];st.threads.set(st.key,a);}
 a.push({text:q,user:true},{text:c()[reply(st.key)]+" "+c().unavailable,user:false});
 if(a.length>14)a.splice(0,a.length-14);
 input.value="";showMessages();
}
mark.onclick=()=>{
 if(context().blocked)return;st.open=true;
 if(!st.wasOpen){st.wasOpen=true;let a=st.threads.get(st.key)||[];
  a.push({text:c().intro,user:false});st.threads.set(st.key,a);}
 render();input.focus();
};
close.onclick=()=>{st.open=false;render();};
expand.onclick=()=>{st.expanded=!st.expanded;sheet.classList.toggle("expanded",st.expanded);render();};
send.onclick=()=>{if(input.value.trim())answer(input.value.trim());};
input.onkeydown=e=>{if(e.key==="Enter"&&!e.shiftKey){e.preventDefault();send.click();}};
let last="";let queued=false;
const observer=new MutationObserver(()=>{if(queued)return;queued=true;queueMicrotask(()=>{
 queued=false;const k=context();const token=k.key+":"+String(k.blocked);
 if(token!==last){last=token;st.open=false;st.expanded=false;sheet.classList.remove("expanded");render();}
});});
const main=document.getElementById("main");if(main)observer.observe(main,{subtree:true,attributes:true,attributeFilter:["class","hidden","aria-hidden"]});
const tab=document.getElementById("tabbar");if(tab)observer.observe(tab,{subtree:true,attributes:true,attributeFilter:["class"]});
document.addEventListener("keydown",e=>{if(e.key==="Escape"&&st.open){st.open=false;render();}});
render();
window.__iClubAiVisualReview=()=>({scope:st.key,visible:!mark.hidden,open:st.open,mode:"visual-only",liveAI:false,academicWrites:false});
})();