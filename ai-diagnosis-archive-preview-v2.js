// Clean lab-only AI diagnosis preview layer.
// Default is OFF unless ai-diagnostic-lab.html injects this file.
// Safe scope: normal practice history is protected by marking lab attempts as is_lab=true.
// It creates/reads saved learning_roadmaps snapshots through RPC.

(() => {
  'use strict';

  const ENTRY_ID = 'ai-diagnosis-archive-entry';
  const RESULT_ACTION_ID = 'ai-diagnosis-result-action';
  const OVERLAY_ID = 'ai-diagnosis-archive-overlay';

  function lang() {
    try {
      if (window.i18n && typeof window.i18n.getLang === 'function') {
        return String(window.i18n.getLang() || 'ru').toLowerCase();
      }
    } catch {}
    return String(document.documentElement.lang || 'ru').toLowerCase();
  }

  function tr(ru, uz, en) {
    const l = lang();
    if (l === 'uz') return uz || ru || en || '';
    if (l === 'en') return en || ru || uz || '';
    return ru || uz || en || '';
  }

  function escapeHtml(value) {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  function formatDate(value) {
    const raw = String(value || '').trim();
    if (!raw) return '—';
    try {
      return new Intl.DateTimeFormat(lang() === 'en' ? 'en-US' : 'ru-RU', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
      }).format(new Date(raw));
    } catch {
      return raw.slice(0, 10) || raw;
    }
  }

  function topicLabel(topic) {
    const l = lang();
    return topic?.[`topic_${l}`] || topic?.topic_ru || topic?.topic_en || topic?.topic || '—';
  }

  function focusLabel(plan, fallback) {
    const l = lang();
    return plan?.[`main_focus_${l}`] || plan?.main_focus_ru || plan?.main_focus_en || fallback || '—';
  }

  function localizedMessage(item, plan, diagnosis) {
    const base = tr(item?.message_ru, item?.message_uz, item?.message_en) || '';
    const topics = diagnosis.priorityTopics || [];
    const totalErrors = Number(diagnosis.errors || 0);
    const top = Number(topics[0]?.errors || 0);
    const second = Number(topics[1]?.errors || 0);

    if (totalErrors >= 4 && topics.length > 1 && (top === second || top < Math.ceil(totalErrors * 0.35))) {
      const names = topics.slice(0, 3).map(topicLabel).filter(Boolean).join(', ');
      return tr(
        `Ошибки распределены по нескольким темам: ${names}. Начните с самой частой темы, затем откройте разбор ошибок и закрепите похожими заданиями.`,
        `Xatolar bir nechta mavzuga tarqalgan: ${names}. Avval eng ko‘p xato bo‘lgan mavzudan boshlang, keyin xatolar tahlilini ochib, o‘xshash savollar bilan mustahkamlang.`,
        `Mistakes are spread across several topics: ${names}. Start with the most frequent area, then open the mistake review and reinforce with similar questions.`
      );
    }

    return base;
  }

  function normalizePlan(item) {
    const plan = item?.plan_json || {};
    const priorityTopics = Array.isArray(plan.priority_topics)
      ? plan.priority_topics
      : Array.isArray(item?.priority_topics)
        ? item.priority_topics
        : [];

    const score = Number(item?.score ?? plan.score ?? 0);
    const total = Number(item?.total ?? plan.total ?? 0);
    const errors = Number(item?.errors ?? plan.errors ?? 0);
    const percent = Number(item?.percent ?? plan.percent ?? 0);

    const top = Number(priorityTopics[0]?.errors || 0);
    const second = Number(priorityTopics[1]?.errors || 0);
    const mixed = errors >= 4 && priorityTopics.length > 1 && (top === second || top < Math.ceil(errors * 0.35));

    const fallbackFocus = focusLabel(plan, item?.main_weakness);
    const mainFocus = mixed
      ? tr('Смешанные ошибки', 'Aralash xatolar', 'Mixed gaps')
      : fallbackFocus;

    const diagnosis = {
      id: item?.id,
      subjectTitle: item?.subject_title || tr('Предмет', 'Fan', 'Subject'),
      createdAt: item?.created_at,
      mainFocus,
      rawMainFocus: fallbackFocus,
      score,
      total,
      errors,
      percent,
      priorityTopics,
      steps: Array.isArray(plan.steps) ? plan.steps : [],
      sourceRefs: Array.isArray(plan.source_refs) ? plan.source_refs : []
    };

    diagnosis.message = localizedMessage(item, plan, diagnosis);
    return diagnosis;
  }

  function closeOverlay() {
    document.getElementById(OVERLAY_ID)?.remove();
  }

  async function loadArchive() {
    if (!window.sb) return [];
    const { data, error } = await window.sb.rpc('get_ai_diagnosis_archive', { p_subject_id: null, p_limit: 20 });
    if (error) throw error;
    return Array.isArray(data) ? data.map(normalizePlan) : [];
  }

  async function hasArchive() {
    try {
      const items = await loadArchive();
      return items.length > 0;
    } catch {
      return false;
    }
  }

  async function createLatestDiagnosis() {
    if (!window.sb) throw new Error('supabase_not_ready');
    const { data, error } = await window.sb.rpc('create_latest_lab_practice_ai_diagnosis');
    if (error) throw error;
    if (!data) throw new Error('empty_diagnosis');
    return normalizePlan(data);
  }

  function renderArchiveOverlay(items) {
    closeOverlay();
    const overlay = document.createElement('div');
    overlay.id = OVERLAY_ID;
    overlay.className = 'ai-diagnosis-archive-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');

    const empty = !items.length;
    overlay.innerHTML = `
      <div class="ai-diagnosis-archive-sheet">
        <div class="ai-diagnosis-archive-head">
          <div>
            <h2 class="ai-diagnosis-archive-title">${escapeHtml(tr('Архив AI-диагностик', 'AI diagnostika arxivi', 'AI diagnosis archive'))}</h2>
            <p class="ai-diagnosis-archive-sub">${escapeHtml(tr('Сохранённые рекомендации по практикам', 'Mashqlar bo‘yicha saqlangan tavsiyalar', 'Saved recommendations from practice'))}</p>
          </div>
          <button class="ai-diagnosis-archive-close" type="button" aria-label="Close">×</button>
        </div>
        <div class="ai-diagnosis-archive-body">
          ${empty ? `<div class="ai-diagnosis-detail-section"><div class="ai-diagnosis-detail-text">${escapeHtml(tr('Пока нет сохранённых AI-диагностик. Нажмите AI-диагностика на результате практики.', 'Hozircha saqlangan AI diagnostika yo‘q. Mashq natijasi ekranida AI diagnostika tugmasini bosing.', 'No saved AI diagnoses yet. Press AI diagnosis on the practice result screen.'))}</div></div>` : items.map((item, index) => `
            <button class="ai-diagnosis-archive-card" type="button" data-ai-diagnosis-index="${index}">
              <div class="ai-diagnosis-archive-card-top">
                <div>
                  <div class="ai-diagnosis-archive-card-title">${escapeHtml(item.subjectTitle)}</div>
                  <div class="ai-diagnosis-archive-card-meta">${escapeHtml(formatDate(item.createdAt))}</div>
                </div>
                <span class="ai-diagnosis-archive-badge">AI</span>
              </div>
              <div class="ai-diagnosis-archive-focus">${escapeHtml(tr('Фокус', 'Fokus', 'Focus'))}: ${escapeHtml(item.mainFocus)}</div>
              <div class="ai-diagnosis-archive-stats">
                <div class="ai-diagnosis-archive-stat"><span>${escapeHtml(tr('Счёт', 'Ball', 'Score'))}</span><b>${escapeHtml(`${item.score}/${item.total || '—'}`)}</b></div>
                <div class="ai-diagnosis-archive-stat"><span>${escapeHtml(tr('Ошибки', 'Xato', 'Errors'))}</span><b>${escapeHtml(item.errors)}</b></div>
                <div class="ai-diagnosis-archive-stat"><span>${escapeHtml(tr('%', '%', '%'))}</span><b>${escapeHtml(item.percent)}</b></div>
              </div>
            </button>
          `).join('')}
        </div>
      </div>
    `;

    overlay.addEventListener('click', (event) => {
      if (event.target === overlay || event.target.closest('.ai-diagnosis-archive-close')) {
        closeOverlay();
        return;
      }
      const card = event.target.closest('[data-ai-diagnosis-index]');
      if (!card) return;
      const index = Number(card.getAttribute('data-ai-diagnosis-index'));
      renderDiagnosisDetailOverlay(items[index]);
    });

    document.body.appendChild(overlay);
  }

  function renderDiagnosisDetailOverlay(item) {
    closeOverlay();
    const overlay = document.createElement('div');
    overlay.id = OVERLAY_ID;
    overlay.className = 'ai-diagnosis-archive-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');

    const steps = item.steps || [];
    const topicChips = (item.priorityTopics || []).slice(0, 4).map((topic) => {
      const label = topicLabel(topic);
      const count = Number(topic.errors || 0);
      return `<span class="ai-diagnosis-topic-chip">${escapeHtml(label)} · ${escapeHtml(count)}</span>`;
    }).join('');

    overlay.innerHTML = `
      <div class="ai-diagnosis-archive-sheet">
        <div class="ai-diagnosis-archive-head">
          <div>
            <h2 class="ai-diagnosis-archive-title">${escapeHtml(tr('AI-диагностика', 'AI diagnostika', 'AI diagnosis'))}</h2>
            <p class="ai-diagnosis-archive-sub">${escapeHtml(item.subjectTitle)} · ${escapeHtml(formatDate(item.createdAt))}</p>
          </div>
          <button class="ai-diagnosis-archive-close" type="button" aria-label="Close">×</button>
        </div>
        <div class="ai-diagnosis-archive-body">
          <section class="ai-diagnosis-detail-section">
            <div class="ai-diagnosis-detail-kicker">${escapeHtml(tr('Главный фокус', 'Asosiy fokus', 'Main focus'))}</div>
            <div class="ai-diagnosis-detail-title">${escapeHtml(item.mainFocus)}</div>
            ${topicChips ? `<div class="ai-diagnosis-topic-chips">${topicChips}</div>` : ''}
          </section>
          <section class="ai-diagnosis-detail-section">
            <div class="ai-diagnosis-detail-kicker">${escapeHtml(tr('Диагностический вывод', 'Diagnostik xulosa', 'Diagnostic insight'))}</div>
            <div class="ai-diagnosis-detail-text">${escapeHtml(item.message || '—')}</div>
          </section>
          <section class="ai-diagnosis-detail-section">
            <div class="ai-diagnosis-detail-kicker">${escapeHtml(tr('Персональный план', 'Shaxsiy reja', 'Personal plan'))}</div>
            <div class="ai-diagnosis-detail-steps">
              ${steps.map((step, index) => {
                const title = tr(step.title_ru, step.title_uz, step.title_en) || `${index + 1}`;
                const text = tr(step.text_ru, step.text_uz, step.text_en) || '';
                return `<div class="ai-diagnosis-detail-step"><div class="ai-diagnosis-detail-step-no">${index + 1}</div><div><div class="ai-diagnosis-detail-step-title">${escapeHtml(title)}</div><div class="ai-diagnosis-detail-step-text">${escapeHtml(text)}</div></div></div>`;
              }).join('')}
            </div>
          </section>
          <button class="btn primary" type="button" data-ai-diagnosis-back>${escapeHtml(tr('Назад к архиву', 'Arxivga qaytish', 'Back to archive'))}</button>
        </div>
      </div>
    `;

    overlay.addEventListener('click', async (event) => {
      if (event.target === overlay || event.target.closest('.ai-diagnosis-archive-close')) {
        closeOverlay();
        return;
      }
      if (event.target.closest('[data-ai-diagnosis-back]')) {
        try {
          renderArchiveOverlay(await loadArchive());
        } catch {
          closeOverlay();
        }
      }
    });

    document.body.appendChild(overlay);
  }

  async function openArchive() {
    try {
      renderArchiveOverlay([]);
      renderArchiveOverlay(await loadArchive());
    } catch {
      renderArchiveOverlay([]);
    }
  }

  async function openDiagnosisFromResult(button) {
    const titleNode = button.querySelector('.card-title');
    const subNode = button.querySelector('.muted');
    try {
      button.disabled = true;
      if (titleNode) titleNode.textContent = tr('Формируем AI-диагностику…', 'AI diagnostika tayyorlanmoqda…', 'Building AI diagnosis…');
      if (subNode) subNode.textContent = tr('Сохраняем lab-попытку отдельно', 'Lab urinishi alohida saqlanmoqda', 'Saving the lab attempt separately');

      const diagnosis = await createLatestDiagnosis();

      if (titleNode) titleNode.textContent = tr('AI-диагностика готова', 'AI diagnostika tayyor', 'AI diagnosis is ready');
      if (subNode) subNode.textContent = tr('Открываем сохранённую рекомендацию', 'Saqlangan tavsiya ochilmoqda', 'Opening saved recommendation');
      renderDiagnosisDetailOverlay(diagnosis);
      setTimeout(refreshUi, 300);
    } catch (error) {
      console.warn('[AI Diagnosis Lab] create_latest_lab_practice_ai_diagnosis failed:', error);
      if (titleNode) titleNode.textContent = tr('AI-диагностика', 'AI diagnostika', 'AI diagnosis');
      if (subNode) subNode.textContent = tr('Не удалось сохранить. Попробуйте пройти практику ещё раз.', 'Saqlanmadi. Mashqni yana bir marta bajarib ko‘ring.', 'Could not save. Try completing practice again.');
    } finally {
      button.disabled = false;
    }
  }

  function ensureResultAction() {
    const resultScreen = document.getElementById('courses-practice-result');
    const grid = resultScreen?.querySelector('.cards-grid');
    if (!grid || document.getElementById(RESULT_ACTION_ID)) return;

    const btn = document.createElement('button');
    btn.id = RESULT_ACTION_ID;
    btn.className = 'card-btn ai-diagnosis-result-card';
    btn.type = 'button';
    btn.innerHTML = `
      <div class="card-title">${escapeHtml(tr('AI-диагностика', 'AI diagnostika', 'AI diagnosis'))}</div>
      <div class="muted small">${escapeHtml(tr('Персональный план по этой практике', 'Ushbu mashq bo‘yicha shaxsiy reja', 'Personal plan for this practice'))}</div>
    `;
    btn.addEventListener('click', () => openDiagnosisFromResult(btn));
    grid.prepend(btn);
  }

  async function ensureArchiveEntry() {
    const list = document.querySelector('#courses-subject-hub .subject-hub-actions');
    if (!list || document.getElementById(ENTRY_ID)) return;

    const available = await hasArchive();
    const showEmpty = localStorage.getItem('iclub_ai_diag_show_empty') === '1';
    if (!available && !showEmpty) return;

    const btn = document.createElement('button');
    btn.id = ENTRY_ID;
    btn.className = 'settings-nav';
    btn.type = 'button';
    btn.innerHTML = `
      <span class="settings-nav-ico">AI</span>
      <span class="settings-nav-text">
        <span class="settings-nav-title">${escapeHtml(tr('Архив AI-диагностик', 'AI diagnostika arxivi', 'AI diagnosis archive'))}</span>
        <span class="settings-nav-sub muted small">${escapeHtml(tr('Сохранённые рекомендации по практикам', 'Mashqlar bo‘yicha saqlangan tavsiyalar', 'Saved practice recommendations'))}</span>
      </span>
      <span class="settings-nav-arrow">›</span>
    `;
    btn.addEventListener('click', openArchive);

    const recBtn = list.querySelector('[data-action="open-my-recommendations"]');
    if (recBtn && recBtn.nextSibling) list.insertBefore(btn, recBtn.nextSibling);
    else list.appendChild(btn);
  }

  function refreshUi() {
    ensureResultAction();
    ensureArchiveEntry();
  }

  window.iClubAiDiagnosisArchivePreview = { openArchive, refresh: refreshUi };

  let timer = null;
  const schedule = () => {
    clearTimeout(timer);
    timer = setTimeout(refreshUi, 180);
  };

  document.addEventListener('DOMContentLoaded', schedule);
  window.addEventListener('focus', schedule);
  new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true });
  schedule();
})();
