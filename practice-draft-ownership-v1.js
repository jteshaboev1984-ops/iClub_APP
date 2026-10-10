/* iClub Practice — additive local-draft ownership vault v1.
 * Dormant until deliberately integrated into app.js and covered by release tests.
 * Never deletes legacy device-wide drafts, unrelated localStorage or server data.
 * The caller must supply a UID verified by Supabase auth.getUser (not a profile).
 */
(function (global) {
  'use strict';
  const OLD_KEY = 'iclub_practice_draft_v1';
  const PREFIX = 'iclub_practice_draft_v2:';
  const MARK_PREFIX = 'iclub_practice_legacy_claimed_v2:';
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  function verifiedUid(value) {
    if (typeof value !== 'string' || !UUID_RE.test(value)) throw Error('draft_authenticated_uid_required');
    return value.toLowerCase();
  }
  function parsed(raw) {
    try { const x = raw ? JSON.parse(raw) : null; return x && typeof x === 'object' && !Array.isArray(x) ? x : null; }
    catch { return null; }
  }
  function sessionId(draft) {
    const q = draft?.quiz;
    const value = Number(q?.safeDrillSessionId || q?.safeSessionId || 0);
    return Number.isSafeInteger(value) && value > 0 ? value : null;
  }
  function validDraft(draft) {
    return !!(draft && draft.status === 'paused' && typeof draft.subjectKey === 'string' &&
      draft.subjectKey.length > 0 && draft.quiz?.mode === 'practice' &&
      sessionId(draft) && Array.isArray(draft.quiz.questions) && draft.quiz.questions.length > 0);
  }
  function storage() {
    if (!global.localStorage) throw Error('draft_local_storage_unavailable');
    return global.localStorage;
  }
  function key(uid) { return PREFIX + verifiedUid(uid); }
  function mark(uid) { return MARK_PREFIX + verifiedUid(uid); }
  function sanitizeQuestion(question) {
    if (!question || typeof question !== 'object') return question;
    const out = { ...question };
    for (const field of ['correct_answer', 'correctAnswer', 'correctIndex', 'correct_index',
      'answer_key', 'answerKey', 'explanation', 'explanation_ru', 'explanation_uz',
      'explanation_en', 'inputKind', 'inputHint']) delete out[field];
    return out;
  }
  function safeCopy(draft, uid) {
    const q = { ...draft.quiz, qTimerId: null, qEndsAtMono: null };
    // Paused storage is never a source of academic correctness authority.
    if (Array.isArray(q.correct)) q.correct = q.correct.map(() => false);
    q.questions = q.questions.map(sanitizeQuestion);
    return { ...draft, quiz: q, ownerUserId: verifiedUid(uid) };
  }
  function readForUid(uid) {
    const owner = verifiedUid(uid);
    const draft = parsed(storage().getItem(key(owner)));
    if (!validDraft(draft) || draft.ownerUserId !== owner ||
        (draft.quiz?.practiceOwnerUid && draft.quiz.practiceOwnerUid !== owner)) return null;
    return draft;
  }
  function writeForUid(uid, draft, expectedSessionId = null) {
    const owner = verifiedUid(uid);
    if (!validDraft(draft) || (draft.ownerUserId && draft.ownerUserId !== owner) ||
        (draft.quiz?.practiceOwnerUid && draft.quiz.practiceOwnerUid !== owner) ||
        (draft.pendingTopicSwitch?.userId && draft.pendingTopicSwitch.userId !== owner))
      throw Error('draft_invalid_or_owner_mismatch');
    const prior = readForUid(owner);
    const priorId = sessionId(prior), newId = sessionId(draft);
    if (priorId && priorId !== newId && Number(expectedSessionId) !== priorId)
      throw Error('draft_existing_session_conflict');
    const copy = safeCopy(draft, owner);
    storage().setItem(key(owner), JSON.stringify(copy));
    // A newly started session supersedes device-wide legacy for this owner.
    // Preserve legacy bytes, but do not resurrect them after the new draft clears.
    storage().setItem(mark(owner), '1');
    return copy;
  }
  function clearForUid(uid, expectedSessionId) {
    const owner = verifiedUid(uid);
    const current = readForUid(owner);
    if (!current || !Number.isSafeInteger(Number(expectedSessionId)) ||
      sessionId(current) !== Number(expectedSessionId)) return false;
    storage().removeItem(key(owner));
    return true;
  }
  // Legacy contains no authenticated identity. Never display or take possession
  // based on its subject, local profile or question text. Only authenticated,
  // owner-scoped server resume may prove the session belongs to this account.
  async function claimLegacyForUid(uid, verifyOwnedSession, readCurrentAuthenticatedUid) {
    const owner = verifiedUid(uid);
    if (typeof verifyOwnedSession !== 'function' || typeof readCurrentAuthenticatedUid !== 'function')
      throw Error('draft_server_proof_required');
    const existing = readForUid(owner);
    if (existing) return existing;
    const vault = storage();
    if (vault.getItem(mark(owner)) === '1') return null;
    const raw = vault.getItem(OLD_KEY);
    const legacy = parsed(raw);
    if (!validDraft(legacy)) return null;
    // Legacy might have been tagged by an older release: never claim someone else's.
    if (legacy.ownerUserId && legacy.ownerUserId !== owner) return null;
    if (legacy.quiz?.practiceOwnerUid && legacy.quiz.practiceOwnerUid !== owner) return null;
    if (legacy.pendingTopicSwitch?.userId && legacy.pendingTopicSwitch.userId !== owner) return null;
    let proved = false;
    try { proved = (await verifyOwnedSession(legacy)) === true; } catch { return null; }
    if (!proved) return null;
    let liveUid = null;
    try { liveUid = verifiedUid(await readCurrentAuthenticatedUid()); } catch { return null; }
    if (liveUid !== owner) return null;
    // Do not overwrite a changed legacy draft or a parallel tab's newer vault.
    if (vault.getItem(OLD_KEY) !== raw) return null;
    const concurrent = readForUid(owner);
    if (concurrent) return concurrent;
    const copy = writeForUid(owner, legacy);
    vault.setItem(mark(owner), '1');
    // Old key is deliberately retained for rollback and recovery.
    return copy;
  }
  global.iClubPracticeDraftVaultV1 = Object.freeze({
    version: '1', readForUid, writeForUid, clearForUid, claimLegacyForUid, sessionId
  });
})(globalThis);
