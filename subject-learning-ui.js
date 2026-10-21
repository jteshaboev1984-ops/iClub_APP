/* iClub universal subject learning library, v1.
 * Read-only, fail-closed: no academic progress, attempt, result or storage writes.
 * The subject's latest approved publication is resolved by the server.
 */
(() => {
  'use strict';
  const LANGS = ['ru','uz','en'];
  const ALIASES = {
    economics: ['экономика','economics','iqtisodiyot'],
    biology: ['биология','biology','biologiya'],
    chemistry: ['химия','chemistry','kimyo'],
    mathematics: ['математика','mathematics','matematika'],
    informatics: ['информатика','informatics','computer science','informatika']
  };
  const COPY = {
    ru: { title:'Темы и объяснения', sub:'Изучайте теорию и разбирайте примеры в своём темпе', choose:'Выберите тему', search:'Поиск темы', all:'Все туры', tour:'Тур', close:'Закрыть', back:'К списку тем', loading:'Загружаем материал…', unavailable:'Материал сейчас недоступен. Попробуйте позже.', main:'Объяснение', simple:'Проще', alternative:'Другой подход', focus:'Главное', example:'Пример', trap:'Важный нюанс', check:'Проверь себя', answer:'Показать ответ', hideAnswer:'Скрыть ответ', explanation:'Теория' },
    uz: { title:'Mavzular va izohlar', sub:'Nazariyani o‘rganing va misollarni qulay sur’atda ko‘rib chiqing', choose:'Mavzuni tanlang', search:'Mavzuni qidirish', all:'Barcha turlar', tour:'Tur', close:'Yopish', back:'Mavzular ro‘yxatiga', loading:'Material yuklanmoqda…', unavailable:'Material hozir mavjud emas. Keyinroq urinib ko‘ring.', main:'Tushuntirish', simple:'Soddaroq', alternative:'Boshqa usul', focus:'Asosiy jihat', example:'Misol', trap:'Muhim jihat', check:'O‘zingizni tekshiring', answer:'Javobni ko‘rsatish', hideAnswer:'Javobni yashirish', explanation:'Nazariya' },
    en: { title:'Topics and explanations', sub:'Learn the theory and work through examples at your pace', choose:'Choose a topic', search:'Search topics', all:'All tours', tour:'Tour', close:'Close', back:'Back to topics', loading:'Loading material…', unavailable:'This material is unavailable right now. Please try again later.', main:'Explanation', simple:'Simpler', alternative:'Another approach', focus:'Key points', example:'Example', trap:'Important detail', check:'Check your understanding', answer:'Show answer', hideAnswer:'Hide answer', explanation:'Theory' }
  };
  let entry=null, modal=null, catalog=null, loadedKey='', busy=false, subject='', selectedSkill='', selectedTour='all', selectedLocale='ru', selectedVariant='main', currentCard=null, previousFocus=null, lastCheck=0;
  const $=(root,sel)=>root.querySelector(sel);
  function language() {
    try { const l=String(window.i18n?.getLang?.()||document.documentElement.lang||'ru').toLowerCase().split('-')[0];return LANGS.includes(l)?l:'ru'; } catch (_) {return 'ru';}
  }
  function keyFromHub(){
    const direct=String(document.getElementById('courses-subject-hub')?.dataset?.subjectKey||'').toLowerCase();
    if (ALIASES[direct]) return direct;
    const title=String(document.getElementById('subject-hub-title')?.textContent||'').toLowerCase().trim();
    return Object.keys(ALIASES).find(k=>ALIASES[k].some(name=>title===name||title.startsWith(name+' ·')||title.startsWith(name+' —'))) || '';
  }
  function t(){return COPY[selectedLocale]||COPY.ru;}
  function node(tag,cls,txt){const e=document.createElement(tag);if(cls)e.className=cls;if(txt!==undefined)e.textContent=String(txt);return e;}
  function labelText(el,txt){if(el) el.textContent=String(txt||'');}
  function css(){
    if(document.getElementById('iclub-learning-style'))return;
    const s=node('style');s.id='iclub-learning-style';s.textContent=`
    .iclub-learning-entry{width:100%;text-align:left;margin:10px 0;display:flex;align-items:center;justify-content:space-between;gap:18px;border:1px solid rgba(65,121,207,.24);background:linear-gradient(112deg,rgba(237,245,255,.94),rgba(250,252,255,.98));border-radius:18px;padding:17px 18px;cursor:pointer;color:#19355e;box-shadow:0 6px 20px rgba(29,59,111,.045)}
    .iclub-learning-entry[hidden]{display:none!important}.iclub-learning-entry:focus-visible{outline:3px solid #3577d4;outline-offset:3px}
    .iclub-learning-entry strong{display:block;font-size:16px;line-height:1.32}.iclub-learning-entry small{display:block;font-size:12px;line-height:1.5;color:#526c8c;margin-top:5px}.iclub-learning-entry .iclub-learning-chevron{font-size:26px;flex:0 0 auto}
    #iclub-learning-modal[hidden]{display:none!important}#iclub-learning-modal{position:fixed;inset:0;z-index:2147482000;background:rgba(17,34,62,.68);display:flex;align-items:center;justify-content:center;padding:12px;box-sizing:border-box}
    #iclub-learning-modal *{box-sizing:border-box}#iclub-learning-modal .il-card{display:flex;flex-direction:column;background:#fbfdff;color:#193052;border-radius:22px;width:min(1040px,100%);height:min(92dvh,900px);min-height:280px;overflow:hidden;box-shadow:0 24px 75px rgba(0,12,34,.34)}
    #iclub-learning-modal .il-head{display:flex;align-items:center;gap:14px;padding:18px 22px;border-bottom:1px solid #e0e9f6;flex:0 0 auto}#iclub-learning-modal .il-head-name{flex:1;min-width:0}#iclub-learning-modal .il-head h2{font-size:20px;line-height:1.24;font-weight:800;margin:0;color:#1b3762}#iclub-learning-modal .il-head p{font-size:12px;color:#5c718f;margin:4px 0 0}
    #iclub-learning-modal .il-close,#iclub-learning-modal .il-back{border:1px solid #d9e4f3;background:#fff;color:#21477b;border-radius:12px;padding:10px 13px;min-height:41px;font-weight:700;cursor:pointer}
    #iclub-learning-modal .il-body{display:grid;grid-template-columns:minmax(250px,350px) minmax(0,1fr);min-height:0;flex:1}#iclub-learning-modal .il-list{padding:15px;border-right:1px solid #e0e9f6;overflow:auto;min-width:0}#iclub-learning-modal .il-fields{display:grid;grid-template-columns:1fr;gap:10px;margin-bottom:12px}
    #iclub-learning-modal input,#iclub-learning-modal select{width:100%;font:inherit;color:#23456e;padding:10px 12px;border:1px solid #cddded;border-radius:10px;background:white;min-height:41px}
    #iclub-learning-modal .il-skills{display:flex;flex-direction:column;gap:6px}#iclub-learning-modal .il-skill{border:1px solid transparent;text-align:left;border-radius:12px;padding:11px 12px;background:transparent;color:#27466e;cursor:pointer;font-size:13px;line-height:1.4}#iclub-learning-modal .il-skill:hover{background:#eef5ff}#iclub-learning-modal .il-skill[aria-current="true"]{background:#e6f0ff;border-color:#b8d1f7;font-weight:750}
    #iclub-learning-modal .il-detail{min-width:0;overflow:auto;padding:22px 25px 34px}#iclub-learning-modal .il-back{display:none;margin-bottom:14px}
    #iclub-learning-modal .il-detail h3{font-size:21px;line-height:1.34;margin:0 0 18px;color:#1c3a65}#iclub-learning-modal .il-eyebrow{display:block;font-size:12px;font-weight:750;color:#52749f;margin-bottom:6px}
    #iclub-learning-modal .il-tabs{display:flex;flex-wrap:wrap;gap:7px;margin-bottom:15px}#iclub-learning-modal .il-tabs button{border:1px solid #d6e3f4;border-radius:999px;background:#fff;color:#32567f;padding:9px 12px;min-height:38px;font-size:12px;font-weight:700;cursor:pointer}#iclub-learning-modal .il-tabs button[aria-selected="true"]{color:#fff;background:#2f6fd6;border-color:#2f6fd6}
    #iclub-learning-modal .il-text{font-size:14px;line-height:1.72;white-space:pre-wrap;color:#263e60;margin:0}#iclub-learning-modal .il-section{background:#fff;border:1px solid #e2eaf5;border-radius:14px;padding:15px;margin-top:13px}#iclub-learning-modal .il-section h4{font-size:13px;margin:0 0 8px;color:#2c5d98}#iclub-learning-modal .il-reveal{background:#edf4ff;border:1px solid #cadcf7;color:#245998;padding:9px 12px;border-radius:10px;cursor:pointer;font-weight:700;margin-top:12px}#iclub-learning-modal .il-status{font-size:14px;line-height:1.5;color:#6a7790}
    @media (max-width:700px){#iclub-learning-modal{padding:0}#iclub-learning-modal .il-card{border-radius:0;width:100%;height:100dvh;max-height:none}#iclub-learning-modal .il-head{padding:13px 16px}#iclub-learning-modal .il-head h2{font-size:17px}#iclub-learning-modal .il-head p{font-size:11px}#iclub-learning-modal .il-body{display:block}#iclub-learning-modal .il-list{height:100%;border-right:0;padding:13px 15px}#iclub-learning-modal .il-detail{height:100%;padding:18px 17px 30px}#iclub-learning-modal[data-detail="true"] .il-list{display:none}#iclub-learning-modal:not([data-detail="true"]) .il-detail{display:none}#iclub-learning-modal .il-back{display:inline-block}}
    `;document.head.appendChild(s);
  }
  function setup(){
    if(entry) return true;
    const hub=document.getElementById('courses-subject-hub');const modes=hub?.querySelector('.subject-hub-primary-modes');
    if(!hub||!modes)return false;
    css();entry=node('button','iclub-learning-entry');entry.type='button';entry.hidden=true;const left=node('span');left.append(node('strong','',COPY.ru.title),node('small','',COPY.ru.sub));entry.append(left,node('span','iclub-learning-chevron','›'));modes.insertBefore(entry,modes.querySelector('.subject-hub-exam-prep-entry')||modes.children[1]||null);
    entry.addEventListener('click',()=>{if(catalog)open();});
    modal=node('div');modal.id='iclub-learning-modal';modal.hidden=true;modal.dataset.detail='false';modal.setAttribute('role','dialog');modal.setAttribute('aria-modal','true');modal.setAttribute('aria-label',COPY.ru.title);
    modal.innerHTML='<div class="il-card"><header class="il-head"><div class="il-head-name"><h2 class="il-modal-title"></h2><p class="il-modal-sub"></p></div><button type="button" class="il-close"></button></header><div class="il-body"><aside class="il-list"><div class="il-fields"><input class="il-search" type="search"/><select class="il-tour"></select></div><div class="il-skills"></div></aside><main class="il-detail" tabindex="-1"><button type="button" class="il-back"></button><div class="il-material"></div></main></div></div>';
    document.body.appendChild(modal);
    $(modal,'.il-close').addEventListener('click',close);$(modal,'.il-back').addEventListener('click',()=>{modal.dataset.detail='false';selectedSkill='';});
    $(modal,'.il-search').addEventListener('input',renderList);$(modal,'.il-tour').addEventListener('change',e=>{selectedTour=e.target.value;renderList();});
    document.addEventListener('keydown',e=>{if(e.key==='Escape'&&!modal.hidden)close();});return true;
  }
  function decorate(){
    const c=t();labelText(entry.querySelector('strong'),c.title);labelText(entry.querySelector('small'),c.sub);
    labelText($(modal,'.il-modal-title'),c.title);labelText($(modal,'.il-modal-sub'),c.sub);labelText($(modal,'.il-close'),c.close);labelText($(modal,'.il-back'),c.back);
    $(modal,'.il-search').placeholder=c.search;modal.setAttribute('aria-label',c.title);
    const select=$(modal,'.il-tour');select.replaceChildren();const add=(v,label)=>{const o=node('option','',label);o.value=v;select.appendChild(o);};add('all',c.all);const tours=[...new Set((catalog?.skills||[]).map(x=>x.tour_no))].sort((a,b)=>a-b);tours.forEach(n=>add(String(n),c.tour+' '+n));select.value=selectedTour;
  }
  function close(){modal.hidden=true;modal.dataset.detail='false';currentCard=null;selectedSkill='';try{previousFocus?.focus();}catch(_) {}}
  function open(){if(!setup()||!catalog)return;previousFocus=document.activeElement;selectedLocale=language();selectedTour='all';selectedSkill='';currentCard=null;selectedVariant='main';decorate();$(modal,'.il-search').value='';modal.hidden=false;modal.dataset.detail='false';renderList();$(modal,'.il-close').focus();}
  function renderList(){if(!catalog)return;const search=$(modal,'.il-search').value.toLocaleLowerCase().trim();const box=$(modal,'.il-skills');box.replaceChildren();const skills=(catalog.skills||[]).filter(x=>(selectedTour==='all'||String(x.tour_no)===selectedTour)&&(!search||[x.title,x.skill_key,x.syllabus_point].some(v=>String(v||'').toLocaleLowerCase().includes(search))));
    for(const skill of skills){const btn=node('button','il-skill',`${skill.syllabus_point} · ${skill.title||skill.skill_key}`);btn.type='button';btn.setAttribute('aria-current',String(skill.skill_key===selectedSkill));btn.addEventListener('click',()=>loadSkill(skill.skill_key));box.appendChild(btn);}if(!skills.length)box.appendChild(node('p','il-status',t().unavailable));
  }
  function section(root,title,body){if(!body)return;const wrap=node('section','il-section');wrap.append(node('h4','',title),node('p','il-text',body));root.appendChild(wrap);}
  function renderCard(){const dest=$(modal,'.il-material');dest.replaceChildren();const d=currentCard;if(!d){dest.appendChild(node('p','il-status',t().unavailable));return;}
    const th=d.theory||{},tu=d.tutor||{};const cc=t();dest.append(node('span','il-eyebrow',`${cc.tour} ${d.tour_no} · ${d.syllabus_point}`),node('h3','',String(th.title||tu.title||d.skill_key)));
    const tabs=node('div','il-tabs');const options=[['main','main_explanation'],['simple','simple_explanation'],['alternative','alternative_explanation'],['focus','focus_explanation']];
    for(const [k] of options){const b=node('button','',cc[k]);b.type='button';b.setAttribute('aria-selected',String(selectedVariant===k));b.addEventListener('click',()=>{selectedVariant=k;renderCard();});tabs.appendChild(b);}dest.appendChild(tabs);
    const selected=options.find(x=>x[0]===selectedVariant)||options[0];dest.appendChild(node('p','il-text',String(tu[selected[1]]||th.explanation||'')));
    if(selectedVariant==='main'){section(dest,cc.example,th.original_example);section(dest,cc.trap,th.common_trap);if(th.check_question){const div=node('section','il-section');div.append(node('h4','',cc.check),node('p','il-text',th.check_question));const answer=node('p','il-text',th.check_answer||'');answer.hidden=true;const reveal=node('button','il-reveal',cc.answer);reveal.type='button';reveal.addEventListener('click',()=>{answer.hidden=!answer.hidden;reveal.textContent=answer.hidden?cc.answer:cc.hideAnswer;});div.append(reveal,answer);dest.appendChild(div);}}
  }
  async function loadSkill(skillKey){if(!catalog||!window.sb?.rpc)return;selectedSkill=skillKey;modal.dataset.detail='true';$(modal,'.il-material').replaceChildren(node('p','il-status',t().loading));selectedVariant='main';renderList();const expectedSubject=subject,expectedLocale=selectedLocale;try{const {data,error}=await window.sb.rpc('get_my_subject_learning_content_v1',{p_subject_key:subject,p_skill_key:skillKey,p_locale:selectedLocale});if(error)throw error;if(subject!==expectedSubject||selectedLocale!==expectedLocale||selectedSkill!==skillKey||modal.hidden)return;currentCard=data&&data.skill_key===skillKey?data:null;renderCard();}catch(_){if(selectedSkill===skillKey){currentCard=null;renderCard();}}}
  async function refresh(force=false){if(!setup()||busy)return;const hub=document.getElementById('courses-subject-hub');const key=keyFromHub(),locale=language();if(!hub?.classList.contains('is-active')||!key){entry.hidden=true;return;}const target=key+'|'+locale;if(!force&&target===loadedKey&&Date.now()-lastCheck<30000)return;if(!window.sb?.rpc){entry.hidden=true;return;}busy=true;try{const {data,error}=await window.sb.rpc('get_my_subject_learning_catalog_v1',{p_subject_key:key,p_locale:locale});if(error)throw error;if(key!==keyFromHub()||locale!==language())return;catalog=data&&Array.isArray(data.skills)&&data.skills.length?data:null;subject=key;selectedLocale=locale;entry.hidden=!catalog;if(catalog)decorate();loadedKey=target;lastCheck=Date.now();}catch(_){entry.hidden=true;catalog=null;loadedKey='';}finally{busy=false;}}
  function boot(){if(!setup())return;const hub=document.getElementById('courses-subject-hub'),title=document.getElementById('subject-hub-title');if(hub)new MutationObserver(()=>{lastCheck=0;refresh();}).observe(hub,{attributes:true,attributeFilter:['class','data-subject-key']});if(title)new MutationObserver(()=>{lastCheck=0;refresh();}).observe(title,{childList:true,characterData:true,subtree:true});setInterval(()=>refresh(),2000);refresh();}
  if(document.readyState==='loading')document.addEventListener('DOMContentLoaded',boot,{once:true});else boot();
})();