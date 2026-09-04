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

    return Object.freeze({
      ok: true,
      data: Object.freeze({
        programKey: String(row.program_key || "math_as_p1_p5"),
        rolloutState: String(row.rollout_state || "off"),
        coreAccess: row.core_access === true,
        aiAssist: row.ai_assist === true,
        mentorCareEntitled: row.mentor_care_entitled === true,
        mentorAssignmentActive: row.mentor_assignment_active === true,
        mentorAuthority: row.mentor_authority === true,
        killSwitch: row.kill_switch !== false
      })
    });
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
    return rpc("grant_my_exam_prep_beta_consent_v1", {
      p_cohort_key: key,
      p_acknowledgement: CONSENT_ACK
    });
  }

  async function revokeBetaConsent(cohortKey) {
    const key = String(cohortKey || "").trim();
    if (!key) return fail("beta_cohort_key_required");
    return rpc("revoke_my_exam_prep_beta_consent_v1", {
      p_cohort_key: key,
      p_acknowledgement: REVOKE_ACK
    });
  }

  root.api = Object.freeze({
    capabilities,
    betaInvitation,
    grantBetaConsent,
    revokeBetaConsent
  });
})();
