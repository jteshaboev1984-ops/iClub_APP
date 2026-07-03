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
};

const statusEl = document.getElementById('demo-status');
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

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.style.borderColor = isError ? '#fed7aa' : '';
  statusEl.style.background = isError ? '#fff7ed' : '';
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

function renderQuestion() {
  const question = state.questions[state.currentIndex];
  state.selectedOptionIndex = null;
  inputAnswer.value = '';
  feedbackCard.classList.add('hidden');

  if (!question) {
    questionCard.classList.add('hidden');
    setStatus('Demo completed. Refresh the page to start again.');
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
      state.selectedOptionIndex = index;
      document.querySelectorAll('.option-btn').forEach((node) => node.classList.remove('selected'));
      button.classList.add('selected');
    });
    optionsList.appendChild(button);
  });
}

async function loadQuestions() {
  setStatus('Loading diagnostic pilot…');

  const { data, error } = await client.rpc('get_safe_questions_by_ids', {
    p_question_ids: PILOT_QUESTION_IDS,
  });

  if (error) {
    console.error(error);
    setStatus('Could not load the diagnostic pilot. Please check the connection.', true);
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
  if (!question) return;

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

  submitButton.disabled = false;

  if (error) {
    console.error(error);
    setStatus('Could not check the answer. Please try again.', true);
    return;
  }

  const result = data || {};
  const correct = Boolean(result.is_correct);
  feedbackTitle.textContent = correct ? 'Correct' : 'Needs revision';
  feedbackTitle.className = `feedback-title ${correct ? 'good' : 'bad'}`;
  feedbackText.textContent = result.feedback_en || result.feedback_ru || result.feedback_uz || 'Feedback is not available yet.';

  const area = [result.recommended_topic, result.recommended_subtopic].filter(Boolean).join(' / ');
  weakArea.textContent = result.weak_skill || area || 'Review the related topic';
  nextAction.textContent = result.next_action_en || result.next_action_ru || result.next_action_uz || 'Try one more similar question.';

  feedbackCard.classList.remove('hidden');
  setStatus(`Question ${state.currentIndex + 1} checked`);
}

function goNext() {
  state.currentIndex += 1;
  renderQuestion();
}

submitButton.addEventListener('click', submitAnswer);
nextButton.addEventListener('click', goNext);
inputAnswer.addEventListener('keydown', (event) => {
  if (event.key === 'Enter') submitAnswer();
});

loadQuestions();
