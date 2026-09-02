(() => {
  "use strict";

  const API_VERSION = "p0-02-v3";

  function client() {
    const sb = window.sb || null;
    if (!sb || typeof sb.rpc !== "function") {
      throw new Error("supabase_client_unavailable");
    }
    return sb;
  }

  async function rpc(name, args) {
    const { data, error } = await client().rpc(name, args || {});
    if (error) throw error;
    return data;
  }

  function requirePositiveInt(value, name) {
    const n = Number(value);
    if (!Number.isInteger(n) || n <= 0) throw new Error(`invalid_${name}`);
    return n;
  }

  function makeClientSessionId(prefix) {
    const p = String(prefix || "session").replace(/[^a-z0-9_-]/gi, "").slice(0, 24) || "session";
    const uuid = globalThis.crypto?.randomUUID?.();
    if (uuid) return `${p}_${uuid}`.slice(0, 128);
    return `${p}_${Date.now()}_${Math.random().toString(36).slice(2, 12)}`.slice(0, 128);
  }

  const practice = Object.freeze({
    async start({ poolId, questionIds = null, clientSessionId = null }) {
      const pPoolId = requirePositiveInt(poolId, "pool_id");
      const ids = Array.isArray(questionIds)
        ? questionIds.map(x => requirePositiveInt(x, "question_id"))
        : null;
      return rpc("start_practice_session_safe_v3", {
        p_pool_id: pPoolId,
        p_client_session_id: clientSessionId || makeClientSessionId("practice"),
        p_question_ids: ids
      });
    },

    async questions(sessionId) {
      return rpc("get_practice_session_questions_safe_v3", {
        p_session_id: requirePositiveInt(sessionId, "session_id")
      });
    },

    async submit({ sessionId, questionId, userAnswer = "", pickedIndex = null, timeSpent = 0 }) {
      return rpc("submit_practice_session_answer_safe_v3", {
        p_session_id: requirePositiveInt(sessionId, "session_id"),
        p_question_id: requirePositiveInt(questionId, "question_id"),
        p_user_answer: userAnswer == null ? "" : String(userAnswer),
        p_picked_index: Number.isInteger(Number(pickedIndex)) ? Number(pickedIndex) : null,
        p_time_spent: Math.max(0, Math.floor(Number(timeSpent) || 0))
      });
    },

    async finalize({ sessionId, totalTime = 0 }) {
      return rpc("finalize_practice_session_safe_v3", {
        p_session_id: requirePositiveInt(sessionId, "session_id"),
        p_total_time: Math.max(0, Math.floor(Number(totalTime) || 0))
      });
    },

    async review(attemptId) {
      return rpc("get_practice_review_safe_v3", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    }
  });

  const tour = Object.freeze({
    async start({ tourId, clientSessionId = null }) {
      return rpc("start_tour_attempt_safe_v3", {
        p_tour_id: requirePositiveInt(tourId, "tour_id"),
        p_client_session_id: clientSessionId || makeClientSessionId("tour")
      });
    },

    async questions(attemptId) {
      return rpc("get_tour_session_questions_safe_v3", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    },

    async submit({ attemptId, questionId, userAnswer = "", pickedIndex = null, timeSpent = 0, answered = true, finishReason = null }) {
      return rpc("submit_tour_answer_safe_v3", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id"),
        p_question_id: requirePositiveInt(questionId, "question_id"),
        p_user_answer: userAnswer == null ? "" : String(userAnswer),
        p_picked_index: Number.isInteger(Number(pickedIndex)) ? Number(pickedIndex) : null,
        p_time_spent: Math.max(0, Math.floor(Number(timeSpent) || 0)),
        p_answered: answered !== false,
        p_finish_reason: finishReason == null ? null : String(finishReason)
      });
    },

    async finalize({ attemptId, totalTime = 0, status = "submitted" }) {
      const allowed = new Set(["submitted", "time_expired", "anti_cheat", "abandoned"]);
      const safeStatus = String(status || "submitted");
      if (!allowed.has(safeStatus)) throw new Error("invalid_tour_status");
      return rpc("finalize_tour_attempt_safe_v3", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id"),
        p_total_time: Math.max(0, Math.floor(Number(totalTime) || 0)),
        p_status: safeStatus
      });
    },

    async review(attemptId) {
      return rpc("get_tour_review_safe_v3", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    }
  });

  window.iclubSafeAssessment = Object.freeze({
    version: API_VERSION,
    makeClientSessionId,
    practice,
    tour
  });
})();
