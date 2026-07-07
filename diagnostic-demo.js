// Hidden President Tech Award diagnostic practice preview.
// Safe by design:
// - uses safe question delivery;
// - uses read-only diagnostic evaluator;
// - does not write to attempts, answers, scores, ratings or certificates;
// - is not linked from the live app UI.

const SUPABASE_URL = 'https://mmmduffgpvwjdpruzikw.supabase.co';
const SUPABASE_PUBLISHABLE_KEY = 'sb_publishable_OUJFpELgfrrmIIw2lF8_Sw_xEFH1M46';
const PILOT_QUESTION_IDS = [1081, 1071, 1115, 1135, 2548, 1018, 1022];

const client = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

const COPY = {
  en: {
    practice: 'Practice', startSubtitle: '7 questions • from easy to hard', tourPicker: 'Tour selection', tour: 'Tour', subjectLabel: 'Subject', subjectTitle: 'Economics',
    stageMeta: (done, total) => `Tour 6 practice • Completed ${done}/${total} • Remaining ${Math.max(0, total - done)}`,
    bestResult: 'Best result', bestTime: 'Best time', lastAttempts: 'Last attempts', noAttempts: 'No attempts yet', date: 'Date', score: 'Score', time: 'Time', start: 'Start practice', pause: 'Pause',
    difficulty: 'Difficulty', difficulty_easy: 'easy', difficulty_medium: 'medium', difficulty_hard: 'hard', inputLabel: 'Answer', inputPlaceholder: 'Type your answer', answer: 'Answer', checking: 'Checking…', loadError: 'Could not load practice.', loading: 'Loading practice questions…',
    resultTitle: 'Practice result', resultMeta: 'Basic result first. AI diagnosis is opened separately.', scoreCaption: (score, total) => `${score} of ${total} correct`, correctShort: 'Correct', errors: 'Errors', topics: 'Topics',
    reviewErrors: 'Review mistakes', reviewErrorsSub: 'Answers, correct logic and explanations', getAi: 'Get AI diagnosis', aiEntryTitle: 'Get a personal plan', aiEntrySub: 'Main focus, mistake reason and next step', toPractice: 'To practice',
    reviewSubtitle: 'Tap a question to open its detailed review', reviewSummary: 'Review summary', result: 'Result', questions: 'Questions', mistakes: 'Mistakes',
    aiThinkingTitle: 'AI diagnosis', aiThinkingSubtitle: 'Analysing your practice result', aiThinkingStatus: 'Diagnosing the result…', aiStep1: 'Checking repeated mistakes', aiStep2: 'Finding the main focus', aiStep3: 'Building the next step',
    aiReadyTitle: 'AI diagnosis is ready', aiReadySubtitle: 'Personal next step after practice', aiDiagnostic: 'AI diagnosis', aiFocus: 'Main focus', aiReason: 'Why this first', aiPlan: 'Next plan', startMini: 'Start mini-training', backToResult: 'Back to result',
    aiReasonText: (focus, errors) => `${focus} is the best first focus because ${errors} mistake(s) are connected to this result pattern.`,
    miniPlan: (focus) => [`Review the key idea in ${focus}.`, 'Open the mistake review and check the logic.', 'Try a short mini-training on this focus.'],
    yourAnswer: 'Your answer', feedback: 'Explanation', weakArea: 'Weak area', reinforcement: 'For reinforcement', nextAction: 'Next action', correct: 'Correct', needsRevision: 'Needs revision', times: 'times', backToReview: 'Back to review', questionReview: 'Question review', questionReviewSub: 'Mistake reason and next step', chooseOption: 'Choose one option first.', typeAnswer: 'Type your answer first.'
  },
  ru: {
    practice: 'Практика', startSubtitle: '7 вопросов • от простого к сложному', tourPicker: 'Выбор тура', tour: 'Тур', subjectLabel: 'Предмет', subjectTitle: 'Экономика',
    stageMeta: (done, total) => `Практика 6 тура • Завершено ${done}/${total} • Осталось ${Math.max(0, total - done)}`,
    bestResult: 'Лучший результат', bestTime: 'Лучшее время', lastAttempts: 'Последние попытки', noAttempts: 'Пока нет попыток', date: 'Дата', score: 'Счёт', time: 'Время', start: 'Начать практику', pause: 'Пауза',
    difficulty: 'Сложность', difficulty_easy: 'легко', difficulty_medium: 'средне', difficulty_hard: 'сложно', inputLabel: 'Ответ', inputPlaceholder: 'Введите ответ', answer: 'Ответить', checking: 'Проверяем…', loadError: 'Не удалось загрузить практику.', loading: 'Загружаем вопросы практики…',
    resultTitle: 'Результат практики', resultMeta: 'Сначала обычный итог. ИИ-диагностика открывается отдельно.', scoreCaption: (score, total) => `${score} из ${total} верно`, correctShort: 'Верно', errors: 'Ошибки', topics: 'Темы',
    reviewErrors: 'Разбор ошибок', reviewErrorsSub: 'Ответы, правильная логика и объяснения', getAi: 'Получить ИИ-диагностику', aiEntryTitle: 'Получить персональный план', aiEntrySub: 'Главный фокус, причина ошибок и следующий шаг', toPractice: 'К практике',
    reviewSubtitle: 'Нажми на вопрос, чтобы открыть подробный разбор', reviewSummary: 'Итог разбора', result: 'Результат', questions: 'Вопросов', mistakes: 'Ошибок',
    aiThinkingTitle: 'ИИ-диагностика', aiThinkingSubtitle: 'Анализируем результат практики', aiThinkingStatus: 'Идёт диагностика результата…', aiStep1: 'Проверяем повторяющиеся ошибки', aiStep2: 'Определяем главный фокус', aiStep3: 'Собираем следующий шаг',
    aiReadyTitle: 'ИИ-диагностика готова', aiReadySubtitle: 'Персональный следующий шаг после практики', aiDiagnostic: 'ИИ-диагностика', aiFocus: 'Главный фокус', aiReason: 'Почему начать с этого', aiPlan: 'Следующий план', startMini: 'Начать мини-тренировку', backToResult: 'Назад к результату',
    aiReasonText: (focus, errors) => `${focus} выбран первым, потому что ${errors} ошибк(и) связаны с этим направлением результата.`,
    miniPlan: (focus) => [`Повтори ключевую идею темы «${focus}».`, 'Открой разбор ошибок и проверь правильную логику.', 'Пройди короткую мини-тренировку по этому фокусу.'],
    yourAnswer: 'Твой ответ', feedback: 'Объяснение', weakArea: 'Слабое место', reinforcement: 'Для закрепления', nextAction: 'Следующий шаг', correct: 'Верно', needsRevision: 'Нужно повторить', times: 'раза', backToReview: 'Назад к разбору', questionReview: 'Разбор вопроса', questionReviewSub: 'Причина ошибки и следующий шаг', chooseOption: 'Сначала выбери один вариант ответа.', typeAnswer: 'Сначала введи ответ.'
  },
  uz: {
    practice: 'Mashq', startSubtitle: '7 savol • osondan qiyinga', tourPicker: 'Tur tanlash', tour: 'Tur', subjectLabel: 'Fan', subjectTitle: 'Iqtisodiyot',
    stageMeta: (done, total) => `6-tur mashqi • Tugallandi ${done}/${total} • Qoldi ${Math.max(0, total - done)}`,
    bestResult: 'Eng yaxshi natija', bestTime: 'Eng yaxshi vaqt', lastAttempts: 'Oxirgi urinishlar', noAttempts: 'Hozircha urinish yo‘q', date: 'Sana', score: 'Ball', time: 'Vaqt', start: 'Mashqni boshlash', pause: 'Pauza',
    difficulty: 'Qiyinlik', difficulty_easy: 'oson', difficulty_medium: 'o‘rtacha', difficulty_hard: 'qiyin', inputLabel: 'Javob', inputPlaceholder: 'Javobni kiriting', answer: 'Javob berish', checking: 'Tekshirilmoqda…', loadError: 'Mashq yuklanmadi.', loading: 'Mashq savollari yuklanmoqda…',
    resultTitle: 'Mashq natijasi', resultMeta: 'Avval oddiy natija. AI diagnostika alohida ochiladi.', scoreCaption: (score, total) => `${score} / ${total} to‘g‘ri`, correctShort: 'To‘g‘ri', errors: 'Xatolar', topics: 'Mavzular',
    reviewErrors: 'Xatolar tahlili', reviewErrorsSub: 'Javoblar, to‘g‘ri mantiq va izohlar', getAi: 'AI diagnostika olish', aiEntryTitle: 'Shaxsiy reja olish', aiEntrySub: 'Asosiy fokus, xato sababi va keyingi qadam', toPractice: 'Mashqqa',
    reviewSubtitle: 'Batafsil tahlilni ochish uchun savolni bosing', reviewSummary: 'Tahlil yakuni', result: 'Natija', questions: 'Savollar', mistakes: 'Xatolar',
    aiThinkingTitle: 'AI diagnostika', aiThinkingSubtitle: 'Mashq natijasi tahlil qilinmoqda', aiThinkingStatus: 'Natija diagnostika qilinmoqda…', aiStep1: 'Takroriy xatolar tekshirilmoqda', aiStep2: 'Asosiy fokus aniqlanmoqda', aiStep3: 'Keyingi qadam tuzilmoqda',
    aiReadyTitle: 'AI diagnostika tayyor', aiReadySubtitle: 'Mashqdan keyingi shaxsiy keyingi qadam', aiDiagnostic: 'AI diagnostika', aiFocus: 'Asosiy fokus', aiReason: 'Nega bundan boshlash kerak', aiPlan: 'Keyingi reja', startMini: 'Mini-mashqni boshlash', backToResult: 'Natijaga qaytish',
    aiReasonText: (focus, errors) => `${focus} birinchi fokus sifatida tanlandi, chunki ${errors} ta xato shu yo‘nalish bilan bog‘liq.`,
    miniPlan: (focus) => [`«${focus}» mavzusining asosiy g‘oyasini takrorlang.`, 'Xatolar tahlilini ochib, to‘g‘ri mantiqni tekshiring.', 'Shu fokus bo‘yicha qisqa mini-mashqni bajaring.'],
    yourAnswer: 'Sizning javobingiz', feedback: 'Izoh', weakArea: 'Zaif joy', reinforcement: 'Mustahkamlash uchun', nextAction: 'Keyingi qadam', correct: 'To‘g‘ri', needsRevision: 'Qayta ko‘rib chiqish kerak', times: 'marta', backToReview: 'Tahlilga qaytish', questionReview: 'Savol tahlili', questionReviewSub: 'Xato sababi va keyingi qadam', chooseOption: 'Avval bitta javob variantini tanlang.', typeAnswer: 'Avval javobni kiriting.'
  }
};

const LABELS = {
  topic: { Market:{en:'Market',ru:'Рынок',uz:'Bozor'}, Demand:{en:'Demand',ru:'Спрос',uz:'Talab'}, Basics:{en:'Economics basics',ru:'Основы экономики',uz:'Iqtisodiyot asoslari'}, PPC:{en:'PPC',ru:'Кривая производственных возможностей',uz:'Ishlab chiqarish imkoniyatlari egri chizig‘i'}, Elasticity:{en:'Elasticity',ru:'Эластичность',uz:'Elastiklik'}, 'Government macroeconomic intervention':{en:'Government macroeconomic policy',ru:'Макроэкономическая политика государства',uz:'Davlatning makroiqtisodiy siyosati'}, 'Allocative efficiency':{en:'Allocative efficiency',ru:'Аллокативная эффективность',uz:'Allokativ samaradorlik'}, 'Complementary goods':{en:'Complementary goods',ru:'Дополняющие товары',uz:'To‘ldiruvchi tovarlar'}, 'Consumer surplus':{en:'Consumer surplus',ru:'Потребительский излишек',uz:'Iste’molchi ortiqchaligi'}, 'Income from factors of production':{en:'Income from factors of production',ru:'Доходы факторов производства',uz:'Ishlab chiqarish omillari daromadi'}, 'Fiscal policy':{en:'Fiscal policy',ru:'Фискальная политика',uz:'Fiskal siyosat'}, 'Opportunity cost on the PPC':{en:'Opportunity cost on PPC',ru:'Альтернативная стоимость на PPC',uz:'PPC bo‘yicha muqobil qiymat'}, 'Calculating PED':{en:'Calculating PED',ru:'Расчёт PED',uz:'PED hisoblash'} },
  skill: { 'Allocative efficiency vs average-cost logic':{en:'Allocative efficiency vs average cost',ru:'Аллокативная эффективность и средние издержки',uz:'Allokativ samaradorlik va o‘rtacha xarajat'}, 'Area position on demand diagram':{en:'Area position on demand diagram',ru:'Область на графике спроса',uz:'Talab grafigidagi soha'}, 'Complement demand shift direction':{en:'Direction of demand shift for complements',ru:'Направление сдвига спроса у дополняющих товаров',uz:'To‘ldiruvchi tovarlarda talab siljishi yo‘nalishi'}, 'Consumer surplus vs producer/supply area':{en:'Consumer surplus vs producer area',ru:'Потребительский излишек и область производителя',uz:'Iste’molchi ortiqchaligi va ishlab chiqaruvchi sohasi'}, 'Consumer vs producer surplus':{en:'Consumer surplus vs producer surplus',ru:'Потребительский и производительский излишек',uz:'Iste’molchi va ishlab chiqaruvchi ortiqchaligi'}, 'Demand shift vs elasticity terminology':{en:'Demand shift vs elasticity term',ru:'Сдвиг спроса и термин эластичности',uz:'Talab siljishi va elastiklik termini'}, 'Efficiency vs profit outcome':{en:'Efficiency vs profit result',ru:'Эффективность и результат прибыли',uz:'Samaradorlik va foyda natijasi'}, 'Enterprise vs capital reward':{en:'Enterprise vs capital reward',ru:'Доход предпринимательства и капитала',uz:'Tadbirkorlik va kapital daromadi'}, 'Fiscal vs monetary policy':{en:'Fiscal policy vs monetary policy',ru:'Фискальная и монетарная политика',uz:'Fiskal va monetar siyosat'}, 'Labour vs capital reward':{en:'Labour vs capital reward',ru:'Доход труда и капитала',uz:'Mehnat va kapital daromadi'}, 'Land vs capital reward':{en:'Land vs capital reward',ru:'Доход земли и капитала',uz:'Yer va kapital daromadi'}, 'Macroeconomic policy categories':{en:'Macroeconomic policy categories',ru:'Категории макроэкономической политики',uz:'Makroiqtisodiy siyosat turlari'}, 'Market supply misconception':{en:'Misconception about market supply',ru:'Неверное понимание предложения',uz:'Taklif haqida noto‘g‘ri tushuncha'}, 'Opportunity cost calculation':{en:'Opportunity cost calculation',ru:'Расчёт альтернативной стоимости',uz:'Muqobil qiymatni hisoblash'}, 'PED calculation':{en:'PED calculation',ru:'Расчёт PED',uz:'PED hisoblash'}, 'Policy instrument recognition':{en:'Recognising policy instruments',ru:'Распознавание инструментов политики',uz:'Siyosat instrumentlarini tanish'}, 'Related goods effect':{en:'Effect of related goods',ru:'Влияние связанных товаров',uz:'Bog‘liq tovarlar ta’siri'} },
  mistake: { concept_confusion:{en:'Concept confusion',ru:'Путаница понятий',uz:'Tushuncha chalkashligi'}, diagram_area_direction:{en:'Diagram area error',ru:'Ошибка области на графике',uz:'Diagrammadagi soha xatosi'}, direction_error:{en:'Direction error',ru:'Ошибка направления',uz:'Yo‘nalish xatosi'}, diagram_area_confusion:{en:'Diagram area confusion',ru:'Путаница областей на графике',uz:'Diagramma sohalarini adashtirish'}, producer_surplus_confusion:{en:'Consumer/producer surplus confusion',ru:'Путаница потребительского и производительского излишка',uz:'Iste’molchi va ishlab chiqaruvchi ortiqchaligi chalkashligi'}, term_misuse:{en:'Term misuse',ru:'Неверное использование термина',uz:'Termin noto‘g‘ri ishlatilgan'}, overgeneralisation:{en:'Overgeneralisation',ru:'Слишком общее правило',uz:'Haddan tashqari umumlashtirish'}, factor_reward_confusion:{en:'Factor income confusion',ru:'Путаница доходов факторов',uz:'Omil daromadlari chalkashligi'}, policy_type_confusion:{en:'Policy type confusion',ru:'Путаница типов политики',uz:'Siyosat turlari chalkashligi'}, policy_scope_confusion:{en:'Policy scope confusion',ru:'Путаница области политики',uz:'Siyosat doirasi chalkashligi'}, irrelevant_condition:{en:'Irrelevant condition',ru:'Нерелевантное условие',uz:'Aloqasiz shart'}, calculation_error:{en:'Calculation error',ru:'Ошибка расчёта',uz:'Hisoblash xatosi'}, formula_or_percentage_error:{en:'Formula or percentage error',ru:'Ошибка формулы или процентов',uz:'Formula yoki foiz xatosi'}, missing_link:{en:'Missing link between ideas',ru:'Пропущена связь между идеями',uz:'G‘oyalar orasidagi bog‘lanish tushib qolgan'} }
};

const TERM_FIXES_RU = [['related goods demand shifts','сдвиги спроса из-за связанных товаров'],['demand shifters','факторы сдвига спроса'],['capital vs enterprise','капитал и предпринимательство'],['factors of production and rewards','факторы производства и их доходы'],['PED calculation','расчёт PED'],['PPC opportunity cost','альтернативную стоимость на PPC'],['demand/supply diagram','график спроса и предложения'],['government spending and taxation','государственные расходы и налоги'],['substitutes and complements','заменители и дополняющие товары']];

const state = { lang:'ru', screen:'start', allQuestions:[], questions:[], currentIndex:0, selectedOptionIndex:null, results:[], detailIndex:null, aiTimers:[] };
const $ = (id) => document.getElementById(id);
const els = {
  startScreen:$('practice-start-screen'), quizScreen:$('practice-quiz-screen'), resultScreen:$('practice-result-screen'), reviewScreen:$('practice-review-diagnosis-screen'), aiThinkingScreen:$('ai-thinking-screen'), aiResultScreen:$('ai-result-screen'), detailScreen:$('practice-question-detail-screen'),
  startTitle:$('start-title'), startSubtitle:$('start-subtitle'), tourPickerTitle:$('tour-picker-title'), tourActiveChip:$('tour-active-chip'), heroSubjectLabel:$('hero-subject-label'), heroSubjectTitle:$('hero-subject-title'), heroStageMeta:$('hero-stage-meta'), bestResultLabel:$('best-result-label'), bestTimeLabel:$('best-time-label'), lastAttemptsTitle:$('last-attempts-title'), lastAttemptsEmpty:$('last-attempts-empty'), colDate:$('col-date'), colScore:$('col-score'), colTime:$('col-time'), startDemo:$('start-demo'),
  qno:$('practice-qno'), timer:$('practice-timer'), pauseBtn:$('practice-pause-btn'), questionText:$('question-text'), questionDifficulty:$('question-difficulty'), optionsList:$('options-list'), inputWrap:$('input-wrap'), inputLabel:$('input-label'), inputAnswer:$('input-answer'), submitButton:$('submit-answer'),
  resultTitle:$('result-title'), resultMeta:$('practice-result-meta'), resultScoreMain:$('result-score-main'), resultScoreCaption:$('result-score-caption'), resultCorrectLabel:$('result-correct-label'), resultCorrectValue:$('result-correct-value'), resultErrorsLabel:$('result-errors-label'), resultErrorsValue:$('result-errors-value'), resultTopicsLabel:$('result-topics-label'), resultTopicsValue:$('result-topics-value'),
  openReview:$('open-review-diagnosis'), reviewDiagnosisTitle:$('review-diagnosis-title'), reviewDiagnosisSub:$('review-diagnosis-sub'), reviewDiagnosisCount:$('review-diagnosis-count'), openAi:$('open-ai-diagnosis'), aiEntryLabel:$('ai-entry-label'), aiProBadge:$('ai-pro-badge'), aiEntryTitle:$('ai-entry-title'), aiEntrySub:$('ai-entry-sub'), resultPrimaryAction:$('result-primary-action'), backToStart:$('back-to-start'),
  reviewTitle:$('review-title'), reviewSubtitle:$('review-subtitle'), reviewSummaryTitle:$('review-summary-title'), diagnosticScoreLabel:$('diagnostic-score-label'), diagnosticScore:$('diagnostic-score'), diagnosticErrorsLabel:$('diagnostic-errors-label'), diagnosticErrors:$('diagnostic-errors'), diagnosticTopicsLabel:$('diagnostic-topics-label'), diagnosticTopics:$('diagnostic-topics'), reviewQuestionList:$('review-question-list'), reviewBackToResult:$('review-back-to-result'), reviewToAi:$('review-to-ai'),
  aiThinkingTitle:$('ai-thinking-title'), aiThinkingSubtitle:$('ai-thinking-subtitle'), aiThinkingStatus:$('ai-thinking-status'), aiStep1:$('ai-step-1'), aiStep2:$('ai-step-2'), aiStep3:$('ai-step-3'), aiStep1Text:$('ai-step-1-text'), aiStep2Text:$('ai-step-2-text'), aiStep3Text:$('ai-step-3-text'),
  aiResultTitle:$('ai-result-title'), aiResultSubtitle:$('ai-result-subtitle'), aiResultPill:$('ai-result-pill'), aiFocusLabel:$('ai-focus-label'), aiFocusTitle:$('ai-focus-title'), aiReasonLabel:$('ai-reason-label'), aiReasonText:$('ai-reason-text'), aiPlanLabel:$('ai-plan-label'), aiPlanList:$('ai-plan-list'), startMiniTraining:$('start-mini-training'), aiBackToResult:$('ai-back-to-result'),
  detailTitle:$('detail-title'), detailSubtitle:$('detail-subtitle'), detailStatus:$('detail-status'), detailQuestionText:$('detail-question-text'), detailAnswerLabel:$('detail-answer-label'), detailAnswerValue:$('detail-answer-value'), detailFocusLabel:$('detail-focus-label'), detailFocusValue:$('detail-focus-value'), detailFeedbackLabel:$('detail-feedback-label'), detailFeedbackValue:$('detail-feedback-value'), detailNextLabel:$('detail-next-label'), detailNextValue:$('detail-next-value'), detailBackToReview:$('detail-back-to-review'), detailToAi:$('detail-to-ai'),
  languageButtons:document.querySelectorAll('.language-btn')
};

function copy(){ return COPY[state.lang] || COPY.ru; }
function localField(base){ return `${base}_${state.lang}`; }
function label(value, group='topic'){ return LABELS[group]?.[value]?.[state.lang] || LABELS[group]?.[value]?.ru || LABELS[group]?.[value]?.en || value || ''; }
function escapeHtml(v){ return String(v ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#039;'); }
function formatMMSS(s){ s=Math.max(0, Number(s)||0); return `${String(Math.floor(s/60)).padStart(2,'0')}:${String(s%60).padStart(2,'0')}`; }
function cleanText(text){ let out = String(text || ''); if(state.lang==='ru') TERM_FIXES_RU.forEach(([a,b]) => { out = out.replaceAll(a,b); }); return out; }
function getText(row, base){ return row?.[localField(base)] || row?.[`${base}_ru`] || row?.[`${base}_en`] || row?.[`${base}_uz`] || row?.[base] || ''; }
function getResultText(result, base){ return cleanText(result?.[localField(base)] || result?.[`${base}_ru`] || result?.[`${base}_en`] || result?.[`${base}_uz`] || ''); }
function parseOptions(raw){ if(!raw) return []; if(Array.isArray(raw)) return raw; try{ const p=JSON.parse(raw); return Array.isArray(p)?p:[]; }catch{ return String(raw).split('|').map(x=>x.trim()).filter(Boolean); } }
function countBy(items, getKey){ const m=new Map(); items.forEach(item=>{ const k=getKey(item); if(k) m.set(k,(m.get(k)||0)+1); }); return [...m.entries()].sort((a,b)=>b[1]-a[1]); }

function showScreen(name){
  state.screen=name;
  els.startScreen.classList.toggle('hidden', name!=='start');
  els.quizScreen.classList.toggle('hidden', name!=='quiz');
  els.resultScreen.classList.toggle('hidden', name!=='result');
  els.reviewScreen.classList.toggle('hidden', name!=='review');
  els.aiThinkingScreen.classList.toggle('hidden', name!=='aiThinking');
  els.aiResultScreen.classList.toggle('hidden', name!=='aiResult');
  els.detailScreen.classList.toggle('hidden', name!=='detail');
}

function updateStaticCopy(){
  const t=copy();
  document.documentElement.lang=state.lang;
  els.startTitle.textContent=t.practice; els.startSubtitle.textContent=t.startSubtitle; els.tourPickerTitle.textContent=t.tourPicker; els.tourActiveChip.textContent=`${t.tour} 6`;
  els.heroSubjectLabel.textContent=t.subjectLabel; els.heroSubjectTitle.textContent=t.subjectTitle; els.heroStageMeta.textContent=t.stageMeta(state.results.length, state.questions.length || PILOT_QUESTION_IDS.length);
  els.bestResultLabel.textContent=t.bestResult; els.bestTimeLabel.textContent=t.bestTime; els.lastAttemptsTitle.textContent=t.lastAttempts; els.lastAttemptsEmpty.textContent=t.noAttempts; els.colDate.textContent=t.date; els.colScore.textContent=t.score; els.colTime.textContent=t.time;
  els.startDemo.textContent=state.allQuestions.length?t.start:t.loading; els.pauseBtn.textContent=t.pause; els.inputLabel.textContent=t.inputLabel; els.inputAnswer.placeholder=t.inputPlaceholder; els.submitButton.textContent=t.answer;
  els.resultTitle.textContent=t.resultTitle; els.resultMeta.textContent=t.resultMeta; els.resultCorrectLabel.textContent=t.correctShort; els.resultErrorsLabel.textContent=t.errors; els.resultTopicsLabel.textContent=t.topics;
  els.reviewDiagnosisTitle.textContent=t.reviewErrors; els.reviewDiagnosisSub.textContent=t.reviewErrorsSub; els.aiEntryLabel.textContent=t.aiDiagnostic; els.aiProBadge.textContent='AI'; els.aiEntryTitle.textContent=t.aiEntryTitle; els.aiEntrySub.textContent=t.aiEntrySub; els.resultPrimaryAction.textContent=t.reviewErrors; els.backToStart.textContent=t.toPractice;
  els.reviewTitle.textContent=t.reviewErrors; els.reviewSubtitle.textContent=t.reviewSubtitle; els.reviewSummaryTitle.textContent=t.reviewSummary; els.diagnosticScoreLabel.textContent=t.result; els.diagnosticErrorsLabel.textContent=t.errors; els.diagnosticTopicsLabel.textContent=t.topics; els.reviewBackToResult.textContent=t.backToResult; els.reviewToAi.textContent=t.getAi;
  els.aiThinkingTitle.textContent=t.aiThinkingTitle; els.aiThinkingSubtitle.textContent=t.aiThinkingSubtitle; els.aiThinkingStatus.textContent=t.aiThinkingStatus; els.aiStep1Text.textContent=t.aiStep1; els.aiStep2Text.textContent=t.aiStep2; els.aiStep3Text.textContent=t.aiStep3;
  els.aiResultTitle.textContent=t.aiReadyTitle; els.aiResultSubtitle.textContent=t.aiReadySubtitle; els.aiResultPill.textContent=t.aiDiagnostic; els.aiFocusLabel.textContent=t.aiFocus; els.aiReasonLabel.textContent=t.aiReason; els.aiPlanLabel.textContent=t.aiPlan; els.startMiniTraining.textContent=t.startMini; els.aiBackToResult.textContent=t.backToResult;
  els.detailTitle.textContent=t.questionReview; els.detailSubtitle.textContent=t.questionReviewSub; els.detailAnswerLabel.textContent=t.yourAnswer; els.detailFeedbackLabel.textContent=t.feedback; els.detailNextLabel.textContent=t.nextAction; els.detailBackToReview.textContent=t.backToReview; els.detailToAi.textContent=t.getAi;
}

function setSubmitReady(ready){ els.submitButton.disabled=!ready; els.submitButton.classList.toggle('is-ready', !!ready); }
function hasCurrentAnswer(){ const q=state.questions[state.currentIndex]; if(!q) return false; return String(q.qtype||'').toLowerCase()==='input' ? !!String(els.inputAnswer.value||'').trim() : state.selectedOptionIndex!==null; }
function difficultyLabel(d){ return copy()[`difficulty_${String(d||'').toLowerCase()}`] || d || ''; }

async function loadQuestions(){
  updateStaticCopy(); els.startDemo.disabled=true; els.startDemo.textContent=copy().loading;
  const {data,error}=await client.rpc('get_safe_questions_by_ids',{p_question_ids:PILOT_QUESTION_IDS});
  if(error){ console.error(error); els.startDemo.textContent=copy().loadError; return; }
  state.allQuestions=[...(data||[])].sort((a,b)=> (a.request_order??PILOT_QUESTION_IDS.indexOf(Number(a.id))) - (b.request_order??PILOT_QUESTION_IDS.indexOf(Number(b.id))));
  state.questions=[...state.allQuestions];
  els.startDemo.disabled=!state.allQuestions.length;
  updateStaticCopy();
}

function renderQuestion(){
  const t=copy(); const q=state.questions[state.currentIndex];
  if(!q){ renderResult(); return; }
  state.selectedOptionIndex=null; els.inputAnswer.value='';
  els.qno.textContent=`${state.currentIndex+1}/${state.questions.length}`; els.timer.textContent=formatMMSS(Number(q.time_limit_sec||q.timeLimitSec||58));
  els.questionText.textContent=getText(q,'question_text'); els.questionDifficulty.textContent=`${t.difficulty}: ${difficultyLabel(q.difficulty)}`; els.submitButton.textContent=t.answer; setSubmitReady(false); els.optionsList.innerHTML='';
  if(String(q.qtype||'').toLowerCase()==='input'){ els.inputWrap.classList.remove('hidden'); return; }
  els.inputWrap.classList.add('hidden');
  parseOptions(getText(q,'options_text')).forEach((option,index)=>{ const row=document.createElement('label'); row.className='option-row'; row.innerHTML=`<input type="radio" name="diagnostic-option" value="${index}"><span>${String.fromCharCode(65+index)}. ${escapeHtml(option)}</span>`; row.querySelector('input')?.addEventListener('change',()=>{ state.selectedOptionIndex=index; els.optionsList.querySelectorAll('.option-row').forEach(n=>n.classList.remove('is-selected')); row.classList.add('is-selected'); setSubmitReady(true); }); els.optionsList.appendChild(row); });
}

function startDemo(questionSet=null){
  const source = Array.isArray(questionSet) && questionSet.length ? questionSet : state.allQuestions;
  if(!source.length) return;
  state.questions=[...source]; state.currentIndex=0; state.selectedOptionIndex=null; state.results=[]; state.detailIndex=null;
  showScreen('quiz'); renderQuestion(); updateStaticCopy();
}

async function submitAnswer(){
  const t=copy(); const q=state.questions[state.currentIndex]; if(!q) return;
  const isInput=String(q.qtype||'').toLowerCase()==='input'; const userAnswer=isInput?els.inputAnswer.value.trim():null;
  if(isInput&&!userAnswer){ alert(t.typeAnswer); return; } if(!isInput&&state.selectedOptionIndex===null){ alert(t.chooseOption); return; }
  els.submitButton.disabled=true; els.submitButton.textContent=t.checking;
  const selectedDisplay=isInput?userAnswer:String.fromCharCode(65+state.selectedOptionIndex);
  const {data,error}=await client.rpc('evaluate_diagnostic_demo_answer',{p_question_id:Number(q.id),p_user_answer:userAnswer,p_picked_index:isInput?null:state.selectedOptionIndex});
  if(error){ console.error(error); alert(t.loadError); setSubmitReady(hasCurrentAnswer()); return; }
  state.results.push({question:q,result:data||{},selectedDisplay}); state.currentIndex+=1; state.currentIndex>=state.questions.length ? renderResult() : renderQuestion();
}

function getStats(){
  const total=state.results.length; const correctCount=state.results.filter(x=>!!x.result.is_correct).length; const wrong=state.results.filter(x=>!x.result.is_correct);
  const weakAreas=countBy(wrong, x=>label(x.result.weak_skill,'skill') || label(x.result.recommended_topic,'topic'));
  const mistakeTypes=countBy(wrong, x=>label(x.result.mistake_type,'mistake'));
  const topicFocus=countBy(wrong, x=>label(x.question.topic,'topic'));
  const rawTopicFocus=countBy(wrong, x=>x.question.topic);
  const percent=total?Math.round((correctCount/total)*100):0;
  return {total,correctCount,wrong,weakAreas,mistakeTypes,topicFocus,rawTopicFocus,percent};
}

function renderResult(){
  const t=copy(); const s=getStats(); showScreen('result');
  els.resultScoreMain.textContent=`${s.percent}%`; els.resultScoreCaption.textContent=t.scoreCaption(s.correctCount, s.total);
  els.resultCorrectValue.textContent=`${s.correctCount}/${s.total}`; els.resultErrorsValue.textContent=String(s.wrong.length); els.resultTopicsValue.textContent=String(s.topicFocus.length); els.reviewDiagnosisCount.textContent=String(s.wrong.length);
}

function renderReview(){
  const t=copy(); const s=getStats(); showScreen('review');
  els.diagnosticScore.textContent=`${s.percent}%`; els.diagnosticErrors.textContent=String(s.wrong.length); els.diagnosticTopics.textContent=String(s.topicFocus.length);
  const byTopic=new Map(); state.results.forEach((item,idx)=>{ const topic=label(item.question.topic,'topic')||'General'; if(!byTopic.has(topic)) byTopic.set(topic,[]); byTopic.get(topic).push({...item,idx}); });
  const topics=[...byTopic.keys()].sort((a,b)=> byTopic.get(b).filter(x=>!x.result.is_correct).length - byTopic.get(a).filter(x=>!x.result.is_correct).length || a.localeCompare(b));
  els.reviewQuestionList.innerHTML='';
  topics.forEach((topic,i)=>{ const items=byTopic.get(topic); const wrongCount=items.filter(x=>!x.result.is_correct).length; const card=document.createElement('section'); card.className='card review-topic-card'; const head=document.createElement('button'); head.className='review-topic-head'; head.type='button'; head.innerHTML=`<div><div class="review-topic-title">${escapeHtml(topic)}</div><div class="review-topic-meta">${t.questions}: ${items.length} • ${t.mistakes}: ${wrongCount}</div></div><span class="badge badge-pin">${wrongCount?'❌ '+wrongCount:'✅ 0'}</span>`; const body=document.createElement('div'); body.className='review-topic-body'; body.style.display=i===0?'grid':'none'; head.addEventListener('click',()=>{ body.style.display=body.style.display==='none'?'grid':'none'; }); items.forEach(item=>{ const row=document.createElement('button'); row.className='review-row'; row.type='button'; row.innerHTML=`<div class="review-row-title">${item.result.is_correct?'✅':'❌'} ${item.idx+1}. ${escapeHtml(item.result.is_correct?t.correct:t.needsRevision)}</div><div class="review-row-text">${escapeHtml(getText(item.question,'question_text'))}</div><div class="review-row-foot">${escapeHtml(reviewFocusLabel(item))}: ${escapeHtml(itemFocus(item))}</div>`; row.addEventListener('click',()=>renderQuestionDetail(item.idx)); body.appendChild(row); }); card.appendChild(head); card.appendChild(body); els.reviewQuestionList.appendChild(card); });
}

function itemFeedback(item){ const id=Number(item.question.id); const answer=String(item.selectedDisplay||'').trim(); if(!item.result.is_correct && id===1022 && answer){ if(state.lang==='ru') return `Ты ввёл ${answer}. Для PED нужно разделить процентное изменение величины спроса на процентное изменение цены: 20 ÷ 10 = 2.`; if(state.lang==='uz') return `Siz ${answer} deb yozdingiz. PED uchun talab miqdoridagi foiz o‘zgarishi narxdagi foiz o‘zgarishiga bo‘linadi: 20 ÷ 10 = 2.`; return `You entered ${answer}. For PED, divide the percentage change in quantity demanded by the percentage change in price: 20 ÷ 10 = 2.`; } if(!item.result.is_correct && id===1018 && answer){ if(state.lang==='ru') return `Ты ввёл ${answer}. Для альтернативной стоимости уменьшение Y делится на увеличение X: 12 ÷ 4 = 3.`; if(state.lang==='uz') return `Siz ${answer} deb yozdingiz. Muqobil qiymat uchun Y kamayishi X oshishiga bo‘linadi: 12 ÷ 4 = 3.`; return `You entered ${answer}. For opportunity cost, divide the decrease in Y by the increase in X: 12 ÷ 4 = 3.`; } return getResultText(item.result,'feedback') || '—'; }
function itemNext(item){ return getResultText(item.result,'next_action') || '—'; }
function itemFocus(item){ return label(item.result.weak_skill,'skill') || label(item.result.recommended_topic,'topic') || '—'; }
function reviewFocusLabel(item){ return item.result.is_correct ? copy().reinforcement : copy().weakArea; }

function renderQuestionDetail(idx){
  const item=state.results[idx]; if(!item) return; const t=copy(); state.detailIndex=idx; showScreen('detail');
  els.detailTitle.textContent=t.questionReview; els.detailSubtitle.textContent=t.questionReviewSub; els.detailStatus.textContent=item.result.is_correct?t.correct:t.needsRevision; els.detailStatus.className=`detail-status ${item.result.is_correct?'good':'bad'}`; els.detailQuestionText.textContent=getText(item.question,'question_text');
  els.detailAnswerLabel.textContent=t.yourAnswer; els.detailAnswerValue.textContent=item.selectedDisplay || '—'; els.detailFocusLabel.textContent=reviewFocusLabel(item); els.detailFocusValue.textContent=itemFocus(item); els.detailFeedbackLabel.textContent=t.feedback; els.detailFeedbackValue.textContent=itemFeedback(item); els.detailNextLabel.textContent=t.nextAction; els.detailNextValue.textContent=itemNext(item);
}

function clearAiTimers(){ state.aiTimers.forEach(timer=>clearTimeout(timer)); state.aiTimers=[]; }
function openAiThinking(){
  clearAiTimers(); const t=copy(); showScreen('aiThinking');
  [els.aiStep1, els.aiStep2, els.aiStep3].forEach((el,idx)=>{ el.classList.remove('active','done'); if(idx===0) el.classList.add('active'); });
  els.aiThinkingStatus.textContent=t.aiThinkingStatus;
  state.aiTimers.push(setTimeout(()=>{ els.aiStep1.classList.remove('active'); els.aiStep1.classList.add('done'); els.aiStep2.classList.add('active'); }, 700));
  state.aiTimers.push(setTimeout(()=>{ els.aiStep2.classList.remove('active'); els.aiStep2.classList.add('done'); els.aiStep3.classList.add('active'); }, 1450));
  state.aiTimers.push(setTimeout(()=>{ els.aiStep3.classList.remove('active'); els.aiStep3.classList.add('done'); renderAiResult(); }, 2250));
}

function renderAiResult(){
  clearAiTimers(); const t=copy(); const s=getStats(); const focus=s.topicFocus[0]?.[0] || t.noWeakArea; showScreen('aiResult');
  els.aiFocusTitle.textContent=focus; els.aiReasonText.textContent=t.aiReasonText(focus, s.wrong.length || 0);
  els.aiPlanList.innerHTML=''; t.miniPlan(focus).forEach(step=>{ const li=document.createElement('li'); li.textContent=step; els.aiPlanList.appendChild(li); });
}

function startMiniTraining(){
  const s=getStats(); const focusRaw=s.rawTopicFocus[0]?.[0]; const mini=focusRaw ? state.allQuestions.filter(q=>q.topic===focusRaw) : [];
  startDemo(mini.length ? mini : state.allQuestions);
}

function resetToStart(){ state.questions=[...state.allQuestions]; state.currentIndex=0; state.selectedOptionIndex=null; state.results=[]; state.detailIndex=null; clearAiTimers(); showScreen('start'); updateStaticCopy(); }
function setLanguage(lang){ if(!COPY[lang]) return; state.lang=lang; els.languageButtons.forEach(b=>b.classList.toggle('active',b.dataset.lang===lang)); updateStaticCopy(); if(state.screen==='quiz') renderQuestion(); if(state.screen==='result') renderResult(); if(state.screen==='review') renderReview(); if(state.screen==='detail' && state.detailIndex!==null) renderQuestionDetail(state.detailIndex); if(state.screen==='aiThinking') openAiThinking(); if(state.screen==='aiResult') renderAiResult(); }

els.startDemo.addEventListener('click',()=>startDemo());
els.submitButton.addEventListener('click',submitAnswer);
els.resultPrimaryAction.addEventListener('click',renderReview);
els.backToStart.addEventListener('click',resetToStart);
els.openReview.addEventListener('click',renderReview);
els.openAi.addEventListener('click',openAiThinking);
els.reviewBackToResult.addEventListener('click',renderResult);
els.reviewToAi.addEventListener('click',openAiThinking);
els.aiBackToResult.addEventListener('click',renderResult);
els.startMiniTraining.addEventListener('click',startMiniTraining);
els.detailBackToReview.addEventListener('click',renderReview);
els.detailToAi.addEventListener('click',openAiThinking);
els.pauseBtn.addEventListener('click',()=>null);
els.inputAnswer.addEventListener('input',()=>setSubmitReady(hasCurrentAnswer()));
els.inputAnswer.addEventListener('keydown',e=>{ if(e.key==='Enter'&&hasCurrentAnswer()) submitAnswer(); });
els.languageButtons.forEach(b=>b.addEventListener('click',()=>setLanguage(b.dataset.lang)));

updateStaticCopy(); showScreen('start'); loadQuestions();
