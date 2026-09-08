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
    const invitations = Array.isArray(row.invitations) ? row.invitations.map(normalizeInvitationItem).filter(Boolean) : [];
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
    const result = await rpc("save_exam_prep_exam_profile_v2", {
      p_exam_series: String(examSeries || "").trim() || null,
      p_target_grade: String(targetGrade || "").trim() || null,
      p_total_student_hours_available: Number(totalHours),
      p_mathematics_hours_budget: Number(mathHours)
    });
    if (!result.ok) return result;

    // Profile changes replan both components independently. Failures here never roll back the saved profile;
    // opening a component plan can safely retry its governed generator later.
    if (result.data?.plan_rebuild_required === true) {
      await Promise.all([
        rpc("generate_exam_prep_weekly_plan_safe_v3", { p_component_code: "P1" }),
        rpc("generate_exam_prep_weekly_plan_safe_v3", { p_component_code: "P5" })
      ]);
    }
    return result;
  }

  async function examMapStatus() { return rpc("get_exam_prep_exam_map_status_safe_v1"); }

  const componentArg = componentCode => String(componentCode || "");

  async function diagnosticProgress(componentCode) { return rpc("get_exam_prep_diagnostic_progress_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function startNextDiagnostic(componentCode, idempotencyKey) {
    return rpc("start_exam_prep_next_diagnostic_safe_v1", { p_component_code: componentArg(componentCode), p_idempotency_key: String(idempotencyKey || "") });
  }
  async function getPlacement(componentCode = null) { return rpc("get_exam_prep_placement_safe_v1", { p_component_code: componentCode || null }); }
  async function getState(componentCode) { return rpc("get_exam_prep_state_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function overview(componentCode) { return rpc("get_exam_prep_overview_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function legacyReferenceSummary(componentCode) { return rpc("get_exam_prep_legacy_reference_summary_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function placementResult(componentCode) { return rpc("get_exam_prep_placement_result_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function syllabusTracker(componentCode) { return rpc("get_exam_prep_syllabus_tracker_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function skillDetail(componentCode, skillCode) {
    return rpc("get_exam_prep_skill_detail_safe_v1", { p_component_code: componentArg(componentCode), p_skill_code: String(skillCode || "") });
  }
  async function correctionQueue(componentCode) { return rpc("get_exam_prep_correction_queue_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function pastPaperCompanion(componentCode, language = "en") {
    return rpc("get_exam_prep_past_paper_companion_safe_v1", { p_component_code: componentArg(componentCode), p_language: String(language || "en") });
  }
  async function materialsLibrary(language = "en") {
    return rpc("get_exam_prep_materials_library_safe_v1", { p_language: String(language || "en") });
  }

  async function getSession(sessionId, language = "en") { return rpc("get_exam_prep_session_safe_v1", { p_session_id: sessionId, p_language: language }); }
  async function startSession(authorizationId, idempotencyKey) {
    return rpc("start_exam_prep_session_safe_v1", { p_authorization_id: authorizationId, p_idempotency_key: String(idempotencyKey || "") });
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
    return rpc("finalize_exam_prep_session_safe_v1", { p_session_id: sessionId, p_idempotency_key: String(idempotencyKey || "") });
  }

  // Recovery is non-destructive: the server owns the day-band policy and any optional progress confirmation.
  async function recovery(componentCode) { return rpc("get_exam_prep_recovery_safe_v2", { p_component_code: componentArg(componentCode) }); }
  async function recordInterruption({ startedOn, resumedOn, kind = "absence" } = {}) {
    const started = String(startedOn || "").trim();
    const resumed = String(resumedOn || "").trim();
    if (!started || !resumed) return fail("interruption_dates_required");
    return rpc("record_my_exam_prep_interruption_v2", {
      p_interruption_started_on: started,
      p_resumed_on: resumed,
      p_interruption_kind: String(kind || "absence")
    });
  }
  async function authorizeRevalidationItem(caseId, itemOrder) {
    return rpc("authorize_exam_prep_revalidation_item_safe_v1", { p_case_id: caseId, p_item_order: Number(itemOrder) });
  }
  async function weeklyPlan(componentCode) { return rpc("get_exam_prep_weekly_plan_safe_v2", { p_component_code: componentArg(componentCode) }); }
  async function generateWeeklyPlan(componentCode) { return rpc("generate_exam_prep_weekly_plan_safe_v3", { p_component_code: componentArg(componentCode) }); }
  async function authorizePlanItem(planId, priorityOrder) {
    return rpc("authorize_exam_prep_plan_item_safe_v1", { p_plan_id: planId, p_priority_order: Number(priorityOrder) });
  }

  async function timedCatalog(componentCode) { return rpc("get_exam_prep_timed_catalog_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function authorizeTimed(assessmentId) { return rpc("authorize_exam_prep_timed_safe_v1", { p_assessment_id: Number(assessmentId) }); }
  async function finalizeTimed(sessionId, idempotencyKey, completionReason = "submitted") {
    return rpc("finalize_exam_prep_timed_safe_v1", { p_session_id: sessionId, p_idempotency_key: String(idempotencyKey || ""), p_completion_reason: completionReason });
  }
  async function timedResult(sessionId) { return rpc("get_exam_prep_timed_result_safe_v1", { p_session_id: sessionId }); }
  async function timedReviewPack(sessionId, language = "en") { return rpc("get_exam_prep_timed_review_pack_safe_v1", { p_session_id: sessionId, p_language: language }); }
  async function submitTimedSelfMark(sessionId, itemOrder, marks, idempotencyKey, reviewNote = null) {
    return rpc("submit_exam_prep_timed_written_self_mark_safe_v1", {
      p_session_id: sessionId,
      p_item_order: Number(itemOrder),
      p_marks_awarded: Number(marks),
      p_idempotency_key: String(idempotencyKey || ""),
      p_review_note: reviewNote || null
    });
  }
  async function readiness(componentCode) { return rpc("get_exam_prep_readiness_safe_v1", { p_component_code: componentArg(componentCode) }); }
  async function finalCalibration(componentCode) { return rpc("get_exam_prep_final_calibration_safe_v1", { p_component_code: componentArg(componentCode) }); }

  root.api = Object.freeze({
    capabilities, betaInvitation, grantBetaConsent, revokeBetaConsent,
    examProfile, saveExamProfile, examMapStatus,
    diagnosticProgress, startNextDiagnostic, getPlacement, getState, overview,
    legacyReferenceSummary, placementResult, syllabusTracker, skillDetail, correctionQueue, pastPaperCompanion, materialsLibrary,
    getSession, startSession, submitResponse, finalizeSession,
    recovery, recordInterruption, authorizeRevalidationItem,
    weeklyPlan, generateWeeklyPlan, authorizePlanItem,
    timedCatalog, authorizeTimed, finalizeTimed, timedResult, timedReviewPack, submitTimedSelfMark,
    readiness, finalCalibration
  });

  try {
    const src = document?.currentScript?.src || "";
    const valid = /^https?:/i.test(src) && /exam-prep-api\.js(?:\?|$)/.test(src);
    const load = (selector, datasetKey, filename) => {
      if (!valid || document.querySelector(selector)) return;
      const script = document.createElement("script");
      script.dataset[datasetKey] = "true";
      script.src = src.replace(/exam-prep-api\.js(?:\?.*)?$/, filename);
      document.head.appendChild(script);
    };

    if (src && /exam-prep-api\.js(?:\?|$)/.test(src)) load('script[data-exam-prep-live]', "examPrepLive", "exam-prep-live.js?v=p019timed1");
    load('script[data-exam-prep-learner-views]', "examPrepLearnerViews", "exam-prep-learner-views.js?v=p020views2");
    load('script[data-exam-prep-overview-placement]', "examPrepOverviewPlacement", "exam-prep-overview-placement.js?v=p021overview1");
    load('script[data-exam-prep-ai-ui]', "examPrepAiUi", "exam-prep-ai-ui.js?v=p104aiui1");
    load('script[data-exam-prep-history-note]', "examPrepHistoryNote", "exam-prep-history-note.js?v=p105history1");
    load('script[data-exam-prep-past-paper]', "examPrepPastPaper", "exam-prep-past-paper.js?v=p203paper1");
    load('script[data-exam-prep-profile-completeness]', "examPrepProfileCompleteness", "exam-prep-profile-completeness.js?v=p205profile1");
    load('script[data-exam-prep-recovery]', "examPrepRecovery", "exam-prep-recovery.js?v=p208preserve1");
    load('script[data-exam-prep-exam-map]', "examPrepExamMap", "exam-prep-exam-map.js?v=p209map1");
    load('script[data-exam-prep-materials]', "examPrepMaterials", "exam-prep-materials.js?v=p210materials1");
  } catch (_) {
    // Fail closed: the host access shell still works without optional learner layers.
  }
})();
