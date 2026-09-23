/* Same-pack learning review. Optional, OFF by default; never replaces Core APIs.
 * This narrowly bridges the existing native plan button to an ATOMIC, separately
 * authorized noncredit review. Original sessions, plans and answers are retained.
 */
(() => {
  'use strict';
  const internal = window.iClubExamPrepHostInternal;
  if (window.iClubExamPrepWeeklyFlowEnabled !== true ||
      !internal || internal.weeklyReviewUi ||
      internal.weeklyFlowApi?.version !== 'weekly_flow_adapter_v1' ||
      typeof internal.weeklyFlowApi.review !== 'function') return;
  const original = internal.weeklyFlowApi;
  const VERSION = 'learning_review_ui_v1';
  const texts = Object.freeze({
    ru: {
      button: 'Повторить задания',
      note: 'Вы уже работали с этими заданиями. Повторите их, чтобы разобраться в ошибках. Это учебное повторение, а не новая независимая проверка знаний. Предыдущие ответы сохранены.'
    },
    uz: {
      button: 'Topshiriqlarni takrorlash',
      note: 'Siz bu topshiriqlarni avval bajargansiz. Xatolarni tushunish uchun ularni qayta ishlang. Bu o‘quv takrori, yangi mustaqil bilim tekshiruvi emas. Oldingi javoblaringiz saqlangan.'
    },
    en: {
      button: 'Review these questions',
      note: 'You have seen these questions before. Work through them again to understand your mistakes. This is learning review, not a new independent knowledge check. Your earlier answers are saved.'
    }
  });
  const root = () => document.querySelector('#exam-prep-host-root');
  const language = () => {
    const value = String(window.i18n?.getLang?.() || document.documentElement.lang || 'ru').toLowerCase();
    return Object.hasOwn(texts, value) ? value : 'ru';
  };
  const uuid = value => typeof value === 'string' &&
    /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(value);
  function active(component, sessionId) {
    if ((component !== 'P1' && component !== 'P5') || !uuid(sessionId)) return;
    internal.weeklyReviewActive = Object.freeze({ component, sessionId });
    showQuestionNote();
  }
  // Only one learner screen is visible. On ANY new ordinary plan/assessment
  // (including a switch P5 -> P1), remove the previous screen's review marker.
  function forget() {
    internal.weeklyReviewActive = null;
    root()?.querySelectorAll('[data-ep-learning-review-note]').forEach(note => note.remove());
  }
  function showQuestionNote() {
    if (window.iClubExamPrepWeeklyFlowEnabled !== true || !internal.weeklyReviewActive ||
        original.allowed(internal.weeklyReviewActive.component)) return;
    const host = root();
    if (!host || host.hidden || host.getAttribute('aria-hidden') === 'true') return;
    const question = host.querySelector('.ep-live-qtext');
    const card = question?.closest('.ep-live-card');
    // A review marker must never label a timed examination or paper attempt.
    if (!card || card.querySelector('[data-ep-live-end],[data-ep-live-timer]')) return;
    if (card.querySelector('[data-ep-learning-review-note]')) {
      const existing = card.querySelector('[data-ep-learning-review-note]');
      const expected = texts[language()].note;
      if (existing.textContent !== expected) existing.textContent = expected;
      return;
    }
    const notice = document.createElement('div');
    notice.className = 'ep-live-notice ep-learning-review-notice';
    notice.setAttribute('role', 'note');
    notice.dataset.epLearningReviewNote = 'true';
    notice.textContent = texts[language()].note;
    question.before(notice);
  }
  function markGoal(component, goalId, planId, data) {
    if (!data || data.status !== 'review_ready' || data.component_code !== component ||
        data.goal_id !== goalId || data.plan_id !== planId ||
        data.reason !== 'same_pack_learning_review' || data.fresh_assessment !== false ||
        !Number.isInteger(data.priority_order) || data.priority_order < 1 || data.priority_order > 3) return;
    const host = root();
    if (!host || host.hidden || host.getAttribute('aria-hidden') === 'true') return;
    const heading = host.querySelector('.ep-live-head strong')?.textContent || '';
    if (!heading.startsWith(component + ' · ')) return;
    const button = host.querySelector(`[data-ep-live-plan-item="${data.priority_order}"]`);
    const row = button?.closest('.ep-live-plan-item');
    if (!button || button.disabled || !row || row.dataset.epLearningReviewGoal === goalId) return;
    row.dataset.epLearningReviewGoal = goalId;
    button.textContent = texts[language()].button;
    const note = document.createElement('small');
    note.className = 'ep-live-meta ep-learning-review-plan-note';
    note.dataset.epLearningReviewPlanNote = 'true';
    note.textContent = texts[language()].note;
    row.firstElementChild?.append(note);
  }
  const bridged = Object.freeze({
    ...original,
    async recover(component) {
      const result = await original.recover(component);
      if (result.ok && ['resume','ready_to_finalize'].includes(result.data.status) &&
          result.data.learning_review === true && uuid(result.data.session_id)) {
        active(component, result.data.session_id);
      } else if (result.ok && ['none','resume','ready_to_finalize'].includes(result.data.status)) {
        forget();
      }
      return result;
    },
    async plan(component) {
      const result = await original.plan(component);
      if (result.ok && result.data.status === 'resume_first' &&
          result.data.recovery?.learning_review === true && uuid(result.data.recovery.session_id)) {
        active(component, result.data.recovery.session_id);
      } else if (result.ok && (['created','existing'].includes(result.data.status) ||
          result.data.status === 'resume_first')) forget();
      return result;
    },
    async goal(component, goalId, planId) {
      const result = await original.goal(component, goalId, planId);
      if (result.ok) markGoal(component, goalId, planId, result.data);
      return result;
    },
    async authorize(component, goalId, planId) {
      const decision = await original.authorize(component, goalId, planId);
      if (!decision.ok) return decision;
      if (decision.data.status === 'authorized') forget();
      if (decision.data.status === 'resume_existing_session_first') {
        if (decision.data.recovery?.learning_review === true &&
            uuid(decision.data.recovery.session_id)) {
          active(component, decision.data.recovery.session_id);
        } else forget();
      }
      if (decision.data.status !== 'review_ready') return decision;
      // Called solely from a user click. The backend atomically authorizes AND
      // starts a known-question noncredit attempt; never fake an authorization.
      const requestKey = 'review-' + component + '-' + goalId + '-' +
        Date.now().toString(36) + '-' + Math.random().toString(36).slice(2, 10);
      const started = await original.review(component, goalId, planId, requestKey);
      if (!started.ok) {
        if (started.reason === 'review_outcome_unknown' &&
            started.recovery?.learning_review === true && uuid(started.recovery.session_id)) {
          active(component, started.recovery.session_id);
          return Object.freeze({ok:true, data:{status:'resume',session_id:started.recovery.session_id,
            component_code:component}});
        }
        return started;
      }
      if (started.data.status === 'started' && uuid(started.data.session_id)) {
        active(component, started.data.session_id);
        return Object.freeze({ok:true,data:{status:'resume',session_id:started.data.session_id,
          component_code:component}});
      }
      if (started.data.status === 'resume_existing_session_first' &&
          uuid(started.data.session_id)) {
        // Two devices may race AFTER the first recovery read: the review start
        // then returns a bare session ID. Prove it belongs to a review using a
        // fresh server recovery; never label a normal active session by guess.
        const proof = await original.recover(component);
        if (!proof.ok || !['resume','ready_to_finalize'].includes(proof.data?.status) ||
            proof.data.session_id !== started.data.session_id) {
          return Object.freeze({ok:false,reason:'review_resume_unverified'});
        }
        if (proof.data.learning_review === true) active(component, proof.data.session_id);
        else forget();
        return Object.freeze({ok:true,data:{status:'resume',session_id:proof.data.session_id,
          component_code:component}});
      }
      return started;
    }
  });
  internal.weeklyFlowApi = bridged;
  const attach = () => {
    const host = root();
    if (!host) return;
    const observer = new MutationObserver(() => {
      if (window.iClubExamPrepWeeklyFlowEnabled !== true || host.hidden ||
          host.getAttribute('aria-hidden') === 'true') { forget(); return; }
      showQuestionNote();
    });
    observer.observe(host,{childList:true,subtree:true,attributes:true,attributeFilter:['hidden','aria-hidden']});
    showQuestionNote();
  };
  if (root()) attach();
  else document.addEventListener('DOMContentLoaded',attach,{once:true});
  internal.weeklyReviewUi = Object.freeze({version:VERSION});
})();