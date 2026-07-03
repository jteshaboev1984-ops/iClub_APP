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
    nextStudyPlan: 'Keyingi o‘quv reja',
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
  submitButton.textContent = t.checkAnswer;
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

function renderQuestion() {
  const t = copy();
  const question = state.questions[state.currentIndex];
  state.selectedOptionIndex = null;
  state.currentAnswered = false;
  inputAnswer.value = '';
  inputAnswer.disabled = false;
  feedbackCard.classList.add('hidden');
  summaryCard.classList.add('hidden');
  progressCard.classList.remove('hidden');
  updateProgress();

  if (!question) {
    renderSummary();
    return;
  }

  setStatus(t.questionOf(state.currentIndex + 1, state.questions.length));
  questionCard.classList.remove('hidden');
  submitButton.disabled = false;
  submitButton.textContent = t.checkAnswer;

  questionMeta.innerHTML = '';
  [question.topic, question.subtopic]
    .filter(Boolean)
    .forEach((value) => {
      const pill = document.createElement('span');
      pill.className = 'meta-pill';
      pill.textContent = value;
      questionMeta.appendChild(pill);
    });

  questionText.textContent = getText(question, 'question_text');
  optionsList.innerHTML = '';

  if (question.qtype === 'input') {
    inputWrap.classList.remove('hidden');
    optionsList.classList.add('hidden');
    return;
  }

  inputWrap.classList.add('hidden');
  optionsList.classList.remove('hidden');

  const options = parseOptions(getText(question, 'options_text'));

  options.forEach((option, index) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'option-btn';
    button.textContent = `${String.fromCharCode(65 + index)}. ${option}`;
    button.addEventListener('click', () => {
      if (state.currentAnswered) return;
      state.selectedOptionIndex = index;
      document.querySelectorAll('.option-btn').forEach((node) => node.classList.remove('selected'));
      button.classList.add('selected');
    });
    optionsList.appendChild(button);
  });
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

  renderQuestion();
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
  const correct = Boolean(result.is_correct);
  state.currentAnswered = true;
  state.results.push({ question, result });
  updateProgress();
  setAnswerControlsDisabled(true);

  feedbackTitle.textContent = correct ? t.correct : t.needsRevision;
  feedbackTitle.className = `feedback-title ${correct ? 'good' : 'bad'}`;
  feedbackText.textContent = getResultText(result, 'feedback') || t.feedbackMissing;

  const area = [result.recommended_topic, result.recommended_subtopic].filter(Boolean).join(' / ');
  weakArea.textContent = result.weak_skill || area || t.reviewRelatedTopic;
  nextAction.textContent = getResultText(result, 'next_action') || t.trySimilar;

  nextButton.textContent = state.currentIndex + 1 >= state.questions.length ? t.showSummary : t.nextQuestion;
  feedbackCard.classList.remove('hidden');
  setStatus(t.questionChecked(state.currentIndex + 1));
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
    return result.weak_skill || [result.recommended_topic, result.recommended_subtopic].filter(Boolean).join(' / ');
  });

  const mistakeTypes = countBy(wrongResults, ({ result }) => {
    if (!result.mistake_type) return null;
    return result.mistake_type.replaceAll('_', ' ');
  });

  fillList(summaryWeakList, weakAreas, t.noWeakArea);
  fillList(summaryMistakeList, mistakeTypes, t.noMistakePattern);
  fillPlanList(wrongResults);
}

function goNext() {
  if (!state.currentAnswered) return;
  state.currentIndex += 1;
  renderQuestion();
}

function restartDemo() {
  state.currentIndex = 0;
  state.selectedOptionIndex = null;
  state.currentAnswered = false;
  state.results = [];
  renderQuestion();
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

  const hasSummary = !summaryCard.classList.contains('hidden');
  const hasFeedback = !feedbackCard.classList.contains('hidden');

  if (hasSummary) {
    renderSummary();
  } else if (hasFeedback) {
    const last = state.results[state.results.length - 1];
    if (last) {
      const correct = Boolean(last.result.is_correct);
      feedbackTitle.textContent = correct ? copy().correct : copy().needsRevision;
      feedbackText.textContent = getResultText(last.result, 'feedback') || copy().feedbackMissing;
      nextAction.textContent = getResultText(last.result, 'next_action') || copy().trySimilar;
      nextButton.textContent = state.currentIndex + 1 >= state.questions.length ? copy().showSummary : copy().nextQuestion;
      setStatus(copy().questionChecked(state.currentIndex + 1));
    }
    questionText.textContent = getText(state.questions[state.currentIndex], 'question_text');
  } else {
    renderQuestion();
  }
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
