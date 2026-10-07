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
const VALID_SUBJECT_KEYS = new Set([
  "general",
  "mathematics",
  "biology",
  "chemistry",
  "economics",
  "informatics",
]);

const PREPARED_PROMPTS: Record<string, { interaction: string; variant?: string }> = {
  topic_main: { interaction: "topic_explanation", variant: "main_explanation" },
  topic_simple: { interaction: "topic_explanation", variant: "simple_explanation" },
  topic_alternative: { interaction: "topic_explanation", variant: "alternative_explanation" },
  topic_focus: { interaction: "topic_explanation", variant: "focus_explanation" },
  app_help_here: { interaction: "app_help" },
  app_help_practice: { interaction: "app_help" },
  app_help_tours: { interaction: "app_help" },
  app_help_results: { interaction: "app_help" },
};

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function isUuid(value: unknown): value is string {
  return typeof value === "string"
    && /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

function normalizeLocale(value: unknown) {
  const locale = String(value || "ru").toLowerCase();
  return VALID_LOCALES.has(locale) ? locale : "ru";
}

function normalizeSubject(value: unknown) {
  const subject = String(value || "").trim().toLowerCase();
  return VALID_SUBJECT_KEYS.has(subject) ? subject : "";
}

function normalizeScope(value: unknown) {
  const scope = String(value || "global").trim().toLowerCase();
  return /^[a-z0-9_]{2,80}$/.test(scope) ? scope : "";
}

function normalizeText(value: unknown, max = 12000) {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

function normalizeIntentText(value: string) {
  return String(value || "")
    .toLowerCase()
    .replace(/[’‘ʻʼ]/g, "'")
    .replace(/[^\p{L}\p{N}'+]+/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function matchPreparedPrompt(userText: string, locale: string) {
  const q = normalizeIntentText(userText);
  if (!q) return "";

  const aliases: Record<string, Record<string, string[]>> = {
    ru: {
      topic_main: ["объясни", "объясни тему", "объясни эту тему"],
      topic_simple: ["проще", "объясни проще", "можно проще"],
      topic_alternative: ["по другому", "объясни по другому", "другим способом"],
      topic_focus: ["что главное", "что главное запомнить", "что важно запомнить"],
      app_help_here: ["что можно делать здесь", "что здесь можно делать"],
      app_help_practice: ["как работает practice", "что такое practice"],
      app_help_tours: ["как работают tours", "что такое tours"],
      app_help_results: ["где смотреть результаты", "где мои результаты"]
    },
    uz: {
      topic_main: ["tushuntir", "mavzuni tushuntir", "shu mavzuni tushuntir"],
      topic_simple: ["soddaroq", "soddaroq tushuntir", "oddiyroq tushuntir"],
      topic_alternative: ["boshqacha", "boshqacha tushuntir", "boshqa usulda tushuntir"],
      topic_focus: ["eng muhimi nima", "nimani eslab qolish kerak", "nima muhim"],
      app_help_here: ["bu yerda nima qilish mumkin", "bu yerda nimalar bor"],
      app_help_practice: ["practice qanday ishlaydi", "practice nima"],
      app_help_tours: ["tours qanday ishlaydi", "tours nima"],
      app_help_results: ["natijalarni qayerda koraman", "natijalarim qayerda"]
    },
    en: {
      topic_main: ["explain", "explain the topic", "explain this topic"],
      topic_simple: ["simpler", "explain more simply", "can you explain more simply"],
      topic_alternative: ["explain it differently", "explain another way", "another way"],
      topic_focus: ["what matters most", "what should i remember", "what is important to remember"],
      app_help_here: ["what can i do here", "what is available here"],
      app_help_practice: ["how does practice work", "what is practice"],
      app_help_tours: ["how do tours work", "what are tours"],
      app_help_results: ["where are my results", "where can i see results"]
    }
  };

  const byLocale = aliases[locale] || aliases.ru;
  for (const [key, values] of Object.entries(byLocale)) {
    if (values.some((value) => normalizeIntentText(value) === q)) return key;
  }
  return "";
}

async function rpc(
  name: string,
  body: Record<string, unknown>,
  authorization: string,
  apiKey: string,
): Promise<any> {
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
  try {
    data = raw ? JSON.parse(raw) : null;
  } catch {
    data = raw;
  }
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
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function learnerMessage(locale: string, reason: string) {
  const messages: Record<string, Record<string, string>> = {
    ru: {
      gateway_disabled: "iClub AI сейчас недоступен. Остальные функции iClub продолжают работать.",
      subscription_unassigned: "iClub AI пока недоступен для этого аккаунта.",
      active_assessment: "AI Tutor свёрнут на время экзамена. Он снова станет доступен после завершения.",
      subject_not_ready: "AI-помощь по этому предмету пока недоступна. Мы готовим проверенные объяснения.",
      subject_blocked: "iClub AI временно недоступен для этого раздела.",
      generation_upgrade_required: "Для такого вопроса нужен Plus или Pro.",
      generation_disabled: "Расширенный ответ iClub AI сейчас временно недоступен.",
      usage_exhausted: "Лимит iClub AI достигнут. Доступ восстановится после указанного времени.",
      no_source: "Для этого запроса пока нет проверенного объяснения iClub.",
      unavailable: "iClub AI сейчас недоступен. Попробуйте позже.",
    },
    uz: {
      gateway_disabled: "iClub AI hozir mavjud emas. iClub'ning boshqa funksiyalari odatdagidek ishlaydi.",
      subscription_unassigned: "iClub AI hozircha bu akkaunt uchun mavjud emas.",
      active_assessment: "AI Tutor imtihon vaqtida yig‘ildi. Imtihon tugagach yana mavjud bo‘ladi.",
      subject_not_ready: "Bu fan bo‘yicha AI yordami hozircha mavjud emas. Tasdiqlangan izohlarni tayyorlayapmiz.",
      subject_blocked: "iClub AI bu bo‘lim uchun vaqtincha mavjud emas.",
      generation_upgrade_required: "Bunday savol uchun Plus yoki Pro kerak.",
      generation_disabled: "iClub AI'ning kengaytirilgan javobi hozir vaqtincha mavjud emas.",
      usage_exhausted: "iClub AI limiti tugadi. Kirish ko‘rsatilgan vaqtdan keyin tiklanadi.",
      no_source: "Bu so‘rov uchun hozircha tasdiqlangan iClub izohi yo‘q.",
      unavailable: "iClub AI hozir mavjud emas. Keyinroq qayta urinib ko‘ring.",
    },
    en: {
      gateway_disabled: "iClub AI is unavailable right now. The rest of iClub continues to work normally.",
      subscription_unassigned: "iClub AI is not available for this account yet.",
      active_assessment: "AI Tutor is collapsed during the exam. It will be available again after you finish.",
      subject_not_ready: "AI help for this subject is not available yet. We are preparing verified explanations.",
      subject_blocked: "iClub AI is temporarily unavailable for this section.",
      generation_upgrade_required: "This type of question requires Plus or Pro.",
      generation_disabled: "An extended iClub AI answer is temporarily unavailable.",
      usage_exhausted: "Your iClub AI limit has been reached. Access will return after the shown reset time.",
      no_source: "There is no verified iClub explanation for this request yet.",
      unavailable: "iClub AI is unavailable right now. Please try again later.",
    },
  };
  const d = messages[locale] || messages.ru;
  return d[reason] || d.unavailable;
}

function auditMode(guard: any) {
  const mode = String(guard?.mode || "");
  if (mode === "blocked") return "blocked";
  return "unavailable";
}

async function recordAudit(params: {
  requestId: string;
  userId: string | null;
  subjectKey: string;
  scopeCode: string;
  interaction: string;
  routeClass: "prepared" | "generated" | null;
  mode: "prepared" | "generated" | "blocked" | "unavailable" | "no_source" | "failed";
  reason?: string | null;
  adapterCode?: string | null;
  policyVersion?: string | null;
  latencyMs: number;
  outputHash?: string | null;
}) {
  if (!SERVICE_ROLE_KEY || !isUuid(params.requestId)) return;
  try {
    await rpc("record_iclub_global_ai_gateway_audit_service_v1", {
      p_request_id: params.requestId,
      p_user_id: params.userId,
      p_subject_key: params.subjectKey || "unknown",
      p_scope_code: params.scopeCode || "unknown",
      p_interaction_type: params.interaction || "unknown",
      p_route_class: params.routeClass,
      p_mode: params.mode,
      p_reason: params.reason || null,
      p_adapter_code: params.adapterCode || null,
      p_policy_version: params.policyVersion || "global_ai_gateway_policy_v1",
      p_latency_ms: Math.max(0, Math.round(params.latencyMs)),
      p_output_hash: params.outputHash || null,
    }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
  } catch {
    // Operational audit failure must not mutate learner state or trigger retries.
  }
}

async function tutorCard(componentCode: string, skillCode: string, locale: string) {
  return await rpc("get_exam_prep_ai_tutor_card_service_v1", {
    p_component_code: componentCode,
    p_skill_code: skillCode,
    p_locale: locale,
  }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
}

async function reserveUsage(
  requestId: string,
  userId: string,
  usagePolicyCode: string,
  routeClass: "prepared" | "generated",
) {
  return await rpc("reserve_iclub_ai_usage_service_v1", {
    p_request_id: requestId,
    p_user_id: userId,
    p_usage_policy_code: usagePolicyCode,
    p_route_class: routeClass,
  }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
}

async function finalizeUsage(requestId: string, outcome: "completed" | "released", reason?: string | null) {
  return await rpc("finalize_iclub_ai_usage_service_v1", {
    p_request_id: requestId,
    p_outcome: outcome,
    p_release_reason: reason || null,
  }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
}

async function callMathSkillQuestionAdapter(params: {
  requestId: string;
  authorization: string;
  locale: string;
  componentCode: string;
  skillCode: string;
  userText: string;
}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 14000);

  try {
    const res = await fetch(`${SUPABASE_URL}/functions/v1/exam-prep-ai`, {
      method: "POST",
      headers: {
        apikey: ANON_KEY,
        Authorization: params.authorization,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        request_id: params.requestId,
        component_code: params.componentCode,
        interaction_type: "skill_question",
        locale: params.locale,
        skill_code: params.skillCode,
        user_text: params.userText,
      }),
      signal: controller.signal,
    });

    const raw = await res.text();
    let data: any = null;
    try {
      data = raw ? JSON.parse(raw) : null;
    } catch {
      data = null;
    }

    if (!res.ok && !data) throw new Error(`math_adapter_http_${res.status}`);
    return data;
  } finally {
    clearTimeout(timeout);
  }
}

function safeTutorText(card: any, variant: string) {
  const text = String(card?.[variant] || "").trim();
  if (!text) return "";
  if (text.length > 8000) return "";
  if (/<\s*script\b/i.test(text) || /javascript\s*:/i.test(text)) return "";
  return text;
}

function appHelpMessage(locale: string, promptKey: string) {
  const copy: Record<string, Record<string, string>> = {
    ru: {
      app_help_here: "Здесь можно учиться по выбранному предмету, запускать Practice, открывать Tours и возвращаться к сохранённым рекомендациям и материалам. Доступные действия зависят от текущего раздела.",
      app_help_practice: "Practice помогает тренировать темы в своём темпе. После попытки iClub сохраняет результат и историю, чтобы можно было вернуться к ошибкам и повторить нужные темы.",
      app_help_tours: "Tours — соревновательная проверка знаний по расписанию. Результаты тура могут учитываться в рейтинге, а завершённые туры остаются доступны через результаты и архив по правилам приложения.",
      app_help_results: "Результаты Practice и Tours сохраняются в iClub. Их можно использовать, чтобы увидеть свои прошлые попытки, вернуться к ошибкам и открыть доступные рекомендации."
    },
    uz: {
      app_help_here: "Bu yerda tanlangan fan bo‘yicha o‘qish, Practice boshlash, Tours bo‘limini ochish va saqlangan tavsiyalar hamda materiallarga qaytish mumkin. Mavjud amallar joriy bo‘limga bog‘liq.",
      app_help_practice: "Practice mavzularni o‘z tempingizda mashq qilishga yordam beradi. Urinishdan keyin iClub natija va tarixni saqlaydi, shunda xatolarga qaytish va kerakli mavzularni takrorlash mumkin.",
      app_help_tours: "Tours — jadval bo‘yicha o‘tkaziladigan raqobatli bilim tekshiruvi. Tur natijalari reytingda hisobga olinishi mumkin, yakunlangan turlar esa ilova qoidalariga ko‘ra natijalar va arxiv orqali saqlanadi.",
      app_help_results: "Practice va Tours natijalari iClub’da saqlanadi. Ulardan oldingi urinishlarni ko‘rish, xatolarga qaytish va mavjud tavsiyalarni ochish uchun foydalanish mumkin."
    },
    en: {
      app_help_here: "Here you can study the selected subject, start Practice, open Tours, and return to saved recommendations and learning materials. Available actions depend on the current section.",
      app_help_practice: "Practice lets you train topics at your own pace. After an attempt, iClub keeps the result and history so you can return to mistakes and repeat the topics you need.",
      app_help_tours: "Tours are scheduled competitive knowledge checks. Tour results may count toward rankings, while completed tours remain available through results and archive according to the app rules.",
      app_help_results: "Practice and Tours results are saved in iClub. You can use them to review past attempts, return to mistakes, and open available recommendations."
    }
  };
  return String((copy[locale] || copy.ru)?.[promptKey] || "").trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response(405, { ok: false, message: "Method not allowed." });

  const started = performance.now();
  const authorization = req.headers.get("authorization") || "";

  if (!SUPABASE_URL || !ANON_KEY || !SERVICE_ROLE_KEY) {
    return response(503, {
      ok: false,
      mode: "unavailable",
      message: "iClub AI is unavailable right now.",
      academic_state_changed: false,
    });
  }

  const user = await currentUser(authorization).catch(() => null);
  if (!user) {
    return response(401, {
      ok: false,
      mode: "unavailable",
      message: "Authentication required.",
      academic_state_changed: false,
    });
  }

  const payload = await req.json().catch(() => null);
  if (!payload || typeof payload !== "object") {
    return response(400, {
      ok: false,
      mode: "unavailable",
      message: "Invalid request.",
      academic_state_changed: false,
    });
  }

  const requestId = isUuid(payload.request_id) ? payload.request_id : "";
  const locale = normalizeLocale(payload.locale);
  const subjectKey = normalizeSubject(payload.subject_key);
  const scopeCode = normalizeScope(payload.scope_code);
  const explicitPromptKey = String(payload.prompt_key || "").trim();
  const userText = normalizeText(payload.user_text, 12000);
  const matchedPromptKey = explicitPromptKey || matchPreparedPrompt(userText, locale);
  const promptKey = PREPARED_PROMPTS[matchedPromptKey] ? matchedPromptKey : "";
  const componentCode = String(payload.component_code || "").trim().toUpperCase();
  const skillCode = String(payload.skill_code || "").trim().toUpperCase();

  if (!requestId || !subjectKey || !scopeCode) {
    return response(400, {
      ok: false,
      mode: "unavailable",
      message: learnerMessage(locale, "unavailable"),
      academic_state_changed: false,
    });
  }

  const preparedPrompt = promptKey ? PREPARED_PROMPTS[promptKey] : null;
  const routeClass: "prepared" | "generated" = preparedPrompt ? "prepared" : "generated";
  const interaction = preparedPrompt?.interaction || (subjectKey === "general" ? "app_help" : "freeform_question");

  if (!preparedPrompt && !userText) {
    return response(400, {
      ok: false,
      mode: "unavailable",
      message: learnerMessage(locale, "unavailable"),
      academic_state_changed: false,
    });
  }

  let guard: any;
  try {
    guard = await rpc("get_iclub_global_ai_guard_service_v1", {
      p_user_id: user.id,
      p_subject_key: subjectKey,
      p_scope_code: scopeCode,
      p_interaction_type: interaction,
      p_route_class: routeClass,
      p_requested_locale: locale,
      p_user_text_length: userText.length,
    }, `Bearer ${SERVICE_ROLE_KEY}`, SERVICE_ROLE_KEY);
  } catch {
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: "failed",
      reason: "guard_error",
      latencyMs: performance.now() - started,
    });
    return response(503, {
      ok: false,
      mode: "unavailable",
      message: learnerMessage(locale, "unavailable"),
      academic_state_changed: false,
    });
  }

  if (guard?.allowed !== true) {
    const reason = String(guard?.reason || "unavailable");
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: auditMode(guard),
      reason,
      adapterCode: guard?.adapter_code || null,
      policyVersion: guard?.policy_version || null,
      latencyMs: performance.now() - started,
    });
    return response(reason === "active_assessment" ? 423 : 200, {
      ok: false,
      mode: guard?.mode === "blocked" ? "blocked" : "unavailable",
      reason,
      message: learnerMessage(locale, reason),
      reset_at: guard?.reset_at || null,
      upgrade_available: reason === "generation_upgrade_required",
      academic_state_changed: false,
    });
  }

  const usagePolicyCode = String(guard?.ai_usage_policy_code || "");
  const adapterCode = String(guard?.adapter_code || "");
  const policyVersion = String(guard?.policy_version || "global_ai_gateway_policy_v1");

  if (!usagePolicyCode) {
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: "failed",
      reason: "usage_policy_missing",
      adapterCode,
      policyVersion,
      latencyMs: performance.now() - started,
    });
    return response(503, {
      ok: false,
      mode: "unavailable",
      message: learnerMessage(locale, "unavailable"),
      academic_state_changed: false,
    });
  }

  if (routeClass === "generated") {
    if (adapterCode !== "math_exam_prep_v1"
        || subjectKey !== "mathematics"
        || scopeCode !== "exam_prep"
        || !["P1", "P5"].includes(componentCode)
        || !/^P[15]-[A-Z0-9]+-[0-9]{2}$/.test(skillCode)) {
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "no_source",
        reason: "generated_adapter_unavailable",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "no_source",
        reason: "generated_adapter_unavailable",
        message: learnerMessage(locale, "no_source"),
        academic_state_changed: false,
      });
    }

    let reservation: any;
    try {
      reservation = await reserveUsage(requestId, user.id, usagePolicyCode, "generated");
    } catch {
      reservation = null;
    }

    if (reservation?.allowed !== true) {
      const reason = String(reservation?.reason || "usage_unavailable");
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "unavailable",
        reason,
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "unavailable",
        reason,
        message: learnerMessage(locale, reason === "usage_exhausted" ? "usage_exhausted" : "unavailable"),
        reset_at: reservation?.reset_at || null,
        academic_state_changed: false,
      });
    }

    let domain: any = null;
    try {
      domain = await callMathSkillQuestionAdapter({
        requestId,
        authorization,
        locale,
        componentCode,
        skillCode,
        userText,
      });
    } catch {
      try {
        await finalizeUsage(requestId, "released", "domain_adapter_error");
      } catch {}
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "failed",
        reason: "domain_adapter_error",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "unavailable",
        reason: "domain_adapter_error",
        message: learnerMessage(locale, "unavailable"),
        academic_state_changed: false,
      });
    }

    const domainReason = String(domain?.reason || domain?.error || "domain_generation_unavailable");
    const domainMessage = String(domain?.message || "").trim();
    const validGenerated = domain?.generated === true
      && domain?.academic_state_changed === false
      && domainMessage.length > 0;

    if (!validGenerated) {
      try {
        await finalizeUsage(requestId, "released", domainReason.slice(0, 120));
      } catch {}

      const mode = domain?.mode === "no_source"
        ? "no_source"
        : domain?.mode === "blocked"
          ? "blocked"
          : "unavailable";

      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode,
        reason: domainReason,
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
        outputHash: domainMessage ? await sha256(domainMessage) : null,
      });

      return response(domainReason === "active_assessment" ? 423 : 200, {
        ok: false,
        mode,
        reason: domainReason,
        message: domainMessage || learnerMessage(
          locale,
          domainReason === "approved_source_missing" || domainReason === "deterministic_mapping_missing"
            ? "no_source"
            : domainReason === "active_assessment"
              ? "active_assessment"
              : "unavailable"
        ),
        academic_state_changed: false,
      });
    }

    let finalizedUsage: any = null;
    try {
      finalizedUsage = await finalizeUsage(requestId, "completed");
      if (finalizedUsage?.ok !== true) throw new Error("usage_finalize_failed");
    } catch {
      try {
        await finalizeUsage(requestId, "released", "delivery_not_finalized");
      } catch {}
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "failed",
        reason: "usage_finalize_failed",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(503, {
        ok: false,
        mode: "unavailable",
        reason: "usage_finalize_failed",
        message: learnerMessage(locale, "unavailable"),
        academic_state_changed: false,
      });
    }

    const outputHash = await sha256(domainMessage);
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: "generated",
      reason: null,
      adapterCode,
      policyVersion,
      latencyMs: performance.now() - started,
      outputHash,
    });

    return response(200, {
      ok: true,
      mode: "answer",
      message: domainMessage,
      usage_exhausted: finalizedUsage?.exhausted === true,
      reset_at: finalizedUsage?.reset_at || null,
      academic_state_changed: false,
    });
  }

  let message = "";

  if (interaction === "app_help") {
    message = appHelpMessage(locale, promptKey);
    if (!message) {
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "no_source",
        reason: "app_help_prompt_unknown",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "no_source",
        reason: "app_help_prompt_unknown",
        message: learnerMessage(locale, "no_source"),
        academic_state_changed: false,
      });
    }
  } else {
    if (adapterCode !== "math_exam_prep_v1"
        || subjectKey !== "mathematics"
        || scopeCode !== "exam_prep"
        || !preparedPrompt?.variant) {
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "no_source",
        reason: "prepared_adapter_unavailable",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "no_source",
        reason: "prepared_adapter_unavailable",
        message: learnerMessage(locale, "no_source"),
        academic_state_changed: false,
      });
    }

    if (!["P1", "P5"].includes(componentCode)
        || !/^P[15]-[A-Z0-9]+-[0-9]{2}$/.test(skillCode)) {
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "no_source",
        reason: "invalid_math_context",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "no_source",
        reason: "invalid_math_context",
        message: learnerMessage(locale, "no_source"),
        academic_state_changed: false,
      });
    }

    let card: any;
    try {
      card = await tutorCard(componentCode, skillCode, locale);
    } catch {
      card = null;
    }

    message = safeTutorText(card, preparedPrompt.variant);
    if (!message) {
      await recordAudit({
        requestId,
        userId: user.id,
        subjectKey,
        scopeCode,
        interaction,
        routeClass,
        mode: "no_source",
        reason: "prepared_source_missing",
        adapterCode,
        policyVersion,
        latencyMs: performance.now() - started,
      });
      return response(200, {
        ok: false,
        mode: "no_source",
        reason: "prepared_source_missing",
        message: learnerMessage(locale, "no_source"),
        academic_state_changed: false,
      });
    }
  }

  let reservation: any;
  try {
    reservation = await reserveUsage(requestId, user.id, usagePolicyCode, "prepared");
  } catch {
    reservation = null;
  }

  if (reservation?.allowed !== true) {
    const reason = String(reservation?.reason || "usage_unavailable");
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: "unavailable",
      reason,
      adapterCode,
      policyVersion,
      latencyMs: performance.now() - started,
    });
    return response(200, {
      ok: false,
      mode: "unavailable",
      reason,
      message: learnerMessage(locale, reason === "usage_exhausted" ? "usage_exhausted" : "unavailable"),
      reset_at: reservation?.reset_at || null,
      academic_state_changed: false,
    });
  }

  let finalizedUsage: any = null;
  try {
    finalizedUsage = await finalizeUsage(requestId, "completed");
    if (finalizedUsage?.ok !== true) throw new Error("usage_finalize_failed");
  } catch {
    try {
      await finalizeUsage(requestId, "released", "delivery_not_finalized");
    } catch {
      // Leave service-side expiry as the final safety net.
    }
    await recordAudit({
      requestId,
      userId: user.id,
      subjectKey,
      scopeCode,
      interaction,
      routeClass,
      mode: "failed",
      reason: "usage_finalize_failed",
      adapterCode,
      policyVersion,
      latencyMs: performance.now() - started,
    });
    return response(503, {
      ok: false,
      mode: "unavailable",
      message: learnerMessage(locale, "unavailable"),
      academic_state_changed: false,
    });
  }

  const outputHash = await sha256(message);
  await recordAudit({
    requestId,
    userId: user.id,
    subjectKey,
    scopeCode,
    interaction,
    routeClass,
    mode: "prepared",
    reason: null,
    adapterCode,
    policyVersion,
    latencyMs: performance.now() - started,
    outputHash,
  });

  return response(200, {
    ok: true,
    mode: "answer",
    message,
    usage_exhausted: finalizedUsage?.exhausted === true,
    reset_at: finalizedUsage?.reset_at || null,
    academic_state_changed: false,
  });
});