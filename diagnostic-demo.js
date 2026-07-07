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
    practice: 'Practice',
    startSubtitle: '7 questions • from easy to hard',
    tourPicker: 'Tour selection',
    tour: 'Tour',
    subjectLabel: 'Subject',
    subjectTitle: 'Economics',
    stageMeta: (done, total) => `Tour 6 practice • Completed ${done}/${total} • Remaining ${Math.max(0, total - done)}`,
    bestResult: 'Best result',
    bestTime: 'Best time',
    lastAttempts: 'Last attempts',
    noAttempts: 'No attempts yet',
    date: 'Date',
    score: 'Score',
    time: 'Time',
    start: 'Start practice',
    pause: 'Pause',
    difficulty: 'Difficulty',
    difficulty_easy: 'easy',
    difficulty_medium: 'medium',
    difficulty_hard: 'hard',
    inputLabel: 'Answer',
    inputPlaceholder: 'Type your answer',
    answer: 'Answer',
    checking: 'Checking…',
    loadError: 'Could not load practice.',
    loading: 'Loading practice questions…',
    resultTitle: 'Practice result',
    resultMeta: (score, total, percent, wrong, topics) => `Score: ${score}/${total} (${percent}%) • Errors: ${wrong} • Weak topics: ${topics}`,
    reviewDiagnosis: 'Review and diagnosis',
    reviewDiagnosisSub: 'Answers, mistake reasons and what to repeat',
    tryAgain: 'Try again',
    toPractice: 'To practice',
    reviewSubtitle: 'Mistakes, explanations and repetition plan',
    diagnosticSummary: 'Diagnostic summary',
    result: 'Result',
    errors: 'Errors',
    topics: 'Topics',
    mainWeakAreas: 'Main weak areas',
    mistakePattern: 'Mistake pattern',
    nextStudyPlan: 'Next study plan',
    noWeakArea: 'No major weak area found in this short set.',
    noMistakePattern: 'No repeated mistake pattern found.',
    harderSet: 'Move to a harder Economics practice set.',
    explainLogic: 'Review your correct answers and explain the logic in your own words.',
    yourAnswer: 'Your answer',
    feedback: 'Explanation',
    weakArea: 'Weak area',
    nextAction: 'Next action',
    correct: 'Correct',
    needsRevision: 'Needs revision',
    questions: 'Questions',
    mistakes: 'Mistakes',
    times: 'times',
    backToResult: 'Back to result',
    chooseOption: 'Choose one option first.',
    typeAnswer: 'Type your answer first.',
  },
  ru: {
    practice: 'Практика',
    startSubtitle: '7 вопросов • от простого к сложному',
    tourPicker: 'Выбор тура',
    tour: 'Тур',
    subjectLabel: 'Предмет',
    subjectTitle: 'Экономика',
    stageMeta: (done, total) => `Практика 6 тура • Завершено ${done}/${total} • Осталось ${Math.max(0, total - done)}`,
    bestResult: 'Лучший результат',
    bestTime: 'Лучшее время',
    lastAttempts: 'Последние попытки',
    noAttempts: 'Пока нет попыток',
    date: 'Дата',
    score: 'Счёт',
    time: 'Время',
    start: 'Начать практику',
    pause: 'Пауза',
    difficulty: 'Сложность',
    difficulty_easy: 'легко',
    difficulty_medium: 'средне',
    difficulty_hard: 'сложно',
    inputLabel: 'Ответ',
    inputPlaceholder: 'Введите ответ',
    answer: 'Ответить',
    checking: 'Проверяем…',
    loadError: 'Не удалось загрузить практику.',
    loading: 'Загружаем вопросы практики…',
    resultTitle: 'Результат практики',
    resultMeta: (score, total, percent, wrong, topics) => `Счёт: ${score}/${total} (${percent}%) • Ошибки: ${wrong} • Слабые темы: ${topics}`,
    reviewDiagnosis: 'Разбор и диагностика',
    reviewDiagnosisSub: 'Ответы, причины ошибок и что повторить',
    tryAgain: 'Пройти снова',
    toPractice: 'К практике',
    reviewSubtitle: 'Ошибки, объяснения и план повторения',
    diagnosticSummary: 'Диагностический итог',
    result: 'Результат',
    errors: 'Ошибки',
    topics: 'Темы',
    mainWeakAreas: 'Главные слабые места',
    mistakePattern: 'Тип ошибок',
    nextStudyPlan: 'Следующий учебный план',
    noWeakArea: 'В этом коротком блоке серьёзных слабых мест не найдено.',
    noMistakePattern: 'Повторяющийся тип ошибок не найден.',
    harderSet: 'Перейти к более сложному блоку по экономике.',
    explainLogic: 'Повтори правильные ответы и объясни логику своими словами.',
    yourAnswer: 'Твой ответ',
    feedback: 'Объяснение',
    weakArea: 'Слабое место',
    nextAction: 'Следующий шаг',
    correct: 'Верно',
    needsRevision: 'Нужно повторить',
    questions: 'Вопросов',
    mistakes: 'Ошибок',
    times: 'раза',
    backToResult: 'Назад к результату',
    chooseOption: 'Сначала выбери один вариант ответа.',
    typeAnswer: 'Сначала введи ответ.',
  },
  uz: {
    practice: 'Mashq',
    startSubtitle: '7 savol • osondan qiyinga',
    tourPicker: 'Tur tanlash',
    tour: 'Tur',
    subjectLabel: 'Fan',
    subjectTitle: 'Iqtisodiyot',
    stageMeta: (done, total) => `6-tur mashqi • Tugallandi ${done}/${total} • Qoldi ${Math.max(0, total - done)}`,
    bestResult: 'Eng yaxshi natija',
    bestTime: 'Eng yaxshi vaqt',
    lastAttempts: 'Oxirgi urinishlar',
    noAttempts: 'Hozircha urinish yo‘q',
    date: 'Sana',
    score: 'Ball',
    time: 'Vaqt',
    start: 'Mashqni boshlash',
    pause: 'Pauza',
    difficulty: 'Qiyinlik',
    difficulty_easy: 'oson',
    difficulty_medium: 'o‘rtacha',
    difficulty_hard: 'qiyin',
    inputLabel: 'Javob',
    inputPlaceholder: 'Javobni kiriting',
    answer: 'Javob berish',
    checking: 'Tekshirilmoqda…',
    loadError: 'Mashq yuklanmadi.',
    loading: 'Mashq savollari yuklanmoqda…',
    resultTitle: 'Mashq natijasi',
    resultMeta: (score, total, percent, wrong, topics) => `Ball: ${score}/${total} (${percent}%) • Xatolar: ${wrong} • Zaif mavzular: ${topics}`,
    reviewDiagnosis: 'Tahlil va diagnostika',
    reviewDiagnosisSub: 'Javoblar, xato sabablari va qayta ko‘rish rejasi',
    tryAgain: 'Qayta o‘tish',
    toPractice: 'Mashqqa',
    reviewSubtitle: 'Xatolar, izohlar va takrorlash rejasi',
    diagnosticSummary: 'Diagnostik natija',
    result: 'Natija',
    errors: 'Xatolar',
    topics: 'Mavzular',
    mainWeakAreas: 'Asosiy zaif joylar',
    mistakePattern: 'Xato turi',
    nextStudyPlan: 'Keyingi tayyorgarlik rejasi',
    noWeakArea: 'Bu qisqa blokda katta zaif joy topilmadi.',
    noMistakePattern: 'Takrorlanayotgan xato turi topilmadi.',
    harderSet: 'Iqtisodiyot bo‘yicha qiyinroq blokka o‘ting.',
    explainLogic: 'To‘g‘ri javoblarni qayta ko‘rib chiqing va mantiqni o‘z so‘zingiz bilan tushuntiring.',
    yourAnswer: 'Sizning javobingiz',
    feedback: 'Izoh',
    weakArea: 'Zaif joy',
    nextAction: 'Keyingi qadam',
    correct: 'To‘g‘ri',
    needsRevision: 'Qayta ko‘rib chiqish kerak',
    questions: 'Savollar',
    mistakes: 'Xatolar',
    times: 'marta',
    backToResult: 'Natijaga qaytish',
    chooseOption: 'Avval bitta javob variantini tanlang.',
    typeAnswer: 'Avval javobni kiriting.',
  },
};

const LABELS = {
  topic: {
    Market: { en: 'Market', ru: 'Рынок', uz: 'Bozor' },
    Demand: { en: 'Demand', ru: 'Спрос', uz: 'Talab' },
    Basics: { en: 'Economics basics', ru: 'Основы экономики', uz: 'Iqtisodiyot asoslari' },
    PPC: { en: 'PPC', ru: 'Кривая производственных возможностей', uz: 'Ishlab chiqarish imkoniyatlari egri chizig‘i' },
    Elasticity: { en: 'Elasticity', ru: 'Эластичность', uz: 'Elastiklik' },
    'Government macroeconomic intervention': { en: 'Government macroeconomic policy', ru: 'Макроэкономическая политика государства', uz: 'Davlatning makroiqtisodiy siyosati' },
    'Allocative efficiency': { en: 'Allocative efficiency', ru: 'Аллокативная эффективность', uz: 'Allokativ samaradorlik' },
    'Complementary goods': { en: 'Complementary goods', ru: 'Дополняющие товары', uz: 'To‘ldiruvchi tovarlar' },
    'Consumer surplus': { en: 'Consumer surplus', ru: 'Потребительский излишек', uz: 'Iste’molchi ortiqchaligi' },
    'Income from factors of production': { en: 'Income from factors of production', ru: 'Доходы факторов производства', uz: 'Ishlab chiqarish omillari daromadi' },
    'Fiscal policy': { en: 'Fiscal policy', ru: 'Фискальная политика', uz: 'Fiskal siyosat' },
    'Opportunity cost on the PPC': { en: 'Opportunity cost on PPC', ru: 'Альтернативная стоимость на PPC', uz: 'PPC bo‘yicha muqobil qiymat' },
    'Calculating PED': { en: 'Calculating PED', ru: 'Расчёт PED', uz: 'PED hisoblash' },
  },
  skill: {
    'Allocative efficiency vs average-cost logic': { en: 'Allocative efficiency vs average cost', ru: 'Аллокативная эффективность и средние издержки', uz: 'Allokativ samaradorlik va o‘rtacha xarajat' },
    'Area position on demand diagram': { en: 'Area position on demand diagram', ru: 'Область на графике спроса', uz: 'Talab grafigidagi soha' },
    'Complement demand shift direction': { en: 'Direction of demand shift for complements', ru: 'Направление сдвига спроса у дополняющих товаров', uz: 'To‘ldiruvchi tovarlarda talab siljishi yo‘nalishi' },
    'Consumer surplus vs producer/supply area': { en: 'Consumer surplus vs producer area', ru: 'Потребительский излишек и область производителя', uz: 'Iste’molchi ortiqchaligi va ishlab chiqaruvchi sohasi' },
    'Consumer vs producer surplus': { en: 'Consumer surplus vs producer surplus', ru: 'Потребительский и производительский излишек', uz: 'Iste’molchi va ishlab chiqaruvchi ortiqchaligi' },
    'Demand shift vs elasticity terminology': { en: 'Demand shift vs elasticity term', ru: 'Сдвиг спроса и термин эластичности', uz: 'Talab siljishi va elastiklik termini' },
    'Efficiency vs profit outcome': { en: 'Efficiency vs profit result', ru: 'Эффективность и результат прибыли', uz: 'Samaradorlik va foyda natijasi' },
    'Enterprise vs capital reward': { en: 'Enterprise vs capital reward', ru: 'Доход предпринимательства и капитала', uz: 'Tadbirkorlik va kapital daromadi' },
    'Fiscal vs monetary policy': { en: 'Fiscal policy vs monetary policy', ru: 'Фискальная и монетарная политика', uz: 'Fiskal va monetar siyosat' },
    'Labour vs capital reward': { en: 'Labour vs capital reward', ru: 'Доход труда и капитала', uz: 'Mehnat va kapital daromadi' },
    'Land vs capital reward': { en: 'Land vs capital reward', ru: 'Доход земли и капитала', uz: 'Yer va kapital daromadi' },
    'Macroeconomic policy categories': { en: 'Macroeconomic policy categories', ru: 'Категории макроэкономической политики', uz: 'Makroiqtisodiy siyosat turlari' },
    'Market supply misconception': { en: 'Misconception about market supply', ru: 'Неверное понимание предложения', uz: 'Taklif haqida noto‘g‘ri tushuncha' },
    'Opportunity cost calculation': { en: 'Opportunity cost calculation', ru: 'Расчёт альтернативной стоимости', uz: 'Muqobil qiymatni hisoblash' },
    'PED calculation': { en: 'PED calculation', ru: 'Расчёт PED', uz: 'PED hisoblash' },
    'Policy instrument recognition': { en: 'Recognising policy instruments', ru: 'Распознавание инструментов политики', uz: 'Siyosat instrumentlarini tanish' },
    'Related goods effect': { en: 'Effect of related goods', ru: 'Влияние связанных товаров', uz: 'Bog‘liq tovarlar ta’siri' },
  },
  mistake: {
    concept_confusion: { en: 'Concept confusion', ru: 'Путаница понятий', uz: 'Tushuncha chalkashligi' },
    diagram_area_direction: { en: 'Diagram area error', ru: 'Ошибка области на графике', uz: 'Diagrammadagi soha xatosi' },
    direction_error: { en: 'Direction error', ru: 'Ошибка направления', uz: 'Yo‘nalish xatosi' },
    diagram_area_confusion: { en: 'Diagram area confusion', ru: 'Путаница областей на графике', uz: 'Diagramma sohalarini adashtirish' },
    producer_surplus_confusion: { en: 'Consumer/producer surplus confusion', ru: 'Путаница потребительского и производительского излишка', uz: 'Iste’molchi va ishlab chiqaruvchi ortiqchaligi chalkashligi' },
    term_misuse: { en: 'Term misuse', ru: 'Неверное использование термина', uz: 'Termin noto‘g‘ri ishlatilgan' },
    overgeneralisation: { en: 'Overgeneralisation', ru: 'Слишком общее правило', uz: 'Haddan tashqari umumlashtirish' },
    factor_reward_confusion: { en: 'Factor income confusion', ru: 'Путаница доходов факторов', uz: 'Omil daromadlari chalkashligi' },
    policy_type_confusion: { en: 'Policy type confusion', ru: 'Путаница типов политики', uz: 'Siyosat turlari chalkashligi' },
    policy_scope_confusion: { en: 'Policy scope confusion', ru: 'Путаница области политики', uz: 'Siyosat doirasi chalkashligi' },
    irrelevant_condition: { en: 'Irrelevant condition', ru: 'Нерелевантное условие', uz: 'Aloqasiz shart' },
    calculation_error: { en: 'Calculation error', ru: 'Ошибка расчёта', uz: 'Hisoblash xatosi' },
    formula_or_percentage_error: { en: 'Formula or percentage error', ru: 'Ошибка формулы или процентов', uz: 'Formula yoki foiz xatosi' },
    missing_link: { en: 'Missing link between ideas', ru: 'Пропущена связь между идеями', uz: 'G‘oyalar orasidagi bog‘lanish tushib qolgan' },
  },
};

const state = {
  lang: 'ru',
  screen: 'start',
  questions: [],
  currentIndex: 0,
  selectedOptionIndex: null,
  results: [],
};

const $ = (id) => document.getElementById(id);
const els = {
  startScreen: $('practice-start-screen'), quizScreen: $('practice-quiz-screen'), resultScreen: $('practice-result-screen'), reviewScreen: $('practice-review-diagnosis-screen'),
  startTitle: $('start-title'), startSubtitle: $('start-subtitle'), tourPickerTitle: $('tour-picker-title'), tourActiveChip: $('tour-active-chip'),
  heroSubjectLabel: $('hero-subject-label'), heroSubjectTitle: $('hero-subject-title'), heroStageMeta: $('hero-stage-meta'),
  bestResultLabel: $('best-result-label'), bestTimeLabel: $('best-time-label'), lastAttemptsTitle: $('last-attempts-title'), lastAttemptsEmpty: $('last-attempts-empty'),
  colDate: $('col-date'), colScore: $('col-score'), colTime: $('col-time'), startDemo: $('start-demo'),
  qno: $('practice-qno'), timer: $('practice-timer'), pauseBtn: $('practice-pause-btn'), questionText: $('question-text'), questionDifficulty: $('question-difficulty'),
  optionsList: $('options-list'), inputWrap: $('input-wrap'), inputLabel: $('input-label'), inputAnswer: $('input-answer'), submitButton: $('submit-answer'),
  resultTitle: $('result-title'), resultMeta: $('practice-result-meta'), openReview: $('open-review-diagnosis'), reviewDiagnosisTitle: $('review-diagnosis-title'), reviewDiagnosisSub: $('review-diagnosis-sub'), reviewDiagnosisCount: $('review-diagnosis-count'), restartButton: $('restart-demo'), backToStart: $('back-to-start'),
  reviewTitle: $('review-title'), reviewSubtitle: $('review-subtitle'), diagnosticSummaryTitle: $('diagnostic-summary-title'), diagnosticScoreLabel: $('diagnostic-score-label'), diagnosticScore: $('diagnostic-score'), diagnosticErrorsLabel: $('diagnostic-errors-label'), diagnosticErrors: $('diagnostic-errors'), diagnosticTopicsLabel: $('diagnostic-topics-label'), diagnosticTopics: $('diagnostic-topics'), summaryWeakTitle: $('summary-weak-title'), summaryWeakList: $('summary-weak-list'), summaryMistakeTitle: $('summary-mistake-title'), summaryMistakeList: $('summary-mistake-list'), summaryPlanTitle: $('summary-plan-title'), summaryPlanList: $('summary-plan-list'), reviewQuestionList: $('review-question-list'), reviewBackToResult: $('review-back-to-result'), reviewToPractice: $('review-to-practice'),
  languageButtons: document.querySelectorAll('.language-btn')
};

function copy() { return COPY[state.lang] || COPY.ru; }
function localField(base) { return `${base}_${state.lang}`; }
function displayLabel(value, group = 'topic') { return LABELS[group]?.[value]?.[state.lang] || LABELS[group]?.[value]?.ru || LABELS[group]?.[value]?.en || value || ''; }
function escapeHtml(value) { return String(value ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#039;'); }
function formatMMSS(seconds) { const s = Math.max(0, Number(seconds) || 0); return `${String(Math.floor(s / 60)).padStart(2, '0')}:${String(s % 60).padStart(2, '0')}`; }

function parseOptions(rawOptions) {
  if (!rawOptions) return [];
  if (Array.isArray(rawOptions)) return rawOptions;
  try { const parsed = JSON.parse(rawOptions); return Array.isArray(parsed) ? parsed : []; }
  catch { return String(rawOptions).split('|').map((item) => item.trim()).filter(Boolean); }
}

function getText(row, fieldBase) {
  return row?.[localField(fieldBase)] || row?.[`${fieldBase}_ru`] || row?.[`${fieldBase}_en`] || row?.[`${fieldBase}_uz`] || row?.[fieldBase] || '';
}

function getResultText(result, fieldBase) {
  return result?.[localField(fieldBase)] || result?.[`${fieldBase}_ru`] || result?.[`${fieldBase}_en`] || result?.[`${fieldBase}_uz`] || '';
}

function showScreen(name) {
  state.screen = name;
  els.startScreen.classList.toggle('hidden', name !== 'start');
  els.quizScreen.classList.toggle('hidden', name !== 'quiz');
  els.resultScreen.classList.toggle('hidden', name !== 'result');
  els.reviewScreen.classList.toggle('hidden', name !== 'review');
}

function updateStaticCopy() {
  const t = copy();
  document.documentElement.lang = state.lang;
  els.startTitle.textContent = t.practice;
  els.startSubtitle.textContent = t.startSubtitle;
  els.tourPickerTitle.textContent = t.tourPicker;
  els.tourActiveChip.textContent = `${t.tour} 6`;
  els.heroSubjectLabel.textContent = t.subjectLabel;
  els.heroSubjectTitle.textContent = t.subjectTitle;
  els.heroStageMeta.textContent = t.stageMeta(state.results.length, PILOT_QUESTION_IDS.length);
  els.bestResultLabel.textContent = t.bestResult;
  els.bestTimeLabel.textContent = t.bestTime;
  els.lastAttemptsTitle.textContent = t.lastAttempts;
  els.lastAttemptsEmpty.textContent = t.noAttempts;
  els.colDate.textContent = t.date;
  els.colScore.textContent = t.score;
  els.colTime.textContent = t.time;
  els.startDemo.textContent = state.questions.length ? t.start : t.loading;
  els.pauseBtn.textContent = t.pause;
  els.inputLabel.textContent = t.inputLabel;
  els.inputAnswer.placeholder = t.inputPlaceholder;
  els.submitButton.textContent = t.answer;
  els.resultTitle.textContent = t.resultTitle;
  els.reviewDiagnosisTitle.textContent = t.reviewDiagnosis;
  els.reviewDiagnosisSub.textContent = t.reviewDiagnosisSub;
  els.restartButton.textContent = t.tryAgain;
  els.backToStart.textContent = t.toPractice;
  els.reviewTitle.textContent = t.reviewDiagnosis;
  els.reviewSubtitle.textContent = t.reviewSubtitle;
  els.diagnosticSummaryTitle.textContent = t.diagnosticSummary;
  els.diagnosticScoreLabel.textContent = t.result;
  els.diagnosticErrorsLabel.textContent = t.errors;
  els.diagnosticTopicsLabel.textContent = t.topics;
  els.summaryWeakTitle.textContent = t.mainWeakAreas;
  els.summaryMistakeTitle.textContent = t.mistakePattern;
  els.summaryPlanTitle.textContent = t.nextStudyPlan;
  els.reviewBackToResult.textContent = t.backToResult;
  els.reviewToPractice.textContent = t.toPractice;
}

function setSubmitReady(ready) {
  els.submitButton.disabled = !ready;
  els.submitButton.classList.toggle('is-ready', !!ready);
}

function hasCurrentAnswer() {
  const question = state.questions[state.currentIndex];
  if (!question) return false;
  if (String(question.qtype || '').toLowerCase() === 'input') return !!String(els.inputAnswer.value || '').trim();
  return state.selectedOptionIndex !== null && state.selectedOptionIndex !== undefined;
}

function difficultyLabel(difficulty) {
  const key = `difficulty_${String(difficulty || '').toLowerCase()}`;
  return copy()[key] || difficulty || '';
}

async function loadQuestions() {
  updateStaticCopy();
  els.startDemo.disabled = true;
  els.startDemo.textContent = copy().loading;
  const { data, error } = await client.rpc('get_safe_questions_by_ids', { p_question_ids: PILOT_QUESTION_IDS });
  if (error) { console.error(error); els.startDemo.textContent = copy().loadError; return; }
  state.questions = [...(data || [])].sort((a, b) => {
    const aOrder = a.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(a.id));
    const bOrder = b.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(b.id));
    return aOrder - bOrder;
  });
  els.startDemo.disabled = !state.questions.length;
  updateStaticCopy();
}

function renderQuestion() {
  const t = copy();
  const question = state.questions[state.currentIndex];
  if (!question) { renderResult(); return; }
  state.selectedOptionIndex = null;
  els.inputAnswer.value = '';
  els.qno.textContent = `${state.currentIndex + 1}/${state.questions.length}`;
  els.timer.textContent = formatMMSS(Number(question.time_limit_sec || question.timeLimitSec || 58));
  els.questionText.textContent = getText(question, 'question_text');
  els.questionDifficulty.textContent = `${t.difficulty}: ${difficultyLabel(question.difficulty)}`;
  els.submitButton.textContent = t.answer;
  setSubmitReady(false);
  els.optionsList.innerHTML = '';

  if (String(question.qtype || '').toLowerCase() === 'input') {
    els.inputWrap.classList.remove('hidden');
    return;
  }

  els.inputWrap.classList.add('hidden');
  const options = parseOptions(getText(question, 'options_text'));
  options.forEach((option, index) => {
    const row = document.createElement('label');
    row.className = 'option-row';
    row.innerHTML = `<input type="radio" name="diagnostic-option" value="${index}"><span>${String.fromCharCode(65 + index)}. ${escapeHtml(option)}</span>`;
    row.querySelector('input')?.addEventListener('change', () => {
      state.selectedOptionIndex = index;
      els.optionsList.querySelectorAll('.option-row').forEach((node) => node.classList.remove('is-selected'));
      row.classList.add('is-selected');
      setSubmitReady(true);
    });
    els.optionsList.appendChild(row);
  });
}

function startDemo() {
  if (!state.questions.length) return;
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.results = [];
  showScreen('quiz');
  renderQuestion();
}

async function submitAnswer() {
  const t = copy();
  const question = state.questions[state.currentIndex];
  if (!question) return;
  const isInput = String(question.qtype || '').toLowerCase() === 'input';
  const userAnswer = isInput ? els.inputAnswer.value.trim() : null;
  if (isInput && !userAnswer) { alert(t.typeAnswer); return; }
  if (!isInput && state.selectedOptionIndex === null) { alert(t.chooseOption); return; }

  els.submitButton.disabled = true;
  els.submitButton.textContent = t.checking;
  const selectedDisplay = isInput ? userAnswer : `${String.fromCharCode(65 + state.selectedOptionIndex)}`;
  const { data, error } = await client.rpc('evaluate_diagnostic_demo_answer', {
    p_question_id: Number(question.id),
    p_user_answer: userAnswer,
    p_picked_index: isInput ? null : state.selectedOptionIndex,
  });
  if (error) { console.error(error); alert(t.loadError); setSubmitReady(hasCurrentAnswer()); return; }
  state.results.push({ question, result: data || {}, selectedDisplay });
  state.currentIndex += 1;
  if (state.currentIndex >= state.questions.length) renderResult();
  else renderQuestion();
}

function countBy(items, getKey) {
  const map = new Map();
  items.forEach((item) => { const key = getKey(item); if (key) map.set(key, (map.get(key) || 0) + 1); });
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}

function getDiagnosticStats() {
  const total = state.results.length;
  const correctCount = state.results.filter(({ result }) => Boolean(result.is_correct)).length;
  const wrong = state.results.filter(({ result }) => !Boolean(result.is_correct));
  const weakAreas = countBy(wrong, ({ result }) => displayLabel(result.weak_skill, 'skill') || displayLabel(result.recommended_topic, 'topic'));
  const mistakeTypes = countBy(wrong, ({ result }) => displayLabel(result.mistake_type, 'mistake'));
  const percent = total ? Math.round((correctCount / total) * 100) : 0;
  return { total, correctCount, wrong, weakAreas, mistakeTypes, percent };
}

function renderResult() {
  const t = copy();
  const stats = getDiagnosticStats();
  showScreen('result');
  els.resultMeta.textContent = t.resultMeta(stats.correctCount, stats.total, stats.percent, stats.wrong.length, stats.weakAreas.length);
  els.reviewDiagnosisCount.textContent = String(stats.wrong.length);
}

function fillList(listEl, items, fallbackText) {
  listEl.innerHTML = '';
  if (!items.length) { const li = document.createElement('li'); li.textContent = fallbackText; listEl.appendChild(li); return; }
  items.slice(0, 4).forEach(([label, count]) => {
    const li = document.createElement('li');
    li.textContent = count > 1 ? `${label} (${count} ${copy().times})` : label;
    listEl.appendChild(li);
  });
}

function fillPlanList(wrongResults) {
  els.summaryPlanList.innerHTML = '';
  const planItems = [];
  wrongResults.forEach(({ result }) => {
    const action = getResultText(result, 'next_action');
    if (action && !planItems.includes(action)) planItems.push(action);
  });
  if (!planItems.length) {
    planItems.push(copy().harderSet);
    planItems.push(copy().explainLogic);
  }
  planItems.slice(0, 4).forEach((text) => { const li = document.createElement('li'); li.textContent = text; els.summaryPlanList.appendChild(li); });
}

function renderReviewDiagnosis() {
  const t = copy();
  const stats = getDiagnosticStats();
  showScreen('review');
  els.diagnosticScore.textContent = `${stats.percent}%`;
  els.diagnosticErrors.textContent = String(stats.wrong.length);
  els.diagnosticTopics.textContent = String(stats.weakAreas.length);
  fillList(els.summaryWeakList, stats.weakAreas, t.noWeakArea);
  fillList(els.summaryMistakeList, stats.mistakeTypes, t.noMistakePattern);
  fillPlanList(stats.wrong);

  const byTopic = new Map();
  state.results.forEach((item, idx) => {
    const topic = displayLabel(item.question.topic, 'topic') || 'General';
    if (!byTopic.has(topic)) byTopic.set(topic, []);
    byTopic.get(topic).push({ ...item, idx });
  });

  const topics = [...byTopic.keys()].sort((a, b) => {
    const aw = byTopic.get(a).filter(x => !x.result.is_correct).length;
    const bw = byTopic.get(b).filter(x => !x.result.is_correct).length;
    return bw - aw || a.localeCompare(b);
  });

  els.reviewQuestionList.innerHTML = '';
  topics.forEach((topic, topicIndex) => {
    const items = byTopic.get(topic);
    const wrongCount = items.filter(x => !x.result.is_correct).length;
    const card = document.createElement('section');
    card.className = 'card review-topic-card';
    const bodyId = `topic-body-${topicIndex}`;
    card.innerHTML = `
      <button class="review-topic-head" type="button">
        <div>
          <div class="review-topic-title">${escapeHtml(topic)}</div>
          <div class="review-topic-meta">${t.questions}: ${items.length} • ${t.mistakes}: ${wrongCount}</div>
        </div>
        <span class="badge badge-pin">${wrongCount ? `❌ ${wrongCount}` : '✅ 0'}</span>
      </button>
      <div class="review-topic-body" id="${bodyId}" style="display:${topicIndex === 0 ? 'grid' : 'none'}"></div>
    `;
    const body = card.querySelector(`#${bodyId}`);
    card.querySelector('.review-topic-head')?.addEventListener('click', () => {
      body.style.display = body.style.display === 'none' ? 'grid' : 'none';
    });
    items.forEach(({ question, result, selectedDisplay, idx }) => {
      const item = document.createElement('article');
      item.className = 'review-item';
      const statusText = result.is_correct ? t.correct : t.needsRevision;
      const statusIcon = result.is_correct ? '✅' : '❌';
      item.innerHTML = `
        <div class="review-item-title">${statusIcon} ${idx + 1}. ${escapeHtml(statusText)}</div>
        <div class="review-item-text">${escapeHtml(getText(question, 'question_text'))}</div>
        <div class="review-two-col">
          <div class="review-mini-box"><span>${escapeHtml(t.yourAnswer)}</span><strong>${escapeHtml(selectedDisplay || '—')}</strong></div>
          <div class="review-mini-box"><span>${escapeHtml(t.weakArea)}</span><strong>${escapeHtml(displayLabel(result.weak_skill, 'skill') || displayLabel(result.recommended_topic, 'topic') || '—')}</strong></div>
          <div class="review-mini-box"><span>${escapeHtml(t.feedback)}</span><strong>${escapeHtml(getResultText(result, 'feedback') || '—')}</strong></div>
          <div class="review-mini-box"><span>${escapeHtml(t.nextAction)}</span><strong>${escapeHtml(getResultText(result, 'next_action') || '—')}</strong></div>
        </div>
      `;
      body.appendChild(item);
    });
    els.reviewQuestionList.appendChild(card);
  });
}

function resetToStart() {
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.results = [];
  showScreen('start');
  updateStaticCopy();
}

function setLanguage(lang) {
  if (!COPY[lang]) return;
  state.lang = lang;
  els.languageButtons.forEach((btn) => btn.classList.toggle('active', btn.dataset.lang === lang));
  updateStaticCopy();
  if (state.screen === 'quiz') renderQuestion();
  if (state.screen === 'result') renderResult();
  if (state.screen === 'review') renderReviewDiagnosis();
}

els.startDemo.addEventListener('click', startDemo);
els.submitButton.addEventListener('click', submitAnswer);
els.restartButton.addEventListener('click', startDemo);
els.backToStart.addEventListener('click', resetToStart);
els.openReview.addEventListener('click', renderReviewDiagnosis);
els.reviewBackToResult.addEventListener('click', renderResult);
els.reviewToPractice.addEventListener('click', resetToStart);
els.pauseBtn.addEventListener('click', () => null);
els.inputAnswer.addEventListener('input', () => setSubmitReady(hasCurrentAnswer()));
els.inputAnswer.addEventListener('keydown', (event) => { if (event.key === 'Enter' && hasCurrentAnswer()) submitAnswer(); });
els.languageButtons.forEach((button) => button.addEventListener('click', () => setLanguage(button.dataset.lang)));

updateStaticCopy();
showScreen('start');
loadQuestions();
