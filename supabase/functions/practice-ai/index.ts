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

const VALID_LOCALES = new Set(["ru", "uz", "en"]);
const VALID_INTERACTIONS = new Set(["post_answer_explanation", "practice_result_summary"]);

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function isUuid(value: unknown): value is string {
  return typeof value === "string"
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function positiveInt(value: unknown) {
  const n = Number(value);
  return Number.isInteger(n) && n > 0 ? n : null;
}

function normalizeLocale(value: unknown) {
  const locale = String(value || "ru").toLowerCase();
  return VALID_LOCALES.has(locale) ? locale : "ru";
}

function learnerMessage(locale: string, mode: string, reason: string) {
  const messages: Record<string, Record<string, string>> = {
    ru: {
      active_assessment: "Помощник недоступен, пока идёт проверочная работа.",
      interaction_not_allowed: "Этот тип помощи пока недоступен.",
      ai_disabled: "ИИ-помощник для практики пока недоступен.",
      no_source: "Для этого разбора пока нет утверждённого материала.",
      context_unavailable: "Не удалось получить подтверждённые данные этой практики.",
      fallback: "Дополнительное объяснение сейчас недоступно. Практика продолжает работать без изменений.",
      unavailable: "ИИ-помощник сейчас недоступен. Практика продолжает работать без изменений.",
    },
    uz: {
      active_assessment: "Tekshiruv davom etayotgan paytda yordamchi mavjud emas.",
      interaction_not_allowed: "Bu turdagi yordam hozircha mavjud emas.",
      ai_disabled: "Practice uchun AI yordamchi hozircha mavjud emas.",
      no_source: "Bu tahlil uchun hozircha tasdiqlangan material yo‘q.",
      context_unavailable: "Ushbu practice bo‘yicha tasdiqlangan ma’lumotlarni olib bo‘lmadi.",
      fallback: "Qo‘shimcha izoh hozir mavjud emas. Practice odatdagidek ishlashda davom etadi.",
      unavailable: "AI yordamchi hozir mavjud emas. Practice odatdagidek ishlashda davom etadi.",
    },
    en: {
      active_assessment: "The assistant is unavailable while a protected assessment is active.",
      interaction_not_allowed: "This type of help is not available yet.",
      ai_disabled: "AI help for Practice is not available yet.",
      no_source: "There is no approved material for this explanation yet.",
      context_unavailable: "The confirmed Practice context could not be loaded.",
      fallback: "An additional explanation is unavailable right now. Practice continues unchanged.",
      unavailable: "AI assistance is unavailable right now. Practice continues unchanged.",
    },
  };
  const d = messages[locale] || messages.ru;
  if (reason === "active_assessment") return d.active_assessment;
  if (reason === "interaction_not_allowed") return d.interaction_not_allowed;
  if (reason === "ai_disabled" || reason === "interaction_not_entitled") return d.ai_disabled;
  if (mode === "no_source") return d.no_source;
  if (reason === "context_unavailable") return d.context_unavailable;
  if (mode === "fallback") return d.fallback;
  return d.unavailable;
}

async function rpc(name: string, body: Record<string, unknown>, authorization: string, apiKey: string): Promise<any> {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: {
      apikey: apiKey,
      Authorization: authorization,
      "Content-Type": "application/json",
    },
    body: JSON.stringify(body),
  });
  const raw = await res.text();
  let data: any = null;
  try { data = raw ? JSON.parse(raw) : null; } catch { data = raw; }
  if (!res.ok) throw new Error(`${name}:${res.status}`);
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

async function sha256(value: string) {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

function versions(snapshot: any) {
  const p = snapshot?.policy || {};
  return {
    policy_version: String(p.policy_version || "practice_ai_policy_v1"),
    prompt_version: String(p.prompt_version || "practice_ai_prompt_v1"),
    retrieval_policy_version: String(p.retrieval_policy_version || "practice_ai_retrieval_v1"),
    response_schema_version: String(p.response_schema_version || "practice_ai_response_v1"),
  };
}

async function audit(params: {
  requestId: string;
  userId: string;
  interaction: string;
  locale: string;
  mode: string;
  guard: Record<string, unknown>;
  snapshot: any;
  latencyMs: number;
  context?: any;
  deterministicSnapshotHash?: string | null;
  fallbackReason?: string | null;
  sourceCardKeys?: string[];
  safetyFlags?: string[];
  outputHash?: string | null;
}) {
  if (!SERVICE_ROLE_KEY) return;
  const v = versions(params.snapshot);
  await rpc("record_practice_ai_audit_service_v1", {
    p_request_id: params.requestId,
    p_user_id: params.userId,
    p_interaction_type: params.interaction,
    p_requested_locale: params.locale,
    p_mode: params.mode,
    p_guard_decisions: params.guard || {},
    p_policy_version: v.policy_version,
    p_prompt_version: v.prompt_version,
    p_retrieval_policy_version: v.retrieval_policy_version,
    p_response_schema_version: v.response_schema_version,
    p_subject_id: positiveInt(params.context?.subject_id),
    p_session_id: positiveInt(params.context?.session_id),
    p_attempt_id: positiveInt(params.context?.attempt_id),
    p_question_id: positiveInt(params.context?.question_id),
    p_deterministic_snapshot_hash: params.deterministicSnapshotHash || null,
    p_source_card_keys: params.sourceCardKeys || [],
    p_latency_ms: Math.max(0, Math.round(params.latencyMs)),
    p_fallback_reason: params.fallbackReason || null,
    p_safety_flags: params.safetyFlags || [],
    p_output_hash: params.outputHash || null,
  }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
}

async function loadContext(interaction: string, userId: string, payload: any, locale: string) {
  if (interaction === "post_answer_explanation") {
    const sessionId = positiveInt(payload?.session_id);
    const questionId = positiveInt(payload?.question_id);
    if (!sessionId || !questionId) throw new Error("invalid_practice_reference");
    return await rpc("get_practice_ai_answer_context_service_v1", {
      p_user_id: userId,
      p_session_id: sessionId,
      p_question_id: questionId,
      p_locale: locale,
    }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
  }

  const attemptId = positiveInt(payload?.attempt_id);
  if (!attemptId) throw new Error("invalid_practice_reference");
  return await rpc("get_practice_ai_result_context_service_v1", {
    p_user_id: userId,
    p_attempt_id: attemptId,
    p_locale: locale,
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
  const interaction = String((payload as any).interaction_type || "");
  const locale = normalizeLocale((payload as any).locale);

  if (!VALID_INTERACTIONS.has(interaction)) {
    return response(400, { request_id: requestId, error: "invalid_interaction" });
  }

  let snapshot: any = null;
  try {
    snapshot = await rpc("get_practice_ai_operational_snapshot_v1", {}, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
  } catch {
    snapshot = null;
  }

  let guard: any;
  try {
    guard = await rpc("get_practice_ai_guard_v1", {
      p_interaction_type: interaction,
      p_requested_locale: locale,
      p_user_text_length: 0,
    }, authorization, ANON_KEY);
  } catch {
    const mode = "unavailable";
    const reason = "guard_error";
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({
      requestId, userId: user.id, interaction, locale, mode, guard: { guard_error: true }, snapshot,
      latencyMs: performance.now() - started, fallbackReason: reason, safetyFlags: ["fail_closed"], outputHash,
    }).catch(() => {});
    return response(200, {
      request_id: requestId, mode, reason, interaction_type: interaction, locale, message,
      generated: false, academic_state_changed: false,
    });
  }

  if (!guard?.allowed) {
    const mode = ["blocked", "fallback", "unavailable"].includes(String(guard?.mode))
      ? String(guard.mode)
      : "unavailable";
    const reason = String(guard?.reason || "unavailable");
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({
      requestId, userId: user.id, interaction, locale, mode, guard, snapshot,
      latencyMs: performance.now() - started, fallbackReason: reason,
      safetyFlags: mode === "blocked" ? [reason] : [], outputHash,
    }).catch(() => {});
    return response(200, {
      request_id: requestId, mode, reason, interaction_type: interaction, locale, message,
      generated: false, academic_state_changed: false,
    });
  }

  let context: any = null;
  let deterministicSnapshotHash: string | null = null;
  try {
    context = await loadContext(interaction, user.id, payload, locale);
    if (!context || typeof context !== "object") throw new Error("context_unavailable");
    deterministicSnapshotHash = await sha256(JSON.stringify(context));
  } catch {
    const mode = "fallback";
    const reason = "context_unavailable";
    const message = learnerMessage(locale, mode, reason);
    const outputHash = await sha256(message);
    await audit({
      requestId, userId: user.id, interaction, locale, mode, guard, snapshot,
      latencyMs: performance.now() - started, fallbackReason: reason,
      safetyFlags: [reason], outputHash,
    }).catch(() => {});
    return response(200, {
      request_id: requestId, mode, reason, interaction_type: interaction, locale, message,
      generated: false, academic_state_changed: false,
    });
  }

  const cardType = interaction === "post_answer_explanation" ? "answer_explanation" : "result_context";
  let cards: any[] = [];
  try {
    const result = await rpc("get_practice_ai_source_cards_service_v1", {
      p_subject_key: String(context?.subject_key || ""),
      p_locale: locale,
      p_card_type: cardType,
      p_question_id: positiveInt(context?.question_id),
      p_topic: context?.topic == null ? null : String(context.topic),
      p_subtopic: context?.subtopic == null ? null : String(context.subtopic),
      p_limit: 6,
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
    await audit({
      requestId, userId: user.id, interaction, locale, mode, guard, snapshot, context,
      latencyMs: performance.now() - started, deterministicSnapshotHash,
      fallbackReason: reason, safetyFlags: ["no_source"], outputHash,
    }).catch(() => {});
    return response(200, {
      request_id: requestId, mode, reason, interaction_type: interaction, locale, message,
      source_cards: [], context_bound: true, generated: false, academic_state_changed: false,
    });
  }

  // AI-2 foundation intentionally has no model call yet.
  // Approved sources, context isolation and protected-assessment blackout are proven first.
  const mode = "fallback";
  const reason = "model_not_configured";
  const message = learnerMessage(locale, mode, reason);
  const sourceCardKeys = cards.map((card) => String(card?.source_card_key || "")).filter(Boolean);
  const outputHash = await sha256(message);
  await audit({
    requestId, userId: user.id, interaction, locale, mode, guard, snapshot, context,
    latencyMs: performance.now() - started, deterministicSnapshotHash,
    fallbackReason: reason, sourceCardKeys, safetyFlags: [reason], outputHash,
  }).catch(() => {});

  return response(200, {
    request_id: requestId, mode, reason, interaction_type: interaction, locale, message,
    source_cards: sourceCardKeys, context_bound: true, generated: false, academic_state_changed: false,
  });
});
