import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" };

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";

const VALID_COMPONENTS = new Set(["P1", "P5"]);
const VALID_LOCALES = new Set(["ru", "uz", "en"]);
const VALID_INTERACTIONS = new Set([
  "established_error_explanation",
  "weekly_plan_narration",
  "progress_summary",
  "repeated_error_summary",
  "theory_explanation",
  "multilingual_explanation",
  "mentor_report_draft",
]);

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function isUuid(value: unknown): value is string {
  return typeof value === "string" && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function normalizeLocale(value: unknown) {
  const locale = String(value || "ru").toLowerCase();
  return VALID_LOCALES.has(locale) ? locale : "ru";
}

function learnerMessage(locale: string, mode: string, reason: string) {
  const messages: Record<string, Record<string, string>> = {
    ru: {
      active_assessment: "Помощь с объяснениями недоступна, пока идёт проверочная работа. После завершения можно разобрать ошибки.",
      input_too_long: "Сократите запрос и попробуйте ещё раз.",
      interaction_not_allowed: "Этот тип запроса недоступен в учебном помощнике.",
      mentor_actor_required: "Этот запрос доступен только в рабочем пространстве назначенного ментора.",
      no_source: "Для этого объяснения пока нет утверждённого материала. Продолжайте по текущему плану.",
      unavailable: "ИИ-помощник сейчас недоступен. Основная подготовка продолжает работать без изменений.",
      fallback: "Сейчас не удалось подготовить дополнительное объяснение. Основной план доступен без изменений.",
    },
    uz: {
      active_assessment: "Tekshiruv davom etayotgan paytda izohli yordam mavjud emas. Tugagach, xatolarni tahlil qilish mumkin.",
      input_too_long: "So‘rovni qisqartirib, yana urinib ko‘ring.",
      interaction_not_allowed: "Bu turdagi so‘rov o‘quv yordamchisida mavjud emas.",
      mentor_actor_required: "Bu so‘rov faqat biriktirilgan mentor ish maydonida mavjud.",
      no_source: "Bu izoh uchun hozircha tasdiqlangan material yo‘q. Joriy reja bo‘yicha davom eting.",
      unavailable: "AI yordamchi hozir mavjud emas. Asosiy tayyorgarlik odatdagidek ishlashda davom etadi.",
      fallback: "Hozir qo‘shimcha izoh tayyorlab bo‘lmadi. Asosiy reja o‘zgarishsiz mavjud.",
    },
    en: {
      active_assessment: "Explanation help is unavailable while this assessment is active. You can review mistakes after it is finished.",
      input_too_long: "Shorten the request and try again.",
      interaction_not_allowed: "This request type is not available in the learning assistant.",
      mentor_actor_required: "This request is available only in an assigned mentor workspace.",
      no_source: "There is no approved material for this explanation yet. Continue with the current plan.",
      unavailable: "AI assistance is unavailable right now. Core exam preparation continues unchanged.",
      fallback: "An additional explanation could not be prepared right now. The core plan remains available.",
    },
  };
  const dictionary = messages[locale] || messages.ru;
  if (reason === "active_assessment") return dictionary.active_assessment;
  if (reason === "input_too_long") return dictionary.input_too_long;
  if (reason === "interaction_not_allowed") return dictionary.interaction_not_allowed;
  if (reason === "mentor_actor_required") return dictionary.mentor_actor_required;
  if (mode === "no_source") return dictionary.no_source;
  if (mode === "fallback") return dictionary.fallback;
  return dictionary.unavailable;
}

async function rpc(name: string, body: Record<string, unknown>, authorization: string, apiKey: string) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: {
      apikey: apiKey,
      Authorization: authorization,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let data: unknown = null;
  try { data = text ? JSON.parse(text) : null; } catch { data = text; }
  if (!res.ok) throw new Error(`${name}:${res.status}:${typeof data === "string" ? data.slice(0, 240) : JSON.stringify(data).slice(0, 240)}`);
  return data;
}

async function currentUser(authorization: string) {
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: ANON_KEY, Authorization: authorization },
  });
  if (!res.ok) return null;
  const data = await res.json().catch(() => null);
  return data && isUuid(data.id) ? data : null;
}

async function learnerContext(
  interaction: string,
  component: string,
  skillCode: string | null,
  authorization: string,
) {
  if (interaction === "progress_summary") {
    return {
      context_type: "component_overview_v1",
      data: await rpc("get_exam_prep_overview_safe_v1", { p_component_code: component }, authorization, ANON_KEY),
    };
  }
  if (interaction === "weekly_plan_narration") {
    return {
      context_type: "weekly_plan_v1",
      data: await rpc("get_exam_prep_weekly_plan_safe_v1", { p_component_code: component }, authorization, ANON_KEY),
    };
  }
  if (interaction === "established_error_explanation" || interaction === "repeated_error_summary") {
    return {
      context_type: "correction_queue_v1",
      data: await rpc("get_exam_prep_correction_queue_safe_v1", { p_component_code: component }, authorization, ANON_KEY),
    };
  }
  if ((interaction === "theory_explanation" || interaction === "multilingual_explanation") && skillCode) {
    return {
      context_type: "skill_detail_v1",
      data: await rpc("get_exam_prep_skill_detail_safe_v1", {
        p_component_code: component,
        p_skill_code: skillCode,
      }, authorization, ANON_KEY),
    };
  }
  return null;
}

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function versions(snapshot: any) {
  const p = snapshot?.policy || {};
  return {
    policy_version: String(p.policy_version || "exam_prep_ai_policy_v1"),
    prompt_version: String(p.prompt_version || "exam_prep_ai_prompt_v1"),
    retrieval_policy_version: String(p.retrieval_policy_version || "exam_prep_ai_retrieval_v1"),
    response_schema_version: String(p.response_schema_version || "exam_prep_ai_response_v1"),
  };
}

async function audit(params: {
  requestId: string;
  userId: string;
  component: string;
  interaction: string;
  locale: string;
  mode: string;
  guard: Record<string, unknown>;
  snapshot: any;
  latencyMs: number;
  deterministicSnapshotHash?: string | null;
  fallbackReason?: string | null;
  sourceCardKeys?: string[];
  safetyFlags?: string[];
  outputHash?: string | null;
}) {
  if (!SERVICE_ROLE_KEY) return;
  const v = versions(params.snapshot);
  await rpc("record_exam_prep_ai_audit_service_v1", {
    p_request_id: params.requestId,
    p_user_id: params.userId,
    p_component_code: params.component,
    p_interaction_type: params.interaction,
    p_requested_locale: params.locale,
    p_mode: params.mode,
    p_guard_decisions: params.guard,
    p_policy_version: v.policy_version,
    p_prompt_version: v.prompt_version,
    p_retrieval_policy_version: v.retrieval_policy_version,
    p_response_schema_version: v.response_schema_version,
    p_deterministic_snapshot_hash: params.deterministicSnapshotHash || null,
    p_latency_ms: Math.max(0, Math.round(params.latencyMs)),
    p_fallback_reason: params.fallbackReason || null,
    p_source_card_keys: params.sourceCardKeys || [],
    p_safety_flags: params.safetyFlags || [],
    p_output_hash: params.outputHash || null,
  }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: corsHeaders });
  if (req.method !== "POST") return response(405, { error: "method_not_allowed" });
  if (!SUPABASE_URL || !ANON_KEY || !SERVICE_ROLE_KEY) return response(503, { error: "service_unavailable" });

  const started = performance.now();
  const authorization = req.headers.get("Authorization") || "";
  if (!authorization.startsWith("Bearer ")) return response(401, { error: "auth_required" });

  const user = await currentUser(authorization);
  if (!user) return response(401, { error: "auth_required" });

  const payload = await req.json().catch(() => null);
  if (!payload || typeof payload !== "object") return response(400, { error: "invalid_json" });

  const requestId = isUuid((payload as any).request_id) ? (payload as any).request_id : crypto.randomUUID();
  const component = String((payload as any).component_code || "").toUpperCase();
  const interaction = String((payload as any).interaction_type || "");
  const locale = normalizeLocale((payload as any).locale);
  const userText = typeof (payload as any).user_text === "string" ? (payload as any).user_text : "";
  const rawSkillCode = typeof (payload as any).skill_code === "string" ? String((payload as any).skill_code).trim() : "";
  const skillCode = rawSkillCode && rawSkillCode.length <= 80 ? rawSkillCode : null;

  if (!VALID_COMPONENTS.has(component)) return response(400, { request_id: requestId, error: "invalid_component" });
  if (!VALID_INTERACTIONS.has(interaction)) return response(400, { request_id: requestId, error: "invalid_interaction" });

  let snapshot: any = null;
  try {
    snapshot = await rpc("get_exam_prep_ai_operational_snapshot_v1", {}, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
  } catch {
    snapshot = null;
  }

  let guard: any;
  try {
    guard = await rpc("get_exam_prep_ai_guard_v1", {
      p_component_code: component,
      p_interaction_type: interaction,
      p_requested_locale: locale,
      p_user_text_length: userText.length,
    }, authorization, ANON_KEY);
  } catch {
    const mode = "unavailable";
    const message = learnerMessage(locale, mode, "unavailable");
    const outputHash = await sha256(message);
    await audit({ requestId, userId: user.id, component, interaction, locale, mode, guard: { guard_error: true }, snapshot, latencyMs: performance.now() - started, fallbackReason: "guard_error", safetyFlags: ["fail_closed"], outputHash }).catch(() => {});
    return response(200, { request_id: requestId, mode, component_code: component, interaction_type: interaction, locale, message, generated: false, academic_state_changed: false });
  }

  if (!guard?.allowed) {
    const mode = ["blocked", "fallback", "unavailable"].includes(String(guard?.mode)) ? String(guard.mode) : "unavailable";
    const reason = String(guard?.reason || "unavailable");
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({ requestId, userId: user.id, component, interaction, locale, mode, guard, snapshot, latencyMs: performance.now() - started, fallbackReason: reason, safetyFlags: mode === "blocked" ? [reason] : [], outputHash }).catch(() => {});
    return response(200, { request_id: requestId, mode, reason, component_code: component, interaction_type: interaction, locale, message, generated: false, academic_state_changed: false });
  }

  let deterministicContext: any = null;
  let deterministicSnapshotHash: string | null = null;
  try {
    deterministicContext = await learnerContext(interaction, component, skillCode, authorization);
    if (deterministicContext) deterministicSnapshotHash = await sha256(JSON.stringify(deterministicContext));
  } catch {
    const mode = "fallback";
    const reason = "context_unavailable";
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({ requestId, userId: user.id, component, interaction, locale, mode, guard, snapshot, latencyMs: performance.now() - started, fallbackReason: reason, safetyFlags: ["context_unavailable"], outputHash }).catch(() => {});
    return response(200, { request_id: requestId, mode, reason, component_code: component, interaction_type: interaction, locale, message, generated: false, academic_state_changed: false });
  }

  const cardTypeMap: Record<string, string | null> = {
    established_error_explanation: "error_explanation",
    weekly_plan_narration: "weekly_plan_context",
    progress_summary: "progress_context",
    repeated_error_summary: "error_explanation",
    theory_explanation: "theory",
    multilingual_explanation: "theory",
  };

  let cards: any[] = [];
  try {
    const result = await rpc("get_exam_prep_ai_source_cards_service_v1", {
      p_component_code: component,
      p_locale: locale,
      p_card_type: cardTypeMap[interaction] || null,
      p_skill_code: skillCode,
      p_limit: 8,
    }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
    cards = Array.isArray(result) ? result : [];
  } catch {
    cards = [];
  }

  if (!cards.length) {
    const mode = "no_source";
    const reason = "approved_source_missing";
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({ requestId, userId: user.id, component, interaction, locale, mode, guard, snapshot, latencyMs: performance.now() - started, deterministicSnapshotHash, fallbackReason: reason, safetyFlags: ["no_source"], outputHash }).catch(() => {});
    return response(200, { request_id: requestId, mode, reason, component_code: component, interaction_type: interaction, locale, message, source_cards: [], context_bound: Boolean(deterministicContext), generated: false, academic_state_changed: false });
  }

  // Provider/model routing is intentionally not enabled in this foundation release.
  // The endpoint remains safe even if an AI entitlement is accidentally granted:
  // it returns a transparent fallback and never writes academic state.
  const mode = "fallback";
  const reason = "model_not_configured";
  const message = learnerMessage(locale, mode, reason);
  const sourceCardKeys = cards.map((c) => String(c?.source_card_key || "")).filter(Boolean);
  const outputHash = await sha256(message);
  await audit({ requestId, userId: user.id, component, interaction, locale, mode, guard, snapshot, latencyMs: performance.now() - started, deterministicSnapshotHash, fallbackReason: reason, sourceCardKeys, safetyFlags: ["model_not_configured"], outputHash }).catch(() => {});
  return response(200, { request_id: requestId, mode, reason, component_code: component, interaction_type: interaction, locale, message, source_cards: sourceCardKeys, context_bound: Boolean(deterministicContext), generated: false, academic_state_changed: false });
});