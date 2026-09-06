(() => {
  "use strict";

  const root = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});
  const CONSENT_ACK = "I_CONSENT_TO_EXAM_PREP_CONTROLLED_BETA_V1";
  const REVOKE_ACK = "I_REVOKE_EXAM_PREP_CONTROLLED_BETA_V1";

  function fail(reason, error = null) {
    return Object.freeze({ ok: false, reason: String(reason || "unknown"), error: error || null });
  }

  async function rpc(name, args = {}) {
    try {
      const client = window.sb;
      if (!client || typeof client.rpc !== "function") return fail("supabase_unavailable");
      const { data, error } = await client.rpc(name, args || {});
      if (error) return fail("rpc_error", error);
      return Object.freeze({ ok: true, data });
    } catch (error) {
      return fail("rpc_exception", error);
    }
  }

  async function capabilities() {
    const result = await rpc("get_exam_prep_capabilities_v1");
    if (!result.ok) return result;
    const row = Array.isArray(result.data) ? result.data[0] : result.data;
    if (!row || typeof row !== "object") return fail("capability_payload_missing");
    const data = Object.freeze({
      programKey: String(row.program_key || "math_as_p1_p5"),
      rolloutState: String(row.rollout_state || "off"),
      coreAccess: row.core_access === true,
      aiAssist: row.ai_assist === true,
      mentorCareEntitled: row.mentor_care_entitled === true,
      mentorAssignmentActive: row.mentor_assignment_active === true,
      mentorAuthority: row.mentor_authority === true,
      killSwitch: row.kill_switch !== false
    });
    root.lastCapabilities = data;
    return Object.freeze({ ok: true, data });
  }

  function normalizeInvitationItem(row) {
    if (!row || typeof row !== "object") return null;
    const cohortKey = String(row.cohort_key || "").trim();
    if (!cohortKey) return null;
    return Object.freeze({
      cohortKey,
      cohortStatus: String(row.cohort_status || "draft"),
      capacity: Number(row.capacity || 0),
      monitoringHours: Number(row.monitoring_hours || 0),
      serviceMode: String(row.service_mode || "core"),
      activationWave: Number(row.activation_wave || 1),
      memberStatus: String(row.member_status || "candidate"),
      consentStatus: String(row.consent_status || "missing"),
      consentedAt: row.consented_at || null,
      revokedAt: row.revoked_at || null,
      consentScope: String(row.consent_scope || "exam_prep_controlled_beta_v1"),
      consentCopyVersion: String(row.consent_copy_version || "controlled_beta_v1_2026_09_04")
    });
  }

  async function betaInvitation() {
    const result = await rpc("get_my_exam_prep_beta_invitation_v1");
    if (!result.ok) return result;
    const row = Array.isArray(result.data) ? result.data[0] : result.data;
    if (!row || typeof row !== "object") return fail("beta_invitation_payload_missing");
    const invitations = Array.isArray(row.invitations)
      ? row.invitations.map(normalizeInvitationItem).filter(Boolean)
      : [];
    return Object.freeze({
      ok: true,
      data: Object.freeze({
        invited: row.invited === true && invitations.length > 0,
        consentScope: String(row.consent_scope || "exam_prep_controlled_beta_v1"),
        consentCopyVersion: String(row.consent_copy_version || "controlled_beta_v1_2026_09_04"),
        invitations: Object.freeze(invitations)
      })
    });
  }

  async function grantBetaConsent(cohortKey) {
    const key = String(cohortKey || "").trim();
    if (!key) return fail("beta_cohort_key_required");
    return rpc("grant_my_exam_prep_beta_consent_v1", { p_cohort_key: key, p_acknowledgement: CONSENT_ACK });
  }

  async function revokeBetaConsent(cohortKey) {
    const key = String(cohortKey || "").trim();
    if (!key) return fail("beta_cohort_key_required");
    return rpc("revoke_my_exam_prep_beta_consent_v1", { p_cohort_key: key, p_acknowledgement: REVOKE_ACK });
  }

  async function examProfile() {
    const result = await rpc("get_exam_prep_exam_profile_v1");
    if (!result.ok) return result;
    const row = Array.isArray(result.data) ? result.data[0] : result.data;
    return Object.freeze({ ok: true, data: row && typeof row === "object" ? row : null });
  }

  async function saveExamProfile({ examSeries = null, targetGrade = null, totalHours, mathHours } = {}) {
    return rpc("save_exam_prep_exam_profile_v1", {
      p_exam_series: String(examSeries || "").trim() || null,
      p_target_grade: String(targetGrade || "").trim() || null,
      p_total_student_hours_available: Number(totalHours),
      p_mathematics_hours_budget: Number(mathHours)
    });
  }

  async function diagnosticProgress(componentCode) {
    return rpc("get_exam_prep_diagnostic_progress_safe_v1", { p_component_code: String(componentCode || "") });
  }

  async function startNextDiagnostic(componentCode, idempotencyKey) {
    return rpc("start_exam_prep_next_diagnostic_safe_v1", {
      p_component_code: String(componentCode || ""),
      p_idempotency_key: String(idempotencyKey || "")
    });
  }

  async function getPlacement(componentCode = null) {
    return rpc("get_exam_prep_placement_safe_v1", { p_component_code: componentCode || null });
  }

  async function getState(componentCode) {
    return rpc("get_exam_prep_state_safe_v1", { p_component_code: String(componentCode || "") });
  }

  async function getSession(sessionId, language = "en") {
    return rpc("get_exam_prep_session_safe_v1", { p_session_id: sessionId, p_language: language });
  }

  async function startSession(authorizationId, idempotencyKey) {
    return rpc("start_exam_prep_session_safe_v1", {
      p_authorization_id: authorizationId,
      p_idempotency_key: String(idempotencyKey || "")
    });
  }

  async function submitResponse(sessionId, itemOrder, payload, idempotencyKey, elapsedMs = null, language = "en") {
    return rpc("submit_exam_prep_response_safe_v1", {
      p_session_id: sessionId,
      p_item_order: Number(itemOrder),
      p_payload: payload || {},
      p_idempotency_key: String(idempotencyKey || ""),
      p_elapsed_ms: elapsedMs == null ? null : Math.max(0, Number(elapsedMs) || 0),
      p_language: language
    });
  }

  async function finalizeSession(sessionId, idempotencyKey) {
    return rpc("finalize_exam_prep_session_safe_v1", {
      p_session_id: sessionId,
      p_idempotency_key: String(idempotencyKey || "")
    });
  }

  async function weeklyPlan(componentCode) {
    return rpc("get_exam_prep_weekly_plan_safe_v1", { p_component_code: String(componentCode || "") });
  }

  async function generateWeeklyPlan(componentCode, recoveryMode = "normal") {
    return rpc("generate_exam_prep_weekly_plan_safe_v1", {
      p_component_code: String(componentCode || ""),
      p_recovery_mode: String(recoveryMode || "normal")
    });
  }

  async function timedCatalog(componentCode) {
    return rpc("get_exam_prep_timed_catalog_safe_v1", { p_component_code: String(componentCode || "") });
  }

  async function authorizeTimed(assessmentId) {
    return rpc("authorize_exam_prep_timed_safe_v1", { p_assessment_id: Number(assessmentId) });
  }

  async function finalizeTimed(sessionId, idempotencyKey, completionReason = "submitted") {
    return rpc("finalize_exam_prep_timed_safe_v1", {
      p_session_id: sessionId,
      p_idempotency_key: String(idempotencyKey || ""),
      p_completion_reason: completionReason
    });
  }

  async function timedResult(sessionId) {
    return rpc("get_exam_prep_timed_result_safe_v1", { p_session_id: sessionId });
  }

  async function timedReviewPack(sessionId, language = "en") {
    return rpc("get_exam_prep_timed_review_pack_safe_v1", { p_session_id: sessionId, p_language: language });
  }

  async function submitTimedSelfMark(sessionId, itemOrder, marks, idempotencyKey, reviewNote = null) {
    return rpc("submit_exam_prep_timed_written_self_mark_safe_v1", {
      p_session_id: sessionId,
      p_item_order: Number(itemOrder),
      p_marks_awarded: Number(marks),
      p_idempotency_key: String(idempotencyKey || ""),
      p_review_note: reviewNote || null
    });
  }

  root.api = Object.freeze({
    capabilities,
    betaInvitation,
    grantBetaConsent,
    revokeBetaConsent,
    examProfile,
    saveExamProfile,
    diagnosticProgress,
    startNextDiagnostic,
    getPlacement,
    getState,
    getSession,
    startSession,
    submitResponse,
    finalizeSession,
    weeklyPlan,
    generateWeeklyPlan,
    timedCatalog,
    authorizeTimed,
    finalizeTimed,
    timedResult,
    timedReviewPack,
    submitTimedSelfMark
  });

  // Main app loads only api.js + host.js statically. Load the live learner layer
  // from the same directory without changing legacy/preview wiring. Inline test
  // injection has no currentScript.src and therefore does not auto-load it.
  try {
    const src = document?.currentScript?.src || "";
    if (src && /exam-prep-api\.js(?:\?|$)/.test(src) && !document.querySelector('script[data-exam-prep-live]')) {
      const script = document.createElement("script");
      script.dataset.examPrepLive = "true";
      script.src = src.replace(/exam-prep-api\.js(?:\?.*)?$/, "exam-prep-live.js?v=p017live1");
      document.head.appendChild(script);
    }
  } catch (_) {
    // Fail closed: host consent/access shell still works without the optional live learner layer.
  }
})();