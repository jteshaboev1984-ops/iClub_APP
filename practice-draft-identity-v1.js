/* iClub Practice: authenticated local draft boundary (local staging only).
 * No DB writes and no deletion of legacy local drafts.
 * Requires practice-draft-ownership-v1.js to be loaded first.
 */
(function (global) {
  'use strict';
  const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  let verifiedOwner = null;
  let ownerClient = null;
  let authSubscription = null;
  let inFlight = null;
  let authEpoch = 0;

  function normalized(value) {
    return typeof value === 'string' && UUID_RE.test(value) ? value.toLowerCase() : null;
  }
  function resetBinding() {
    verifiedOwner = null;
    authEpoch += 1;
    inFlight = null;
  }
  function client() {
    const sb = global.sb;
    return sb?.auth?.getUser && typeof sb.auth.getUser === 'function' ? sb : null;
  }
  function vault() {
    return global.iClubPracticeDraftVaultV1 || null;
  }
  function subscribeIfNeeded(sb) {
    if (ownerClient === sb) return;
    try { authSubscription?.unsubscribe?.(); } catch {}
    ownerClient = sb;
    resetBinding();
    authSubscription = null;
    try {
      const result = sb.auth.onAuthStateChange?.((event, session) => {
        const uid = normalized(session?.user?.id);
        if (event === 'SIGNED_OUT' || (verifiedOwner && uid !== verifiedOwner)) {
          resetBinding();
          try { global.dispatchEvent?.(new CustomEvent('iclub:practice-identity-invalidated')); } catch {}
        }
      });
      authSubscription = result?.data?.subscription || null;
    } catch { /* A fresh getUser check still runs on every entry. */ }
  }
  async function freshUid(sb) {
    if (!sb?.auth?.getUser) return null;
    try {
      const result = await sb.auth.getUser();
      if (result?.error) return null;
      return normalized(result?.data?.user?.id);
    } catch { return null; }
  }
  function serverProofClient(sb) {
    return async function prove(draft) {
      const q = draft?.quiz;
      const id = Number(q?.safeDrillSessionId || q?.safeSessionId || 0);
      const expected = Array.isArray(q?.questions) ? q.questions.map(x => Number(x?.id)) : [];
      if (!Number.isSafeInteger(id) || id < 1 || !expected.length ||
          expected.some(x => !Number.isSafeInteger(x) || x < 1) ||
          new Set(expected).size !== expected.length) return false;
      const rpc = q?.safeDrillSessionId
        ? 'get_practice_drill_resume_safe_v4'
        : 'get_practice_session_resume_safe_v4';
      if (!sb?.rpc) return false;
      const {data, error} = await sb.rpc(rpc,{p_session_id:id});
      if (error || !Array.isArray(data) || data.length !== expected.length) return false;
      const actual = data.map(x => Number(x?.id));
      return actual.every((value, index) => value === expected[index]);
    };
  }
  async function bind() {
    const sb = client(), v = vault();
    if (!sb || !v) { resetBinding(); return null; }
    subscribeIfNeeded(sb);
    if (inFlight) return inFlight;
    const epoch = authEpoch;
    const promise = (async () => {
      const owner = await freshUid(sb);
      if (!owner || epoch !== authEpoch) return null;
      // Claim is additive: server RPC is scoped to auth.uid and legacy remains intact.
      try { await v.claimLegacyForUid(owner, serverProofClient(sb), () => freshUid(sb)); }
      catch { /* Legacy recovery failure cannot make another person's draft visible. */ }
      if (epoch !== authEpoch || sb !== client()) return null;
      if ((await freshUid(sb)) !== owner || epoch !== authEpoch) return null;
      verifiedOwner = owner;
      return owner;
    })();
    inFlight = promise;
    try { return await promise; }
    finally { if (inFlight === promise) inFlight = null; }
  }
  function currentUid() { return verifiedOwner; }
  function read() { return verifiedOwner ? vault()?.readForUid(verifiedOwner) || null : null; }
  function save(draft) {
    if (!verifiedOwner || !vault()) throw Error('draft_owner_not_bound');
    if (draft?.quiz?.practiceOwnerUid && normalized(draft.quiz.practiceOwnerUid) !== verifiedOwner)
      throw Error('draft_active_quiz_owner_mismatch');
    return vault().writeForUid(verifiedOwner,draft);
  }
  function clear(expectedSessionId) {
    if (!verifiedOwner || !vault()) return false;
    return vault().clearForUid(verifiedOwner,expectedSessionId);
  }
  function ownsActiveQuiz(quiz) {
    return !!verifiedOwner && normalized(quiz?.practiceOwnerUid) === verifiedOwner;
  }
  global.iClubPracticeDraftIdentityV1 = Object.freeze({
    bind,currentUid,read,save,clear,ownsActiveQuiz,resetBinding
  });
})(globalThis);
