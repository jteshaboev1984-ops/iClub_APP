/* iClub Practice active-session isolation — isolated release candidate.
 * New active quizzes stay under an authenticated per-user key. Legacy global
 * state is copied to a quarantine key, never silently deleted or shown to a
 * different account. Recovery uses an existing auth-scoped read-only resume RPC.
 */
(function (global) {
  'use strict';
  const PREFIX = 'iclub_practice_active_v1:';
  const LEGACY = 'iclub_practice_active_legacy_v1:';
  const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  let writtenSession = null;
  let writtenOwner = null;
  function uid(v) { return typeof v === 'string' && UUID.test(v) ? v.toLowerCase() : null; }
  function session(quiz) {
    const n = Number(quiz?.safeDrillSessionId || quiz?.safeSessionId || 0);
    return Number.isSafeInteger(n) && n > 0 ? n : null;
  }
  function quizOk(quiz) {
    return quiz?.mode === 'practice' && session(quiz) && Array.isArray(quiz.questions) && quiz.questions.length > 0;
  }
  function saved(raw) {
    try { const x = JSON.parse(raw); return x && typeof x === 'object' ? x : null; } catch { return null; }
  }
  function quarantine(quiz) {
    if (!quizOk(quiz)) return false;
    const key = LEGACY + session(quiz);
    // The original remains in the legacy iClub state until this copy succeeds.
    if (!global.localStorage.getItem(key)) global.localStorage.setItem(key, JSON.stringify(quiz));
    return !!global.localStorage.getItem(key);
  }
  function sanitizeLoaded(state) {
    if (state?.quiz?.mode === 'practice') {
      try {
        if (!quarantine(state.quiz)) return { ...state, __practiceStorageReadOnly: true, quiz: null, quizLock: null };
      } catch {
        return { ...state, __practiceStorageReadOnly: true, quiz: null, quizLock: null };
      }
      return { ...state, quiz: null, quizLock: null };
    }
    return state;
  }
  function persist(state) {
    if (state.__practiceStorageReadOnly) return false;
    const quiz = state.quiz;
    const identity = global.iClubPracticeDraftIdentityV1;
    if (quiz?.mode === 'practice') {
      if (!quizOk(quiz) || !identity?.ownsActiveQuiz(quiz)) throw Error('practice_active_owner_unverified');
      const owner = uid(identity.currentUid());
      if (!owner) throw Error('practice_active_identity_missing');
      const key = PREFIX + owner;
      const snapshot = { ...quiz, qTimerId: null, qEndsAtMono: null };
      global.localStorage.setItem(key, JSON.stringify(snapshot));
      writtenOwner = owner;
      writtenSession = session(quiz);
      // Non-Practice app preferences remain at their original key.
      state.quiz = null;
      state.quizLock = null;
    } else if (writtenOwner && writtenSession) {
      const key = PREFIX + writtenOwner;
      if (session(saved(global.localStorage.getItem(key))) === writtenSession) {
        global.localStorage.removeItem(key);
      }
      writtenOwner = null;
      writtenSession = null;
    }
    return true;
  }
  async function proof(quiz, sb, expectedOwner) {
    if (!quizOk(quiz) || !sb?.rpc || !sb?.auth?.getUser) return false;
    const qOwner = uid(quiz.practiceOwnerUid);
    if (qOwner && qOwner !== expectedOwner) return false;
    let data;
    try {
      const r = await sb.rpc(quiz.safeDrillSessionId ? 'get_practice_drill_resume_safe_v4'
        : 'get_practice_session_resume_safe_v4', { p_session_id: session(quiz) });
      if (r?.error || !Array.isArray(r?.data)) return false;
      data = r.data;
    } catch { return false; }
    const ids = quiz.questions.map(q => Number(q.id));
    if (!ids.length || ids.some(id => !Number.isSafeInteger(id) || id < 1) ||
        data.length !== ids.length || data.some((row,i) => Number(row.id) !== ids[i])) return false;
    try {
      const user = await sb.auth.getUser();
      return !user?.error && uid(user?.data?.user?.id) === expectedOwner;
    } catch { return false; }
  }
  async function recoverAsPaused() {
    const identity = global.iClubPracticeDraftIdentityV1;
    const owner = await identity?.bind();
    const sb = global.sb;
    if (!uid(owner) || !sb || !identity || identity.currentUid() !== owner) return false;
    if (identity.read()) return false;
    const storage = global.localStorage;
    const keys = [PREFIX + owner];
    for (let i=0; i<storage.length && keys.length < 20; i++) {
      const key = storage.key(i);
      if (key?.startsWith(LEGACY)) keys.push(key);
    }
    for (const key of keys) {
      const quiz = saved(storage.getItem(key));
      if (!quizOk(quiz)) continue;
      if (!(await proof(quiz, sb, owner)) || identity.currentUid() !== owner) continue;
      const draft = {
        status:'paused', subjectKey:String(quiz.subjectKey || ''),
        practiceTourNo:Number(quiz.practiceTourNo || 1),
        practicePoolId:Number(quiz.practicePoolId || 0) || null,
        pausedAt:Date.now(),
        quiz:{...quiz,practiceOwnerUid:owner,paused:true,pauseStartedAt:Date.now()}
      };
      try {
        identity.save(draft);
        // Delete only the verified restored session copy; leave old legacy global
        // state untouched until the normal saveState rerenders a safe Home state.
        storage.removeItem(key);
        return true;
      } catch { return false; }
    }
    return false;
  }
  // Called on account change: do not delete the previous owner's active key.
  function detachWithoutDeleting() { writtenOwner = null; writtenSession = null; }
  global.iClubPracticeActiveStateV1 = Object.freeze({
    sanitizeLoaded, persist, recoverAsPaused, detachWithoutDeleting
  });
})(globalThis);
