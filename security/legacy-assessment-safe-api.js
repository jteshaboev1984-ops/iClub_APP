(() => {
  "use strict";

  const API_VERSION = "p0-02-v4-aux2-tour";
  const LEGACY_PRACTICE_MAX_QUESTIONS = 10;

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

  function normalizePickedIndex(value) {
    if (value === null || value === undefined || value === "") return null;
    const n = Number(value);
    if (!Number.isInteger(n) || n < 0 || n > 25) throw new Error("invalid_picked_index");
    return n;
  }

  function normalizeQuestionIds(values) {
    const ids = (Array.isArray(values) ? values : [])
      .map(value => requirePositiveInt(value, "question_id"));
    if (!ids.length || ids.length > LEGACY_PRACTICE_MAX_QUESTIONS) {
      throw new Error("invalid_question_ids");
    }
    if (new Set(ids).size !== ids.length) throw new Error("duplicate_question_ids");
    return ids;
  }

  function makeClientSessionId(prefix) {
    const p = String(prefix || "session").replace(/[^a-z0-9_-]/gi, "").slice(0, 24) || "session";
    const uuid = globalThis.crypto?.randomUUID?.();
    if (uuid) return `${p}_${uuid}`.slice(0, 128);
    return `${p}_${Date.now()}_${Math.random().toString(36).slice(2, 12)}`.slice(0, 128);
  }

  const practiceDrill = Object.freeze({
    async startTopic({ subjectKey, topic, subtopic = null, clientSessionId = null }) {
      return rpc("start_practice_topic_drill_safe_v4", {
        p_subject_key: String(subjectKey || ""),
        p_topic: String(topic || ""),
        p_subtopic: subtopic == null || String(subtopic).trim() === "" ? null : String(subtopic),
        p_client_session_id: clientSessionId || makeClientSessionId("practice_topic")
      });
    },

    async startMistakes({ subjectKey, questionIds, clientSessionId = null }) {
      return rpc("start_practice_mistakes_drill_safe_v4", {
        p_subject_key: String(subjectKey || ""),
        p_question_ids: normalizeQuestionIds(questionIds),
        p_client_session_id: clientSessionId || makeClientSessionId("practice_mistakes")
      });
    },

    async startPast({ subjectKey, clientSessionId = null }) {
      return rpc("start_practice_past_drill_safe_v4", {
        p_subject_key: String(subjectKey || ""),
        p_client_session_id: clientSessionId || makeClientSessionId("practice_past")
      });
    },

    async questions(sessionId) {
      return rpc("get_practice_drill_resume_safe_v4", {
        p_session_id: requirePositiveInt(sessionId, "session_id")
      });
    },

    async submit({ sessionId, questionId, userAnswer = "", pickedIndex = null, timeSpent = 0 }) {
      return rpc("submit_practice_drill_answer_safe_v4", {
        p_session_id: requirePositiveInt(sessionId, "session_id"),
        p_question_id: requirePositiveInt(questionId, "question_id"),
        p_user_answer: userAnswer == null ? "" : String(userAnswer),
        p_picked_index: normalizePickedIndex(pickedIndex),
        p_time_spent: Math.max(0, Math.floor(Number(timeSpent) || 0))
      });
    }
  });

  const practice = Object.freeze({
    async start({ poolId, clientSessionId = null }) {
      return rpc("start_practice_session_auto_safe_v4", {
        p_pool_id: requirePositiveInt(poolId, "pool_id"),
        p_client_session_id: clientSessionId || makeClientSessionId("practice")
      });
    },

    async questions(sessionId) {
      return rpc("get_practice_session_resume_safe_v4", {
        p_session_id: requirePositiveInt(sessionId, "session_id")
      });
    },

    async submit({ sessionId, questionId, userAnswer = "", pickedIndex = null, timeSpent = 0 }) {
      return rpc("submit_practice_session_answer_safe_v4", {
        p_session_id: requirePositiveInt(sessionId, "session_id"),
        p_question_id: requirePositiveInt(questionId, "question_id"),
        p_user_answer: userAnswer == null ? "" : String(userAnswer),
        p_picked_index: normalizePickedIndex(pickedIndex),
        p_time_spent: Math.max(0, Math.floor(Number(timeSpent) || 0))
      });
    },

    async finalize({ sessionId, totalTime = 0 }) {
      return rpc("finalize_practice_session_safe_v4", {
        p_session_id: requirePositiveInt(sessionId, "session_id"),
        p_total_time: Math.max(0, Math.floor(Number(totalTime) || 0))
      });
    },

    async review(attemptId) {
      return rpc("get_practice_review_full_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    },

    async recentMistakes({ subjectKey, topic = null, subtopic = null, limit = 10 }) {
      return rpc("get_recent_practice_mistakes_safe_v4", {
        p_subject_key: String(subjectKey || ""),
        p_topic: topic == null || String(topic).trim() === "" ? null : String(topic),
        p_subtopic: subtopic == null || String(subtopic).trim() === "" ? null : String(subtopic),
        p_limit: Math.max(1, Math.min(10, Math.floor(Number(limit) || 10)))
      });
    },

    drill: practiceDrill
  });

  const tour = Object.freeze({
    async preflight(tourId) {
      return rpc("get_tour_preflight_questions_safe_v4", {
        p_tour_id: requirePositiveInt(tourId, "tour_id")
      });
    },

    async start({ tourId, clientSessionId = null }) {
      return rpc("start_tour_attempt_safe_v4", {
        p_tour_id: requirePositiveInt(tourId, "tour_id"),
        p_client_session_id: clientSessionId || makeClientSessionId("tour")
      });
    },

    async questions(attemptId) {
      return rpc("get_tour_session_questions_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    },

    async submit({ attemptId, questionId, userAnswer = "", pickedIndex = null, timeSpent = 0, answered = true, finishReason = null }) {
      return rpc("submit_tour_answer_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id"),
        p_question_id: requirePositiveInt(questionId, "question_id"),
        p_user_answer: userAnswer == null ? "" : String(userAnswer),
        p_picked_index: normalizePickedIndex(pickedIndex),
        p_time_spent: Math.max(0, Math.floor(Number(timeSpent) || 0)),
        p_answered: answered !== false,
        p_finish_reason: finishReason == null ? null : String(finishReason)
      });
    },

    async finalize({ attemptId, totalTime = 0, status = "submitted" }) {
      const allowed = new Set(["submitted", "time_expired", "anti_cheat", "abandoned"]);
      const safeStatus = String(status || "submitted");
      if (!allowed.has(safeStatus)) throw new Error("invalid_tour_status");

      return rpc("finalize_tour_attempt_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id"),
        p_total_time: Math.max(0, Math.floor(Number(totalTime) || 0)),
        p_status: safeStatus
      });
    },

    async review(attemptId) {
      return rpc("get_tour_review_full_safe_v4", {
        p_attempt_id: requirePositiveInt(attemptId, "attempt_id")
      });
    }
  });

  window.iclubSafeAssessment = Object.freeze({
    version: API_VERSION,
    legacyPracticeMaxQuestions: LEGACY_PRACTICE_MAX_QUESTIONS,
    makeClientSessionId,
    practice,
    tour
  });
})();
