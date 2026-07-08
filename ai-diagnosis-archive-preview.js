// Gated production-safe AI diagnosis archive preview.
// Default: OFF for all users.
// Enable manually with URL ?ai_diag=1 or localStorage.setItem('iclub_ai_diag_enabled','1').
// Read-only UI: does not create, update, delete attempts, scores, ratings, certificates or roadmaps.

(() => {
  'use strict';

  const FLAG_KEY = 'iclub_ai_diag_enabled';
  const SHOW_EMPTY_KEY = 'iclub_ai_diag_show_empty';
  const ENTRY_ID = 'ai-diagnosis-archive-entry';
  const OVERLAY_ID = 'ai-diagnosis-archive-overlay';

  function isEnabled() {
    try {
      const params = new URLSearchParams(window.location.search || '');
      if (params.get('ai_diag') === '1') {
        localStorage.setItem(FLAG_KEY, '1');
        return true;
      }
      return localStorage.getItem(FLAG_KEY) === '1';
    } catch {
      return false;
    }
  }

  function shouldShowEmptyArchiveEntry() {
    try {
      const params = new URLSearchParams(window.location.search || '');
      if (params.get('ai_diag_empty') === '1') {
        localStorage.setItem(SHOW_EMPTY_KEY, '1');
        return true;
      }
      return localStorage.getItem(SHOW_EMPTY_KEY) === '1';
    } catch {
      return false;
    }
  }

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

  function normalizePlan(item) {
    const plan = item?.plan_json || {};
    const score = Number(item?.score ?? plan.score ?? 0);
    const total = Number(item?.total ?? plan.total ?? 0);
    const errors = Number(item?.errors ?? plan.errors ?? 0);
    const percent = Number(item?.percent ?? plan.percent ?? 0);
    return {
      id: item?.id,
      subjectTitle: item?.subject_title || tr('Предмет', 'Fan', 'Subject'),
      createdAt: item?.created_at,
      mainFocus: item?.main_weakness || plan.main_focus || '—',
      message: tr(item?.message_ru, item?.message_uz, item?.message_en) || '',
      score,
      total,
      errors,
      percent,
      steps: Array.isArray(plan.steps) ? plan.steps : [],
      sourceRefs: Array.isArray(plan.source_refs) ? plan.source_refs : []
    };
  }

  async function hasArchive() {
    try {
      if (!window.sb) return false;
      const { data, error } = await window.sb.rpc('has_ai_diagnosis_archive', { p_subject_id: null });
      if (error) return false;
      return data === true;
    } catch {
      return false;
    }
  }

  async function loadArchive() {
    if (!window.sb) return [];
    const { data, error } = await window.sb.rpc('get_ai_diagnosis_archive', { p_subject_id: null, p_limit: 20 });
    if (error) throw error;
    return Array.isArray(data) ? data.map(normalizePlan) : [];
  }

  function closeOverlay() {
    const overlay = document.getElementById(OVERLAY_ID);
    if (overlay) overlay.remove();
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
          ${empty ? `<div class="ai-diagnosis-detail-section"><div class="ai-diagnosis-detail-text">${escapeHtml(tr('Пока нет сохранённых AI-диагностик. После подключения кнопки на результате практики здесь появятся реальные диагностики.', 'Hozircha saqlangan AI diagnostika yo‘q. Amaliyot natijasi ekranidagi tugma ulangandan keyin bu yerda haqiqiy diagnostikalar chiqadi.', 'No saved AI diagnoses yet. After the Practice Result button is connected, real diagnoses will appear here.'))}</div></div>` : items.map((item, index) => `
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
    const steps = item.steps || [];
    closeOverlay();
    const overlay = document.createElement('div');
    overlay.id = OVERLAY_ID;
    overlay.className = 'ai-diagnosis-archive-overlay';
    overlay.setAttribute('role', 'dialog');
    overlay.setAttribute('aria-modal', 'true');

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
          const items = await loadArchive();
          renderArchiveOverlay(items);
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
      const items = await loadArchive();
      renderArchiveOverlay(items);
    } catch {
      renderArchiveOverlay([]);
    }
  }

  async function ensureEntry() {
    if (!isEnabled()) return;
    const list = document.querySelector('#courses-subject-hub .subject-hub-actions');
    if (!list || document.getElementById(ENTRY_ID)) return;

    const available = await hasArchive();
    if (!available && !shouldShowEmptyArchiveEntry()) return;
    if (document.getElementById(ENTRY_ID)) return;

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

  if (!isEnabled()) return;

  window.iClubAiDiagnosisArchivePreview = { openArchive, refresh: ensureEntry };

  let timer = null;
  const schedule = () => {
    clearTimeout(timer);
    timer = setTimeout(ensureEntry, 180);
  };

  document.addEventListener('DOMContentLoaded', schedule);
  window.addEventListener('focus', schedule);
  new MutationObserver(schedule).observe(document.documentElement, { childList: true, subtree: true });
  schedule();
})();
