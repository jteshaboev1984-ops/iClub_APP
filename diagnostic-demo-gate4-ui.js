(()=>{'use strict';
const E=window.ICLUB_DEMO_DIAGNOSTIC_ENGINE,G=window.ICLUB_DEMO_GATE4_DATA,D=window.ICLUB_DEMO_V12_DATA;
if(!E||!G||!D)return;

const P='iclub_demo_v12.';
const $=id=>document.getElementById(id);
const read=(key,fallback)=>{try{return JSON.parse(localStorage.getItem(key)||'')??fallback}catch{return fallback}};
const lang=()=>['ru','uz','en'].includes(document.documentElement.lang)?document.documentElement.lang:(read(P+'state',{}).lang||'ru');
const loc=value=>value?.[lang()]??value?.ru??value?.en??value?.uz??value??'';
const plan=()=>document.querySelector('[data-plan].is-active')?.dataset.plan||read(P+'state',{}).plan||'free';
const latest=()=>{const rows=read(P+'history',{diagnostics:[]}).diagnostics||[];return rows[rows.length-1]||null};
const el=(tag,cls,text)=>{const node=document.createElement(tag);if(cls)node.className=cls;if(text!==undefined&&text!==null)node.textContent=text;return node};
const append=(parent,...children)=>{children.filter(Boolean).forEach(child=>parent.appendChild(child));return parent};
const skillLabel=id=>loc(G.skills?.[id]?.label)||id;

const COPY={
 ru:{
  ready:'Персональный анализ готов',readySub:'iClub AI сопоставил текущие ответы с вашей учебной историей.',open:'Открыть траекторию',
  trajectory:'Персональная траектория',trajectorySub:'Один вывод, понятные причины и следующий шаг.',summary:'Итог',skills:'Навыки',plan:'План',
  reliability:'Надёжность',high:'Высокая',medium:'Средняя',insufficient:'Пока недостаточно',
  repeated:'Повторяется',improved:'Улучшилось',unchecked:'Не проверено',patterns:'ошибок',signals:'сигналов',skillsCount:'навыков',
  why:'Почему такой вывод',toPlan:'Перейти к плану',allClear:'В текущей диагностике прежняя ошибка не повторилась.',noPositive:'Нового положительного сигнала пока нет.',
  needsCheck:'Нужно проверить',positive:'Положительный сигнал',confirmed:'Подтверждено сейчас',notEnough:'Недостаточно данных',repeatedStatus:'Ошибка повторилась',
  actual:'Текущая диагностика',tour:'Закрытый Tour 4',practice:'Practice 4 после тура',correct:'верно',wrong:'ошибка',notTested:'не проверялось',notAnswered:'нет ответа',
  skillReason:'Почему такой статус',basis:'Основание',currentResult:'Текущий результат',historyResult:'История',close:'Закрыть',
  repeatedReason:'Та же путаница встречалась раньше и повторилась на новой формулировке.',positiveReason:'Ранее навык вызывал ошибку, а сейчас решён правильно на новой формулировке. Это положительный сигнал, но ещё не окончательное освоение.',
  currentReason:'Навык подтверждён несколькими ответами в текущей практике.',verifyReason:'Одного ответа недостаточно — нужен ещё один независимый вопрос.',historyReason:'В истории была ошибка, но новая практика этот навык ещё не проверила.',
  methodTitle:'Как сформирован вывод',methodSub:'Система сравнивает только те навыки, которые действительно проверялись в каждом блоке.',can:'Можно заключить',cannot:'Нельзя заключить',
  targetTitle:'Ваш следующий учебный шаг',targetSub:'Сначала — задания по повторяющимся ошибкам, затем проверка положительных сигналов.',showAll:'Показать весь набор',hideExtra:'Свернуть набор',
  whyThese:'Почему выбраны эти задания',verified:'Проверенный вопрос iClub',priority:'Приоритет',
  historyOnly:'История готова, но текущая диагностика ещё не завершена.',closeRepeated:'Путаница близких экономических понятий повторилась в новой диагностике.',oneRepeated:'Один прежний паттерн ошибки повторился. Остальные навыки оцениваются отдельно.',broadPositive:'Есть улучшение по нескольким навыкам, но часть ошибок Tour 4 ещё не перепроверена.',mixedPositive:'Есть положительный сигнал, но часть истории ещё требует проверки.',notStable:'Текущих данных пока недостаточно для устойчивого вывода.',
  coverage:p=>`Practice 4 получила 10/10, но перепроверила только ${p.errorOverlap} из 14 ошибочных ответов Tour 4. ${p.unverified} ошибок остались без новой проверки.`,
  repeatedClaim:s=>`Та же путаница повторилась в навыке «${s}».`,positiveClaim:s=>`Навык «${s}» решён правильно на новой формулировке.`,efficiencyClaim:'В текущей практике правильно различены аллокативная и производственная эффективность.',
  limitOverall:'Нельзя определять общий уровень Economics по одному туру.',limitMastery:'Один правильный ответ ещё не означает полного освоения.',limitHistory:n=>`Результат Practice 4 на 100% не закрывает ${n} исторических ошибок, которые она не проверяла.`,limitGuess:'Нельзя объявлять угадывание только по короткому времени ответа.',
  diagnoses:{firm_profit:'Полезность смешана с прибылью фирмы.',isoquant_production_confusion:'Кривая безразличия смешана с производственной моделью.',break_even_confusion:'P = MC смешано с условием безубыточности TR = TC.',allocative_efficiency_confusion:'Минимум AC смешан с P = MC.',finance_source_growth_method_confusion:'Источник финансирования смешан со способом роста.',merger_internal_growth_confusion:'Внутренний рост смешан со слиянием.'}
 },
 uz:{
  ready:'Shaxsiy tahlil tayyor',readySub:'iClub AI joriy javoblarni o‘quv tarixingiz bilan solishtirdi.',open:'O‘quv yo‘lini ochish',
  trajectory:'Shaxsiy o‘quv yo‘li',trajectorySub:'Bitta xulosa, tushunarli sabablar va keyingi qadam.',summary:'Xulosa',skills:'Ko‘nikmalar',plan:'Reja',
  reliability:'Ishonchlilik',high:'Yuqori',medium:'O‘rta',insufficient:'Hozircha yetarli emas',
  repeated:'Takrorlandi',improved:'Yaxshilandi',unchecked:'Tekshirilmagan',patterns:'xato',signals:'signal',skillsCount:'ko‘nikma',
  why:'Nega shunday xulosa',toPlan:'Rejaga o‘tish',allClear:'Joriy diagnostikada oldingi xato takrorlanmadi.',noPositive:'Hozircha yangi ijobiy signal yo‘q.',
  needsCheck:'Tekshirish kerak',positive:'Ijobiy signal',confirmed:'Hozir tasdiqlandi',notEnough:'Ma’lumot yetarli emas',repeatedStatus:'Xato takrorlandi',
  actual:'Joriy diagnostika',tour:'Yopilgan 4-tur',practice:'Turdan keyingi 4-mashq',correct:'to‘g‘ri',wrong:'xato',notTested:'tekshirilmagan',notAnswered:'javob yo‘q',
  skillReason:'Nega bu status berildi',basis:'Asos',currentResult:'Joriy natija',historyResult:'Tarix',close:'Yopish',
  repeatedReason:'Ayni chalkashlik oldin ham bo‘lgan va yangi savolda takrorlandi.',positiveReason:'Oldin xato bo‘lgan ko‘nikma yangi savolda to‘g‘ri bajarildi. Bu ijobiy signal, ammo yakuniy o‘zlashtirish emas.',
  currentReason:'Ko‘nikma joriy mashqdagi bir nechta javob bilan tasdiqlandi.',verifyReason:'Bitta javob yetarli emas — yana bir mustaqil savol kerak.',historyReason:'Tarixda xato bo‘lgan, ammo yangi mashq bu ko‘nikmani hali tekshirmadi.',
  methodTitle:'Xulosa qanday tuzildi',methodSub:'Tizim faqat har bir blokda haqiqatan tekshirilgan ko‘nikmalarni solishtiradi.',can:'Aytish mumkin',cannot:'Aytib bo‘lmaydi',
  targetTitle:'Keyingi o‘quv qadamingiz',targetSub:'Avval takroriy xatolar, keyin ijobiy signallarni tekshirish.',showAll:'Barcha to‘plamni ko‘rsatish',hideExtra:'To‘plamni yig‘ish',
  whyThese:'Nega aynan shu savollar',verified:'iClub tekshirgan savol',priority:'Ustuvorlik',
  historyOnly:'Tarix tayyor, ammo joriy diagnostika hali tugamagan.',closeRepeated:'Yaqin iqtisodiy tushunchalarni chalkashtirish yangi diagnostikada takrorlandi.',oneRepeated:'Bitta oldingi xato namunasi takrorlandi. Qolgan ko‘nikmalar alohida baholanadi.',broadPositive:'Bir nechta ko‘nikmada yaxshilanish bor, ammo 4-tur xatolarining bir qismi hali tekshirilmagan.',mixedPositive:'Ijobiy signal bor, lekin tarixning bir qismi hali tekshirilishi kerak.',notStable:'Barqaror xulosa uchun joriy ma’lumot yetarli emas.',
  coverage:p=>`4-mashq 10/10 bo‘ldi, ammo 4-turdagi 14 xatodan faqat ${p.errorOverlap} tasini qayta tekshirdi. ${p.unverified} xato yangi tekshiruvsiz qoldi.`,
  repeatedClaim:s=>`«${s}» ko‘nikmasida ayni chalkashlik takrorlandi.`,positiveClaim:s=>`«${s}» yangi savolda to‘g‘ri bajarildi.`,efficiencyClaim:'Joriy mashqda allokativ va ishlab chiqarish samaradorligi to‘g‘ri ajratildi.',
  limitOverall:'Bitta tur asosida Economics umumiy darajasini aniqlab bo‘lmaydi.',limitMastery:'Bitta to‘g‘ri javob to‘liq o‘zlashtirishni anglatmaydi.',limitHistory:n=>`4-mashqdagi 100% natija u tekshirmagan ${n} tarixiy xatoni yopmaydi.`,limitGuess:'Faqat qisqa vaqt asosida taxmin qilingan deb bo‘lmaydi.',
  diagnoses:{firm_profit:'Naflilik firma foydasi bilan aralashdi.',isoquant_production_confusion:'Befarqlik egri chizig‘i ishlab chiqarish modeli bilan aralashdi.',break_even_confusion:'P = MC TR = TC zararsizlik sharti bilan aralashdi.',allocative_efficiency_confusion:'Minimum AC P = MC bilan aralashdi.',finance_source_growth_method_confusion:'Moliya manbasi o‘sish usuli bilan aralashdi.',merger_internal_growth_confusion:'Ichki o‘sish qo‘shilish bilan aralashdi.'}
 },
 en:{
  ready:'Personal analysis is ready',readySub:'iClub AI compared the current answers with the learning history.',open:'Open learning path',
  trajectory:'Personal learning path',trajectorySub:'One conclusion, clear reasons, and the next step.',summary:'Summary',skills:'Skills',plan:'Plan',
  reliability:'Reliability',high:'High',medium:'Medium',insufficient:'Not enough yet',
  repeated:'Repeated',improved:'Improved',unchecked:'Not checked',patterns:'errors',signals:'signals',skillsCount:'skills',
  why:'Why this conclusion',toPlan:'Go to plan',allClear:'No previous error repeated in the current diagnosis.',noPositive:'There is no new positive signal yet.',
  needsCheck:'Needs checking',positive:'Positive signal',confirmed:'Confirmed now',notEnough:'Insufficient evidence',repeatedStatus:'Error repeated',
  actual:'Current diagnosis',tour:'Closed Tour 4',practice:'Practice 4 after the tour',correct:'correct',wrong:'wrong',notTested:'not tested',notAnswered:'no answer',
  skillReason:'Why this status',basis:'Basis',currentResult:'Current result',historyResult:'History',close:'Close',
  repeatedReason:'The same confusion appeared earlier and repeated on a new formulation.',positiveReason:'A previously weak skill was answered correctly on a new formulation. This is a positive signal, not final mastery.',
  currentReason:'The skill is confirmed by several answers in the current practice.',verifyReason:'One answer is not enough — another independent question is needed.',historyReason:'There was a historical error, but the new practice has not tested this skill yet.',
  methodTitle:'How the conclusion was formed',methodSub:'The system compares only skills that were actually tested in each block.',can:'Can conclude',cannot:'Cannot conclude',
  targetTitle:'Your next learning step',targetSub:'Repeated errors first, then verification of positive signals.',showAll:'Show the full set',hideExtra:'Collapse set',
  whyThese:'Why these questions',verified:'Verified iClub question',priority:'Priority',
  historyOnly:'The history is ready, but the current diagnosis is not complete.',closeRepeated:'Confusion between neighbouring economic concepts repeated in the new diagnosis.',oneRepeated:'One previous error pattern repeated. The remaining skills are evaluated separately.',broadPositive:'Several skills improved, but some Tour 4 errors are still unverified.',mixedPositive:'There is a positive signal, but part of the history still needs checking.',notStable:'Current evidence is not enough for a stable conclusion.',
  coverage:p=>`Practice 4 scored 10/10, but rechecked only ${p.errorOverlap} of 14 incorrect Tour 4 answers. ${p.unverified} errors remained without a new check.`,
  repeatedClaim:s=>`The same confusion repeated in “${s}”.`,positiveClaim:s=>`“${s}” was answered correctly on a new formulation.`,efficiencyClaim:'The current practice correctly separated allocative and productive efficiency.',
  limitOverall:'One tour cannot establish the learner’s overall Economics level.',limitMastery:'One correct answer does not establish full mastery.',limitHistory:n=>`A 100% Practice 4 result does not close ${n} historical errors it did not test.`,limitGuess:'A short response time alone does not prove guessing.',
  diagnoses:{firm_profit:'Utility was confused with firm profit.',isoquant_production_confusion:'An indifference curve was confused with a production model.',break_even_confusion:'P = MC was confused with the TR = TC break-even condition.',allocative_efficiency_confusion:'Minimum AC was confused with P = MC.',finance_source_growth_method_confusion:'The finance source was confused with the growth method.',merger_internal_growth_confusion:'Internal growth was confused with a merger.'}
 }
};

const t=()=>COPY[lang()]||COPY.ru;
const confidenceLabel=value=>value==='high'?t().high:value==='medium'?t().medium:t().insufficient;
const visibleResult=()=>{const node=$('courses-practice-result');return !!(node&&!node.hidden&&node.classList.contains('is-active'))};
const summaryText=out=>t()[out.briefConclusion==='historical_only'?'historyOnly':out.briefConclusion==='close_concepts_repeated'?'closeRepeated':out.briefConclusion==='one_pattern_repeated'?'oneRepeated':out.briefConclusion==='broad_positive_signal'?'broadPositive':out.briefConclusion==='mixed_positive_signal'?'mixedPositive':'notStable'];

let trajectoryOpen=false;
let activeTab='summary';
let showAllTargeted=false;
let currentOutput=null;

function compute(){const attempt=latest();if(!attempt)return null;currentOutput=E.compute({currentAttempt:attempt,lang:lang()});return currentOutput}

function ensureTrajectoryScreen(){
 let screen=$('courses-pro-trajectory');
 if(screen)return screen;
 screen=el('section','stack-screen demo-trajectory-screen');
 screen.id='courses-pro-trajectory';
 screen.hidden=true;
 screen.setAttribute('aria-hidden','true');
 $('courses-stack')?.appendChild(screen);
 return screen;
}

function ensureSheet(){
 let root=$('demo-insight-sheet-root');
 if(root)return root;
 root=el('div','demo-insight-sheet-root');
 root.id='demo-insight-sheet-root';
 root.setAttribute('aria-hidden','true');
 root.innerHTML='<button class="demo-insight-sheet-backdrop" type="button" aria-label="Close"></button><section class="demo-insight-sheet" role="dialog" aria-modal="true"><div class="demo-insight-sheet-handle"></div><div class="demo-insight-sheet-head"><div><div class="demo-insight-sheet-title" id="demo-insight-sheet-title"></div><div class="demo-insight-sheet-sub muted small" id="demo-insight-sheet-sub"></div></div><button class="icon-btn demo-insight-sheet-close" type="button" aria-label="Close">×</button></div><div class="demo-insight-sheet-body" id="demo-insight-sheet-body"></div></section>';
 document.body.appendChild(root);
 return root;
}

function openSheet(title,sub,content){
 const root=ensureSheet();
 $('demo-insight-sheet-title').textContent=title;
 $('demo-insight-sheet-sub').textContent=sub||'';
 const body=$('demo-insight-sheet-body');
 body.replaceChildren(content);
 root.setAttribute('aria-hidden','false');
 document.body.classList.add('demo-sheet-open');
}
function closeSheet(){const root=$('demo-insight-sheet-root');if(root)root.setAttribute('aria-hidden','true');document.body.classList.remove('demo-sheet-open')}

function statusMeta(state){
 if(state.repeatedError&&state.currentWrongCount)return{label:t().repeatedStatus,cls:'is-error'};
 if(state.positiveSignal&&state.currentRightCount)return{label:t().positive,cls:'is-positive'};
 if(state.status==='current_session')return{label:t().confirmed,cls:'is-confirmed'};
 if(state.status==='needs_verification')return{label:t().needsCheck,cls:'is-check'};
 return{label:t().notEnough,cls:'is-muted'};
}

function primaryDiagnosis(state){
 const wrong=state.current?.find(item=>!item.correct);
 return t().diagnoses[wrong?.diagnosisId]||t().diagnoses[state.history?.find(item=>!item.correct)?.diagnosisId]||skillLabel(state.skillId);
}

function claimText(claim){
 if(claim.id==='coverage_mismatch')return t().coverage(claim.params);
 if(claim.id==='repeated_error')return t().repeatedClaim(skillLabel(claim.skillId));
 if(claim.id==='positive_signal')return t().positiveClaim(skillLabel(claim.skillId));
 if(claim.id==='efficiency_pair_current_session')return t().efficiencyClaim;
 return '';
}
function limitText(item){
 if(item.id==='not_overall_level')return t().limitOverall;
 if(item.id==='not_mastered_from_one_correct')return t().limitMastery;
 if(item.id==='practice4_did_not_close_history')return t().limitHistory(item.count);
 if(item.id==='no_guessing_claim_from_time')return t().limitGuess;
 return '';
}

function compactMetric(label,value,cls){const node=el('div',`demo-compact-metric ${cls||''}`);append(node,el('b','',String(value)),el('span','',label));return node}

function renderCompact(){
 if(!visibleResult()||plan()!=='pro')return;
 const out=compute();
 const card=$('demo-plan-result');
 if(!out||!card)return;
 card.hidden=false;
 card.className='card demo-plan-result demo-engine-card demo-engine-compact is-pro';
 card.dataset.gate4View='compact';
 card.replaceChildren();

 const head=el('div','demo-compact-head');
 const mark=el('span','demo-compact-mark');mark.innerHTML='<img src="iclub-ai-mark.svg" alt="">';
 const copy=el('div','demo-compact-copy');append(copy,el('div','card-title',t().ready),el('div','muted small',t().readySub));
 append(head,mark,copy,el('span','demo-plan-result-badge','Pro'));
 const summary=el('div','demo-compact-summary',summaryText(out));
 const metrics=el('div','demo-compact-metrics');
 append(metrics,
  compactMetric(t().repeated,out.repeatedErrors.length,'is-error'),
  compactMetric(t().improved,out.positiveSignals.length,'is-positive'),
  compactMetric(t().unchecked,out.historicalSummary.unverifiedTour4Errors.length,'is-muted')
 );
 const footer=el('div','demo-compact-footer');
 const reliability=el('div','demo-compact-reliability');append(reliability,el('span','',t().reliability),el('b',`is-${out.confidence}`,confidenceLabel(out.confidence)));
 const button=el('button','btn primary demo-open-trajectory',t().open);button.type='button';
 append(footer,reliability,button);
 append(card,head,summary,metrics,footer);
}

function renderRepeatedCard(out){
 const state=out.skills.find(item=>item.repeatedError&&item.currentWrongCount);
 const card=el('button','demo-insight-card is-error');card.type='button';
 if(state){card.dataset.skillId=state.skillId;append(card,el('span','demo-insight-label',t().repeated),el('b','',skillLabel(state.skillId)),el('small','',primaryDiagnosis(state)),el('span','demo-insight-arrow','›'))}
 else{card.disabled=true;append(card,el('span','demo-insight-label',t().repeated),el('b','',t().allClear))}
 return card;
}
function renderImprovedCard(out){
 const state=out.skills.find(item=>item.positiveSignal&&item.currentRightCount);
 const card=el('button','demo-insight-card is-positive');card.type='button';
 if(state){card.dataset.skillId=state.skillId;append(card,el('span','demo-insight-label',t().improved),el('b','',skillLabel(state.skillId)),el('small','',t().positiveReason),el('span','demo-insight-arrow','›'))}
 else{card.disabled=true;append(card,el('span','demo-insight-label',t().improved),el('b','',t().noPositive))}
 return card;
}

function renderSummaryPanel(out){
 const wrap=el('div','demo-trajectory-panel');
 const hero=el('div','demo-trajectory-hero');
 const top=el('div','demo-trajectory-hero-top');
 const mark=el('span','demo-trajectory-mark');mark.innerHTML='<img src="iclub-ai-mark.svg" alt="">';
 const heroCopy=el('div','demo-trajectory-hero-copy');append(heroCopy,el('span','',`iClub AI · Pro`),el('strong','',summaryText(out)));
 const conf=el('div','demo-trajectory-confidence');append(conf,el('span','',t().reliability),el('b',`is-${out.confidence}`,confidenceLabel(out.confidence)));
 append(top,mark,heroCopy);append(hero,top,conf);

 const cards=el('div','demo-insight-grid');append(cards,renderRepeatedCard(out),renderImprovedCard(out));
 const unchecked=el('button','demo-unchecked-row');unchecked.type='button';unchecked.dataset.openMethod='1';
 append(unchecked,append(el('span','demo-unchecked-copy'),el('b','',t().unchecked),el('small','',`${out.historicalSummary.unverifiedTour4Errors.length} ${t().skillsCount}`)),el('span','demo-insight-arrow','›'));
 const actions=el('div','demo-trajectory-actions');
 const why=el('button','btn demo-why-button',t().why);why.type='button';why.dataset.openMethod='1';
 const next=el('button','btn primary demo-go-plan',t().toPlan);next.type='button';
 append(actions,why,next);
 append(wrap,hero,cards,unchecked,actions);
 return wrap;
}

function renderSkillsPanel(out){
 const wrap=el('div','demo-trajectory-panel');
 const intro=el('div','demo-panel-intro');append(intro,el('div','h2',t().skills),el('div','muted small',t().trajectorySub));
 const list=el('div','demo-skill-list');
 const currentIds=new Set(Object.values(G.currentMap));
 out.skills.filter(item=>currentIds.has(item.skillId)).forEach(state=>{
  const meta=statusMeta(state);
  const row=el('button','demo-skill-row');row.type='button';row.dataset.skillId=state.skillId;
  const copy=el('span','demo-skill-row-copy');append(copy,el('b','',skillLabel(state.skillId)),el('small','',state.currentRightCount?`${t().actual}: ${t().correct}`:state.currentWrongCount?`${t().actual}: ${t().wrong}`:t().notAnswered));
  append(row,copy,el('span',`demo-skill-chip ${meta.cls}`,meta.label),el('span','demo-skill-chevron','›'));
  list.appendChild(row);
 });
 append(wrap,intro,list);
 return wrap;
}

function renderPlanPanel(out){
 const wrap=el('div','demo-trajectory-panel');
 const intro=el('div','demo-panel-intro');append(intro,el('div','h2',t().targetTitle),el('div','muted small',t().targetSub));
 const list=el('div','demo-plan-list');
 const rows=showAllTargeted?out.targetedSet:out.targetedSet.slice(0,3);
 rows.forEach((question,index)=>{
  const row=el('div','demo-plan-row');
  const no=el('span','demo-plan-no',String(index+1));
  const copy=el('div','demo-plan-copy');append(copy,el('b','',loc(question.title)),el('span','',`${skillLabel(question.skillId)} · ${question.difficulty}`));
  const badge=el('span','demo-plan-verified',t().verified);
  append(row,no,copy,badge);list.appendChild(row);
 });
 const actions=el('div','demo-plan-actions');
 if(out.targetedSet.length>3){const more=el('button','btn demo-toggle-targeted',showAllTargeted?t().hideExtra:t().showAll);more.type='button';actions.appendChild(more)}
 const why=el('button','btn demo-plan-why',t().whyThese);why.type='button';why.dataset.openMethod='1';actions.appendChild(why);
 append(wrap,intro,list,actions);
 return wrap;
}

function renderTrajectory(){
 const out=compute();
 const screen=ensureTrajectoryScreen();
 if(!out)return;
 screen.replaceChildren();
 const head=el('div','section demo-trajectory-heading');append(head,el('div','h1',t().trajectory),el('div','muted',t().trajectorySub));
 const tabs=el('div','demo-trajectory-tabs');
 [['summary',t().summary],['skills',t().skills],['plan',t().plan]].forEach(([id,label])=>{const btn=el('button',`demo-trajectory-tab ${activeTab===id?'is-active':''}`,label);btn.type='button';btn.dataset.trajectoryTab=id;tabs.appendChild(btn)});
 const body=activeTab==='skills'?renderSkillsPanel(out):activeTab==='plan'?renderPlanPanel(out):renderSummaryPanel(out);
 append(screen,head,tabs,body);
}

function openTrajectory(){
 if(plan()!=='pro')return;
 const screen=ensureTrajectoryScreen();
 document.querySelectorAll('#courses-stack > .stack-screen').forEach(node=>{node.classList.remove('is-active');node.hidden=true;node.setAttribute('aria-hidden','true')});
 screen.hidden=false;screen.classList.add('is-active');screen.setAttribute('aria-hidden','false');
 trajectoryOpen=true;activeTab='summary';showAllTargeted=false;renderTrajectory();window.scrollTo({top:0,behavior:'auto'});
}
function closeTrajectory(){
 if(!trajectoryOpen)return;
 const screen=ensureTrajectoryScreen();screen.hidden=true;screen.classList.remove('is-active');screen.setAttribute('aria-hidden','true');
 const result=$('courses-practice-result');if(result){result.hidden=false;result.classList.add('is-active');result.setAttribute('aria-hidden','false')}
 trajectoryOpen=false;closeSheet();window.scrollTo({top:0,behavior:'auto'});setTimeout(renderCompact,0);
}

function attemptLabel(id){if(id==='tour4')return t().tour;if(id==='practice4')return t().practice;return t().actual}
function resultWord(correct){return correct?t().correct:t().wrong}

function openSkillSheet(skillId){
 const out=currentOutput||compute();
 const state=out?.skills.find(item=>item.skillId===skillId);if(!state)return;
 const meta=statusMeta(state);
 const body=el('div','demo-sheet-stack');
 const status=el('div','demo-sheet-status');append(status,el('span','',t().skillReason),el('b',meta.cls,meta.label));
 let reason=t().verifyReason;
 if(state.repeatedError&&state.currentWrongCount)reason=t().repeatedReason;
 else if(state.positiveSignal&&state.currentRightCount)reason=t().positiveReason;
 else if(state.status==='current_session')reason=t().currentReason;
 else if(state.reason==='historical_error_not_rechecked')reason=t().historyReason;
 const reasonCard=el('div','demo-sheet-reason');append(reasonCard,el('b','',t().basis),el('p','',reason));
 const rows=el('div','demo-sheet-history');
 const grouped=new Map();[...(state.history||[]),...(state.current||[])].forEach(item=>{const key=item.attemptId||'current';if(!grouped.has(key))grouped.set(key,[]);grouped.get(key).push(item)});
 grouped.forEach((items,id)=>{
  const row=el('div','demo-sheet-history-row');const correct=items.filter(item=>item.correct).length;const wrong=items.filter(item=>!item.correct).length;
  append(row,append(el('div',''),el('b','',attemptLabel(id)),el('span','',`${items.length} ${t().skillsCount}`)),el('strong',wrong?'is-wrong':'is-correct',wrong?`${wrong} ${t().wrong}`:`${correct} ${t().correct}`));rows.appendChild(row)
 });
 append(body,status,reasonCard,rows);
 openSheet(skillLabel(skillId),primaryDiagnosis(state),body);
}

function openMethodSheet(){
 const out=currentOutput||compute();if(!out)return;
 const body=el('div','demo-sheet-stack');
 const score=el('div','demo-method-scores');
 [['6/20',t().tour],['10/10',t().practice],[`${out.currentAttemptSummary.score}/${out.currentAttemptSummary.total}`,t().actual]].forEach(([value,label])=>{const card=el('div','demo-method-score');append(card,el('b','',value),el('span','',label));score.appendChild(card)});
 const can=el('div','demo-method-box is-can');append(can,el('b','',t().can));const canList=el('ul');out.whatCanBeConcluded.slice(0,4).forEach(item=>{const text=claimText(item);if(text)canList.appendChild(el('li','',text))});can.appendChild(canList);
 const cannot=el('div','demo-method-box is-cannot');append(cannot,el('b','',t().cannot));const cannotList=el('ul');out.whatCannotBeConcluded.slice(0,4).forEach(item=>{const text=limitText(item);if(text)cannotList.appendChild(el('li','',text))});cannot.appendChild(cannotList);
 append(body,score,can,cannot);
 openSheet(t().methodTitle,t().methodSub,body);
}

function appendTechnical(){
 setTimeout(()=>{
  const box=$('demo-technical-card'),out=currentOutput||compute();
  if(!box||!out||box.querySelector('[data-gate4-tech]'))return;
  const rows=[['Diagnostic Engine',out.engineVersion],['Model call','No'],[t().reliability,out.confidence],['Rule IDs',out.claimEvidence.map(item=>item.claimId).join(', ')||'—'],['Targeted IDs',out.targetedQuestionIds.join(', ')||'—']];
  rows.forEach(([label,value])=>{const row=el('div','demo-technical-row');row.dataset.gate4Tech='1';append(row,el('span','',label),el('b','',value));box.appendChild(row)})
 },40)
}

function handlePlanOrLanguageChange(){
 setTimeout(()=>{
  closeSheet();
  if(trajectoryOpen){
   if(plan()!=='pro')closeTrajectory();
   else{document.querySelectorAll('#courses-stack > .stack-screen').forEach(node=>{node.classList.remove('is-active');node.hidden=true;node.setAttribute('aria-hidden','true')});const screen=ensureTrajectoryScreen();screen.hidden=false;screen.classList.add('is-active');screen.setAttribute('aria-hidden','false');renderTrajectory()}
  }else renderCompact();
 },60)
}

document.addEventListener('click',event=>{
 if(trajectoryOpen&&event.target.closest('#topbar-back')){event.preventDefault();event.stopImmediatePropagation();closeTrajectory();return}
 if(event.target.closest('.demo-insight-sheet-backdrop,.demo-insight-sheet-close')){event.preventDefault();closeSheet();return}
},true);

document.addEventListener('click',event=>{
 if(event.target.closest('.demo-open-trajectory')){openTrajectory();return}
 const tab=event.target.closest('[data-trajectory-tab]')?.dataset.trajectoryTab;if(tab){activeTab=tab;renderTrajectory();window.scrollTo({top:0,behavior:'auto'});return}
 if(event.target.closest('.demo-go-plan')){activeTab='plan';renderTrajectory();window.scrollTo({top:0,behavior:'auto'});return}
 const skillId=event.target.closest('[data-skill-id]')?.dataset.skillId;if(skillId){openSkillSheet(skillId);return}
 if(event.target.closest('[data-open-method]')){openMethodSheet();return}
 if(event.target.closest('.demo-toggle-targeted')){showAllTargeted=!showAllTargeted;renderTrajectory();return}
 if(event.target.closest('[data-plan],[data-lang]'))handlePlanOrLanguageChange();
 if(event.target.closest('[data-demo-menu-action="technical"]'))appendTechnical();
});

const result=$('courses-practice-result');
if(result)new MutationObserver(()=>setTimeout(renderCompact,50)).observe(result,{attributes:true,attributeFilter:['hidden','class']});
const card=$('demo-plan-result');
if(card)new MutationObserver(()=>{if(plan()==='pro'&&visibleResult()&&card.dataset.gate4View!=='compact')setTimeout(renderCompact,35)}).observe(card,{childList:true,attributes:true,attributeFilter:['class','hidden','data-gate4-view']});

setTimeout(renderCompact,100);
window.ICLUB_DEMO_GATE4={render:renderCompact,openTrajectory,closeTrajectory,getOutput:()=>currentOutput||compute()};
})();