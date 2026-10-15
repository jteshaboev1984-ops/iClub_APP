(() => {
"use strict";
// Current APP's original DOM, styles and navigation. Only generated example values.
// Every live SDK, app.js and external script is removed by the demo HTML compiler.
const $=id=>document.getElementById(id);
const card=(title,sub,action,icon)=>{const b=document.createElement("button");b.type="button";b.className="card-btn";
 b.style.cssText="display:flex;align-items:center;gap:12px;width:100%;text-align:left;padding:16px;min-height:75px";
 const badge=document.createElement("span");badge.textContent=icon;
 badge.style.cssText="width:40px;height:40px;display:grid;place-items:center;border-radius:12px;background:#eaf1ff;color:#2F6FD6;font-size:22px";
 const info=document.createElement("span");info.style.cssText="flex:1;min-width:0";
 const t=document.createElement("strong");t.textContent=title;t.style.cssText="display:block;font-size:14px";
 const s=document.createElement("small");s.textContent=sub;s.style.cssText="display:block;color:#64748b;font-size:12px;margin-top:4px";
 info.append(t,s);b.append(badge,info);b.onclick=action;return b;};
const lang=()=>new URLSearchParams(location.search).get("lang")||"ru";
const text={
 ru:{sample:"Просмотр учебного пути · учебные данные",example:"Это пример интерфейса без подключения к ученику или базе.",practice:"Практика",result:"Результат",review:"Разбор ошибок",tour:"Архив тура",study:"Обучение",profile:"Профиль",finish:"Завершить пример",home:"Главная",lesson:"Экономика",q:"Проверка знаний — экран активного задания",subject:"Экономика",opened:"Открыть пример"},
 uz:{sample:"O‘quv yo‘li · namunaviy ma’lumotlar",example:"Haqiqiy o‘quvchi yoki bazaga ulanmagan interfeys namunasi.",practice:"Mashq",result:"Natija",review:"Xatolar tahlili",tour:"Tur arxivi",study:"O‘qish",profile:"Profil",finish:"Namunani yakunlash",home:"Bosh sahifa",lesson:"Iqtisodiyot",q:"Bilimni tekshirish — savol ekrani",subject:"Iqtisodiyot",opened:"Namunani ochish"},
 en:{sample:"Study journey · example data",example:"Interface review with no learner or database connection.",practice:"Practice",result:"Result",review:"Mistake review",tour:"Tour archive",study:"Study",profile:"Profile",finish:"Finish the example",home:"Home",lesson:"Economics",q:"Knowledge check — active question screen",subject:"Economics",opened:"Open example"}
};
const s=text[lang()]||text.ru;
document.documentElement.lang=lang();
const note=document.createElement("div");note.textContent=s.sample;
note.style.cssText="position:fixed;top:0;left:50%;transform:translateX(-50%);z-index:70;padding:5px 12px;background:#ebf2ff;border-radius:0 0 12px 12px;border:1px solid #dae6fc;color:#315caa;font-size:10px;font-weight:750;pointer-events:none";
document.body.append(note);
const top=$("topbar");if(top){top.style.display="grid";top.classList.add("is-no-left");}
const splash=$("view-splash");if(splash)splash.classList.remove("is-active");
const home=$("view-home");if(home)home.classList.add("is-active");
const bars=document.querySelectorAll("#tabbar .tab");
const captions={ru:["Главная","Обучение","Рейтинг","Профиль"],uz:["Bosh sahifa","O‘qish","Reyting","Profil"],en:["Home","Study","Rankings","Profile"]}[lang()]||["Главная","Обучение","Рейтинг","Профиль"];
bars.forEach((tab,i)=>{tab.querySelector(".tab-txt").textContent=captions[i];tab.setAttribute("aria-label",captions[i]);});
function view(name){document.querySelectorAll("#main > .view").forEach(x=>x.classList.toggle("is-active",x.dataset.view===name));bars.forEach(t=>t.classList.toggle("is-active",t.dataset.tab===name));
 if(name==="courses")screen("all-subjects");window.scrollTo(0,0);}
function screen(name){
 document.querySelectorAll("#courses-stack > .stack-screen").forEach(x=>x.classList.toggle("is-active",x.dataset.screen===name));
 window.scrollTo(0,0);
}
bars.forEach(t=>t.onclick=()=>view(t.dataset.tab));
const homeList=$("home-study-list");
const competitive=$("home-competitive-list");
if(homeList){homeList.replaceChildren();
 homeList.append(card(s.subject,"Cambridge International AS & A Level",()=>{view("courses");screen("subject-hub");},"E"));}
if(competitive){competitive.replaceChildren();
 competitive.append(card(s.tour,s.example,()=>{view("courses");screen("tour-review");},"🏆"));}
const heading=document.createElement("div");heading.className="home-block";heading.style.marginTop="18px";
const title=document.createElement("div");title.className="home-block-title";title.textContent=s.sample;
const subtitle=document.createElement("p");subtitle.className="muted small";subtitle.textContent=s.example;
const options=document.createElement("div");options.style.cssText="display:flex;flex-wrap:wrap;gap:10px;margin-top:12px";
const add=(label,fn)=>{const b=document.createElement("button");b.type="button";b.className="btn";b.textContent=label;b.onclick=fn;options.append(b)};
add(s.practice,()=>{view("courses");screen("practice-quiz")});
add(s.result,()=>{view("courses");screen("practice-result")});
add(s.review,()=>{view("courses");screen("practice-review")});
add(s.tour,()=>{view("courses");screen("tour-review")});
heading.append(title,subtitle,options);
const homeContent=home?.querySelector(".content");homeContent?.insertBefore(heading,homeContent.children[2]||null);
const subjectGrid=$("subjects-grid");if(subjectGrid){subjectGrid.replaceChildren();
 subjectGrid.append(card(s.subject,"Cambridge AS • Practice",()=>{view("courses");screen("subject-hub")}, "E"));}
const name=$("subject-hub-title");if(name)name.textContent=s.subject;
const quiz=$("courses-practice-quiz");
if(quiz){const block=document.createElement("div");block.className="card";block.style.cssText="padding:20px;margin-top:22px";
 const label=document.createElement("h2");label.textContent=s.q;label.style.fontSize="20px";
 const row=document.createElement("p");row.className="muted";row.textContent=s.example;
 const finish=document.createElement("button");finish.type="button";finish.className="btn primary";finish.textContent=s.finish;finish.onclick=()=>screen("practice-result");
 block.append(label,row,finish);quiz.prepend(block);}
for(const [id,label,target]of [["courses-practice-result",s.result,"practice-review"],["courses-practice-review",s.review,"subject-hub"],["courses-tour-review",s.tour,"subject-hub"]]){
 const area=$(id);if(!area)continue;const block=document.createElement("div");block.className="card";block.style.cssText="padding:18px;margin:12px 0";
 const h=document.createElement("h2");h.textContent=label;h.style.fontSize="19px";
 const p=document.createElement("p");p.className="muted";p.textContent=s.example;
 const next=document.createElement("button");next.className="btn primary";next.type="button";
 next.textContent=target==="practice-review"?s.review:s.study;next.onclick=()=>screen(target);
 block.append(h,p,next);area.prepend(block);
}
const subject=$("courses-subject-hub");if(subject){
 const btn=document.createElement("div");btn.style.cssText="display:flex;flex-wrap:wrap;gap:8px;margin:12px 0";
 const make=(label,dest)=>{const b=document.createElement("button");b.type="button";b.className="btn";b.textContent=label;b.onclick=()=>screen(dest);btn.append(b)};
 make(s.practice,"practice-quiz");make(s.review,"practice-review");make(s.tour,"tour-review");
 subject.insertBefore(btn,subject.firstChild);
}
window.__iclubQaVisualDemo={view,screen,readOnly:true,backend:false};
})();