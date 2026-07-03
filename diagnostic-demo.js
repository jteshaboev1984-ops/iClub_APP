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
    startSubtitle: '7 questions • diagnostic feedback',
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
    start: 'Start diagnostic practice',
    pause: 'Pause',
    difficulty: 'Difficulty',
    difficulty_easy: 'easy',
    difficulty_medium: 'medium',
    difficulty_hard: 'hard',
    inputLabel: 'Answer',
    inputPlaceholder: 'Type your answer',
    answer: 'Answer',
    answerChecked: 'Answer checked',
    correct: 'Correct',
    needsRevision: 'Needs revision',
    weakArea: 'Weak area',
    nextAction: 'Next action',
    nextQuestion: 'Next question',
    showResult: 'Show result',
    chooseOption: 'Choose one answer option first.',
    typeAnswer: 'Type your answer first.',
    checking: 'Checking…',
    checkError: 'Could not check the answer. Try again.',
    loadError: 'Could not load diagnostic practice.',
    loading: 'Loading practice questions…',
    questionPlaceholder: 'Practice question…',
    resultTitle: 'Practice result',
    resultMeta: (score, total, percent, wrong, weak) => `Score: ${score}/${total} (${percent}%) • Errors: ${wrong} • Topics: ${weak}`,
    resultScoreLabel: 'Diagnostic result',
    mainWeakAreas: 'Main weak areas',
    mistakePattern: 'Mistake pattern',
    nextStudyPlan: 'Next study plan',
    noWeakArea: 'No major weak area found in this short set.',
    noMistakePattern: 'No repeated mistake pattern found.',
    harderSet: 'Move to a harder Economics practice set.',
    explainLogic: 'Review your correct answers and explain the logic in your own words.',
    reviewRelatedTopic: 'Review the related topic',
    trySimilar: 'Try one more similar question.',
    feedbackMissing: 'Feedback is not available yet.',
    times: 'times',
    restart: 'Try again',
    backToPractice: 'To practice',
  },
  ru: {
    practice: 'Практика',
    startSubtitle: '7 вопросов • диагностическая обратная связь',
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
    start: 'Начать диагностическую практику',
    pause: 'Пауза',
    difficulty: 'Сложность',
    difficulty_easy: 'легко',
    difficulty_medium: 'средне',
    difficulty_hard: 'сложно',
    inputLabel: 'Ответ',
    inputPlaceholder: 'Введите ответ',
    answer: 'Ответить',
    answerChecked: 'Ответ проверен',
    correct: 'Верно',
    needsRevision: 'Нужно повторить',
    weakArea: 'Слабое место',
    nextAction: 'Следующий шаг',
    nextQuestion: 'Следующий вопрос',
    showResult: 'Показать результат',
    chooseOption: 'Сначала выбери один вариант ответа.',
    typeAnswer: 'Сначала введи ответ.',
    checking: 'Проверяем…',
    checkError: 'Не удалось проверить ответ. Попробуй ещё раз.',
    loadError: 'Не удалось загрузить диагностическую практику.',
    loading: 'Загружаем вопросы практики…',
    questionPlaceholder: 'Вопрос практики…',
    resultTitle: 'Результат практики',
    resultMeta: (score, total, percent, wrong, weak) => `Счёт: ${score}/${total} (${percent}%) • Ошибки: ${wrong} • Темы: ${weak}`,
    resultScoreLabel: 'Диагностический результат',
    mainWeakAreas: 'Главные слабые места',
    mistakePattern: 'Тип ошибок',
    nextStudyPlan: 'Следующий учебный план',
    noWeakArea: 'В этом коротком блоке серьёзных слабых мест не найдено.',
    noMistakePattern: 'Повторяющийся тип ошибок не найден.',
    harderSet: 'Перейти к более сложному блоку по экономике.',
    explainLogic: 'Повтори правильные ответы и объясни логику своими словами.',
    reviewRelatedTopic: 'Повтори связанную тему',
    trySimilar: 'Реши ещё один похожий вопрос.',
    feedbackMissing: 'Диагностический комментарий пока недоступен.',
    times: 'раза',
    restart: 'Пройти снова',
    backToPractice: 'К практике',
  },
  uz: {
    practice: 'Mashq',
    startSubtitle: '7 savol • diagnostik feedback',
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
    start: 'Diagnostik mashqni boshlash',
    pause: 'Pauza',
    difficulty: 'Qiyinlik',
    difficulty_easy: 'oson',
    difficulty_medium: 'o‘rtacha',
    difficulty_hard: 'qiyin',
    inputLabel: 'Javob',
    inputPlaceholder: 'Javobni kiriting',
    answer: 'Javob berish',
    answerChecked: 'Javob tekshirildi',
    correct: 'To‘g‘ri',
    needsRevision: 'Qayta ko‘rib chiqish kerak',
    weakArea: 'Zaif joy',
    nextAction: 'Keyingi qadam',
    nextQuestion: 'Keyingi savol',
    showResult: 'Natijani ko‘rsatish',
    chooseOption: 'Avval bitta javob variantini tanlang.',
    typeAnswer: 'Avval javobni kiriting.',
    checking: 'Tekshirilmoqda…',
    checkError: 'Javobni tekshirib bo‘lmadi. Qayta urinib ko‘ring.',
    loadError: 'Diagnostik mashq yuklanmadi.',
    loading: 'Mashq savollari yuklanmoqda…',
    questionPlaceholder: 'Mashq savoli…',
    resultTitle: 'Mashq natijasi',
    resultMeta: (score, total, percent, wrong, weak) => `Ball: ${score}/${total} (${percent}%) • Xatolar: ${wrong} • Mavzular: ${weak}`,
    resultScoreLabel: 'Diagnostik natija',
    mainWeakAreas: 'Asosiy zaif joylar',
    mistakePattern: 'Xato turi',
    nextStudyPlan: 'Keyingi tayyorgarlik rejasi',
    noWeakArea: 'Bu qisqa blokda katta zaif joy topilmadi.',
    noMistakePattern: 'Takrorlanayotgan xato turi topilmadi.',
    harderSet: 'Iqtisodiyot bo‘yicha qiyinroq blokka o‘ting.',
    explainLogic: 'To‘g‘ri javoblarni qayta ko‘rib chiqing va mantiqni o‘z so‘zingiz bilan tushuntiring.',
    reviewRelatedTopic: 'Bog‘liq mavzuni qayta ko‘rib chiqing',
    trySimilar: 'Yana bitta o‘xshash savol yeching.',
    feedbackMissing: 'Diagnostik izoh hozircha mavjud emas.',
    times: 'marta',
    restart: 'Qayta o‘tish',
    backToPractice: 'Mashqqa',
  },
};

const LABELS = {
  topic: {
    Market: { en: 'Market', ru: 'Рынок', uz: 'Bozor' },
    Demand: { en: 'Demand', ru: 'Спрос', uz: 'Talab' },
    Basics: { en: 'Economics basics', ru: 'Основы экономики', uz: 'Iqtisodiyot asoslari' },
    PPC: { en: 'PPC', ru: 'Кривая производственных возможностей', uz: 'Ishlab chiqarish imkoniyatlari egri chizig‘i' },
    Elasticity: { en: 'Elasticity', ru: 'Эластичность', uz: 'Elastiklik' },
    'Government macroeconomic intervention': {
      en: 'Government macroeconomic policy',
      ru: 'Макроэкономическая политика государства',
      uz: 'Davlatning makroiqtisodiy siyosati',
    },
    'Allocative efficiency': { en: 'Allocative efficiency', ru: 'Аллокативная эффективность', uz: 'Allokativ samaradorlik' },
    'Complementary goods': { en: 'Complementary goods', ru: 'Дополняющие товары', uz: 'To‘ldiruvchi tovarlar' },
    'Consumer surplus': { en: 'Consumer surplus', ru: 'Потребительский излишек', uz: 'Iste’molchi ortiqchaligi' },
    'Income from factors of production': {
      en: 'Income from factors of production',
      ru: 'Доходы факторов производства',
      uz: 'Ishlab chiqarish omillari daromadi',
    },
    'Fiscal policy': { en: 'Fiscal policy', ru: 'Фискальная политика', uz: 'Fiskal siyosat' },
    'Opportunity cost on the PPC': {
      en: 'Opportunity cost on PPC',
      ru: 'Альтернативная стоимость на PPC',
      uz: 'PPC bo‘yicha muqobil qiymat',
    },
    'Calculating PED': { en: 'Calculating PED', ru: 'Расчёт PED', uz: 'PED hisoblash' },
  },
  skill: {
    'Allocative efficiency vs average-cost logic': {
      en: 'Allocative efficiency vs average cost',
      ru: 'Аллокативная эффективность и средние издержки',
      uz: 'Allokativ samaradorlik va o‘rtacha xarajat',
    },
    'Area position on demand diagram': {
      en: 'Area position on demand diagram',
      ru: 'Область на графике спроса',
      uz: 'Talab grafigidagi soha',
    },
    'Complement demand shift direction': {
      en: 'Direction of demand shift for complements',
      ru: 'Направление сдвига спроса у дополняющих товаров',
      uz: 'To‘ldiruvchi tovarlarda talab siljishi yo‘nalishi',
    },
    'Consumer surplus vs producer/supply area': {
      en: 'Consumer surplus vs producer area',
      ru: 'Потребительский излишек и область производителя',
      uz: 'Iste’molchi ortiqchaligi va ishlab chiqaruvchi sohasi',
    },
    'Consumer vs producer surplus': {
      en: 'Consumer surplus vs producer surplus',
      ru: 'Потребительский и производительский излишек',
      uz: 'Iste’molchi va ishlab chiqaruvchi ortiqchaligi',
    },
    'Demand shift vs elasticity terminology': {
      en: 'Demand shift vs elasticity term',
      ru: 'Сдвиг спроса и термин эластичности',
      uz: 'Talab siljishi va elastiklik termini',
    },
    'Efficiency vs profit outcome': {
      en: 'Efficiency vs profit result',
      ru: 'Эффективность и результат прибыли',
      uz: 'Samaradorlik va foyda natijasi',
    },
    'Enterprise vs capital reward': {
      en: 'Enterprise vs capital reward',
      ru: 'Доход предпринимательства и капитала',
      uz: 'Tadbirkorlik va kapital daromadi',
    },
    'Fiscal vs monetary policy': {
      en: 'Fiscal policy vs monetary policy',
      ru: 'Фискальная и монетарная политика',
      uz: 'Fiskal va monetar siyosat',
    },
    'Labour vs capital reward': {
      en: 'Labour vs capital reward',
      ru: 'Доход труда и капитала',
      uz: 'Mehnat va kapital daromadi',
    },
    'Land vs capital reward': {
      en: 'Land vs capital reward',
      ru: 'Доход земли и капитала',
      uz: 'Yer va kapital daromadi',
    },
    'Macroeconomic policy categories': {
      en: 'Macroeconomic policy categories',
      ru: 'Категории макроэкономической политики',
      uz: 'Makroiqtisodiy siyosat turlari',
    },
    'Market supply misconception': {
      en: 'Misconception about market supply',
      ru: 'Неверное понимание предложения',
      uz: 'Taklif haqida noto‘g‘ri tushuncha',
    },
    'Opportunity cost calculation': {
      en: 'Opportunity cost calculation',
      ru: 'Расчёт альтернативной стоимости',
      uz: 'Muqobil qiymatni hisoblash',
    },
    'PED calculation': { en: 'PED calculation', ru: 'Расчёт PED', uz: 'PED hisoblash' },
    'Policy instrument recognition': {
      en: 'Recognising policy instruments',
      ru: 'Распознавание инструментов политики',
      uz: 'Siyosat instrumentlarini tanish',
    },
    'Related goods effect': {
      en: 'Effect of related goods',
      ru: 'Влияние связанных товаров',
      uz: 'Bog‘liq tovarlar ta’siri',
    },
  },
  mistake: {
    concept_confusion: { en: 'Concept confusion', ru: 'Путаница понятий', uz: 'Tushuncha chalkashligi' },
    diagram_area_direction: { en: 'Diagram area error', ru: 'Ошибка области на графике', uz: 'Diagrammadagi soha xatosi' },
    direction_error: { en: 'Direction error', ru: 'Ошибка направления', uz: 'Yo‘nalish xatosi' },
    diagram_area_confusion: { en: 'Diagram area confusion', ru: 'Путаница областей на графике', uz: 'Diagramma sohalarini adashtirish' },
    producer_surplus_confusion: {
      en: 'Consumer/producer surplus confusion',
      ru: 'Путаница потребительского и производительского излишка',
      uz: 'Iste’molchi va ishlab chiqaruvchi ortiqchaligi chalkashligi',
    },
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
  currentAnswered: false,
  results: [],
};

const els = {
  startScreen: document.getElementById('practice-start-screen'),
  quizScreen: document.getElementById('practice-quiz-screen'),
  resultScreen: document.getElementById('practice-result-screen'),
  startTitle: document.getElementById('start-title'),
  startSubtitle: document.getElementById('start-subtitle'),
  tourPickerTitle: document.getElementById('tour-picker-title'),
  tourActiveChip: document.getElementById('tour-active-chip'),
  heroSubjectLabel: document.getElementById('hero-subject-label'),
  heroSubjectTitle: document.getElementById('hero-subject-title'),
  heroStageMeta: document.getElementById('hero-stage-meta'),
  bestResultLabel: document.getElementById('best-result-label'),
  bestTimeLabel: document.getElementById('best-time-label'),
  lastAttemptsTitle: document.getElementById('last-attempts-title'),
  lastAttemptsEmpty: document.getElementById('last-attempts-empty'),
  colDate: document.getElementById('col-date'),
  colScore: document.getElementById('col-score'),
  colTime: document.getElementById('col-time'),
  startDemo: document.getElementById('start-demo'),
  qno: document.getElementById('practice-qno'),
  timer: document.getElementById('practice-timer'),
  pauseBtn: document.getElementById('practice-pause-btn'),
  questionText: document.getElementById('question-text'),
  questionDifficulty: document.getElementById('question-difficulty'),
  optionsList: document.getElementById('options-list'),
  inputWrap: document.getElementById('input-wrap'),
  inputLabel: document.getElementById('input-label'),
  inputAnswer: document.getElementById('input-answer'),
  submitButton: document.getElementById('submit-answer'),
  feedbackCard: document.getElementById('feedback-card'),
  feedbackTitle: document.getElementById('feedback-title'),
  feedbackText: document.getElementById('feedback-text'),
  weakAreaLabel: document.getElementById('weak-area-label'),
  weakArea: document.getElementById('weak-area'),
  nextActionLabel: document.getElementById('next-action-label'),
  nextAction: document.getElementById('next-action'),
  nextButton: document.getElementById('next-question'),
  resultTitle: document.getElementById('result-title'),
  resultMeta: document.getElementById('practice-result-meta'),
  resultScoreLabel: document.getElementById('result-score-label'),
  summaryScore: document.getElementById('summary-score'),
  summaryCount: document.getElementById('summary-count'),
  summaryWeakTitle: document.getElementById('summary-weak-title'),
  summaryMistakeTitle: document.getElementById('summary-mistake-title'),
  summaryPlanTitle: document.getElementById('summary-plan-title'),
  summaryWeakList: document.getElementById('summary-weak-list'),
  summaryMistakeList: document.getElementById('summary-mistake-list'),
  summaryPlanList: document.getElementById('summary-plan-list'),
  restartButton: document.getElementById('restart-demo'),
  backToStart: document.getElementById('back-to-start'),
  languageButtons: document.querySelectorAll('.language-btn'),
};

function copy() {
  return COPY[state.lang] || COPY.ru;
}

function showScreen(name) {
  state.screen = name;
  els.startScreen.classList.toggle('hidden', name !== 'start');
  els.quizScreen.classList.toggle('hidden', name !== 'quiz');
  els.resultScreen.classList.toggle('hidden', name !== 'result');
}

function localField(base, lang = state.lang) {
  return `${base}_${lang}`;
}

function displayLabel(value, group = 'topic') {
  if (!value) return '';
  return LABELS[group]?.[value]?.[state.lang] || LABELS[group]?.[value]?.ru || LABELS[group]?.[value]?.en || value;
}

function parseOptions(rawOptions) {
  if (!rawOptions) return [];
  if (Array.isArray(rawOptions)) return rawOptions;
  try {
    const parsed = JSON.parse(rawOptions);
    return Array.isArray(parsed) ? parsed : [];
  } catch (_) {
    return String(rawOptions)
      .split('|')
      .map((item) => item.trim())
      .filter(Boolean);
  }
}

function getText(row, fieldBase) {
  return (
    row?.[localField(fieldBase)] ||
    row?.[`${fieldBase}_ru`] ||
    row?.[`${fieldBase}_en`] ||
    row?.[`${fieldBase}_uz`] ||
    row?.[fieldBase] ||
    ''
  );
}

function getResultText(result, fieldBase) {
  return (
    result?.[localField(fieldBase)] ||
    result?.[`${fieldBase}_ru`] ||
    result?.[`${fieldBase}_en`] ||
    result?.[`${fieldBase}_uz`] ||
    ''
  );
}

function formatMMSS(seconds) {
  const s = Math.max(0, Number(seconds) || 0);
  const mm = Math.floor(s / 60);
  const ss = s % 60;
  return `${String(mm).padStart(2, '0')}:${String(ss).padStart(2, '0')}`;
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
  els.weakAreaLabel.textContent = t.weakArea;
  els.nextActionLabel.textContent = t.nextAction;
  els.resultTitle.textContent = t.resultTitle;
  els.resultScoreLabel.textContent = t.resultScoreLabel;
  els.summaryWeakTitle.textContent = t.mainWeakAreas;
  els.summaryMistakeTitle.textContent = t.mistakePattern;
  els.summaryPlanTitle.textContent = t.nextStudyPlan;
  els.restartButton.textContent = t.restart;
  els.backToStart.textContent = t.backToPractice;
}

function setSubmitReady(ready) {
  els.submitButton.disabled = !ready;
  els.submitButton.classList.toggle('is-ready', !!ready);
}

function difficultyLabel(difficulty) {
  const key = `difficulty_${String(difficulty || '').toLowerCase()}`;
  return copy()[key] || difficulty || '';
}

async function loadQuestions() {
  updateStaticCopy();
  els.startDemo.disabled = true;
  els.startDemo.textContent = copy().loading;

  const { data, error } = await client.rpc('get_safe_questions_by_ids', {
    p_question_ids: PILOT_QUESTION_IDS,
  });

  if (error) {
    console.error(error);
    els.startDemo.textContent = copy().loadError;
    return;
  }

  state.questions = [...(data || [])].sort((a, b) => {
    const aOrder = a.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(a.id));
    const bOrder = b.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(b.id));
    return aOrder - bOrder;
  });

  els.startDemo.disabled = !state.questions.length;
  els.startDemo.textContent = state.questions.length ? copy().start : copy().loadError;
  updateStaticCopy();
}

function renderQuestion({ reset = true } = {}) {
  const t = copy();
  const question = state.questions[state.currentIndex];

  if (!question) {
    renderSummary();
    return;
  }

  if (reset) {
    state.selectedOptionIndex = null;
    state.currentAnswered = false;
    els.inputAnswer.value = '';
    els.feedbackCard.classList.add('hidden');
  }

  els.qno.textContent = `${state.currentIndex + 1}/${state.questions.length}`;
  els.timer.textContent = formatMMSS(Number(question.time_limit_sec || question.timeLimitSec || 58));
  els.questionText.textContent = getText(question, 'question_text') || t.questionPlaceholder;
  els.questionDifficulty.textContent = `${t.difficulty}: ${difficultyLabel(question.difficulty)}`;
  els.submitButton.textContent = state.currentAnswered ? t.answerChecked : t.answer;
  setSubmitReady(!state.currentAnswered && hasCurrentAnswer());

  els.optionsList.innerHTML = '';

  if (String(question.qtype || '').toLowerCase() === 'input') {
    els.inputWrap.classList.remove('hidden');
    els.inputAnswer.disabled = state.currentAnswered;
    return;
  }

  els.inputWrap.classList.add('hidden');

  const optionItems = parseOptions(getText(question, 'options_text'));
  optionItems.forEach((option, index) => {
    const row = document.createElement('label');
    row.className = `option-row${state.selectedOptionIndex === index ? ' is-selected' : ''}${state.currentAnswered ? ' is-disabled' : ''}`;
    row.innerHTML = `
      <input type="radio" name="diagnostic-option" value="${index}" ${state.selectedOptionIndex === index ? 'checked' : ''} ${state.currentAnswered ? 'disabled' : ''}>
      <span>${String.fromCharCode(65 + index)}. ${escapeHtml(option)}</span>
    `;
    const input = row.querySelector('input');
    input?.addEventListener('change', () => {
      if (state.currentAnswered) return;
      state.selectedOptionIndex = index;
      renderQuestion({ reset: false });
    });
    els.optionsList.appendChild(row);
  });
}

function hasCurrentAnswer() {
  const question = state.questions[state.currentIndex];
  if (!question) return false;
  if (String(question.qtype || '').toLowerCase() === 'input') {
    return !!String(els.inputAnswer.value || '').trim();
  }
  return state.selectedOptionIndex !== null && state.selectedOptionIndex !== undefined;
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

function startDemo() {
  if (!state.questions.length) return;
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.currentAnswered = false;
  state.results = [];
  showScreen('quiz');
  renderQuestion({ reset: true });
}

async function submitAnswer() {
  const t = copy();
  const question = state.questions[state.currentIndex];
  if (!question || state.currentAnswered) return;

  const isInput = String(question.qtype || '').toLowerCase() === 'input';
  const userAnswer = isInput ? els.inputAnswer.value.trim() : null;

  if (isInput && !userAnswer) {
    alert(t.typeAnswer);
    return;
  }

  if (!isInput && state.selectedOptionIndex === null) {
    alert(t.chooseOption);
    return;
  }

  els.submitButton.disabled = true;
  els.submitButton.textContent = t.checking;

  const { data, error } = await client.rpc('evaluate_diagnostic_demo_answer', {
    p_question_id: Number(question.id),
    p_user_answer: userAnswer,
    p_picked_index: isInput ? null : state.selectedOptionIndex,
  });

  if (error) {
    console.error(error);
    alert(t.checkError);
    renderQuestion({ reset: false });
    return;
  }

  const result = data || {};
  state.currentAnswered = true;
  state.results.push({ question, result });
  renderQuestion({ reset: false });
  renderFeedback(result);
  updateStaticCopy();
}

function renderFeedback(result) {
  const t = copy();
  const correct = Boolean(result.is_correct);
  const area = [displayLabel(result.recommended_topic, 'topic'), displayLabel(result.recommended_subtopic, 'topic')]
    .filter(Boolean)
    .join(' / ');

  els.feedbackTitle.textContent = correct ? t.correct : t.needsRevision;
  els.feedbackTitle.className = `feedback-title ${correct ? 'good' : 'bad'}`;
  els.feedbackText.textContent = getResultText(result, 'feedback') || t.feedbackMissing;
  els.weakArea.textContent = displayLabel(result.weak_skill, 'skill') || area || t.reviewRelatedTopic;
  els.nextAction.textContent = getResultText(result, 'next_action') || t.trySimilar;
  els.nextButton.textContent = state.currentIndex + 1 >= state.questions.length ? t.showResult : t.nextQuestion;
  els.feedbackCard.classList.remove('hidden');
}

function goNext() {
  if (!state.currentAnswered) return;
  state.currentIndex += 1;
  if (state.currentIndex >= state.questions.length) {
    renderSummary();
    return;
  }
  renderQuestion({ reset: true });
}

function countBy(items, getKey) {
  const map = new Map();
  items.forEach((item) => {
    const key = getKey(item);
    if (!key) return;
    map.set(key, (map.get(key) || 0) + 1);
  });
  return [...map.entries()].sort((a, b) => b[1] - a[1]);
}

function fillList(listEl, items, fallbackText) {
  listEl.innerHTML = '';

  if (!items.length) {
    const item = document.createElement('li');
    item.textContent = fallbackText;
    listEl.appendChild(item);
    return;
  }

  items.slice(0, 4).forEach(([label, count]) => {
    const item = document.createElement('li');
    item.textContent = count > 1 ? `${label} (${count} ${copy().times})` : label;
    listEl.appendChild(item);
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

  planItems.slice(0, 4).forEach((text) => {
    const item = document.createElement('li');
    item.textContent = text;
    els.summaryPlanList.appendChild(item);
  });
}

function renderSummary() {
  const t = copy();
  const total = state.results.length;
  const correctCount = state.results.filter(({ result }) => Boolean(result.is_correct)).length;
  const percent = total ? Math.round((correctCount / total) * 100) : 0;
  const wrongResults = state.results.filter(({ result }) => !Boolean(result.is_correct));

  showScreen('result');

  const weakAreas = countBy(wrongResults, ({ result }) => {
    return (
      displayLabel(result.weak_skill, 'skill') ||
      [displayLabel(result.recommended_topic, 'topic'), displayLabel(result.recommended_subtopic, 'topic')]
        .filter(Boolean)
        .join(' / ')
    );
  });

  const mistakeTypes = countBy(wrongResults, ({ result }) => displayLabel(result.mistake_type, 'mistake'));

  els.summaryScore.textContent = `${percent}%`;
  els.summaryCount.textContent = `${correctCount} / ${total}`;
  els.resultMeta.textContent = t.resultMeta(correctCount, total, percent, wrongResults.length, weakAreas.length);
  fillList(els.summaryWeakList, weakAreas, t.noWeakArea);
  fillList(els.summaryMistakeList, mistakeTypes, t.noMistakePattern);
  fillPlanList(wrongResults);
}

function resetToStart() {
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.currentAnswered = false;
  state.results = [];
  els.feedbackCard.classList.add('hidden');
  showScreen('start');
  updateStaticCopy();
}

function setLanguage(lang) {
  if (!COPY[lang]) return;
  state.lang = lang;
  els.languageButtons.forEach((button) => {
    button.classList.toggle('active', button.dataset.lang === lang);
  });
  updateStaticCopy();

  if (state.screen === 'quiz') {
    renderQuestion({ reset: false });
    const last = state.currentAnswered ? state.results[state.results.length - 1] : null;
    if (last) renderFeedback(last.result);
  }

  if (state.screen === 'result') {
    renderSummary();
  }
}

els.startDemo.addEventListener('click', startDemo);
els.submitButton.addEventListener('click', submitAnswer);
els.nextButton.addEventListener('click', goNext);
els.restartButton.addEventListener('click', startDemo);
els.backToStart.addEventListener('click', resetToStart);
els.pauseBtn.addEventListener('click', () => null);
els.inputAnswer.addEventListener('input', () => setSubmitReady(hasCurrentAnswer() && !state.currentAnswered));
els.inputAnswer.addEventListener('keydown', (event) => {
  if (event.key === 'Enter' && hasCurrentAnswer()) submitAnswer();
});
els.languageButtons.forEach((button) => {
  button.addEventListener('click', () => setLanguage(button.dataset.lang));
});

updateStaticCopy();
showScreen('start');
loadQuestions();
