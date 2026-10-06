(() => {
  "use strict";

  const ALLOWED_ROUTES = new Set([
    "catalog_subject_hub",
    "profile_competitive_subject_hub",
    "global_books",
    "global_recommendations",
    "profile_recommendations",
    "subject_video",
    "subject_exam_prep",
    "subject_practice",
    "subject_tours",
    "subject_books",
    "subject_recommendations",
    "recommendation_books",
    "recommendation_practice",
    "recommendation_train",
    "recommendation_retry",
    "recommendation_repeat_drill",
    "tour_practice",
    "recommendation_to_subject"
  ]);

  const RECENT_TTL_MS = 700;
  const recent = new Map();

  function normalize(value) {
    return String(value || "").trim().toLowerCase();
  }

  function recentKey(subjectKey, routeCode) {
    return normalize(subjectKey) + "|" + normalize(routeCode);
  }

  function shouldSkipDuplicate(subjectKey, routeCode) {
    const key = recentKey(subjectKey, routeCode);
    const now = Date.now();
    const last = Number(recent.get(key) || 0);
    recent.set(key, now);

    if (recent.size > 80) {
      for (const [itemKey, ts] of recent.entries()) {
        if (now - Number(ts || 0) > RECENT_TTL_MS * 4) recent.delete(itemKey);
      }
    }

    return last > 0 && now - last < RECENT_TTL_MS;
  }

  async function observe({ subjectKey, routeCode } = {}) {
    const subject = normalize(subjectKey);
    const route = normalize(routeCode);

    if (!subject || !ALLOWED_ROUTES.has(route)) {
      return {
        observed: false,
        reason: "invalid_client_route",
        access_unchanged: true
      };
    }

    if (shouldSkipDuplicate(subject, route)) {
      return {
        observed: false,
        reason: "duplicate_client_observation",
        access_unchanged: true
      };
    }

    const client = window.sb;
    if (!client?.rpc) {
      return {
        observed: false,
        reason: "rpc_unavailable",
        access_unchanged: true
      };
    }

    try {
      const { data, error } = await client.rpc(
        "record_iclub_my_subject_access_shadow_v1",
        {
          p_subject_key: subject,
          p_route_code: route
        }
      );

      if (error || !data || typeof data !== "object") {
        return {
          observed: false,
          reason: "shadow_observation_failed",
          access_unchanged: true
        };
      }

      // Deliberately never block navigation in this phase.
      // The server answer is shadow telemetry only.
      return {
        ...data,
        access_unchanged: true
      };
    } catch {
      return {
        observed: false,
        reason: "shadow_observation_failed",
        access_unchanged: true
      };
    }
  }

  window.iClubSubjectAccessShadow = Object.freeze({
    version: "subject_access_shadow_routing_v1",
    observe,
    routes: () => Array.from(ALLOWED_ROUTES)
  });
})();
