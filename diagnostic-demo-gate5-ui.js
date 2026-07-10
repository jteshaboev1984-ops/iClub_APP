(()=>{'use strict';
const CARDS=window.ICLUB_DEMO_GATE5_CARDS||[];
const DATA=window.ICLUB_DEMO_V12_DATA;
const G4=window.ICLUB_DEMO_GATE4_DATA;
if(!DATA||CARDS.length<30)return;

const PREFIX='iclub_demo_v12.';
const CHAT_KEY=PREFIX+'chat';
const TECH_KEY=PREFIX+'technical';
const $=id=>document.getElementById(id);
const read=(store,key,fallback)=>{try{return JSON.parse(store.getItem(key)||'')??fallback}catch{return fallback}};
const write=(store,key,value)=>{try{store.setItem(key,JSON.stringify(value))}catch{}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(localStorage,PREFIX+'state',{}).lang||'ru');
const loc=value=>value?.[lang()]??value?.ru??value?.en??value?.uz??value??'';
const plan=()=>document.querySelector('[data-plan].is-active')?.dataset.plan||read(localStorage,PREFIX+'state',{}).plan||'free';
const el=(tag,cls,text)=>{const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined&&text!==null)node.textContent=text;return node};
const append=(parent,...children)=>{children.filter(Boolean).forEach(child=>parent.appendChild(child));return parent};
const now=()=>new Date().toISOString();
const uid=prefix=>`${prefix}-${Date.now()}-${Math.random().toString(36).slice(2,7)}`;
const normalize=value=>String(value||'').toLowerCase().replace(/ё/g,'е').replace(/[’‘`]/g,"'").replace(/[^a-zа-я0-9қғўҳ\s=><]+/gi,' ').replace(/\s+/g,' ').trim();

const COPY={
 ru:{
  hubFree:'AI-репетитор',hubFreeSub:'Доступен в Plus. Ответы по проверенным материалам iClub.',hubFreeAction:'Посмотреть Plus и Pro',
  hubPlus:'AI-репетитор по экономике',hubPlusSub:'Задайте вопрос по теме, формуле или понятию.',hubPlusAction:'Открыть репетитора',
  hubPro:'AI-репетитор с учётом прогресса',hubProSub:'Помощь по экономике и связь с вашей текущей практикой.',hubProAction:'Продолжить обучение',
  chatTitle:'AI-репетитор по экономике',chatSub:'Ответы по проверенным материалам iClub',dialog:'Диалог',dialogs:'Диалоги',history:'История',progress:'Прогресс',
  welcome:'Задайте вопрос по понятию, формуле или различию между темами.',verified:'Проверенный ответ iClub',short:'Коротко',simple:'Простыми словами',example:'Пример',source:'Источник',
  fill:'Заполнить вопрос',send:'Отправить',placeholder:'Напишите вопрос по экономике…',filled:'Вопрос вставлен. Отправьте его самостоятельно.',empty:'Диалогов пока нет.',
  easier:'Объяснить проще',showExample:'Показать на примере',check:'Проверить понимание',practice:'Закрепить в практике',
  microTitle:'Проверьте понимание',microAnswer:'Показать ответ',practiceReady:'Открываю диагностическую практику по этому навыку.',
  noSource:'В проверенных материалах iClub пока нет достаточно точной карточки для этого вопроса.',noSourceSub:'Попробуйте спросить определение, формулу или сравнение двух понятий.',
  context:'Разбор отправленного ответа',yourAnswer:'Ваш ответ',correctAnswer:'Правильный ответ',answerCorrect:'Ответ верный. Ниже — связь с ключевым понятием.',
  reviewAI:'Разобрать с AI',attemptAI:'Разобрать текущую попытку с AI',noAttempt:'Сначала завершите диагностическую практику.',
  compare:'Что добавляют тарифы',plus:'Plus',pro:'Pro',plus1:'Постоянный предметный чат',plus2:'Проверенные объяснения и примеры',plus3:'Разбор текущего ответа и попытки',pro1:'Всё из Plus',pro2:'Траектория по нескольким попыткам',pro3:'Evidence, надёжность и точный следующий шаг',choosePlus:'Показать Plus',choosePro:'Показать Pro',close:'Закрыть',
  quick1:'Чем аллокативная эффективность отличается от производственной?',quick2:'Что такое кривая безразличия?',quick3:'Объясни условие MR = MC',
  historyTitle:'История с репетитором',today:'Сегодня',openChat:'Вернуться к диалогу',draftSaved:'Черновик сохранён',
  proProgressEmpty:'Сначала завершите диагностику, чтобы открыть персональную траекторию.',
  technicalMode:'Режим ответа',technicalModel:'Model call',technicalSource:'Источник',technicalLatency:'Время',technicalQuota:'Quota',technicalRenderer:'Renderer',notCharged:'не списана',
  cardCount:n=>`${n} проверенных карточек`,sourceLine:card=>`iClub Economics · ${loc(card.topic)} · ${loc(card.section)}`,
  autofillQuestion:'Чем allocative efficiency отличается от productive efficiency?'
 },
 uz:{
  hubFree:'AI-repetitor',hubFreeSub:'Plus tarifida mavjud. iClub tekshirgan materiallar asosida javob beradi.',hubFreeAction:'Plus va Pro ni ko‘rish',
  hubPlus:'Iqtisodiyot bo‘yicha AI-repetitor',hubPlusSub:'Mavzu, formula yoki tushuncha haqida savol bering.',hubPlusAction:'Repetitorni ochish',
  hubPro:'Progressni hisobga oluvchi AI-repetitor',hubProSub:'Iqtisodiyot bo‘yicha yordam va joriy mashq bilan bog‘lanish.',hubProAction:'O‘qishni davom ettirish',
  chatTitle:'Iqtisodiyot bo‘yicha AI-repetitor',chatSub:'iClub tekshirgan materiallar asosidagi javoblar',dialog:'Dialog',dialogs:'Dialoglar',history:'Tarix',progress:'Progress',
  welcome:'Tushuncha, formula yoki mavzular farqi haqida savol bering.',verified:'iClub tekshirgan javob',short:'Qisqacha',simple:'Oddiy tilda',example:'Misol',source:'Manba',
  fill:'Savolni to‘ldirish',send:'Yuborish',placeholder:'Iqtisodiyot bo‘yicha savol yozing…',filled:'Savol kiritildi. Uni o‘zingiz yuboring.',empty:'Hozircha dialog yo‘q.',
  easier:'Soddaroq tushuntirish',showExample:'Misolda ko‘rsatish',check:'Tushunishni tekshirish',practice:'Mashqda mustahkamlash',
  microTitle:'Tushunishni tekshiring',microAnswer:'Javobni ko‘rsatish',practiceReady:'Shu ko‘nikma bo‘yicha diagnostik mashq ochilmoqda.',
  noSource:'iClub tekshirgan materiallarda bu savol uchun yetarlicha aniq karta hozircha yo‘q.',noSourceSub:'Ta’rif, formula yoki ikki tushunchani solishtirishni so‘rang.',
  context:'Yuborilgan javob tahlili',yourAnswer:'Sizning javobingiz',correctAnswer:'To‘g‘ri javob',answerCorrect:'Javob to‘g‘ri. Quyida asosiy tushuncha bilan bog‘lanish berilgan.',
  reviewAI:'AI bilan tahlil qilish',attemptAI:'Joriy urinishni AI bilan tahlil qilish',noAttempt:'Avval diagnostik mashqni tugating.',
  compare:'Tariflar nima qo‘shadi',plus:'Plus',pro:'Pro',plus1:'Doimiy fan bo‘yicha chat',plus2:'Tekshirilgan izoh va misollar',plus3:'Joriy javob va urinish tahlili',pro1:'Plus dagi barcha imkoniyatlar',pro2:'Bir nechta urinish bo‘yicha yo‘l',pro3:'Dalillar, ishonchlilik va aniq keyingi qadam',choosePlus:'Plus ni ko‘rsatish',choosePro:'Pro ni ko‘rsatish',close:'Yopish',
  quick1:'Allokativ samaradorlik ishlab chiqarish samaradorligidan nimasi bilan farq qiladi?',quick2:'Befarqlik egri chizig‘i nima?',quick3:'MR = MC shartini tushuntir',
  historyTitle:'Repetitor bilan tarix',today:'Bugun',openChat:'Dialogga qaytish',draftSaved:'Qoralama saqlandi',
  proProgressEmpty:'Shaxsiy o‘quv yo‘lini ochish uchun avval diagnostikani tugating.',
  technicalMode:'Javob rejimi',technicalModel:'Model chaqiruvi',technicalSource:'Manba',technicalLatency:'Vaqt',technicalQuota:'Kvota',technicalRenderer:'Renderer',notCharged:'yechilmadi',
  cardCount:n=>`${n} ta tekshirilgan karta`,sourceLine:card=>`iClub Economics · ${loc(card.topic)} · ${loc(card.section)}`,
  autofillQuestion:'Allokativ samaradorlik ishlab chiqarish samaradorligidan nimasi bilan farq qiladi?'
 },
 en:{
  hubFree:'AI tutor',hubFreeSub:'Available in Plus. Answers from verified iClub materials.',hubFreeAction:'View Plus and Pro',
  hubPlus:'Economics AI tutor',hubPlusSub:'Ask about a topic, formula, or concept.',hubPlusAction:'Open tutor',
  hubPro:'AI tutor with progress context',hubProSub:'Economics help connected to the current practice.',hubProAction:'Continue learning',
  chatTitle:'Economics AI tutor',chatSub:'Answers from verified iClub materials',dialog:'Chat',dialogs:'Chats',history:'History',progress:'Progress',
  welcome:'Ask about a concept, formula, or the difference between topics.',verified:'Verified iClub answer',short:'In brief',simple:'In simple words',example:'Example',source:'Source',
  fill:'Fill question',send:'Send',placeholder:'Ask an Economics question…',filled:'The question is inserted. Send it yourself.',empty:'No tutor conversations yet.',
  easier:'Explain more simply',showExample:'Show an example',check:'Check understanding',practice:'Reinforce in practice',
  microTitle:'Check your understanding',microAnswer:'Show answer',practiceReady:'Opening diagnostic practice for this skill.',
  noSource:'The verified iClub materials do not yet contain a sufficiently precise card for this question.',noSourceSub:'Try asking for a definition, formula, or comparison of two concepts.',
  context:'Submitted-answer review',yourAnswer:'Your answer',correctAnswer:'Correct answer',answerCorrect:'The answer is correct. Below is the link to the key concept.',
  reviewAI:'Review with AI',attemptAI:'Review current attempt with AI',noAttempt:'Complete the diagnostic practice first.',
  compare:'What each plan adds',plus:'Plus',pro:'Pro',plus1:'Persistent subject chat',plus2:'Verified explanations and examples',plus3:'Current answer and attempt review',pro1:'Everything in Plus',pro2:'A path across multiple attempts',pro3:'Evidence, reliability, and an exact next step',choosePlus:'Show Plus',choosePro:'Show Pro',close:'Close',
  quick1:'How is allocative efficiency different from productive efficiency?',quick2:'What is an indifference curve?',quick3:'Explain the MR = MC condition',
  historyTitle:'History with tutor',today:'Today',openChat:'Back to chat',draftSaved:'Draft saved',
  proProgressEmpty:'Complete the diagnosis first to open the personal learning path.',
  technicalMode:'Answer mode',technicalModel:'Model call',technicalSource:'Source',technicalLatency:'Latency',technicalQuota:'Quota',technicalRenderer:'Renderer',notCharged:'not charged',
  cardCount:n=>`${n} verified cards`,sourceLine:card=>`iClub Economics · ${loc(card.topic)} · ${loc(card.section)}`,
  autofillQuestion:'How is allocative efficiency different from productive efficiency?'
 }
};
const t=()=>COPY[lang()]||COPY.ru;

const aliasIndex=new Map();
CARDS.forEach(card=>{
 ['ru','uz','en'].forEach(code=>{
  const values=[...(card.aliases?.[code]||[]),card.section?.[code],card.topic?.[code]];
  values.filter(Boolean).forEach(value=>aliasIndex.set(`${code}:${normalize(value)}`,card));
 });
});
const skillMap=new Map(CARDS.map(card=>[card.skillId,card]));
const questionSkill={d1:'utility_meaning',d2:'diminishing_marginal_utility',d3:'indifference_curve_definition',d4:'budget_line_income_shift',d5:'allocative_efficiency_condition',d6:'productive_efficiency_condition',d7:'internal_external_growth'};

let chatOpen=false;
let chatTab='dialog';
let chatOrigin='courses-subject-hub';
let toastTimer=null;
let renderLock=false;

function toast(message){const node=$('toast');if(!node)return;node.textContent=message;node.classList.add('is-show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>node.classList.remove('is-show'),2400)}
function getChat(){const value=read(localStorage,CHAT_KEY,{});return{version:'gate5-v1',messages:Array.isArray(value.messages)?value.messages:[],draft:String(value.draft||''),lastMode:value.lastMode||null,lastSourceIds:Array.isArray(value.lastSourceIds)?value.lastSourceIds:[],unread:Number(value.unread||0)}}
function saveChat(value){write(localStorage,CHAT_KEY,{...getChat(),...value,version:'gate5-v1'})}
function latestAttempt(){const history=read(localStorage,PREFIX+'history',{diagnostics:[]});const rows=history.diagnostics||[];return rows[rows.length-1]||null}
function currentVisibleScreen(){return [...document.querySelectorAll('#courses-stack > .stack-screen')].find(node=>!node.hidden&&node.classList.contains('is-active'))?.id||'courses-subject-hub'}
function hideAllScreens(){document.querySelectorAll('#courses-stack > .stack-screen').forEach(node=>{node.hidden=true;node.classList.remove('is-active');node.setAttribute('aria-hidden','true')})}
function showExistingScreen(id){hideAllScreens();const node=$(id)||$('courses-subject-hub');if(node){node.hidden=false;node.classList.add('is-active');node.setAttribute('aria-hidden','false')}}

function ensureHubCard(){
 let card=$('demo-ai-hub-card');
 if(card)return card;
 const panels=document.querySelector('#courses-subject-hub .subject-hub-panels');
 if(!panels)return null;
 card=el('button','panel-card subject-hub-panel demo-ai-hub-card');card.type='button';card.id='demo-ai-hub-card';
 const row=el('div','panel-row');
 const mark=el('span','demo-ai-hub-mark');const img=document.createElement('img');img.src='iclub-ai-mark.svg';img.alt='';mark.appendChild(img);mark.appendChild(el('span','demo-ai-lock-mark'));
 const copy=el('div','panel-col demo-ai-hub-copy');append(copy,el('div','panel-kicker','iClub AI'),el('div','panel-title',''),el('div','muted small',''));
 const side=el('span','demo-ai-hub-side');append(side,el('span','demo-ai-plan-chip',''),el('span','settings-nav-arrow','›'));
 append(row,mark,copy,side);card.appendChild(row);panels.appendChild(card);return card;
}
function renderHubCard(){
 const card=ensureHubCard();if(!card)return;const p=plan();const title=card.querySelector('.panel-title'),sub=card.querySelector('.muted.small'),chip=card.querySelector('.demo-ai-plan-chip');
 card.classList.toggle('is-locked',p==='free');card.classList.toggle('is-available',p!=='free');
 if(p==='free'){title.textContent=t().hubFree;sub.textContent=t().hubFreeSub;chip.textContent='Plus'}
 else if(p==='plus'){title.textContent=t().hubPlus;sub.textContent=t().hubPlusSub;chip.textContent='Plus'}
 else{title.textContent=t().hubPro;sub.textContent=t().hubProSub;chip.textContent='Pro'}
 card.setAttribute('aria-label',`${title.textContent}. ${sub.textContent}`);
}

function ensureChatScreen(){
 let screen=$('courses-ai-chat');if(screen)return screen;
 screen=el('section','stack-screen demo-ai-chat-screen');screen.id='courses-ai-chat';screen.hidden=true;screen.setAttribute('aria-hidden','true');
 const head=el('div','section demo-ai-chat-head');
 const titleRow=el('div','demo-ai-chat-title-row');const mark=el('span','demo-ai-chat-mark');const img=document.createElement('img');img.src='iclub-ai-mark.svg';img.alt='';mark.appendChild(img);
 const copy=el('div','demo-ai-chat-title-copy');append(copy,el('div','h1 demo-ai-chat-title',''),el('div','muted small demo-ai-chat-sub',''));
 append(titleRow,mark,copy,el('span','demo-ai-chat-plan',''));
 const tabs=el('div','demo-ai-chat-tabs');tabs.id='demo-ai-chat-tabs';
 append(head,titleRow,tabs);
 const body=el('div','demo-ai-chat-body');body.id='demo-ai-chat-body';
 const composer=el('div','demo-ai-composer');composer.id='demo-ai-composer';
 const tools=el('div','demo-ai-composer-tools');const fill=el('button','demo-ai-fill-btn','');fill.type='button';fill.id='demo-ai-fill-btn';tools.appendChild(fill);
 const row=el('div','demo-ai-composer-row');const input=document.createElement('textarea');input.id='demo-ai-input';input.className='demo-ai-input';input.rows=1;input.maxLength=500;
 const send=el('button','btn primary demo-ai-send','');send.type='button';send.id='demo-ai-send';append(row,input,send);append(composer,tools,row);
 append(screen,head,body,composer);$('courses-stack')?.appendChild(screen);return screen;
}

function makeTabs(){
 const tabs=$('demo-ai-chat-tabs');if(!tabs)return;tabs.replaceChildren();
 const p=plan();
 const items=p==='pro'?[['dialog',t().dialogs],['progress',t().progress]]:[['dialog',t().dialog],['history',t().history]];
 items.forEach(([id,label])=>{const btn=el('button',`demo-ai-chat-tab ${chatTab===id?'is-active':''}`,label);btn.type='button';btn.dataset.chatTab=id;tabs.appendChild(btn)});
}

function quickPrompts(){const wrap=el('div','demo-ai-quick');[t().quick1,t().quick2,t().quick3].forEach(text=>{const btn=el('button','demo-ai-quick-btn',text);btn.type='button';btn.dataset.quickPrompt=text;wrap.appendChild(btn)});return wrap}
function verifiedBadge(){const badge=el('span','demo-ai-verified');const img=document.createElement('img');img.src='iclub-ai-mark.svg';img.alt='';append(badge,img,el('span','',t().verified));return badge}
function section(label,text){const box=el('div','demo-ai-answer-section');append(box,el('b','',label),el('p','',text));return box}

function assistantCard(message){
 const card=CARDS.find(item=>item.id===message.cardId);if(!card)return null;
 const wrap=el('article','demo-ai-message is-assistant');
 const bubble=el('div','demo-ai-bubble');bubble.appendChild(verifiedBadge());
 if(message.context){
  const ctx=el('div','demo-ai-context');append(ctx,el('b','',t().context));
  const q=DATA.questions.find(item=>item.id===message.context.questionId);
  const line=el('div','demo-ai-context-grid');append(line,append(el('span',''),el('small','',t().yourAnswer),el('b','',message.context.selected||'—')),append(el('span',''),el('small','',t().correctAnswer),el('b','',q?.a||'—')));ctx.appendChild(line);
  const explanation=message.context.correct?t().answerCorrect:loc(q?.bad);if(explanation)ctx.appendChild(el('p','',explanation));bubble.appendChild(ctx);
 }
 const variant=message.variant||'full';
 if(variant==='simple')bubble.appendChild(section(t().simple,loc(card.simple)));
 else if(variant==='example')bubble.appendChild(section(t().example,loc(card.example)));
 else if(variant==='check'){
  const check=el('div','demo-ai-microcheck');append(check,el('b','',t().microTitle),el('p','',loc(card.check)));
  const btn=el('button','btn demo-ai-show-check',t().microAnswer);btn.type='button';btn.dataset.cardId=card.id;check.appendChild(btn);bubble.appendChild(check);
 }else if(variant==='check_answer')bubble.appendChild(section(t().microTitle,loc(card.checkAnswer)));
 else{
  bubble.appendChild(section(t().short,loc(card.short)));bubble.appendChild(section(t().simple,loc(card.simple)));if(loc(card.example))bubble.appendChild(section(t().example,loc(card.example)));
 }
 const source=el('div','demo-ai-source');append(source,el('b','',t().source),el('span','',t().sourceLine(card)));bubble.appendChild(source);
 if(['full','simple','example'].includes(variant)){
  const actions=el('div','demo-ai-actions');
  [[t().easier,'simple'],[t().showExample,'example'],[t().check,'check'],[t().practice,'practice']].forEach(([label,action])=>{const btn=el('button','demo-ai-action',label);btn.type='button';btn.dataset.aiAction=action;btn.dataset.cardId=card.id;actions.appendChild(btn)});bubble.appendChild(actions);
 }
 wrap.appendChild(bubble);return wrap;
}
function noSourceMessage(){const wrap=el('article','demo-ai-message is-assistant');const bubble=el('div','demo-ai-bubble is-no-source');append(bubble,el('b','',t().noSource),el('p','',t().noSourceSub));wrap.appendChild(bubble);return wrap}
function userMessage(message){const wrap=el('article','demo-ai-message is-user');wrap.appendChild(el('div','demo-ai-bubble',message.text));return wrap}

function renderDialog(){
 const body=$('demo-ai-chat-body');if(!body)return;body.replaceChildren();
 const chat=getChat();
 if(!chat.messages.length){const intro=el('div','demo-ai-welcome');const mark=el('span','demo-ai-welcome-mark');const img=document.createElement('img');img.src='iclub-ai-mark.svg';img.alt='';mark.appendChild(img);append(intro,mark,el('b','',t().welcome),el('span','',t().cardCount(CARDS.length)));body.appendChild(intro);body.appendChild(quickPrompts())}
 chat.messages.forEach(message=>{let node=null;if(message.role==='user')node=userMessage(message);else if(message.type==='no_source')node=noSourceMessage();else node=assistantCard(message);if(node)body.appendChild(node)});
 requestAnimationFrame(()=>{body.scrollTop=body.scrollHeight});
}
function renderHistory(){
 const body=$('demo-ai-chat-body');if(!body)return;body.replaceChildren();const chat=getChat();const users=chat.messages.filter(item=>item.role==='user');
 const head=el('div','demo-ai-history-head');append(head,el('div','h2',t().historyTitle),el('div','muted small',t().cardCount(CARDS.length)));body.appendChild(head);
 if(!users.length){body.appendChild(el('div','empty muted',t().empty));return}
 const list=el('div','demo-ai-history-list');users.slice().reverse().forEach(message=>{const row=el('button','demo-ai-history-row');row.type='button';row.dataset.historyMessage=message.id;append(row,append(el('span','demo-ai-history-copy'),el('b','',message.text),el('small','',t().today)),el('span','settings-nav-arrow','›'));list.appendChild(row)});body.appendChild(list);
}
function renderChat(){
 ensureChatScreen();const p=plan();if(p==='free'){closeChat();openCompare();return}
 $('.demo-ai-chat-title')?.replaceChildren(document.createTextNode(t().chatTitle));$('.demo-ai-chat-sub')?.replaceChildren(document.createTextNode(t().chatSub));$('.demo-ai-chat-plan')?.replaceChildren(document.createTextNode(p==='pro'?'Pro':'Plus'));
 makeTabs();const input=$('demo-ai-input');if(input){input.placeholder=t().placeholder;if(document.activeElement!==input)input.value=getChat().draft}
 if($('demo-ai-fill-btn'))$('demo-ai-fill-btn').textContent=t().fill;if($('demo-ai-send'))$('demo-ai-send').textContent=t().send;
 $('demo-ai-composer').hidden=chatTab!=='dialog';if(chatTab==='history')renderHistory();else renderDialog();
}
function openChat(options={}){
 if(plan()==='free'){openCompare();return}
 ensureChatScreen();chatOrigin=options.origin||currentVisibleScreen();hideAllScreens();const screen=$('courses-ai-chat');screen.hidden=false;screen.classList.add('is-active');screen.setAttribute('aria-hidden','false');chatOpen=true;chatTab='dialog';renderChat();window.scrollTo({top:0,behavior:'auto'});
 if(options.contextQuestionId)setTimeout(()=>addContextReview(options.contextQuestionId),0);
}
function closeChat(){if(!chatOpen)return;const screen=$('courses-ai-chat');if(screen){screen.hidden=true;screen.classList.remove('is-active');screen.setAttribute('aria-hidden','true')}chatOpen=false;showExistingScreen(chatOrigin==='courses-ai-chat'?'courses-subject-hub':chatOrigin);window.scrollTo({top:0,behavior:'auto'})}

function recordTechnical(mode,cardIds,latency=0){
 const existing=read(sessionStorage,TECH_KEY,{});const value={...existing,ai:{mode,model_call:false,source_ids:cardIds,source_version:'economics-v1.0',latency_ms:latency,quota_charged:false,cache_hit:false,safe_renderer:'DOM textContent',knowledge_cards:CARDS.length}};write(sessionStorage,TECH_KEY,value);saveChat({lastMode:mode,lastSourceIds:cardIds});
}
function findCard(question){const key=`${lang()}:${normalize(question)}`;return aliasIndex.get(key)||null}
function addMessages(messages){const chat=getChat();chat.messages.push(...messages);saveChat({messages:chat.messages,draft:''});renderChat()}
function sendQuestion(text){
 const clean=String(text||'').trim();if(!clean)return;const started=performance.now();const card=findCard(clean);const user={id:uid('u'),role:'user',text:clean,lang:lang(),createdAt:now()};
 if(card){const assistant={id:uid('a'),role:'assistant',type:'verified',cardId:card.id,variant:'full',createdAt:now()};addMessages([user,assistant]);recordTechnical('verified',[card.id],Math.round(performance.now()-started))}
 else{const assistant={id:uid('a'),role:'assistant',type:'no_source',createdAt:now()};addMessages([user,assistant]);recordTechnical('no_source',[],Math.round(performance.now()-started))}
 const input=$('demo-ai-input');if(input)input.value='';saveChat({draft:''});
}
function addAction(cardId,variant){const card=CARDS.find(item=>item.id===cardId);if(!card)return;const assistant={id:uid('a'),role:'assistant',type:'verified',cardId,variant,createdAt:now()};addMessages([assistant]);recordTechnical('verified',[cardId],0)}
function addContextReview(questionId){
 const attempt=latestAttempt();const q=DATA.questions.find(item=>item.id===questionId);const answer=attempt?.answers?.find(item=>item.questionId===questionId);if(!q||!answer)return;
 const skill=questionSkill[questionId];const card=skillMap.get(skill)||CARDS.find(item=>item.skillId===skill);if(!card)return;
 const questionText=lang()==='ru'?`Разберите мой ответ на вопрос ${q.order}.`:lang()==='uz'?`${q.order}-savoldagi javobimni tahlil qiling.`:`Review my answer to question ${q.order}.`;
 const chat=getChat();const last=chat.messages[chat.messages.length-1];if(last?.context?.questionId===questionId)return;
 const user={id:uid('u'),role:'user',text:questionText,lang:lang(),createdAt:now()};const assistant={id:uid('a'),role:'assistant',type:'verified',cardId:card.id,variant:'full',context:{questionId,selected:answer.selected,correct:!!answer.correct},createdAt:now()};addMessages([user,assistant]);recordTechnical('verified',[card.id],0);
}
function reviewAttempt(){const attempt=latestAttempt();if(!attempt){toast(t().noAttempt);return}const wrong=attempt.answers?.find(item=>!item.correct)||attempt.answers?.[0];if(!wrong){toast(t().noAttempt);return}openChat({origin:'courses-practice-result',contextQuestionId:wrong.questionId})}

function openPractice(){toast(t().practiceReady);closeChat();setTimeout(()=>document.querySelector('[data-hub-tab="practice"]')?.click(),0)}

function ensureCompare(){
 let root=$('demo-plan-compare');if(root)return root;
 root=el('div','demo-plan-compare');root.id='demo-plan-compare';root.setAttribute('aria-hidden','true');
 const backdrop=el('button','demo-plan-compare-backdrop');backdrop.type='button';backdrop.setAttribute('aria-label','Close');
 const sheet=el('section','demo-plan-compare-sheet');const handle=el('div','demo-plan-compare-handle');const head=el('div','demo-plan-compare-head');append(head,el('div','h2 demo-plan-compare-title',''),el('button','icon-btn demo-plan-compare-close','×'));
 const body=el('div','demo-plan-compare-body');body.id='demo-plan-compare-body';append(sheet,handle,head,body);append(root,backdrop,sheet);document.body.appendChild(root);return root;
}
function featureCard(name,features,buttonText,target){const card=el('div','demo-plan-feature-card');append(card,el('span','demo-plan-feature-name',name));const list=el('ul');features.forEach(text=>list.appendChild(el('li','',text)));card.appendChild(list);const btn=el('button',`btn ${target==='pro'?'primary':''}`,buttonText);btn.type='button';btn.dataset.choosePlan=target;card.appendChild(btn);return card}
function openCompare(){const root=ensureCompare();root.querySelector('.demo-plan-compare-title').textContent=t().compare;const body=$('demo-plan-compare-body');body.replaceChildren(featureCard(t().plus,[t().plus1,t().plus2,t().plus3],t().choosePlus,'plus'),featureCard(t().pro,[t().pro1,t().pro2,t().pro3],t().choosePro,'pro'));root.setAttribute('aria-hidden','false');document.body.classList.add('demo-sheet-open')}
function closeCompare(){const root=$('demo-plan-compare');if(root)root.setAttribute('aria-hidden','true');document.body.classList.remove('demo-sheet-open')}

function selectPlan(value){const btn=document.querySelector(`[data-plan="${value}"]`);if(btn)btn.click();closeCompare();setTimeout(()=>openChat({origin:'courses-subject-hub'}),60)}

function injectResultAction(){
 const card=$('demo-plan-result');if(!card)return;card.querySelector('.demo-result-ai-action')?.remove();if(!['plus','pro'].includes(plan())||$('courses-practice-result')?.hidden)return;
 const btn=el('button','btn demo-result-ai-action',t().attemptAI);btn.type='button';card.appendChild(btn);
}
function injectReviewActions(){
 const list=$('practice-review-list');if(!list)return;list.querySelectorAll('.demo-review-card').forEach((card,index)=>{if(card.querySelector('.demo-review-ai'))return;const q=DATA.questions[index];if(!q)return;const btn=el('button','btn demo-review-ai',t().reviewAI);btn.type='button';btn.dataset.reviewQuestion=q.id;card.appendChild(btn)})
}

function appendTechnical(){
 setTimeout(()=>{
  const panel=$('demo-technical-card');if(!panel||panel.querySelector('[data-gate5-tech]'))return;const chat=getChat();const tech=read(sessionStorage,TECH_KEY,{}).ai||{};
  const rows=[[t().technicalMode,tech.mode||chat.lastMode||'—'],[t().technicalModel,tech.model_call?'Yes':'No'],[t().technicalSource,(tech.source_ids||chat.lastSourceIds||[]).join(', ')||'—'],[t().technicalLatency,`${Number(tech.latency_ms||0)} ms`],[t().technicalQuota,t().notCharged],[t().technicalRenderer,tech.safe_renderer||'DOM textContent']];
  rows.forEach(([label,value])=>{const row=el('div','demo-technical-row');row.dataset.gate5Tech='1';append(row,el('span','',label),el('b','',value));panel.appendChild(row)})
 },40)
}

function updateAll(){if(renderLock)return;renderLock=true;renderHubCard();if(chatOpen)renderChat();setTimeout(()=>{injectResultAction();injectReviewActions();renderLock=false},20)}

document.addEventListener('input',event=>{if(event.target.id==='demo-ai-input')saveChat({draft:event.target.value})});
document.addEventListener('click',event=>{
 if(chatOpen&&event.target.closest('#topbar-back')){event.preventDefault();event.stopImmediatePropagation();closeChat();return}
},true);

document.addEventListener('click',event=>{
 if(event.target.closest('#demo-ai-hub-card')){plan()==='free'?openCompare():openChat({origin:'courses-subject-hub'});return}
 if(event.target.closest('#demo-ai-fill-btn')){const input=$('demo-ai-input');if(input){input.value=t().autofillQuestion;saveChat({draft:input.value});input.focus();toast(t().filled)}return}
 if(event.target.closest('#demo-ai-send')){sendQuestion($('demo-ai-input')?.value);return}
 const prompt=event.target.closest('[data-quick-prompt]')?.dataset.quickPrompt;if(prompt){const input=$('demo-ai-input');if(input){input.value=prompt;saveChat({draft:prompt});input.focus()}return}
 const tab=event.target.closest('[data-chat-tab]')?.dataset.chatTab;if(tab){if(tab==='progress'){const attempt=latestAttempt();if(attempt&&window.ICLUB_DEMO_GATE4?.openTrajectory){closeChat();setTimeout(()=>window.ICLUB_DEMO_GATE4.openTrajectory(),0)}else toast(t().proProgressEmpty)}else{chatTab=tab;renderChat()}return}
 const actionButton=event.target.closest('[data-ai-action]');if(actionButton){const action=actionButton.dataset.aiAction,cardId=actionButton.dataset.cardId;if(action==='practice')openPractice();else addAction(cardId,action);return}
 const check=event.target.closest('.demo-ai-show-check');if(check){addAction(check.dataset.cardId,'check_answer');return}
 const history=event.target.closest('[data-history-message]');if(history){chatTab='dialog';renderChat();return}
 if(event.target.closest('.demo-result-ai-action')){reviewAttempt();return}
 const review=event.target.closest('[data-review-question]');if(review){openChat({origin:'courses-practice-review',contextQuestionId:review.dataset.reviewQuestion});return}
 if(event.target.closest('.demo-plan-compare-backdrop,.demo-plan-compare-close')){closeCompare();return}
 const choose=event.target.closest('[data-choose-plan]')?.dataset.choosePlan;if(choose){selectPlan(choose);return}
 if(event.target.closest('[data-plan],[data-lang]'))setTimeout(updateAll,60);
 if(event.target.closest('[data-demo-menu-action="technical"]'))appendTechnical();
});

document.addEventListener('keydown',event=>{if(event.target.id==='demo-ai-input'&&event.key==='Enter'&&!event.shiftKey){event.preventDefault();sendQuestion(event.target.value)}});

ensureHubCard();ensureChatScreen();ensureCompare();renderHubCard();
const resultCard=$('demo-plan-result');if(resultCard)new MutationObserver(()=>setTimeout(injectResultAction,30)).observe(resultCard,{childList:true,subtree:true,attributes:true,attributeFilter:['class','hidden']});
const reviewList=$('practice-review-list');if(reviewList)new MutationObserver(()=>setTimeout(injectReviewActions,30)).observe(reviewList,{childList:true,subtree:true});
setTimeout(updateAll,120);
window.ICLUB_DEMO_GATE5={cards:CARDS.length,openChat,closeChat,findCard,getChat,sendQuestion,openCompare,getTechnical:()=>read(sessionStorage,TECH_KEY,{}).ai||null};
})();