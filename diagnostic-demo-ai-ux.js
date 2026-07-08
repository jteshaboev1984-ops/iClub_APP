// Presentation-layer polish for the hidden diagnostic demo.
// It does not write to the database and does not change practice history.

(function () {
  const RU = 'ru';

  function currentLang() {
    return document.documentElement.lang || RU;
  }

  function textByLang(map) {
    return map[currentLang()] || map.ru || map.en || '';
  }

  function el(id) {
    return document.getElementById(id);
  }

  function setText(id, value) {
    const node = el(id);
    if (node && node.textContent !== value) node.textContent = value;
  }

  function getText(id) {
    return el(id)?.textContent?.trim() || '';
  }

  function replaceAiWord(root = document.body) {
    const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT);
    const nodes = [];
    while (walker.nextNode()) nodes.push(walker.currentNode);
    nodes.forEach((node) => {
      const next = node.nodeValue.replaceAll('ИИ', 'AI');
      if (next !== node.nodeValue) node.nodeValue = next;
    });
  }

  function applyMainCopy() {
    replaceAiWord();

    const lang = currentLang();
    const aiButton = el('result-primary-action');
    if (aiButton) {
      aiButton.textContent = textByLang({ en: 'AI diagnosis', ru: 'AI-диагностика', uz: 'AI diagnostika' });
    }

    setText('ai-thinking-title', textByLang({ en: 'AI diagnosis', ru: 'AI-диагностика', uz: 'AI diagnostika' }));
    setText('ai-thinking-subtitle', textByLang({
      en: 'Analysing the practice you just completed',
      ru: 'Анализируем только что завершённую практику',
      uz: 'Hozirgina tugallangan mashq tahlil qilinmoqda',
    }));
    setText('ai-thinking-status', textByLang({ en: 'Building your diagnosis…', ru: 'Формируем вашу диагностику…', uz: 'Diagnostika tayyorlanmoqda…' }));

    setText('ai-result-title', textByLang({ en: 'AI diagnosis is ready', ru: 'AI-диагностика готова', uz: 'AI diagnostika tayyor' }));
    setText('ai-result-subtitle', textByLang({
      en: 'Recommendations based on the practice you just completed',
      ru: 'Рекомендации по только что завершённой практике',
      uz: 'Hozirgina tugallangan mashq bo‘yicha tavsiyalar',
    }));
    setText('ai-focus-label', textByLang({ en: 'Main focus', ru: 'Главный фокус', uz: 'Asosiy fokus' }));
    setText('ai-reason-label', textByLang({ en: 'Diagnostic insight', ru: 'Диагностический вывод', uz: 'Diagnostik xulosa' }));
    setText('ai-plan-label', textByLang({ en: 'Personal plan', ru: 'Персональный план', uz: 'Shaxsiy reja' }));

    setText('ai-source-action-title', textByLang({ en: 'Open source', ru: 'Открыть источник', uz: 'Manbani ochish' }));
    setText('ai-source-action-sub', textByLang({
      en: 'Material for the main focus',
      ru: 'Материал по главному фокусу',
      uz: 'Asosiy fokus bo‘yicha material',
    }));
    setText('ai-review-action-title', textByLang({ en: 'Review mistakes', ru: 'Разобрать ошибки', uz: 'Xatolarni tahlil qilish' }));
    setText('ai-review-action-sub', textByLang({
      en: 'Check the logic behind each mistake',
      ru: 'Проверить логику каждого ответа',
      uz: 'Har bir xato mantiqini tekshirish',
    }));
    setText('ai-mini-action-title', textByLang({ en: 'Start mini-training', ru: 'Начать мини-тренировку', uz: 'Mini-mashqni boshlash' }));
    setText('ai-mini-action-sub', textByLang({
      en: 'Similar questions for reinforcement',
      ru: 'Похожие задания для закрепления',
      uz: 'Mustahkamlash uchun o‘xshash savollar',
    }));

    const archiveBtn = el('ai-open-archive');
    if (archiveBtn) archiveBtn.textContent = textByLang({ en: 'AI diagnosis archive', ru: 'Архив AI-диагностик', uz: 'AI diagnostika arxivi' });

    if (lang === 'ru') {
      setText('source-subtitle', 'Материал связан с главным фокусом AI-диагностики');
      setText('source-back-to-ai', 'Назад к AI-плану');
    }
  }

  function applyAiResultPolish() {
    const focus = getText('ai-focus-title') || textByLang({ en: 'main focus', ru: 'главный фокус', uz: 'asosiy fokus' });
    const errorsText = getText('result-errors-value');
    const errors = Number.parseInt(errorsText, 10);
    const safeErrors = Number.isFinite(errors) ? errors : 0;

    const insight = textByLang({
      en: `${focus} is the first priority because the same misunderstanding appears across ${safeErrors} mistake(s). Start with the core idea, then return to the exact questions and finish with similar practice.`,
      ru: `${focus} выбран первым, потому что в этой попытке повторяется один и тот же тип ошибки. Сначала восстановите базовую идею темы, затем проверьте конкретные вопросы и закрепите похожими заданиями.`,
      uz: `${focus} birinchi tanlandi, chunki bu urinishda bir xil xato turi takrorlangan. Avval mavzuning asosiy g‘oyasini tiklang, keyin savollarni tekshirib, o‘xshash mashqlar bilan mustahkamlang.`,
    });
    setText('ai-reason-text', insight);

    const steps = Array.from(document.querySelectorAll('#ai-plan-list .ai-route-step'));
    const route = textByLang({
      en: [
        ['1. Restore the idea', `Review the rule behind ${focus} and define what the question is really asking.`],
        ['2. Check your mistakes', 'Open the mistake review and compare your answer with the correct logic.'],
        ['3. Reinforce with practice', 'Complete a short set of similar questions so the same mistake does not repeat.'],
      ],
      ru: [
        ['1. Восстановить идею', `Повторите правило темы «${focus}» и разберите, что именно спрашивает вопрос.`],
        ['2. Проверить ошибки', 'Откройте разбор и сравните свой ответ с правильной логикой.'],
        ['3. Закрепить практикой', 'Пройдите короткий набор похожих заданий, чтобы ошибка не повторилась.'],
      ],
      uz: [
        ['1. G‘oyani tiklash', `«${focus}» mavzusidagi qoidani takrorlang va savol nimani so‘rayotganini aniqlang.`],
        ['2. Xatolarni tekshirish', 'Xatolar tahlilini ochib, javobingizni to‘g‘ri mantiq bilan solishtiring.'],
        ['3. Mashq bilan mustahkamlash', 'Xuddi shunday xato takrorlanmasligi uchun qisqa o‘xshash savollar blokini bajaring.'],
      ],
    });
    steps.forEach((step, index) => {
      const title = step.querySelector('.route-step-title');
      const body = step.querySelector('.route-step-text');
      if (title && route[index]) title.textContent = route[index][0];
      if (body && route[index]) body.textContent = route[index][1];
    });
  }

  function makeArchiveCard({ title, meta, focus, score, errors, current }) {
    const badge = current ? textByLang({ en: 'Current', ru: 'Текущая', uz: 'Joriy' }) : textByLang({ en: 'Saved', ru: 'Сохранено', uz: 'Saqlangan' });
    return `
      <button class="archive-card" type="button" data-current="${current ? '1' : '0'}">
        <div class="archive-card-top">
          <div>
            <div class="archive-card-title">${title}</div>
            <div class="archive-card-meta">${meta}</div>
          </div>
          <span class="archive-badge">${badge}</span>
        </div>
        <div class="archive-focus">${focus}</div>
        <div class="archive-card-row"><span>${score}</span><span>${errors}</span></div>
      </button>
    `;
  }

  function renderArchive() {
    const focus = getText('ai-focus-title') || getText('topic-weakness-title') || '—';
    const correct = getText('result-correct-value') || '0/7';
    const errors = getText('result-errors-value') || '0';
    const subject = textByLang({ en: 'Economics · Practice 6', ru: 'Экономика · Практика 6', uz: 'Iqtisodiyot · 6-mashq' });

    const list = el('ai-archive-list');
    if (!list) return;
    list.innerHTML = makeArchiveCard({
      title: textByLang({ en: 'Latest AI diagnosis', ru: 'Последняя AI-диагностика', uz: 'Oxirgi AI diagnostika' }),
      meta: subject,
      focus: `${textByLang({ en: 'Focus', ru: 'Фокус', uz: 'Fokus' })}: ${focus}`,
      score: `${textByLang({ en: 'Result', ru: 'Результат', uz: 'Natija' })}: ${correct}`,
      errors: `${textByLang({ en: 'Errors', ru: 'Ошибки', uz: 'Xatolar' })}: ${errors}`,
      current: true,
    }) + makeArchiveCard({
      title: textByLang({ en: 'Example recommendation', ru: 'Пример рекомендации', uz: 'Tavsiya namunasi' }),
      meta: subject,
      focus: `${textByLang({ en: 'Focus', ru: 'Фокус', uz: 'Fokus' })}: ${textByLang({ en: 'Demand shifts', ru: 'Сдвиги спроса', uz: 'Talab siljishi' })}`,
      score: `${textByLang({ en: 'Result', ru: 'Результат', uz: 'Natija' })}: 4/7`,
      errors: `${textByLang({ en: 'Errors', ru: 'Ошибки', uz: 'Xatolar' })}: 3`,
      current: false,
    });
  }

  function showArchive() {
    document.querySelectorAll('.demo-screen').forEach((screen) => screen.classList.add('hidden'));
    const archive = el('ai-archive-screen');
    if (archive) archive.classList.remove('hidden');
    el('topbar-back')?.classList.remove('hidden');
    renderArchive();
  }

  function showAiResultAgain() {
    if (typeof window.renderAiResult === 'function') window.renderAiResult();
    else {
      document.querySelectorAll('.demo-screen').forEach((screen) => screen.classList.add('hidden'));
      el('ai-result-screen')?.classList.remove('hidden');
    }
    setTimeout(() => {
      applyMainCopy();
      applyAiResultPolish();
    }, 0);
  }

  function applyAll() {
    applyMainCopy();
    applyAiResultPolish();
  }

  document.addEventListener('click', (event) => {
    if (event.target.closest('#ai-open-archive')) {
      event.preventDefault();
      showArchive();
    }
    if (event.target.closest('.archive-card[data-current="1"]')) {
      event.preventDefault();
      showAiResultAgain();
    }
  });

  el('topbar-back')?.addEventListener('click', (event) => {
    const archive = el('ai-archive-screen');
    if (archive && !archive.classList.contains('hidden')) {
      event.preventDefault();
      event.stopImmediatePropagation();
      showAiResultAgain();
    }
  }, true);

  const observer = new MutationObserver(() => {
    window.clearTimeout(window.__aiUxPolishTimer);
    window.__aiUxPolishTimer = window.setTimeout(applyAll, 20);
  });
  observer.observe(document.body, { childList: true, subtree: true, characterData: true });

  setTimeout(applyAll, 0);
  setTimeout(applyAll, 300);
})();
