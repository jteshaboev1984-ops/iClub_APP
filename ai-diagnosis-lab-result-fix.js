// Lab-only hotfix for AI diagnosis result action.
// Uses server-side latest-attempt RPC instead of reading practice_attempts columns in the client.
// Safe: creates only a learning_roadmaps snapshot and does not change attempts/scores/tours/certificates.

(() => {
  'use strict';

  const ACTION_ID = 'ai-diagnosis-result-action';

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

  function setCardState(button, title, subtitle) {
    const titleNode = button?.querySelector?.('.card-title');
    const subNode = button?.querySelector?.('.muted');
    if (titleNode) titleNode.textContent = title;
    if (subNode) subNode.textContent = subtitle;
  }

  async function createLatestDiagnosis() {
    if (!window.sb) throw new Error('supabase_not_ready');
    const { data, error } = await window.sb.rpc('create_latest_practice_ai_diagnosis');
    if (error) throw error;
    if (!data) throw new Error('empty_diagnosis');
    return data;
  }

  async function openArchiveAfterCreate() {
    if (window.iClubAiDiagnosisArchivePreview?.openArchive) {
      await window.iClubAiDiagnosisArchivePreview.openArchive();
    }
  }

  document.addEventListener('click', async (event) => {
    const button = event.target?.closest?.(`#${ACTION_ID}`);
    if (!button) return;

    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    try {
      button.disabled = true;
      setCardState(
        button,
        tr('Формируем AI-диагностику…', 'AI diagnostika tayyorlanmoqda…', 'Building AI diagnosis…'),
        tr('Сохраняем результат этой практики', 'Ushbu mashq natijasi saqlanmoqda', 'Saving this practice result')
      );

      await createLatestDiagnosis();

      setCardState(
        button,
        tr('AI-диагностика готова', 'AI diagnostika tayyor', 'AI diagnosis is ready'),
        tr('Открываем сохранённую рекомендацию', 'Saqlangan tavsiya ochilmoqda', 'Opening saved recommendation')
      );

      setTimeout(openArchiveAfterCreate, 250);
    } catch (error) {
      console.warn('[AI Diagnosis Lab] create_latest_practice_ai_diagnosis failed:', error);
      setCardState(
        button,
        tr('AI-диагностика', 'AI diagnostika', 'AI diagnosis'),
        tr('Не удалось сохранить. Попробуйте пройти практику ещё раз.', 'Saqlanmadi. Mashqni yana bir marta bajarib ko‘ring.', 'Could not save. Try completing practice again.')
      );
    } finally {
      button.disabled = false;
    }
  }, true);
})();
