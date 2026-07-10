(() => {
  'use strict';

  const DATA = window.ICLUB_DEMO_V12_DATA;
  if (!DATA) throw new Error('Local demo data is missing.');

  const PREFIX = 'iclub_demo_v12.';
  const KEYS = {
    state: PREFIX + 'state',
    history: PREFIX + 'history',
    chat: PREFIX + 'chat',
    technical: PREFIX + 'technical'
  };
  const VALID_PLANS = new Set(['free', 'plus', 'pro']);
  const VALID_LANGS = new Set(['ru', 'uz', 'en']);
  const SCREEN_IDS = {
    hub: 'courses-subject-hub',
    start: 'courses-practice-start',
    quiz: 'courses-practice-quiz',
    result: 'courses-practice-result',
    review: 'courses-practice-review',
    recs: 'courses-practice-recs'
  };

  const COPY = {
    ru: {
      showMode: 'РЕЖИМ ПОКАЗА', subject: 'Экономика', mode: 'Соревновательный', mentor: 'ВАШ МЕНТОР',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics', content: 'Контент', practice: 'Практика', tours: 'Туры', resources: 'Ресурсы',
      video: 'Видео-уроки', videoSub: 'Видео-уроки доступны в Telegram', recs: 'Мои рекомендации', recsSub: 'Повторный доступ к чтению',
      system: 'Системные', certificates: 'Сертификаты', certificatesSub: 'Туры и финальные результаты', archive: 'Архив туров', archiveSub: 'Самопроверка • вне рейтинга', all: 'Все предметы', allSub: 'Каталог предметов',
      scenario: 'Сценарий', language: 'Язык интерфейса', normal: 'Обычное обучение', technical: 'Техническая панель', reset: 'Сбросить demo', close: 'Закрыть',
      copied: 'Экран работает на локальных demo-данных.', next: 'Этот раздел будет подключён на следующем этапе.', mentorInfo: 'Профиль ментора в demo не обращается к базе.', resetConfirm: 'Сбросить только локальные данные demo?', resetDone: 'Локальные данные demo сброшены.',
      dataSource: 'Источник данных', storage: 'Хранилище', productionCalls: 'Production-запросы', currentPlan: 'Тариф', guard: 'Сетевая защита',
      practiceTitle: 'Практика', practiceSubtitle: '7 вопросов • от простого к сложному', subjectLabel: 'Предмет', stage: 'Диагностическая практика • 7 вопросов', best: 'Лучший результат', bestTime: 'Лучшее время', trend: 'Тренд прогресса', last: 'Последние попытки', date: 'Дата', score: 'Счёт', time: 'Время', start: 'Начать практику', stop: 'Остановить', answer: 'Ответить',
      resultTitle: 'Результат практики', reviewTitle: 'Разбор ошибок', reviewSub: 'Правильные ответы и объяснения', recommendations: 'Рекомендации', recommendationsSub: 'Что прочитать по вашим ошибкам', again: 'Пройти снова', toSubject: 'К предмету', backResult: 'Назад к результату',
      emptyAttempts: 'Пока нет попыток', emptyReview: 'Нет данных для разбора. Сначала пройдите практику.', emptyRecs: 'Ошибок нет — дополнительные рекомендации не требуются.', correct: 'Верно', wrong: 'Ошибка', yourAnswer: 'Ваш ответ', correctAnswer: 'Правильный ответ', explanation: 'Объяснение', nextStep: 'Следующий шаг', source: 'Источник', noAnswer: 'Нет ответа', choose: 'Сначала выберите вариант ответа.', stopped: 'Практика остановлена.', diagnostic: 'Диагностика', practiceNo: n => `Практика ${n}`, resultMeta: (score, total, pct) => `${score} из ${total} верно • ${pct}%`
    },
    uz: {
      showMode: 'NAMOYISH REJIMI', subject: 'Iqtisodiyot', mode: 'Musobaqa rejimi', mentor: 'SIZNING MENTORINGIZ',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics', content: 'Kontent', practice: 'Mashq', tours: 'Turlar', resources: 'Resurslar',
      video: 'Video darslar', videoSub: 'Video darslar Telegramda mavjud', recs: 'Mening tavsiyalarim', recsSub: 'O‘qish materialiga qaytish',
      system: 'Tizimli', certificates: 'Sertifikatlar', certificatesSub: 'Turlar va yakuniy natijalar', archive: 'Turlar arxivi', archiveSub: 'O‘zini tekshirish • reytingdan tashqari', all: 'Barcha fanlar', allSub: 'Fanlar katalogi',
      scenario: 'Ssenariy', language: 'Interfeys tili', normal: 'Oddiy o‘qish', technical: 'Texnik panel', reset: 'Demo holatini tiklash', close: 'Yopish',
      copied: 'Ekran lokal demo ma’lumotlari bilan ishlaydi.', next: 'Bu bo‘lim keyingi bosqichda ulanadi.', mentorInfo: 'Demo mentor profili bazaga murojaat qilmaydi.', resetConfirm: 'Faqat lokal demo ma’lumotlari tiklansinmi?', resetDone: 'Lokal demo ma’lumotlari tiklandi.',
      dataSource: 'Ma’lumot manbasi', storage: 'Saqlash', productionCalls: 'Production so‘rovlari', currentPlan: 'Tarif', guard: 'Tarmoq himoyasi',
      practiceTitle: 'Mashq', practiceSubtitle: '7 savol • osondan qiyinga', subjectLabel: 'Fan', stage: 'Diagnostik mashq • 7 savol', best: 'Eng yaxshi natija', bestTime: 'Eng yaxshi vaqt', trend: 'Progress yo‘nalishi', last: 'So‘nggi urinishlar', date: 'Sana', score: 'Ball', time: 'Vaqt', start: 'Mashqni boshlash', stop: 'To‘xtatish', answer: 'Javob berish',
      resultTitle: 'Mashq natijasi', reviewTitle: 'Xatolar tahlili', reviewSub: 'To‘g‘ri javoblar va izohlar', recommendations: 'Tavsiyalar', recommendationsSub: 'Xatolarga ko‘ra nimani o‘qish kerak', again: 'Qayta ishlash', toSubject: 'Fanga qaytish', backResult: 'Natijaga qaytish',
      emptyAttempts: 'Hozircha urinish yo‘q', emptyReview: 'Tahlil uchun ma’lumot yo‘q. Avval mashqni bajaring.', emptyRecs: 'Xato yo‘q — qo‘shimcha tavsiya kerak emas.', correct: 'To‘g‘ri', wrong: 'Xato', yourAnswer: 'Sizning javobingiz', correctAnswer: 'To‘g‘ri javob', explanation: 'Izoh', nextStep: 'Keyingi qadam', source: 'Manba', noAnswer: 'Javob yo‘q', choose: 'Avval javob variantini tanlang.', stopped: 'Mashq to‘xtatildi.', diagnostic: 'Diagnostika', practiceNo: n => `${n}-mashq`, resultMeta: (score, total, pct) => `${total} tadan ${score} to‘g‘ri • ${pct}%`
    },
    en: {
      showMode: 'DEMO MODE', subject: 'Economics', mode: 'Competitive', mentor: 'YOUR MENTOR',
      mentorName: 'Erkinov Azizbek', mentorSub: 'AS Level Economics', content: 'Content', practice: 'Practice', tours: 'Tours', resources: 'Resources',
      video: 'Video lessons', videoSub: 'Video lessons are available in Telegram', recs: 'My recommendations', recsSub: 'Return to saved reading',
      system: 'System', certificates: 'Certificates', certificatesSub: 'Tours and final results', archive: 'Tour archive', archiveSub: 'Self-check • outside ranking', all: 'All subjects', allSub: 'Subject catalogue',
      scenario: 'Scenario', language: 'Interface language', normal: 'Normal learning', technical: 'Technical panel', reset: 'Reset demo', close: 'Close',
      copied: 'The screen runs on local demo data.', next: 'This section will be connected in the next stage.', mentorInfo: 'The demo mentor profile does not query the database.', resetConfirm: 'Reset only local demo data?', resetDone: 'Local demo data reset.',
      dataSource: 'Data source', storage: 'Storage', productionCalls: 'Production calls', currentPlan: 'Plan', guard: 'Network guard',
      practiceTitle: 'Practice', practiceSubtitle: '7 questions • from easy to hard', subjectLabel: 'Subject', stage: 'Diagnostic practice • 7 questions', best: 'Best result', bestTime: 'Best time', trend: 'Progress trend', last: 'Latest attempts', date: 'Date', score: 'Score', time: 'Time', start: 'Start practice', stop: 'Stop', answer: 'Answer',
      resultTitle: 'Practice result', reviewTitle: 'Review mistakes', reviewSub: 'Correct answers and explanations', recommendations: 'Recommendations', recommendationsSub: 'What to review based on your mistakes', again: 'Try again', toSubject: 'To subject', backResult: 'Back to result',
      emptyAttempts: 'No attempts yet', emptyReview: 'No review data. Complete the practice first.', emptyRecs: 'No mistakes — no additional recommendations are needed.', correct: 'Correct', wrong: 'Wrong', yourAnswer: 'Your answer', correctAnswer: 'Correct answer', explanation: 'Explanation', nextStep: 'Next step', source: 'Source', noAnswer: 'No answer', choose: 'Choose an answer first.', stopped: 'Practice stopped.', diagnostic: 'Diagnosis', practiceNo: n => `Practice ${n}`, resultMeta: (score, total, pct) => `${score} of ${total} correct • ${pct}%`
    }
  };

  const $ = id => document.getElementById(id);
  const escapeHtml = value => String(value ?? '').replace(/[&<>"']/g, ch => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#039;' }[ch]));
  const read = (store, key, fallback) => { try { return JSON.parse(store.getItem(key) || '') || fallback; } catch { return fallback; } };
  const write = (store, key, value) => { try { store.setItem(key, JSON.stringify(value)); } catch {} };
  const mmss = seconds => `${String(Math.floor(Math.max(0, seconds) / 60)).padStart(2, '0')}:${String(Math.max(0, seconds) % 60).padStart(2, '0')}`;
  const isoDate = () => new Date().toISOString().slice(0, 10);

  const initial = read(localStorage, KEYS.state, {});
  const state = {
    plan: VALID_PLANS.has(initial.plan) ? initial.plan : 'free',
    lang: VALID_LANGS.has(initial.lang) ? initial.lang : 'ru',
    screen: SCREEN_IDS[initial.screen] ? initial.screen : 'hub',
    index: 0,
    selected: null,
    results: [],
    startedAt: 0,
    timer: null,
    remaining: 0,
    elapsedBeforeQuestion: 0
  };

  function t() { return COPY[state.lang] || COPY.ru; }
  function localize(value) { return value?.[state.lang] ?? value?.ru ?? value?.en ?? value?.uz ?? value ?? ''; }
  function setText(id, value) { const node = $(id); if (node) node.textContent = value; }
  function getHistory() { return read(localStorage, KEYS.history, { baseline: DATA.history || [], diagnostics: [] }); }
  function saveHistory(history) { write(localStorage, KEYS.history, history); }

  function ensureLocalStorage() {
    if (!localStorage.getItem(KEYS.history)) saveHistory({ baseline: DATA.history || [], diagnostics: [] });
    if (!localStorage.getItem(KEYS.chat)) write(localStorage, KEYS.chat, { messages: [], draft: '' });
  }

  function persist() {
    write(localStorage, KEYS.state, { plan: state.plan, lang: state.lang, screen: state.screen });
    write(sessionStorage, KEYS.technical, {
      gate: 'main-copy-foundation', data_source: 'static local object', production_calls: 0,
      storage: 'iclub_demo_v12.* only', plan: state.plan, lang: state.lang, network_guard: 'connect-src none'
    });
  }

  function stopTimer() {
    if (state.timer) window.clearInterval(state.timer);
    state.timer = null;
  }

  function showScreen(name) {
    stopTimer();
    Object.entries(SCREEN_IDS).forEach(([key, id]) => {
      const node = $(id);
      if (!node) return;
      const active = key === name;
      node.classList.toggle('is-active', active);
      node.hidden = !active;
      node.setAttribute('aria-hidden', String(!active));
    });
    state.screen = name;
    $('topbar-back')?.style.setProperty('visibility', name === 'hub' ? 'visible' : 'visible');
    persist();
    window.scrollTo({ top: 0, behavior: 'auto' });
    if (name === 'start') renderPracticeStart();
    if (name === 'quiz') renderQuestion();
    if (name === 'result') renderResult();
    if (name === 'review') renderReview();
    if (name === 'recs') renderRecommendations();
  }

  function renderStaticCopy() {
    const x = t();
    document.documentElement.lang = state.lang;
    setText('demo-planbar-label', x.showMode); setText('demo-scenario-button', x.scenario);
    setText('subject-hub-title', x.subject); setText('subject-hub-meta', x.mode);
    setText('mentor-kicker', x.mentor); setText('subject-hub-mentor-title', x.mentorName); setText('subject-hub-mentor-sub', x.mentorSub);

    const tabLabels = { content: x.content, practice: x.practice, tours: x.tours, resources: x.resources };
    document.querySelectorAll('[data-hub-tab]').forEach(button => { button.textContent = tabLabels[button.dataset.hubTab] || button.textContent; });

    setText('hub-video-title', x.video); setText('hub-video-sub', x.videoSub); setText('hub-recs-title', x.recs); setText('hub-recs-sub', x.recsSub);
    setText('hub-system-title', x.system); setText('hub-cert-title', x.certificates); setText('hub-cert-sub', x.certificatesSub);
    setText('hub-archive-title', x.archive); setText('hub-archive-sub', x.archiveSub); setText('hub-all-title', x.all); setText('hub-all-sub', x.allSub);

    setText('demo-menu-title', x.scenario); setText('demo-language-label', x.language); setText('demo-normal-learning', x.normal);
    setText('demo-technical', x.technical); setText('demo-reset', x.reset); setText('demo-close', x.close);

    setText('practice-title', x.practiceTitle); setText('practice-subtitle', x.practiceSubtitle); setText('practice-subject-label', x.subjectLabel);
    setText('practice-subject-title', x.subject); setText('practice-stage-meta', x.stage); setText('practice-best-result-label', x.best);
    setText('practice-best-time-label', x.bestTime); setText('practice-trend-label', x.trend); setText('practice-last-title', x.last);
    setText('practice-col-date', x.date); setText('practice-col-score', x.score); setText('practice-col-time', x.time);
    setText('practice-restart-label', x.start); setText('practice-pause-btn', x.stop); setText('practice-submit-btn', x.answer);
    setText('practice-result-title', x.resultTitle); setText('practice-review-title', x.reviewTitle); setText('practice-review-sub', x.reviewSub);
    setText('practice-recs-title', x.recommendations); setText('practice-recs-sub', x.recommendationsSub); setText('practice-again-btn', x.again);
    setText('practice-to-subject-btn', x.toSubject); setText('practice-review-screen-title', x.reviewTitle); setText('practice-review-screen-sub', x.reviewSub);
    setText('practice-review-back-btn', x.backResult); setText('practice-review-to-subject-btn', x.toSubject);
    setText('practice-recs-screen-title', x.recommendations); setText('practice-recs-screen-sub', x.recommendationsSub);
    setText('practice-recs-back-btn', x.backResult); setText('practice-recs-to-subject-btn', x.toSubject);

    document.querySelectorAll('[data-plan]').forEach(button => {
      const active = button.dataset.plan === state.plan;
      button.classList.toggle('is-active', active); button.setAttribute('aria-pressed', String(active));
    });
    document.querySelectorAll('[data-lang]').forEach(button => {
      const active = button.dataset.lang === state.lang;
      button.classList.toggle('is-active', active); button.setAttribute('aria-pressed', String(active));
    });
    persist();
  }

  function renderPracticeStart() {
    const x = t();
    const picker = $('practice-tour-picker');
    if (picker) {
      picker.innerHTML = '';
      [1, 2, 3, 4].forEach(no => {
        const button = document.createElement('button');
        button.type = 'button'; button.className = 'practice-tour-chip'; button.textContent = x.practiceNo(no);
        button.dataset.localNotice = '1'; picker.appendChild(button);
      });
      const active = document.createElement('button');
      active.type = 'button'; active.className = 'practice-tour-chip is-active'; active.textContent = x.diagnostic; active.setAttribute('aria-current', 'true');
      picker.appendChild(active);
    }

    const history = getHistory();
    const diagnostics = Array.isArray(history.diagnostics) ? history.diagnostics : [];
    const best = diagnostics.slice().sort((a, b) => b.score - a.score || a.seconds - b.seconds)[0];
    setText('practice-best-score', best ? `${best.score}/${best.total}` : '—');
    setText('practice-best-percent', best ? `${Math.round((best.score / best.total) * 100)}%` : '');
    setText('practice-best-time', best ? mmss(best.seconds) : '—');

    const tbody = $('practice-last-tbody');
    if (tbody) {
      tbody.innerHTML = '';
      diagnostics.slice(-3).reverse().forEach(item => {
        const row = document.createElement('tr');
        row.innerHTML = `<td>${escapeHtml(item.date)}</td><td>${escapeHtml(`${item.score}/${item.total}`)}</td><td>${escapeHtml(mmss(item.seconds))}</td>`;
        tbody.appendChild(row);
      });
    }
    const empty = $('practice-last-empty');
    if (empty) {
      empty.textContent = x.emptyAttempts;
      empty.style.display = diagnostics.length ? 'none' : 'block';
    }
  }

  function startPractice() {
    state.index = 0; state.selected = null; state.results = []; state.startedAt = Date.now(); state.elapsedBeforeQuestion = 0;
    showScreen('quiz');
  }

  function startQuestionTimer(seconds) {
    stopTimer(); state.remaining = seconds; setText('practice-timer', mmss(state.remaining));
    state.timer = window.setInterval(() => {
      state.remaining -= 1; setText('practice-timer', mmss(state.remaining));
      $('practice-timer')?.classList.toggle('danger', state.remaining <= 10);
      if (state.remaining <= 0) {
        stopTimer(); recordAnswer(null); advanceQuestion();
      }
    }, 1000);
  }

  function renderQuestion() {
    const question = DATA.questions[state.index];
    if (!question) { finishPractice(); return; }
    state.selected = null;
    setText('practice-qno', `${state.index + 1}/${DATA.questions.length}`);
    setText('practice-question', localize(question.q));
    const submit = $('practice-submit-btn'); if (submit) { submit.disabled = true; submit.classList.remove('primary'); }
    const options = $('practice-options');
    if (options) {
      options.innerHTML = '';
      const rows = question.o?.[state.lang] || question.o?.ru || question.o?.en || [];
      rows.forEach((text, index) => {
        const letter = String.fromCharCode(65 + index);
        const button = document.createElement('button');
        button.type = 'button'; button.className = 'option'; button.dataset.option = letter;
        button.innerHTML = `<span class="dot" aria-hidden="true"></span><span class="opt-text">${letter}. ${escapeHtml(text)}</span>`;
        button.addEventListener('click', () => {
          state.selected = letter;
          options.querySelectorAll('.option').forEach(node => node.classList.toggle('is-selected', node === button));
          if (submit) { submit.disabled = false; submit.classList.add('primary'); }
        });
        options.appendChild(button);
      });
    }
    startQuestionTimer(Number(question.seconds || 60));
  }

  function recordAnswer(selected) {
    const question = DATA.questions[state.index];
    if (!question) return;
    state.results.push({ questionId: question.id, selected, correct: selected === question.a });
  }

  function advanceQuestion() {
    state.index += 1;
    if (state.index >= DATA.questions.length) finishPractice();
    else renderQuestion();
  }

  function submitAnswer() {
    if (!state.selected) { toast(t().choose); return; }
    stopTimer(); recordAnswer(state.selected); advanceQuestion();
  }

  function finishPractice() {
    stopTimer();
    const total = DATA.questions.length;
    const score = state.results.filter(item => item.correct).length;
    const seconds = Math.max(1, Math.round((Date.now() - state.startedAt) / 1000));
    const history = getHistory();
    const diagnostics = Array.isArray(history.diagnostics) ? history.diagnostics : [];
    diagnostics.push({ id: `diag-${Date.now()}`, kind: 'diagnostic', date: isoDate(), score, total, seconds, answers: state.results });
    history.diagnostics = diagnostics; saveHistory(history);
    showScreen('result');
  }

  function latestAttempt() {
    const diagnostics = getHistory().diagnostics || [];
    return diagnostics.length ? diagnostics[diagnostics.length - 1] : null;
  }

  function renderResult() {
    const attempt = latestAttempt();
    const total = attempt?.total || DATA.questions.length;
    const score = attempt?.score || 0;
    const pct = total ? Math.round((score / total) * 100) : 0;
    setText('practice-result-meta', t().resultMeta(score, total, pct));
    const wrong = (attempt?.answers || []).filter(item => !item.correct);
    setText('practice-review-count', String(wrong.length));
    const topics = new Set(wrong.map(item => localize(DATA.questions.find(q => q.id === item.questionId)?.topic)).filter(Boolean));
    setText('practice-recs-count', String(topics.size));
  }

  function optionText(question, letter) {
    if (!letter) return t().noAnswer;
    const index = letter.charCodeAt(0) - 65;
    const rows = question.o?.[state.lang] || question.o?.ru || question.o?.en || [];
    return `${letter}. ${rows[index] ?? ''}`;
  }

  function renderReview() {
    const list = $('practice-review-list'); if (!list) return;
    const attempt = latestAttempt();
    const answers = attempt?.answers || [];
    if (!answers.length) { list.innerHTML = `<div class="empty muted">${escapeHtml(t().emptyReview)}</div>`; return; }
    list.innerHTML = '';
    answers.forEach((answer, index) => {
      const q = DATA.questions.find(item => item.id === answer.questionId); if (!q) return;
      const card = document.createElement('article'); card.className = 'card demo-review-card';
      card.innerHTML = `
        <div class="demo-review-head"><div class="card-title">${index + 1}. ${escapeHtml(localize(q.q))}</div><span class="demo-review-status ${answer.correct ? 'is-correct' : 'is-wrong'}">${escapeHtml(answer.correct ? t().correct : t().wrong)}</span></div>
        <div class="demo-review-grid">
          <div class="demo-review-box"><span>${escapeHtml(t().yourAnswer)}</span>${escapeHtml(optionText(q, answer.selected))}</div>
          <div class="demo-review-box"><span>${escapeHtml(t().correctAnswer)}</span>${escapeHtml(optionText(q, q.a))}</div>
          <div class="demo-review-box"><span>${escapeHtml(t().explanation)}</span>${escapeHtml(localize(answer.correct ? q.ok : q.bad))}</div>
          <div class="demo-review-box"><span>${escapeHtml(t().nextStep)}</span>${escapeHtml(localize(q.next))}</div>
        </div>`;
      list.appendChild(card);
    });
  }

  function renderRecommendations() {
    const list = $('practice-recs-list'); if (!list) return;
    const attempt = latestAttempt();
    const wrongQuestions = (attempt?.answers || []).filter(item => !item.correct).map(item => DATA.questions.find(q => q.id === item.questionId)).filter(Boolean);
    if (!wrongQuestions.length) { list.innerHTML = `<div class="empty muted">${escapeHtml(t().emptyRecs)}</div>`; return; }
    const unique = new Map(); wrongQuestions.forEach(q => { const key = `${localize(q.topic)}|${localize(q.skill)}`; if (!unique.has(key)) unique.set(key, q); });
    list.innerHTML = '';
    unique.forEach(q => {
      const card = document.createElement('article'); card.className = 'card demo-recommendation-card';
      card.innerHTML = `<div class="card-title">${escapeHtml(localize(q.topic))}</div><div class="muted small">${escapeHtml(localize(q.skill))}</div><div class="demo-review-grid"><div class="demo-review-box"><span>${escapeHtml(t().source)}</span>${escapeHtml(q.ref)}</div><div class="demo-review-box"><span>${escapeHtml(t().nextStep)}</span>${escapeHtml(localize(q.next))}</div></div>`;
      list.appendChild(card);
    });
  }

  let toastTimer = null;
  function toast(message) {
    const node = $('toast'); if (!node) return;
    node.textContent = message; node.classList.add('is-show');
    window.clearTimeout(toastTimer); toastTimer = window.setTimeout(() => node.classList.remove('is-show'), 2400);
  }

  function openMenu() { $('modal-root')?.setAttribute('aria-hidden', 'false'); document.body.classList.add('modal-open'); }
  function closeMenu() { $('modal-root')?.setAttribute('aria-hidden', 'true'); document.body.classList.remove('modal-open'); $('demo-technical-card')?.remove(); }

  function showTechnical() {
    const modal = document.querySelector('.demo-menu-modal'); if (!modal) return;
    $('demo-technical-card')?.remove();
    const x = t(); const card = document.createElement('div'); card.id = 'demo-technical-card'; card.className = 'demo-technical-card';
    card.innerHTML = `<div class="demo-technical-row"><span>${escapeHtml(x.dataSource)}</span><b>static local object</b></div><div class="demo-technical-row"><span>${escapeHtml(x.storage)}</span><b>iclub_demo_v12.*</b></div><div class="demo-technical-row"><span>${escapeHtml(x.productionCalls)}</span><b>0</b></div><div class="demo-technical-row"><span>${escapeHtml(x.currentPlan)}</span><b>${escapeHtml(state.plan)}</b></div><div class="demo-technical-row"><span>${escapeHtml(x.guard)}</span><b>connect-src none</b></div>`;
    modal.querySelector('.modal-actions')?.before(card);
  }

  function resetDemo() {
    if (!window.confirm(t().resetConfirm)) return;
    [localStorage, sessionStorage].forEach(store => {
      const keys = []; for (let i = 0; i < store.length; i += 1) { const key = store.key(i); if (key?.startsWith(PREFIX)) keys.push(key); }
      keys.forEach(key => store.removeItem(key));
    });
    state.plan = 'free'; state.lang = 'ru'; state.screen = 'hub'; state.results = []; state.index = 0;
    ensureLocalStorage(); closeMenu(); renderStaticCopy(); showScreen('hub'); toast(COPY.ru.resetDone);
  }

  function goBack() {
    if (state.screen === 'hub') { if (history.length > 1) history.back(); else toast(t().copied); return; }
    if (state.screen === 'start') showScreen('hub');
    else if (state.screen === 'quiz') { if (window.confirm(t().stopped)) showScreen('start'); }
    else if (state.screen === 'review' || state.screen === 'recs') showScreen('result');
    else showScreen('start');
  }

  document.addEventListener('click', event => {
    const planButton = event.target.closest('[data-plan]');
    if (planButton) { state.plan = planButton.dataset.plan; renderStaticCopy(); return; }
    const langButton = event.target.closest('[data-lang]');
    if (langButton) { state.lang = langButton.dataset.lang; renderStaticCopy(); showScreen(state.screen); return; }
    if (event.target.closest('#demo-scenario-button')) { openMenu(); return; }
    if (event.target.matches('[data-close-demo-menu]') || event.target.closest('#demo-close')) { closeMenu(); return; }

    const menuAction = event.target.closest('[data-demo-menu-action]')?.dataset.demoMenuAction;
    if (menuAction === 'technical') { showTechnical(); return; }
    if (menuAction === 'reset') { resetDemo(); return; }
    if (menuAction === 'learning') { closeMenu(); toast(t().copied); return; }

    if (event.target.closest('#topbar-back')) { goBack(); return; }
    if (event.target.closest('#subject-hub-mentor-btn')) { toast(t().mentorInfo); return; }

    const hubTab = event.target.closest('[data-hub-tab]')?.dataset.hubTab;
    if (hubTab === 'content') { showScreen('hub'); return; }
    if (hubTab === 'practice') { showScreen('start'); return; }
    if (hubTab) { toast(t().next); return; }

    if (event.target.closest('[data-local-action]')) { toast(t().next); return; }
    if (event.target.closest('[data-local-notice]')) { toast(t().next); return; }
    if (event.target.closest('#practice-restart-btn') || event.target.closest('#practice-again-btn')) { startPractice(); return; }
    if (event.target.closest('#practice-pause-btn')) { if (window.confirm(t().stopped)) showScreen('start'); return; }
    if (event.target.closest('#practice-submit-btn')) { submitAnswer(); return; }
    if (event.target.closest('#practice-review-open')) { showScreen('review'); return; }
    if (event.target.closest('#practice-recs-open')) { showScreen('recs'); return; }
    if (event.target.closest('#practice-to-subject-btn') || event.target.closest('#practice-review-to-subject-btn') || event.target.closest('#practice-recs-to-subject-btn')) { showScreen('hub'); return; }
    if (event.target.closest('#practice-review-back-btn') || event.target.closest('#practice-recs-back-btn')) { showScreen('result'); }
  });

  ensureLocalStorage();
  renderStaticCopy();
  showScreen(state.screen);
  window.ICLUB_DEMO_MAIN_LOCAL = { getState: () => ({ plan: state.plan, lang: state.lang, screen: state.screen, productionCalls: 0 }), reset: resetDemo };
})();
