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

const state = {
  questions: [],
  currentIndex: 0,
  selectedOptionIndex: null,
  currentAnswered: false,
  results: [],
};

const statusEl = document.getElementById('demo-status');
const progressCard = document.getElementById('progress-card');
const progressCount = document.getElementById('progress-count');
const progressFill = document.getElementById('progress-fill');
const questionCard = document.getElementById('question-card');
const questionMeta = document.getElementById('question-meta');
const questionText = document.getElementById('question-text');
const optionsList = document.getElementById('options-list');
const inputWrap = document.getElementById('input-wrap');
const inputAnswer = document.getElementById('input-answer');
const submitButton = document.getElementById('submit-answer');
const feedbackCard = document.getElementById('feedback-card');
const feedbackTitle = document.getElementById('feedback-title');
const feedbackText = document.getElementById('feedback-text');
const weakArea = document.getElementById('weak-area');
const nextAction = document.getElementById('next-action');
const nextButton = document.getElementById('next-question');
const summaryCard = document.getElementById('summary-card');
const summaryScore = document.getElementById('summary-score');
const summaryCount = document.getElementById('summary-count');
const summaryWeakList = document.getElementById('summary-weak-list');
const summaryMistakeList = document.getElementById('summary-mistake-list');
const summaryPlanList = document.getElementById('summary-plan-list');
const restartButton = document.getElementById('restart-demo');

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.borderColor = isError ? '#fed7aa' : '';
  statusEl.style.background = isError ? '#fff7ed' : '';
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

function getText(question, fieldBase) {
  return (
    question[`${fieldBase}_en`] ||
    question[`${fieldBase}_ru`] ||
    question[`${fieldBase}_uz`] ||
    question[fieldBase] ||
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

  setStatus(`Question ${state.currentIndex + 1} of ${state.questions.length}`);
  questionCard.classList.remove('hidden');
  submitButton.disabled = false;

  questionMeta.innerHTML = '';
  [question.topic, question.subtopic, question.difficulty, question.qtype]
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
  setStatus('Loading diagnostic practice…');
  updateProgress();

  const { data, error } = await client.rpc('get_safe_questions_by_ids', {
    p_question_ids: PILOT_QUESTION_IDS,
  });

  if (error) {
    console.error(error);
    setStatus('Could not load the diagnostic practice. Please check the connection.', true);
    return;
  }

  state.questions = [...(data || [])].sort((a, b) => {
    const aOrder = a.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(a.id));
    const bOrder = b.request_order ?? PILOT_QUESTION_IDS.indexOf(Number(b.id));
    return aOrder - bOrder;
  });

  if (!state.questions.length) {
    setStatus('No pilot questions were returned.', true);
    return;
  }

  renderQuestion();
}

async function submitAnswer() {
  const question = state.questions[state.currentIndex];
  if (!question || state.currentAnswered) return;

  const isInput = question.qtype === 'input';
  const userAnswer = isInput ? inputAnswer.value.trim() : null;

  if (isInput && !userAnswer) {
    setStatus('Please type your answer first.', true);
    return;
  }

  if (!isInput && state.selectedOptionIndex === null) {
    setStatus('Please choose one option first.', true);
    return;
  }

  submitButton.disabled = true;
  setStatus('Checking your answer…');

  const { data, error } = await client.rpc('evaluate_diagnostic_demo_answer', {
    p_question_id: Number(question.id),
    p_user_answer: userAnswer,
    p_picked_index: isInput ? null : state.selectedOptionIndex,
  });

  if (error) {
    console.error(error);
    submitButton.disabled = false;
    setStatus('Could not check the answer. Please try again.', true);
    return;
  }

  const result = data || {};
  const correct = Boolean(result.is_correct);
  state.currentAnswered = true;
  state.results.push({ question, result });
  updateProgress();
  setAnswerControlsDisabled(true);

  feedbackTitle.textContent = correct ? 'Correct' : 'Needs revision';
  feedbackTitle.className = `feedback-title ${correct ? 'good' : 'bad'}`;
  feedbackText.textContent = result.feedback_en || result.feedback_ru || result.feedback_uz || 'Feedback is not available yet.';

  const area = [result.recommended_topic, result.recommended_subtopic].filter(Boolean).join(' / ');
  weakArea.textContent = result.weak_skill || area || 'Review the related topic';
  nextAction.textContent = result.next_action_en || result.next_action_ru || result.next_action_uz || 'Try one more similar question.';

  nextButton.textContent = state.currentIndex + 1 >= state.questions.length ? 'Show summary' : 'Next question';
  feedbackCard.classList.remove('hidden');
  setStatus(`Question ${state.currentIndex + 1} checked`);
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
    item.textContent = count > 1 ? `${label} (${count} times)` : label;
    listEl.appendChild(item);
  });
}

function fillPlanList(wrongResults) {
  summaryPlanList.innerHTML = '';
  const planItems = [];

  wrongResults.forEach(({ result }) => {
    const action = result.next_action_en || result.next_action_ru || result.next_action_uz;
    if (action && !planItems.includes(action)) planItems.push(action);
  });

  if (!planItems.length) {
    planItems.push('Move to a harder Economics practice set.');
    planItems.push('Review your correct answers and explain the logic in your own words.');
  }

  planItems.slice(0, 4).forEach((text) => {
    const item = document.createElement('li');
    item.textContent = text;
    summaryPlanList.appendChild(item);
  });
}

function renderSummary() {
  const total = state.results.length;
  const correctCount = state.results.filter(({ result }) => Boolean(result.is_correct)).length;
  const percent = total ? Math.round((correctCount / total) * 100) : 0;
  const wrongResults = state.results.filter(({ result }) => !Boolean(result.is_correct));

  questionCard.classList.add('hidden');
  feedbackCard.classList.add('hidden');
  summaryCard.classList.remove('hidden');
  updateProgress();
  setStatus('Diagnostic summary is ready');

  summaryScore.textContent = `${percent}%`;
  summaryCount.textContent = `${correctCount} / ${total}`;

  const weakAreas = countBy(wrongResults, ({ result }) => {
    return result.weak_skill || [result.recommended_topic, result.recommended_subtopic].filter(Boolean).join(' / ');
  });

  const mistakeTypes = countBy(wrongResults, ({ result }) => {
    if (!result.mistake_type) return null;
    return result.mistake_type.replaceAll('_', ' ');
  });

  fillList(summaryWeakList, weakAreas, 'No major weak area found in this short set.');
  fillList(summaryMistakeList, mistakeTypes, 'No repeated mistake pattern found.');
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

submitButton.addEventListener('click', submitAnswer);
nextButton.addEventListener('click', goNext);
restartButton.addEventListener('click', restartDemo);
inputAnswer.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') submitAnswer();
});

loadQuestions();
