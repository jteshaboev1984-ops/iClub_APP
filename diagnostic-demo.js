// Hidden President Tech Award diagnostic demo.
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
    heroLabel: 'Diagnostic Practice Demo',
    heroTitle: 'iClub Diagnostic Learning Engine',
    heroCopy:
      'Answer a short Economics set. After each answer, iClub explains the mistake and builds a personal mini study plan. Demo results are not saved to student history.',
    loading: 'Loading diagnostic practice…',
    progress: 'Progress',
    inputLabel: 'Your answer',
    inputPlaceholder: 'Type your answer',
    checkAnswer: 'Check answer',
    answerChecked: 'Answer checked',
    correct: 'Correct',
    needsRevision: 'Needs revision',
    weakArea: 'Weak area',
    nextAction: 'Next action',
    nextQuestion: 'Next question',
    showSummary: 'Show summary',
    chooseOption: 'Please choose one option first.',
    typeAnswer: 'Please type your answer first.',
    checking: 'Checking your answer…',
    checkError: 'Could not check the answer. Please try again.',
    loadError: 'Could not load the diagnostic practice. Please check the connection.',
    noQuestions: 'No pilot questions were returned.',
    questionOf: (current, total) => `Question ${current} of ${total}`,
    questionChecked: (current) => `Question ${current} checked`,
    summaryReadyStatus: 'Diagnostic summary is ready',
    summaryLabel: 'Diagnostic Summary',
    summaryTitle: 'Your mini study plan is ready',
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
    restart: 'Restart demo',
  },
  ru: {
    heroLabel: 'Демо диагностической практики',
    heroTitle: 'iClub Diagnostic Learning Engine',
    heroCopy:
      'Ответь на короткий блок по экономике. После каждого ответа iClub объясняет ошибку и собирает личный мини-план подготовки. Результаты demo не сохраняются в историю ученика.',
    loading: 'Загружается диагностическая практика…',
    progress: 'Прогресс',
    inputLabel: 'Твой ответ',
    inputPlaceholder: 'Введи ответ',
    checkAnswer: 'Проверить ответ',
    answerChecked: 'Ответ проверен',
    correct: 'Верно',
    needsRevision: 'Нужно повторить',
    weakArea: 'Слабое место',
    nextAction: 'Следующий шаг',
    nextQuestion: 'Следующий вопрос',
    showSummary: 'Показать итог',
    chooseOption: 'Сначала выбери один вариант ответа.',
    typeAnswer: 'Сначала введи ответ.',
    checking: 'Проверяем ответ…',
    checkError: 'Не удалось проверить ответ. Попробуй ещё раз.',
    loadError: 'Не удалось загрузить диагностическую практику. Проверь соединение.',
    noQuestions: 'Вопросы pilot не вернулись.',
    questionOf: (current, total) => `Вопрос ${current} из ${total}`,
    questionChecked: (current) => `Вопрос ${current} проверен`,
    summaryReadyStatus: 'Диагностический итог готов',
    summaryLabel: 'Диагностический итог',
    summaryTitle: 'Твой мини-план подготовки готов',
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
    restart: 'Начать заново',
  },
  uz: {
    heroLabel: 'Diagnostik mashq demo',
    heroTitle: 'iClub Diagnostic Learning Engine',
    heroCopy:
      'Iqtisodiyot bo‘yicha qisqa blokni yeching. Har bir javobdan keyin iClub xatoni tushuntiradi va shaxsiy mini tayyorgarlik rejasini tuzadi. Demo natijalari o‘quvchi tarixiga saqlanmaydi.',
    loading: 'Diagnostik mashq yuklanmoqda…',
    progress: 'Jarayon',
    inputLabel: 'Javobingiz',
    inputPlaceholder: 'Javobni kiriting',
    checkAnswer: 'Javobni tekshirish',
    answerChecked: 'Javob tekshirildi',
    correct: 'To‘g‘ri',
    needsRevision: 'Qayta ko‘rib chiqish kerak',
    weakArea: 'Zaif joy',
    nextAction: 'Keyingi qadam',
    nextQuestion: 'Keyingi savol',
    showSummary: 'Natijani ko‘rsatish',
    chooseOption: 'Avval bitta javob variantini tanlang.',
    typeAnswer: 'Avval javobni kiriting.',
    checking: 'Javob tekshirilmoqda…',
    checkError: 'Javobni tekshirib bo‘lmadi. Qayta urinib ko‘ring.',
    loadError: 'Diagnostik mashq yuklanmadi. Internet aloqasini tekshiring.',
    noQuestions: 'Pilot savollar qaytmadi.',
    questionOf: (current, total) => `Savol ${current} / ${total}`,
    questionChecked: (current) => `${current}-savol tekshirildi`,
    summaryReadyStatus: 'Diagnostik natija tayyor',
    summaryLabel: 'Diagnostik natija',
    summaryTitle: 'Mini tayyorgarlik rejangiz tayyor',
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
    restart: 'Qayta boshlash',
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
  lang: 'en',
  questions: [],
  currentIndex: 0,
  selectedOptionIndex: null,
  currentAnswered: false,
  results: [],
};

const statusEl = document.getElementById('demo-status');
const progressCard = document.getElementById('progress-card');
const progressLabel = document.getElementById('progress-label');
const progressCount = document.getElementById('progress-count');
const progressFill = document.getElementById('progress-fill');
const questionCard = document.getElementById('question-card');
const questionMeta = document.getElementById('question-meta');
const questionText = document.getElementById('question-text');
const optionsList = document.getElementById('options-list');
const inputWrap = document.getElementById('input-wrap');
const inputLabel = document.getElementById('input-label');
const inputAnswer = document.getElementById('input-answer');
const submitButton = document.getElementById('submit-answer');
const feedbackCard = document.getElementById('feedback-card');
const feedbackTitle = document.getElementById('feedback-title');
const feedbackText = document.getElementById('feedback-text');
const weakAreaLabel = document.getElementById('weak-area-label');
const weakArea = document.getElementById('weak-area');
const nextActionLabel = document.getElementById('next-action-label');
const nextAction = document.getElementById('next-action');
const nextButton = document.getElementById('next-question');
const summaryCard = document.getElementById('summary-card');
const summaryLabel = document.getElementById('summary-label');
const summaryTitle = document.getElementById('summary-title');
const summaryScore = document.getElementById('summary-score');
const summaryCount = document.getElementById('summary-count');
const summaryWeakTitle = document.getElementById('summary-weak-title');
const summaryMistakeTitle = document.getElementById('summary-mistake-title');
const summaryPlanTitle = document.getElementById('summary-plan-title');
const summaryWeakList = document.getElementById('summary-weak-list');
const summaryMistakeList = document.getElementById('summary-mistake-list');
const summaryPlanList = document.getElementById('summary-plan-list');
const restartButton = document.getElementById('restart-demo');
const languageButtons = document.querySelectorAll('.language-btn');

function copy() {
  return COPY[state.lang] || COPY.en;
}

function localField(base, lang = state.lang) {
  return `${base}_${lang}`;
}

function displayLabel(value, group = 'topic') {
  if (!value) return '';
  return LABELS[group]?.[value]?.[state.lang] || LABELS[group]?.[value]?.en || value;
}

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.borderColor = isError ? '#fed7aa' : '';
  statusEl.style.background = isError ? '#fff7ed' : '';
}

function updateStaticCopy() {
  const t = copy();
  document.documentElement.lang = state.lang;
  document.getElementById('hero-label').textContent = t.heroLabel;
  document.getElementById('hero-title').textContent = t.heroTitle;
  document.getElementById('hero-copy').textContent = t.heroCopy;
  progressLabel.textContent = t.progress;
  inputLabel.textContent = t.inputLabel;
  inputAnswer.placeholder = t.inputPlaceholder;
  weakAreaLabel.textContent = t.weakArea;
  nextActionLabel.textContent = t.nextAction;
  summaryLabel.textContent = t.summaryLabel;
  summaryTitle.textContent = t.summaryTitle;
  summaryWeakTitle.textContent = t.mainWeakAreas;
  summaryMistakeTitle.textContent = t.mistakePattern;
  summaryPlanTitle.textContent = t.nextStudyPlan;
  restartButton.textContent = t.restart;
}

function updateProgress() {
  const total = state.questions.length || PILOT_QUESTION_IDS.length;
  const done = Math.min(state.results.length, total);
  const percent = total ? Math.round((done / total) * 100) : 0;
  progressCount.textContent = `${done} / ${total}`;
  progressFill.style.width = `${percent}%`;
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
    row[localField(fieldBase)] ||
    row[`${fieldBase}_en`] ||
    row[`${fieldBase}_ru`] ||
    row[`${fieldBase}_uz`] ||
    row[fieldBase] ||
    ''
  );
}

function getResultText(result, fieldBase) {
  return (
    result[localField(fieldBase)] ||
    result[`${fieldBase}_en`] ||
    result[`${fieldBase}_ru`] ||
    result[`${fieldBase}_uz`] ||
    ''
  );
}

function setAnswerControlsDisabled(disabled) {
  submitButton.disabled = disabled;
  inputAnswer.disabled = disabled;
  document.querySelectorAll('.option-btn').forEach((button) => {
    button.disabled = disabled;
  });
}

function renderQuestion(options = {}) {
  const { reset = true } = options;
  const t = copy();
  const question = state.questions[state.currentIndex];

  if (reset) {
    state.selectedOptionIndex = null;
    state.currentAnswered = false;
    inputAnswer.value = '';
    feedbackCard.classList.add('hidden');
  }

  inputAnswer.disabled = state.currentAnswered;
  summaryCard.classList.add('hidden');
  progressCard.classList.remove('hidden');
  updateProgress();

  if (!question) {
    renderSummary();
    return;
  }

  questionCard.classList.remove('hidden');
  submitButton.textContent = state.currentAnswered ? t.answerChecked : t.checkAnswer;
  submitButton.disabled = state.currentAnswered;

  questionMeta.innerHTML = '';
  [question.topic, question.subtopic]
    .filter(Boolean)
    .forEach((value) => {
      const pill = document.createElement('span');
      pill.className = 'meta-pill';
      pill.textContent = displayLabel(value, 'topic');
      questionMeta.appendChild(pill);
    });

  questionText.textContent = getText(question, 'question_text');
  optionsList.innerHTML = '';

  if (question.qtype === 'input') {
    inputWrap.classList.remove('hidden');
    optionsList.classList.add('hidden');
  } else {
    inputWrap.classList.add('hidden');
    optionsList.classList.remove('hidden');

    const optionItems = parseOptions(getText(question, 'options_text'));
    optionItems.forEach((option, index) => {
      const button = document.createElement('button');
      button.type = 'button';
      button.className = `option-btn${state.selectedOptionIndex === index ? ' selected' : ''}`;
      button.textContent = `${String.fromCharCode(65 + index)}. ${option}`;
      button.disabled = state.currentAnswered;
      button.addEventListener('click', () => {
        if (state.currentAnswered) return;
        state.selectedOptionIndex = index;
        document.querySelectorAll('.option-btn').forEach((node) => node.classList.remove('selected'));
        button.classList.add('selected');
      });
      optionsList.appendChild(button);
    });
  }

  if (!state.currentAnswered) {
    setStatus(t.questionOf(state.currentIndex + 1, state.questions.length));
  }
}

async function loadQuestions() {
  setStatus(copy().loading);
  updateProgress();

  const { data, error } = await client.rpc('get_safe_questions_by_ids', {
    p_question_ids: PILOT_QUESTION_IDS,
  });

  if (error) {
    console.error(error);
    setStatus(copy().loadError, true);
    return;
  }

  state.questions = [...(data || [])].sort((a, b) => {
    const aOrder = a.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(a.id));
    const bOrder = b.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(b.id));
    return aOrder - bOrder;
  });

  if (!state.questions.length) {
    setStatus(copy().noQuestions, true);
    return;
  }

  renderQuestion({ reset: true });
}

function renderFeedback(result) {
  const t = copy();
  const correct = Boolean(result.is_correct);
  const area = [displayLabel(result.recommended_topic, 'topic'), displayLabel(result.recommended_subtopic, 'topic')]
    .filter(Boolean)
    .join(' / ');

  feedbackTitle.textContent = correct ? t.correct : t.needsRevision;
  feedbackTitle.className = `feedback-title ${correct ? 'good' : 'bad'}`;
  feedbackText.textContent = getResultText(result, 'feedback') || t.feedbackMissing;
  weakArea.textContent = displayLabel(result.weak_skill, 'skill') || area || t.reviewRelatedTopic;
  nextAction.textContent = getResultText(result, 'next_action') || t.trySimilar;
  nextButton.textContent = state.currentIndex + 1 >= state.questions.length ? t.showSummary : t.nextQuestion;
  feedbackCard.classList.remove('hidden');
  setStatus(t.questionChecked(state.currentIndex + 1));
}

async function submitAnswer() {
  const t = copy();
  const question = state.questions[state.currentIndex];
  if (!question || state.currentAnswered) return;

  const isInput = question.qtype === 'input';
  const userAnswer = isInput ? inputAnswer.value.trim() : null;

  if (isInput && !userAnswer) {
    setStatus(t.typeAnswer, true);
    return;
  }

  if (!isInput && state.selectedOptionIndex === null) {
    setStatus(t.chooseOption, true);
    return;
  }

  submitButton.disabled = true;
  setStatus(t.checking);

  const { data, error } = await client.rpc('evaluate_diagnostic_demo_answer', {
    p_question_id: Number(question.id),
    p_user_answer: userAnswer,
    p_picked_index: isInput ? null : state.selectedOptionIndex,
  });

  if (error) {
    console.error(error);
    submitButton.disabled = false;
    setStatus(t.checkError, true);
    return;
  }

  const result = data || {};
  state.currentAnswered = true;
  state.results.push({ question, result });
  updateProgress();
  renderQuestion({ reset: false });
  setAnswerControlsDisabled(true);
  renderFeedback(result);
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
  summaryPlanList.innerHTML = '';
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
    summaryPlanList.appendChild(item);
  });
}

function renderSummary() {
  const t = copy();
  const total = state.results.length;
  const correctCount = state.results.filter(({ result }) => Boolean(result.is_correct)).length;
  const percent = total ? Math.round((correctCount / total) * 100) : 0;
  const wrongResults = state.results.filter(({ result }) => !Boolean(result.is_correct));

  questionCard.classList.add('hidden');
  feedbackCard.classList.add('hidden');
  summaryCard.classList.remove('hidden');
  updateProgress();
  setStatus(t.summaryReadyStatus);

  summaryScore.textContent = `${percent}%`;
  summaryCount.textContent = `${correctCount} / ${total}`;

  const weakAreas = countBy(wrongResults, ({ result }) => {
    return (
      displayLabel(result.weak_skill, 'skill') ||
      [displayLabel(result.recommended_topic, 'topic'), displayLabel(result.recommended_subtopic, 'topic')]
        .filter(Boolean)
        .join(' / ')
    );
  });

  const mistakeTypes = countBy(wrongResults, ({ result }) => {
    return displayLabel(result.mistake_type, 'mistake');
  });

  fillList(summaryWeakList, weakAreas, t.noWeakArea);
  fillList(summaryMistakeList, mistakeTypes, t.noMistakePattern);
  fillPlanList(wrongResults);
}

function goNext() {
  if (!state.currentAnswered) return;
  state.currentIndex += 1;
  renderQuestion({ reset: true });
}

function restartDemo() {
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.currentAnswered = false;
  state.results = [];
  renderQuestion({ reset: true });
}

function setLanguage(lang) {
  if (!COPY[lang]) return;
  state.lang = lang;
  languageButtons.forEach((button) => {
    button.classList.toggle('active', button.dataset.lang === lang);
  });
  updateStaticCopy();

  if (!state.questions.length) {
    setStatus(copy().loading);
    return;
  }

  if (!summaryCard.classList.contains('hidden')) {
    renderSummary();
    return;
  }

  renderQuestion({ reset: false });
  const last = state.currentAnswered ? state.results[state.results.length - 1] : null;
  if (last) renderFeedback(last.result);
}

submitButton.addEventListener('click', submitAnswer);
nextButton.addEventListener('click', goNext);
restartButton.addEventListener('click', restartDemo);
inputAnswer.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') submitAnswer();
});
languageButtons.forEach((button) => {
  button.addEventListener('click', () => setLanguage(button.dataset.lang));
});

updateStaticCopy();
loadQuestions();
