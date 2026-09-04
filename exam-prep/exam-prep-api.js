(() => {
  "use strict";

  const root = (window.iClubExamPrepHostInternal = window.iClubExamPrepHostInternal || {});

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

  root.api = Object.freeze({ capabilities });
})();
